//
//  XVim.m
//  XVim2
//
//  Created by Shuichiro Suzuki on 8/26/17.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "XVim.h"
#import "Logger.h"
#import "Xcode/_TtC22IDEPegasusSourceEditor20SourceCodeEditorView.h"

@implementation XVim

// For reverse engineering purpose.
+(void)receiveNotification:(NSNotification*)notification{
    if( [notification.name hasPrefix:@"IDE"] || [notification.name hasPrefix:@"DVT"] ){
        TRACE_LOG(@"Got notification name : %@    object : %@", notification.name, NSStringFromClass([[notification object] class]));
    }
}

+ (void) load{
    NSBundle* app = [NSBundle mainBundle];
    NSString* identifier = [app bundleIdentifier];
    
    // Load only into Xcode
    if( ![identifier isEqualToString:@"com.apple.dt.Xcode"] ){
        return;
    }
    
    // Entry Point of the Plugin.
    [Logger defaultLogger].level = LogTrace;

    [_TtC22IDEPegasusSourceEditor20SourceCodeEditorView xvim_hook];
}
@end
