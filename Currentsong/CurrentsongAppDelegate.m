//
//  CurrentsongAppDelegate.m
//  Currentsong
//
//  Created by Matthew Sarnoff on 1/7/12.
//  Copyright 2012 Matt Sarnoff. All rights reserved.
//

#import "iTunes.h"
#import "MSDurationFormatter.h"
#import "CurrentsongStatusView.h"
#import "CurrentsongPreferenceKeys.h"
#import "CurrentsongAppDelegate.h"

// View max-width presets
#define kCSViewWidthLarge   500
#define kCSViewWidthMedium  300
#define kCSViewWidthSmall   210

@interface CurrentsongAppDelegate ()
- (NSDictionary *)fetchTrackInfo;
- (void)updateMenuItemsWithTrackInfo:(NSDictionary *)trackInfo;
- (void)updateMenuTrackTime;
@end


@implementation CurrentsongAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}

- (void)awakeFromNib
{
    // Initialize preferences
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithInteger:kCSStyleFormatted], kCSPrefViewStyle,
      [NSNumber numberWithDouble:kCSViewWidthLarge], kCSPrefMaxWidth,
      [NSNumber numberWithBool:YES], kCSPrefShowArtist,
      [NSNumber numberWithBool:NO], kCSPrefShowAlbum,
      [NSNumber numberWithBool:YES], kCSPrefScrollLongText,
      nil]];

    // Install status item
    mStatusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [mStatusItem setMenu:mMenu];
    [mMenu setDelegate:self];
    
    // Set up view
    mStatusView = [[CurrentsongStatusView alloc] init];
    mStatusView.statusItem = mStatusItem;
    mStatusView.viewStyle       = (CurrentsongViewStyle)[[NSUserDefaults standardUserDefaults] integerForKey:kCSPrefViewStyle];
    mStatusView.maxWidth        = [[NSUserDefaults standardUserDefaults] doubleForKey:kCSPrefMaxWidth];
    mStatusView.showArtist      = [[NSUserDefaults standardUserDefaults] boolForKey:kCSPrefShowArtist];
    mStatusView.showAlbum       = [[NSUserDefaults standardUserDefaults] boolForKey:kCSPrefShowAlbum];
    mStatusView.shouldScroll    = [[NSUserDefaults standardUserDefaults] boolForKey:kCSPrefScrollLongText];
        
    // Get initial track info
    NSDictionary *initialTrackInfo = [self fetchTrackInfo];
    [self updateMenuItemsWithTrackInfo:initialTrackInfo];
    [mStatusView updateTrackInfo:initialTrackInfo];
    [mStatusItem setView:mStatusView];
    
    // Start listening to iTunes notifications
    NSDistributedNotificationCenter *dnc = [NSDistributedNotificationCenter defaultCenter];
    [dnc addObserver:self selector:@selector(trackInfoDidChange:) name:@"com.apple.iTunes.playerInfo" object:nil];
}

- (void)dealloc
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [mMenuUpdateTimer invalidate];
    [mMenuUpdateTimer release];
    [mStatusItem release];
    [mStatusView release];
    [super dealloc];
}

// Handle play state and track changes
- (void)trackInfoDidChange:(NSNotification *)notification
{    
    [self updateMenuItemsWithTrackInfo:[notification userInfo]];
    [mStatusView updateTrackInfo:[notification userInfo]];
    
    if (mMenuIsOpen) {
        [self updateMenuTrackTime];
    }    
}

