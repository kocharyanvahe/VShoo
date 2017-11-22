//
//  EstimationViewController.m
//  VShoo
//
//  Created by Vahe Kocharyan on 7/31/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import "EstimationViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <QuartzCore/QuartzCore.h>
#import <GoogleMaps/GoogleMaps.h>
#import "Utils.h"
#import "Requests.h"
#import "UIStaff.h"
#import "DistanceDurationSuperView.h"
#import "EstimatedCostView.h"
#import "ViewController.h"
#import "SCLAlertView.h"
#import "SpecialRequestViewController.h"
#import "UIViewController+PopinView.h"

@interface EstimationViewController () <UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UINavigationControllerDelegate, UISearchControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *selectCarTextField;
@property (weak, nonatomic) IBOutlet UITextField *specialRequestTextField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (copy, nonatomic) NSArray *carTypes;
@property (copy, nonatomic) NSArray *classId;
@property (copy, nonatomic) NSString *homeAddress;
@property (copy, nonatomic) NSString *workAddress;
@property (copy, nonatomic) NSMutableArray *additionalScopes;
@property (assign, nonatomic) BOOL isAddedNewAddress;
@property (copy, nonatomic) NSString *aNewFromAddress;
@property (copy, nonatomic) NSString *aNewToAddress;
@property (assign, nonatomic) NSInteger selectedScope;
@property (copy, nonatomic) NSArray *searchItems;
@property (copy, nonatomic) NSString *fromPlaceId;
@property (copy, nonatomic) NSString *toPlaceId;
@property (assign, nonatomic) CLLocationCoordinate2D fromLocation;
@property (assign, nonatomic) CLLocationCoordinate2D toLocation;
@property (assign, nonatomic) NSUInteger carTypeInt;
@property (strong, nonatomic) DistanceDurationSuperView *distanceDurationSuperView;
@property (strong, nonatomic) EstimatedCostView *estimatedCostView;
@property (strong, nonatomic) GMSPolyline *polyline;
@property (copy, nonatomic) NSString *fromAddress;
@property (copy, nonatomic) NSString *toAddress;
@property (assign, nonatomic) BOOL isOrdered;
@property (assign, nonatomic) BOOL isCalculationCalled;
@property (copy, nonatomic) NSArray *specialRequests;

@end

@implementation EstimationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _carTypeInt = 0;
    [self.searchDisplayController.searchBar setScopeButtonTitles:@[KKLocalizedString(@"From"), KKLocalizedString(@"To")]];
    [self.searchDisplayController.searchBar setPlaceholder:KKLocalizedString(@"Search")];
    [self.specialRequestTextField setPlaceholder:KKLocalizedString(@"Special Request")];
    _isAddedNewAddress = NO;
    _isCalculationCalled = NO;
    _selectedScope = 0;
    if (!_searchItems) {
        _searchItems = [NSArray array];
    }
    [self.selectCarTextField setPlaceholder:KKLocalizedString(@"Select a car")];
    UIImage *estimateTitleImage = [UIImage imageNamed:@"EstimateTitleImage"];
    UIImageView *titleImageView = [[UIImageView alloc] initWithImage:estimateTitleImage];
    [self.navigationItem setTitleView:titleImageView];
    [[self.selectCarTextField valueForKey:@"textInputTraits"] setValue:[UIColor clearColor] forKey:@"insertionPointColor"];
    [[self.specialRequestTextField valueForKey:@"textInputTraits"] setValue:[UIColor blackColor] forKey:@"insertionPointColor"];
    UIImage *selectCarImage = [UIImage imageNamed:@"SelectCarIcon"];
    UIImage *specialRequestImage = [UIImage imageNamed:@"SpecialRequestIcon"];
    UIImageView *selectCarImageView = [[UIImageView alloc] initWithImage:selectCarImage];
    UIImageView *specialRequestImageView = [[UIImageView alloc] initWithImage:specialRequestImage];
    [self.selectCarTextField setRightViewMode:UITextFieldViewModeAlways];
    [self.selectCarTextField setRightView:selectCarImageView];
    [self.specialRequestTextField setRightViewMode:UITextFieldViewModeAlways];
    [self.specialRequestTextField setRightView:specialRequestImageView];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _homeAddress = [defaults objectForKey:@"home_address"];
    _workAddress = [defaults objectForKey:@"work_address"];
    NSLog(@"ffff :%@   fff :%@", self.homeAddress, self.workAddress);
    [self initDistanceEstimatedCostViews];
    [self initOrderButton];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getSpecialRequestArguments:) name:@"GetSpecialRequestArguments" object:nil];
}

#pragma mark -
#pragma mark Initialize Distance/Estimated Cost Views

