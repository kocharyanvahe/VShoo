//
//  HomeWorkMapViewController.h
//  VShoo
//
//  Created by Vahe Kocharyan on 7/24/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HomeWorkMapViewControllerDelegate <NSObject>

@optional

- (void)refreshTableView;

@end

@interface HomeWorkMapViewController : UIViewController

@property (copy, nonatomic) NSString *navigationTitle;
@property (weak, nonatomic) id<HomeWorkMapViewControllerDelegate> delegate;

@end
