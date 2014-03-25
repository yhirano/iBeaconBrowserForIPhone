#import "BeaconAndDate.h"

@implementation BeaconAndDate

-(id)initWithBeacon:(CLBeacon*)beacon date:(NSDate*)date
{
    if (self = [super init]) {
        _beacon = beacon;
        _date = date;
    }
    return self;
}

@end
