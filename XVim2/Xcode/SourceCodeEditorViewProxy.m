//
//  SourceEditorProxy.m
//  XVim2
//
//  Created by Anthony Dervish on 16/09/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "SourceCodeEditorViewProxy.h"
#import "NSTextStorage+VimOperation.h"
#import "XVim.h"
#import "_TtC22IDEPegasusSourceEditor16SourceCodeEditor.h"
#import "_TtC22IDEPegasusSourceEditor18SourceCodeDocument.h"
#import "XVimMotion.h"
#import "rd_route.h"
#import "ffi.h"

static void(*fpSetCursorStyle)(int style, id obj);
static void(*fpGetCursorStyle)(int style, id obj);
static void(*fpGetTextStorage)(void);
static void(*fpGetSourceEditorDataSource)(void);

@interface SourceCodeEditorViewProxy()
@property(readwrite) NSUInteger selectionBegin;
@property(readwrite) NSUInteger insertionPoint;
@property(readwrite) NSUInteger preservedColumn;
@property(readwrite) BOOL selectionToEOL;
@end

#define LOG_STATE()

@implementation SourceCodeEditorViewProxy {
    NSMutableArray<NSValue*> * _foundRanges;
}
@synthesize selectedRange;

+ (void)initialize
{
    if (self == [SourceCodeEditorViewProxy class]) {
        // SourceEditorView.cursorStyle.setter
        fpSetCursorStyle = function_ptr_from_name("_T012SourceEditor0aB4ViewC11cursorStyleAA0ab6CursorE0Ofs", NULL);
        fpGetCursorStyle = function_ptr_from_name("_T012SourceEditor0aB4ViewC11cursorStyleAA0ab6CursorE0Ofg", NULL);
        fpGetTextStorage = function_ptr_from_name("_T022IDEPegasusSourceEditor0B12CodeDocumentC16sdefSupport_textSo13NSTextStorageCyF", NULL);
        fpGetSourceEditorDataSource = function_ptr_from_name("_T012SourceEditor0aB4ViewC04dataA0AA0ab4DataA0Cfg", NULL);
    }
}

-(instancetype)initWithSourceCodeEditorView:(SourceCodeEditorView*)sourceCodeEditorView
{
    self = [super init];
    if (self) {
        self.sourceCodeEditorView = sourceCodeEditorView;
    }
    return self;
}

#define GET(target, fp) \
ffi_cif cif; \
ffi_arg rc = 0; \
void *values = NULL; \
ffi_type *args[0]; \
if (ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 0, \
                 &ffi_type_sint64, args) == FFI_OK) \
{ \
    ffi_call_apple(&cif, (void*)fpGetTextStorage, target, NULL, &rc, values); \
}

#define SET(target, fp, ffitype, arg) \
ffi_cif cif; \
ffi_type *args[1]; \
void *values[1]; \
ffi_arg rc = 0; \
args[0] = &ffitype; \
values[0] = &arg; \
if (ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 1, \
                 &ffi_type_pointer, args) == FFI_OK) \
{ \
    ffi_call_apple(&cif, (void*)fp, target, NULL, &rc, values); \
}

-(void)setCursorStyle:(CursorStyle)cursorStyle
{
    void * sourceEditorView = (__bridge_retained void *)self.sourceCodeEditorView;
    SET(sourceEditorView, fpSetCursorStyle, ffi_type_sint64, cursorStyle)
}

-(CursorStyle)cursorStyle {
    void * sourceEditorView = (__bridge void *)self.sourceCodeEditorView;
    GET(sourceEditorView, fpSetCursorStyle)
    return rc & 0xFF;
}

-(NSTextStorage*)textStorage {
    void * sourceCodeDocument = (__bridge void *)self.sourceCodeEditorView.hostingEditor.document;
    GET(sourceCodeDocument, fpGetTextStorage);
    return (__bridge NSTextStorage*)(void*)rc;
}

- (void)scrollPageBackward:(NSUInteger)numPages {
    for (int i=0; i < numPages; ++i)
        [self.sourceCodeEditorView scrollPageUp:self];
}

- (void)scrollPageForward:(NSUInteger)numPages {
    for (int i=0; i < numPages; ++i)
        [self.sourceCodeEditorView scrollPageDown:self];
}



-(void)setSelectedRange:(NSRange)range {
    self.sourceCodeEditorView.selectedTextRange = range;
}

