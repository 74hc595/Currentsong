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

#define kCSViewSideMargin           5
#define kCSViewPauseIconOffset      13
#define kCSViewScrollPadding        20
#define kCSViewScrollDelayInSeconds 3
#define kCSViewScrollTimerFrequency (1.0/30.0)

#define kCSViewFadeEdges            0
#define kCSViewScrollStartOffset    (-kCSViewScrollDelayInSeconds/kCSViewScrollTimerFrequency)

@interface CurrentsongStatusView ()
@property (nonatomic,retain) NSString *artist;
@property (nonatomic,retain) NSString *name;
@property (nonatomic,retain) NSString *album;
@property (nonatomic,retain) NSAttributedString *topRow;
@property (nonatomic,retain) NSAttributedString *bottomRow;
- (BOOL)isScrolling;
- (void)startScrolling;
- (void)stopScrolling;
@end

#pragma mark -
@implementation CurrentsongStatusView

@synthesize statusItem = mStatusItem;
@synthesize viewStyle = mViewStyle;
@synthesize maxWidth = mMaxWidth;
@synthesize showArtist = mShowArtist;
@synthesize showAlbum = mShowAlbum;
@synthesize shouldScroll = mShouldScroll;
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
    CGImageRelease(mAlphaMask);
    [mScrollTimer invalidate];
    [mScrollTimer release];
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

- (void)generateEdgeMask
{    
    NSSize viewSize = [self frame].size;
    CGFloat leftEdge = (mShowPauseIcon) ? kCSViewPauseIconOffset : 0;
   
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef maskContext = CGBitmapContextCreate(NULL, viewSize.width, viewSize.height, 8, viewSize.width, cs, 0);
    CGColorSpaceRelease(cs);
    
    CGContextSetGrayFillColor(maskContext, 1, 1);
    CGContextFillRect(maskContext, [self bounds]);
    
#if kCSViewFadeEdges
    if (mShowPauseIcon) {
        CGContextSetGrayFillColor(maskContext, 0, 1);
        CGContextFillRect(maskContext, NSMakeRect(0, 0, leftEdge, viewSize.height));
    }
    
    CGFloat components[] = {1, 1, 0, 1};
    CGGradientRef gradient = CGGradientCreateWithColorComponents(cs, components, NULL, 2);
    CGContextDrawLinearGradient(maskContext, gradient, CGPointMake(viewSize.width-kCSViewSideMargin, 0), CGPointMake(viewSize.width,0), 0); // right edge
    CGContextDrawLinearGradient(maskContext, gradient, CGPointMake(leftEdge+kCSViewSideMargin,0), CGPointMake(leftEdge,0), 0); // left edge
    CGGradientRelease(gradient);
#else
    CGContextSetGrayFillColor(maskContext, 0, 1);    
    CGContextFillRect(maskContext, NSMakeRect(viewSize.width-kCSViewSideMargin, 0, kCSViewSideMargin, viewSize.height)); // right edge
    CGContextFillRect(maskContext, NSMakeRect(0, 0, leftEdge+kCSViewSideMargin, viewSize.height)); // left edges
#endif
    
    CGImageRelease(mAlphaMask);
    mAlphaMask = CGBitmapContextCreateImage(maskContext);
    mAlphaMaskAccountsForPauseIcon = mShowPauseIcon;
    CGContextRelease(maskContext);
}

- (void)setEdgeMask
{    
    NSSize viewSize = [self frame].size;
    
    // generate the mask if necessary
    BOOL needToRegenerateMask = (!mAlphaMask ||
                                 CGImageGetWidth(mAlphaMask) != viewSize.width ||
                                 CGImageGetHeight(mAlphaMask) != viewSize.height ||
                                 mAlphaMaskAccountsForPauseIcon != mShowPauseIcon);
    
    if (needToRegenerateMask) {
        [self generateEdgeMask];
    }
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextClipToMask(context, [self bounds], mAlphaMask);
}

