//
//  GeofencingModuleDelegate.m
//
//  Created by Carlos Silva on 16/03/2021.
//  Copyright © 2021 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeofencingModuleDelegate.h"
#import "NativeGeofencing.h"

#import <CoreLocation/CoreLocation.h>
#import <UserNotifications/UserNotifications.h>
#import <CoreLocation/CLLocationManagerDelegate.h>

@implementation GeofencingModuleDelegate

+ (GeofencingModuleDelegate *)sharedManager {
    static GeofencingModuleDelegate *sharedMyManager = nil;
    static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedMyManager = [[self alloc]init];
        });
        return sharedMyManager;
}

+(void)start {
    static GeofencingModuleDelegate *sharedMyManager = nil;
    static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedMyManager = [[self alloc]init];
        });
}

- (id)init {
    self = [super init];
    if (self != nil) {
          //we now create a new self.locationManager service
          self.locationManager = [CLLocationManager new];
          self.locationManager.distanceFilter = 5;
          self.locationManager.allowsBackgroundLocationUpdates = true;
          self.locationManager.pausesLocationUpdatesAutomatically = true;
          self.locationManager.activityType = CLActivityTypeFitness;
          self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
          self.locationManager.delegate = self;
        
        self.notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
        self.notificationCenter.delegate = self;
    
      }
    return self;
}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler{
NSLog(@"User Info : %@",notification.request.content.userInfo);
completionHandler(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge);
}

- (void)locationManager:(CLLocationManager *)_manager didExitRegion:(CLRegion *)region{
  NSLog(@"Region = %@", @"Did exit Region");
}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler
{
  NSLog(@"User Info : %@", response.notification.request.content.userInfo);

  if([response.notification.request.content.userInfo valueForKeyPath:@"deepLink"] !=nil){
    NSString *deepLink = [response.notification.request.content.userInfo valueForKeyPath:@"deepLink"];
    UIApplication *application = [UIApplication sharedApplication];
    NSURL *URL = [NSURL URLWithString:deepLink];
    [application openURL:URL options:@{} completionHandler:^(BOOL success) {
        if (success) {
             NSLog(@"Opened url");
        }
    }];
  }

  completionHandler(UNNotificationPresentationOptionAlert);
}

- (void)locationManager:(CLLocationManager *)_manager monitoringDidFailFor:(CLRegion *)region withError:(NSError *)error{
  printf("Monitoring failed for region with identifier: \(region!.identifier)");
}

- (void)locationManager:(CLLocationManager *)_manager didFailWithError:(CLRegion *)region withError:(NSError *)error{
  printf("Location Manager failed with the following error: \(error)");
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
            NSLog(@"GEOFENCE: %@", @"START MONITORING");
    [[GeofencingModuleDelegate sharedManager].self.locationManager performSelector:@selector(requestStateForRegion:) withObject:region afterDelay:5];
}

- (void)locationManager:(CLLocationManager *)manager
  didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {

    if (state == CLRegionStateInside){

        [self enterGeofence:region];

    } else if (state == CLRegionStateOutside){

        [self exitGeofence:region];

    } else if (state == CLRegionStateUnknown){
        NSLog(@"Unknown state for geofence: %@", region);
        return;
    }
}


