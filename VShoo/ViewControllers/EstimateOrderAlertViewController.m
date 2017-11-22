//
//  EstimateOrderAlertViewController.m
//  VShoo
//
//  Created by Vahe Kocharyan on 9/7/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import "EstimateOrderAlertViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIViewController+PopinView.h"
#import "Utils.h"

@interface EstimateOrderAlertViewController ()

@end

@implementation EstimateOrderAlertViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initContentView];
}

#pragma mark -
#pragma mark Init Content View

- (void)initContentView {
    UIImage *alertCancelImage = [UIImage imageNamed:@"AlertCancelImage"];
    UIImage *alertCancelPressedImage = [UIImage imageNamed:@"AlertCancelPressedImage"];
    CGFloat contentViewX = alertCancelImage.size.width/2.0f;
    CGFloat contentViewY = alertCancelImage.size.height/2.0f;
    CGFloat contentViewWidth = self.contentWidth - alertCancelImage.size.width;
    CGFloat contentViewHeight = self.contentHeight - contentViewY;
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(contentViewX, contentViewY, contentViewWidth, contentViewHeight)];
    UIColor *fromColor = [UIColor colorWithRed:227.0f/255.0f green:87.0f/255.0f blue:72.0f/255.0f alpha:1.0f];
    UIColor *toColor = [UIColor colorWithRed:242.0f/255.0f green:182.0f/255.0f blue:168.0f/255.0f alpha:1.0f];
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    [gradientLayer setStartPoint:CGPointMake(0.0f, 0.5f)];
    [gradientLayer setEndPoint:CGPointMake(1.0f, 0.5f)];
    [gradientLayer setColors:@[(id)fromColor.CGColor, (id)toColor.CGColor]];
    [gradientLayer setFrame:[contentView bounds]];
    [contentView.layer setCornerRadius:10.0f];
    [contentView setClipsToBounds:YES];
    [contentView.layer insertSublayer:gradientLayer atIndex:0];
    [self.view addSubview:contentView];
    [self.view sendSubviewToBack:contentView];
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton setImage:alertCancelImage forState:UIControlStateNormal];
    [closeButton setImage:alertCancelPressedImage forState:UIControlStateHighlighted];
    [closeButton setFrame:CGRectMake(contentViewWidth, 0.0f, alertCancelImage.size.width, alertCancelImage.size.height)];
    [closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    CGFloat backgroundViewWidth = contentViewWidth - (contentViewWidth * 3.0f)/100.0f;
    CGFloat backgroundViewHeight = contentViewHeight - (contentViewHeight * 2.5f)/100.0f;
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(4.0f, 4.0f, backgroundViewWidth, backgroundViewHeight)];
    [backgroundView setBackgroundColor:[UIColor colorWithRed:242.0f/255.0f green:108.0f/255.0f blue:79.0f/255.0f alpha:1.0f]];
    [backgroundView.layer setCornerRadius:5.0f];
    [contentView addSubview:backgroundView];
    
    CGFloat titleLabelWidth = backgroundViewWidth - (backgroundViewWidth * 5.0f)/100.0f;
    CGFloat titleLabelHeight = backgroundViewHeight - (backgroundViewHeight * 85.0f)/100.0f;
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(5.0f, 5.0f, titleLabelWidth, titleLabelHeight)];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [titleLabel setTextColor:[UIColor colorWithRed:236.0f/255.0f green:240.0f/255.0f blue:241.0f/255.0f alpha:1.0f]];
    [titleLabel setText:self.alertTitle];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:20.0f]];
    [backgroundView addSubview:titleLabel];
    
    CGFloat bodyLabelY = titleLabelHeight + 10.0f;
    UILabel *bodyLabel = [[UILabel alloc] initWithFrame:CGRectMake(5.0f, bodyLabelY, titleLabelWidth, 100.0f)];
    [bodyLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [bodyLabel setNumberOfLines:4];
    [bodyLabel setTextColor:[UIColor colorWithRed:236.0f/255.0f green:240.0f/255.0f blue:241.0f/255.0f alpha:1.0f]];
    [bodyLabel setTextAlignment:NSTextAlignmentCenter];
    [bodyLabel setFont:[UIFont systemFontOfSize:15.0f]];
    [bodyLabel setText:self.alertBody];
    [backgroundView addSubview:bodyLabel];
    
    UIButton *orderButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [orderButton setFrame:CGRectMake(5.0f, 160.0f, titleLabelWidth, 40.0f)];
    [orderButton setBackgroundColor:[UIColor colorWithRed:226.0f/255.0f green:229.0f/255.0f blue:230.0f/255.0f alpha:1.0f]];
    [orderButton setTitleColor:[UIColor colorWithRed:53.0f/255.0f green:54.0f/255.0f blue:54.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
    [orderButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:24.0f]];
    [orderButton setTitle:KKLocalizedString(@"Order") forState:UIControlStateNormal];
    [orderButton addTarget:self action:@selector(orderButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [backgroundView addSubview:orderButton];
    
    UIButton *estimateButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [estimateButton setFrame:CGRectMake(5.0f, 205.0f, titleLabelWidth, 40.0f)];
    [estimateButton setBackgroundColor:[UIColor colorWithRed:226.0f/255.0f green:229.0f/255.0f blue:230.0f/255.0f alpha:1.0f]];
    [estimateButton setTitleColor:[UIColor colorWithRed:53.0f/255.0f green:54.0f/255.0f blue:54.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
    [estimateButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:24.0f]];
    [estimateButton setTitle:KKLocalizedString(@"Estimate") forState:UIControlStateNormal];
    [estimateButton addTarget:self action:@selector(estimateAction:) forControlEvents:UIControlEventTouchUpInside];
    [backgroundView addSubview:estimateButton];
}

#pragma mark -
#pragma mark Close button action

- (void)closeButtonAction:(UIButton *)sender {
    [self.presentingPopinViewController dismissCurrentPopinControllerAnimated:YES];
}

#pragma mark -
#pragma mark Order Action

- (void)orderButtonAction:(UIButton *)sender {
    [self.presentingPopinViewController dismissCurrentPopinControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"OrderNotification" object:self.locationAddress];
    }];
}

#pragma mark -
#pragma mark Estimate Action

- (void)estimateAction:(UIButton *)sender {
    [self.presentingPopinViewController dismissCurrentPopinControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PushEstimationViewControllerNotification" object:self];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
