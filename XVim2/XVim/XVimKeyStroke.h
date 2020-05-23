//
//  XVimKeyStroke.h
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#include "XVimDefs.h"

NS_ASSUME_NONNULL_BEGIN

#define KS_MODIFIER 0xF8 // This value is not the same as Vim's one
// Following values are differed from Vim's definition in keymap.h
typedef NS_OPTIONS(NSUInteger, XVimModifier) {
    XVIM_MOD_SHIFT = 1 << 1,
    XVIM_MOD_CTRL = 1 << 2,
    XVIM_MOD_ALT = 1 << 3,
    XVIM_MOD_CMD = 1 << 4,
    XVIM_MOD_FUNC = 1 << 7  // XVim Original
};

#define XVimMakeKeyCode(modifier, character) ((modifier << 16) | character)


@class XVimKeyStroke;
typedef uint32_t XVimKeyCode;

// Helper Functions
XVimString* XVimStringFromKeyNotation(NSString* notation);
XVimString* XVimStringFromKeyStrokes(NSArray<XVimKeyStroke*>* strokes);
NSArray<XVimKeyStroke*>* XVimKeyStrokesFromXVimString(XVimString* string);
NSArray<XVimKeyStroke*>* XVimKeyStrokesFromKeyNotation(NSString* notation);
NSString* XVimKeyNotationFromXVimString(XVimString* string);

@interface NSEvent (XVimKeyStroke)
- (XVimKeyStroke*)toXVimKeyStroke;
- (XVimString*)toXVimString;
@end

@interface XVimKeyStroke : NSObject <NSCopying>
@property unichar character;
@property unsigned char modifier;
@property NSEvent* event;
@property (nonatomic, readonly) BOOL isNumeric;
@property (nonatomic, readonly) BOOL isPrintable;
@property (nonatomic, readonly) BOOL isWhitespace;

- (id)initWithCharacter:(unichar)c modifier:(unsigned char)mod event:(nullable NSEvent*)e;

- (XVimString*)xvimString;

// Generates an event from this key stroke
- (NSEvent*)toEvent;

// Creates a human-readable string
- (NSString*)keyNotation;

// Returns the selector for this object
- (SEL)selector;
- (XVimKeyCode)keycode;

// Following methods are for to be a key in NSDictionary
- (NSUInteger)hash;
- (BOOL)isEqual:(id)object;
- (id)copyWithZone:(nullable NSZone*)zone;

- (BOOL)isCTRLModifier;
- (NSEvent*)toEventwithWindowNumber:(NSInteger)num context:(nullable NSGraphicsContext*)context;
@end

NS_ASSUME_NONNULL_END
