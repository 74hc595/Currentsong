//
//  CurrentsongStatusView.h
//  Currentsong
//
//  Created by Matthew Sarnoff on 1/7/12.
//  Copyright 2012 Matt Sarnoff. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, CurrentsongViewStyle)
{
    kCSStyleFormatted,
    kCSStylePlain,
    kCSStyleTwoLevel
};


@interface CurrentsongStatusView : NSView

@property (nonatomic,strong) NSStatusItem *statusItem;
@property (nonatomic,assign) BOOL highlighted;
@property (nonatomic,assign) CurrentsongViewStyle viewStyle;
@property (nonatomic,assign) CGFloat maxWidth;
@property (nonatomic,assign) BOOL showArtist;
@property (nonatomic,assign) BOOL showAlbum;
@property (nonatomic,assign) BOOL showRating;
@property (nonatomic,assign) BOOL shouldScroll;

- (void)setShowArtist:(BOOL)showArtist showAlbum:(BOOL)showAlbum showRating:(BOOL)showRating viewStyle:(CurrentsongViewStyle)viewStyle;

// Update track info from dictionary provided by iTunes distributed notification
- (void)updateTrackInfo:(NSDictionary *)trackInfo;

@end