-(void)setSelectedRanges:(NSArray<NSValue*>*)ranges
                affinity:(NSSelectionAffinity)affinity
          stillSelecting:(BOOL)stillSelectingFlag
{
    // TODO
    [self.sourceCodeEditorView setAccessibilitySelectedTextRanges:ranges];
}

- (void)xvim_move:(XVimMotion*)motion{
    XVimRange r = [self xvim_getMotionRange:self.insertionPoint Motion:motion];
    if( r.end == NSNotFound ){
        return;
    }
    
    if( self.selectionMode != XVIM_VISUAL_NONE && [motion isTextObject]){
        if( self.selectionMode == XVIM_VISUAL_LINE){
            // Motion with text object in VISUAL LINE changes visual mode to VISUAL CHARACTER
            [self setSelectionMode:XVIM_VISUAL_CHARACTER];
        }
        
        if( self.insertionPoint < self.selectionBegin ){
            // When insertionPoint < selectionBegin it only changes insertion point to beginning of the text object
            [self xvim_moveCursor:r.begin preserveColumn:NO];
        }else{
            // Text object expands one text object ( the text object under insertion point + 1 )
            if( ![self.textStorage isEOF:self.insertionPoint+1]){
                if( motion.motion != TEXTOBJECT_UNDERSCORE) {
                    r = [self xvim_getMotionRange:self.insertionPoint+1 Motion:motion];
                }
            }
            if( self.selectionBegin > r.begin ){
                self.selectionBegin = r.begin;
            }
            [self xvim_moveCursor:r.end preserveColumn:NO];
        }
    } else {
        switch( motion.motion ){
            case MOTION_LINE_BACKWARD:
            case MOTION_LINE_FORWARD:
            case MOTION_LASTLINE:
            case MOTION_LINENUMBER:
                // TODO: Preserve column option can be included in motion object
                if (self.selectionMode == XVIM_VISUAL_BLOCK && self.selectionToEOL) {
                    r.end = [self.textStorage xvim_endOfLine:r.end];
                } else if (XVIM.options[XVimPref_StartOfLine]) {
                    // only jump to nonblank line for last line or line number
                    if (motion.motion == MOTION_LASTLINE || motion.motion == MOTION_LINENUMBER) {
                        r.end = [self.textStorage xvim_firstNonblankInLineAtIndex:r.end allowEOL:YES];
                    }
                }
                [self xvim_moveCursor:r.end preserveColumn:YES];
                break;
            case MOTION_END_OF_LINE:
                self.selectionToEOL = YES;
                [self xvim_moveCursor:r.end preserveColumn:NO];
                break;
            case MOTION_END_OF_WORD_BACKWARD:
                self.selectionToEOL = NO;
                [self xvim_moveCursor:r.begin preserveColumn:NO];
                break;
                
            default:
                self.selectionToEOL = NO;
                [self xvim_moveCursor:r.end preserveColumn:NO];
                break;
        }
    }
    //[self setNeedsDisplay:YES];
    [self xvim_syncState];
}

- (void)xvim_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve{
    // This method only update the internal state(like self.insertionPoint)
    
    if( pos > [self xvim_string].length){
        ERROR_LOG(@"[%p]Position specified exceeds the length of the text", self);
        pos = [self xvim_string].length;
    }
    
    if( self.cursorMode == CURSOR_MODE_COMMAND && !(self.selectionMode == XVIM_VISUAL_BLOCK)){
        self.insertionPoint = [self.textStorage convertToValidCursorPositionForNormalMode:pos];
    }else{
        self.insertionPoint = pos;
    }
    
    if( !preserve ){
        self.preservedColumn = [self.textStorage xvim_columnOfIndex:self.insertionPoint];
    }
    
    DEBUG_LOG(@"[%p]New Insertion Point:%d   Preserved Column:%d", self, self.insertionPoint, self.preservedColumn);
}

- (void)_adjustCursorPosition{
#ifdef TODO
    TRACE_LOG(@"[%p]ENTER", self);
    if( ![self.textStorage isValidCursorPosition:self.insertionPoint] ){
        NSRange placeholder = [(DVTSourceTextView*)self rangeOfPlaceholderFromCharacterIndex:self.insertionPoint forward:NO wrap:NO limit:0];
        if( placeholder.location != NSNotFound && self.insertionPoint == (placeholder.location + placeholder.length)){
            //The condition here means that just before current insertion point is a placeholder.
            //So we select the the place holder and its already selected by "selectedPreviousPlaceholder" above
            [self xvim_moveCursor:placeholder.location preserveColumn:YES];
        }else{
            [self xvim_moveCursor:self.insertionPoint-1 preserveColumn:YES];
        }
    }
#endif
}


