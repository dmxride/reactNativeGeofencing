#import <Foundation/Foundation.h>
#import "UbiNativeGeofencing.h"
#import "GeofencingModuleDelegate.h"

#import <CoreLocation/CoreLocation.h>
#import <UserNotifications/UserNotifications.h>
#import <React/RCTLog.h>

@implementation UbiNativeGeofencing

RCT_EXPORT_METHOD(startMonitoring: (NSDictionary *) channelOptions
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  @try
  {
    // You need to authorize Location Services and NotificationServices first of all
    BOOL isUserAuthorizedForThisModule = [GeofencingModuleDelegate authorizeUserForThisModule];

    if(isUserAuthorizedForThisModule){
      NSMutableArray *entriesToSave = [NSMutableArray array];
      NSMutableDictionary *map = [[NSMutableDictionary alloc] init];

      map[@"channelId"] = [channelOptions valueForKeyPath:@"channelId"];
      map[@"channelName"] = [channelOptions valueForKeyPath:@"channelName"];
      map[@"channelDescription"] = [channelOptions valueForKeyPath:@"channelDescription"];

      //Auto consume pois
      if([channelOptions valueForKeyPath:@"watchSelfLocation"] != nil && [channelOptions valueForKeyPath:@"poiURL"] != nil  && [channelOptions valueForKeyPath:@"dataStructure"] != nil){
        map[@"watchSelfLocation"] = [channelOptions valueForKeyPath:@"watchSelfLocation"];
        map[@"poiURL"] = [channelOptions valueForKeyPath:@"poiURL"];
        map[@"dataStructure"] = [channelOptions valueForKeyPath:@"dataStructure"];

        if([channelOptions valueForKeyPath:@"fetchRadius"] != nil){
          map[@"fetchRadius"] = [channelOptions valueForKeyPath:@"fetchRadius"];
        }
      }

      if([[channelOptions valueForKeyPath:@"stopNotification"]valueForKeyPath:@"title"] != nil){
        map[@"stopNotTitle"] = [[channelOptions valueForKeyPath:@"stopNotification"]valueForKeyPath:@"title"];
      }

      if([[channelOptions valueForKeyPath:@"stopNotification"]valueForKeyPath:@"description"] != nil){
        map[@"stopNotMessage"] = [[channelOptions valueForKeyPath:@"stopNotification"]valueForKeyPath:@"description"];
      }

      [entriesToSave addObject:map];
      [GeofencingModuleDelegate writeToFile:entriesToSave withName:@"channelOptions"];

      [[GeofencingModuleDelegate sharedManager].locationManager startUpdatingLocation];
      //if watch self location start POI setup from current location
      if(map[@"watchSelfLocation"]){
        [self configPoiFromMe];
      }

      if([[channelOptions valueForKeyPath:@"startNotification"]valueForKeyPath:@"description"] != nil || [[channelOptions valueForKeyPath:@"startNotification"]valueForKeyPath:@"title"] != nil){

        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1
                                                                                                        repeats:NO];
        NSString *identifier = @"UYLLocalNotification";

        if([[channelOptions valueForKeyPath:@"startNotification"]valueForKeyPath:@"title"] != nil){
          content.title = [[channelOptions valueForKeyPath:@"startNotification"]valueForKeyPath:@"title"];
        }

        if([[channelOptions valueForKeyPath:@"startNotification"]valueForKeyPath:@"description"] != nil){
          content.body = [[channelOptions valueForKeyPath:@"startNotification"]valueForKeyPath:@"description"];
        }

        if([[channelOptions valueForKeyPath:@"startNotification"]valueForKeyPath:@"deepLink"] != nil){
          content.userInfo = @{@"deepLink": [[channelOptions valueForKeyPath:@"startNotification"]valueForKeyPath:@"deepLink"]};

        }

        content.sound = [UNNotificationSound defaultSound];


        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                              content:content trigger:trigger];
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
          if (error != nil) {
            NSLog(@"Something went wrong: %@",error);
          }
        }];
      }



      NSLog(@"Geofencing = %@", @"Started Geofencing Receiver, waiting for POI");
      resolve(@"Started Geofencing Receiver, waiting for POI");
    }else{
      NSError *error;
      reject(@"No Authorization", @"An Error has ocurred", error);
    }
  }
  @catch (NSException *exception){
    NSError *error;
    reject(@"No geofences", @"An Error has ocurred", error);
    NSLog(@"%@", exception.reason);
  }
}