- (void)initDistanceEstimatedCostViews {
    _distanceDurationSuperView = [[[NSBundle mainBundle] loadNibNamed:@"DistanceDurationSuperView" owner:self options:nil] objectAtIndex:0];
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    CGFloat genericSuperViewWidth = screenWidth - (screenWidth * 10.0f)/100.0f;
    CGRect updatedDistanceDurationFrame = [self.distanceDurationSuperView frame];
    updatedDistanceDurationFrame.size.width = genericSuperViewWidth;
    CGFloat genericSuperViewX = updatedDistanceDurationFrame.origin.x + genericSuperViewWidth;
    [_distanceDurationSuperView setFrame:updatedDistanceDurationFrame];
    [_distanceDurationSuperView setFrame:CGRectSetPos([self.distanceDurationSuperView frame], -genericSuperViewX, 242.0f)];
    [_distanceDurationSuperView.layer setBorderWidth:1.0f];
    [_distanceDurationSuperView.layer setBorderColor:[[UIColor colorWithRed:200.0f/255.0f green:201.0f/255.0f blue:200.0f/255.0f alpha:1.0f] CGColor]];
    [self.view addSubview:_distanceDurationSuperView];
    _estimatedCostView = [[[NSBundle mainBundle] loadNibNamed:@"EstimatedCostView" owner:self options:nil] objectAtIndex:0];
    CGRect updatedEstimatedCostFrame = [self.estimatedCostView frame];
    updatedEstimatedCostFrame.size.width = genericSuperViewWidth;
    [_estimatedCostView setFrame:updatedEstimatedCostFrame];
    [_estimatedCostView setFrame:CGRectSetPos([self.estimatedCostView frame], -genericSuperViewX, 290.0f)];
    [_estimatedCostView.layer setBorderWidth:1.0f];
    [_estimatedCostView.layer setBorderColor:[[UIColor colorWithRed:200.0f/255.0f green:201.0f/255.0f blue:200.0f/255.0f alpha:1.0f] CGColor]];
    [self.view addSubview:_estimatedCostView];
}

#pragma mark -
#pragma mark Initialize Order Button

