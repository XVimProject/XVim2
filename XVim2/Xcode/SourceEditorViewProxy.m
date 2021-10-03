//
//  SourceEditorProxy.m
//  XVim2
//
//  Created by Anthony Dervish on 16/09/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "SourceEditorViewProxy.h"
#import "NSString+VimHelper.h"
#import "NSTextStorage+VimOperation.h"
#import "XVim.h"
#import "XVimCommandLine.h"
#import "XVimOptions.h"
#import "XVimWindow.h"
#import "XVim2-Swift.h"

#import "rd_route.h"
#import <IDEKit/IDEEditorArea.h>
#import "XcodeUtils.h"
#import <SourceEditor/SourceEditorScrollView.h>
#import "SourceEditorViewProxy+XVim.h"

#import <IDESourceEditor/_TtC15IDESourceEditor18SourceCodeDocument.h>
#import <IDESourceEditor/_TtC15IDESourceEditor19IDESourceEditorView.h>
#import "_TtC15IDESourceEditor19IDESourceEditorView+XVim.h"
#import <SourceEditor/_TtC12SourceEditor16SourceEditorView.h>
#import "_TtC12SourceEditor16SourceEditorView+XVim.h"
#import "XVimXcode.h"
#import <IDESourceEditor/_TtC15IDESourceEditor19IDESourceEditorView-IDESourceEditor.h>
//#import <IDESourceEditor/_TtC15IDESourceEditor19IDESourceEditorView-IDESourceEditor1.h>
//#import <IDESourceEditor/_TtC15IDESourceEditor19IDESourceEditorView-IDESourceEditor2.h>
//#import <IDESourceEditor/_TtC15IDESourceEditor19IDESourceEditorView-IDESourceEditor3.h>
//#import <IDESourceEditor/_TtC15IDESourceEditor19IDESourceEditorView-IDESourceEditor4.h>

@interface SourceEditorViewProxy ()
@property (weak) _TtC15IDESourceEditor19IDESourceEditorView* sourceEditorView;
@property NSLayoutConstraint* cmdLineBottomAnchor;
@property NSEdgeInsets originalScrollViewInsets;
@end

@implementation SourceEditorViewProxy {
    NSMutableArray<NSValue*>* _foundRanges;
    XVimCommandLine* _commandLine;
    BOOL _enabled;
}

- (void)haltScroll
{
    self.sourceEditorView.xvim_window.scrollHalt = YES;
}

- (void)restoreScroll
{
    self.sourceEditorView.xvim_window.scrollHalt = NO;
}

- (instancetype)initWithSourceEditorView:(_TtC15IDESourceEditor19IDESourceEditorView*)sourceEditorView
{
    self = [super init];
    if (self) {
        _enabled = NO;
        self.sourceEditorView = sourceEditorView;
        self.sourceEditorViewWrapper = [[SourceEditorViewWrapper alloc] initWithSourceEditorViewProxy:self];
    }
    return self;
}

- (void)setEnabled:(BOOL)enable
{
    if (enable != _enabled) {
        _enabled = enable;
        if (enable) {
            [self _enableAction];
        }
        else {
            [self _disableAction];
        }
    }
}

- (BOOL)isEnabled {
    return _enabled;
}

- (void)_enableAction
{
    self.originalCursorStyle = self.cursorStyle;
    self.selectionMode = XVIM_VISUAL_NONE;
    self.cursorMode = XVIM_CURSOR_MODE_COMMAND;
    [self showCommandLine];
    [self xvim_syncStateFromView];
}

- (void)_disableAction
{
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
    self.cursorStyle = self.originalCursorStyle;
    [self hideCommandLine];
}

- (SourceEditorDataSourceWrapper*)sourceEditorDataSourceWrapper
{
    return self.sourceEditorViewWrapper.dataSourceWrapper;
}

// NOTE: line ranges are zero-indexed
- (NSRange)lineRangeForCharacterRange:(NSRange)arg1
{
    return [self.sourceEditorView lineRangeForCharacterRange:arg1];
}
- (NSRange)characterRangeForLineRange:(NSRange)arg1
{
    return [self.sourceEditorView characterRangeForLineRange:arg1];
}
- (NSInteger)lineCount { return  self.sourceEditorDataSourceWrapper.lineCount; }
- (void)scrollRangeToVisible:(NSRange)arg1 { [self.sourceEditorView scrollRangeToVisible:arg1]; }

- (void)setCursorStyle:(CursorStyle)cursorStyle { self.sourceEditorViewWrapper.cursorStyle = cursorStyle; }

- (CursorStyle)cursorStyle { return self.sourceEditorViewWrapper.cursorStyle; }