RCT_EXPORT_METHOD(stopMonitoring: (RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  @try
  {
    [self clearPoi];
    resolve(@"Stopped Geofencing Receiaver");
    NSLog(@"Stopping%@", @"Stop monitoring");
  }
  @catch (NSException *exception){
    NSError *error;
    reject(@"Error stopping", @"An Error has ocurred", error);
    NSLog(@"Error stopping%@", @"Stop monitoring");
    NSLog(@"%@", exception.reason);
  }
}

RCT_EXPORT_METHOD(addPoi: (NSArray *)entries
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  @try
  {
    [self addPois: entries];

    NSLog(@"Geofencing = %@", @"Geofences added");
    resolve(@"Geofences added");
  }
  @catch (NSException *exception){
    NSError *error;
    reject(@"Adding Geofences", @"An Error has ocurred", error);
    NSLog(@"Error geofences: %@", exception.reason);
  }
}

RCT_EXPORT_METHOD(removeGeofences)
{
  [self clearPoi];
}

- (void)clearPoi{
  for(CLCircularRegion *region in [GeofencingModuleDelegate sharedManager].locationManager.monitoredRegions) {
    [[GeofencingModuleDelegate sharedManager].locationManager stopMonitoringForRegion:region];
  }
  [[GeofencingModuleDelegate sharedManager].locationManager stopUpdatingLocation];
}

- (void)monitorRegionAtLocation:(CLLocationCoordinate2D *)center withId:(NSString *)identifier withRadius:(long)radius
{
  bool isMonitorigAvailable = [CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]];
  NSLog(@"Adding new POI monitoring = %@", isMonitorigAvailable ? @"YES" : @"NO");

  // Make sure the devices supports region monitoring.
  if (isMonitorigAvailable) {
    // Register the region.
    CLRegion *region = [[CLCircularRegion alloc] initWithCenter:*center radius:radius identifier:identifier];
    region.notifyOnEntry = true;
//    region.notifyOnExit = true;

    [[GeofencingModuleDelegate sharedManager].locationManager startMonitoringForRegion:region];
  }
}

-(void)addPois: (NSArray *)entries{
    [self clearPoi];

    RCTLog(@"%@%lu", @"Total of geofences:" ,(unsigned long)[entries count]);

    NSRange range;
    range.location = 0;
    if([entries count] > 19){
      range.length = 19;
    }else{
      range.length = [entries count];
    }

    entries = [entries subarrayWithRange:range];
    RCTLog(@"%@%@", @"Total of entries:" ,entries);

    //add self location as a geoFence
    CLLocation *location = [[GeofencingModuleDelegate sharedManager].locationManager location];
    CLLocationCoordinate2D coordinate = [location coordinate];
    [self monitorRegionAtLocation:&coordinate withId:@"myCurrenLocation" withRadius:100];
    RCTLog(@"%@%@", @"Added entry:" , @"myCurrenLocation");

    [GeofencingModuleDelegate writeToFile:[[NSMutableArray alloc]initWithArray:entries] withName:@"geofenceEntries"];

    for (NSDictionary *entry in entries) {
      NSString *key=[entry valueForKeyPath:@"key"];
      NSString *latString=[entry valueForKeyPath:@"latitude"];
      NSString *lngString=[entry valueForKeyPath:@"longitude"];
      NSString *radiusString=[entry valueForKeyPath:@"radius"];

      double latDouble = [latString doubleValue];
      double lngDouble = [lngString doubleValue];
      long radius = [radiusString longLongValue];

      CLLocationCoordinate2D location = CLLocationCoordinate2DMake(latDouble, lngDouble);

      [self monitorRegionAtLocation:&location withId:key withRadius:radius];
      RCTLog(@"%@%@", @"Added entry:" , entry);
      NSLog(@"ADDING POI = %@", entry);

    }
    NSLog(@"ADDING POI = %@", @"ADDED ALL NEW POIS");

}

