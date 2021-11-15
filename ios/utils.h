//
//  Utils.h
//  app_geoparque_vc
//
//  Created by Carlos Silva on 21/03/2021.
//  Copyright © 2021 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import <CoreLocation/CoreLocation.h>

@interface Utils : NSObject<CLLocationManagerDelegate>{
  CLLocationManager *locationManager;
}

@property (nonatomic, retain) CLLocationManager *locationManager;

+ (Utils *)sharedManager;

+ (void)writeToFile:(NSMutableArray*)array withName:(NSString*) filename;
+ (NSMutableArray*)readFromFile:(NSString*) filename;
+ (void)loadAttachmentForUrlString:(NSString *)urlString completionHandler:(void(^)(UNNotificationAttachment *))completionHandler;
+ (BOOL)authorizeUserForThisModule;
+ (void) getDataFrom:(NSString *)url withCompletionHandler:(void(^)(NSMutableArray *result))withCompletionHandler withError:(void(^)(NSMutableArray *result))withError;
@end
