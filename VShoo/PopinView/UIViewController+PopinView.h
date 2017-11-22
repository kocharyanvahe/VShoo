//
//  UIViewController+PopinView.h
//  VShoo
//
//  Created by Vahe Kocharyan on 7/24/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BKTBlurParameters : NSObject

@property (assign, nonatomic) CGFloat alpha;
@property (assign, nonatomic) CGFloat radius;
@property (assign, nonatomic) CGFloat saturationDeltaFactor;
@property (strong, nonatomic) UIColor *tintColor;

@end

typedef NS_ENUM(NSInteger, BKTPopinTransitionStyle) {
    BKTPopinTransitionStyleSlide,
    BKTPopinTransitionStyleCrossDissolve,
    BKTPopinTransitionStyleZoom,
    BKTPopinTransitionStyleSpringySlide,
    BKTPopinTransitionStyleSpringyZoom,
    BKTPopinTransitionStyleSnap,
    BKTPopinTransitionStyleCustom
};

typedef NS_ENUM(NSInteger, BKTPopinTransitionDirection) {
    BKTPopinTransitionDirectionBottom = 0,
    BKTPopinTransitionDirectionTop,
    BKTPopinTransitionDirectionLeft,
    BKTPopinTransitionDirectionRight
};

typedef NS_OPTIONS(NSUInteger, BKTPopinOption) {
    BKTPopinDefault = 0,
    BKTPopinIgnoreKeyboardNotification = 1 << 0,
    BKTPopinDisableAutoDismiss = 1 << 1,
    BKTPopinBlurryDimmingView = 1 << 2,
    BKTPopinDisableParallaxEffect = 1 << 3,
    BKTPopinDimmingViewStyleNone = 1 << 16,
};

typedef NS_ENUM(NSInteger, BKTPopinAlignementOption) {
    BKTPopinAlignementOptionCentered = 0,
    BKTPopinAlignementOptionUp       = 1,
    BKTPopinAlignementOptionLeft     = 2,
    BKTPopinAlignementOptionDown     = 3,
    BKTPopinAlignementOptionRight    = 4
};

@interface UIViewController (PopinView) <UIDynamicAnimatorDelegate>

- (void)presentPopinController:(UIViewController *)popinController animated:(BOOL)animated completion:(void(^)(void))completion;
- (void)presentPopinController:(UIViewController *)popinController fromRect:(CGRect)rect animated:(BOOL)animated completion:(void(^)(void))completion;
- (void)dismissCurrentPopinControllerAnimated:(BOOL)animated;
- (void)dismissCurrentPopinControllerAnimated:(BOOL)animated completion:(void(^)(void))completion;
- (UIViewController *)presentedPopinViewController;
- (UIViewController *)presentingPopinViewController;
- (CGSize)preferedPopinContentSize;
- (void)setPreferedPopinContentSize:(CGSize)preferredSize;
- (BKTPopinTransitionStyle)popinTransitionStyle;
- (void)setPopinTransitionStyle:(BKTPopinTransitionStyle)transitionStyle;
- (BKTPopinTransitionDirection)popinTransitionDirection;
- (void)setPopinTransitionDirection:(BKTPopinTransitionDirection)transitionDirection;
- (BKTPopinOption)popinOptions;
- (void)setPopinOptions:(BKTPopinOption)popinOptions;
- (void (^)(UIViewController * popinController,CGRect initialFrame,CGRect finalFrame))popinCustomInAnimation;
- (void)setPopinCustomInAnimation:(void (^)(UIViewController * popinController,CGRect initialFrame,CGRect finalFrame))customInAnimation;
- (void (^)(UIViewController * popinController,CGRect initialFrame,CGRect finalFrame))popinCustomOutAnimation;
- (void)setPopinCustomOutAnimation:(void (^)(UIViewController * popinController,CGRect initialFrame,CGRect finalFrame))customOutAnimation;
- (BKTPopinAlignementOption)popinAlignment;
- (void)setPopinAlignment:(BKTPopinAlignementOption)popinAlignment;
- (BKTBlurParameters *)blurParameters;
- (void)setBlurParameters:(BKTBlurParameters *)blurParameters;

@end
