//
//  XVimTest.h
//  XVim
//
//  Created by Suzuki Shuichiro on 8/18/12.
//
//

#import "XVimTestCase.h"
#import "XVimWindow.h"
#import <Foundation/Foundation.h>

@interface XVimTester : NSObject <NSTableViewDataSource, NSTableViewDelegate>

// Get all the caregory of tests
- (NSArray*)categories;

// Select test categories to run
- (void)selectCategories:(NSArray*)categories;

// Run tests
- (void)runTest;
@end

@class DVTTextPreferences;
DVTTextPreferences* XcodeTextPreferences(void);
