//
//  MSDurationFormatter.m
//  Currentsong
//
//  Created by Matthew Sarnoff on 08/01/12.
//  Copyright 2012 Matt Sarnoff. All rights reserved.
//

#import "MSDurationFormatter.h"

@implementation MSDurationFormatter

// Localized time separator
static NSString *sSeparator = nil;

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Cocoa provides no way to access the localized time separator,
        // so extract them manually from the current locale
        // This doesn't support weirdos with custom date/time formats, but whatever
        NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:@"hhmmss" options:0 locale:[NSLocale currentLocale]];
        NSMutableCharacterSet *separatorChars = [NSMutableCharacterSet letterCharacterSet];
        [separatorChars formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
        [separatorChars invert];
        NSRange separatorRange = [dateFormat rangeOfCharacterFromSet:separatorChars];
        
        if (separatorRange.location != NSNotFound) {
            sSeparator = [dateFormat substringWithRange:separatorRange];
        } else {
            sSeparator = @":";
        }
    });
}

+ (NSString *)hoursMinutesSecondsFromSeconds:(NSInteger)seconds
{
    NSInteger hr = seconds / 3600;
    NSInteger min = (seconds / 60) % 60;
    NSInteger sec = seconds % 60;
    
    if (hr == 0) {
        return [NSString stringWithFormat:@"%ld%@%02ld", min, sSeparator, sec];
    } else {
        return [NSString stringWithFormat:@"%ld%@%02ld%@%02ld", hr, sSeparator, min, sSeparator, sec];
    }    
}

@end