- (void)exitGeofence:(CLRegion *)region {
  NSLog(@"Region Did exit Region= %@", [region valueForKeyPath:@"identifier"]);
//  NSLog(@"Region details= %@", region);

  NSMutableArray *collection =  [GeofencingModuleDelegate readFromFile:@"geofenceEntries"];
  NSString *name= nil;
  NSString *desc= nil;
  NSString *poiId= nil;
  NSString *imageURL= nil;
  NSString *deepLinkURL= nil;

  if(![[region valueForKeyPath:@"identifier"] isEqualToString:@"myCurrenLocation"]){
    //check values of the geojson key saved in the system
    for (int i = 0; i < [collection count]; i++)
    {
      if([[collection[i] valueForKeyPath:@"key"] isEqualToString:[region valueForKeyPath:@"identifier"]]){
        if([collection[i] valueForKeyPath:@"exitTitle"] != nil){
          name=[collection[i] valueForKeyPath:@"exitTitle"];
        }
        if([collection[i] valueForKeyPath:@"exitMessage"] != nil){
          desc=[collection[i] valueForKeyPath:@"exitMessage"];
        }
        if([collection[i] valueForKeyPath:@"largeIcon"] != nil){
          imageURL=[collection[i] valueForKeyPath:@"largeIcon"];
        }
        if([collection[i] valueForKeyPath:@"key"] != nil){
          poiId=[collection[i] valueForKeyPath:@"key"];
        }
        if([collection[i] valueForKeyPath:@"deepLink"] != nil){
          deepLinkURL=[collection[i] valueForKeyPath:@"deepLink"];
        }
        break;
      }
    }

    if(name != nil || desc != nil){

      NSLog(@"DEBUG CLASS IMAGE URL= %@", imageURL);

      UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];

      UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1
                                                                                                      repeats:NO];

      NSString *identifier = @"UYLLocalNotification";
      if(poiId !=nil){
        identifier = poiId;
      }

      content.title = desc;
      content.body = name;
      content.sound = [UNNotificationSound defaultSound];

      if(deepLinkURL != nil){
        content.userInfo = @{@"deepLink": deepLinkURL};
      }

      if(imageURL){
        [GeofencingModuleDelegate loadAttachmentForUrlString:imageURL completionHandler:^(UNNotificationAttachment *attachment) {

          if (attachment) {
            content.attachments = [NSArray arrayWithObject:attachment];
          }

          UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                                content:content trigger:trigger];


          [self.notificationCenter addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error != nil) {
              NSLog(@"Something went wrong: %@",error);
            }
          }];
        }];
      }else{
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                              content:content trigger:trigger];
        [self.notificationCenter addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
          if (error != nil) {
            NSLog(@"Something went wrong: %@",error);
          }
        }];
      }
    }
  }

  if([[region valueForKeyPath:@"identifier"] isEqualToString:@"myCurrenLocation"]){
    NSLog(@"Region = %@", @"Did exit myCurrenLocation");
      NativeGeofencing *theObject=[[NativeGeofencing alloc]init];
    [theObject configPoiFromMe];
  }
}

- (void)enterGeofence:(CLRegion *)region {
  NSLog(@"Region = %@", @"Did enter Region");

  NSMutableArray *collection =  [GeofencingModuleDelegate readFromFile:@"geofenceEntries"];
  NSString *name= nil;
  NSString *desc= nil;
  NSString *poiId= nil;
  NSString *imageURL= nil;
  NSString *deepLinkURL= nil;

  NSLog(@"Region = %@", [region valueForKeyPath:@"identifier"]);

  if(![[region valueForKeyPath:@"identifier"] isEqualToString:@"myCurrenLocation"]){
    NSLog(@"Region = %@", @"Did enter valid Region");

    //check values of the geojson key saved in the system
    for (int i = 0; i < [collection count]; i++)
    {
      if([[collection[i] valueForKeyPath:@"key"] isEqualToString:[region valueForKeyPath:@"identifier"]]){
        if([collection[i] valueForKeyPath:@"enterTitle"] != nil){
          name=[collection[i] valueForKeyPath:@"enterTitle"];
        }
        if([collection[i] valueForKeyPath:@"enterMessage"] != nil){
          desc=[collection[i] valueForKeyPath:@"enterMessage"];
        }
        if([collection[i] valueForKeyPath:@"largeIcon"] != nil){
          imageURL=[collection[i] valueForKeyPath:@"largeIcon"];
        }
        if([collection[i] valueForKeyPath:@"key"] != nil){
          poiId=[collection[i] valueForKeyPath:@"key"];
        }
        if([collection[i] valueForKeyPath:@"deepLink"] != nil){
          deepLinkURL=[collection[i] valueForKeyPath:@"deepLink"];
        }

        break;
      }
    }

    NSLog(@"Did enter valid Region Name = %@", name);
    NSLog(@"Did enter valid Region Desc = %@", desc);

    if(name != nil || desc != nil){

      NSLog(@"DEBUG CLASS IMAGE URL= %@", imageURL);

      UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
      UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1
                                                                                                      repeats:NO];
      NSString *identifier = @"UYLLocalNotification";
      if(poiId !=nil){
        identifier = poiId;
      }

      content.title = desc;
      content.body = name;
      content.sound = [UNNotificationSound defaultSound];

      if(deepLinkURL != nil){
        content.userInfo = @{@"deepLink": deepLinkURL};
      }

      if(imageURL != nil){
        [GeofencingModuleDelegate loadAttachmentForUrlString:imageURL completionHandler:^(UNNotificationAttachment *attachment) {

          if (attachment) {
            content.attachments = [NSArray arrayWithObject:attachment];
          }

          UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                                content:content trigger:trigger];
          [self.notificationCenter addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error != nil) {
              NSLog(@"Something went wrong: %@",error);
            }
          }];
        }];
      }else{
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                              content:content trigger:trigger];
        [self.notificationCenter addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
          if (error != nil) {
            NSLog(@"Something went wrong: %@",error);
          }
        }];
      }
    }
  }
}