- (void)initOrderButton {
    UIImage *orderButtonImage = [UIImage imageNamed:@"OrderButtonImage"];
    UIButton *orderButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [orderButton setImage:orderButtonImage forState:UIControlStateNormal];
    [orderButton setFrame:CGRectMake(0.0f, 0.0f, orderButtonImage.size.width, orderButtonImage.size.height)];
    [orderButton addTarget:self action:@selector(ordering:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *orderButtonItem = [[UIBarButtonItem alloc] initWithCustomView:orderButton];
    [self.navigationItem setRightBarButtonItem:orderButtonItem];
    [self.navigationItem.rightBarButtonItem.customView setHidden:YES];
}

CG_INLINE CGRect CGRectSetPos(CGRect frame, CGFloat x, CGFloat y) {
    CGRect rect;
    rect.origin.x = x;
    rect.origin.y = y;
    rect.size.width = frame.size.width;
    rect.size.height = frame.size.height;
    return rect;
}

#pragma mark -
#pragma mark UITableView Delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (![self.searchDisplayController isActive]) {
        return 2;
    }
    return [self.searchItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    static NSString *cellIdentifierSearchTableView = @"SearchCell";
    UITableViewCell *cell = nil;
    UIImage *startLocationImage = [UIImage imageNamed:@"StartLocationIcon"];
    UIImage *endLocationImage = [UIImage imageNamed:@"EndLocationIcon"];
    if ([self.searchDisplayController isActive]) {
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierSearchTableView];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierSearchTableView];
        }
        NSUInteger selectedScopeIndex = self.searchDisplayController.searchBar.selectedScopeButtonIndex;
        if (selectedScopeIndex == 2 || selectedScopeIndex == 3) {
            NSUInteger scopeCount = [self.searchDisplayController.searchBar.scopeButtonTitles count];
            if (scopeCount > 2) {
                NSString *scopeTitle = [self.searchDisplayController.searchBar.scopeButtonTitles objectAtIndex:selectedScopeIndex];
                if ([scopeTitle isEqualToString:KKLocalizedString(@"From Home")] || [scopeTitle isEqualToString:KKLocalizedString(@"From Work")]) {
                    switch ([indexPath row]) {
                        case 0: {
                            if ([cell.imageView image] == nil) {
                                [cell.imageView setImage:startLocationImage];
                            }
                            [cell.textLabel setText:nil];
                            [cell.textLabel setText:[self.searchDisplayController.searchBar text]];
                        }
                            break;
                        default:
                            [cell.textLabel setText:nil];
                            break;
                    }
                } else if ([scopeTitle isEqualToString:KKLocalizedString(@"To Home")] || [scopeTitle isEqualToString:KKLocalizedString(@"To Work")]) {
                    switch ([indexPath row]) {
                        case 0: {
                            if ([cell.imageView image] == nil) {
                                [cell.imageView setImage:endLocationImage];
                            }
                            [cell.textLabel setText:[self.searchDisplayController.searchBar text]];
                        }
                            break;
                        default:
                            [cell.textLabel setText:nil];
                            break;
                    }
                }
            }
        } else if (selectedScopeIndex == 0 || selectedScopeIndex == 1) {
            NSString *typedText = [self.searchDisplayController.searchBar text];
            if ([typedText length] > 0) {
                switch ([indexPath row]) {
                    case 0:
                    case 1:
                        [cell.textLabel setText:nil];
                        [cell.imageView setImage:nil];
                        break;
                    default:
                        break;
                }
            } else {
                NSString *cellText = [cell.textLabel text];
                if (![cellText isEqualToString:@""]) {
                    [cell.textLabel setText:nil];
                }
            }
            [cell.textLabel setText:[self.searchItems objectAtIndex:[indexPath row]]];
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        switch ([indexPath row]) {
            case 0: {
                if (!self.isAddedNewAddress) {
                    [cell.textLabel setText:KKLocalizedString(@"From")];
                } else {
                    [cell.textLabel setText:self.aNewFromAddress];
                }
            }
                break;
            case 1: {
                if (!self.isAddedNewAddress) {
                    [cell.textLabel setText:KKLocalizedString(@"To")];
                } else {
                    [cell.textLabel setText:self.aNewToAddress];
                }
            }
                break;
            default:
                break;
        }
    }
    [cell.textLabel setFont:[UIFont italicSystemFontOfSize:17.0f]];
    [cell.textLabel setTextColor:[UIColor colorWithRed:127.0f/255.0f green:127.0f/255.0f blue:127.0f/255.0f alpha:1.0f]];
    if (![self.searchDisplayController isActive]) {
        switch ([indexPath row]) {
            case 0:
                [cell.imageView setImage:startLocationImage];
                break;
            case 1:
                [cell.imageView setImage:endLocationImage];
                break;
            default:
                break;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = [indexPath row];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if ([self.searchDisplayController isActive]) {
            NSUInteger selectedScopeIndex = [self.searchDisplayController.searchBar selectedScopeButtonIndex];
            NSString *scopeTitle = [self.searchDisplayController.searchBar.scopeButtonTitles objectAtIndex:selectedScopeIndex];
            if ([scopeTitle isEqualToString:KKLocalizedString(@"From Home")] || [scopeTitle isEqualToString:KKLocalizedString(@"From Work")]) {
                _aNewFromAddress = [self.searchDisplayController.searchBar text];
                _isAddedNewAddress = YES;
            } else if ([scopeTitle isEqualToString:KKLocalizedString(@"To Home")] || [scopeTitle isEqualToString:KKLocalizedString(@"To Work")]) {
                _aNewToAddress = [self.searchDisplayController.searchBar text];
                _isAddedNewAddress = YES;
            }
            if ([self.searchItems count] > 0) {
                self.isAddedNewAddress = YES;
                switch (selectedScopeIndex) {
                    case 0:
                        self.aNewFromAddress = [self.searchItems objectAtIndex:[indexPath row]];
                        break;
                    case 1:
                        self.aNewToAddress = [self.searchItems objectAtIndex:[indexPath row]];
                        break;
                    default:
                        break;
                }
                [self.tableView reloadData];
            }
            [self.searchDisplayController.searchBar resignFirstResponder];
            [self.searchDisplayController setActive:NO animated:YES];
        } else {
            [self.searchDisplayController.searchBar becomeFirstResponder];
            [self.searchDisplayController.searchBar setSelectedScopeButtonIndex:row];
            NSMutableArray *scopes = [NSMutableArray arrayWithObject:[self.searchDisplayController.searchBar scopeButtonTitles]];
            scopes = [scopes objectAtIndex:0];
            NSString *fromHome = KKLocalizedString(@"From Home");
            NSString *fromWork = KKLocalizedString(@"From Work");
            NSString *toHome = KKLocalizedString(@"To Home");
            NSString *toWork = KKLocalizedString(@"To Work");
            NSUInteger idx = 0;
            if (!_additionalScopes) {
                _additionalScopes = [NSMutableArray array];
            }
            for (NSUInteger i = 0; i < [scopes count]; i++) {
                if (![self.additionalScopes containsObject:[scopes objectAtIndex:i]]) {
                    [_additionalScopes addObject:[scopes objectAtIndex:i]];
                }
            }
            if (row == 0) {
                if ([self.additionalScopes count] == 2) {
                    if (self.homeAddress) {
                        if (![self.additionalScopes containsObject:KKLocalizedString(@"From Home")]) {
                            [_additionalScopes addObject:KKLocalizedString(@"From Home")];
                        }
                    }
                    if (self.workAddress) {
                        if (![self.additionalScopes containsObject:KKLocalizedString(@"From Work")]) {
                            [_additionalScopes addObject:KKLocalizedString(@"From Work")];
                        }
                    }
                } else if ([self.additionalScopes count] > 2) {
                    if (self.homeAddress) {
                        idx = [self.additionalScopes indexOfObject:toHome];
                        if (idx != NSNotFound) {
                            if ([[self.additionalScopes objectAtIndex:idx] isEqualToString:toHome]) {
                                [_additionalScopes replaceObjectAtIndex:idx withObject:fromHome];
                            }
                        }
                    }
                    if (self.workAddress) {
                        idx = [self.additionalScopes indexOfObject:toWork];
                        if (idx != NSNotFound) {
                            if ([[self.additionalScopes objectAtIndex:idx] isEqualToString:toWork]) {
                                [_additionalScopes replaceObjectAtIndex:idx withObject:fromWork];
                            }
                        }
                    }
                }
            } else if (row == 1) {
                if ([self.additionalScopes count] == 2) {
                    if (self.homeAddress) {
                        if (![self.additionalScopes containsObject:KKLocalizedString(@"To Home")]) {
                            [_additionalScopes addObject:KKLocalizedString(@"To Home")];
                        }
                    }
                    if (self.workAddress) {
                        if (![self.additionalScopes containsObject:KKLocalizedString(@"To Work")]) {
                            [_additionalScopes addObject:KKLocalizedString(@"To Work")];
                        }
                    }
                } else if ([self.additionalScopes count] > 2) {
                    if (self.homeAddress) {
                        idx = [self.additionalScopes indexOfObject:fromHome];
                        if (idx != NSNotFound) {
                            if ([[self.additionalScopes objectAtIndex:idx] isEqualToString:fromHome]) {
                                [_additionalScopes replaceObjectAtIndex:idx withObject:toHome];
                            }
                        }
                    }
                    if (self.workAddress) {
                        idx = [self.additionalScopes indexOfObject:fromWork];
                        if (idx != NSNotFound) {
                            if ([[self.additionalScopes objectAtIndex:idx] isEqualToString:fromWork]) {
                                [_additionalScopes replaceObjectAtIndex:idx withObject:toWork];
                            }
                        }
                    }
                }
            }
            [self.searchDisplayController.searchBar setScopeButtonTitles:self.additionalScopes];
        }
        if (self.isAddedNewAddress) {
            [self.tableView reloadData];
        }
    }];
    self.selectedScope = row;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)getSpecialRequestArguments:(NSNotification *)notification {
    _specialRequests = [notification object];
    [self retrieveAvailableCars];
}

