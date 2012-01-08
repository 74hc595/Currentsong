//
//  CurrentsongStatusView.m
//  Currentsong
//
//  Created by Matthew Sarnoff on 1/7/12.
//  Copyright 2012 Matt Sarnoff. All rights reserved.
//

#import "CurrentsongStatusView.h"
#import "CurrentsongPreferenceKeys.h"
#import "NSAttributedStringAdditions.h"

#define kCSViewSideMargin       5
#define kCSViewPauseIconOffset  13

@interface CurrentsongStatusView ()
@property (nonatomic,retain) NSString *artist;
@property (nonatomic,retain) NSString *name;
@property (nonatomic,retain) NSString *album;
@property (nonatomic,retain) NSAttributedString *topRow;
@property (nonatomic,retain) NSAttributedString *bottomRow;
@end

#pragma mark -
@implementation CurrentsongStatusView

@synthesize statusItem = mStatusItem;
@synthesize viewStyle = mViewStyle;
@synthesize maxWidth = mMaxWidth;
@synthesize showArtist = mShowArtist;
@synthesize showAlbum = mShowAlbum;
@synthesize scroll = mScroll;
@synthesize artist = mArtist;
@synthesize name = mName;
@synthesize album = mAlbum;
@synthesize topRow = mTopRow;
@synthesize bottomRow = mBottomRow;

#pragma mark -
- (void)dealloc
{
    [mStatusItem release];
    [mArtist release];
    [mName release];
    [mAlbum release];
    [mTopRow release];
    [mBottomRow release];
    [super dealloc];
}

// Mimic the white shadow under menu item text in the menu bar
+ (NSShadow *)menuBarShadow
{
    static NSShadow *shadow = nil;
    if (!shadow)
    {
        shadow = [[NSShadow alloc] init];
        [shadow setShadowColor:[NSColor colorWithDeviceWhite:1 alpha:0.25]];
        [shadow setShadowOffset:NSMakeSize(0, -1)];
        [shadow setShadowBlurRadius:0];
    }
    
    return shadow;
}

- (void)drawPauseIcon
{
    NSPoint iconOrigin = NSMakePoint(5,7);
    [[NSColor blackColor] set];
    NSRect rect = NSMakeRect(iconOrigin.x,iconOrigin.y,3,9);
    [NSBezierPath fillRect:rect];
    rect.origin.x += 5;
    [NSBezierPath fillRect:rect];
}

- (void)drawSingleRowInRect:(NSRect)rect
{
    if (!mTopRow) {
        return;
    }
        
    NSSize viewSize = [self frame].size;
    NSSize textSize = [mTopRow size];

    NSPoint textOrigin = NSMakePoint(kCSViewSideMargin, ceil((viewSize.height - textSize.height)/2)+1);
    if (mShowPauseIcon) {
        textOrigin.x += kCSViewPauseIconOffset;
        [self drawPauseIcon];
    }

    [mTopRow drawAtPoint:textOrigin];
}

- (void)drawRect:(NSRect)rect
{
//    [[NSColor redColor] set];
//    NSRectFill([self bounds]);
    
    [NSGraphicsContext saveGraphicsState];
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    // disabling font smoothing draws text makes it look just like other menu items and the clock
    CGContextSetShouldSmoothFonts(context, NO);
    
    // add subtle white shadow to match other menu bar text
    [[CurrentsongStatusView menuBarShadow] set];
    
    if (mTopRow && !mBottomRow) {
        [self drawSingleRowInRect:rect];
    }
    
    [NSGraphicsContext restoreGraphicsState];
}

- (void)updateBounds
{
    CGFloat height = mStatusItem.statusBar.thickness;
    CGFloat topRowWidth = (mTopRow) ? [mTopRow size].width : 0;
    CGFloat bottomRowWidth = (mBottomRow) ? [mBottomRow size].width : 0;
    CGFloat width = MAX(topRowWidth, bottomRowWidth);
    //width = MAX(width, 22);
    width += kCSViewSideMargin*2;

    if (mShowPauseIcon) {
        width += kCSViewPauseIconOffset;
    }
    
    // If mMaxWidth is greater than 0, enforce maximum width
    if (mMaxWidth > 0) {
        width = MIN(mMaxWidth, width);
    }
    
    [self setFrame:NSMakeRect(0, 0, width, height)];
    [self setNeedsDisplay:YES];
}

- (void)setNotPlaying
{
    mShowPauseIcon = NO;
    self.bottomRow = nil;
    self.topRow = [NSAttributedString plainAttributedStringForMenuBar:@"\u266B"];
    
    [self updateBounds];
}

- (void)setTrackInfo
{    
    BOOL haveArtist = mShowArtist && ([mArtist length] > 0);
    BOOL haveName = ([mName length] > 0);
    BOOL haveAlbum = mShowAlbum && ([mAlbum length] > 0);
        
    self.bottomRow = nil;
    
    if (mViewStyle == kCSStyleFormatted)
    {
        NSMutableAttributedString *topRowFormatted = [[[NSMutableAttributedString alloc] init] autorelease];
        NSMutableArray *fields = [NSMutableArray arrayWithCapacity:3];
        if (haveName)   [fields addObject:[NSAttributedString boldAttributedStringForMenuBar:mName]];
        if (haveArtist) [fields addObject:[NSAttributedString plainAttributedStringForMenuBar:mArtist]];
        if (haveAlbum)  [fields addObject:[NSAttributedString lightAttributedStringForMenuBar:mAlbum]];
        
        BOOL first = YES;
        for (NSAttributedString *astr in fields)
        {
            if (!first) [topRowFormatted appendAttributedString:
                         [NSAttributedString plainAttributedStringForMenuBar:@"  "]];
            [topRowFormatted appendAttributedString:astr];
            first = NO;
        }
        
        self.topRow = topRowFormatted;
        
    }
    else
    {
        NSMutableArray *fields = [NSMutableArray arrayWithCapacity:3];
        if (haveName)   [fields addObject:mName];
        if (haveArtist) [fields addObject:mArtist];
        if (haveAlbum)  [fields addObject:mAlbum];
        
        self.topRow = [NSAttributedString plainAttributedStringForMenuBar:[fields componentsJoinedByString:@" - "]];
    }
    
    [self updateBounds];
}

- (void)updateTrackInfo:(NSDictionary *)trackInfo
{        
    self.artist = [trackInfo objectForKey:@"Artist"];
    self.name = [trackInfo objectForKey:@"Name"];
    self.album = [trackInfo objectForKey:@"Album"];
    NSString *streamTitle = [trackInfo objectForKey:@"Stream Title"];

    // No song?
    if (!self.name) {
        [self setNotPlaying];
        return;
    }
    
    NSString *playerState = [trackInfo objectForKey:@"Player State"];
    mShowPauseIcon = ([playerState isEqualToString:@"Stopped"] || [playerState isEqualToString:@"Paused"]);
    
    // Streaming?
    if (streamTitle) {
        mIsStream = YES;
        self.album = self.name;
        self.name = streamTitle;
    } else {
        mIsStream = NO;
    }
    
    [self setTrackInfo];
}

#pragma mark -

- (void)setViewStyle:(CurrentsongViewStyle)viewStyle
{
    mViewStyle = viewStyle; [self updateBounds];
}

- (void)setMaxWidth:(CGFloat)maxWidth
{
    mMaxWidth = maxWidth; [self updateBounds];
}

- (void)setShowArtist:(BOOL)showArtist
{
    mShowArtist = showArtist; [self updateBounds];
}

- (void)setShowAlbum:(BOOL)showAlbum
{
    mShowAlbum = showAlbum; [self updateBounds];
}

@end
