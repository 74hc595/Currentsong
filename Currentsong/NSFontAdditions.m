//
//  NSFontAdditions.m
//  Currentsong
//
//  Created by Matthew Sarnoff on 1/7/12.
//  Copyright 2012 Matt Sarnoff. All rights reserved.
//

#import "NSFontAdditions.h"

@implementation NSFont (NSFontAdditions)

// Creates a pseudo-italic font from one that doesn't support italic
// (like Lucida Grande)
// http://stackoverflow.com/questions/1724647/how-do-i-get-lucida-grande-italic-into-my-application
+ (NSFont *)italicFontFromFont:(NSFont *)font
{
    NSFontManager *sharedFontManager = [NSFontManager sharedFontManager];
    NSFont *newFont = [sharedFontManager convertFont:font toHaveTrait:NSItalicFontMask];
    
    // Did it work?
    NSFontTraitMask fontTraits = [sharedFontManager traitsOfFont:newFont];
    
    if (!((fontTraits & NSItalicFontMask) == NSItalicFontMask))
    {
        // If not, manually apply text transform
        CGFloat skew = -tanf(-10.0 * acosf(0) / 90);
        NSAffineTransform *fontTransform = [NSAffineTransform transform];           
        [fontTransform scaleBy:[newFont pointSize]];
        
        NSAffineTransform *italicTransform = [NSAffineTransform transform];
        NSAffineTransformStruct italicTransformData = {1, 0, skew, 1, 0, 0};
        [italicTransform setTransformStruct:italicTransformData];
        
        [fontTransform appendTransform:italicTransform];        
        newFont = [NSFont fontWithDescriptor:[newFont fontDescriptor] textTransform:fontTransform];
    }
    return newFont;
}

@end
