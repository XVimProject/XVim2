//
//  ViewRecursion.m
//  XVim2
//
//  Created by Kent Robin Haugen on 14/11/2020.
//  Copyright © 2020 Shuichiro Suzuki. All rights reserved.
//

#import "NSView+ViewRecursion.h"

@implementation NSView (ViewRecursion)

- (NSMutableArray*)allSubViews
{
   NSMutableArray *arr=[[NSMutableArray alloc] init];
   [arr addObject:self];
   for (NSView *subview in self.subviews)
   {
       [arr addObjectsFromArray:(NSArray*)[subview allSubViews]];
   }
   return arr;
}

@end
