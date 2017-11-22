//
//  OrderViewController.m
//  VShoo
//
//  Created by Vahe Kocharyan on 9/8/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import "OrderViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <SCLAlertView.h>
#import "UIViewController+PopinView.h"
#import "BackgroundView.h"
#import "Utils.h"
#import "Requests.h"
#import "SlideNavigationController.h"

@interface OrderViewController () <UIAlertViewDelegate>

@property (copy, nonatomic) NSString *sessionId;

@end

@implementation OrderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initContentView];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _sessionId = [defaults objectForKey:@"tsmSessionId"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(quickOrderAction:) name:@"OrderActionNotification" object:nil];
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
    CGFloat backgroundViewHeight = contentViewHeight - (contentViewHeight * 3.0f)/100.0f;
    BackgroundView *backgroundView = [[BackgroundView alloc] initWithFrame:CGRectMake(3.0f, 3.0f, backgroundViewWidth, backgroundViewHeight)];
    [backgroundView setPickedAddress:self.myAddress];
    [backgroundView setCarImage:self.currentCarTypeImage];
    [backgroundView setCarTypeName:self.currentCarClassName];
    [backgroundView setBackgroundColor:[UIColor colorWithRed:232.0f/255.0f green:235.0f/255.0f blue:235.0f/255.0f alpha:1.0f]];
    [backgroundView.layer setCornerRadius:5.0f];
    [backgroundView setClipsToBounds:YES];
    [contentView addSubview:backgroundView];
}

#pragma mark -
#pragma mark Order Action

- (void)quickOrderAction:(NSNotification *)notification {
    NSString *url = [Utils getFromPlistWithKey:@"HotzoneURL"];
    NSDictionary *params = @{ @"sessionId": self.sessionId, @"latitude": [NSNumber numberWithDouble:self.lat], @"longitude": [NSNumber numberWithDouble:self.lng] };
    [Requests sendPostRequest:url withParameters:params andCallback:^(NSDictionary *response) {
        NSLog(@"RESSSS :%@", response);
        NSString *result = [response valueForKey:@"result"];
        if ([result isEqualToString:@"OK"]) {
            CGFloat rateCoefficient = [[response valueForKey:@"rateCoefficient"] floatValue];
            if (rateCoefficient > 1.0f) {
                NSLog(@"show alert");
                NSString *title = KKLocalizedString(@"Message");
                NSString *message = [NSString stringWithFormat:KKLocalizedString(@"Currently, you are in hot zone. The estimated price was increased by %fx times. Do you want to continue this order ?"), rateCoefficient];
                if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:KKLocalizedString(@"Yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        [alertController dismissCurrentPopinControllerAnimated:YES completion:^{
                            [self ordering];
                        }];
                    }];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:KKLocalizedString(@"No") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                        [alertController dismissViewControllerAnimated:YES completion:nil];
                    }];
                    [alertController addAction:yesAction];
                    [alertController addAction:cancelAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } else if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:KKLocalizedString(@"No") otherButtonTitles:KKLocalizedString(@"Yes"), nil];
                    [alertView setDelegate:self];
                    [alertView show];
                }
            } else if (rateCoefficient == 1.0f) {
                [self ordering];
            }
        }
    } andFailCallBack:^(NSError *error) {
        NSLog(@"ERR :%@", error);
        [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self];
    }];
}

#pragma mark -
#pragma mark Ordering

- (void)ordering {
    NSLog(@"ordering");
    NSString *url = [Utils getFromPlistWithKey:@"OrderURL"];
    NSDictionary *params = @{ @"sessionId": self.sessionId, @"carType": [NSNumber numberWithUnsignedInteger:self.currentCarClassId], @"latitude": [NSNumber numberWithDouble:self.lat], @"longitude": [NSNumber numberWithDouble:self.lng], @"startAddress": self.currentStartAddress };
    SCLAlertView *alert = [[SCLAlertView alloc] init];
    [self.presentingPopinViewController dismissCurrentPopinControllerAnimated:YES completion:^{
        [Requests sendPostRequest:url withParameters:params andCallback:^(NSDictionary *response) {
            NSLog(@"response :%@", response);
            NSString *result = [response valueForKey:@"result"];
            if ([result isEqualToString:@"OK"]) {
                NSString *title = KKLocalizedString(@"Message");
                NSString *message = [response valueForKey:@"message"];
                BOOL isOrderInProceed = [[response valueForKey:@"isOrderInProceed"] boolValue];
                if (!isOrderInProceed) {
                    [alert showWarning:[SlideNavigationController sharedInstance] title:title subTitle:message closeButtonTitle:@"Dismiss" duration:0.0f];
                } else {
                    BOOL isOrder = [[response valueForKey:@"isOrder"] boolValue];
                    if (isOrder) {
                        [alert showSuccess:[SlideNavigationController sharedInstance] title:@"Success" subTitle:message closeButtonTitle:@"OK" duration:0.0f];
                        [alert alertIsDismissed:^{
                            NSLog(@"start checking availability");
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"AfterOrderSuccessfullyAccepted" object:nil];
                        }];
                    }
                }
            }
        } andFailCallBack:^(NSError *error) {
            NSLog(@"error :%@", error);
            [alert showError:[SlideNavigationController sharedInstance] title:KKLocalizedString(@"ERROR") subTitle:[error localizedDescription] closeButtonTitle:@"OK" duration:0.0f];
        }];
    }];
}

#pragma mark -
#pragma mark UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self ordering];
    }
}

#pragma mark -
#pragma mark Close button action

- (void)closeButtonAction:(UIButton *)sender {
    [self.presentingPopinViewController dismissCurrentPopinControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
