//
//  CurrentsongAppDelegate.m
//  Currentsong
//
//  Created by Matthew Sarnoff on 1/7/12.
//  Copyright 2012 Matt Sarnoff. All rights reserved.
//

#import "iTunes.h"
#import "MSDurationFormatter.h"
#import "LaunchAtLoginController.h"
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


@implementation CurrentsongAppDelegate {
    NSStatusItem *_statusItem;
    CurrentsongStatusView *_statusView;
    NSTimer *_menuUpdateTimer;
    BOOL _menuIsOpen;
    BOOL _needStreamTitleWorkaround;
}

+ (iTunesApplication *)iTunes
{
    return [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Check the version of iTunes, see if we need to workaround the issue on 11.2+ where the stream title
    // is not included in the update notification
    iTunesApplication *iTunes = [[self class] iTunes];
    if (iTunes) {
        NSString *version = iTunes.version;
        NSArray *versionComponents = [version componentsSeparatedByString:@"."];
        if ([versionComponents count] >= 2) {
            _needStreamTitleWorkaround = ([versionComponents[0] integerValue] >= 11 && [versionComponents[1] integerValue] >= 2);
        }
    }

    // If this is the first run, prompt the user to select launch at login
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kCSPrefShownLaunchAtLoginPrompt])
    {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Start Currentsong when you log in?", @"Launch at login prompt title")
                                         defaultButton:NSLocalizedString(@"Yes", @"Yes")
                                       alternateButton:NSLocalizedString(@"No", @"No")
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(
                          @"Would you like Currentsong to start automatically when you log in? "
                          @"This setting can also be changed from the Options sub-menu.", @"Launch at login prompt text")];
        NSInteger result = [alert runModal];

        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCSPrefShownLaunchAtLoginPrompt];
        [_launchAtLoginController setLaunchAtLogin:(result == NSAlertDefaultReturn)];
    }
}

- (void)awakeFromNib
{
    // Initialize preferences
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     @{kCSPrefViewStyle: @(kCSStyleFormatted),
      kCSPrefMaxWidth: [NSNumber numberWithDouble:kCSViewWidthLarge],
      kCSPrefShowArtist: @YES,
      kCSPrefShowAlbum: @NO,
      kCSPrefShowRating: @NO,
      kCSPrefScrollLongText: @YES}];
    
    // Inject version number into menu
    [_versionMenuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Currentsong %@", @"application name with version number"),
                                [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]];

    // Install status item
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setMenu:_menu];
    [_menu setDelegate:self];
    
    // Set up view
    _statusView = [[CurrentsongStatusView alloc] init];
    _statusView.statusItem = _statusItem;
    _statusView.viewStyle       = (CurrentsongViewStyle)[[NSUserDefaults standardUserDefaults] integerForKey:kCSPrefViewStyle];
    _statusView.maxWidth        = [[NSUserDefaults standardUserDefaults] doubleForKey:kCSPrefMaxWidth];
    _statusView.showArtist      = [[NSUserDefaults standardUserDefaults] boolForKey:kCSPrefShowArtist];
    _statusView.showAlbum       = [[NSUserDefaults standardUserDefaults] boolForKey:kCSPrefShowAlbum];
    _statusView.showRating       = [[NSUserDefaults standardUserDefaults] boolForKey:kCSPrefShowRating];
    _statusView.shouldScroll    = [[NSUserDefaults standardUserDefaults] boolForKey:kCSPrefScrollLongText];
        
    // Get initial track info
    NSDictionary *initialTrackInfo = [self fetchTrackInfo];
    [self updateMenuItemsWithTrackInfo:initialTrackInfo];
    [_statusView updateTrackInfo:initialTrackInfo];
    [_statusItem setView:_statusView];
    
    // Start listening to iTunes notifications
    NSDistributedNotificationCenter *dnc = [NSDistributedNotificationCenter defaultCenter];
    [dnc addObserver:self selector:@selector(trackInfoDidChange:) name:@"com.apple.iTunes.playerInfo" object:nil];
    
    // Listen to application-did-terminate notifications since iTunes 11 no longer posts a "stopped" event on quit
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(anotherAppDidTerminate:)
                                                               name:NSWorkspaceDidTerminateApplicationNotification
                                                             object:nil];
}

- (void)dealloc
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    [_menuUpdateTimer invalidate];
}

// Handle play state and track changes
- (void)trackInfoDidChange:(NSNotification *)notification
{
    NSDictionary *trackInfo = [notification userInfo];
    if (_needStreamTitleWorkaround) {
        trackInfo = [self infoWithAddedStreamTitle:trackInfo];
    }
    
    [self updateMenuItemsWithTrackInfo:trackInfo];
    [_statusView updateTrackInfo:trackInfo];
    
    if (_menuIsOpen) {
        [self updateMenuTrackTime];
    }
}

