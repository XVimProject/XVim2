//
//  XVimMotion.m
//  XVim
//
//  Created by Suzuki Shuichiro on 9/25/12.
//
//

#import "XVimMotion.h"

@implementation XVimMotionInfo
- (id)init
{
    self = [super init];
    if (self){
        _reachedEndOfLine = NO;
        _isFirstWordInLine = NO;
        _deleteLastLine = NO;
        _lastEndOfLine = NSNotFound;
        _lastEndOfWord = NSNotFound;
    }
    return self;
}
@end

@implementation XVimMotion

- (BOOL)isJumpMotion
{
    switch (_style) {
    case MOTION_SENTENCE_FORWARD: // )
    case MOTION_SENTENCE_BACKWARD: // (
    case MOTION_PARAGRAPH_FORWARD: // }
    case MOTION_PARAGRAPH_BACKWARD: // {
    case MOTION_NEXT_MATCHED_ITEM: // %
    case MOTION_LINENUMBER: // [num]G
    case MOTION_PERCENT: // [num]%
    case MOTION_LASTLINE: // G
    case MOTION_HOME: // H
    case MOTION_MIDDLE: // M
    case MOTION_BOTTOM: // L
    case MOTION_SEARCH_FORWARD: // /
    case MOTION_SEARCH_BACKWARD: // ?
    case MOTION_POSITION_JUMP: // Custom position change for jump
        return YES;
    default:
        break;
    }
    return NO;
}

- (nonnull XVimMotion*)initWithStyle:(MOTION_STYLE)style type:(MOTION_TYPE)type option:(MOTION_OPTION)option count:(NSUInteger)count
{
    if (self = [super init]) {
        _style = style;
        _type = type;
        _option = option;
        _count = count;
        _regex = nil;
        _motionInfo = [[XVimMotionInfo alloc] init];
        _jumpToAnotherFile = NO;
        _keepJumpMarkIndex = NO;
    }
    return self;
}

- (nonnull XVimMotion*)initWithStyle:(MOTION_STYLE)style type:(MOTION_TYPE)type option:(MOTION_OPTION)option
{
    return [self initWithStyle:style type:type option:option count:1];
}

- (nonnull XVimMotion*)initWithStyle:(MOTION_STYLE)style type:(MOTION_TYPE)type count:(NSUInteger)count
{
    return [self initWithStyle:style type:type option:MOPT_NONE count:count];
}

+ (nonnull XVimMotion*)style:(MOTION_STYLE)style type:(MOTION_TYPE)type option:(MOTION_OPTION)option count:(NSUInteger)count
{
    return [[XVimMotion alloc] initWithStyle:style type:type option:option count:count];
}

+ (nonnull XVimMotion*)style:(MOTION_STYLE)style type:(MOTION_TYPE)type option:(MOTION_OPTION)option
{
    return [[XVimMotion alloc] initWithStyle:style type:type option:option];
}

+ (nonnull XVimMotion*)style:(MOTION_STYLE)style type:(MOTION_TYPE)type count:(NSUInteger)count
{
    return [[XVimMotion alloc] initWithStyle:style type:type count:count];
}

- (BOOL)isTextObject { return TEXTOBJECT_WORD <= self.style && self.style <= TEXTOBJECT_UNDERSCORE; }
+ (NSArray<NSString*>*)uncodablePropertyKeys { return @[ @"info" ]; }
- (NSString *)debugDescription {
	return [NSString stringWithFormat:@"style: %d type: %d option: %d count: %d line: %d column: %d position %d info %@",
			(int)_style, (int)_type, (int)_option, (int)_count, (int)_line, (int)_column, (int)_position, _motionInfo];
}
@end
