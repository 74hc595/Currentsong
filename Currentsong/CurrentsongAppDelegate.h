//
//  CurrentsongAppDelegate.h
//  Currentsong
//
//  Created by Matthew Sarnoff on 1/7/12.
//  Copyright 2012 Matt Sarnoff. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CurrentsongAppDelegate : NSObject <NSApplicationDelegate>
{
    NSStatusItem *mStatusItem;
    IBOutlet NSMenu *mMenu;    
}

@end
