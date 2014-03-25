#import "LocationManagerAndRegion.h"

@implementation LocationManagerAndRegion

- (id)initWithLocationManager:(CLLocationManager*)locationManager beaconRegion:(CLBeaconRegion*)beaconRegion
{
    if (self = [super init]) {
        _locationManager = locationManager;
        _beaconRegion = beaconRegion;
    }
    return self;
}

@end