- (BOOL)normalizeRange:(XVimSourceEditorRange*)rng
{
    if ((rng->pos1).line > (rng->pos2).line)
        xvim_swap((rng->pos1).line, (rng->pos2).line);
    if ((rng->pos1).col > (rng->pos2).col)
        xvim_swap((rng->pos1).col, (rng->pos2).col);
    clamp((rng->pos1).line, 0, self.lineCount - 1);
    clamp((rng->pos2).line, 0, self.lineCount - 1);

    // Special handling for cursor on first col of last row
    if ((rng->pos1).line == self.lineCount - 1 && (rng->pos2).line == self.lineCount - 1 && (rng->pos1).col == 0
        && (rng->pos2).col == 0)
        return YES;

    var rr = [self characterRangeForLineRange:NSMakeRange((rng->pos1).line, 1)];
    if (rr.location == NSNotFound)
        return NO;
    clamp((rng->pos1).col, 0, rr.length);
    if ((rng->pos2).line != (rng->pos1).line) {
        rr = [self characterRangeForLineRange:NSMakeRange((rng->pos2).line, 1)];
        if (rr.location == NSNotFound)
            return NO;
    }
    clamp((rng->pos2).col, 0, rr.length);
    return YES;
}

- (void)addSelectedRange:(XVimSourceEditorRange)rng modifiers:(XVimSelectionModifiers)modifiers
{
    //DEBUG_LOG(@"Add range: %@, modifiers: %lu", XVimSourceEditorRangeToString(rng), modifiers);
    [self.sourceEditorViewWrapper addSelectedRange:rng modifiers:modifiers];
}
- (void)setSelectedRange:(XVimSourceEditorRange)rng modifiers:(XVimSelectionModifiers)modifiers
{
    //DEBUG_LOG(@"Set range: %@, modifiers: %lu", XVimSourceEditorRangeToString(rng), modifiers);
    [self.sourceEditorViewWrapper setSelectedRange:rng modifiers:modifiers];
}

- (nullable id)dataSource { return [self.sourceEditorViewWrapper dataSource]; }

- (XVimSourceEditorPosition)positionFromIndex:(NSUInteger)idx lineHint:(NSUInteger)line
{
    return [self.sourceEditorDataSourceWrapper positionFromInternalCharOffset:idx lineHint:line];
}

- (NSUInteger)indexFromPosition:(XVimSourceEditorPosition)pos
{
    return [self.sourceEditorDataSourceWrapper internalCharOffsetFromPosition:pos];
}

- (_TtC12SourceEditor23SourceEditorUndoManager*)undoManager { return self.sourceEditorDataSourceWrapper.undoManager; }

- (void)beginEditTransaction { [self.sourceEditorDataSourceWrapper beginEditTransaction]; }

- (void)endEditTransaction { [self.sourceEditorDataSourceWrapper endEditTransaction]; }


- (void)keyDown:(NSEvent*)event { [self.sourceEditorView xvim_keyDown:event]; }

- (NSString*)string { return self.sourceEditorView.string; }

- (void)setString:(NSString*)string
{
    let scanner = [NSScanner scannerWithString:string];
    scanner.charactersToBeSkipped = [NSCharacterSet new];

    NSString* nextLine = nil;

    NSRange nextRng = NSMakeRange(0, self.string.length);

    self.xvim_lockSyncStateFromView = YES;
    xvim_on_exit {
        self.xvim_lockSyncStateFromView = NO;
    };

    while ([scanner scanUpToCharactersFromSet:NSCharacterSet.newlineCharacterSet intoString:&nextLine]) {
        if (!scanner.atEnd){
            scanner.scanLocation += 1;
        }
        [self insertText:nextLine replacementRange:nextRng];

        nextRng.location = self.string.length;
        nextRng.length = 0;
    }
    if (!scanner.atEnd) {
        [self insertText:[string substringFromIndex:scanner.scanLocation] replacementRange:nextRng];
    }
}

- (void)insertText:(id)string replacementRange:(NSRange)replacementRange
{
    [self haltScroll];
    [self.sourceEditorView insertText:string replacementRange:replacementRange];
    [self restoreScroll];
}

- (void)insertText:(NSString*)text {
    [self haltScroll];
    [self.sourceEditorView insertText:text];
    [self restoreScroll];
}

- (NSTextStorage*)textStorage
{
    return [[NSTextStorage alloc] initWithString:(self.string ?: @"")];
}

- (void)scrollPageBackward:(NSUInteger)numPages
{
    for (int i = 0; i < numPages; ++i){
        [self.sourceEditorView scrollPageUp:self];
    }
}

