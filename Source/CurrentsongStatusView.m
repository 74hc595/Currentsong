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
@property (nonatomic,strong) NSString *artist;
@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSString *album;
@property (nonatomic,strong) NSString *rating;
@property (nonatomic,strong) NSAttributedString *topRow;
@property (nonatomic,strong) NSAttributedString *bottomRow;
@property (nonatomic, getter=isScrolling, readonly) BOOL scrolling;
- (void)startScrolling;
- (void)stopScrolling;
@end

#pragma mark -
@implementation CurrentsongStatusView {
    BOOL _highlighted;
    CGFloat _maxWidth;
    BOOL _showPauseIcon;
    BOOL _isStream;
    
    NSAttributedString *_topRow;
    NSAttributedString *_bottomRow;
    CGFloat _topRowScrollOffset;
    CGFloat _bottomRowScrollOffset;
    BOOL _scrollTopRow;
    BOOL _scrollBottomRow;
    NSTimer *_scrollTimer;
    
    CGImageRef _alphaMask;
    BOOL _alphaMaskAccountsForPauseIcon;
}

#pragma mark -
- (void)dealloc
{
    CGImageRelease(_alphaMask);
    [_scrollTimer invalidate];
}

// Mimic the white shadow under menu item text in the menu bar
+ (NSShadow *)menuBarShadow
{
    static NSShadow *shadow = nil;
    if (!shadow) {
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
    [((_highlighted) ? [NSColor whiteColor] : [NSColor blackColor]) set];
    NSRect rect = NSMakeRect(iconOrigin.x,iconOrigin.y,3,9);
    [NSBezierPath fillRect:rect];
    rect.origin.x += 5;
    [NSBezierPath fillRect:rect];
}

- (void)generateEdgeMask
{    
    NSSize viewSize = [self frame].size;
    CGFloat leftEdge = (_showPauseIcon) ? kCSViewPauseIconOffset : 0;
   
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef maskContext = CGBitmapContextCreate(NULL, viewSize.width, viewSize.height, 8, viewSize.width, cs, 0);
    CGColorSpaceRelease(cs);
    
    CGContextSetGrayFillColor(maskContext, 1, 1);
    CGContextFillRect(maskContext, NSRectToCGRect([self bounds]));
    
#if kCSViewFadeEdges
    if (_showPauseIcon) {
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
    CGContextFillRect(maskContext, CGRectMake(viewSize.width-kCSViewSideMargin, 0, kCSViewSideMargin, viewSize.height)); // right edge
    CGContextFillRect(maskContext, CGRectMake(0, 0, leftEdge+kCSViewSideMargin, viewSize.height)); // left edges
#endif
    
    CGImageRelease(_alphaMask);
    _alphaMask = CGBitmapContextCreateImage(maskContext);
    _alphaMaskAccountsForPauseIcon = _showPauseIcon;
    CGContextRelease(maskContext);
}

// Set the clipping mask to clip the left and right edges of text
- (void)setEdgeMask
{    
    NSSize viewSize = [self frame].size;
    
    // generate the mask if necessary
    BOOL needToRegenerateMask = (!_alphaMask ||
                                 CGImageGetWidth(_alphaMask) != viewSize.width ||
                                 CGImageGetHeight(_alphaMask) != viewSize.height ||
                                 _alphaMaskAccountsForPauseIcon != _showPauseIcon);
    
    if (needToRegenerateMask) {
        [self generateEdgeMask];
    }
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextClipToMask(context, NSRectToCGRect([self bounds]), _alphaMask);
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

- (void)drawRect:(NSRect)rect
{
    [_statusItem drawStatusBarBackgroundInRect:[self bounds] withHighlight:_highlighted];
    
    [NSGraphicsContext saveGraphicsState];
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    // disable font smoothing; makes text look like it does in other menu items and the clock
    CGContextSetShouldSmoothFonts(context, NO);

    // add subtle white shadow to match other menu bar text
    if (!_highlighted) {
        [[CurrentsongStatusView menuBarShadow] set];
    }
    
    // draw pause icon
    CGFloat leftEdge = kCSViewSideMargin;
    if (_showPauseIcon) {
        leftEdge += kCSViewPauseIconOffset;
        [self drawPauseIcon];
    }
    
    // set clipping mask and draw text
    BOOL twoRows = ([_topRow length] > 0 && [_bottomRow length] > 0);
    [self setEdgeMask];
    [self drawTextRow:_topRow leftEdge:leftEdge yPosition:((twoRows) ? 11 : kCSDrawTextCentered) scrollOffset:_topRowScrollOffset];
    [self drawTextRow:_bottomRow leftEdge:leftEdge yPosition:((twoRows) ? 1 : kCSDrawTextCentered) scrollOffset:_bottomRowScrollOffset];

    [NSGraphicsContext restoreGraphicsState];
}

- (void)updateBounds
{
    CGFloat height = _statusItem.statusBar.thickness;
    CGFloat topRowWidth = (_topRow) ? [_topRow size].width : 0;
    CGFloat bottomRowWidth = (_bottomRow) ? [_bottomRow size].width : 0;
    CGFloat width = MAX(topRowWidth, bottomRowWidth);
    CGFloat padding = kCSViewSideMargin*2;
    width += padding;
    
    // If _maxWidth is greater than 0, enforce maximum width
    if (_maxWidth > 0) {
        width = MIN(_maxWidth, width);
    }

    if (_showPauseIcon) {
        padding += kCSViewPauseIconOffset;
        width += kCSViewPauseIconOffset;
    }
    
    _scrollTopRow = (topRowWidth > width-padding);
    _scrollBottomRow = (bottomRowWidth > width-padding);
    
    if (_shouldScroll && (_scrollTopRow || _scrollBottomRow) && ![self isScrolling]) {
        [self startScrolling];
    } else if (!(_scrollTopRow || _scrollBottomRow) && [self isScrolling]) {
        [self stopScrolling];
    }
    
    [self setFrame:NSMakeRect(0, 0, width, height)];
    [self setNeedsDisplay:YES];
}

- (void)updateAppearance
{    
    BOOL haveArtist = _showArtist && ([_artist length] > 0);
    BOOL haveName = ([_name length] > 0);
    BOOL haveAlbum = _showAlbum && ([_album length] > 0);
    BOOL haveRating = _showRating && ([_rating length] > 0);
    
    self.bottomRow = nil;
    
    // No track name, not plaing
    if (!haveName) {
        _showPauseIcon = NO;
        self.topRow = [NSAttributedString menuBarAttributedString:@"\u266B" attributes:_highlighted];
    } else {    
        if (_viewStyle == kCSStyleFormatted) {
            NSMutableAttributedString *topRowFormatted = [[NSMutableAttributedString alloc] init];
            NSMutableArray *fields = [NSMutableArray arrayWithCapacity:3];
            if (haveName)   {
                [fields addObject:[NSAttributedString menuBarAttributedString:_name attributes:_highlighted|kCSBold]];
            }
            if (haveArtist) {
                [fields addObject:[NSAttributedString menuBarAttributedString:_artist attributes:_highlighted]];
            }
            if (haveAlbum) {
                [fields addObject:[NSAttributedString menuBarAttributedString:_album attributes:_highlighted|kCSLight]];
            }
            if (haveRating) {
                [fields addObject:[NSAttributedString menuBarAttributedString:_rating attributes:_highlighted|kCSLight]];
            }
        
            BOOL first = YES;
            for (NSAttributedString *astr in fields) {
                if (!first) {
                    [topRowFormatted appendAttributedString:[NSAttributedString menuBarAttributedString:@"  " attributes:_highlighted]];
                }
                [topRowFormatted appendAttributedString:astr];
                first = NO;
            }
            
            self.topRow = topRowFormatted;
            
        } else if (_viewStyle == kCSStyleTwoLevel) {
            self.topRow = [NSAttributedString menuBarAttributedString:_name attributes:_highlighted|kCSBold|kCSSmall];
            NSMutableArray *fields = [NSMutableArray arrayWithCapacity:2];
            if (haveArtist) {
                [fields addObject:_artist];
            }
            if (haveAlbum) {
                [fields addObject:_album];
            }
            if (haveRating) {
                [fields addObject:_rating];
            }
            self.bottomRow = [NSAttributedString menuBarAttributedString:[fields componentsJoinedByString:@" \u2014 "]
                                                              attributes:_highlighted|kCSSmall];            
        } else {
            NSMutableArray *fields = [NSMutableArray arrayWithCapacity:3];
            if (haveName) {
                [fields addObject:_name];
            }
            if (haveArtist) {
                [fields addObject:_artist];
            }
            if (haveAlbum) {
                [fields addObject:_album];
            }
            if (haveRating) {
                [fields addObject:_rating];
            }
            self.topRow = [NSAttributedString menuBarAttributedString:[fields componentsJoinedByString:@" \u2014 "]
                                                           attributes:_highlighted];
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
    _showPauseIcon = ([playerState isEqualToString:@"Stopped"] || [playerState isEqualToString:@"Paused"]);
    
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
    
    // Streaming?
    if (streamTitle) {
        _isStream = YES;
        album = name;
        name = streamTitle;
    } else {
        _isStream = NO;
    }
    
    // Reset scroll offset if the track changed
    if ([self isScrolling] && (![artist isEqualToString:self.artist] ||
        ![name isEqualToString:self.name] ||
        ![album isEqualToString:self.album])) {
        _topRowScrollOffset = kCSViewScrollStartOffset;
        _bottomRowScrollOffset = kCSViewScrollStartOffset;
    }
    
    self.artist = artist;
    self.name = name;
    self.album = album;
    self.rating = rating;
    
    [self updateAppearance];
}


#pragma mark Scrolling

- (BOOL)isScrolling
{
    return (_scrollTimer != nil);
}
        
- (void)startScrolling
{
    if (_scrollTimer) {
        return;
    }
    
    _scrollTimer = [NSTimer scheduledTimerWithTimeInterval:kCSViewScrollTimerFrequency
                                                    target:self
                                                  selector:@selector(scrollTimerFired:)
                                                  userInfo:nil
                                                   repeats:YES];
}

- (void)stopScrolling
{
    if (!_scrollTimer) {
        return;
    }
    
    [_scrollTimer invalidate];
    _scrollTimer = nil;
}

- (void)scrollTimerFired:(NSTimer *)timer
{
    if (_scrollTopRow && _topRow) {
        _topRowScrollOffset += 1;
        if (_topRowScrollOffset >= [_topRow size].width+kCSViewScrollPadding) {
            _topRowScrollOffset = kCSViewScrollStartOffset;
        }
    }
    
    if (_scrollBottomRow && _bottomRow) {
        _bottomRowScrollOffset += 1;
        if (_bottomRowScrollOffset >= [_bottomRow size].width+kCSViewScrollPadding) {
            _bottomRowScrollOffset = kCSViewScrollStartOffset;
        }
    }
    
    [self setNeedsDisplay:YES];
}


#pragma mark Properties

- (void)setHighlighted:(BOOL)highlighted
{
    _highlighted = highlighted; [self updateAppearance];
}

- (void)setViewStyle:(CurrentsongViewStyle)viewStyle
{
    _viewStyle = viewStyle;
    _topRowScrollOffset = kCSViewScrollStartOffset;
    _bottomRowScrollOffset = kCSViewScrollStartOffset;
    [self updateAppearance];
}

- (void)setMaxWidth:(CGFloat)maxWidth
{
    _maxWidth = maxWidth;
    _topRowScrollOffset = kCSViewScrollStartOffset;
    _bottomRowScrollOffset = kCSViewScrollStartOffset;
    [self updateAppearance];
}

- (void)setShowArtist:(BOOL)showArtist
{
    _showArtist = showArtist;
    _topRowScrollOffset = kCSViewScrollStartOffset;
    _bottomRowScrollOffset = kCSViewScrollStartOffset;
    [self updateAppearance];
}

- (void)setShowAlbum:(BOOL)showAlbum
{
    _showAlbum = showAlbum;
    _topRowScrollOffset = kCSViewScrollStartOffset;
    _bottomRowScrollOffset = kCSViewScrollStartOffset;
    [self updateAppearance];
}

- (void)setShowRating:(BOOL)showRating
{
    _showRating = showRating;
    _topRowScrollOffset = kCSViewScrollStartOffset;
    _bottomRowScrollOffset = kCSViewScrollStartOffset;
    [self updateAppearance];

}

- (void)setShowArtist:(BOOL)showArtist showAlbum:(BOOL)showAlbum showRating:(BOOL)showRating viewStyle:(CurrentsongViewStyle)viewStyle
{
    _showArtist = showArtist;
    _showAlbum = showAlbum;
    _showRating = showRating;
    _viewStyle = viewStyle;
    _topRowScrollOffset = kCSViewScrollStartOffset;
    _bottomRowScrollOffset = kCSViewScrollStartOffset;
    [self updateAppearance];    
}

- (void)setShouldScroll:(BOOL)shouldScroll
{
    if (_shouldScroll != shouldScroll) {
        if (!shouldScroll) {
            [self stopScrolling];
        }
        _shouldScroll = shouldScroll;
        _topRowScrollOffset = kCSViewScrollStartOffset;
        _bottomRowScrollOffset = kCSViewScrollStartOffset;
        [self updateAppearance];
    }
}

#pragma mark Events
- (void)mouseDown:(NSEvent *)event
{
    [_statusItem popUpStatusItemMenu:[_statusItem menu]];
    [self setNeedsDisplay:YES];
}

- (void)rightMouseDown:(NSEvent *)event
{
    [self mouseDown:event];
}

@end
