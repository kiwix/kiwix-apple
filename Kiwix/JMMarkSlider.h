//
//  JMMarkSlider.h
//  JMMarkSlider
//
//  Created by JOSE MARTINEZ on 22/07/2014.
//  Copyright (c) 2014 desarrolloios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JMMarkSlider : UISlider
@property (nonatomic) UIColor *markColor;
@property (nonatomic) CGFloat markWidth;
@property (nonatomic) NSArray *markPositions;
@property (nonatomic) UIColor *selectedBarColor;
@property (nonatomic) UIColor *unselectedBarColor;
@property (nonatomic) UIImage *handlerImage;
@property (nonatomic) UIColor *handlerColor;
@end
