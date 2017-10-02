//
//  XVimPreferences.m
//  XVim2
//
//  Created by Ant on 01/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "XVimPreferences.h"

#define PREF_DEFN(_key) NSString* XVimPref_##_key = @"XVim" #_key;

PREF_DEFN(StartOfLine)
PREF_DEFN(AlwaysUseInputSource);
PREF_DEFN(ClipboardHasUnnamed);
