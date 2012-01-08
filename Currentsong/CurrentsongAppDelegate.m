//
//  CurrentsongAppDelegate.m
//  Currentsong
//
//  Created by Matthew Sarnoff on 1/7/12.
//  Copyright 2012 Matt Sarnoff. All rights reserved.
//

#import "iTunes.h"
#import "CurrentsongStatusView.h"
#import "CurrentsongPreferenceKeys.h"
#import "CurrentsongAppDelegate.h"

@interface CurrentsongAppDelegate ()
- (NSDictionary *)fetchTrackInfo;
@end


@implementation CurrentsongAppDelegate

static CGFloat largeViewSize()  { return 500; }
static CGFloat mediumViewSize() { return 350; }
static CGFloat smalliewSize()   { return 200; }

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}

// Artist - Name - Album
// Stream Title - Name

- (void)awakeFromNib
{
    // Initialize preferences
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithInteger:kCSStyleFormatted], kCSPrefViewStyle,
      [NSNumber numberWithDouble:500], kCSPrefMaxWidth,
      [NSNumber numberWithBool:YES], kCSPrefShowArtist,
      [NSNumber numberWithBool:NO], kCSPrefShowAlbum,
      nil]];

    // Install status item
    mStatusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [mStatusItem setHighlightMode:YES];
    mStatusView = [[CurrentsongStatusView alloc] init];
    mStatusView.statusItem = mStatusItem;
    
    // Set up view preferences
    mStatusView.viewStyle   = (CurrentsongViewStyle)[[NSUserDefaults standardUserDefaults] integerForKey:kCSPrefViewStyle];
    mStatusView.maxWidth    = [[NSUserDefaults standardUserDefaults] doubleForKey:kCSPrefMaxWidth];
    mStatusView.showArtist  = [[NSUserDefaults standardUserDefaults] boolForKey:kCSPrefShowArtist];
    mStatusView.showAlbum   = [[NSUserDefaults standardUserDefaults] boolForKey:kCSPrefShowAlbum];
    
    [mStatusItem setView:mStatusView];
    
    // Get initial track info
    NSDictionary *initialTrackInfo = [self fetchTrackInfo];
    [mStatusView updateTrackInfo:initialTrackInfo];
    
    // Start listening to iTunes notifications
    NSDistributedNotificationCenter *dnc = [NSDistributedNotificationCenter defaultCenter];
    [dnc addObserver:self selector:@selector(trackInfoDidChange:) name:@"com.apple.iTunes.playerInfo" object:nil];
}

- (void)dealloc
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [mStatusItem release];
    [mStatusView release];
    [super dealloc];
}

// Handle play state and track changes
- (void)trackInfoDidChange:(NSNotification *)notification
{
    [mStatusView updateTrackInfo:[notification userInfo]];
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
    NSString *artist = [currentTrack artist];
    NSString *name = [currentTrack name];
    NSString *album = [currentTrack album];
    NSString *streamTitle = iTunes.currentStreamTitle;
    
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:5];
    if (playerStateString)  [info setObject:playerStateString forKey:@"Player State"];
    if (artist)             [info setObject:artist forKey:@"Artist"];
    if (name)               [info setObject:name forKey:@"Name"];
    if (album)              [info setObject:album forKey:@"Album"];
    if (streamTitle)        [info setObject:streamTitle forKey:@"Stream Title"];
    return info;
}

@end
