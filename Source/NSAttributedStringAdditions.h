//
//  NSAttributedStringAdditions.h
//  Currentsong
//
//  Created by Matthew Sarnoff on 1/7/12.
//  Copyright 2012 Matt Sarnoff. All rights reserved.
//
//  Methods to simplify creation of attributed strings for use in the menu bar.

#import <Foundation/Foundation.h>

enum
{
    kCSPlain        = 0,
    kCSHighlighted  = 1,
    kCSBold         = 2,
    kCSLight        = 4,
    kCSSmall        = 8
};
typedef NSInteger CurrentsongTextAttributeMask;

@interface NSAttributedString (NSAttributedStringAdditions)

// Factory method that Cocoa doesn't provide
+ (NSAttributedString *)attributedStringWithString:(NSString *)str attributes:(NSDictionary *)attrs;

// Create formatted attributed strings from plain strings
+ (NSAttributedString *)menuBarAttributedString:(NSString *)str attributes:(CurrentsongTextAttributeMask)attrs;

@end
