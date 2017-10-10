//
//  XVimCmdArg.m
//  XVim2
//
//  Created by Shuichiro Suzuki on 8/27/17.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "XVimCmdArg.h"

@implementation XVimCmdArg

- (id)init
{
    if (self = [super init]) {
        _args = [[NSMutableString alloc] init];
    }
    return self;
}
@end
