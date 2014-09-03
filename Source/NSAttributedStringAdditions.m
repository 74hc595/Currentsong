//
//  NSAttributedStringAdditions.m
//  Currentsong
//
//  Created by Matthew Sarnoff on 1/7/12.
//  Copyright 2012 Matt Sarnoff. All rights reserved.
//

#import "NSAttributedStringAdditions.h"

@implementation NSAttributedString (NSAttributedStringAdditions)

+ (NSAttributedString *)attributedStringWithString:(NSString *)str attributes:(NSDictionary *)attrs
{
    return [[NSAttributedString alloc] initWithString:str attributes:attrs];
}

+ (NSAttributedString *)menuBarAttributedString:(NSString *)str attributes:(CurrentsongTextAttributeMask)attrs
{
    BOOL bold = (attrs & kCSBold);
    BOOL highlight = (attrs & kCSHighlighted);
    CGFloat fontSize = (attrs & kCSSmall) ? 9 : 12;
    CGFloat alpha = (attrs & kCSLight) ? 0.6 : 1.0;
    
    NSFont *font = [NSFont menuFontOfSize:fontSize];

    if (bold) {
        font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];
    }
    
    NSColor *color = [NSColor colorWithDeviceWhite:(highlight) ? 1.0 : 0.0 alpha:alpha];
    
    NSDictionary *attrsDict = @{NSFontAttributeName: font,
                               NSForegroundColorAttributeName: color};
    return [NSAttributedString attributedStringWithString:str attributes:attrsDict];
}

@end