#pragma mark -
#pragma mark Retrieve available cars

- (void)retrieveAvailableCars {
    NSUInteger wheelchairAccess = 0;
    NSUInteger carSeatAccess = 0;
    NSUInteger cameraAccess = 0;
    if ([self.specialRequests count] > 0) {
        wheelchairAccess = [[self.specialRequests objectAtIndex:0] unsignedIntegerValue];
        carSeatAccess = [[self.specialRequests objectAtIndex:1] unsignedIntegerValue];
        cameraAccess = [[self.specialRequests objectAtIndex:2] unsignedIntegerValue];
    }
    NSString *sessionId = [[NSUserDefaults standardUserDefaults] objectForKey:@"tsmSessionId"];
    NSString *url = [Utils getFromPlistWithKey:@"GetCarTypes"];
    NSDictionary *params = @{ @"sessionId": sessionId, @"latitude": [NSNumber numberWithDouble:self.fromLocation.latitude], @"longitude": [NSNumber numberWithDouble:self.fromLocation.longitude], @"wheelchairAccess": [NSNumber numberWithUnsignedInteger:wheelchairAccess], @"carSeatAccess": [NSNumber numberWithUnsignedInteger:carSeatAccess], @"cameraAccess": [NSNumber numberWithUnsignedInteger:cameraAccess] };
    [Requests sendPostRequest:url withParameters:params andCallback:^(NSDictionary *response) {
        NSString *result = [response valueForKey:@"result"];
        if ([result isEqualToString:@"OK"]) {
            if (!_carTypes) {
                _carTypes = [NSArray array];
            }
            if (!_classId) {
                _classId = [NSArray array];
            }
            if ([response valueForKey:@"carClasses"]) {
                BOOL isExistenceAvailableVehicle = [[response valueForKey:@"isExistAvailableVehicle"] boolValue];
                if (isExistenceAvailableVehicle) {
                    NSString *className = [response valueForKeyPath:@"carClasses.className"];
                    _carTypes = @[className];
                    _carTypes = [self.carTypes objectAtIndex:0];
                    _classId = @[[response valueForKeyPath:@"carClasses.classId"]];
                    _classId = [self.classId objectAtIndex:0];
                    [self.selectCarTextField setText:[self.carTypes objectAtIndex:0]];
                    self.carTypeInt = [[self.classId objectAtIndex:0] unsignedIntegerValue];
                } else {
                    NSString *message = [response valueForKey:@"message"];
                    [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:message onFollowingViewController:self];
                }
            } else {
                NSLog(@"fff :%@", response);
                NSString *message = [response valueForKey:@"message"];
                [Utils showSimpleAlertsWithTitle:@"Message" andMessage:message onFollowingViewController:self];
            }
        }
    } andFailCallBack:^(NSError *error) {
        [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self];
    }];
}

#pragma mark -
#pragma mark UITextField delegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if ([textField isEqual:self.selectCarTextField]) {
        if ([self.carTypes count] > 0) {
            UIPickerView *selectCarPickerView = [[UIPickerView alloc] init];
            [selectCarPickerView setDataSource:self];
            [selectCarPickerView setDelegate:self];
            [selectCarPickerView setShowsSelectionIndicator:YES];
            [textField setInputView:selectCarPickerView];
            UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 44.0f)];
            UIBarButtonItem *flexiableItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
            UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
            [toolbar setItems:@[flexiableItem, doneButton] animated:YES];
            [textField setInputAccessoryView:toolbar];
            [textField setText:[self.carTypes objectAtIndex:0]];
        } else {
            [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:KKLocalizedString(@"There is no any available cars at this moment. Please, add starting/final destinations.") onFollowingViewController:self];
            return NO;
        }
    } else if ([textField isEqual:self.specialRequestTextField]) {
        if (self.carTypes) {
            SpecialRequestViewController *specialRequestViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SpecialRequestViewController"];
            [specialRequestViewController setPopinTransitionStyle:BKTPopinTransitionStyleSnap];
            [specialRequestViewController setPopinOptions:BKTPopinDefault];
            [specialRequestViewController setPopinAlignment:BKTPopinAlignementOptionRight];
            BKTBlurParameters *blurParameters = [[BKTBlurParameters alloc] init];
            [blurParameters setAlpha:1.0f];
            [blurParameters setRadius:8.0f];
            [blurParameters setSaturationDeltaFactor:1.8f];
            [blurParameters setTintColor:[UIColor colorWithRed:215.0f/255.0f green:215.0f/255.0f blue:215.0f/255.0f alpha:0.3f]];
            [specialRequestViewController setBlurParameters:blurParameters];
            [specialRequestViewController setPopinOptions:[specialRequestViewController popinOptions] | BKTPopinIgnoreKeyboardNotification];
            [specialRequestViewController setPopinTransitionDirection:BKTPopinTransitionDirectionTop];
            [specialRequestViewController setPreferedPopinContentSize:CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height)];
            [self.navigationController presentPopinController:specialRequestViewController animated:YES completion:nil];
        } else {
            [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:KKLocalizedString(@"There is no any available cars at this moment. Please, add starting/final destinations.") onFollowingViewController:self];
        }
        return NO;
    }
    return YES;
}

#pragma mark -
#pragma mark UIToolbar Done button action

- (void)doneAction:(id)sender {
    [self.selectCarTextField resignFirstResponder];
}

#pragma mark -
#pragma mark UIPickerView delegate methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.carTypes count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self.carTypes objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    [self.selectCarTextField setText:[self.carTypes objectAtIndex:row]];
    self.carTypeInt = [[self.classId objectAtIndex:row] unsignedIntegerValue];
}