// iTunes 11.2 and up no longer include the "Stream Title" property in the track-changed notification,
// so we need to fetch it manually.
- (NSDictionary *)infoWithAddedStreamTitle:(NSDictionary *)info
{
    // Check if the file is remote (not sure how robust this is...)
    NSString *location = [info objectForKey:@"Location"];
    if (location && ![location hasPrefix:@"file:"] && ![info objectForKey:@"Stream Title"]) {
        NSMutableDictionary *newTrackInfo = [NSMutableDictionary dictionaryWithDictionary:info];
        NSString *streamTitle = nil;
        iTunesApplication *iTunes = [[self class] iTunes];
        if (iTunes && [iTunes isRunning]) {
            streamTitle = iTunes.currentStreamTitle;
        }
        if (streamTitle) {
            [newTrackInfo setObject:streamTitle forKey:@"Stream Title"];
        }
        return newTrackInfo;
    } else {
        return info;
    }
}

// Handle iTunes quit notifications
- (void)anotherAppDidTerminate:(NSNotification *)notification
{
    if ([[[notification userInfo] valueForKey:@"NSApplicationBundleIdentifier"] isEqualToString:@"com.apple.iTunes"]) {
        [self trackInfoDidChange:nil];
    }
}

// Fetch track info directly using Scripting Bridge
// Fetches play state, artist, name, album, and stream title.
- (NSDictionary *)fetchTrackInfo
{
    iTunesApplication *iTunes = [[self class] iTunes];

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
    NSInteger rating = currentTrack.rating;
    NSString *streamTitle = iTunes.currentStreamTitle;
    
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    if (playerStateString) {
        [info setObject:playerStateString forKey:@"Player State"];
    }
    if (artist) {
        [info setObject:artist forKey:@"Artist"];
    }
    if (name) {
        [info setObject:name forKey:@"Name"];
    }
    if (album) {
        [info setObject:album forKey:@"Album"];
    }
    if (rating) {
        [info setObject:[NSNumber numberWithInteger:rating] forKey:@"Rating"];
    }
    if (streamTitle) {
        [info setObject:streamTitle forKey:@"Stream Title"];
    }
    
    // note: these keys aren't provided by the track change notification
    [info setObject:@(iTunes.playerPosition) forKey:@"Player Position"];
    [info setObject:@(currentTrack.duration) forKey:@"Duration"];
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
        [menuItem setState:_statusView.showArtist];
    } else if ([menuItem action] == @selector(toggleShowAlbum:)) {
        [menuItem setState:_statusView.showAlbum];
    } else if ([menuItem action] == @selector(toggleTwoLineDisplay:)) {
        [menuItem setState:(_statusView.viewStyle == kCSStyleTwoLevel)];
    } else if ([menuItem action] == @selector(toggleScrollLongText:)) {
        [menuItem setState:_statusView.shouldScroll];
    } else if ([menuItem action] == @selector(setLargeViewWidth:)) {
        [menuItem setState:(_statusView.maxWidth == kCSViewWidthLarge)];
    } else if ([menuItem action] == @selector(setMediumViewWidth:)) {
        [menuItem setState:(_statusView.maxWidth == kCSViewWidthMedium)];
    } else if ([menuItem action] == @selector(setSmallViewWidth:)) {
        [menuItem setState:(_statusView.maxWidth == kCSViewWidthSmall)];
    } else if ([menuItem action] == @selector(setTitleOnly:)) {
        [menuItem setState:(!_statusView.showArtist && !_statusView.showAlbum && !_statusView.showRating && !(_statusView.viewStyle == kCSStyleTwoLevel))];
    } else if ([menuItem action] == @selector(setTitleAndArtist:)) {
        [menuItem setState:(_statusView.showArtist && !_statusView.showAlbum && !_statusView.showRating && !(_statusView.viewStyle == kCSStyleTwoLevel))];
    } else if ([menuItem action] == @selector(setTitleArtistAlbum:)) {
        [menuItem setState:(_statusView.showArtist && _statusView.showAlbum && !_statusView.showRating && !(_statusView.viewStyle == kCSStyleTwoLevel))];
    } else if ([menuItem action] == @selector(setTitleArtistAlbumRating:)) {
        [menuItem setState:(_statusView.showArtist && _statusView.showAlbum && _statusView.showRating && !(_statusView.viewStyle == kCSStyleTwoLevel))];
    } else if ([menuItem action] == @selector(setTitleAndArtistStacked:)) {
        [menuItem setState:(_statusView.showArtist && !_statusView.showAlbum && !_statusView.showRating && (_statusView.viewStyle == kCSStyleTwoLevel))];
    } else if ([menuItem action] == @selector(setTitleArtistAlbumStacked:)) {
        [menuItem setState:(_statusView.showArtist && _statusView.showAlbum && !_statusView.showRating && (_statusView.viewStyle == kCSStyleTwoLevel))];
    } else if ([menuItem action] == @selector(setTitleArtistAlbumRatingStacked:)) {
        [menuItem setState:(_statusView.showArtist && _statusView.showAlbum && _statusView.showRating && (_statusView.viewStyle == kCSStyleTwoLevel))];
    } else if ([menuItem action] == @selector(toggleLaunchAtLogin:)) {
        [menuItem setState:[_launchAtLoginController launchAtLogin]];
    } else if ([menuItem action] == @selector(launchITunes:)) {
        [menuItem setTitle:([[[self class] iTunes] isRunning]) ? NSLocalizedString(@"iTunes", @"iTunes")
                                                               : NSLocalizedString(@"Launch iTunes", @"Launch iTunes")];
    }
    return YES;
}

