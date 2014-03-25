#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface BeaconAndDate : NSObject

@property (nonatomic) CLBeacon *beacon;

@property (nonatomic) NSDate *date;

- (id)initWithBeacon:(CLBeacon*)beacon date:(NSDate*)date;

@end