- (void)scrollPageForward:(NSUInteger)numPages
{
    for (int i = 0; i < numPages; ++i){
        [self.sourceEditorView scrollPageDown:self];
    }
}

- (void)interpretKeyEvents:(NSArray<NSEvent*>*)eventArray { [self.sourceEditorView interpretKeyEvents:eventArray]; }

#pragma mark-- NSTextInputClient

- (void)setSelectedRange:(NSRange)range { self.sourceEditorView.selectedTextRange = range; }

- (NSRange)selectedRange
{
    NSRange rng = self.sourceEditorView.selectedTextRange;

    // TODO: Work out why Xcode can return 'NSNotFound' for location
    if (rng.location == NSNotFound) {
        rng = NSMakeRange(0, 0);
    }
    return rng;
}

- (nullable NSAttributedString*)attributedSubstringForProposedRange:(NSRange)range
                                                        actualRange:(nullable NSRangePointer)actualRange
{
    return [self.sourceEditorView attributedSubstringForProposedRange:range actualRange:actualRange];
}

- (NSUInteger)characterIndexForPoint:(NSPoint)point { return [self.sourceEditorView characterIndexForPoint:point]; }

- (void)doCommandBySelector:(nonnull SEL)selector { [self.sourceEditorView doCommandBySelector:selector]; }

- (NSRect)firstRectForCharacterRange:(NSRange)range actualRange:(nullable NSRangePointer)actualRange
{
    return [self.sourceEditorView firstRectForCharacterRange:range actualRange:actualRange];
}

- (BOOL)hasMarkedText {
    return self.sourceEditorView.hasMarkedText;
}

- (NSRange)markedRange {
    return self.sourceEditorView.markedRange;
}

- (void)setMarkedText:(nonnull id)string selectedRange:(NSRange)selectedRange replacementRange:(NSRange)replacementRange
{
    [self.sourceEditorView setMarkedText:string selectedRange:selectedRange replacementRange:replacementRange];
}

- (void)unmarkText {
    [self.sourceEditorView unmarkText];
}

- (nonnull NSArray<NSAttributedStringKey>*)validAttributesForMarkedText
{
    return self.sourceEditorView.validAttributesForMarkedText;
}

#pragma mark-- selection

- (void)setSelectedRanges:(NSArray<NSValue*>*)ranges
                     affinity:(NSSelectionAffinity)affinity
               stillSelecting:(BOOL)stillSelectingFlag
{
    if (ranges.count == 0)
        return;

    if (ranges.count == 1) {
        let rng = ranges.firstObject.rangeValue;

        if (rng.length == 0) {
            self.sourceEditorView.selectedTextRange = rng;
            return;
        }

        let insertionPos = [self positionFromIndex:self.insertionPoint lineHint:0];
        XVimSourceEditorRange insertionRange = {.pos1 = insertionPos, .pos2 = insertionPos };
        [self setSelectedRange:insertionRange modifiers:0];
        let pos1 = [self positionFromIndex:rng.location lineHint:insertionPos.line];
        let pos2 = [self positionFromIndex:rng.location + rng.length lineHint:pos1.line];
        XVimSourceEditorRange selectionRange = {.pos1 = pos1, .pos2 = pos2 };
		[self setSelectedRange:selectionRange modifiers:SelectionModifierExtension];
    }
    else {
        let rangeItr = (affinity == NSSelectionAffinityUpstream) ? [ranges reverseObjectEnumerator] : ranges;
        let insertionPos = [self positionFromIndex:self.insertionPoint lineHint:0];
        let insertionLine = insertionPos.line;
        var lastLine = insertionLine;
        BOOL isFirst = YES;

        for (NSValue* val in rangeItr) {
            let rng = val.rangeValue;
            let pos1 = [self positionFromIndex:rng.location lineHint:lastLine];
            let pos2 = [self positionFromIndex:rng.location + rng.length lineHint:pos1.line];
            lastLine = pos2.line;

            XVimSourceEditorRange ser = {.pos1 = pos1, .pos2 = pos2 };
            BOOL isInsertionLine = (pos1.line == insertionLine);

            let selectionModifiers = isInsertionLine ? SelectionModifierDiscontiguous
                                                       : SelectionModifierDiscontiguous | SelectionModifierExtension;
            if (![self normalizeRange:&ser])
                continue;
			if (isFirst){
				[self setSelectedRange:ser modifiers:selectionModifiers];
			} else {
				[self addSelectedRange:ser modifiers:selectionModifiers];
			}
            isFirst = NO;
        }
    }
}

- (NSArray<NSValue*>*)selectedRanges
{
    // TODO
    return @[ [NSValue valueWithRange:self.selectedRange] ];
}

