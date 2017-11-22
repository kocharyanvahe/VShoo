//
//  WalletViewController.h
//  VShoo
//
//  Created by Vahe Kocharyan on 1/21/16.
//  Copyright © 2016 ConnectTo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WalletViewController : UIViewController

@property (copy, nonatomic) NSString *urlStr;
@property (copy, nonatomic) NSString *deviceToken;
@property (copy, nonatomic) NSString *sessionId;

@end
