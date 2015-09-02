//
//  JMMarkSlider.m
//  JMMarkSlider
//
//  Created by JOSE MARTINEZ on 22/07/2014.
//  Copyright (c) 2014 desarrolloios. All rights reserved.
//

#import "JMMarkSlider.h"

@implementation JMMarkSlider

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Default configuration
        self.markColor = [UIColor colorWithRed:106/255.0 green:106/255.0 blue:124/255.0 alpha:0.7];
        self.markPositions = @[@10,@20,@30,@40,@50,@60,@70,@80,@90,@100];
        self.markWidth = 1.0;
        self.selectedBarColor = [UIColor colorWithRed:179/255.0 green:179/255.0 blue:193/255.0 alpha:0.8];
        self.unselectedBarColor = [UIColor colorWithRed:55/255.0 green:55/255.0 blue:94/255.0 alpha:0.8];

    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Default configuration
        self.markColor = [UIColor colorWithRed:106/255.0 green:106/255.0 blue:124/255.0 alpha:0.7];
        self.markPositions = @[@10,@20,@30,@40,@50,@60,@70,@80,@90,@100];
        self.markWidth = 1.0;
        self.selectedBarColor = [UIColor colorWithRed:179/255.0 green:179/255.0 blue:193/255.0 alpha:0.8];
        self.unselectedBarColor = [UIColor colorWithRed:55/255.0 green:55/255.0 blue:94/255.0 alpha:0.8];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    // We create an innerRect in which we paint the lines
    CGRect innerRect = CGRectInset(rect, 1.0, 10.0);
    
    UIGraphicsBeginImageContextWithOptions(innerRect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Selected side
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, 12.0);
    CGContextMoveToPoint(context, 6, CGRectGetHeight(innerRect)/2);
    CGContextAddLineToPoint(context, innerRect.size.width - 10, CGRectGetHeight(innerRect)/2);
    CGContextSetStrokeColorWithColor(context, [self.selectedBarColor CGColor]);
    CGContextStrokePath(context);
    UIImage *selectedSide = [UIGraphicsGetImageFromCurrentImageContext() resizableImageWithCapInsets:UIEdgeInsetsZero];
    
    // Unselected side
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, 12.0);
    CGContextMoveToPoint(context, 6, CGRectGetHeight(innerRect)/2);
    CGContextAddLineToPoint(context, innerRect.size.width - 10, CGRectGetHeight(innerRect)/2);
    CGContextSetStrokeColorWithColor(context, [self.unselectedBarColor CGColor]);
    CGContextStrokePath(context);
    UIImage *unselectedSide = [UIGraphicsGetImageFromCurrentImageContext() resizableImageWithCapInsets:UIEdgeInsetsZero];
    
    // Set trips on selected side
    [selectedSide drawAtPoint:CGPointMake(0,0)];
    for (int i = 0; i < [self.markPositions count]; i++) {
        CGContextSetLineWidth(context, self.markWidth);
        float position = [self.markPositions[i]floatValue] * innerRect.size.width / 100.0;
        CGContextMoveToPoint(context, position, CGRectGetHeight(innerRect)/2 - 5);
        CGContextAddLineToPoint(context, position, CGRectGetHeight(innerRect)/2 + 5);
        CGContextSetStrokeColorWithColor(context, [self.markColor CGColor]);
        CGContextStrokePath(context);
    }
    UIImage *selectedStripSide = [UIGraphicsGetImageFromCurrentImageContext() resizableImageWithCapInsets:UIEdgeInsetsZero];
    
    // Set trips on unselected side
    [unselectedSide drawAtPoint:CGPointMake(0,0)];
    for (int i = 0; i < [self.markPositions count]; i++) {
        CGContextSetLineWidth(context, self.markWidth);
        float position = [self.markPositions[i]floatValue] * innerRect.size.width / 100.0;
        CGContextMoveToPoint(context, position, CGRectGetHeight(innerRect)/2 - 5);
        CGContextAddLineToPoint(context, position, CGRectGetHeight(innerRect)/2 + 5);
        CGContextSetStrokeColorWithColor(context, [self.markColor CGColor]);
        CGContextStrokePath(context);
    }
    UIImage *unselectedStripSide = [UIGraphicsGetImageFromCurrentImageContext() resizableImageWithCapInsets:UIEdgeInsetsZero];
    
    UIGraphicsEndImageContext();
    
    [self setMinimumTrackImage:selectedStripSide forState:UIControlStateNormal];
    [self setMaximumTrackImage:unselectedStripSide forState:UIControlStateNormal];
    if (self.handlerImage != nil) {
        [self setThumbImage:self.handlerImage forState:UIControlStateNormal];
    } else if (self.handlerColor != nil) {
        [self setThumbImage:[UIImage new] forState:UIControlStateNormal];
        [self setThumbTintColor:self.handlerColor];
    }
}

@end
