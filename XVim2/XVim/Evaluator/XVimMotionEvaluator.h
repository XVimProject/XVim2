//
//  XVimMotionEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimEvaluator.h"
#import "XVimMotion.h"
#import "XVimNumericEvaluator.h"

@class XVimMark;

// This evaluator handles motions.
// Make subclass of this to implement operation on which takes motions as argument (deletion,yank...and so on.)

@interface XVimMotionEvaluator : XVimNumericEvaluator
@property (strong) XVimMotion* motion;

- (XVimEvaluator*)commonMotion:(SEL)motion Type:(MOTION_TYPE)type;

/**
 * The difference between motionFixed and _motionFixed:
 * _motionFixed is called internaly from its inherited classes.
 * After _motionFixed method does some common conversion to the motion or commmon operation
 * it calls motionFixed method with the converted motion.
 * So mainly you have to implement motionFixed method to delete/yanking or other operation with a motion.
 * If you want to implement new motion for a input you implement a selector for the input
 * and should call _motionFixed with the newly created motion.
 **/
// Override this method to implement operations on motions.
- (XVimEvaluator*)motionFixed:(XVimMotion*)motion;

// Do not override this method
- (XVimEvaluator*)_motionFixed:(XVimMotion*)motion;

- (XVimEvaluator*)jumpToMark:(XVimMark*)mark
                  firstOfLine:(BOOL)fol
            KeepJumpMarkIndex:(BOOL)keepJumpMarkIndex
               NeedUpdateMark:(BOOL)needUpdateMark;

// These are only for surpress warning

- (XVimEvaluator*)f;
- (XVimEvaluator*)F;
//- (XVimEvaluator*)C_f;
- (XVimEvaluator*)g;
- (XVimEvaluator*)G;
- (XVimEvaluator*)h;
- (XVimEvaluator*)H;
- (XVimEvaluator*)j;
- (XVimEvaluator*)J;
- (XVimEvaluator*)k;
- (XVimEvaluator*)K;
- (XVimEvaluator*)l;
- (XVimEvaluator*)L;
- (XVimEvaluator*)M;
//- (XVimEvaluator*)n;
//- (XVimEvaluator*)N;
//- (XVimEvaluator*)C_u;
- (XVimEvaluator*)t;
- (XVimEvaluator*)T;
- (XVimEvaluator*)v;
- (XVimEvaluator*)V;
- (XVimEvaluator*)C_v;
- (XVimEvaluator*)w;
- (XVimEvaluator*)W;
- (XVimEvaluator*)NUM0;
//- (XVimEvaluator*)z;
//- (XVimEvaluator*)ASTERISK;
//- (XVimEvaluator*)NUMBER;
//- (XVimEvaluator*)SQUOTE;
//- (XVimEvaluator*)BACKQUOTE;
- (XVimEvaluator*)CARET;
- (XVimEvaluator*)DOLLAR;
//- (XVimEvaluator*)UNDERSCORE;
- (XVimEvaluator*)PERCENT;
- (XVimEvaluator*)SPACE;
- (XVimEvaluator*)BS;
- (XVimEvaluator*)PLUS;
- (XVimEvaluator*)CR;
- (XVimEvaluator*)MINUS;
- (XVimEvaluator*)LSQUAREBRACKET;
- (XVimEvaluator*)RSQUAREBRACKET;
- (XVimEvaluator*)LBRACE;
- (XVimEvaluator*)RBRACE;
- (XVimEvaluator*)LPARENTHESIS;
- (XVimEvaluator*)RPARENTHESIS;
- (XVimEvaluator*)COMMA;
- (XVimEvaluator*)SEMICOLON;
//- (XVimEvaluator*)QUESTION;
//- (XVimEvaluator*)SLASH;
- (XVimEvaluator*)Up;
- (XVimEvaluator*)Down;
- (XVimEvaluator*)Left;
- (XVimEvaluator*)Right;
//-(XVimEvaluator*)Home;
//-(XVimEvaluator*)End;
@end
