//
//  SourceCodeEditorViewProxy+Operations.m
//  XVim2
//
//  Created by Ant on 02/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "SourceCodeEditorViewProxy+Operations.h"
#import "SourceCodeEditorViewProxy+Yank.h"
#import "XVimMotion.h"
#import "NSTextStorage+VimOperation.h"

@interface SourceCodeEditorViewProxy()
@property(readwrite) NSUInteger selectionBegin;
@property(readwrite) NSUInteger insertionPoint;
@property(readwrite) NSUInteger preservedColumn;
@property(readwrite) BOOL selectionToEOL;
@property(readonly) NSTextStorage *textStorage;
@property NSRange selectedRange;
@property BOOL xvim_lockSyncStateFromView;
@property(strong) NSString* lastYankedText;
@property TEXT_TYPE lastYankedType;
- (void)xvim_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve;
- (void)xvim_syncState;
- (XVimRange)xvim_getMotionRange:(NSUInteger)current Motion:(XVimMotion*)motion;
- (XVimSelection)_xvim_selectedBlock;
- (NSRange)_xvim_selectedRange;
-(void)xvim_changeSelectionMode:(XVIM_VISUAL_MODE)mode;
-(void)xvim_registerInsertionPointForUndo;
@end


@implementation SourceCodeEditorViewProxy(Operations)

- (BOOL)xvim_delete:(XVimMotion*)motion andYank:(BOOL)yank
{
        return [self xvim_delete:motion withMotionPoint:self.insertionPoint andYank:yank];
}

