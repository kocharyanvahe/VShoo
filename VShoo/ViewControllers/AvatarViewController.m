//
//  AvatarViewController.m
//  VShoo
//
//  Created by Vahe Kocharyan on 6/30/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import "AvatarViewController.h"
#import <Social/Social.h>
#import <MessageUI/MessageUI.h>
#import <GooglePlus/GooglePlus.h>
#import <GoogleOpenSource/GoogleOpenSource.h>
#import "AFNetworking.h"
#import "Utils.h"
#import "Requests.h"
#import "AppDelegate.h"
#import "InitialWebViewController.h"
#import "UIViewController+PopinView.h"
#import "WalletViewController.h"

@interface AvatarViewController () <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, UINavigationControllerDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, GPPSignInDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (strong, nonatomic) NSUserDefaults *defaults;
@property (copy, nonatomic) NSString *phoneNumber;
@property (copy, nonatomic) NSString *emailAddress;

@end

@implementation AvatarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!_defaults) {
        _defaults = [NSUserDefaults standardUserDefaults];
    }
    NSString *userAvatarImageUrl = [self.defaults objectForKey:@"userAvatarUrl"];
    NSString *username = [self.defaults objectForKey:@"user_name"];
    [self.usernameLabel setText:username];
    [self.usernameLabel sizeToFit];
    __weak typeof(self) weakSelf = self;
    [Requests downloadImage:userAvatarImageUrl andCallback:^(UIImage *image) {
        [weakSelf.avatarImageView setImage:image];
    } andFailCallBack:^(NSError *error) {
        NSLog(@"ERROR :%@", error);
    }];
}

#pragma mark -
#pragma mark UITableView delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 7;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    UIImage *myWalletImage = [UIImage imageNamed:@"MyWalletImage"];
    UIImage *tripHistoryImage = [UIImage imageNamed:@"TripHistoryImage"];
    UIImage *homeImage = [UIImage imageNamed:@"HomeImage"];
    UIImage *workImage = [UIImage imageNamed:@"WorkImage"];
    UIImage *socialNetworkImage = [UIImage imageNamed:@"SocialNetworkImage"];
    UIImage *referCustomerImage = [UIImage  imageNamed:@"ReferCustomerImage"];
    UIImage *changeRegionImage = [UIImage imageNamed:@"ChangeRegionImage"];
    [cell.textLabel setTextColor:[UIColor colorWithRed:127.0f/255.0f green:127.0f/255.0f blue:127.0f/255.0f alpha:1.0f]];
    switch ([indexPath row]) {
        case 0:
            [cell.imageView setImage:myWalletImage];
            [cell.textLabel setText:KKLocalizedString(@"My Wallet")];
            break;
        case 1:
            [cell.imageView setImage:tripHistoryImage];
            [cell.textLabel setText:KKLocalizedString(@"Trip History")];
            break;
        case 2:
        {
            [cell.imageView setImage:homeImage];
            NSString *homeAddress = [self.defaults objectForKey:@"home_address"];
            if (homeAddress) {
                [cell.textLabel setText:homeAddress];
            } else {
                [cell.textLabel setText:KKLocalizedString(@"Add Home Address")];
            }
        }
            break;
        case 3:
        {
            [cell.imageView setImage:workImage];
            NSString *workAddress = [self.defaults objectForKey:@"work_address"];
            if (workAddress) {
                [cell.textLabel setText:workAddress];
            } else {
                [cell.textLabel setText:KKLocalizedString(@"Add Work Address")];
            }
        }
            break;
        case 4:
            [cell.imageView setImage:socialNetworkImage];
            [cell.textLabel setText:KKLocalizedString(@"Social Network")];
        break;
        case 5:
            [cell.imageView setImage:referCustomerImage];
            [cell.textLabel setText:KKLocalizedString(@"Refer a customer")];
        break;
        case 6:
            [cell.imageView setImage:changeRegionImage];
            [cell.textLabel setText:KKLocalizedString(@"Change region")];
            break;
        default:
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *startWebUrl = [self.defaults objectForKey:@"startWebViewUrl"];
    NSString *tsmSessionId = [self.defaults objectForKey:@"tsmSessionId"];
    NSString *url = nil;
    switch ([indexPath row]) {
        case 0: {
            NSLog(@"Wallet");
            NSString *url = [self receiveWalletUrlWithStartURL:startWebUrl andTSMSessionId:tsmSessionId];
            NSString *deviceToken = [self.defaults objectForKey:@"device_token"];
            UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            WalletViewController *walletViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"WalletViewController"];
            [walletViewController setDeviceToken:deviceToken];
            [walletViewController setSessionId:tsmSessionId];
            [walletViewController setUrlStr:url];
            [self.view.window.rootViewController presentViewController:walletViewController animated:YES completion:nil];
        }
            break;
        case 1:
            NSLog(@"Trip History");
            url = [NSString stringWithFormat:@"%@/TSM/index.jsp?%@", startWebUrl, tsmSessionId];
            [self openSafariWithURL:url];
            break;
        case 2:
            NSLog(@"Add Home address");
            [self openMapViewWithTitle:KKLocalizedString(@"Add Home Address")];
            break;
        case 3:
            NSLog(@"Add Work address");
            [self openMapViewWithTitle:KKLocalizedString(@"Add Work Address")];
            break;
        case 4:
            [self showSocialActionSheet];
            break;
        case 5:
            [self showReferActionSheet];
            break;
        case 6:
            [self changeRegionAction];
            break;
        default:
            break;
    }
}