- (void)selectionChanged:(NSNotification*)changeNotification
{
    if (!self.xvim_lockSyncStateFromView) {
        /*
        DEBUG_LOG(@"SELECTION CHANGED from %@! Locked = %@", changeNotification.object,
                  self.xvim_lockSyncStateFromView ? @"YES" : @"NO");
         */
        [self xvim_syncStateFromView];
    }
}

- (void)setSelectionMode:(XVIM_VISUAL_MODE)selectionMode
{
    if (_selectionMode != selectionMode) {
        self.selectionToEOL = NO;
        _selectionMode = selectionMode;
    }
}

- (XVIM_CURSOR_MODE)cursorMode
{
    return self.cursorStyle == CursorStyleVerticalBar ? XVIM_CURSOR_MODE_INSERT : XVIM_CURSOR_MODE_COMMAND;
}

- (void)setCursorMode:(XVIM_CURSOR_MODE)cursorMode
{
    self.cursorStyle = (cursorMode == XVIM_CURSOR_MODE_INSERT) ? CursorStyleVerticalBar : CursorStyleBlock;
}

- (NSInteger)currentLineNumber
{
    let l = [self.sourceEditorView lineRangeForCharacterRange:self.sourceEditorView.selectedTextRange]
                           .location;
    return l == NSNotFound ? 1 : (NSInteger)l + 1;
}

- (XVimLocation)insertionLocation { return XVimMakeLocation(self.insertionLine, self.insertionColumn); }

- (NSUInteger)insertionColumn { return self.sourceEditorView.accessibilityColumnIndexRange.location; }

- (NSUInteger)insertionLine { return [self.textStorage xvim_lineNumberAtIndex:self.insertionPoint]; }

- (XVimLocation)selectionBeginLocation
{
    return XVimMakeLocation([self.textStorage xvim_lineNumberAtIndex:self.selectionBegin],
                            [self.textStorage xvim_columnOfIndex:self.selectionBegin]);
}

- (NSURL*)documentURL
{
    // XCODE93
#if 0
    if ([self.sourceEditorView.hostingEditor isKindOfClass:NSClassFromString(@"IDEEditor")]) {
        return [(IDEEditorDocument*)((IDEEditor*)self.sourceEditorView.hostingEditor).document fileURL];
    }
    else {
        return nil;
    }
#else
    IDEEditorArea* area = XVimLastActiveEditorArea();
    if (area != nil){
        if (area.primaryEditorDocument != nil){
            return area.primaryEditorDocument.readOnlyItemURL;
        }
    }
#endif
    return nil;
}

// Proxy methods

