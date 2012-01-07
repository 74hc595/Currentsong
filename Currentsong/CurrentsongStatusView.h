//
//  CurrentsongStatusView.h
//  Currentsong
//
//  Created by Matthew Sarnoff on 1/7/12.
//  Copyright 2012 Matt Sarnoff. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum
{
    kCSStylePlain,
    kCSStylePlainSmall,
    kCSStyleFormatted,
    kCSStyleFormattedSmall,
    kCSStyleTwoLevel
} CurrentsongViewStyle;

@interface CurrentsongStatusView : NSView
{
    NSStatusItem *mStatusItem;

    // Properties
    CurrentsongViewStyle mViewStyle;
    BOOL mScroll;
    
    // Track data
    BOOL isRunningAndNotStopped;
    BOOL isPaused;
    NSString *mArtist;
    NSString *mName;
    NSString *mAlbum;
    
    NSAttributedString *topRow;
    NSAttributedString *bottomRow;
}

@property (nonatomic,retain) NSStatusItem *statusItem;
@property (nonatomic,assign) CurrentsongViewStyle viewStyle;
@property (nonatomic,assign) BOOL scroll;

// Update track info from dictionary provided by iTunes distributed notification
- (void)updateTrackInfo:(NSDictionary *)trackInfo;

@end
