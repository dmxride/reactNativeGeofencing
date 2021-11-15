//
//  GeofencingModuleDelegate.m
//  app_geoparque_vc
//
//  Created by Carlos Silva on 16/03/2021.
//  Copyright © 2021 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeofencingModuleDelegate.h"
#import "GeofencingModule.h"

#import <CoreLocation/CoreLocation.h>
#import <UserNotifications/UserNotifications.h>

@implementation GeofencingModuleDelegate

-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler{
NSLog(@"User Info : %@",notification.request.content.userInfo);
completionHandler(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge);
}

- (void)locationManager:(CLLocationManager *)_manager monitoringDidFailFor:(CLRegion *)region withError:(NSError *)error{
  printf("Monitoring failed for region with identifier: \(region!.identifier)");
}

- (void)locationManager:(CLLocationManager *)_manager didFailWithError:(CLRegion *)region withError:(NSError *)error{
  printf("Location Manager failed with the following error: \(error)");
}

- (void)locationManager:(CLLocationManager *)_manager didExitRegion:(CLRegion *)region{
  NSLog(@"Region = %@", @"Did exit Region");
}


// Add the openURL and continueUserActivity functions
-(BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {

  NSLog(@"Notification Info : %@", url);

    if (![RNBranch.branch application:app openURL:url options:options]) {
        // do other deep link routing for the Facebook SDK, Pinterest SDK, etc

    }
    return YES;
}

-(BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    return [RNBranch continueUserActivity:userActivity];
}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler{
  completionHandler(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge);
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

    [[Utils sharedManager].locationManager performSelector:@selector(requestStateForRegion:) withObject:region afterDelay:5];
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

  NSMutableArray *collection =  [Utils readFromFile:@"geofenceEntries"];
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

      UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
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
        [Utils loadAttachmentForUrlString:imageURL completionHandler:^(UNNotificationAttachment *attachment) {

          if (attachment) {
            content.attachments = [NSArray arrayWithObject:attachment];
          }

          UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                                content:content trigger:trigger];


          [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error != nil) {
              NSLog(@"Something went wrong: %@",error);
            }
          }];
        }];
      }else{
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                              content:content trigger:trigger];
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
          if (error != nil) {
            NSLog(@"Something went wrong: %@",error);
          }
        }];
      }
    }
  }

  if([[region valueForKeyPath:@"identifier"] isEqualToString:@"myCurrenLocation"]){
    NSLog(@"Region = %@", @"Did exit myCurrenLocation");
    GeofencingModule *theObject=[[GeofencingModule alloc]init];
    [theObject configPoiFromMe];
  }
}

- (void)enterGeofence:(CLRegion *)region {
  NSLog(@"Region = %@", @"Did enter Region");

  NSMutableArray *collection =  [Utils readFromFile:@"geofenceEntries"];
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

      UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
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
        [Utils loadAttachmentForUrlString:imageURL completionHandler:^(UNNotificationAttachment *attachment) {

          if (attachment) {
            content.attachments = [NSArray arrayWithObject:attachment];
          }

          UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                                content:content trigger:trigger];
          [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error != nil) {
              NSLog(@"Something went wrong: %@",error);
            }
          }];
        }];
      }else{
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                              content:content trigger:trigger];
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
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

@end
