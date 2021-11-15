#import <React/RCTBridgeModule.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@interface UbiNativeGeofencing : NSObject <CLLocationManagerDelegate, UIApplicationDelegate, RCTBridgeModule>

@end
