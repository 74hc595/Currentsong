//
//  CurrentsongAppDelegate.h
//  Currentsong
//
//  Created by Matthew Sarnoff on 1/7/12.
//  Copyright 2012 Matt Sarnoff. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CurrentsongStatusView;
@class LaunchAtLoginController;

@interface CurrentsongAppDelegate : NSObject <NSApplicationDelegate,NSMenuDelegate>
{
    NSStatusItem *mStatusItem;
    CurrentsongStatusView *mStatusView;
    NSTimer *mMenuUpdateTimer;
    BOOL mMenuIsOpen;
    
    IBOutlet NSMenu *mMenu;
    IBOutlet NSMenuItem *mNameMenuItem;
    IBOutlet NSMenuItem *mArtistMenuItem;
    IBOutlet NSMenuItem *mAlbumMenuItem;
    IBOutlet NSMenuItem *mStreamTitleMenuItem;
    IBOutlet NSMenuItem *mTimeMenuItem;

    IBOutlet LaunchAtLoginController *mLaunchAtLoginController;
}

- (IBAction)toggleShowArtist:(id)sender;
- (IBAction)toggleShowAlbum:(id)sender;
- (IBAction)toggleTwoLineDisplay:(id)sender;
- (IBAction)toggleScrollLongText:(id)sender;

- (IBAction)setTitleOnly:(id)sender;
- (IBAction)setTitleAndArtist:(id)sender;
- (IBAction)setTitleArtistAlbum:(id)sender;
- (IBAction)setTitleAndArtistStacked:(id)sender;
- (IBAction)setTitleArtistAlbumStacked:(id)sender;

- (IBAction)setLargeViewWidth:(id)sender;
- (IBAction)setMediumViewWidth:(id)sender;
- (IBAction)setSmallViewWidth:(id)sender;

- (IBAction)toggleLaunchAtLogin:(id)sender;

- (IBAction)launchITunes:(id)sender;

@end
