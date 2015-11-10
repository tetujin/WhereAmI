//
//  ViewController.h
//  WhereAmI
//
//  Created by Yuuki Nishiyama on 11/9/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SystemConfiguration/CaptiveNetwork.h>

extern NSString * const KEY_BSSID;
extern NSString * const KEY_APP_ID;
extern NSString * const KEY_DEVICE_INFO;

extern NSString * const KEY_VAL_BUILDING_NAME;
extern NSString * const KEY_VAL_ROOM_NAME;
extern NSString * const KEY_VAL_AP_SSID;
extern NSString * const KEY_VAL_AP_FREQUENCY;
extern NSString * const KEY_VAL_AP_BSSID;

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *apiIdField;
@property (weak, nonatomic) IBOutlet UILabel *resultTextView;


- (IBAction)pushedUpdateButton:(id)sender;

@end

