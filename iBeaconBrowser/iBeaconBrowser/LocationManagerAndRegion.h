#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LocationManagerAndRegion : NSObject

@property (nonatomic) CLLocationManager *locationManager;

@property (nonatomic) CLBeaconRegion *beaconRegion;

- (id)initWithLocationManager:(CLLocationManager*)locationManager beaconRegion:(CLBeaconRegion*)beaconRegion;

@end