- (NSMutableArray*)readFromFile:(NSString*) filename {
  // Build the path
  NSString* filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  NSString* fileName = [NSString stringWithFormat:filename, @".json"];
  NSString* fileAtPath = [filePath stringByAppendingPathComponent:fileName];

  // The main act...
  return [NSMutableArray arrayWithContentsOfFile:fileAtPath];
}

// UTILS ::::::


+ (void)writeToFile:(NSMutableArray*)array withName:(NSString*) filename {
  // Build the path, and create if needed.
  NSString* filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  NSString* fileName = [NSString stringWithFormat:filename, @".json"];
  NSString* fileAtPath = [filePath stringByAppendingPathComponent:fileName];

  if (![[NSFileManager defaultManager] fileExistsAtPath:fileAtPath]) {
    [[NSFileManager defaultManager] createFileAtPath:fileAtPath contents:nil attributes:nil];
  }

  // The main act...
  [array writeToFile:fileAtPath atomically:YES];
}

+ (NSMutableArray*)readFromFile:(NSString*) filename {
  // Build the path
  NSString* filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  NSString* fileName = [NSString stringWithFormat:filename, @".json"];
  NSString* fileAtPath = [filePath stringByAppendingPathComponent:fileName];

  // The main act...
  return [NSMutableArray arrayWithContentsOfFile:fileAtPath];
}

+ (void)loadAttachmentForUrlString:(NSString *)urlString completionHandler:(void(^)(UNNotificationAttachment *))completionHandler  {

  __block UNNotificationAttachment *attachment = nil;
  NSURL *attachmentURL = [NSURL URLWithString:urlString];
  NSString *fileExt =  @".jpg";

  NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
  [[session downloadTaskWithURL:attachmentURL
              completionHandler:^(NSURL *temporaryFileLocation, NSURLResponse *response, NSError *error) {
    if (error != nil) {
      NSLog(@"%@", error.localizedDescription);
    } else {
      NSFileManager *fileManager = [NSFileManager defaultManager];
      NSURL *localURL = [NSURL fileURLWithPath:[temporaryFileLocation.path stringByAppendingString:fileExt]];
      [fileManager moveItemAtURL:temporaryFileLocation toURL:localURL error:&error];

      NSError *attachmentError = nil;
      attachment = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:localURL options:nil error:&attachmentError];
      if (attachmentError) {
        NSLog(@"%@", attachmentError.localizedDescription);
      }
    }
    completionHandler(attachment);
  }] resume];
}

+ (BOOL)authorizeUserForThisModule
{
  if([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways || [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedWhenInUse)
  {
    [[GeofencingModuleDelegate sharedManager].self.locationManager requestAlwaysAuthorization];
  } else {
    return false;
  }

  __block bool authorizedNotifications = true;

  UNAuthorizationOptions options = UNAuthorizationOptionBadge + UNAuthorizationOptionAlert + UNAuthorizationOptionSound;

  [[GeofencingModuleDelegate sharedManager].self.notificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
    if (settings.authorizationStatus != UNAuthorizationStatusAuthorized) {
      // Notifications not allowed
      [[GeofencingModuleDelegate sharedManager].self.notificationCenter requestAuthorizationWithOptions:options
                            completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (!granted) {
          NSLog(@"Something went wrong");
          authorizedNotifications = false;
        }else{
          authorizedNotifications = true;
        }
      }];
    }else{
      authorizedNotifications = true;
    }
  }];

  return authorizedNotifications && [CLLocationManager locationServicesEnabled];
}

+ (void) getDataFrom:(NSString *)url withCompletionHandler:(void(^)(NSMutableArray *result))withCompletionHandler withError:(void(^)(NSMutableArray *result))withError{
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
  [request setHTTPMethod:@"GET"];
  [request setURL:[NSURL URLWithString:url]];

  [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSInteger statusCode = httpResponse.statusCode;
    if (statusCode >= 200 && statusCode < 300){
      withCompletionHandler([NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error]);
    }else{
      withError([NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error]);
      NSLog(@"Error getting %@, HTTP status code %li", url, (long)[httpResponse statusCode]);
    }
  }] resume];
}


@end