-(void)configPoiFromMe{
  [[GeofencingModuleDelegate sharedManager].locationManager startUpdatingLocation];

  CLLocation *location = [[GeofencingModuleDelegate sharedManager].locationManager location];

  CLLocationCoordinate2D coordinate = [location coordinate];
  NSLog(@"ADDING POI LATITUDE= %f", coordinate.latitude);

  NSMutableArray *collection =  [GeofencingModuleDelegate readFromFile:@"channelOptions"];

  //value key adds arrays in one array
  NSString *poiURL= [[collection valueForKeyPath:@"poiURL"] lastObject];

  NSLog(@"ADDING POI = %@", @"START");

  if ([poiURL rangeOfString:@":radius"].location != NSNotFound) {
    if([[collection valueForKeyPath:@"fetchRadius"] lastObject] != nil){
      poiURL = [poiURL stringByReplacingOccurrencesOfString:@":radius"
                                                 withString:[NSString stringWithFormat:@"%@", [[collection valueForKeyPath:@"fetchRadius"] lastObject]]];
    }else{
      poiURL = [poiURL stringByReplacingOccurrencesOfString:@":radius"
                                                 withString:@"0.5"];
    }
  }

  if ([poiURL rangeOfString:@":latitude"].location != NSNotFound) {
    poiURL = [poiURL stringByReplacingOccurrencesOfString:@":latitude"
                                               withString:[NSString stringWithFormat:@"%.20f", coordinate.latitude]];
  }

  if ([poiURL rangeOfString:@":longitude"].location != NSNotFound) {
    poiURL = [poiURL stringByReplacingOccurrencesOfString:@":longitude"
                                               withString:[NSString stringWithFormat:@"%.20f", coordinate.longitude]];
  }

  NSLog(@"ADDING POI = %@", poiURL);

  [GeofencingModuleDelegate getDataFrom:poiURL withCompletionHandler:^(NSMutableArray* data){
    @try {
      NSLog(@"ADDING POI = %@", @"REQUEST");
      NSLog(@"ADDING POI DATA = %@", data);
      RCTLog(@"%@%@", @"Request url:" ,poiURL);
      RCTLog(@"%@%@", @"Request:" ,data);

      // valueForKey has a special behavior. Applied to an array it returns always an array of all values for the given key.
      NSArray *dataStructure= [[collection valueForKeyPath:@"dataStructure"] lastObject];

      NSMutableArray *entries = [NSMutableArray array];

      int countNotId = 0;

      for(NSArray *structure in dataStructure) {
        NSMutableArray *poiItems = [NSMutableArray array];

        if([structure valueForKeyPath:@"poi"] != nil){
          if ([structure valueForKeyPath:@"main"] != nil){
            for(NSString *mainPath in [structure valueForKeyPath:@"main"]) {
              NSLog(@"DEBUG MAIN PATH = %@",mainPath);
              NSMutableArray *poiItemsCopy = [NSMutableArray array];

              if([poiItems count]>0){

                for(NSMutableArray *poiItem in poiItems) {
                  bool isArray = false;
                  @try{
                    isArray = [poiItem valueForKeyPath:mainPath][0] != nil;
                  }
                  @catch(NSException *exception) {
                    NSLog(@"%@", exception.reason);
                  }

                  if(isArray){
                    NSLog(@"DEBUG CLASS = %@", @"ARRAY");
                    for(NSMutableArray *structureItem in [poiItem valueForKeyPath:mainPath]) {
                      [poiItemsCopy addObject:structureItem];
                    }
                  } else {
                    NSLog(@"DEBUG CLASS = %@", @"OBJECT");
                    [poiItemsCopy addObject:[poiItem valueForKeyPath:mainPath]];
                  }
                }

                poiItems = poiItemsCopy;
              }else{
                bool isArray = false;
                @try{
                  isArray = [data valueForKeyPath:mainPath][0] != nil;
                }
                @catch(NSException *exception) {
                  NSLog(@"%@", exception.reason);
                }

                if(isArray){
                  for(NSMutableArray *structureItem in [data valueForKeyPath:mainPath]) {
                    [poiItemsCopy addObject:structureItem];
                  }
                } else {
                  [poiItemsCopy addObject:data];
                }

                poiItems = poiItemsCopy;
              }
            }
          }
        }

        for(NSMutableArray *poiItem in poiItems) {
          NSMutableDictionary *map = [[NSMutableDictionary alloc] init];
          NSLog(@"MyGeo = %@", poiItem);

          map[@"notificationId"] = [@(countNotId) stringValue];
          map[@"key"] = [NSString stringWithFormat:@"%@/%@", @"POI_", [@(countNotId) stringValue]];

          if ([[structure valueForKeyPath:@"poi"] valueForKeyPath:@"poiId"] != nil){
            NSMutableDictionary *poiMap = [[structure valueForKeyPath:@"poi"] valueForKeyPath:@"poiId"];
            map[@"poiId"] = [self getValueFromStructure:poiItem  withData: poiMap];
          }
          if ([[structure valueForKeyPath:@"poi"] valueForKeyPath:@"key"] != nil){
            NSMutableDictionary *poiMap = [[structure valueForKeyPath:@"poi"] valueForKeyPath:@"key"];
            map[@"key"] = [self getValueFromStructure:poiItem  withData: poiMap];
          }
          if ([[structure valueForKeyPath:@"poi"] valueForKeyPath:@"latitude"] != nil){
            NSMutableDictionary *poiMap = [[structure valueForKeyPath:@"poi"] valueForKeyPath:@"latitude"];
            map[@"latitude"] = [self getValueFromStructure:poiItem  withData: poiMap];
          }
          if ([[structure valueForKeyPath:@"poi"] valueForKeyPath:@"longitude"] != nil){
            NSMutableDictionary *poiMap = [[structure valueForKeyPath:@"poi"] valueForKeyPath:@"longitude"];
            map[@"longitude"] = [self getValueFromStructure:poiItem  withData: poiMap];
          }
          if ([[structure valueForKeyPath:@"poi"] valueForKeyPath:@"radius"] != nil){
            NSMutableDictionary *poiMap = [[structure valueForKeyPath:@"poi"] valueForKeyPath:@"radius"];
            map[@"radius"] = [self getValueFromStructure:poiItem  withData: poiMap];
          }
          if ([[structure valueForKeyPath:@"poi"] valueForKeyPath:@"largeIcon"] != nil){
            NSMutableDictionary *poiMap = [[structure valueForKeyPath:@"poi"] valueForKeyPath:@"largeIcon"];
            map[@"largeIcon"] = [self getValueFromStructure:poiItem  withData: poiMap];
          }
          if ([[structure valueForKeyPath:@"poi"] valueForKeyPath:@"deepLink"] != nil){
            NSMutableDictionary *poiMap = [[structure valueForKeyPath:@"poi"] valueForKeyPath:@"deepLink"];
            map[@"deepLink"] = [self getValueFromStructure:poiItem  withData: poiMap];
          }
          if ([[structure valueForKeyPath:@"poi"] valueForKeyPath:@"enterTitle"] != nil){
            NSMutableDictionary *poiMap = [[structure valueForKeyPath:@"poi"] valueForKeyPath:@"enterTitle"];
            map[@"enterTitle"] = [self getValueFromStructure:poiItem  withData: poiMap];
          }
          if ([[structure valueForKeyPath:@"poi"] valueForKeyPath:@"enterMessage"] != nil){
            NSMutableDictionary *poiMap = [[structure valueForKeyPath:@"poi"] valueForKeyPath:@"enterMessage"];
            map[@"enterMessage"] = [self getValueFromStructure:poiItem  withData: poiMap];
          }
          if ([[structure valueForKeyPath:@"poi"] valueForKeyPath:@"exitTitle"] != nil){
            NSMutableDictionary *poiMap = [[structure valueForKeyPath:@"poi"] valueForKeyPath:@"exitTitle"];
            BOOL isFiltered = true;
            if ([[[structure valueForKeyPath:@"poi"] valueForKeyPath:@"exitTitle"] valueForKeyPath:@"filter"] != nil) {
              isFiltered = [self isFilteredValue:poiItem withData: [[structure valueForKeyPath:@"poi"] valueForKeyPath:@"exitTitle"]];
            }

            if(isFiltered){
              map[@"exitTitle"] = [self getValueFromStructure:poiItem  withData: poiMap];
            }
          }
          if ([[structure valueForKeyPath:@"poi"] valueForKeyPath:@"exitMessage"] != nil){
            NSMutableDictionary *poiMap = [[structure valueForKeyPath:@"poi"] valueForKeyPath:@"exitMessage"];
            BOOL isFiltered = true;
            if ([[[structure valueForKeyPath:@"poi"] valueForKeyPath:@"exitMessage"] valueForKeyPath:@"filter"] != nil) {
              isFiltered = [self isFilteredValue:poiItem withData: [[structure valueForKeyPath:@"poi"] valueForKeyPath:@"exitMessage"]];
            }

            if(isFiltered){
              map[@"exitMessage"] = [self getValueFromStructure:poiItem  withData: poiMap];
            }
          }

          NSLog(@"ADDING POI = %@", @"FINISHED");

          [entries addObject:map];

          countNotId += 1;
        }
      };

      [self addPois:entries];
    } @catch (NSException *exception) {
      NSMutableArray *entries = [NSMutableArray array];
      [self addPois:entries];
      NSLog(@"%@", exception.reason);
    }
  } withError:^(NSMutableArray* data){
    NSMutableArray *entries = [NSMutableArray array];
    [self addPois:entries];
  }];
}