// Fetch track info directly using Scripting Bridge
// Fetches play state, artist, name, album, and stream title.
- (NSDictionary *)fetchTrackInfo
{
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];

    // Application not found or not running
    if (!iTunes || ![iTunes isRunning]) {
        return nil;
    }
    
    // Is iTunes stopped or paused?
    NSString *playerStateString;
    switch (iTunes.playerState)
    {
        case iTunesEPlSStopped: playerStateString = @"Stopped"; break;
        case iTunesEPlSPaused:  playerStateString = @"Paused"; break;
        default:                playerStateString = @""; break;
    }
    
    iTunesTrack *currentTrack = iTunes.currentTrack;
    NSString *artist = currentTrack.artist;
    NSString *name = currentTrack.name;
    NSString *album = currentTrack.album;
    NSString *streamTitle = iTunes.currentStreamTitle;
    
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    if (playerStateString)  [info setObject:playerStateString forKey:@"Player State"];
    if (artist)             [info setObject:artist forKey:@"Artist"];
    if (name)               [info setObject:name forKey:@"Name"];
    if (album)              [info setObject:album forKey:@"Album"];
    if (streamTitle)        [info setObject:streamTitle forKey:@"Stream Title"];
    
    // note: these keys aren't provided by the track change notification
    [info setObject:[NSNumber numberWithInteger:iTunes.playerPosition] forKey:@"Player Position"];
    [info setObject:[NSNumber numberWithDouble:currentTrack.duration] forKey:@"Duration"];
    return info;
}

+ (NSString *)timeStringFromTrackInfo:(NSDictionary *)trackInfo
{
    NSString *playerState = [trackInfo objectForKey:@"Player State"];
    if (!playerState || [playerState isEqualToString:@"Stopped"]) {
        return NSLocalizedString(@"Not Playing", @"Not Playing");
    }
    
    NSInteger elapsedTime = [[trackInfo objectForKey:@"Player Position"] integerValue];
    double duration = [[trackInfo objectForKey:@"Duration"] doubleValue];
    
    NSString *elapsedTimeString = [MSDurationFormatter hoursMinutesSecondsFromSeconds:elapsedTime];

    // No duration? Either there is nothing playing or the track is continuous
    if (duration == 0) {
        return elapsedTimeString;
    } else {
        NSInteger remainingTime = round(duration) - elapsedTime;
        NSString *remainingTimeString = [MSDurationFormatter hoursMinutesSecondsFromSeconds:remainingTime];
        return [NSString stringWithFormat:@"%@ (-%@)", elapsedTimeString, remainingTimeString];
    }
}


#pragma mark Menu

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ([menuItem action] == @selector(trackElapsedTime:)) {
        [self updateMenuTrackTime];
        return NO;
    } else if ([menuItem action] == @selector(toggleShowArtist:)) {
        [menuItem setState:mStatusView.showArtist];
    } else if ([menuItem action] == @selector(toggleShowAlbum:)) {
        [menuItem setState:mStatusView.showAlbum];
    } else if ([menuItem action] == @selector(toggleTwoLineDisplay:)) {
        [menuItem setState:(mStatusView.viewStyle == kCSStyleTwoLevel)];
    } else if ([menuItem action] == @selector(toggleScrollLongText:)) {
        [menuItem setState:mStatusView.shouldScroll];
    } else if ([menuItem action] == @selector(setLargeViewWidth:)) {
        [menuItem setState:(mStatusView.maxWidth == kCSViewWidthLarge)];
    } else if ([menuItem action] == @selector(setMediumViewWidth:)) {
        [menuItem setState:(mStatusView.maxWidth == kCSViewWidthMedium)];
    } else if ([menuItem action] == @selector(setSmallViewWidth:)) {
        [menuItem setState:(mStatusView.maxWidth == kCSViewWidthSmall)];
    }
    return YES;
}

- (void)updateMenuItemsWithTrackInfo:(NSDictionary *)trackInfo
{
    NSString *name = [trackInfo objectForKey:@"Name"];
    NSString *artist = [trackInfo objectForKey:@"Artist"];
    NSString *album = [trackInfo objectForKey:@"Album"];
    NSString *streamTitle = [trackInfo objectForKey:@"Stream Title"];
    
    if ([name length] > 0) {
        [mNameMenuItem setHidden:NO];
        [mNameMenuItem setTitle:name];
    } else {
        [mNameMenuItem setHidden:YES];
    }
    
    if ([artist length] > 0) {
        [mArtistMenuItem setHidden:NO];
        [mArtistMenuItem setTitle:artist];
    } else {
        [mArtistMenuItem setHidden:YES];
    }
    
    if ([album length] > 0) {
        [mAlbumMenuItem setHidden:NO];
        [mAlbumMenuItem setTitle:album];
    } else {
        [mAlbumMenuItem setHidden:YES];
    }
    
    if ([streamTitle length] > 0) {
        [mStreamTitleMenuItem setHidden:NO];
        [mStreamTitleMenuItem setTitle:streamTitle];
    } else {
        [mStreamTitleMenuItem setHidden:YES];
    }
}

