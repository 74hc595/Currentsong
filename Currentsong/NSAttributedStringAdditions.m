//
//  NSAttributedStringAdditions.m
//  Currentsong
//
//  Created by Matthew Sarnoff on 1/7/12.
//  Copyright 2012 Matt Sarnoff. All rights reserved.
//

#import "NSAttributedStringAdditions.h"
#import "NSFontAdditions.h"

@implementation NSAttributedString (NSAttributedStringAdditions)

+ (NSDictionary *)menuBarAttributesWithBold:(BOOL)useBold light:(BOOL)useLightColor
{
    NSFont *font = [NSFont menuFontOfSize:12];

    static NSShadow *shadow = nil;
    if (!shadow)
    {
        shadow = [[NSShadow alloc] init];
        [shadow setShadowColor:[NSColor colorWithDeviceWhite:1 alpha:0.25]];
        [shadow setShadowOffset:NSMakeSize(0, -1)];
        [shadow setShadowBlurRadius:0];
    }
    
    /*
    static NSFont *italicFont = nil;
    if (!italicFont) {
        italicFont = [NSFont italicFontFromFont:font];
    }
    
    if (useItalic) {
        font = italicFont;
    }
    */
    
    if (useBold) {
        font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];
    }
    
    NSColor *color = (useLightColor) ? [NSColor colorWithCalibratedWhite:0 alpha:0.6] : [NSColor blackColor];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            font, NSFontAttributeName,
            shadow, NSShadowAttributeName,
            color, NSForegroundColorAttributeName,
            nil];
}

+ (NSAttributedString *)attributedStringWithString:(NSString *)str attributes:(NSDictionary *)attrs
{
    return [[[NSAttributedString alloc] initWithString:str attributes:attrs] autorelease];
}

+ (NSAttributedString *)plainAttributedStringForMenuBar:(NSString *)str
{
    return [NSAttributedString attributedStringWithString:str
                                               attributes:[self menuBarAttributesWithBold:NO light:NO]];
}

+ (NSAttributedString *)boldAttributedStringForMenuBar:(NSString *)str
{
    return [NSAttributedString attributedStringWithString:str
                                               attributes:[self menuBarAttributesWithBold:YES light:NO]];
}

/*
+ (NSAttributedString *)italicAttributedStringForMenuBar:(NSString *)str
{
    return [NSAttributedString attributedStringWithString:str
                                               attributes:[self menuBarAttributesWithBold:NO italic:YES]];
}
*/

+ (NSAttributedString *)lightAttributedStringForMenuBar:(NSString *)str
{
    return [NSAttributedString attributedStringWithString:str
                                               attributes:[self menuBarAttributesWithBold:NO light:YES]];
}


@end
