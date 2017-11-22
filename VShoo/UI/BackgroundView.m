//
//  BackgroundView.m
//  VShoo
//
//  Created by Vahe Kocharyan on 9/9/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import "BackgroundView.h"
#import "Utils.h"
#import "UIImage+Resize.h"

@implementation BackgroundView

- (void)drawRect:(CGRect)rect {
    UIImage *startLocationIcon = [UIImage imageNamed:@"StartingPointLocationIcon"];
    UIImage *carBackgroundCircleImage = [UIImage imageNamed:@"CarBackgroundCircleImage"];
    CGFloat rectWidth = rect.size.width;
    CGFloat rectHeight = rect.size.height;
    CGFloat topLineX = rectWidth - (rectWidth * 85.0f)/100.0f;
    CGFloat topLineY = rectHeight - (rectHeight * 55.0f)/100.0f;
    CGFloat topLineWidth = rectWidth - (rectWidth * 15.0f)/100.0f;
    CGFloat bottomLineX = rectWidth - (rectWidth * 95.0f)/100.0f;
    CGFloat bottomLineY = rectHeight - (rectHeight * 25.0f)/100.0f;
    CGFloat bottomLineWidth = rectWidth - (rectWidth * 5.0f)/100.0f;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0f);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGFloat components[] = { 127.0f/255.0f, 127.0f/255.0f, 127.0f/255.0f, 1.0f };
    CGColorRef color = CGColorCreate(colorspace, components);
    CGContextSetStrokeColorWithColor(context, color);
    CGContextMoveToPoint(context, topLineX, topLineY);
    CGContextAddLineToPoint(context, topLineWidth, topLineY);
    CGContextMoveToPoint(context, bottomLineX, bottomLineY);
    CGContextAddLineToPoint(context, bottomLineWidth, bottomLineY);
    CGContextStrokePath(context);
    CGColorSpaceRelease(colorspace);
    CGColorRelease(color);
    NSString *currentiOSPlatform = [Utils platformString];
    CGFloat startLocationIconX = rectWidth - (rectWidth * 97.0f)/100.0f;
    CGFloat startLocationIconY = rectHeight - (rectHeight * 75.0f)/100.0f;
    UIImageView *starLocationImageView = [[UIImageView alloc] initWithImage:startLocationIcon];
    [starLocationImageView setFrame:CGRectMake(startLocationIconX, startLocationIconY, startLocationIcon.size.width, startLocationIcon.size.height)];
    [self addSubview:starLocationImageView];
    UIImageView *carBackgroundCircleImageView = [[UIImageView alloc] initWithImage:carBackgroundCircleImage];
    [carBackgroundCircleImageView setFrame:CGRectMake(startLocationIconX, startLocationIconY + 50.0f, carBackgroundCircleImage.size.width, carBackgroundCircleImage.size.height)];
    [self addSubview:carBackgroundCircleImageView];
    CGFloat carImageViewX = (carBackgroundCircleImage.size.width * 15.0f)/100.0f;
    CGFloat carImageViewY = (carBackgroundCircleImage.size.height * 20.0f)/100.0f;
    CGFloat carImageViewWidth = carBackgroundCircleImage.size.width - (carBackgroundCircleImage.size.width * 30.0f)/100.0f;
    CGFloat carImageViewHeight = carBackgroundCircleImage.size.height - (carBackgroundCircleImage.size.height * 60.0f)/100.0f;
    _carImage = [_carImage resizedImage:CGSizeMake(carImageViewWidth * 2.0f, carImageViewHeight * 2.0f) interpolationQuality:kCGInterpolationHigh];
    UIImageView *carImageView = [[UIImageView alloc] initWithFrame:CGRectMake(carImageViewX, carImageViewY, carImageViewWidth, carImageViewHeight)];
    [carImageView setImage:self.carImage];
    [carBackgroundCircleImageView addSubview:carImageView];
    CGFloat startLocationLabelX = 0.0f;
    CGFloat startLocationLabelY = rectHeight - (rectHeight * 80.0f)/100.0f;
    CGFloat startLocationLabelWidth = rectWidth - (rectWidth * 18.0f)/100.0f;
    CGFloat startLocationLabelHeight = 0.0f;
    if ([currentiOSPlatform isEqualToString:@"iPhone 4/4S"]) {
        startLocationLabelX = rectWidth - (rectWidth * 80.0f)/100.0f;
        startLocationLabelHeight = 40.0f;
    } else if ([currentiOSPlatform isEqualToString:@"iPhone 5/5S/5C"]) {
        startLocationLabelX = rectWidth - (rectWidth * 82.0f)/100.0f;
        startLocationLabelHeight = 45.0f;
    } else if ([currentiOSPlatform isEqualToString:@"iPhone 6"]) {
        startLocationLabelX = rectWidth - (rectWidth * 81.0f)/100.0f;
        startLocationLabelHeight = 50.0f;
    } else if ([currentiOSPlatform isEqualToString:@"iPhone 6+"]) {
        startLocationLabelX = rectWidth - (rectWidth * 81.0f)/100.0f;
        startLocationLabelHeight = 55.0f;
    } else if ([currentiOSPlatform isEqualToString:@"iPad"] || [currentiOSPlatform isEqualToString:@"iPad 2"] || [currentiOSPlatform isEqualToString:@"iPad Mini"] || [currentiOSPlatform isEqualToString:@"iPad 3"] ||
               [currentiOSPlatform isEqualToString:@"iPad 4"] || [currentiOSPlatform isEqualToString:@"iPad Air"] || [currentiOSPlatform isEqualToString:@"iPad Mini Retina"] || [currentiOSPlatform isEqualToString:@"iPad Air 2"]) {
        startLocationLabelX = rectWidth - (rectWidth * 81.0f)/100.0f;
        startLocationLabelHeight = 55.0f;
    }
    UILabel *startLocationLabel = [[UILabel alloc] initWithFrame:CGRectMake(startLocationLabelX, startLocationLabelY, startLocationLabelWidth, startLocationLabelHeight)];
    [startLocationLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [startLocationLabel setNumberOfLines:2];
    [startLocationLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:16.0f]];
    [startLocationLabel setTextColor:[UIColor colorWithRed:53.0f/255.0f green:54.0f/255.0f blue:54.0f/255.0f alpha:1.0f]];
    [startLocationLabel setText:self.pickedAddress];
    [self addSubview:startLocationLabel];
    UILabel *carTypeLabel = [[UILabel alloc] initWithFrame:CGRectMake(startLocationLabelX + 5.0f, carBackgroundCircleImageView.frame.origin.y - 10.0f, startLocationLabelWidth, startLocationLabelHeight)];
    [carTypeLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:16.0f]];
    [carTypeLabel setTextColor:[UIColor colorWithRed:53.0f/255.0f green:54.0f/255.0f blue:54.0f/255.0f alpha:1.0f]];
    [carTypeLabel setText:self.carTypeName];
    [self addSubview:carTypeLabel];
    CGFloat orderButtonWidth = self.bounds.size.width - (self.bounds.size.width * 50.0f)/100.0f;
    CGFloat orderButtonHeight = self.bounds.size.height - (self.bounds.size.height * 80.0f)/100.0f;
    CGFloat orderButtonX = self.bounds.size.width - orderButtonWidth - 2.0f;
    CGFloat orderButtonY = self.bounds.size.height - orderButtonHeight - 2.0f;
    UIButton *orderButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [orderButton setFrame:CGRectMake(orderButtonX, orderButtonY, orderButtonWidth, orderButtonHeight)];
    [orderButton.titleLabel setFont:[UIFont systemFontOfSize:16.0f]];
    [orderButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [orderButton setTitle:KKLocalizedString(@"Order") forState:UIControlStateNormal];
    [orderButton setBackgroundColor:[UIColor colorWithRed:72.0f/255.0f green:224.0f/255.0f blue:109.0f/255.0f alpha:1.0f]];
    [orderButton addTarget:self action:@selector(orderAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:orderButton];
}

#pragma mark -
#pragma mark Order Action

- (void)orderAction {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"OrderActionNotification" object:nil];
}

@end
