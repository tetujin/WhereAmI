//
//  ViewController.m
//  WhereAmI
//
//  Created by Yuuki Nishiyama on 11/9/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "ViewController.h"
#include <sys/sysctl.h>
#include <sys/utsname.h>

NSString * const KEY_BSSID = @"nearestBSSID";
NSString * const KEY_APP_ID = @"apiID";
NSString * const KEY_DEVICE_INFO = @"deviceInformation";

NSString * const KEY_VAL_BUILDING_NAME = @"buildingName";
NSString * const KEY_VAL_ROOM_NAME = @"roomName";
NSString * const KEY_VAL_AP_SSID = @"apSSID";
NSString * const KEY_VAL_AP_FREQUENCY = @"apFrequency";
NSString * const KEY_VAL_AP_BSSID = @"apBSSID";

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeSoftKeyboard)];
    [self.view addGestureRecognizer:gestureRecognizer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)closeSoftKeyboard {
    [self.view endEditing: YES];
}


- (IBAction)pushedUpdateButton:(id)sender {
    NSString *appID = _apiIdField.text;
    NSString *bssid = [self getCurrentWifiBSSID];
    NSString *deviceInfo = [self getDeviceInfo];
    [self getIndoorLocationFromAPIWithBSSID:bssid apiID:appID deviceInfo:deviceInfo];
}

/**
 * Get indoor location from API with BSSID, appID and device Information.
 */
- (void) getIndoorLocationFromAPIWithBSSID:(NSString *)bssid
                                     apiID:(NSString*) apiID
                                deviceInfo:(NSString *) deviceInfo{
    NSString *url = @"http://r2d2.hcii.cs.cmu.edu:9001/campus/location/wifi";
    NSMutableDictionary* jsonDict = [[NSMutableDictionary alloc] init];
    [jsonDict setObject:bssid forKey:KEY_BSSID];
    [jsonDict setObject:apiID forKey:KEY_APP_ID];
    [jsonDict setObject:deviceInfo forKey:KEY_DEVICE_INFO];
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
//    NSLog(@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:jsonData];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error = nil;
        NSHTTPURLResponse *response = nil;
        NSData *resData = [NSURLConnection sendSynchronousRequest:request
                                                returningResponse:&response error:&error];
        int responseCode = (int)[response statusCode];
        NSDictionary * responseData = [[NSDictionary alloc] init];
        if(responseCode == 200){
            NSError *jsonParsingError = nil;
            responseData = [NSJSONSerialization JSONObjectWithData:resData
                                                          options:0//NSJSONReadingMutableContainers
                                                            error:&jsonParsingError];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"%@",responseData.description);
            if (![responseData isEqual:nil]) {
                NSDictionary *resultObject = [responseData objectForKey:@"resultObject"];
                NSString *buildingName = [resultObject objectForKey:KEY_VAL_BUILDING_NAME];
                NSString *roomName = [resultObject objectForKey:KEY_VAL_ROOM_NAME];
                NSString *apSSID = [resultObject objectForKey:KEY_VAL_AP_SSID];
                NSString *apFrequency = [resultObject objectForKey:KEY_VAL_AP_FREQUENCY];
                NSString *apBSSID = [resultObject objectForKey:KEY_VAL_AP_BSSID];
                NSString *resultText = [NSString stringWithFormat:@"Location based on Wi-Fi\n"
                                                                "- Building Name='%@'\n"
                                                                "- Room Name='%@'\n"
                                                                "- AP SSID='%@'\n"
                                                                "- AP Frequency='%@'\n"
                                                                "- AP BSSID='%@'",
                                        buildingName, roomName, apSSID, apFrequency, apBSSID];
                _resultTextView.text = resultText;
            }
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Updated!"
//                                                            message:@""
//                                                           delegate:self
//                                                  cancelButtonTitle:@"OK"
//                                                  otherButtonTitles:nil];
//            [alert show];
        });
    });
}


/**
 * Get current wifi BSSID
 */
- (NSString *) getCurrentWifiBSSID {
    NSString *bssid = nil;
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    for (NSString *ifnam in ifs) {
        NSDictionary *info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        NSLog(@"info:%@",info);
        if (info[@"BSSID"]) {
            bssid = info[@"BSSID"];
        }
    }
    NSMutableString *finalBSSID = [[NSMutableString alloc] init];
    NSArray *arrayOfBssid = [bssid componentsSeparatedByString:@":"];
    for(int i=0; i<arrayOfBssid.count; i++){
        NSString *element = [arrayOfBssid objectAtIndex:i];
        if(element.length == 1){
            [finalBSSID appendString:[NSString stringWithFormat:@"0%@:",element]];
        }else if(element.length == 2){
            [finalBSSID appendString:[NSString stringWithFormat:@"%@:",element]];
        }else{
            NSLog(@"error");
        }
    }
    [finalBSSID deleteCharactersInRange:NSMakeRange([finalBSSID length]-1, 1)];
    NSLog(@"%@",finalBSSID);
    return finalBSSID;
}


