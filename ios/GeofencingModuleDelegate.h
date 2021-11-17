//
//  GeofencingModuleDelegate.h
//  app_geoparque_vc
//
//  Created by Carlos Silva on 16/03/2021.
//  Copyright © 2021 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreLocation/CLLocationManagerDelegate.h>

@interface GeofencingModuleDelegate : NSObject<CLLocationManagerDelegate>

+ (GeofencingModuleDelegate *)sharedManager;
+ (void)start;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) UNUserNotificationCenter *notificationCenter;
@property (nonatomic, weak) id delegate;

+ (void)writeToFile:(NSMutableArray*)array withName:(NSString*) filename;
+ (NSMutableArray*)readFromFile:(NSString*) filename;
+ (void)loadAttachmentForUrlString:(NSString *)urlString completionHandler:(void(^)(UNNotificationAttachment *))completionHandler;
+ (BOOL)authorizeUserForThisModule;
+ (void) getDataFrom:(NSString *)url withCompletionHandler:(void(^)(NSMutableArray *result))withCompletionHandler withError:(void(^)(NSMutableArray *result))withError;
@end

