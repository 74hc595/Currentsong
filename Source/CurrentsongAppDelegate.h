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

@property (weak) IBOutlet NSMenu *menu;
@property (weak) IBOutlet NSMenuItem *nameMenuItem;
@property (weak) IBOutlet NSMenuItem *artistMenuItem;
@property (weak) IBOutlet NSMenuItem *albumMenuItem;
@property (weak) IBOutlet NSMenuItem *streamTitleMenuItem;
@property (weak) IBOutlet NSMenuItem *timeMenuItem;
@property (weak) IBOutlet NSMenuItem *versionMenuItem;
@property (weak) IBOutlet LaunchAtLoginController *launchAtLoginController;

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
