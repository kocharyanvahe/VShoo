//
//  RateViewController.m
//  VShoo
//
//  Created by Vahe Kocharyan on 11/20/15.
//  Copyright © 2015 ConnectTo. All rights reserved.
//

#import "RateViewController.h"
#import "UIViewController+PopinView.h"
#import "EdStarRating.h"
#import "SCLAlertView.h"
#import "Requests.h"
#import "Utils.h"

@interface RateViewController () <EDStarRatingProtocol>

@property (weak, nonatomic) IBOutlet EDStarRating *starRate;
@property (assign, nonatomic) NSUInteger ratingValue;

@end

@implementation RateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _ratingValue = 0;
    UIImage *selectedImage = [UIImage imageNamed:@"RateSelectedImage"];
    UIImage *deselectedImage = [UIImage imageNamed:@"RateDeselectedImage"];
    [_starRate setStarImage:deselectedImage];
    [_starRate setStarHighlightedImage:selectedImage];
    [_starRate setMaxRating:5];
    [_starRate setDelegate:self];
    [_starRate setEditable:YES];
    [_starRate setRating:0.0f];
    [_starRate setDisplayMode:EDStarRatingDisplayFull];
    [_starRate setNeedsDisplay];
    [_starRate setTintColor:[UIColor colorWithRed:242.0f/255.0f green:108.0f/255.0f blue:79.0f/255.0f alpha:1.0f]];
    [self starsSelectionChanged:self.starRate rating:0.0f];
}

#pragma mark -
#pragma mark - Rate delegate methods

- (void)starsSelectionChanged:(EDStarRating *)control rating:(float)rating {
    self.ratingValue = roundf(rating);
}

- (IBAction)closeAction:(id)sender {
    [self callPriceView];
}

- (IBAction)rateAction:(id)sender {
    NSString *url = [Utils getFromPlistWithKey:@"RateDriverURL"];
    NSString *sessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"tsmSessionId"];
    NSDictionary *params = @{ @"sessionId": sessionId, @"rating": [NSNumber numberWithUnsignedInteger:self.ratingValue] };
    [Requests sendPostRequest:url withParameters:params andCallback:^(NSDictionary *response) {
        NSString *result = [response valueForKey:@"result"];
        if ([result isEqualToString:@"OK"]) {
            [self callPriceView];
        }
    } andFailCallBack:^(NSError *error) {
        NSLog(@"ERROR :%@", error);
    }];
}

- (void)callPriceView {
    __weak typeof(self) weakSelf = self;
    [self.presentingPopinViewController dismissCurrentPopinControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowPriceViewNotification" object:weakSelf.message];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
