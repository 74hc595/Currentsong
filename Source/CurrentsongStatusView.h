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
    BOOL mHighlighted;
    CurrentsongViewStyle mViewStyle;
    CGFloat mMaxWidth;
    BOOL mShowArtist;
    BOOL mShowAlbum;
    BOOL mShouldScroll;
    
    // Track data
    BOOL mShowPauseIcon;
    BOOL mIsStream;
    NSString *mArtist;
    NSString *mName;
    NSString *mAlbum;
    
    NSAttributedString *mTopRow;
    NSAttributedString *mBottomRow;
    CGFloat mTopRowScrollOffset;
    CGFloat mBottomRowScrollOffset;
    BOOL mScrollTopRow;
    BOOL mScrollBottomRow;
    NSTimer *mScrollTimer;

    CGImageRef mAlphaMask;
    BOOL mAlphaMaskAccountsForPauseIcon;
}

@property (nonatomic,strong) NSStatusItem *statusItem;
@property (nonatomic,assign) BOOL highlighted;
@property (nonatomic,assign) CurrentsongViewStyle viewStyle;
@property (nonatomic,assign) CGFloat maxWidth;
@property (nonatomic,assign) BOOL showArtist;
@property (nonatomic,assign) BOOL showAlbum;
@property (nonatomic,assign) BOOL shouldScroll;

- (void)setShowArtist:(BOOL)showArtist showAlbum:(BOOL)showAlbum viewStyle:(CurrentsongViewStyle)viewStyle;

// Update track info from dictionary provided by iTunes distributed notification
- (void)updateTrackInfo:(NSDictionary *)trackInfo;

@end