- (void)updateMenuItemsWithTrackInfo:(NSDictionary *)trackInfo
{
    NSString *name = [trackInfo objectForKey:@"Name"];
    NSString *artist = [trackInfo objectForKey:@"Artist"];
    NSString *album = [trackInfo objectForKey:@"Album"];
    NSString *streamTitle = [trackInfo objectForKey:@"Stream Title"];
    
    NSNumber *ratingPercent = [trackInfo objectForKey:@"Rating"];
    NSString *rating = nil;
    if ([ratingPercent intValue] == 100) {
        rating = @"★★★★★";
    } else if ([ratingPercent intValue] == 90) {
        rating = @"★★★★½";
    } else if ([ratingPercent intValue] == 80) {
        rating = @"★★★★☆";
    } else if ([ratingPercent intValue] == 70) {
        rating = @"★★★½☆";
    } else if ([ratingPercent intValue] == 60) {
        rating = @"★★★☆☆";
    } else if ([ratingPercent intValue] == 50) {
        rating = @"★★½☆☆";
    } else if ([ratingPercent intValue] == 40) {
        rating = @"★★☆☆☆";
    } else if ([ratingPercent intValue] == 30) {
        rating = @"★½☆☆☆";
    } else if ([ratingPercent intValue] == 20) {
        rating = @"★☆☆☆☆";
    } else if ([ratingPercent intValue] == 10) {
        rating = @"½☆☆☆☆";
    } else {
        rating = @"☆☆☆☆☆";
    }

    if ([name length] > 0) {
        [_nameMenuItem setHidden:NO];
        [_nameMenuItem setTitle:name];
    } else {
        [_nameMenuItem setHidden:YES];
    }
    
    if ([artist length] > 0) {
        [_artistMenuItem setHidden:NO];
        [_artistMenuItem setTitle:artist];
    } else {
        [_artistMenuItem setHidden:YES];
    }
    
    if ([album length] > 0) {
        [_albumMenuItem setHidden:NO];
        [_albumMenuItem setTitle:album];
    } else {
        [_albumMenuItem setHidden:YES];
    }
    
    if ([streamTitle length] > 0) {
        [_streamTitleMenuItem setHidden:NO];
        [_streamTitleMenuItem setTitle:streamTitle];
    } else {
        [_streamTitleMenuItem setHidden:YES];
    }
    
    if ([rating length] > 0) {
        [_ratingMenuItem setHidden:NO];
        [_ratingMenuItem setTitle:rating];
    } else {
        [_ratingMenuItem setHidden:YES];
    }
}

- (void)updateMenuTrackTime
{
    NSDictionary *info = [self fetchTrackInfo];
    NSString *elapsedTimeString = [[self class] timeStringFromTrackInfo:info];
    if (elapsedTimeString) {
        [_timeMenuItem setTitle:elapsedTimeString];
    }
    
    NSString *playerState = [info objectForKey:@"Player State"];
    if (!playerState || [playerState isEqualToString:@"Stopped"]) {
        [_ratingMenuItem setHidden:YES];
    }
}

- (void)menuUpdateTimerFired:(NSTimer *)timer
{
    [self updateMenuTrackTime];
}

- (void)menuWillOpen:(NSMenu *)menu
{
    if (menu == _menu) {
        if (!_menuUpdateTimer) {
            _menuUpdateTimer = [[NSTimer alloc] initWithFireDate:[NSDate date]
                                                        interval:1
                                                          target:self
                                                        selector:@selector(menuUpdateTimerFired:)
                                                        userInfo:nil
                                                         repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:_menuUpdateTimer forMode:NSRunLoopCommonModes];
        }
        
        _statusView.highlighted = YES;
        _menuIsOpen = YES;
    }
}

