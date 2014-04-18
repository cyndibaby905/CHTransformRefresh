//
//  UIScrollView+CHTransformRefresh.m
//  CHTransformRefresh
//
//  Created by HangChen on 4/18/14.
//  Copyright (c) 2014 Hang Chen (https://github.com/cyndibaby905)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "UIScrollView+CHTransformRefresh.h"
#import "CHTransformLoadingView.h"
#import <objc/runtime.h>




@interface UIImage (Color)
+(UIImage*)imageWithPureColorBackgroundImage:(UIColor*)color withSize:(CGSize)size;
@end

@implementation UIImage (Color)

+(UIImage*)imageWithPureColorBackgroundImage:(UIColor*)color withSize:(CGSize)size
{
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, size.width, size.height));
    
    
    // Build a context that's the same dimensions as the new size
	CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                newRect.size.width,
                                                newRect.size.height,
                                                8,
                                                newRect.size.width * 4,
                                                rgbColorSpace,					
                                                (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
	CGColorSpaceRelease(rgbColorSpace);
	
	// Default white background color.
	CGRect rect = CGRectMake(0, 0, newRect.size.width, newRect.size.height);
	CGContextSetFillColorWithColor(bitmap, color.CGColor);
	CGContextFillRect(bitmap, rect);
	
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    // Clean up
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);
    
    return newImage;
}
@end

#define CHTransformRefreshHeight 103.0

typedef enum
{
    CHTransformRefreshStateDrawing = 0,
	CHTransformRefreshStateLoading,
} CHTransformRefreshState;



static char UIScrollViewTransformRefresh;
@implementation UIScrollView (GifPullToRefresh)


- (void)setRefreshControl:(CHTransformRefreshView *)pullToRefreshView {
    [self willChangeValueForKey:@"pullToRefreshView"];
    objc_setAssociatedObject(self, &UIScrollViewTransformRefresh,
                             pullToRefreshView,
                             OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"pullToRefreshView"];
}

- (CHTransformRefreshView *)refreshControl {
    return objc_getAssociatedObject(self, &UIScrollViewTransformRefresh);
}

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler
{
    
    CHTransformRefreshView *view = [[CHTransformRefreshView alloc] initWithFrame:CGRectMake(0, -CHTransformRefreshHeight, self.bounds.size.width, CHTransformRefreshHeight)];
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0) {
        view.originalContentInsectY = 64;
    }
        
    view.scrollView = self;
    view.pullToRefreshActionHandler = actionHandler;

    [self addSubview:view];
    self.refreshControl = view;
}


- (void)didFinishPullToRefresh
{
    [self.refreshControl endLoading];
}


@end


@implementation CHTransformRefreshView {
    CHTransformRefreshState _state;
    BOOL _isTrigged;
    CHTransformLoadingView *_circleView;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        _circleView = [[CHTransformLoadingView alloc] initWithFrame:self.bounds];
        _circleView.frontContentImage = [UIImage imageWithPureColorBackgroundImage:[UIColor redColor] withSize:CGSizeMake(20, 20)];
        _circleView.backContentImage = [UIImage imageWithPureColorBackgroundImage:[UIColor blueColor] withSize:CGSizeMake(40, 40)];
        _circleView.progress = 0;
        [self addSubview:_circleView];
    }
    return self;
}

- (void)dealloc
{
    [_scrollView removeObserver:self forKeyPath:@"contentOffset"];
    [_scrollView removeObserver:self forKeyPath:@"pan.state"];
}

- (void)setScrollView:(UIScrollView *)scrollView
{
    
    [_scrollView removeObserver:self forKeyPath:@"contentOffset"];
    [_scrollView removeObserver:self forKeyPath:@"pan.state"];
    _scrollView = scrollView;
    [_scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    [_scrollView addObserver:self forKeyPath:@"pan.state" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.scrollView.contentOffset.y + self.originalContentInsectY <= 0) {
        if ([keyPath isEqualToString:@"pan.state"]) {
            if (self.scrollView.panGestureRecognizer.state == UIGestureRecognizerStateEnded && _isTrigged) {
                [self setState:CHTransformRefreshStateLoading];
                [UIView animateWithDuration:0.2
                                      delay:0
                                    options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                                 animations:^{
                                     self.scrollView.contentOffset = CGPointMake(0, -CHTransformRefreshHeight - self.originalContentInsectY);
                                     self.scrollView.contentInset = UIEdgeInsetsMake(CHTransformRefreshHeight + self.originalContentInsectY, 0.0f, 0.0f, 0.0f);
 
                                 }
                                 completion:^(BOOL finished) {
                                     if (self.pullToRefreshActionHandler) {
                                         self.pullToRefreshActionHandler();
                                     }
                                 }];
            }
        }
        else if([keyPath isEqualToString:@"contentOffset"]){
            [self scrollViewContentOffsetChanged];
        }
       
    }
    
}

- (void)scrollViewContentOffsetChanged
{
    if (_state != CHTransformRefreshStateLoading) {
        if (self.scrollView.isDragging && self.scrollView.contentOffset.y + self.originalContentInsectY < -CHTransformRefreshHeight && !_isTrigged) {
            _isTrigged = YES;
        }
        else {
            if (self.scrollView.isDragging && self.scrollView.contentOffset.y + self.originalContentInsectY > -CHTransformRefreshHeight) {
                _isTrigged = NO;
            }
            [self setState:CHTransformRefreshStateDrawing];
        }
    }
}


- (void)setState:(CHTransformRefreshState)aState{
	
	CGFloat offset = -(self.scrollView.contentOffset.y + self.originalContentInsectY);
    CGFloat percent = 0;
    if (offset < 0) {
        offset = 0;
    }
    if (offset > CHTransformRefreshHeight) {
        offset = CHTransformRefreshHeight;
    }
    percent = offset / CHTransformRefreshHeight;
    _circleView.progress = percent;
	switch (aState)
	{
            
        case CHTransformRefreshStateDrawing:
            [_circleView endAnimation];
            break;
            
		case CHTransformRefreshStateLoading:
            [_circleView startAnimation];
            break;
		default:
            break;
	}
	_state = aState;
	
}

- (void)endLoading
{
    if (_state == CHTransformRefreshStateLoading) {
        _isTrigged = NO;

        [self setState:CHTransformRefreshStateDrawing];
        
        [UIView animateWithDuration:0.2
                              delay:0
                            options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.scrollView.contentInset = UIEdgeInsetsMake(self.originalContentInsectY, 0.0f, 0.0f, 0.0f);
                         }
                         completion:nil];
    }
}


@end