#pragma mark -
#pragma mark UISearchDisplayController Delegate methods

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    NSUInteger scopeCount = [[self.searchDisplayController.searchBar scopeButtonTitles] count];
    if (scopeCount > 2) {
        [self.searchDisplayController.searchBar setScopeButtonTitles:@[KKLocalizedString(@"From"), KKLocalizedString(@"To")]];
        [self.searchDisplayController.searchBar setSelectedScopeButtonIndex:0];
    }
    if ([self.searchItems count] > 0) {
        _searchItems = nil;
    }
    [controller.searchBar setSelectedScopeButtonIndex:0];
    [controller.searchResultsTableView reloadData];
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    self.selectedScope = 0;
    if (![self.fromPlaceId isEqualToString:self.toPlaceId]) {
        if (self.fromPlaceId) {
            [self getFromLocationByPlaceId:self.fromPlaceId];
        }
        if (self.toPlaceId) {
            [self getToLocationByPlaceId:self.toPlaceId];
        }
    }
    if (self.fromLocation.latitude != 0 && self.fromLocation.longitude != 0) {
        if (self.toLocation.latitude != 0 && self.toLocation.longitude != 0) {
            if (!self.isCalculationCalled) {
                [self calculateDistanceFromLocation:self.fromLocation toLocation:self.toLocation];
            }
        }
    }
    [self.tableView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    if ([self.searchItems count] > 0) {
        _searchItems = nil;
    }
    switch (selectedScope) {
        case 0:
        case 1: {
            if (![searchBar.text isEqualToString:@""]) {
                [searchBar setText:nil];
            }
        }
        break;
        case 2:
            [self.searchDisplayController.searchBar setText:self.homeAddress];
            [UIStaff putCursorOnFrontIn:searchBar];
            [self getAddressWithSearchText:self.homeAddress];
            break;
        case 3:
            [self.searchDisplayController.searchBar setText:self.workAddress];
            [UIStaff putCursorOnFrontIn:searchBar];
            [self getAddressWithSearchText:self.workAddress];
            break;
        default:
            break;
    }
    self.selectedScope = selectedScope;
    if ([self.searchDisplayController isActive]) {
        [self.searchDisplayController.searchResultsTableView reloadData];
    } else {
        [self.tableView reloadData];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (self.selectedScope == 0 || self.selectedScope == 1) {
        [self getAddressWithSearchText:searchText];
    }
}

#pragma mark -
#pragma mark Get Address with request

- (void)getAddressWithSearchText:(NSString *)searchText {
    NSString *getPlacesByAddress = [Utils getFromPlistWithKey:@"GooglePlacesAPIURL"];
    NSString *placesAPIKey = [Utils getFromPlistWithKey:@"PlacesAPIKey"];
    NSString *url = nil;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        if ([searchText containsString:@" "]) {
            searchText = [searchText stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        }
        url = [NSString stringWithFormat:getPlacesByAddress, searchText, placesAPIKey];
    } else if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        if ([searchText rangeOfString:@" "].location != NSNotFound) {
            searchText = [searchText stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        }
        url = [NSString stringWithFormat:getPlacesByAddress, searchText, placesAPIKey];
        url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    [Requests sendPostRequest:url andCallback:^(NSDictionary *response) {
        NSString *status = [response valueForKey:@"status"];
        if ([status isEqualToString:@"OK"]) {
            _searchItems = [response valueForKeyPath:@"predictions.description"];
            NSString *scopeTitle = [self.searchDisplayController.searchBar.scopeButtonTitles objectAtIndex:self.selectedScope];
            switch (self.selectedScope) {
                case 0:
                    _fromPlaceId = [[response valueForKeyPath:@"predictions.place_id"] objectAtIndex:0];
                    break;
                case 1:
                    _toPlaceId = [[response valueForKeyPath:@"predictions.place_id"] objectAtIndex:0];
                    break;
                default:
                    break;
            }
            if (self.selectedScope == 2) {
                if ([scopeTitle isEqualToString:KKLocalizedString(@"From Home")]) {
                    _fromPlaceId = [[response valueForKeyPath:@"predictions.place_id"] objectAtIndex:0];
                } else if ([scopeTitle isEqualToString:KKLocalizedString(@"To Home")]) {
                    _toPlaceId = [[response valueForKeyPath:@"predictions.place_id"] objectAtIndex:0];
                }
            } else if (self.selectedScope == 3) {
                if ([scopeTitle isEqualToString:KKLocalizedString(@"From Work")]) {
                    _fromPlaceId = [[response valueForKeyPath:@"predictions.place_id"] objectAtIndex:0];
                } else if ([scopeTitle isEqualToString:KKLocalizedString(@"To Work")]) {
                    _toPlaceId = [[response valueForKeyPath:@"predictions.place_id"] objectAtIndex:0];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.searchDisplayController.searchResultsTableView reloadData];
            });
        } else if ([status isEqualToString:@"ZERO_RESULTS"]) {
            [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:KKLocalizedString(@"Could not find any address.") onFollowingViewController:self];
        }
    } andFailCallBack:^(NSError *error) {
        [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self];
    }];
}

#pragma mark -
#pragma mark Get Location by Place Id

- (void)getFromLocationByPlaceId:(NSString *)placeId {
    NSString *placeURL = [Utils getFromPlistWithKey:@"GetLocationByPlaceID"];
    NSString *placesAPIKey = [Utils getFromPlistWithKey:@"PlacesAPIKey"];
    NSString *url = [NSString stringWithFormat:placeURL, placeId, placesAPIKey];
    [Requests sendPostRequest:url andCallback:^(NSDictionary *response) {
        NSString *status = [response valueForKey:@"status"];
        if ([status isEqualToString:@"OK"]) {
            CLLocationDegrees latitude = [[response valueForKeyPath:@"result.geometry.location.lat"] doubleValue];
            CLLocationDegrees longitude = [[response valueForKeyPath:@"result.geometry.location.lng"] doubleValue];
            NSUInteger selectedScopeIndex = [self.searchDisplayController.searchBar selectedScopeButtonIndex];
            NSString *scopeTitle = [self.searchDisplayController.searchBar.scopeButtonTitles objectAtIndex:selectedScopeIndex];
            if ([scopeTitle isEqualToString:KKLocalizedString(@"From")] || [scopeTitle isEqualToString:KKLocalizedString(@"From Home")] ||
                [scopeTitle isEqualToString:KKLocalizedString(@"From Work")]) {
                _fromLocation = CLLocationCoordinate2DMake(latitude, longitude);
            }
            if (self.fromLocation.latitude != 0 && self.fromLocation.longitude != 0) {
                if (self.toLocation.latitude != 0 && self.toLocation.longitude != 0) {
                    if (!self.isCalculationCalled) {
                        [self calculateDistanceFromLocation:self.fromLocation toLocation:self.toLocation];
                    }
                }
                
            }
        }
    } andFailCallBack:^(NSError *error) {
        [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self];
    }];
}

- (void)getToLocationByPlaceId:(NSString *)placeId {
    NSString *placeURL = [Utils getFromPlistWithKey:@"GetLocationByPlaceID"];
    NSString *placesAPIKey = [Utils getFromPlistWithKey:@"PlacesAPIKey"];
    NSString *url = [NSString stringWithFormat:placeURL, placeId, placesAPIKey];
    [Requests sendPostRequest:url andCallback:^(NSDictionary *response) {
        NSString *status = [response valueForKey:@"status"];
        if ([status isEqualToString:@"OK"]) {
            CLLocationDegrees latitude = [[response valueForKeyPath:@"result.geometry.location.lat"] doubleValue];
            CLLocationDegrees longitude = [[response valueForKeyPath:@"result.geometry.location.lng"] doubleValue];
            NSUInteger selectedScopeIndex = [self.searchDisplayController.searchBar selectedScopeButtonIndex];
            NSString *scopeTitle = [self.searchDisplayController.searchBar.scopeButtonTitles objectAtIndex:selectedScopeIndex];
            if ([scopeTitle isEqualToString:@"To"] || [scopeTitle isEqualToString:@"To Home"] || [scopeTitle isEqualToString:@"To Work"]) {
                _toLocation = CLLocationCoordinate2DMake(latitude, longitude);
            }
            if (self.fromLocation.latitude != 0 && self.fromLocation.longitude != 0) {
                if (self.toLocation.latitude != 0 && self.toLocation.longitude != 0) {
                    if (!self.isCalculationCalled) {
                        [self calculateDistanceFromLocation:self.fromLocation toLocation:self.toLocation];
                    }
                }
            }
        }
    } andFailCallBack:^(NSError *error) {
        [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self];
    }];
}


#pragma mark -
#pragma mark Calculate Distance

- (void)calculateDistanceFromLocation:(CLLocationCoordinate2D)fromStartLocation toLocation:(CLLocationCoordinate2D)toEndLocation {
    NSString *distanceByLocationURL = [Utils getFromPlistWithKey:@"GetDistanceByLocation"];
    NSString *url = [NSString stringWithFormat:distanceByLocationURL, fromStartLocation.latitude, fromStartLocation.longitude, toEndLocation.latitude, toEndLocation.longitude];
    [Requests sendPostRequest:url andCallback:^(NSDictionary *response) {
        NSString *status = [response valueForKey:@"status"];
        if ([status isEqualToString:@"OK"]) {
            NSString *elementStatus = [[[response valueForKeyPath:@"rows.elements.status"] objectAtIndex:0] objectAtIndex:0];
            if ([elementStatus isEqualToString:@"OK"]) {
                NSString *distance = [[[response valueForKeyPath:@"rows.elements.distance.text"] objectAtIndex:0] objectAtIndex:0];
                NSString *duration = [[[response valueForKeyPath:@"rows.elements.duration.text"] objectAtIndex:0] objectAtIndex:0];
                _fromAddress = [[response valueForKey:@"origin_addresses"] objectAtIndex:0];
                _toAddress = [[response valueForKey:@"destination_addresses"] objectAtIndex:0];
                [self.distanceDurationSuperView setDistance:distance];
                [self.distanceDurationSuperView setDuration:duration];
                [self.distanceDurationSuperView setNeedsDisplay];
                [UIView animateWithDuration:0.5f animations:^{
                    [_distanceDurationSuperView setFrame:CGRectSetPos([self.distanceDurationSuperView frame], 15.0f, 242.0f)];
                }];
                NSString *removingPartFromDistance = @" mi";
                NSString *removingPartFromDuration = @" mins";
                CGFloat distanceInFloat = 0.0f;
                NSInteger durationInInt = 0;
                if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
                    if ([distance containsString:removingPartFromDistance]) {
                        NSString *convertedDistance = [distance substringToIndex:[distance length] - 3];
                        distanceInFloat = [convertedDistance floatValue];
                    }
                    if ([duration containsString:removingPartFromDuration]) {
                        NSString *convertedDuration = [duration substringToIndex:[distance length] - 3];
                        durationInInt = [convertedDuration integerValue];
                    }
                } else if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
                    if ([distance rangeOfString:removingPartFromDistance].location != NSNotFound) {
                        NSString *convertedDistance = [distance substringToIndex:[distance length] - 3];
                        distanceInFloat = [convertedDistance floatValue];
                    }
                    if ([duration rangeOfString:removingPartFromDuration].location != NSNotFound) {
                        NSString *convertedDuration = [duration substringToIndex:[distance length] - 3];
                        durationInInt = [convertedDuration integerValue];
                    }
                }
                self.isCalculationCalled = NO;
                [self retrieveAvailableCars];
                [self estimateRideWithDistance:distanceInFloat andDuration:durationInInt];
            } else if ([elementStatus isEqualToString:@"ZERO_RESULTS"]) {
                if (![self.navigationController.visibleViewController isKindOfClass:[UIAlertController class]]) {
                    [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:KKLocalizedString(@"Please, type exact address.") onFollowingViewController:self];
                }
            }
        }
    } andFailCallBack:^(NSError *error) {
        if (![self.navigationController.visibleViewController isKindOfClass:[UIAlertController class]]) {
            [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self];
        }
    }];
    self.isCalculationCalled = YES;
}

