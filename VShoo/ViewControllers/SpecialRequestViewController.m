//
//  SpecialRequestViewController.m
//  VShoo
//
//  Created by Vahe Kocharyan on 11/30/15.
//  Copyright © 2015 ConnectTo. All rights reserved.
//

#import "SpecialRequestViewController.h"
#import "UIViewController+PopinView.h"

@interface SpecialRequestViewController ()

@property (strong, nonatomic) UIImage *checkedImage;
@property (assign, nonatomic) NSUInteger wheelChairSelected;
@property (assign, nonatomic) NSUInteger childCarSeatSelected;
@property (assign, nonatomic) NSUInteger securityCameraSelected;

@end

@implementation SpecialRequestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _checkedImage = [UIImage imageNamed:@"CheckedImage"];
    _wheelChairSelected = 0;
    _childCarSeatSelected = 0;
    _securityCameraSelected = 0;
}

- (IBAction)okAction {
    NSLog(@"ok");
    NSArray *args = @[@(self.wheelChairSelected), @(self.childCarSeatSelected), @(self.securityCameraSelected)];
    [self.presentingPopinViewController dismissCurrentPopinControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"GetSpecialRequestArguments" object:args];
    }];
}

- (IBAction)wheelChairAccessTapped:(UITapGestureRecognizer *)sender {
    UIImageView *wheelImageView = (UIImageView *)[sender view];
    if ([wheelImageView image] == nil) {
        self.wheelChairSelected = 1;
        [wheelImageView setImage:self.checkedImage];
    } else {
        self.wheelChairSelected = 0;
        [wheelImageView setImage:nil];
    }
}

- (IBAction)childCarSeatTapped:(UITapGestureRecognizer *)sender {
    UIImageView *childCarSeatImageView = (UIImageView *)[sender view];
    if ([childCarSeatImageView image] == nil) {
        self.childCarSeatSelected = 1;
        [childCarSeatImageView setImage:self.checkedImage];
    } else {
        self.childCarSeatSelected = 0;
        [childCarSeatImageView setImage:nil];
    }
}

- (IBAction)securityCameraTapped:(UITapGestureRecognizer *)sender {
    UIImageView *securityCameraImageView = (UIImageView *)[sender view];
    if ([securityCameraImageView image] == nil) {
        self.securityCameraSelected = 1;
        [securityCameraImageView setImage:self.checkedImage];
    } else {
        self.securityCameraSelected = 0;
        [securityCameraImageView setImage:nil];
    }
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
