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

+ (NSDictionary *)menuBarAttributesWithBold:(BOOL)useBold alpha:(CGFloat)alpha highlight:(BOOL)highlight
{
    NSFont *font = [NSFont menuFontOfSize:12];

    if (useBold) {
        font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];
    }
    
    NSColor *color = [NSColor colorWithDeviceWhite:(highlight) ? 1.0 : 0.0 alpha:alpha];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            font, NSFontAttributeName,
            color, NSForegroundColorAttributeName,
            nil];
}

+ (NSAttributedString *)attributedStringWithString:(NSString *)str attributes:(NSDictionary *)attrs
{
    return [[[NSAttributedString alloc] initWithString:str attributes:attrs] autorelease];
}

+ (NSAttributedString *)plainAttributedStringForMenuBar:(NSString *)str withHighlight:(BOOL)highlight
{
    return [NSAttributedString attributedStringWithString:str
                                               attributes:[self menuBarAttributesWithBold:NO
                                                                                    alpha:1.0
                                                                                highlight:highlight]];
}

+ (NSAttributedString *)boldAttributedStringForMenuBar:(NSString *)str withHighlight:(BOOL)highlight
{
    return [NSAttributedString attributedStringWithString:str
                                               attributes:[self menuBarAttributesWithBold:YES
                                                                                    alpha:1.0
                                                                                highlight:highlight]];
}

+ (NSAttributedString *)lightAttributedStringForMenuBar:(NSString *)str withHighlight:(BOOL)highlight
{
    return [NSAttributedString attributedStringWithString:str
                                               attributes:[self menuBarAttributesWithBold:NO
                                                                                    alpha:0.6
                                                                                highlight:highlight]];
}


@end
