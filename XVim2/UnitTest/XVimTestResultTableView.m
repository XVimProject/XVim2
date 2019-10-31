//
//  XVimTestResultTableView.m
//  XVim2
//
//  Created by pebble8888 on 2019/10/31.
//  Copyright © 2019 Shuichiro Suzuki. All rights reserved.
//

#import "XVimTestResultTableView.h"

@implementation XVimTestResultTableView

- (void)copy:(id)sender
{
    let pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    let row = [self selectedRow];
    let testCase = [self.testResultDelegate objectAtIndex:row];
    [pasteboard writeObjects:@[testCase.description]];
}

@end