- (void)selectPreviousPlaceholder:(id)arg1 {
    [self.sourceEditorView selectPreviousPlaceholder:self];
}
- (void)selectNextPlaceholder:(id)arg1 {
    [self.sourceEditorView selectNextPlaceholder:self];
}
- (void)mouseExited:(id)sender { [self.sourceEditorView mouseExited:self]; }
- (void)mouseEntered:(id)sender { [self.sourceEditorView mouseEntered:self]; }
- (void)mouseMoved:(id)sender { [self.sourceEditorView mouseMoved:self]; }
- (void)rightMouseUp:(id)sender { [self.sourceEditorView rightMouseUp:self]; }
- (void)mouseUp:(id)sender { [self.sourceEditorView mouseUp:self]; }
- (void)mouseDragged:(id)sender { [self.sourceEditorView mouseDragged:self]; }
- (void)rightMouseDown:(id)sender { [self.sourceEditorView rightMouseDown:self]; }
- (void)mouseDown:(id)sender { [self.sourceEditorView mouseDown:self]; }
- (void)selectWord:(id)sender { [self.sourceEditorView selectWord:self]; }
- (void)selectLine:(id)sender { [self.sourceEditorView selectLine:self]; }
- (void)selectParagraph:(id)sender { [self.sourceEditorView selectParagraph:self]; }
- (void)selectAll:(id)sender { [self.sourceEditorView selectAll:self]; }
- (void)scrollToEndOfDocument:(id)sender { [self.sourceEditorView scrollToEndOfDocument:self]; }
- (void)scrollToBeginningOfDocument:(id)sender { [self.sourceEditorView scrollToBeginningOfDocument:self]; }
- (void)scrollLineDown:(id)sender { [self.sourceEditorView scrollLineDown:self]; }
- (void)scrollLineUp:(id)sender { [self.sourceEditorView scrollLineUp:self]; }
- (void)scrollPageDown:(id)sender { [self.sourceEditorView scrollPageDown:self]; }
- (void)scrollPageUp:(id)sender { [self.sourceEditorView scrollPageUp:self]; }
- (void)centerSelectionInVisibleArea:(id)sender { [self.sourceEditorView centerSelectionInVisibleArea:self]; }
- (void)pageUpAndModifySelection:(id)sender { [self.sourceEditorView pageUpAndModifySelection:self]; }
- (void)pageDownAndModifySelection:(id)sender { [self.sourceEditorView pageDownAndModifySelection:self]; }
- (void)pageUp:(id)sender { [self.sourceEditorView pageUp:self]; }
- (void)pageDown:(id)sender { [self.sourceEditorView pageDown:self]; }
- (void)moveToEndOfDocumentAndModifySelection:(id)sender { [self.sourceEditorView moveToEndOfDocumentAndModifySelection:self]; }
- (void)moveToBeginningOfDocumentAndModifySelection:(id)sender { [self.sourceEditorView moveToBeginningOfDocumentAndModifySelection:self]; }
- (void)moveToEndOfDocument:(id)sender { [self.sourceEditorView moveToEndOfDocument:self]; }
- (void)moveToBeginningOfDocument:(id)sender { [self.sourceEditorView moveToBeginningOfDocument:self]; }
- (void)moveParagraphBackwardAndModifySelection:(id)sender { [self.sourceEditorView moveParagraphBackwardAndModifySelection:self]; }
- (void)moveParagraphForwardAndModifySelection:(id)sender { [self.sourceEditorView moveParagraphForwardAndModifySelection:self]; }
- (void)moveToEndOfParagraphAndModifySelection:(id)sender { [self.sourceEditorView moveToEndOfParagraphAndModifySelection:self]; }
- (void)moveToBeginningOfParagraphAndModifySelection:(id)sender { [self.sourceEditorView moveToBeginningOfParagraphAndModifySelection:self]; }
- (void)moveToEndOfParagraph:(id)sender { [self.sourceEditorView moveToEndOfParagraph:self]; }
- (void)moveToBeginningOfParagraph:(id)sender { [self.sourceEditorView moveToBeginningOfParagraph:self]; }
- (void)moveToEndOfTextAndModifySelection:(id)sender {
    [self.sourceEditorView moveToEndOfTextAndModifySelection:self];
}
- (void)moveToEndOfText:(id)sender {
    [self.sourceEditorView moveToEndOfText:self];
}
- (void)moveToBeginningOfTextAndModifySelection:(id)sender {
    [self.sourceEditorView moveToBeginningOfTextAndModifySelection:self];
}
- (void)moveToBeginningOfText:(id)sender {
    [self.sourceEditorView moveToBeginningOfText:self];
}
- (void)moveToRightEndOfLineAndModifySelection:(id)sender { [self.sourceEditorView moveToRightEndOfLineAndModifySelection:self]; }
- (void)moveToLeftEndOfLineAndModifySelection:(id)sender { [self.sourceEditorView moveToLeftEndOfLineAndModifySelection:self]; }
- (void)moveToRightEndOfLine:(id)sender { [self.sourceEditorView moveToRightEndOfLine:self]; }
- (void)moveToLeftEndOfLine:(id)sender { [self.sourceEditorView moveToLeftEndOfLine:self]; }
- (void)moveToEndOfLineAndModifySelection:(id)sender { [self.sourceEditorView moveToEndOfLineAndModifySelection:self]; }
- (void)moveToBeginningOfLineAndModifySelection:(id)sender { [self.sourceEditorView moveToBeginningOfLineAndModifySelection:self]; }
- (void)moveToEndOfLine:(id)sender { [self.sourceEditorView moveToEndOfLine:self]; }
- (void)moveToBeginningOfLine:(id)sender { [self.sourceEditorView moveToBeginningOfLine:self]; }
- (void)moveExpressionBackwardAndModifySelection:(id)sender {
    [self.sourceEditorView moveExpressionBackwardAndModifySelection:self];
}
- (void)moveExpressionForwardAndModifySelection:(id)sender {
    [self.sourceEditorView moveExpressionForwardAndModifySelection:self];
}
- (void)moveExpressionBackward:(id)sender {
    [self.sourceEditorView moveExpressionBackward:self];
}
- (void)moveExpressionForward:(id)sender {
    [self.sourceEditorView moveExpressionForward:self];
}
- (void)moveSubWordBackwardAndModifySelection:(id)sender {
    [self.sourceEditorView moveSubWordBackwardAndModifySelection:self];
}
- (void)moveSubWordForwardAndModifySelection:(id)sender {
    [self.sourceEditorView moveSubWordForwardAndModifySelection:self];
}
- (void)moveSubWordBackward:(id)sender {
    [self.sourceEditorView moveSubWordBackward:self];
}
- (void)moveSubWordForward:(id)sender {
    [self.sourceEditorView moveSubWordForward:self];
}
- (void)moveWordLeftAndModifySelection:(id)sender { [self.sourceEditorView moveWordLeftAndModifySelection:self]; }
- (void)moveWordRightAndModifySelection:(id)sender { [self.sourceEditorView moveWordRightAndModifySelection:self]; }
- (void)moveWordLeft:(id)sender { [self.sourceEditorView moveWordLeft:self]; }
- (void)moveWordRight:(id)sender { [self.sourceEditorView moveWordRight:self]; }
- (void)moveWordBackwardAndModifySelection:(id)sender { [self.sourceEditorView moveWordBackwardAndModifySelection:self]; }
- (void)moveWordForwardAndModifySelection:(id)sender { [self.sourceEditorView moveWordForwardAndModifySelection:self]; }
- (void)moveWordBackward:(id)sender { [self.sourceEditorView moveWordBackward:self]; }
- (void)moveWordForward:(id)sender { [self.sourceEditorView moveWordForward:self]; }
- (void)moveDownAndModifySelection:(id)sender { [self.sourceEditorView moveDownAndModifySelection:self]; }
- (void)moveUpAndModifySelection:(id)sender { [self.sourceEditorView moveUpAndModifySelection:self]; }
- (void)moveDown:(id)sender { [self.sourceEditorView moveDown:self]; }
- (void)moveUp:(id)sender { [self.sourceEditorView moveUp:self]; }
- (void)moveLeftAndModifySelection:(id)sender { [self.sourceEditorView moveLeftAndModifySelection:self]; }
- (void)moveRightAndModifySelection:(id)sender { [self.sourceEditorView moveRightAndModifySelection:self]; }
- (void)moveLeft:(id)sender { [self.sourceEditorView moveLeft:self]; }
- (void)moveRight:(id)sender { [self.sourceEditorView moveRight:self]; }
- (void)moveBackwardAndModifySelection:(id)sender { [self.sourceEditorView moveBackwardAndModifySelection:self]; }
- (void)moveForwardAndModifySelection:(id)sender { [self.sourceEditorView moveForwardAndModifySelection:self]; }
- (void)moveBackward:(id)sender { [self.sourceEditorView moveBackward:self]; }
- (void)moveForward:(id)sender { [self.sourceEditorView moveForward:self]; }
- (void)unfoldAllComments:(id)sender { [self.sourceEditorView unfoldAllComments:self]; }
- (void)foldAllComments:(id)sender { [self.sourceEditorView foldAllComments:self]; }
- (void)unfoldAllMethods:(id)sender { [self.sourceEditorView unfoldAllMethods:self]; }
- (void)foldAllMethods:(id)sender { [self.sourceEditorView foldAllMethods:self]; }
- (void)unfoldAll:(id)sender { [self.sourceEditorView unfoldAll:self]; }
- (void)unfold:(id)sender { [self.sourceEditorView unfold:self]; }
- (void)fold:(id)sender { [self.sourceEditorView fold:self]; }
- (void)balance:(id)sender {
    [self.sourceEditorView balance:self];
}
- (void)selectStructure:(id)sender { [self.sourceEditorView selectStructure:self]; }
- (void)shiftRight:(id)sender {
    [self.sourceEditorView shiftRight:self];
}
- (void)shiftLeft:(id)sender {
    [self.sourceEditorView shiftLeft:self];
}
- (void)indentSelection:(id)sender {
    [self.sourceEditorView indentSelection:self];
}
- (void)moveCurrentLineDown:(id)sender {
    [self.sourceEditorView moveCurrentLineDown:self];
}
- (void)moveCurrentLineUp:(id)sender {
    [self.sourceEditorView moveCurrentLineUp:self];
}
- (void)complete:(id)sender { [self.sourceEditorView complete:self]; }
- (void)swapWithMark:(id)sender { [self.sourceEditorView swapWithMark:self]; }
- (void)selectToMark:(id)sender { [self.sourceEditorView selectToMark:self]; }
- (void)deleteToMark:(id)sender { [self.sourceEditorView deleteToMark:self]; }
- (void)setMark:(id)sender { [self.sourceEditorView setMark:self]; }
- (void)yankAndSelect:(id)sender { [self.sourceEditorView yankAndSelect:self]; }
- (void)yank:(id)sender { [self.sourceEditorView yank:self]; }
- (void)capitalizeWord:(id)sender { [self.sourceEditorView capitalizeWord:self]; }
- (void)lowercaseWord:(id)sender { [self.sourceEditorView lowercaseWord:self]; }
- (void)uppercaseWord:(id)sender { [self.sourceEditorView uppercaseWord:self]; }
- (void)transpose:(id)sender { [self.sourceEditorView transpose:self]; }
- (void)deleteToEndOfText:(id)sender {
    [self.sourceEditorView deleteToEndOfText:self];
}
- (void)deleteToBeginningOfText:(id)sender {
    [self.sourceEditorView deleteToBeginningOfText:self];
}
- (void)deleteToEndOfParagraph:(id)sender { [self.sourceEditorView deleteToEndOfParagraph:self]; }
- (void)deleteToBeginningOfParagraph:(id)sender { [self.sourceEditorView deleteToBeginningOfParagraph:self]; }
- (void)deleteToEndOfLine:(id)sender { [self.sourceEditorView deleteToEndOfLine:self]; }
- (void)deleteToBeginningOfLine:(id)sender { [self.sourceEditorView deleteToBeginningOfLine:self]; }
- (void)deleteExpressionBackward:(id)sender {
    [self.sourceEditorView deleteExpressionBackward:self];
}
- (void)deleteExpressionForward:(id)sender {
    [self.sourceEditorView deleteExpressionForward:self];
}
- (void)deleteSubWordBackward:(id)sender {
    [self.sourceEditorView deleteSubWordBackward:self];
}
- (void)deleteSubWordForward:(id)sender {
    [self.sourceEditorView deleteSubWordForward:self];
}
- (void)deleteWordBackward:(id)sender { [self.sourceEditorView deleteWordBackward:self]; }
- (void)deleteWordForward:(id)sender { [self.sourceEditorView deleteWordForward:self]; }
- (void)deleteBackwardByDecomposingPreviousCharacter:(id)sender { [self.sourceEditorView deleteBackwardByDecomposingPreviousCharacter:self]; }
- (void)deleteBackward:(id)sender { [self.sourceEditorView deleteBackward:self]; }
- (void)deleteForward:(id)sender { [self.sourceEditorView deleteForward:self]; }
- (void) delete:(id)sender {
    [self.sourceEditorView delete:self];
}
- (void)insertDoubleQuoteIgnoringSubstitution:(id)sender { [self.sourceEditorView insertDoubleQuoteIgnoringSubstitution:self]; }
- (void)insertSingleQuoteIgnoringSubstitution:(id)sender { [self.sourceEditorView insertSingleQuoteIgnoringSubstitution:self]; }
- (void)insertContainerBreak:(id)sender { [self.sourceEditorView insertContainerBreak:self]; }
- (void)insertLineBreak:(id)sender { [self.sourceEditorView insertLineBreak:self]; }
- (void)insertTabIgnoringFieldEditor:(id)sender { [self.sourceEditorView insertTabIgnoringFieldEditor:self]; }
- (void)insertNewlineIgnoringFieldEditor:(id)sender { [self.sourceEditorView insertNewlineIgnoringFieldEditor:self]; }
- (void)insertParagraphSeparator:(id)sender { [self.sourceEditorView insertParagraphSeparator:self]; }
- (void)insertNewline:(id)sender { [self.sourceEditorView insertNewline:self]; }
- (void)insertBacktab:(id)sender { [self.sourceEditorView insertBacktab:self]; }
- (void)insertTab:(id)sender { [self.sourceEditorView insertTab:self]; }
- (void)flagsChanged:(id)sender { [self.sourceEditorView flagsChanged:self]; }
- (void)concludeDragOperation:(id)sender { [self.sourceEditorView concludeDragOperation:self]; }
- (void)draggingExited:(id)sender { [self.sourceEditorView draggingExited:self]; }
- (void)pasteAsPlainText:(id)sender { [self.sourceEditorView pasteAsPlainText:self]; }
- (void)pasteAndPreserveFormatting:(id)sender { [self.sourceEditorView pasteAndPreserveFormatting:self]; }
- (void)paste:(id)sender { [self.sourceEditorView paste:self]; }
- (void)cut:(id)sender { [self.sourceEditorView cut:self]; }
- (void)copy:(id)sender { [self.sourceEditorView copy:self]; }
- (void)showFindIndicatorForRange:(NSRange)arg1 {
    [self.sourceEditorView showFindIndicatorForRange:arg1];
}
- (NSUInteger)characterIndexForInsertionAtPoint:(CGPoint)arg1 { return [self.sourceEditorView characterIndexForInsertionAtPoint:arg1]; }
- (NSRect)bounds { return self.sourceEditorView.bounds; }
- (NSRect)frame { return self.sourceEditorView.frame; }
- (NSSize)contentSize { return self.sourceEditorView.visibleTextRect.size; }
- (NSSize)sourceEditorViewSize { return self.sourceEditorView.bounds.size; }

