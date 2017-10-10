//
//  XVimGEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 3/1/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimEvaluator.h"
#import "XVimKeyStroke.h"

@class XVimMotion;

@interface XVimGMotionEvaluator : XVimEvaluator
@property (strong) XVimMotion* motion;
@property (strong) XVimKeyStroke* key;
@end