- (NSString *)receiveWalletUrlWithStartURL:(NSString *)startUrl andTSMSessionId:(NSString *)tsmSessionId {
    NSString *url = [NSString stringWithFormat:@"%@/wallet_entry_custom.htm", startUrl];
    return url;
}

#pragma mark -
#pragma mark - Open Safari with url

- (void)openSafariWithURL:(NSString *)urlStr {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr]];
}

#pragma mark -
#pragma mark Open Map View

- (void)openMapViewWithTitle:(NSString *)title {
    HomeWorkMapViewController *homeWorkMapViewPopin = [[HomeWorkMapViewController alloc] init];
    [homeWorkMapViewPopin setDelegate:self];
    NSString *currentiOSPlatform = [Utils platformString];
    [homeWorkMapViewPopin setPopinTransitionStyle:BKTPopinTransitionStyleSnap];
    [homeWorkMapViewPopin setPopinOptions:BKTPopinDefault];
    [homeWorkMapViewPopin setPopinAlignment:BKTPopinAlignementOptionLeft];
    [homeWorkMapViewPopin setNavigationTitle:title];
    BKTBlurParameters *blurParameters = [[BKTBlurParameters alloc] init];
    [blurParameters setAlpha:1.0f];
    [blurParameters setRadius:8.0f];
    [blurParameters setSaturationDeltaFactor:1.8f];
    [blurParameters setTintColor:[UIColor colorWithRed:215.0f/255.0f green:215.0f/255.0f blue:215.0f/255.0f alpha:0.3f]];
    [homeWorkMapViewPopin setBlurParameters:blurParameters];
    [homeWorkMapViewPopin setPopinOptions:[homeWorkMapViewPopin popinOptions] | BKTPopinIgnoreKeyboardNotification];
    [homeWorkMapViewPopin setPopinTransitionDirection:BKTPopinTransitionDirectionTop];
    CGFloat width = 0.0f;
    if ([currentiOSPlatform isEqualToString:@"iPhone 6+"]) {
        width = self.view.bounds.size.width - ((self.view.bounds.size.width * 16.0f) / 100.0f);
    } else if ([currentiOSPlatform isEqualToString:@"iPhone 6"]) {
        width = self.view.bounds.size.width - ((self.view.bounds.size.width * 16.0f) / 100.0f);
    } else if ([currentiOSPlatform isEqualToString:@"iPhone 5/5S/5C"]) {
        width = self.view.bounds.size.width - ((self.view.bounds.size.width * 19.0f) / 100.0f);
    } else if ([currentiOSPlatform isEqualToString:@"iPhone 4/4S"]) {
        width = self.view.bounds.size.width - ((self.view.bounds.size.width * 18.0f) / 100.0f);
    } else if ([currentiOSPlatform isEqualToString:@"iPad"] || [currentiOSPlatform isEqualToString:@"iPad 2"] || [currentiOSPlatform isEqualToString:@"iPad Mini"] || [currentiOSPlatform isEqualToString:@"iPad 3"] ||
               [currentiOSPlatform isEqualToString:@"iPad 4"] || [currentiOSPlatform isEqualToString:@"iPad Air"] || [currentiOSPlatform isEqualToString:@"iPad Mini Retina"] || [currentiOSPlatform isEqualToString:@"iPad Air 2"]) {
        width = self.view.bounds.size.width - ((self.view.bounds.size.width * 16.0f) / 100.0f);
    }
    CGFloat height = self.view.bounds.size.height - ((self.view.bounds.size.height * 10.0f) / 100.0f);
    CGSize contentSize = CGSizeMake(width, height);
    [homeWorkMapViewPopin setPreferedPopinContentSize:contentSize];
    [homeWorkMapViewPopin.view setBackgroundColor:[UIColor clearColor]];
    [self presentPopinController:homeWorkMapViewPopin animated:YES completion:nil];
}

