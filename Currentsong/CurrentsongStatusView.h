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
    kCSStyleFormatted,
    kCSStylePlain,
    kCSStyleTwoLevel
} CurrentsongViewStyle;


@interface CurrentsongStatusView : NSView
{
    NSStatusItem *mStatusItem;

    // Properties
    CurrentsongViewStyle mViewStyle;
    CGFloat mMaxWidth;
    BOOL mShowArtist;
    BOOL mShowAlbum;
    BOOL mScroll;
    
    // Track data
    BOOL mShowPauseIcon;
    BOOL mIsStream;
    NSString *mArtist;
    NSString *mName;
    NSString *mAlbum;
    
    NSAttributedString *mTopRow;
    NSAttributedString *mBottomRow;
}

@property (nonatomic,retain) NSStatusItem *statusItem;
@property (nonatomic,assign) CurrentsongViewStyle viewStyle;
@property (nonatomic,assign) CGFloat maxWidth;
@property (nonatomic,assign) BOOL showArtist;
@property (nonatomic,assign) BOOL showAlbum;
@property (nonatomic,assign) BOOL scroll;


// Update track info from dictionary provided by iTunes distributed notification
- (void)updateTrackInfo:(NSDictionary *)trackInfo;

@end
