//
//  XVimAboutDialog.m
//  XVim
//
//  Created by Suzuki Shuichiro on 12/31/15.
//
//

#import "XVimAboutDialog.h"
#import "../../gitrevision.h"
#import "XVim.h"
#import <sys/types.h>
#import <sys/sysctl.h>

@interface XVimAboutDialog ()

@end

@implementation XVimAboutDialog

- (NSString*)xvimInfo
{
    NSString* format = @"XVim2 revision : %@\n"
                       @"OS Version : %@\n"
                       @"Xcode Version : %@\n"
                       @"Rosetta: %@\n"
                       @"\n"
                       @"--- .xvimrc ---\n"
                       @"%@\n"
                       @"--------------\n";

    NSString* rc = [XVim xvimrc];
    if (nil == rc)
        rc = @"N/A";

    NSString* info = [NSString stringWithFormat:format,
                      GIT_REVISION,
                      NSProcessInfo.processInfo.operatingSystemVersionString,
                      [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleShortVersionString"],
                      self.isRunningInRosetta ? @"YES" : @"NO",
                      rc];

    return info;
}

// https://developer.apple.com/videos/play/wwdc2020/10686/?time=870
- (BOOL)isRunningInRosetta
{
    int ret = 0;
    size_t size = sizeof(ret);
    // Call the sysctl and if successful return the result
    if (sysctlbyname("sysctl.proc_translated", &ret, &size, NULL, 0) != -1)
        return ret == 1;
    // If "sysctl.proc_translated" is not present then must be native
    if (errno == ENOENT)
        return NO;
    return NO;
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
    [NSApplication.sharedApplication stopModal];
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
                [body stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
    NSString* url = [NSString stringWithFormat:@"https://github.com/XVimProject/XVim2/issues/new?body=%@", urlencoded];
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:url]];
}

@end
