//
//  CurrentsongStatusView.m
//  Currentsong
//
//  Created by Matthew Sarnoff on 1/7/12.
//  Copyright 2012 Matt Sarnoff. All rights reserved.
//

#import "CurrentsongStatusView.h"

@implementation CurrentsongStatusView

@synthesize statusItem = mStatusItem;
@synthesize viewStyle = mViewStyle;
@synthesize scroll = mScroll;

- (void)dealloc
{
    [mStatusItem release];
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSLog(@"%@", NSStringFromRect([self bounds]));
    
    [[NSColor redColor] set];
    NSRectFill([self bounds]);
}

@end
