//
//  MSDurationFormatter.h
//  Currentsong
//
//  Created by Matthew Sarnoff on 08/01/12.
//  Copyright 2012 Matt Sarnoff. All rights reserved.
//
//  Very rudimentary class to format a time interval according to locale.
//  This could be expanded... but YAGNI dictates otherwise

#import <Foundation/Foundation.h>

@interface MSDurationFormatter : NSObject

+ (NSString *)hoursMinutesSecondsFromSeconds:(NSInteger)seconds;

@end
