//
//  SliderSegmentedControl.h
//  VShoo
//
//  Created by Vahe Kocharyan on 7/6/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class SliderSegmentedControl;

@protocol SliderSegmentedControlDelegate <NSObject>

@optional

- (void)timeSlider:(SliderSegmentedControl *)timeSlider didSelectPointAtIndex:(int)index;

@end

@interface SliderSegmentedControl : UIView {
    UIBezierPath *_drawPath;
    CGContextRef _context;
    NSMutableArray *_positionPoints;
    int _moveFinalIndex;
    bool firstTimeOnly;
}

@property (assign, nonatomic) float spaceBetweenPoints;
@property (assign, nonatomic) float numberOfPoints;
@property (assign, nonatomic) float heightLine;
@property (assign, nonatomic) float radiusPoint;
@property (assign, nonatomic) CGSize shadowSize;
@property (assign, nonatomic) float shadowBlur;
@property (assign, nonatomic) float strokeSize;
@property (strong, nonatomic) UIColor *strokeColor;
@property (strong, nonatomic) UIColor *shadowColor;
@property (assign, nonatomic) BOOL touchEnabled;
@property (assign, nonatomic, readonly) int currentIndex;
@property (assign, nonatomic) CGGradientRef gradientForeground;
@property (assign, nonatomic) float strokeSizeForeground;
@property (strong, nonatomic) UIColor *strokeColorForeground;
@property (assign, nonatomic) float radiusCircle;
@property (strong, nonatomic) UIImageView *holderView;
@property (weak, nonatomic) id<SliderSegmentedControlDelegate> delegate;

- (void)moveToIndex:(int)index;
- (CGPoint)positionForPointAtIndex:(int)index;

@end