- (void)xvim_syncStateWithScroll:(BOOL)scroll{
    DEBUG_LOG(@"[%p]IP:%d", self, self.insertionPoint);
    //self.xvim_lockSyncStateFromView = YES;
    // Reset current selection
    if( self.cursorMode == CURSOR_MODE_COMMAND ){
        [self _adjustCursorPosition];
    }
    [self dumpState];
    
    //[(DVTFoldingTextStorage*)self.textStorage increaseUsingFoldedRanges];
    [self setSelectedRanges:[self xvim_selectedRanges] affinity:NSSelectionAffinityDownstream stillSelecting:NO];
    //[(DVTFoldingTextStorage*)self.textStorage decreaseUsingFoldedRanges];

    if(scroll){
        [self xvim_scrollTo:self.insertionPoint];
    }
    //self.xvim_lockSyncStateFromView = NO;
}

-(void)xvim_scrollTo:(NSUInteger)insertionPoint
{
    //_auto rng = [self.sourceCodeEditorView lineRangeForCharacterRange:NSMakeRange(insertionPoint, 0)];
    [self.sourceCodeEditorView scrollRangeToVisible:NSMakeRange(insertionPoint, 0)];
}

/**
 * Applies internal state to underlying view (self).
 * This update self's property and applies the visual effect on it.
 * All the state need to express Vim is held by this class and
 * we use self to express it visually.
 **/
- (void)xvim_syncState{
    [self xvim_syncStateWithScroll:YES];
}

- (void)dumpState{
    LOG_STATE();
}

// xvim_setSelectedRange is an internal method
// This is used when you want to call [self setSelectedRrange];
// The difference is that this checks the bounds(range can not be include EOF) and protect from Assersion
// Cursor can be on EOF but EOF can not be selected.
// It means that
//   - setSelectedRange:NSMakeRange( indexOfEOF, 0 )   is allowed
//   - setSelectedRange:NSMakeRange( indexOfEOF, 1 )   is not allowed
- (void)xvim_setSelectedRange:(NSRange)range{
    if( [self.textStorage isEOF:range.location] ){
        [self setSelectedRange:NSMakeRange(range.location,0)];
        return;
    }
    if( 0 == range.length ){
        // No need to check bounds
    }else{
        NSUInteger lastIndex = range.location + range.length - 1;
        if( [self.textStorage isEOF:lastIndex] ){
            range.length--;
        }else{
            // No need to change the selection area
        }
    }
    [self setSelectedRange:range];
    LOG_STATE();
}

- (NSArray*)xvim_selectedRanges {
    
    if (self.selectionMode != XVIM_VISUAL_BLOCK) {
        return [NSArray arrayWithObject:[NSValue valueWithRange:[self _xvim_selectedRange]]];
    }
    
    NSMutableArray *rangeArray = [[NSMutableArray alloc] init];
    NSTextStorage  *ts = self.textStorage;
    XVimSelection sel = [self _xvim_selectedBlock];
    
    for (NSUInteger line = sel.top; line <= sel.bottom; line++) {
        NSUInteger begin = [ts xvim_indexOfLineNumber:line column:sel.left];
        NSUInteger end   = [ts xvim_indexOfLineNumber:line column:sel.right];
        
        if ([ts isEOF:begin]) {
            continue;
        }
        if ([ts isEOF:end]){
            end--;
        } else if (sel.right != XVimSelectionEOL && [ts isEOL:end]) {
            end--;
        }
        [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(begin, end - begin + 1)]];
    }
    return rangeArray;
}


- (XVimRange)_xvim_selectedLines{
    if (self.selectionMode == XVIM_VISUAL_NONE) { // its not in selecting mode
        return (XVimRange){ NSNotFound, NSNotFound };
    } else {
        NSUInteger l1 = [self.textStorage xvim_lineNumberAtIndex:self.insertionPoint];
        NSUInteger l2 = [self.textStorage xvim_lineNumberAtIndex:self.selectionBegin];
        
        return (XVimRange){ MIN(l1, l2), MAX(l1, l2) };
    }
}