-(BOOL) isFilteredValue: (NSArray *)structure withData: (NSMutableDictionary *)data{
  NSLog(@"MyFilter DATA = %@", [data valueForKeyPath:@"filter"]);
  if([data valueForKeyPath:@"filter"]!=nil){
    NSLog(@"MyFilter DATA = %@", [[data valueForKeyPath:@"filter"] objectAtIndex:0]);

    if([structure valueForKeyPath:[[data valueForKeyPath:@"filter"] objectAtIndex:0]] != nil){
      NSString *structureValue = [structure valueForKeyPath:[[data valueForKeyPath:@"filter"] objectAtIndex:0]];

      structureValue = structureValue == (id)[NSNull null] ? @"null": structureValue;

      NSString *objectValue = [[data valueForKeyPath:@"filter"] objectAtIndex:1];


      return [structureValue isEqual:objectValue];
    }else{
      return false;
    }
  }

  return false;
}

-(NSString *) getValueFromStructure: (NSArray *)structure withData: (NSMutableDictionary *)data{
  NSString *returnValue;

  NSLog(@"MyGeo DATA = %@", [data valueForKeyPath:@"type"]);

  if([data valueForKeyPath:@"type"]!=nil){
    if([[data valueForKeyPath:@"type"]  isEqual: @"path"]){
      if([data valueForKeyPath:@"data"]!=nil){
        NSArray *filteredDataStructure = structure;

        for(NSString *path in [data valueForKeyPath:@"data"]) {
          @try{
            NSLog(@"DEBUG LOG NUMBER = %@", [path  isKindOfClass:[NSNumber class]] ? @"YES" : @"NO");

            if([path isKindOfClass:[NSNumber class]]){
              if([[filteredDataStructure  objectAtIndex:[path integerValue]] isKindOfClass:[NSArray class]] || [[filteredDataStructure objectAtIndex:[path integerValue]] isKindOfClass:[NSDictionary class]] ) {
                filteredDataStructure = [filteredDataStructure objectAtIndex:[path integerValue]];
              }else{
                returnValue = [filteredDataStructure objectAtIndex:[path integerValue]];
                break;
              }
            }else{
              if([[filteredDataStructure valueForKeyPath:path] isKindOfClass:[NSArray class]] || [[filteredDataStructure valueForKeyPath:path] isKindOfClass:[NSDictionary class]] ) {
                filteredDataStructure = [filteredDataStructure valueForKeyPath:path];
              }else{
                returnValue = [filteredDataStructure valueForKeyPath:path];
                break;
              }
            }

          }
          @catch(NSException *exception){
            NSLog(@"%@", exception.reason);
          }
        }
      }
    }

    if([[data valueForKeyPath:@"type"]  isEqual: @"number"] || [[data valueForKeyPath:@"type"]  isEqual: @"string"]){
      if([data valueForKeyPath:@"data"]!=nil){
        returnValue = [data valueForKeyPath:@"data"];
      }
    }

    if([[data valueForKeyPath:@"type"]  isEqual: @"replace"]){
      if([data valueForKeyPath:@"data"]!=nil && [data valueForKeyPath:@"replace"]!=nil){
        NSString *rawString = [data valueForKeyPath:@"data"];

        for(NSString *replaceObject in [data valueForKeyPath:@"replace"]) {
          NSMutableString *str = [[NSMutableString alloc] initWithString:replaceObject];
          [str insertString:@":" atIndex:0];

          if ([rawString rangeOfString:str].location != NSNotFound) {

            NSArray *value = [[data valueForKeyPath:@"replace"] objectForKey:replaceObject];
            NSArray *filteredDataStructure = structure;

            for(NSString *valueKeys in value) {

              if([valueKeys isKindOfClass:[NSNumber class]]){
                if([[filteredDataStructure  objectAtIndex:[valueKeys integerValue]] isKindOfClass:[NSArray class]] || [[filteredDataStructure  objectAtIndex:[valueKeys integerValue]] isKindOfClass:[NSDictionary class]] ) {
                  filteredDataStructure = [filteredDataStructure  objectAtIndex:[valueKeys integerValue]];
                }else{
                  //replace string
                  rawString = [rawString stringByReplacingOccurrencesOfString:str
                                                                   withString:[filteredDataStructure  objectAtIndex:[valueKeys integerValue]]];
                }
              }else{
                if([[filteredDataStructure valueForKeyPath:valueKeys] isKindOfClass:[NSArray class]] || [[filteredDataStructure valueForKeyPath:valueKeys] isKindOfClass:[NSDictionary class]] ) {
                  filteredDataStructure = [filteredDataStructure valueForKeyPath:valueKeys];
                }else{
                  //replace string
                  rawString = [rawString stringByReplacingOccurrencesOfString:str
                                                                   withString:[filteredDataStructure valueForKeyPath:valueKeys]];
                }
              }

            }
          }
        }
        returnValue = rawString;
      }
    }

  }

  NSLog(@"MyGeo VALUE = %@", returnValue);

  return returnValue;
}

// To export a module named UbiNativeGeofencing
RCT_EXPORT_MODULE(UbiNativeGeofencing);

@end
