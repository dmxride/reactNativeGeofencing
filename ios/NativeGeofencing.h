#import <React/RCTBridgeModule.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@interface NativeGeofencing : NSObject <CLLocationManagerDelegate, UIApplicationDelegate, RCTBridgeModule>

-(void)configPoiFromMe;

@end