#pragma mark -
#pragma mark Estimate Ride

- (void)estimateRideWithDistance:(CGFloat)distance andDuration:(NSUInteger)duration {
    NSString *selectedCarType = [self.selectCarTextField text];
    if (![selectedCarType isEqualToString:KKLocalizedString(@"Select a car")]) {
        if (self.carTypeInt == 0) {
            NSUInteger wheelchairAccess = 0;
            NSUInteger carSeatAccess = 0;
            NSUInteger cameraAccess = 0;
            if ([self.specialRequests count] > 0) {
                wheelchairAccess = [[self.specialRequests objectAtIndex:0] unsignedIntegerValue];
                carSeatAccess = [[self.specialRequests objectAtIndex:1] unsignedIntegerValue];
                cameraAccess = [[self.specialRequests objectAtIndex:2] unsignedIntegerValue];
            }
            NSString *sessionId = [[NSUserDefaults standardUserDefaults] objectForKey:@"tsmSessionId"];
            NSString *url = [Utils getFromPlistWithKey:@"GetCarTypes"];
            NSDictionary *params = @{ @"sessionId": sessionId, @"latitude": [NSNumber numberWithDouble:self.fromLocation.latitude], @"longitude": [NSNumber numberWithDouble:self.fromLocation.longitude], @"wheelchairAccess": [NSNumber numberWithUnsignedInteger:wheelchairAccess], @"carSeatAccess": [NSNumber numberWithUnsignedInteger:carSeatAccess], @"cameraAccess": [NSNumber numberWithUnsignedInteger:cameraAccess] };
            [Requests sendPostRequest:url withParameters:params andCallback:^(NSDictionary *response) {
                NSString *result = [response valueForKey:@"result"];
                if ([result isEqualToString:@"OK"]) {
                    if (!_carTypes) {
                        _carTypes = [NSArray array];
                    }
                    if (!_classId) {
                        _classId = [NSArray array];
                    }
                    if ([response valueForKey:@"carClasses"]) {
                        BOOL isExistenceAvailableVehicle = [[response valueForKey:@"isExistAvailableVehicle"] boolValue];
                        if (isExistenceAvailableVehicle) {
                            NSString *className = [response valueForKeyPath:@"carClasses.className"];
                            _carTypes = @[className];
                            _carTypes = [self.carTypes objectAtIndex:0];
                            _classId = @[[response valueForKeyPath:@"carClasses.classId"]];
                            _classId = [self.classId objectAtIndex:0];
                            [self.selectCarTextField setText:[self.carTypes objectAtIndex:0]];
                            self.carTypeInt = [[self.classId objectAtIndex:0] unsignedIntegerValue];
                            [self estimateWith:distance andDuration:duration];
                        } else {
                            NSString *message = [response valueForKey:@"message"];
                            [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:message onFollowingViewController:self];
                        }
                    } else {
                        NSLog(@"fff :%@", response);
                        NSString *message = [response valueForKey:@"message"];
                        [Utils showSimpleAlertsWithTitle:@"Message" andMessage:message onFollowingViewController:self];
                    }
                }
            } andFailCallBack:^(NSError *error) {
                [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self];
            }];
        } else {
            [self estimateWith:distance andDuration:duration];
        }
    }
}

