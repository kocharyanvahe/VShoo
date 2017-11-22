//
//  EstimatedCostView.m
//  VShoo
//
//  Created by Vahe Kocharyan on 9/2/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import "EstimatedCostView.h"
#import "Utils.h"

@interface EstimatedCostView ()

@property (weak, nonatomic) IBOutlet UILabel *costLabel;
@property (weak, nonatomic) IBOutlet UILabel *estimatedCostLabel;
@property (weak, nonatomic) IBOutlet UILabel *smallTextLabel;

@end

@implementation EstimatedCostView

- (void)drawRect:(CGRect)rect {
    if (self.cost) {
        [self setHidden:NO];
        [self.costLabel setText:self.cost];
        [self.estimatedCostLabel setText:KKLocalizedString(@"Estimated Cost:")];
        [self.smallTextLabel setText:KKLocalizedString(@"Actual cost can be more, due to unforeseen circumstances.")];
    }
}

@end
