//
//  XVimMotionOption.h
//  XVim
//
//  Created by Tomas Lundell on 10/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimDefs.h"

typedef NS_OPTIONS(NSUInteger, MOTION_OPTION) {
    MOPT_NONE = 0x00,
    MOPT_LEFT_RIGHT_WRAP = 0x01,
    MOPT_LEFT_RIGHT_NOWRAP = 0x02,
    MOPT_BIGWORD = 0x04, // for 'WORD' motion
    MOPT_DISPLAY_LINE = 0x08, // for gj, gk
    MOPT_PARA_BOUND_BLANKLINE = 0x10,
    MOPT_TEXTOBJECT_INNER = 0x20,
    MOPT_SEARCH_WRAP = 0x40,
    MOPT_SEARCH_CASEINSENSITIVE = 0x80,
    MOPT_CHANGE_WORD = 0x100, // for 'cw','cW'
    MOPT_SKIP_ADJACENT_CHAR = 0x200, // for repeating t motion
    MOPT_PLACEHOLDER = 0x400,
    /* Custom for Dervish Software */
    MOPT_EXTEND_SELECTION = 0x800,
};
