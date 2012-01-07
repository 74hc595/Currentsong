//
//  NSFontAdditions.h
//  Currentsong
//
//  Created by Matthew Sarnoff on 1/7/12.
//  Copyright 2012 Matt Sarnoff. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NSFont (NSFontAdditions)

// Creates a pseudo-italic font from one that doesn't support italic
// (like Lucida Grande)
+ (NSFont *)italicFontFromFont:(NSFont *)font;

@end
