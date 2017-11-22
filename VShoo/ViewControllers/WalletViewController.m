//
//  WalletViewController.m
//  VShoo
//
//  Created by Vahe Kocharyan on 1/21/16.
//  Copyright © 2016 ConnectTo. All rights reserved.
//

#import "WalletViewController.h"

@interface WalletViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation WalletViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSURL *url = [NSURL URLWithString:self.urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:self.deviceToken forHTTPHeaderField:@"imei"];
    [request addValue:self.sessionId forHTTPHeaderField:@"tsmSessionId"];
    NSLog(@"%@,   %@,   %@", self.deviceToken, self.sessionId, url);
    [self.webView loadRequest:request];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *absoluteUrl = [[request URL] absoluteString];
    NSLog(@"absolute :%@", absoluteUrl);
    if ([absoluteUrl rangeOfString:@"wallet_entry.htm"].location != NSNotFound) {
        NSRange range = [absoluteUrl rangeOfString:@"?"];
        NSString *newSession = [absoluteUrl substringFromIndex:range.location + 1];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:newSession forKey:@"tsmSessionId"];
        [defaults synchronize];
        NSLog(@"newSession :%@", newSession);
    }
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)backAction:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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