- (BOOL)xvim_delete:(XVimMotion*)motion withMotionPoint:(NSUInteger)motionPoint andYank:(BOOL)yank
{
        NSAssert( !(self.selectionMode == XVIM_VISUAL_NONE && motion == nil),
                 @"motion must be specified if current selection mode is not visual");
        if (motionPoint == 0 && self.string.length == 0) {
                return NO;
        }
        NSUInteger newPos = NSNotFound;
        
        EDIT_TRANSACTION_SCOPE

        motion.info->deleteLastLine = NO;
        if (self.selectionMode == XVIM_VISUAL_NONE) {
                XVimRange motionRange = [self xvim_getMotionRange:motionPoint Motion:motion];
                if( motionRange.end == NSNotFound ){
                        return NO;
                }
                // We have to treat some special cases
                // When a cursor get end of line with "l" motion, make the motion type to inclusive.
                // This make you to delete the last character. (if its exclusive last character never deleted with "dl")
                if( motion.motion == MOTION_FORWARD && motion.info->reachedEndOfLine ){
                        if( motion.type == CHARACTERWISE_EXCLUSIVE ){
                                motion.type = CHARACTERWISE_INCLUSIVE;
                        }else if( motion.type == CHARACTERWISE_INCLUSIVE ){
                                motion.type = CHARACTERWISE_EXCLUSIVE;
                        }
                }
                if( motion.motion == MOTION_WORD_FORWARD ){
                        if ( (motion.info->isFirstWordInLine && motion.info->lastEndOfLine != NSNotFound )) {
                                // Special cases for word move over a line break.
                                motionRange.end = motion.info->lastEndOfLine;
                                motion.type = CHARACTERWISE_INCLUSIVE;
                        }
                        else if( motion.info->reachedEndOfLine ){
                                if( motion.type == CHARACTERWISE_EXCLUSIVE ){
                                        motion.type = CHARACTERWISE_INCLUSIVE;
                                }else if( motion.type == CHARACTERWISE_INCLUSIVE ){
                                        motion.type = CHARACTERWISE_EXCLUSIVE;
                                }
                        }
                }
                NSRange r = [self _xvim_getDeleteRange:motion withRange:motionRange];
                if (yank) {
                        [self _xvim_yankRange:r withType:motion.type];
                }
                [self insertText:@"" replacementRange:r];
                if( motion.motion == TEXTOBJECT_SQUOTE ||
                   motion.motion == TEXTOBJECT_DQUOTE ||
                   motion.motion == TEXTOBJECT_BACKQUOTE ||
                   motion.motion == TEXTOBJECT_PARENTHESES ||
                   motion.motion == TEXTOBJECT_BRACES ||
                   motion.motion == TEXTOBJECT_SQUAREBRACKETS ||
                   motion.motion == TEXTOBJECT_ANGLEBRACKETS ){
                        newPos = r.location;
                } else if (motion.type == LINEWISE) {
                        newPos = [self.textStorage xvim_firstNonblankInLineAtIndex:r.location allowEOL:YES];
                }
        } else if (self.selectionMode != XVIM_VISUAL_BLOCK) {
                BOOL toFirstNonBlank = (self.selectionMode == XVIM_VISUAL_LINE);
                NSRange range = [self _xvim_selectedRange];
                
                // Currently not supportin deleting EOF with selection mode.
                // This is because of the fact that NSTextView does not allow select EOF
                
                if (yank) {
                        [self _xvim_yankRange:range withType:DEFAULT_MOTION_TYPE];
                }
                [self insertText:@"" replacementRange:range];
                if (toFirstNonBlank) {
                        newPos = [self.textStorage xvim_firstNonblankInLineAtIndex:range.location allowEOL:YES];
                } else {
                        newPos = range.location;
                }
        } else {
                XVimSelection sel = [self _xvim_selectedBlock];
                if (yank) {
                        [self _xvim_yankSelection:sel];
                }
                [self _xvim_killSelection:sel];
                
                newPos = [self.textStorage xvim_indexOfLineNumber:sel.top column:sel.left];
        }
        
        [self.xvimDelegate textView:self didDelete:self.lastYankedText  withType:self.lastYankedType];
        [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
        if (newPos != NSNotFound) {
                [self xvim_moveCursor:newPos preserveColumn:NO];
        }
        return YES;
}

- (BOOL)xvim_change:(XVimMotion*)motion{
        // We do not need to call this since this method uses xvim_delete to operate on text
        //[self xvim_registerInsertionPointForUndo];
        
        BOOL insertNewline = NO;
        if( motion.type == LINEWISE || self.selectionMode == XVIM_VISUAL_LINE){
                // 'cc' deletes the lines but need to keep the last newline.
                // So insertNewline as 'O' does before entering insert mode
                insertNewline = YES;
        }
        
        // "cw" is like "ce" if the cursor is on a word ( in this case blank line is not treated as a word )
        if( motion.motion == MOTION_WORD_FORWARD && [self.textStorage isNonblank:self.insertionPoint] ){
                motion.motion = MOTION_END_OF_WORD_FORWARD;
                motion.type = CHARACTERWISE_INCLUSIVE;
                motion.option |= MOTION_OPTION_CHANGE_WORD;
        }
        // We have to set cursor mode insert before calling delete
        // because delete adjust cursor position when the cursor is end of line. (e.g. C command).
        // This behaves that insertion position after delete is one character before the last char of the line.
        self.cursorMode = CURSOR_MODE_INSERT;
        if( ![self xvim_delete:motion andYank:YES] ){
                // And if the delele failed we set the cursor mode back to command.
                // The cursor mode should be kept in Evaluators so we should make some delegation to it.
                self.cursorMode = CURSOR_MODE_COMMAND;
                return NO;
        }
        if( motion.info->deleteLastLine){
                [self xvim_insertNewlineAboveLine:[self.textStorage xvim_lineNumberAtIndex:self.insertionPoint]];
        }
        else if( insertNewline ){
                [self xvim_insertNewlineAboveCurrentLineWithIndent];
        }else{
                
        }
        [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
        [self xvim_syncState];
        return YES;
}




- (void)xvim_insertText:(NSString*)str line:(NSUInteger)line column:(NSUInteger)column{
        NSUInteger pos = [self.textStorage xvim_indexOfLineNumber:line column:column];
        if( pos == NSNotFound ){
                return;
        }
        [self insertText:str replacementRange:NSMakeRange(pos,0)];
}

- (void)xvim_insertNewlineBelowLine:(NSUInteger)line{
        NSAssert( line != 0, @"line number starts from 1");
        NSUInteger pos = [self.textStorage xvim_indexOfLineNumber:line];
        if( NSNotFound == pos ){
                return;
        }
        pos = [self.textStorage xvim_endOfLine:pos];
        [self insertText:@"\n" replacementRange:NSMakeRange(pos ,0)];
        [self xvim_moveCursor:pos+1 preserveColumn:NO];
        [self xvim_syncState];
}

- (void)xvim_insertNewlineBelowCurrentLine{
        [self xvim_insertNewlineBelowLine:[self.textStorage xvim_lineNumberAtIndex:self.insertionPoint]];
}

- (void)xvim_insertNewlineBelowCurrentLineWithIndent{
        NSUInteger tail = [self.textStorage xvim_endOfLine:self.insertionPoint];
        [self setSelectedRange:NSMakeRange(tail,0)];
        [self insertNewline:self];
}

- (void)xvim_insertNewlineAboveLine:(NSUInteger)line{
        NSAssert( line != 0, @"line number starts from 1");
        NSUInteger pos = [self.textStorage xvim_indexOfLineNumber:line];
        if( NSNotFound == pos ){
                return;
        }
        if( 1 != line ){
                [self xvim_insertNewlineBelowLine:line-1];
        }else{
                [self insertText:@"\n" replacementRange:NSMakeRange(0,0)];
                [self setSelectedRange:NSMakeRange(0,0)];
        }
}

- (void)xvim_insertNewlineAboveCurrentLine{
        [self xvim_insertNewlineAboveLine:[self.textStorage xvim_lineNumberAtIndex:self.insertionPoint]];
}

- (void)xvim_insertNewlineAboveCurrentLineWithIndent{
        NSUInteger head = [self.textStorage xvim_startOfLine:self.insertionPoint];
        if( 0 != head ){
                [self setSelectedRange:NSMakeRange(head-1,0)];
                [self insertNewline:self];
        }else{
                [self setSelectedRange:NSMakeRange(head,0)];
                [self insertNewline:self];
                [self setSelectedRange:NSMakeRange(0,0)];
        }
}

- (void)xvim_insertNewlineAboveAndInsertWithIndent{
        self.cursorMode = CURSOR_MODE_INSERT;
        [self xvim_insertNewlineAboveCurrentLineWithIndent];
}

- (void)xvim_insertNewlineBelowAndInsertWithIndent{
        self.cursorMode = CURSOR_MODE_INSERT;
        [self xvim_insertNewlineBelowCurrentLineWithIndent];
}



- (BOOL)xvim_replaceCharacters:(unichar)c count:(NSUInteger)count{
        NSUInteger eol = [self.textStorage xvim_endOfLine:self.insertionPoint];
        // Note : endOfLine may return one less than self.insertionPoint if self.insertionPoint is on newline
        if( NSNotFound == eol ){
                return NO;
        }
        NSUInteger end = self.insertionPoint + count;
        for( NSUInteger pos = self.insertionPoint; pos < end; ++pos){
                NSString* text = [NSString stringWithFormat:@"%C",c];
                if( pos < eol ){
                        [self insertText:text replacementRange:NSMakeRange(pos, 1)];
                } else {
                        [self insertText:text];
                }
        }
        return YES;
}

- (void)xvim_swapCaseForRange:(NSRange)range {
        EDIT_TRANSACTION_SCOPE;
        NSString* text = self.string;
        
        
        NSMutableString *substring = [[text substringWithRange:range] mutableCopy];
        for (NSUInteger i = 0; i < range.length; ++i) {
                NSRange currentRange = NSMakeRange(i, 1);
                NSString *currentCase = [substring substringWithRange:currentRange];
                NSString *upperCase = [currentCase uppercaseString];
                
                NSRange replaceRange = NSMakeRange(i, 1);
                if ([currentCase isEqualToString:upperCase]){
                        [substring replaceCharactersInRange:replaceRange withString:[currentCase lowercaseString]];
                }else{
                        [substring replaceCharactersInRange:replaceRange withString:upperCase];
                }
        }
        
        [self insertText:substring replacementRange:range];
}


- (void)xvim_swapCase:(XVimMotion*)motion{
        if( self.insertionPoint == 0 && self.string.length == 0 ){
                return ;
        }
        
        if( self.selectionMode == XVIM_VISUAL_NONE ){
                if( motion.motion == MOTION_NONE ){
                        XVimMotion* m = XVIM_MAKE_MOTION(MOTION_FORWARD,CHARACTERWISE_EXCLUSIVE,LEFT_RIGHT_NOWRAP,motion.count);
                        XVimRange r = [self xvim_getMotionRange:self.insertionPoint Motion:m];
                        if( r.end == NSNotFound){
                                return;
                        }
                        if( m.info->reachedEndOfLine ){
                                [self xvim_swapCaseForRange:[self xvim_getOperationRangeFrom:r.begin To:r.end Type:CHARACTERWISE_INCLUSIVE]];
                        }else{
                                [self xvim_swapCaseForRange:[self xvim_getOperationRangeFrom:r.begin To:r.end Type:CHARACTERWISE_EXCLUSIVE]];
                        }
                        [self xvim_moveCursor:r.end preserveColumn:NO];
                }else{
                        NSRange r;
                        XVimRange to = [self xvim_getMotionRange:self.insertionPoint Motion:motion];
                        if( to.end == NSNotFound){
                                return;
                        }
                        r = [self xvim_getOperationRangeFrom:to.begin To:to.end Type:motion.type];
                        [self xvim_swapCaseForRange:r];
                        [self xvim_moveCursor:r.location preserveColumn:NO];
                }
        }else{
                NSArray* ranges = [self xvim_selectedRanges];
                for( NSValue* val in ranges){
                        [self xvim_swapCaseForRange:[val rangeValue]];
                }
                [self xvim_moveCursor:[[ranges objectAtIndex:0] rangeValue].location preserveColumn:NO];
        }
        
        [self xvim_syncState];
        [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
        
}

- (void)xvim_makeLowerCase:(XVimMotion*)motion{
        if( self.insertionPoint == 0 && [self.string length] == 0 ){
                return ;
        }
        
        NSString* s = self.string;
        if( self.selectionMode == XVIM_VISUAL_NONE ){
                NSRange r;
                XVimRange to = [self xvim_getMotionRange:self.insertionPoint Motion:motion];
                if( to.end == NSNotFound ){
                        return;
                }
                r = [self xvim_getOperationRangeFrom:to.begin To:to.end Type:motion.type];
                [self insertText:[[s substringWithRange:r] lowercaseString] replacementRange:r];
                [self xvim_moveCursor:r.location preserveColumn:NO];
        }else{
                NSArray* ranges = [self xvim_selectedRanges];
                for( NSValue* val in ranges){
                        [self insertText:[[s substringWithRange:val.rangeValue] lowercaseString] replacementRange:val.rangeValue];
                }
                [self xvim_moveCursor:[[ranges objectAtIndex:0] rangeValue].location preserveColumn:NO];
        }
        
        [self xvim_syncState];
        [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}


- (void)xvim_makeUpperCase:(XVimMotion*)motion{
        if( self.insertionPoint == 0 && [self.string length] == 0 ){
                return ;
        }
        
        NSString* s = self.string;
        if( self.selectionMode == XVIM_VISUAL_NONE ){
                NSRange r;
                XVimRange to = [self xvim_getMotionRange:self.insertionPoint Motion:motion];
                if( to.end == NSNotFound ){
                        return;
                }
                r = [self xvim_getOperationRangeFrom:to.begin To:to.end Type:motion.type];  // TODO: use to.begin instead of insertionPoint
                [self insertText:[[s substringWithRange:r] uppercaseString] replacementRange:r];
                [self xvim_moveCursor:r.location preserveColumn:NO];
        }else{
                NSArray* ranges = [self xvim_selectedRanges];
                for( NSValue* val in ranges){
                        [self insertText:[[s substringWithRange:val.rangeValue] uppercaseString] replacementRange:val.rangeValue];
                }
                [self xvim_moveCursor:[[ranges objectAtIndex:0] rangeValue].location preserveColumn:NO];
        }
        
        [self xvim_syncState];
        [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
        
}


- (NSRange)_xvim_getDeleteRange:(XVimMotion*)motion withRange:(XVimRange)to{
        NSRange r = [self xvim_getOperationRangeFrom:to.begin To:to.end Type:motion.type];
        if( motion.type == LINEWISE && [self.textStorage isLastLine:to.end]){
                if( r.location != 0 ){
                        motion.info->deleteLastLine = YES;
                        r.location--;
                        r.length++;
                }
        }
        return r;
}

- (NSRange)xvim_getOperationRangeFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type {
        if( self.string.length == 0 ){
                NSMakeRange(0,0); // No range
        }
        
        if( from > to ){
                NSUInteger tmp = from;
                from = to;
                to = tmp;
        }
        // EOF can not be included in operation range.
        if( [self.textStorage isEOF:from] ){
                return NSMakeRange(from, 0); // from is EOF but the length is 0 means EOF will not be included in the returned range.
        }
        
        // EOF should not be included.
        // If type is exclusive we do not subtract 1 because we do it later below
        if( [self.textStorage isEOF:to] && type != CHARACTERWISE_EXCLUSIVE){
                to--; // Note that we already know that "to" is not 0 so not chekcing if its 0.
        }
        
        // At this point "from" and "to" is not EOF
        if( type == CHARACTERWISE_EXCLUSIVE ){
                // to will not be included.
                to--;
        }else if( type == CHARACTERWISE_INCLUSIVE ){
                // Nothing special
        }else if( type == LINEWISE ){
                to = [self.textStorage xvim_endOfLine:to];
                if( [self.textStorage isEOF:to] ){
                        to--;
                }
                NSUInteger head = [self.textStorage xvim_firstOfLine:from];
                if( NSNotFound != head ){
                        from = head;
                }
        }
        
        return NSMakeRange(from, to - from + 1); // Inclusive range
}


@end