- (void)updateMenuTrackTime
{
    NSDictionary *info = [self fetchTrackInfo];
    NSString *elapsedTimeString = [[self class] timeStringFromTrackInfo:info];
    if (elapsedTimeString) {
        [mTimeMenuItem setTitle:elapsedTimeString];
    }
}

- (void)menuUpdateTimerFired:(NSTimer *)timer
{
    [self updateMenuTrackTime];
}

- (void)menuWillOpen:(NSMenu *)menu
{
    if (menu == mMenu)
    {
        if (!mMenuUpdateTimer)
        {
            mMenuUpdateTimer = [[NSTimer alloc] initWithFireDate:[NSDate date]
                                                        interval:1
                                                          target:self
                                                        selector:@selector(menuUpdateTimerFired:)
                                                        userInfo:nil
                                                         repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:mMenuUpdateTimer forMode:NSRunLoopCommonModes];
        }
        
        mStatusView.highlighted = YES;
        mMenuIsOpen = YES;
    }
}

- (void)menuDidClose:(NSMenu *)menu
{
    if (menu == mMenu)
    {
        [mMenuUpdateTimer invalidate];
        [mMenuUpdateTimer release];
        mMenuUpdateTimer = nil;
        mStatusView.highlighted = NO;
        mMenuIsOpen = NO;
    }
}


#pragma mark Actions

// dummy action so validateMenuItem: gets called
- (IBAction)trackElapsedTime:(id)sender {}

- (IBAction)toggleShowArtist:(id)sender
{
    mStatusView.showArtist = !mStatusView.showArtist;
    [[NSUserDefaults standardUserDefaults] setBool:mStatusView.showArtist forKey:kCSPrefShowArtist];
}

- (IBAction)toggleShowAlbum:(id)sender
{
    mStatusView.showAlbum = !mStatusView.showAlbum;
    [[NSUserDefaults standardUserDefaults] setBool:mStatusView.showAlbum forKey:kCSPrefShowAlbum];
}

- (IBAction)toggleTwoLineDisplay:(id)sender
{
    mStatusView.viewStyle = (mStatusView.viewStyle == kCSStyleTwoLevel) ? kCSStyleFormatted : kCSStyleTwoLevel;
    [[NSUserDefaults standardUserDefaults] setInteger:mStatusView.viewStyle forKey:kCSPrefViewStyle];
    
    // make sure the second line is showing
    if (!mStatusView.showArtist) {
        [self toggleShowArtist:self];
    }
}

- (IBAction)toggleScrollLongText:(id)sender
{
    mStatusView.shouldScroll = !mStatusView.shouldScroll;
    [[NSUserDefaults standardUserDefaults] setBool:mStatusView.shouldScroll forKey:kCSPrefScrollLongText];
}

- (void)setMaxWidth:(CGFloat)maxWidth
{
    mStatusView.maxWidth = maxWidth;
    [[NSUserDefaults standardUserDefaults] setDouble:mStatusView.maxWidth forKey:kCSPrefMaxWidth];
}

- (IBAction)setLargeViewWidth:(id)sender
{
    [self setMaxWidth:kCSViewWidthLarge];
}

- (IBAction)setMediumViewWidth:(id)sender
{
    [self setMaxWidth:kCSViewWidthMedium];
}

- (IBAction)setSmallViewWidth:(id)sender
{
    [self setMaxWidth:kCSViewWidthSmall];
}

@end
