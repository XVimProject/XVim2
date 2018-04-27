//
//  XVimKeyStroke.h
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>


#define KS_MODIFIER 0xF8 // This value is not the same as Vim's one
// Following values are differed from Vim's definition in keymap.h
#define XVIM_MOD_SHIFT 0x02 //  1 << 1
#define XVIM_MOD_CTRL 0x04 //  1 << 2
#define XVIM_MOD_ALT 0x08 //  1 << 3
#define XVIM_MOD_CMD 0x10 //  1 << 4
#define XVIM_MOD_FUNC 0x80 //  1 << 7  // XVim Original

#define XVimMakeKeyCode(modifier, character) ((modifier << 16) | character)


@class XVimKeyStroke;
typedef uint32_t XVimKeyCode;
typedef NSString XVimString;
typedef NSMutableString XVimMutableString;

// Helper Functions
XVimString* XVimStringFromKeyNotation(NSString* notation);
XVimString* XVimStringFromKeyStrokes(NSArray* strokes);
NSArray* XVimKeyStrokesFromXVimString(XVimString* string);
NSArray* XVimKeyStrokesFromKeyNotation(NSString* notation);
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

- (id)initWithCharacter:(unichar)c modifier:(unsigned char)mod event:(NSEvent*)e;

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
- (id)copyWithZone:(NSZone*)zone;

- (BOOL)isCTRLModifier;
- (NSEvent*)toEventwithWindowNumber:(NSInteger)num context:(NSGraphicsContext*)context;
@end