#pragma mark -
#pragma mark Show Social sheet

- (void)showSocialActionSheet {
    UIActionSheet *socialActionSheet = [[UIActionSheet alloc] initWithTitle:KKLocalizedString(@"Select sharing option:") delegate:self cancelButtonTitle:KKLocalizedString(@"Cancel") destructiveButtonTitle:nil otherButtonTitles:KKLocalizedString(@"Share on Facebook"), KKLocalizedString(@"Share on Twitter"), KKLocalizedString(@"Share on Google+"), nil];
    [socialActionSheet setTag:1];
    [socialActionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([popup tag] == 1) {
        switch (buttonIndex) {
            case 0:
                [self postToFacebook];
                break;
            case 1:
                [self postToTwitter];
                break;
            case 2:
                [self postToGooglePlus];
                break;
            default:
                break;
        }
    } else if ([popup tag] == 2) {
        switch (buttonIndex) {
            case 0:
                NSLog(@"Email");
                [self showEmailController];
                break;
            case 1:
                NSLog(@"SMS");
                [self showSMSController];
                break;
            default:
                break;
        }
    }
}

#pragma mark -
#pragma mark Post To Facebook

- (void)postToFacebook {
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        SLComposeViewController *facebookSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [facebookSheet setInitialText:@"Cool app"];
        [facebookSheet addURL:[NSURL URLWithString:@"http://apple.co/1QTYHzc"]];
        [self.view.window.rootViewController presentViewController:facebookSheet animated:YES completion:nil];
    }
}

#pragma mark -
#pragma mark Post To Twitter

- (void)postToTwitter {
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [tweetSheet setInitialText:@"Cool app"];
        [tweetSheet addURL:[NSURL URLWithString:@"http://apple.co/1QTYHzc"]];
        [self.view.window.rootViewController presentViewController:tweetSheet animated:YES completion:nil];
    }
}

#pragma mark -
#pragma mark Post To Google +

- (void)postToGooglePlus {
    NSString *googlePlusClientId = [Utils getFromPlistWithKey:@"GooglePlusClientID"];
    GPPSignIn *signIn = [GPPSignIn sharedInstance];
    [signIn setDelegate:self];
    [signIn setClientID:googlePlusClientId];
    [signIn setShouldFetchGooglePlusUser:YES];
    [signIn setScopes:@[kGTLAuthScopePlusLogin]];
    [signIn authenticate];
}

- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error {
    if (!error) {
        id<GPPNativeShareBuilder> shareBuilder = [[GPPShare sharedInstance] nativeShareDialog];
        [shareBuilder setPrefillText:@"Prefill Text"];
        [shareBuilder setURLToShare:[NSURL URLWithString:@"http://apple.co/1QTYHzc"]];
        [shareBuilder open];
    } else {
        [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self];
    }
}

#pragma mark -
#pragma mark Show Refer Action Sheet

- (void)showReferActionSheet {
    UIActionSheet *socialActionSheet = [[UIActionSheet alloc] initWithTitle:KKLocalizedString(@"Select refer option:") delegate:self cancelButtonTitle:KKLocalizedString(@"Cancel") destructiveButtonTitle:nil otherButtonTitles:KKLocalizedString(@"Send an email"), KKLocalizedString(@"Send SMS"), nil];
    [socialActionSheet setTag:2];
    [socialActionSheet showInView:self.view];
}

