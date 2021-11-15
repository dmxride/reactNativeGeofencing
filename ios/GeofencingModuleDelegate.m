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

- (void)locationManager:(CLLocationManager *)_manager didEnterRegion:(CLRegion *)region{
  NSLog(@"Region = %@", @"Did enter Region");
  
//  NSMutableArray *collection =  [self readFromFile:@"geofences"];
//  NSString *name= nil;
//  NSString *desc= nil;
//
//  //check values of the geojson key saved in the system
//  for (int i = 0; i < [collection count]; i++)
//  {
//    if([[collection[i] valueForKeyPath:@"key"] isEqualToString:[region valueForKeyPath:@"identifier"]]){
//      name=[collection[i] valueForKeyPath:@"name"];
//      desc=[collection[i] valueForKeyPath:@"desc"];
//      break;
//    }
//  }
//
//  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
//
//  UNMutableNotificationContent *content = [UNMutableNotificationContent new];
//  content.title = desc;
//  content.body = name;
//  content.sound = [UNNotificationSound defaultSound];
//
//  UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1
//  repeats:NO];
//
//  NSString *identifier = @"UYLLocalNotification";
//      UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
//                                                                            content:content trigger:trigger];
//      [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
//          if (error != nil) {
//              NSLog(@"Something went wrong: %@",error);
//          }
//      }];
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
