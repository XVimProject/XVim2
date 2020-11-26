//
//  ViewRecursion.h
//  XVim2
//
//  Created by Kent Robin Haugen on 14/11/2020.
//  Copyright © 2020 Shuichiro Suzuki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSView (ViewRecursion )
- (NSMutableArray*) allSubViews;
@end