- (XVimCommandLine*)commandLine
{
    if (nil == _commandLine) {
        _commandLine = [[XVimCommandLine alloc] init];
    }
    return _commandLine;
}
static CGFloat XvimCommandLineHeight = 20;
static CGFloat XvimCommandLineAnimationDuration = 0.1;
static CGFloat IDEKit_BottomBarViewHeight = 27;

- (BOOL)isShowingCommandLine { return self.commandLine.superview != nil; }

- (void)showCommandLine
{
    if (self.isShowingCommandLine)
        return;
    
    let scrollView = [self.sourceEditorView scrollView];
    if ([self.sourceEditorView.class isEqual:NSClassFromString(IDESourceEditorViewClassName)]) {
        NSView* layoutView = [scrollView superview];
        [layoutView addSubview:self.commandLine];
        _cmdLineBottomAnchor = [layoutView.bottomAnchor constraintEqualToAnchor:self.commandLine.bottomAnchor
                                                                       constant:0];
        _cmdLineBottomAnchor.active = YES;
        [layoutView.widthAnchor constraintEqualToAnchor:self.commandLine.widthAnchor multiplier:1.0].active = YES;
        [layoutView.leftAnchor constraintEqualToAnchor:self.commandLine.leftAnchor].active = YES;
        [layoutView.rightAnchor constraintEqualToAnchor:self.commandLine.rightAnchor].active = YES;
        CGFloat commandline_height;
        if ([XVim.instance.options.laststatus isEqualToString:@"0"]){
            commandline_height = 0;
        } else {
            commandline_height = 20;
        }
        let height = [self.commandLine.heightAnchor constraintEqualToConstant:commandline_height];
        height.priority = 250;
        height.active = YES;

        [NSAnimationContext runAnimationGroup:^(NSAnimationContext* _Nonnull context) {
            context.duration = XvimCommandLineAnimationDuration;
            NSEdgeInsets insets = scrollView.contentInsets;
            self->_originalScrollViewInsets = insets;
            self->_cmdLineBottomAnchor.animator.constant = IDEKit_BottomBarViewHeight;
            insets.bottom += XvimCommandLineHeight;
            scrollView.animator.contentInsets = insets;
            [scrollView setUpdatingAutoContentInsets:YES];
        } completionHandler:^{
            self.commandLine.needsDisplay = YES;
            // XVim added contentInsets.bottom value for command line bar will discard by Xcode
            // when add tab, change fullscreen state etc.
            // This observe is for re-add it.
            [scrollView addObserver:self forKeyPath:@"contentInsets" options:NSKeyValueObservingOptionNew context:nil];
        }];
    }
}