- (NSRange)_xvim_selectedRange{
    if (self.selectionMode == XVIM_VISUAL_NONE) {
        return NSMakeRange(self.insertionPoint, 0);
    }
    
    if (self.selectionMode == XVIM_VISUAL_CHARACTER) {
        XVimRange xvr = XVimMakeRange(self.selectionBegin, self.insertionPoint);
        
        if (xvr.begin > xvr.end) {
            xvr = XVimRangeSwap(xvr);
        }
        if ([self.textStorage isEOF:xvr.end]) {
            xvr.end--;
        }
        return XVimMakeNSRange(xvr);
    }
    
    if (self.selectionMode == XVIM_VISUAL_LINE) {
        XVimRange  lines = [self _xvim_selectedLines];
        NSUInteger begin = [self.textStorage xvim_indexOfLineNumber:lines.begin];
        NSUInteger end   = [self.textStorage xvim_indexOfLineNumber:lines.end];
        
        end = [self.textStorage xvim_endOfLine:end];
        if ([self.textStorage isEOF:end]) {
            end--;
        }
        return NSMakeRange(begin, end - begin + 1);
    }
    
    return NSMakeRange(NSNotFound, 0);
}

- (XVimSelection)_xvim_selectedBlock{
    XVimSelection result = { };
    
    if (self.selectionMode == XVIM_VISUAL_NONE) {
        result.top = result.bottom = result.left = result.right = NSNotFound;
        return result;
    }
    
    NSTextStorage *ts = self.textStorage;
    NSUInteger l1, c11, c12;
    NSUInteger l2, c21, c22;
    NSUInteger tabWidth = ts.xvim_tabWidth;
    NSUInteger pos;
    
    pos = self.selectionBegin;
    l1  = [ts xvim_lineNumberAtIndex:pos];
    c11 = [ts xvim_columnOfIndex:pos];
    if (!tabWidth || [ts isEOF:pos] || [self.xvim_string characterAtIndex:pos] != '\t') {
        c12 = c11;
    } else {
        c12 = c11 + tabWidth - (c11 % tabWidth) - 1;
    }
    
    pos = self.insertionPoint;
    l2  = [ts xvim_lineNumberAtIndex:pos];
    c21 = [ts xvim_columnOfIndex:pos];
    if (!tabWidth || [ts isEOF:pos] || [self.xvim_string characterAtIndex:pos] != '\t') {
        c22 = c21;
    } else {
        c22 = c21 + tabWidth - (c21 % tabWidth) - 1;
    }
    
    if (l1 <= l2) {
        result.corner |= _XVIM_VISUAL_BOTTOM;
    }
    if (c11 <= c22) {
        result.corner |= _XVIM_VISUAL_RIGHT;
    }
    result.top     = MIN(l1, l2);
    result.bottom  = MAX(l1, l2);
    result.left    = MIN(c11, c21);
    result.right   = MAX(c12, c22);
    if (self.selectionToEOL) {
        result.right = XVimSelectionEOL;
    }
    return result;
}


