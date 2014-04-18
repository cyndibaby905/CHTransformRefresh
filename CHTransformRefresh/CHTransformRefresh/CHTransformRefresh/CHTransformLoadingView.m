//
//  CHProgressCircleView.m
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

#import "CHTransformLoadingView.h"

#define CHTransformLoadingViewBigSize 40
#define CHTransformLoadingViewSmallSize 20
#define CHTransformLoadingViewLoadingSize 30
#define CHTransformLoadingViewPadding 10




@implementation CHTransformLoadingView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        _backView = [[CHCircleProgressView alloc] initWithFrame:CGRectMake((frame.size.width - CHTransformLoadingViewBigSize)/2, frame.size.height - CHTransformLoadingViewBigSize - CHTransformLoadingViewPadding, CHTransformLoadingViewBigSize, CHTransformLoadingViewBigSize)];
        _frontView = [[CHCircleProgressView alloc] initWithFrame:CGRectMake((frame.size.width - CHTransformLoadingViewSmallSize)/2, frame.size.height - CHTransformLoadingViewPadding - (CHTransformLoadingViewBigSize - CHTransformLoadingViewPadding), CHTransformLoadingViewSmallSize, CHTransformLoadingViewSmallSize)];
        [self addSubview:_backView];
        [self addSubview:_frontView];
    }
    return self;
}

- (void)setBackContentImage:(UIImage *)backContentImage
{
    _backContentImage = backContentImage;
    _backView.contentImage = _backContentImage;
    _backView.progress = _progress;
}

- (void)setFrontContentImage:(UIImage *)frontContentImage
{
    _frontContentImage = frontContentImage;
    _frontView.contentImage = _frontContentImage;
    _frontView.progress = 100;
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    _backView.progress = progress;
}


- (void)startAnimation
{

}


- (void)endAnimation
{

}

@end


@implementation CHCircleProgressView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (void)setProgress:(CGFloat)newProgress
{
    newProgress = MIN(MAX(0.0, newProgress), 1.0);
    
    if (_progress != newProgress)
    {
        _progress = newProgress;
        
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
    CGFloat circleRadius = self.bounds.size.width / 2;
    CGPoint circleCenter = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    CGRect circleRect = CGRectMake(circleCenter.x - circleRadius,
                                   circleCenter.y - circleRadius,
                                   2 * circleRadius,
                                   2 * circleRadius);
    
    CGFloat startAngle = -M_PI_2;
    CGFloat endAngle = startAngle + (_progress * 2 * M_PI);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    
    CGContextSaveGState(context);
    
    CGContextMoveToPoint(context, circleCenter.x, circleCenter.y);
    CGContextAddLineToPoint(context, CGRectGetMidX(circleRect), CGRectGetMinY(circleRect));
    CGContextAddArc(context, circleCenter.x, circleCenter.y, circleRadius, startAngle, endAngle, NO);
    CGContextClip(context);
    
    [_contentImage drawInRect:circleRect];
    
    CGContextRestoreGState(context);
}

@end