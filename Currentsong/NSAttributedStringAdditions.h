//
//  NSAttributedStringAdditions.h
//  Currentsong
//
//  Created by Matthew Sarnoff on 1/7/12.
//  Copyright 2012 Matt Sarnoff. All rights reserved.
//
//  Methods to simplify creation of attributed strings for use in the menu bar.

#import <Foundation/Foundation.h>

@interface NSAttributedString (NSAttributedStringAdditions)

// Factory method that Cocoa doesn't provide
+ (NSAttributedString *)attributedStringWithString:(NSString *)str attributes:(NSDictionary *)attrs;

// Create formatted attributed strings from plain strings
+ (NSAttributedString *)plainAttributedStringForMenuBar:(NSString *)str;
+ (NSAttributedString *)boldAttributedStringForMenuBar:(NSString *)str;
+ (NSAttributedString *)lightAttributedStringForMenuBar:(NSString *)str;

@end