- (XVimRange)xvim_getMotionRange:(NSUInteger)current Motion:(XVimMotion*)motion{
    NSRange range = NSMakeRange( NSNotFound , 0 );
    NSUInteger begin = current;
    NSUInteger end = NSNotFound;
    NSUInteger tmpPos = NSNotFound;
    NSUInteger start = NSNotFound;
    NSUInteger starts_end = NSNotFound;
    
    switch (motion.motion) {
        case MOTION_NONE:
            // Do nothing
            break;
        case MOTION_FORWARD:
            motion.option |= MOPT_PLACEHOLDER;
            end = [self.textStorage next:begin count:motion.count option:motion.option info:motion.info];
            break;
        case MOTION_BACKWARD:
            motion.option |= MOPT_PLACEHOLDER;
            end = [self.textStorage prev:begin count:motion.count option:motion.option ];
            break;
        case MOTION_WORD_FORWARD:
            motion.option |= MOPT_PLACEHOLDER;
            end = [self.textStorage wordsForward:begin count:motion.count option:motion.option info:motion.info];
            break;
        case MOTION_WORD_BACKWARD:
            motion.option |= MOPT_PLACEHOLDER;
            end = [self.textStorage wordsBackward:begin count:motion.count option:motion.option];
            break;
        case MOTION_END_OF_WORD_FORWARD:
            motion.option |= MOPT_PLACEHOLDER;
            end = [self.textStorage endOfWordsForward:begin count:motion.count option:motion.option];
            break;
        case MOTION_END_OF_WORD_BACKWARD:
            motion.option |= MOPT_PLACEHOLDER;
            end = begin;
            begin = [self.textStorage endOfWordsBackward:begin count:motion.count option:motion.option];
            break;
        case MOTION_LINE_FORWARD:
            if( motion.option & DISPLAY_LINE ){
                end = [self xvim_displayNextLine:begin column:self.preservedColumn count:motion.count option:motion.option];
            }else{
                end = [self.textStorage nextLine:begin column:self.preservedColumn count:motion.count option:motion.option];
            }
            break;
        case MOTION_LINE_BACKWARD:
            if( motion.option & DISPLAY_LINE ){
                end = [self xvim_displayPrevLine:begin column:self.preservedColumn count:motion.count option:motion.option];
            }else{
                end = [self.textStorage prevLine:begin column:self.preservedColumn count:motion.count option:motion.option];
            }
            break;
        case MOTION_BEGINNING_OF_LINE:
            end = [self.textStorage xvim_startOfLine:begin];
            if( end == NSNotFound){
                end = current;
            }
            break;
        case MOTION_END_OF_LINE:
            tmpPos = [self.textStorage nextLine:begin column:0 count:motion.count-1 option:MOTION_OPTION_NONE];
            end = [self.textStorage xvim_endOfLine:tmpPos];
            if( end == NSNotFound){
                end = tmpPos;
            }
            break;
        case MOTION_SENTENCE_FORWARD:
            end = [self.textStorage sentencesForward:begin count:motion.count option:motion.option];
            break;
        case MOTION_SENTENCE_BACKWARD:
            end = [self.textStorage sentencesBackward:begin count:motion.count option:motion.option];
            break;
        case MOTION_PARAGRAPH_FORWARD:
            end = [self.textStorage paragraphsForward:begin count:motion.count option:motion.option];
            break;
        case MOTION_PARAGRAPH_BACKWARD:
            end = [self.textStorage paragraphsBackward:begin count:motion.count option:motion.option];
            break;
        case MOTION_NEXT_CHARACTER:
            end = [self.textStorage nextCharacterInLine:begin count:motion.count character:motion.character option:MOTION_OPTION_NONE];
            break;
        case MOTION_PREV_CHARACTER:
            end = [self.textStorage prevCharacterInLine:begin count:motion.count character:motion.character option:MOTION_OPTION_NONE];
            break;
        case MOTION_TILL_NEXT_CHARACTER:
            end = [self.textStorage nextCharacterInLine:begin count:motion.count character:motion.character option:motion.option];
            if(end != NSNotFound){
                end--;
            }
            break;
        case MOTION_TILL_PREV_CHARACTER:
            end = [self.textStorage prevCharacterInLine:begin count:motion.count character:motion.character option:motion.option];
            if(end != NSNotFound){
                end++;
            }
            break;
        case MOTION_NEXT_FIRST_NONBLANK:
            end = [self.textStorage nextLine:begin column:0 count:motion.count option:motion.option];
            tmpPos = [self.textStorage xvim_nextNonblankInLineAtIndex:end allowEOL:NO];
            if( NSNotFound != tmpPos ){
                end = tmpPos;
            }
            break;
        case MOTION_PREV_FIRST_NONBLANK:
            end = [self.textStorage prevLine:begin column:0 count:motion.count option:motion.option];
            tmpPos = [self.textStorage xvim_nextNonblankInLineAtIndex:end allowEOL:NO];
            if( NSNotFound != tmpPos ){
                end = tmpPos;
            }
            break;
        case MOTION_FIRST_NONBLANK:
            end = [self.textStorage xvim_firstNonblankInLineAtIndex:begin allowEOL:NO];
            break;
        case MOTION_LINENUMBER:
            end = [self.textStorage xvim_indexOfLineNumber:motion.line column:self.preservedColumn];
            if( NSNotFound == end ){
                end = [self.textStorage xvim_indexOfLineNumber:[self.textStorage xvim_numberOfLines] column:self.preservedColumn];
            }
            break;
        case MOTION_PERCENT:
            end = [self.textStorage xvim_indexOfLineNumber:1 + ([self.textStorage xvim_numberOfLines]-1) * motion.count/100];
            break;
        case MOTION_NEXT_MATCHED_ITEM:
            end = [self.textStorage positionOfMatchedPair:begin];
            break;
        case MOTION_LASTLINE:
            end = [self.textStorage xvim_indexOfLineNumber:[self.textStorage xvim_numberOfLines] column:self.preservedColumn];
            break;
        case MOTION_HOME:
            //TODO
            //end = [self.textStorage xvim_firstNonblankInLineAtIndex:[self.textStorage xvim_indexOfLineNumber:[self xvim_lineNumberFromTop:motion.count]] allowEOL:YES];
            break;
        case MOTION_MIDDLE:
            //TODO
            //end = [self.textStorage xvim_firstNonblankInLineAtIndex:[self.textStorage xvim_indexOfLineNumber:[self xvim_lineNumberAtMiddle]] allowEOL:YES];
            break;
        case MOTION_BOTTOM:
            //TODO
            //end = [self.textStorage xvim_firstNonblankInLineAtIndex:[self.textStorage xvim_indexOfLineNumber:[self xvim_lineNumberFromBottom:motion.count]] allowEOL:YES];
            break;
        case MOTION_SEARCH_FORWARD:
            end = [self.textStorage searchRegexForward:motion.regex from:self.insertionPoint count:motion.count option:motion.option].location;
            if( end == NSNotFound && !(motion.option&SEARCH_WRAP) ){
                //TODO
                //NSRange range = [self xvim_currentWord:MOTION_OPTION_NONE];
                //end = range.location;
            }
            break;
        case MOTION_SEARCH_BACKWARD:
            end = [self.textStorage searchRegexBackward:motion.regex from:self.insertionPoint count:motion.count option:motion.option].location;
            if( end == NSNotFound && !(motion.option&SEARCH_WRAP) ){
                //TODO
                // NSRange range = [self xvim_currentWord:MOTION_OPTION_NONE];
                //end = range.location;
            }
            break;
        case TEXTOBJECT_WORD:
            range = [self.textStorage currentWord:begin count:motion.count  option:motion.option];
            break;
        case TEXTOBJECT_UNDERSCORE:
            range = [self.textStorage currentCamelCaseWord:begin count:motion.count option:motion.option];
            break;
        case TEXTOBJECT_BRACES:
            range = xv_current_block([self xvim_string], current, motion.count, !(motion.option & TEXTOBJECT_INNER), '{', '}');
            break;
        case TEXTOBJECT_PARAGRAPH:
            // Not supported
            start = self.insertionPoint;
            if(start != 0){
                start = [self.textStorage paragraphsBackward:self.insertionPoint count:1 option:MOPT_PARA_BOUND_BLANKLINE];
            }
            starts_end = [self.textStorage paragraphsForward:start count:1 option:MOPT_PARA_BOUND_BLANKLINE];
            end = [self.textStorage paragraphsForward:self.insertionPoint count:motion.count option:MOPT_PARA_BOUND_BLANKLINE];
            
            if(starts_end != end){
                start = starts_end;
            }
            range = NSMakeRange(start, end - start);
            break;
        case TEXTOBJECT_PARENTHESES:
            range = xv_current_block([self xvim_string], current, motion.count, !(motion.option & TEXTOBJECT_INNER), '(', ')');
            break;
        case TEXTOBJECT_SENTENCE:
            // Not supported
            break;
        case TEXTOBJECT_ANGLEBRACKETS:
            range = xv_current_block([self xvim_string], current, motion.count, !(motion.option & TEXTOBJECT_INNER), '<', '>');
            break;
        case TEXTOBJECT_SQUOTE:
            range = xv_current_quote([self xvim_string], current, motion.count, !(motion.option & TEXTOBJECT_INNER), '\'');
            break;
        case TEXTOBJECT_DQUOTE:
            range = xv_current_quote([self xvim_string], current, motion.count, !(motion.option & TEXTOBJECT_INNER), '\"');
            break;
        case TEXTOBJECT_TAG:
            // Not supported
            break;
        case TEXTOBJECT_BACKQUOTE:
            range = xv_current_quote([self xvim_string], current, motion.count, !(motion.option & TEXTOBJECT_INNER), '`');
            break;
        case TEXTOBJECT_SQUAREBRACKETS:
            range = xv_current_block([self xvim_string], current, motion.count, !(motion.option & TEXTOBJECT_INNER), '[', ']');
            break;
        case MOTION_LINE_COLUMN:
            end = [self.textStorage xvim_indexOfLineNumber:motion.line column:motion.column];
            if( NSNotFound == end ){
                end = current;
            }
            break;
        case MOTION_POSITION:
        case MOTION_POSITION_JUMP:
            end = motion.position;
            break;
    }
    
    if( range.location != NSNotFound ){// This block is for TEXTOBJECT
        begin = range.location;
        if( range.length == 0 ){
            end = NSNotFound;
        }else{
            end = range.location + range.length - 1;
        }
    }
    XVimRange r = XVimMakeRange(begin, end);
    TRACE_LOG(@"range location:%u  length:%u", r.begin, r.end - r.begin + 1);
    return r;
}