- (void)estimateWith:(CGFloat)dist andDuration:(CGFloat)duration {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *sessionId = [defaults objectForKey:@"tsmSessionId"];
    NSString *url = [Utils getFromPlistWithKey:@"EstimateRideURL"];
    CGFloat startLatitude = self.fromLocation.latitude;
    CGFloat startLongitude = self.fromLocation.longitude;
    CGFloat endLatitude = self.toLocation.latitude;
    CGFloat endLongitude = self.toLocation.longitude;
    NSDictionary *params = @{ @"sessionId": sessionId, @"carType": [NSNumber numberWithUnsignedInteger:self.carTypeInt], @"startLatitude": [NSNumber numberWithFloat:startLatitude], @"startLongitude": [NSNumber numberWithFloat:startLongitude], @"endLatitude": [NSNumber numberWithFloat:endLatitude], @"endLongitude": [NSNumber numberWithFloat:endLongitude], @"reserved": [NSNumber numberWithUnsignedInteger:0], @"distance": [NSNumber numberWithFloat:dist], @"estimationTime": [NSNumber numberWithInteger:duration] };
    NSLog(@"params :%@", params);
    [Requests sendPostRequest:url withParameters:params andCallback:^(NSDictionary *response) {
        NSString *status = [response valueForKey:@"result"];
        if ([status isEqualToString:@"OK"]) {
            NSLog(@"response :%@", response);
            NSUInteger estimatedAmount = [[response valueForKey:@"estimatedAmount"] unsignedIntegerValue];
            NSString *currency = [response valueForKey:@"currency"];
            NSString *cost = [NSString stringWithFormat:@"%@ %lu", currency, (unsigned long)estimatedAmount];
            [self.estimatedCostView setCost:cost];
            [self.estimatedCostView setNeedsDisplay];
            [UIView animateWithDuration:0.5f animations:^{
                [_estimatedCostView setFrame:CGRectSetPos([self.estimatedCostView frame], 15.0f, 290.0f)];
            } completion:^(BOOL finished) {
                if (finished) {
                    [self drawStartEndPoints];
                }
            }];
        }
    } andFailCallBack:^(NSError *error) {
        [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self];
    }];
}

