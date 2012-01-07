//
//  CurrentsongAppDelegate.m
//  Currentsong
//
//  Created by Matthew Sarnoff on 1/7/12.
//  Copyright 2012 Matt Sarnoff. All rights reserved.
//

#import "CurrentsongAppDelegate.h"
#import "iTunes.h"

@interface CurrentsongAppDelegate ()
- (NSDictionary *)fetchTrackInfo;
- (void)updateTrackInfo:(NSDictionary *)trackInfo;
@end


@implementation CurrentsongAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

// Artist - Name - Album
// Stream Title - Name

- (void)awakeFromNib
{
    // Install status item
    mStatusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [mStatusItem setHighlightMode:YES];
    
    // Get initial track info
    NSDictionary *initialTrackInfo = [self fetchTrackInfo];
    [self updateTrackInfo:initialTrackInfo];
    
    // Start listening to iTunes notifications
    NSDistributedNotificationCenter *dnc = [NSDistributedNotificationCenter defaultCenter];
    [dnc addObserver:self selector:@selector(trackInfoDidChange:) name:@"com.apple.iTunes.playerInfo" object:nil];
}

- (void)dealloc
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [mStatusItem release];
    [super dealloc];
}

// Handle play state and track changes
- (void)trackInfoDidChange:(NSNotification *)notification
{
    [self updateTrackInfo:[notification userInfo]];
}

// Update track info
- (void)updateTrackInfo:(NSDictionary *)trackInfo
{
    // If trackInfo is nil, interpret this as iTunes not running or the player stopped
    NSString *playerState = [trackInfo objectForKey:@"Player State"];
    
    if (!trackInfo || !playerState || [playerState isEqualToString:@"Stopped"]) {
        [mStatusItem setTitle:@"\u266B"]; // musical note icon
        return;
    }
    
    NSString *artist = [trackInfo objectForKey:@"Artist"];
    NSString *name = [trackInfo objectForKey:@"Name"];
    NSString *album = [trackInfo objectForKey:@"Album"];
    NSString *streamTitle = [trackInfo objectForKey:@"Stream Title"];
    
    // Streaming?
    if (streamTitle) {
        album = name;
        name = streamTitle;
    }
    
    NSLog(@"Artist: %@", artist);
    NSLog(@"Name:   %@", name);
    NSLog(@"Album:  %@", album);
    
    BOOL haveArtist = ([artist length] > 0);
    BOOL haveName = ([name length] > 0);
    BOOL haveAlbum = ([album length] > 0);
    
    NSMutableArray *fields = [NSMutableArray arrayWithCapacity:3];
    if (haveArtist) [fields addObject:artist];
    if (haveName)   [fields addObject:name];
    if (haveAlbum)  [fields addObject:album];
    
    NSString *pausedIcon = ([playerState isEqualToString:@"Paused"] ? @"\u275A\u275A " : @"");
    
    NSString *fullStatus = [NSString stringWithFormat:@"%@%@",
                            pausedIcon,
                            [fields componentsJoinedByString:@" - "]];
    [mStatusItem setTitle:fullStatus];
}

// Fetch track info directly using Scripting Bridge
// Fetches play state, artist, name, album, and stream title.
- (NSDictionary *)fetchTrackInfo
{
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];

    // Application not found or not running
    if (!iTunes || ![iTunes isRunning]) {
        NSLog(@"itunes not running");
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