- (void)showSMSController {
    __block UITextField *txtField = nil;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"Please type the number" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        txtField = textField;
        [txtField setPlaceholder:@"Phone Number"];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *nextAction = [UIAlertAction actionWithTitle:@"Next" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        MFMessageComposeViewController *messageVC = [[MFMessageComposeViewController alloc] init];
        [messageVC setDelegate:self];
        if ([MFMessageComposeViewController canSendText]) {
            messageVC.messageComposeDelegate = self;
            messageVC.body = @"Text which needs to be editing";
            _phoneNumber = [txtField text];
            [messageVC setRecipients:@[self.phoneNumber]];
            [self.view.window.rootViewController presentViewController:messageVC animated:YES completion:nil];
        };
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:nextAction];
    [self.view.window.rootViewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark -
#pragma mark MFMessageComposeViewController delegate methods

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    switch (result) {
        case MessageComposeResultFailed:
            [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"Failed") andMessage:KKLocalizedString(@"Please, try again.") onFollowingViewController:self];
            break;
        case MessageComposeResultSent: {
            [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"Sent") andMessage:KKLocalizedString(@"Your message has been sent.") onFollowingViewController:self];
            NSString *url = [Utils getFromPlistWithKey:@"ReferralURL"];
            NSString *tsmSessionId = [self.defaults objectForKey:@"tsmSessionId"];
            NSLog(@"fff :%@", tsmSessionId);
            [Requests sendPostRequest:url withParameters:@{ @"sessionId": tsmSessionId, @"referralPhone": self.phoneNumber } andCallback:^(NSDictionary *response) {
                NSString *result = [response valueForKey:@"result"];
                if ([result isEqualToString:@"OK"]) {
                    NSLog(@"OK");
                }
            } andFailCallBack:^(NSError *error) {
                NSLog(@"ERROR :%@", error);
            }];
        }
            break;
        default:
            break;
    }
    [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Show Email Controller

- (void)showEmailController {
    __block UITextField *txtField = nil;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:KKLocalizedString(@"Please type the number") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        txtField = textField;
        [txtField setPlaceholder:@"Email"];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:KKLocalizedString(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *nextAction = [UIAlertAction actionWithTitle:KKLocalizedString(@"Next") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        _emailAddress = [txtField text];
        NSString *messageBody = @"Sent from VShoo app http://apple.co/1QTYHzc";
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
            mc.mailComposeDelegate = self;
            [mc setMessageBody:messageBody isHTML:NO];
            [mc setToRecipients:@[self.emailAddress]];
            [self.view.window.rootViewController presentViewController:mc animated:YES completion:nil];
        } else {
            [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:KKLocalizedString(@"Please, make a setup of your email in your phone.") onFollowingViewController:self.view.window.rootViewController];
        }
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:nextAction];
    [self.view.window.rootViewController presentViewController:alertController animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    switch (result) {
        case MFMailComposeResultSaved:
            [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"Saved") andMessage:@"Your message was saved." onFollowingViewController:self];
            break;
        case MFMailComposeResultSent: {
            NSString *url = [Utils getFromPlistWithKey:@"ReferralURL"];
            NSString *tsmSessionId = [self.defaults objectForKey:@"tsmSessionId"];
            [Requests sendPostRequest:url withParameters:@{ @"sessionId": tsmSessionId, @"referralEmail": self.emailAddress } andCallback:^(NSDictionary *response) {
                NSString *result = [response valueForKey:@"result"];
                if ([result isEqualToString:@"OK"]) {
                    NSLog(@"OK");
                }
            } andFailCallBack:^(NSError *error) {
                NSLog(@"ERROR :%@", error);
            }];
            [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"Sent") andMessage:KKLocalizedString(@"Your message has been sent.") onFollowingViewController:self];
        }
            break;
        case MFMailComposeResultFailed:
            [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"Failed") andMessage:[error localizedDescription] onFollowingViewController:self];
            break;
        default:
            break;
    }
    [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Logout Action

- (IBAction)logoutAction {
    NSLog(@"Log out");
    [self logout];
}

- (void)logout {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TerminateTimerNotification" object:nil];
    NSString *tsmSessionId = [self.defaults objectForKey:@"tsmSessionId"];
    NSString *url = [Utils getFromPlistWithKey:@"LogoutURL"];
    AFHTTPRequestOperationManager *operationManager = [AFHTTPRequestOperationManager manager];
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    [requestSerializer setValue:tsmSessionId forHTTPHeaderField:@"tsmSessionId"];
    [operationManager setRequestSerializer:requestSerializer];
    [operationManager POST:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *json = (NSDictionary *)responseObject;
        NSString *status = [json valueForKeyPath:@"responseDto.status"];
        if ([status isEqualToString:@"SUCCESS"]) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            InitialWebViewController *initialWebViewController = [storyboard instantiateViewControllerWithIdentifier:@"InitialWebViewController"];
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
                [self.defaults removeObjectForKey:@"tsmSessionId"];
                [self.defaults removeObjectForKey:@"language"];
                [self.defaults removeObjectForKey:@"userAvatarUrl"];
                [self.defaults removeObjectForKey:@"user_name"];
                [self.defaults synchronize];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [appDelegate.window setRootViewController:initialWebViewController];
                });
            });
        } else if ([status isEqualToString:@"INTERNAL_ERROR"]) {
            NSString *errorMessage = [[json valueForKeyPath:@"responseDto.messages"] objectAtIndex:0];
            [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:errorMessage onFollowingViewController:self.view.window.rootViewController];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"ERROR :%@", error);
        [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self.view.window.rootViewController];
    }];
}

- (void)changeRegionAction {
    [self.defaults removeObjectForKey:@"startWebViewUrl"];
    [self.defaults synchronize];
    [self logout];
}

#pragma mark -
#pragma mark Refreshing Table View

- (void)refreshTableView {
    [self.tableView reloadData];
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