// If yPosition is less than 0, draw the text centered in the view.
#define kCSDrawTextCentered -1
- (void)drawTextRow:(NSAttributedString *)text leftEdge:(CGFloat)leftEdge yPosition:(CGFloat)y scrollOffset:(CGFloat)scrollOffset
{
    if ([text length] == 0) {
        return;
    }
    
    NSSize viewSize = [self frame].size;
    NSSize topTextSize = [text size];
    CGFloat rightEdge = viewSize.width-kCSViewSideMargin;
    scrollOffset = MAX(0, scrollOffset);
    
    if (y < 0) {
        y = ceil((viewSize.height - topTextSize.height)/2)+1;
    }
    
    NSPoint topTextOrigin = NSMakePoint(rightEdge-topTextSize.width,y);        
    topTextOrigin.x = floor(MAX(leftEdge, topTextOrigin.x) - scrollOffset);
    [text drawAtPoint:topTextOrigin];
    
    // If scrolling, draw a second copy of the text
    if (scrollOffset) {
        topTextOrigin.x += topTextSize.width + kCSViewScrollPadding;
        [text drawAtPoint:topTextOrigin];
    }
}

- (void)drawTextInRect:(NSRect)rect
{
    BOOL twoRows = ([mTopRow length] > 0 && [mBottomRow length] > 0);

    CGFloat leftEdge = kCSViewSideMargin;
    if (mShowPauseIcon) {
        leftEdge += kCSViewPauseIconOffset;
        [self drawPauseIcon];
    }
    
    [self setEdgeMask];
    [self drawTextRow:mTopRow leftEdge:leftEdge yPosition:((twoRows) ? 11 : kCSDrawTextCentered) scrollOffset:mTopRowScrollOffset];
    [self drawTextRow:mBottomRow leftEdge:leftEdge yPosition:((twoRows) ? 1 : kCSDrawTextCentered) scrollOffset:mBottomRowScrollOffset];
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
    
    [self drawTextInRect:rect];

    [NSGraphicsContext restoreGraphicsState];
}

