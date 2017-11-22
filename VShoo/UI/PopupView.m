//
//  PopupView.m
//  VShoo
//
//  Created by Vahe Kocharyan on 6/25/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import "PopupView.h"
#import "Utils.h"

@interface PopupView ()

@property (weak, nonatomic) IBOutlet UILabel *orderLabel;

@end

@implementation PopupView

- (void)drawRect:(CGRect)rect {
    [self.orderLabel setText:KKLocalizedString(@"Order")];
}

@end
