/*-
 * Copyright (c) 2011 Ryota Hayashi
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR(S) ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR(S) BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * $FreeBSD$
 */


#import "HRColorInfoView.h"

const CGFloat kHRColorInfoViewLabelHeight = 22.0;
const CGFloat kHRColorInfoViewCornerRadius = 3.0;

@interface HRColorInfoView () {
    UIColor *_color;
}
@end

@implementation HRColorInfoView {
    UITextField *_hexColorTextField;
    CALayer *_borderLayer;
}

@synthesize color = _color;
@synthesize pickerView;

- (id)init {
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self _init];
    }
    return self;
}

- (void)_init {
    self.backgroundColor = [UIColor clearColor];
    UIColor *textColor = [UIColor colorWithWhite:0.5 alpha:1];;
    _hexColorTextField = [[UITextField alloc] init];
    _hexColorTextField.backgroundColor = [UIColor clearColor];
    _hexColorTextField.font = [UIFont systemFontOfSize:12];
    _hexColorTextField.textColor = textColor;
    _hexColorTextField.textAlignment = NSTextAlignmentCenter;
    _hexColorTextField.delegate = self;
    _hexColorTextField.tintColor = textColor;

    [self addSubview:_hexColorTextField];

    _borderLayer = [[CALayer alloc] initWithLayer:self.layer];
    _borderLayer.cornerRadius = kHRColorInfoViewCornerRadius;
    _borderLayer.borderColor = [[UIColor lightGrayColor] CGColor];
    _borderLayer.borderWidth = 1.f / [[UIScreen mainScreen] scale];
    [self.layer addSublayer:_borderLayer];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    _hexColorTextField.frame = CGRectMake(
            0,
            CGRectGetHeight(self.frame) - kHRColorInfoViewLabelHeight,
            CGRectGetWidth(self.frame),
            kHRColorInfoViewLabelHeight);

    _borderLayer.frame = (CGRect) {.origin = CGPointZero, .size = self.frame.size};
}

- (void)setColor:(UIColor *)color {
    _color = color;
    CGFloat r, g, b, a;
    [_color getRed:&r green:&g blue:&b alpha:&a];
    int rgb = (int) (r * 255.0f)<<16 | (int) (g * 255.0f)<<8 | (int) (b * 255.0f)<<0;
    _hexColorTextField.text = [NSString stringWithFormat:@"#%06x", rgb];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGRect colorRect = CGRectMake(0, 0, CGRectGetWidth(rect), CGRectGetHeight(rect) - kHRColorInfoViewLabelHeight);

    UIBezierPath *rectanglePath = [UIBezierPath bezierPathWithRoundedRect:colorRect byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(4, 4)];
    [rectanglePath closePath];
    [self.color setFill];
    [rectanglePath fill];
}

- (UIView *)viewForBaselineLayout {
    return _hexColorTextField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSString *str = textField.text;
    if (!str)
        return;
    NSInteger charsToAdd = 7 - str.length;
    if (charsToAdd < 0) {
        NSAssert(false, @"err");
        return;
    }
    const unichar zeros[] = {'0','0','0','0','0','0','0'};
    NSString *add = [NSString stringWithCharacters:zeros length:charsToAdd];
    str = [str stringByAppendingString:add];
    
    if (str.length != 7) {
        NSAssert(false, @"err");
        return;
    }
    
    unsigned int red = 0;
    unsigned int green = 0;
    unsigned int blue = 0;
    
    NSScanner *redScanner = [NSScanner scannerWithString:[str substringWithRange:NSMakeRange(1, 2)]];
    NSScanner *greenScanner = [NSScanner scannerWithString:[str substringWithRange:NSMakeRange(3, 2)]];
    NSScanner *blueScanner = [NSScanner scannerWithString:[str substringWithRange:NSMakeRange(5, 2)]];
    [redScanner scanHexInt:&red];
    [greenScanner scanHexInt:&green];
    [blueScanner scanHexInt:&blue];

    UIColor *color = [UIColor colorWithRed:((CGFloat)red / 255.0) green:((CGFloat)green / 255.0) blue:((CGFloat)blue / 255.0) alpha:1];
    self.color = color;
    self.pickerView.color = color;
    [self.pickerView sendActions];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (range.location == 0) {
        return NO; // cannot delete #
    }
    NSString *str = textField.text;
    if (!str) {
        return NO;
    }
    if ([str characterAtIndex:0] != '#') {
        return NO;
    }
    
    NSString *newstr = [str stringByReplacingCharactersInRange:range withString:string];
    if (newstr.length > 7) {
        return NO;
    }
    NSCharacterSet* notAllowed = [[NSCharacterSet characterSetWithCharactersInString:@"#0123456789aAbBcCdDeEfF"] invertedSet];
    if ([newstr rangeOfCharacterFromSet:notAllowed].location != NSNotFound) {
        return NO;
    }
    return YES;
}

@end