- (void)updateBounds
{
    CGFloat height = mStatusItem.statusBar.thickness;
    CGFloat topRowWidth = (mTopRow) ? [mTopRow size].width : 0;
    CGFloat bottomRowWidth = (mBottomRow) ? [mBottomRow size].width : 0;
    CGFloat width = MAX(topRowWidth, bottomRowWidth);
    CGFloat padding = kCSViewSideMargin*2;
    width += padding;
    
    // If mMaxWidth is greater than 0, enforce maximum width
    if (mMaxWidth > 0) {
        width = MIN(mMaxWidth, width);
    }

    if (mShowPauseIcon) {
        padding += kCSViewPauseIconOffset;
        width += kCSViewPauseIconOffset;
    }
    
    mScrollTopRow = (topRowWidth > width-padding);
    mScrollBottomRow = (bottomRowWidth > width-padding);
    
    if (mShouldScroll && (mScrollTopRow || mScrollBottomRow) && ![self isScrolling]) {
        [self startScrolling];
    } else if (!(mScrollTopRow || mScrollBottomRow) && [self isScrolling]) {
        [self stopScrolling];
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
    NSString *artist = [trackInfo objectForKey:@"Artist"];
    NSString *name = [trackInfo objectForKey:@"Name"];
    NSString *album = [trackInfo objectForKey:@"Album"];
    NSString *streamTitle = [trackInfo objectForKey:@"Stream Title"];   
    NSString *playerState = [trackInfo objectForKey:@"Player State"];
    mShowPauseIcon = ([playerState isEqualToString:@"Stopped"] || [playerState isEqualToString:@"Paused"]);
    
    // Streaming?
    if (streamTitle) {
        mIsStream = YES;
        album = name;
        name = streamTitle;
    } else {
        mIsStream = NO;
    }
    
    // Reset scroll offset if the track changed
    if ([self isScrolling] && (![artist isEqualToString:self.artist] ||
        ![name isEqualToString:self.name] ||
        ![album isEqualToString:self.album]))
    {
        mTopRowScrollOffset = kCSViewScrollStartOffset;
        mBottomRowScrollOffset = kCSViewScrollStartOffset;
    }
    
    self.artist = artist;
    self.name = name;
    self.album = album;
    
    [self updateAppearance];
}


#pragma mark Scrolling

- (BOOL)isScrolling
{
    return (mScrollTimer != nil);
}
        
- (void)startScrolling
{
    if (mScrollTimer) {
        return;
    }
    
    mScrollTimer = [[NSTimer scheduledTimerWithTimeInterval:kCSViewScrollTimerFrequency
                                                     target:self
                                                   selector:@selector(scrollTimerFired:)
                                                   userInfo:nil
                                                    repeats:YES] retain];
}

- (void)stopScrolling
{
    if (!mScrollTimer) {
        return;
    }
    
    [mScrollTimer invalidate];
    [mScrollTimer release];
    mScrollTimer = nil;
}

- (void)scrollTimerFired:(NSTimer *)timer
{
    if (mScrollTopRow && mTopRow) {
        mTopRowScrollOffset += 1;
        if (mTopRowScrollOffset >= [mTopRow size].width+kCSViewScrollPadding) {
            mTopRowScrollOffset = kCSViewScrollStartOffset;
        }
    }
    
    if (mScrollBottomRow && mBottomRow) {
        mBottomRowScrollOffset += 1;
        if (mBottomRowScrollOffset >= [mBottomRow size].width+kCSViewScrollPadding) {
            mBottomRowScrollOffset = kCSViewScrollStartOffset;
        }
    }
    
    [self setNeedsDisplay:YES];
}


#pragma mark Properties

- (void)setHighlighted:(BOOL)highlighted
{
    mHighlighted = highlighted; [self updateAppearance];
}

- (void)setViewStyle:(CurrentsongViewStyle)viewStyle
{
    mViewStyle = viewStyle;
    mTopRowScrollOffset = kCSViewScrollStartOffset;
    mBottomRowScrollOffset = kCSViewScrollStartOffset;
    [self updateAppearance];
}

- (void)setMaxWidth:(CGFloat)maxWidth
{
    mMaxWidth = maxWidth;
    mTopRowScrollOffset = kCSViewScrollStartOffset;
    mBottomRowScrollOffset = kCSViewScrollStartOffset;
    [self updateAppearance];
}

- (void)setShowArtist:(BOOL)showArtist
{
    mShowArtist = showArtist;
    mTopRowScrollOffset = kCSViewScrollStartOffset;
    mBottomRowScrollOffset = kCSViewScrollStartOffset;
    [self updateAppearance];
}

- (void)setShowAlbum:(BOOL)showAlbum
{
    mShowAlbum = showAlbum;
    mTopRowScrollOffset = kCSViewScrollStartOffset;
    mBottomRowScrollOffset = kCSViewScrollStartOffset;
    [self updateAppearance];
}

- (void)setShowArtist:(BOOL)showArtist showAlbum:(BOOL)showAlbum viewStyle:(CurrentsongViewStyle)viewStyle
{
    mShowArtist = showArtist;
    mShowAlbum = showAlbum;
    mViewStyle = viewStyle;
    mTopRowScrollOffset = kCSViewScrollStartOffset;
    mBottomRowScrollOffset = kCSViewScrollStartOffset;
    [self updateAppearance];    
}

- (void)setShouldScroll:(BOOL)shouldScroll
{
    if (mShouldScroll != shouldScroll)
    {
        if (!shouldScroll) {
            [self stopScrolling];
        }
        mShouldScroll = shouldScroll;
        mTopRowScrollOffset = kCSViewScrollStartOffset;
        mBottomRowScrollOffset = kCSViewScrollStartOffset;
        [self updateAppearance];
    }
}

#pragma mark Events
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
