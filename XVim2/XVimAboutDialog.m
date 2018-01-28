//
//  XVimAboutDialog.m
//  XVim
//
//  Created by Suzuki Shuichiro on 12/31/15.
//
//

#import "XVimAboutDialog.h"
#import "../gitrevision.h"
#import "XVim.h"

@interface XVimAboutDialog ()

@end

@implementation XVimAboutDialog

- (NSString*)xvimInfo
{
    NSString* format = @"XVim2 revision : %@\n"
                       @"OS Version : %@\n"
                       @"Xcode Version : %@\n"
                       @"\n"
                       @"--- .xvimrc ---\n"
                       @"%@\n"
                       @"--------------\n";

    NSString* rc = [XVim xvimrc];
    if (nil == rc)
        rc = @"N/A";

    NSString* info = [NSString
                stringWithFormat:format, GIT_REVISION, [[NSProcessInfo processInfo] operatingSystemVersionString],
                                 [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                                 rc];

    return info;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its
    // nib file.
    [self.infoTextView setString:self.xvimInfo];
}

- (BOOL)windowShouldClose:(id)sender
{
    [[NSApplication sharedApplication] stopModal];
    return YES;
}

- (IBAction)onReportBug:(id)sender
{
    NSString* body = [NSString stringWithFormat:@"[Write issue description here]\n\n"
                                                @"```\n"
                                                @"-------- Debug Info -------\n"
                                                @"%@"
                                                @"```\n",
                                                self.infoTextView.string];
    NSString* urlencoded =
                [body stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString* url = [NSString stringWithFormat:@"https://github.com/XVimProject/XVim2/issues/new?body=%@", urlencoded];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

@end
