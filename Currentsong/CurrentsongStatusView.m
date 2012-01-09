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
@synthesize highlighted = mHighlighted;

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
    [((mHighlighted) ? [NSColor whiteColor] : [NSColor blackColor]) set];
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

- (void)drawTwoRowsInRect:(NSRect)rect
{
    if (!mTopRow || !mBottomRow) {
        return;
    }
    
    NSSize viewSize = [self frame].size;
    NSSize topTextSize = [mTopRow size];
    NSSize bottomTextSize = [mBottomRow size];
        
    CGFloat leftEdge = kCSViewSideMargin;
    CGFloat rightEdge = viewSize.width-kCSViewSideMargin;
    if (mShowPauseIcon) {
        leftEdge += kCSViewPauseIconOffset;
        [self drawPauseIcon];
    }
    
    NSPoint topTextOrigin = NSMakePoint(rightEdge-topTextSize.width,11);
    NSPoint bottomTextOrigin = NSMakePoint(rightEdge-bottomTextSize.width,1);
    topTextOrigin.x = MAX(leftEdge, topTextOrigin.x);
    bottomTextOrigin.x = MAX(leftEdge, bottomTextOrigin.x);
    
    [mTopRow drawAtPoint:topTextOrigin];
    [mBottomRow drawAtPoint:bottomTextOrigin];
}

- (void)drawRect:(NSRect)rect
{
    [mStatusItem drawStatusBarBackgroundInRect:[self bounds] withHighlight:mHighlighted];
    
    [NSGraphicsContext saveGraphicsState];
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    // disabling font smoothing draws text makes it look just like other menu items and the clock
    CGContextSetShouldSmoothFonts(context, NO);
    
    // add subtle white shadow to match other menu bar text
    if (!mHighlighted) {
        [[CurrentsongStatusView menuBarShadow] set];
    }
    
    if ([mTopRow length] > 0 && [mBottomRow length] == 0) {
        [self drawSingleRowInRect:rect];
    } else {
        [self drawTwoRowsInRect:rect];
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

- (void)updateAppearance
{    
    BOOL haveArtist = mShowArtist && ([mArtist length] > 0);
    BOOL haveName = ([mName length] > 0);
    BOOL haveAlbum = mShowAlbum && ([mAlbum length] > 0);
    
    self.bottomRow = nil;
    
    // No track name, not plaing
    if (!haveName) {
        mShowPauseIcon = NO;
        self.topRow = [NSAttributedString menuBarAttributedString:@"\u266B" attributes:mHighlighted];
    } else {    
        if (mViewStyle == kCSStyleFormatted)
        {
            NSMutableAttributedString *topRowFormatted = [[[NSMutableAttributedString alloc] init] autorelease];
            NSMutableArray *fields = [NSMutableArray arrayWithCapacity:3];
            if (haveName)   [fields addObject:[NSAttributedString menuBarAttributedString:mName attributes:mHighlighted|kCSBold]];
            if (haveArtist) [fields addObject:[NSAttributedString menuBarAttributedString:mArtist attributes:mHighlighted]];
            if (haveAlbum)  [fields addObject:[NSAttributedString menuBarAttributedString:mAlbum attributes:mHighlighted|kCSLight]];
            
            BOOL first = YES;
            for (NSAttributedString *astr in fields)
            {
                if (!first) [topRowFormatted appendAttributedString:
                             [NSAttributedString menuBarAttributedString:@"  " attributes:mHighlighted]];
                [topRowFormatted appendAttributedString:astr];
                first = NO;
            }
            
            self.topRow = topRowFormatted;
            
        }
        else if (mViewStyle == kCSStyleTwoLevel)
        {
            self.topRow = [NSAttributedString menuBarAttributedString:mName attributes:mHighlighted|kCSBold|kCSSmall];
            NSMutableArray *fields = [NSMutableArray arrayWithCapacity:2];
            if (haveArtist) [fields addObject:mArtist];
            if (haveAlbum)  [fields addObject:mAlbum];
            self.bottomRow = [NSAttributedString menuBarAttributedString:[fields componentsJoinedByString:@" \u2014 "]
                                                              attributes:mHighlighted|kCSSmall];            
        }
        else
        {
            NSMutableArray *fields = [NSMutableArray arrayWithCapacity:3];
            if (haveName)   [fields addObject:mName];
            if (haveArtist) [fields addObject:mArtist];
            if (haveAlbum)  [fields addObject:mAlbum];
            
            self.topRow = [NSAttributedString menuBarAttributedString:[fields componentsJoinedByString:@" \u2014 "]
                                                           attributes:mHighlighted];
        }
    }
    
    [self updateBounds];
}

- (void)updateTrackInfo:(NSDictionary *)trackInfo
{        
    self.artist = [trackInfo objectForKey:@"Artist"];
    self.name = [trackInfo objectForKey:@"Name"];
    self.album = [trackInfo objectForKey:@"Album"];
    NSString *streamTitle = [trackInfo objectForKey:@"Stream Title"];   
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
    
    [self updateAppearance];
}


#pragma mark -

- (void)setHighlighted:(BOOL)highlighted
{
    mHighlighted = highlighted; [self updateAppearance];
}

- (void)setViewStyle:(CurrentsongViewStyle)viewStyle
{
    mViewStyle = viewStyle; [self updateAppearance];
}

- (void)setMaxWidth:(CGFloat)maxWidth
{
    mMaxWidth = maxWidth; [self updateAppearance];
}

- (void)setShowArtist:(BOOL)showArtist
{
    mShowArtist = showArtist; [self updateAppearance];
}

- (void)setShowAlbum:(BOOL)showAlbum
{
    mShowAlbum = showAlbum; [self updateAppearance];
}


#pragma mark -
- (void)mouseDown:(NSEvent *)event
{
    [mStatusItem popUpStatusItemMenu:[mStatusItem menu]];
    [self setNeedsDisplay:YES];
}

- (void)rightMouseDown:(NSEvent *)event
{
    [self mouseDown:event];
}

@end
