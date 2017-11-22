//
//  DistanceDurationSuperView.m
//  VShoo
//
//  Created by Vahe Kocharyan on 9/2/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import "DistanceDurationSuperView.h"

@interface DistanceDurationSuperView ()

@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;

@end

@implementation DistanceDurationSuperView

- (void)drawRect:(CGRect)rect {
    if (self.distance && self.duration) {
        [self setHidden:NO];
        [self.distanceLabel setText:self.distance];
        [self.durationLabel setText:self.duration];
    }
}

@end