- (void)menuDidClose:(NSMenu *)menu
{
    if (menu == _menu) {
        [_menuUpdateTimer invalidate];
        _menuUpdateTimer = nil;
        _statusView.highlighted = NO;
        _menuIsOpen = NO;
    }
}


#pragma mark Actions

// dummy action so validateMenuItem: gets called
- (IBAction)trackElapsedTime:(id)sender {}

- (IBAction)toggleShowArtist:(id)sender
{
    _statusView.showArtist = !_statusView.showArtist;
    [[NSUserDefaults standardUserDefaults] setBool:_statusView.showArtist forKey:kCSPrefShowArtist];
}

- (IBAction)toggleShowAlbum:(id)sender
{
    _statusView.showAlbum = !_statusView.showAlbum;
    [[NSUserDefaults standardUserDefaults] setBool:_statusView.showAlbum forKey:kCSPrefShowAlbum];
}

- (IBAction)toggleTwoLineDisplay:(id)sender
{
    _statusView.viewStyle = (_statusView.viewStyle == kCSStyleTwoLevel) ? kCSStyleFormatted : kCSStyleTwoLevel;
    [[NSUserDefaults standardUserDefaults] setInteger:_statusView.viewStyle forKey:kCSPrefViewStyle];
    
    // make sure the second line is showing
    if (!_statusView.showArtist) {
        [self toggleShowArtist:self];
    }
}

- (void)writeDisplayPreference
{
    [[NSUserDefaults standardUserDefaults] setBool:_statusView.showArtist forKey:kCSPrefShowArtist];
    [[NSUserDefaults standardUserDefaults] setBool:_statusView.showAlbum forKey:kCSPrefShowAlbum];
    [[NSUserDefaults standardUserDefaults] setBool:_statusView.showRating forKey:kCSPrefShowRating];
    [[NSUserDefaults standardUserDefaults] setInteger:_statusView.viewStyle forKey:kCSPrefViewStyle];
}

- (IBAction)setTitleOnly:(id)sender
{
    [_statusView setShowArtist:NO showAlbum:NO showRating:NO viewStyle:kCSStyleFormatted];
    [self writeDisplayPreference];
}

- (IBAction)setTitleAndArtist:(id)sender
{
    [_statusView setShowArtist:YES showAlbum:NO showRating:NO viewStyle:kCSStyleFormatted];
    [self writeDisplayPreference];
}

- (IBAction)setTitleArtistAlbum:(id)sender
{
    [_statusView setShowArtist:YES showAlbum:YES showRating:NO viewStyle:kCSStyleFormatted];
    [self writeDisplayPreference];
}

- (IBAction)setTitleArtistAlbumRating:(id)sender
{
    [_statusView setShowArtist:YES showAlbum:YES showRating:YES viewStyle:kCSStyleFormatted];
    [self writeDisplayPreference];
}

- (IBAction)setTitleAndArtistStacked:(id)sender
{
    [_statusView setShowArtist:YES showAlbum:NO showRating:NO viewStyle:kCSStyleTwoLevel];
    [self writeDisplayPreference];
}

- (IBAction)setTitleArtistAlbumStacked:(id)sender;
{
    [_statusView setShowArtist:YES showAlbum:YES showRating:NO viewStyle:kCSStyleTwoLevel];
    [self writeDisplayPreference];
}

- (IBAction)setTitleArtistAlbumRatingStacked:(id)sender;
{
    [_statusView setShowArtist:YES showAlbum:YES showRating:YES viewStyle:kCSStyleTwoLevel];
    [self writeDisplayPreference];
}

- (IBAction)toggleScrollLongText:(id)sender
{
    _statusView.shouldScroll = !_statusView.shouldScroll;
    [[NSUserDefaults standardUserDefaults] setBool:_statusView.shouldScroll forKey:kCSPrefScrollLongText];
}

- (void)setMaxWidth:(CGFloat)maxWidth
{
    _statusView.maxWidth = maxWidth;
    [[NSUserDefaults standardUserDefaults] setDouble:_statusView.maxWidth forKey:kCSPrefMaxWidth];
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

- (IBAction)toggleLaunchAtLogin:(id)sender
{
    [_launchAtLoginController setLaunchAtLogin:![_launchAtLoginController launchAtLogin]];
}

- (IBAction)launchITunes:(id)sender
{
    // Reveal the current track (only if iTunes is already running)
    [[[[self class] iTunes] currentTrack] reveal];
    
    // Activate iTunes (or launch it)
    [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.iTunes"
                                                         options:0
                                  additionalEventParamDescriptor:NULL
                                                launchIdentifier:NULL];    
}

@end
