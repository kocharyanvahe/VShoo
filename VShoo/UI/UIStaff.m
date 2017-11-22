//
//  UIStaff.m
//  VShoo
//
//  Created by Vahe Kocharyan on 6/18/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import "UIStaff.h"
#import <QuartzCore/QuartzCore.h>
#import "Utils.h"

@implementation UIStaff

+ (void)setupVShooLogoInNavItem:(UINavigationItem *)navItem {
    UIImageView *vshooLogoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"VShooLogo"]];
    [navItem setTitleView:vshooLogoImageView];
}

+ (void)setupPickupLocationViewSettings:(UISearchBar *)searchBar onView:(UIView *)superView {
    [searchBar setSearchBarStyle:UISearchBarStyleMinimal];
    [searchBar setPlaceholder:KKLocalizedString(@"pickup location")];
    NSArray *subViews = [[[searchBar subviews] objectAtIndex:0] subviews];
    for (UITextField *textField in subViews) {
        if ([textField isKindOfClass:[UITextField class]]) {
            [textField setValue:[UIColor colorWithRed:12.0f/255.0f green:22.0f/255.0f blue:69.0f/255.0f alpha:1.0f] forKeyPath:@"_placeholderLabel.textColor"];
            [textField setLeftView:nil];
            UIImageView *pickupImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PickupIcon"]];
            [textField setLeftView:pickupImage];
            [textField setTextColor:[UIColor blackColor]];
        }
    }
    [superView addSubview:searchBar];
}

+ (void)setImage:(UIImage *)image onTextField:(UITextField *)textField {
    [textField setRightViewMode:UITextFieldViewModeAlways];
    UIImageView *rightView = [[UIImageView alloc] initWithImage:image];
    [textField setRightView:rightView];
}

+ (void)putCursorOnFrontIn:(UISearchBar *)searchBar {
    NSArray *subViews = [[[searchBar subviews] objectAtIndex:0] subviews];
    for (UITextField *textField in subViews) {
        if ([textField isKindOfClass:[UITextField class]]) {
            UITextPosition *startPosition = [textField beginningOfDocument];
            [textField setSelectedTextRange:[textField textRangeFromPosition:startPosition toPosition:startPosition]];
        }
    }
}

+ (void)putCursorToFrontIn:(UITextField *)textField {
    UITextPosition *startPosition = [textField beginningOfDocument];
    [textField setSelectedTextRange:[textField textRangeFromPosition:startPosition toPosition:startPosition]];
}

@end