- (NSRange)xvim_getOperationRangeFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type {
    if( [[self xvim_string] length] == 0 ){
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



- (XVimPosition)insertionPosition{
    return XVimMakePosition(self.insertionLine, self.insertionColumn);
}

- (void)setInsertionPosition:(XVimPosition)pos{
    // Not implemented yet (Just update corresponding insertionPoint)
}

- (NSUInteger)insertionColumn{
    return self.sourceCodeEditorView.accessibilityColumnIndexRange.location;
}

- (NSUInteger)insertionLine{
    return [self.textStorage xvim_lineNumberAtIndex:self.insertionPoint];
}


- (XVimPosition)selectionBeginPosition{
    return XVimMakePosition([self.textStorage xvim_lineNumberAtIndex:self.selectionBegin], [self.textStorage xvim_columnOfIndex:self.selectionBegin]);
}

- (NSUInteger)numberOfSelectedLines{
    if (XVIM_VISUAL_NONE == self.selectionMode) {
        return 0;
    }
    XVimRange lines = [self _xvim_selectedLines];
    return lines.end - lines.begin + 1;
}


- (void)setSelectionMode:(XVIM_VISUAL_MODE)selectionMode{
    if (_selectionMode != selectionMode) {
        self.selectionToEOL = NO;
        _selectionMode = selectionMode;
    }
}

- (NSURL*)documentURL{
    if( [self.sourceCodeEditorView.hostingEditor isKindOfClass:NSClassFromString(@"IDEEditor")] ){
        return [(IDEEditorDocument*)((IDEEditor*)self.sourceCodeEditorView.hostingEditor).document fileURL];
    }else{
        return nil;
    }
    
}


- (long long)currentLineNumber {
    return [self.sourceCodeEditorView accessibilityInsertionPointLineNumber];
}

-(CURSOR_MODE)cursorMode
{
    return self.cursorStyle == CursorStyleVerticalBar ? CURSOR_MODE_INSERT : CURSOR_MODE_COMMAND;
}

-(void)setCursorMode:(CURSOR_MODE)cursorMode
{
    self.cursorStyle = ( cursorMode == CURSOR_MODE_INSERT ) ? CursorStyleVerticalBar : CursorStyleBlock;
}

- (NSString*)xvim_string{
    return [self.textStorage xvim_string];
}

#pragma mark Status

- (NSUInteger)xvim_numberOfLinesInVisibleRect{
    return self.sourceCodeEditorView.linesPerPage;
}

- (NSUInteger)xvim_displayNextLine:(NSUInteger)index column:(NSUInteger)column count:(NSUInteger)count option:(MOTION_OPTION)opt{
    for( NSUInteger i = 0 ; i < count ; i++ ){
        [self.sourceCodeEditorView moveDown:self];
    }
    // TODO
    return [self.sourceCodeEditorView characterRangeForLineRange:NSMakeRange(self.sourceCodeEditorView.accessibilityInsertionPointLineNumber, 1)].location
            + self.sourceCodeEditorView.accessibilityColumnIndexRange.location;
}

- (NSUInteger)xvim_displayPrevLine:(NSUInteger)index column:(NSUInteger)column count:(NSUInteger)count option:(MOTION_OPTION)opt{
    for( NSUInteger i = 0 ; i < count ; i++ ){
        [self.sourceCodeEditorView moveUp:self];
    }
    // TODO
    return [self.sourceCodeEditorView characterRangeForLineRange:NSMakeRange(self.sourceCodeEditorView.accessibilityInsertionPointLineNumber, 1)].location
    + self.sourceCodeEditorView.accessibilityColumnIndexRange.location;

}

@end
