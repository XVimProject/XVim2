//
//  XVimModifier.h
//  XVim2
//
//  Created by pebble8888 on 2020/05/24.
//  Copyright © 2020 Shuichiro Suzuki. All rights reserved.
//

#ifndef XVimModifier_h
#define XVimModifier_h

typedef NS_OPTIONS(NSUInteger, XVimModifier) {
    XVIM_MOD_SHIFT = 1 << 1,
    XVIM_MOD_CTRL = 1 << 2,
    XVIM_MOD_ALT = 1 << 3,
    XVIM_MOD_CMD = 1 << 4,
    XVIM_MOD_FUNC = 1 << 7  // XVim Original
};

#endif /* XVimModifier_h */
