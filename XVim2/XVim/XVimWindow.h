//
//  XVimWindow.h
//  XVim
//
//  Created by Tomas Lundell on 9/04/12.
//

#import "XVimKeyStroke.h"
#import "XVimMotion.h"
@import Cocoa;

NS_ASSUME_NONNULL_BEGIN

/*
 * This class manages 1 window. (The term "window" here is different from NSWindow)
 * A window has several text views and one command line view.
 * All the key input (or mouse input or some other event if needed ) must be passed to
 * the associated XVimWindow object first and it handles the event.
 */
@class CommandResponder;
@class XVimEvaluator;
@class XVimMark;
@class XVimCommandLine;
@protocol SourceEditorViewProtocol;
@protocol SourceEditorViewControlProtocol;
@protocol SourceEditorViewOperationsProtocol;
@protocol SourceEditorViewScrollingProtocol;

@interface XVimWindow : NSObject <NSTextInputClient, NSTextFieldDelegate>
@property (readonly) id<SourceEditorViewProtocol, SourceEditorViewControlProtocol, SourceEditorViewScrollingProtocol, SourceEditorViewOperationsProtocol, NSTextInputClient> sourceView; // This represents currently focused sourceView
@property (weak, readonly) NSTextView* inputView;
@property (weak, readonly) XVimEvaluator* currentEvaluator;
@property (weak, readonly) CommandResponder* commandResponder;
@property (readonly) XVimCommandLine* commandLine;
@property (nonatomic, getter=isEnabled) BOOL enabled;
@property (nonatomic) XVimMark* currentPositionMark;
@property BOOL scrollHalt;

- (instancetype)initWithSourceView:(id<SourceEditorViewProtocol>)sourceView;
- (void)setupAfterEditorViewSetup;
- (void)handleKeyStroke:(XVimKeyStroke*)keyStroke onStack:(nullable NSMutableArray<XVimEvaluator*>*)stack;
- (BOOL)handleKeyEvent:(NSEvent*)event;
- (BOOL)shouldAutoCompleteAtLocation:(unsigned long long)location;
- (void)errorMessage:(NSString*)message ringBell:(BOOL)ringBell;
- (void)statusMessage:(NSString*)message;
- (void)clearErrorMessage;
- (void)beginCommandEntry;
- (void)endCommandEntry;
- (void)setForcusBackToSourceView;
- (void)syncEvaluatorStack;
- (void)preMotion:(XVimMotion*)motion;
@end

NS_ASSUME_NONNULL_END
