//
//  SourceEditorViewProxy+Scrolling.h
//  XVim2
//
//  Created by Ant on 02/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "SourceEditorViewProxy.h"
#import <Foundation/Foundation.h>

@interface SourceEditorViewProxy (Scrolling) <SourceViewScrollingProtocol>
@property (readonly) NSInteger linesPerPage;
@end