- (void)hideCommandLine
{
    if (!self.isShowingCommandLine)
        return;

    let scrollView = [self.sourceEditorView scrollView];
    if ([self.sourceEditorView.class isEqual:NSClassFromString(IDESourceEditorViewClassName)]) {
        [scrollView removeObserver:self forKeyPath:@"contentInsets"];
        NSEdgeInsets insets = scrollView.contentInsets;
        insets.bottom -= XvimCommandLineHeight;

        [NSAnimationContext runAnimationGroup:^(NSAnimationContext* _Nonnull context) {
            context.duration = XvimCommandLineAnimationDuration;
            self->_cmdLineBottomAnchor.animator.constant = -XvimCommandLineHeight;
            scrollView.animator.contentInsets = insets;
            [scrollView setUpdatingAutoContentInsets:YES];
        } completionHandler:^{
            [self.commandLine removeFromSuperview];
            self->_cmdLineBottomAnchor = nil;
            self->_originalScrollViewInsets = NSEdgeInsetsZero;
        }];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"contentInsets"]) {
        let scrollView = self.sourceEditorView.scrollView;
        NSEdgeInsets insets = scrollView.contentInsets;
        // NOTE: insets.bottom value sometimes 1pt difference to original.
        if (self.isShowingCommandLine && insets.bottom <= self->_originalScrollViewInsets.bottom + 1) {
            insets.bottom += XvimCommandLineHeight;
            scrollView.contentInsets = insets;
        }
    }
}

- (NSMutableArray<NSValue*>*)foundRanges
{
    if (_foundRanges == nil) {
        _foundRanges = [[NSMutableArray alloc] init];
    }
    return _foundRanges;
}

- (NSWindow*)window { return self.sourceEditorView.window; }
- (NSView*)view { return self.sourceEditorView; }

@synthesize originalCursorStyle;

@end