#pragma mark -
#pragma mark Draw start/end points

- (void)drawStartEndPoints {
    [self.mapView setHidden:NO];
    [self.mapView clear];
    CLLocationCoordinate2D startLocation = CLLocationCoordinate2DMake(self.fromLocation.latitude, self.fromLocation.longitude);
    CLLocationCoordinate2D endLocation = CLLocationCoordinate2DMake(self.toLocation.latitude, self.toLocation.longitude);
    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] init];
    bounds = [bounds includingCoordinate:startLocation];
    bounds = [bounds includingCoordinate:endLocation];
    [self.mapView animateWithCameraUpdate:[GMSCameraUpdate fitBounds:bounds withPadding:55.0f]];
    GMSMarker *startMarker = [GMSMarker markerWithPosition:startLocation];
    [startMarker setAppearAnimation:kGMSMarkerAnimationPop];
    [startMarker setTitle:KKLocalizedString(@"Start")];
    [startMarker setMap:_mapView];
    GMSMarker *endMarker = [GMSMarker markerWithPosition:endLocation];
    [endMarker setAppearAnimation:kGMSMarkerAnimationPop];
    [endMarker setTitle:KKLocalizedString(@"Finish")];
    [endMarker setMap:_mapView];
    NSString *findNearestWayURL = [Utils getFromPlistWithKey:@"FindNearestWayURL"];
    NSString *url = [NSString stringWithFormat:findNearestWayURL, startLocation.latitude, startLocation.longitude, endLocation.latitude, endLocation.longitude];
    [Requests sendPostRequest:url andCallback:^(NSDictionary *response) {
        NSString *status = [response valueForKey:@"status"];
        if ([status isEqualToString:@"OK"]) {
            NSString *encodedPathStr = [[[[response objectForKey:@"routes"] objectAtIndex:0] objectForKey:@"overview_polyline"] objectForKey:@"points"];
            GMSPath *path = [GMSPath pathFromEncodedPath:encodedPathStr];
            self.polyline.map = nil;
            _polyline = [GMSPolyline polylineWithPath:path];
            [self.polyline setStrokeWidth:4.0f];
            [self.polyline setStrokeColor:[UIColor colorWithRed:72.0f/255.0f green:224.0f/255.0f blue:109.0f/255.0f alpha:0.75f]];
            [self.polyline setMap:self.mapView];
            [self.navigationItem.rightBarButtonItem.customView setHidden:NO];
        } else if ([status isEqualToString:@"ZERO_RESULTS"]) {
            [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:KKLocalizedString(@"Cannot find the nearest way.") onFollowingViewController:self];
        }
    } andFailCallBack:^(NSError *error) {
        [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self];
    }];
}

#pragma mark -
#pragma mark Order Action

- (void)ordering:(UIBarButtonItem *)sender {
    NSLog(@"ordering");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *sessionId = [defaults objectForKey:@"tsmSessionId"];
    NSString *url = [Utils getFromPlistWithKey:@"OrderURL"];
    NSDictionary *params = @{ @"sessionId": sessionId, @"userType": [NSNumber numberWithUnsignedInteger:2], @"carType": [NSNumber numberWithUnsignedInteger:self.carTypeInt], @"latitude": [NSNumber numberWithDouble:self.fromLocation.latitude], @"longitude": [NSNumber numberWithDouble:self.fromLocation.longitude], @"endLatitude": [NSNumber numberWithDouble:self.toLocation.latitude], @"endLongitude": [NSNumber numberWithDouble:self.toLocation.longitude], @"startAddress": self.fromAddress, @"destinationAddress": self.toAddress };
    SCLAlertView *alert = [[SCLAlertView alloc] init];
    [Requests sendPostRequest:url withParameters:params andCallback:^(NSDictionary *response) {
        NSLog(@"Response :%@", response);
        NSString *status = [response valueForKey:@"result"];
        if ([status isEqualToString:@"OK"]) {
            _isOrdered = [[response valueForKey:@"isOrder"] boolValue];
            NSString *message = [response valueForKey:@"message"];
            if (self.isOrdered) {
                [alert showSuccess:self.navigationController title:@"Success" subTitle:message closeButtonTitle:@"OK" duration:0.0f];
            } else {
                [alert showNotice:self.navigationController title:@"Message" subTitle:message closeButtonTitle:@"OK" duration:0.0f];
            }
        }
    } andFailCallBack:^(NSError *error) {
        [alert showError:self.navigationController title:KKLocalizedString(@"ERROR") subTitle:[error localizedDescription] closeButtonTitle:@"OK" duration:0.0f];
    }];
}

-(void)viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        ViewController *parentViewController = [self.navigationController.viewControllers objectAtIndex:0];
        if ([parentViewController isKindOfClass:[ViewController class]]) {
            parentViewController.startLocation = self.fromLocation;
            parentViewController.showPopupView = NO;
        }
    }
    [super viewWillDisappear:animated];
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