/**
 *
 */
- (NSString *) getDeviceInfo{
    NSLog(@"[UIDevice currentDevice].model: %@",[UIDevice currentDevice].model);
    NSLog(@"[UIDevice currentDevice].description: %@",[UIDevice currentDevice].description);
    NSLog(@"[UIDevice currentDevice].localizedModel: %@",[UIDevice currentDevice].localizedModel);
    NSLog(@"[UIDevice currentDevice].name: %@",[UIDevice currentDevice].name);
    NSLog(@"[UIDevice currentDevice].systemVersion: %@",[UIDevice currentDevice].systemVersion);
    NSLog(@"[UIDevice currentDevice].systemName: %@",[UIDevice currentDevice].systemName);
    NSLog(@"[UIDevice currentDevice].batteryLevel: %f",[UIDevice currentDevice].batteryLevel);
    struct utsname systemInfo;
    uname(&systemInfo);
    NSLog(@"[NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding]: %@",[NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding]);
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

    NSLog(@"Your plarform is %@.", platform);
    NSString *platformName = @"Unknown";
    if ([platform isEqualToString:@"iPhone1,1"])    platformName = @"iPhone 1G";
    if ([platform isEqualToString:@"iPhone1,2"])    platformName =  @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    platformName =  @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    platformName =  @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,2"])    platformName =  @"iPhone 4 CDMA";
    if ([platform isEqualToString:@"iPhone3,3"])    platformName =  @"Verizon iPhone 4";
    if ([platform isEqualToString:@"iPhone4,1"])    platformName =  @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    platformName =  @"iPhone 5 (GSM)";
    if ([platform isEqualToString:@"iPhone5,2"])    platformName =  @"iPhone 5 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone5,3"])    platformName =  @"iPhone 5c (GSM)";
    if ([platform isEqualToString:@"iPhone5,4"])    platformName =  @"iPhone 5c (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone6,1"])    platformName =  @"iPhone 5s (GSM)";
    if ([platform isEqualToString:@"iPhone6,2"])    platformName =  @"iPhone 5s (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone7,2"])    platformName =  @"iPhone 6";
    if ([platform isEqualToString:@"iPhone7,1"])    platformName =  @"iPhone 6 Plus";
    if ([platform isEqualToString:@"iPod1,1"])      platformName =  @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      platformName =  @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      platformName =  @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      platformName =  @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])      platformName =  @"iPod Touch 5G";
    if ([platform isEqualToString:@"iPad1,1"])      platformName =  @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])      platformName =  @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,2"])      platformName =  @"iPad 2 (Cellular)";
    if ([platform isEqualToString:@"iPad2,3"])      platformName =  @"iPad 2 (Cellular)";
    if ([platform isEqualToString:@"iPad2,4"])      platformName =  @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,5"])      platformName =  @"iPad Mini (WiFi)";
    if ([platform isEqualToString:@"iPad2,6"])      platformName =  @"iPad Mini (Cellular)";
    if ([platform isEqualToString:@"iPad2,7"])      platformName =  @"iPad Mini (Cellular)";
    if ([platform isEqualToString:@"iPad3,1"])      platformName =  @"iPad 3 (WiFi)";
    if ([platform isEqualToString:@"iPad3,2"])      platformName =  @"iPad 3 (Cellular)";
    if ([platform isEqualToString:@"iPad3,3"])      platformName =  @"iPad 3 (Cellular)";
    if ([platform isEqualToString:@"iPad3,4"])      platformName =  @"iPad 4 (WiFi)";
    if ([platform isEqualToString:@"iPad3,5"])      platformName =  @"iPad 4 (Cellular)";
    if ([platform isEqualToString:@"iPad3,6"])      platformName =  @"iPad 4 (Cellular)";
    if ([platform isEqualToString:@"iPad4,1"])      platformName =  @"iPad Air (WiFi)";
    if ([platform isEqualToString:@"iPad4,2"])      platformName =  @"iPad Air (Cellular)";
    if ([platform isEqualToString:@"i386"])         platformName =  @"Simulator";
    if ([platform isEqualToString:@"x86_64"])       platformName =  @"Simulator";
    return [NSString stringWithFormat:@"%@/iOS%@", platformName,[UIDevice currentDevice].systemVersion];
}


@end
