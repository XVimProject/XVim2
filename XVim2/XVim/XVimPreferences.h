//
//  XVimPreferences.h
//  XVim2
//
//  Created by Ant on 01/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PREF_DECL(_key) extern NSString* XVimPref_##_key;

PREF_DECL(StartOfLine);
PREF_DECL(AlwaysUseInputSource);
