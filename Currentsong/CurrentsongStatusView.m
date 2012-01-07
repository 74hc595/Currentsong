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

#define kCSViewSideMargin  5

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

- (void)drawSingleRowInRect:(NSRect)rect
{
    if (!mTopRow) {
        return;
    }
        
    NSSize viewSize = [self frame].size;
    NSSize textSize = [mTopRow size];
    NSPoint textOrigin = NSMakePoint(ceil((viewSize.width - textSize.width)/2),
                                     ceil((viewSize.height - textSize.height)/2)+1);
    
    [mTopRow drawAtPoint:textOrigin];
}

- (void)drawRect:(NSRect)rect
{
    [NSGraphicsContext saveGraphicsState];
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    // disabling font smoothing draws text makes it look just like other menu items and the clock
    CGContextSetShouldSmoothFonts(context, NO);
    
    
    if (mTopRow && !mBottomRow) {
        [self drawSingleRowInRect:rect];
    }
    
    [NSGraphicsContext restoreGraphicsState];
}

- (void)updateBounds
{
    CGFloat height = mStatusItem.statusBar.thickness;
    CGFloat topRowWidth = (mTopRow) ? [mTopRow size].width+10 : 0;
    CGFloat bottomRowWidth = (mBottomRow) ? [mBottomRow size].width : 0;
    CGFloat width = MAX(topRowWidth, bottomRowWidth);
    width = MAX(width, 22);
    width += kCSViewSideMargin;
    
    [self setFrame:NSMakeRect(0, 0, width, height)];
}

- (void)setNotPlaying
{
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

@end
