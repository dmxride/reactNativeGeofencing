//
//  Utils.m
//  app_geoparque_vc
//
//  Created by Carlos Silva on 21/03/2021.
//  Copyright © 2021 Facebook. All rights reserved.
//

#import "utils.h"
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@implementation Utils

@synthesize locationManager;

static CLLocationManager *locationManager = nil;

+ (id)sharedManager {
    static Utils *sharedMyManager = nil;
    @synchronized(self) {
        if (sharedMyManager == nil)
            sharedMyManager = [[self alloc] init];
    }
    return sharedMyManager;
}

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
    locationManager= [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    [locationManager requestAlwaysAuthorization];
  } else {
    return false;
  }
  
  __block bool authorizedNotifications = true;
  
  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
  UNAuthorizationOptions options = UNAuthorizationOptionBadge + UNAuthorizationOptionAlert + UNAuthorizationOptionSound;
  
  [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
    if (settings.authorizationStatus != UNAuthorizationStatusAuthorized) {
      // Notifications not allowed
      [center requestAuthorizationWithOptions:options
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
