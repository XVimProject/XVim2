//
//  Utils.h
//  XVim
//
//  Created by Suzuki Shuichiro on 2/16/13.
//
//

#import <Foundation/Foundation.h>

// Following utils are for non fliped coordinate system
NS_INLINE NSPoint RightBottom(NSRect r) { return NSMakePoint(r.origin.x + r.size.width, r.origin.y); }
NS_INLINE NSPoint LeftTop(NSRect r) { return NSMakePoint(r.origin.x, r.origin.y + r.size.height); }
NS_INLINE NSPoint RightTop(NSRect r) { return NSMakePoint(r.origin.x + r.size.width, r.origin.y + r.size.height); }
