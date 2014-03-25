#import <CoreLocation/CoreLocation.h>
#import "iBeasonSampleConfig.h"
#import "BeaconBrowserViewController.h"
#import "LocationManagerAndRegion.h"
#import "BeaconAndDate.h"

@interface BeaconBrowserViewController () <CLLocationManagerDelegate>

@end

@implementation BeaconBrowserViewController
{
    NSMutableArray *locationManagerAndBeacons_;
    NSMutableArray *beacons_;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"iBeacon browser";

    if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        locationManagerAndBeacons_ = [[NSMutableArray alloc] initWithCapacity:[BLE_UUIDS count]];
        for (NSString *uuidString in BLE_UUIDS) {
            CLLocationManager *locationManager = [[CLLocationManager alloc] init];
            locationManager.delegate = self;

            NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
            CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:[uuid UUIDString]];
            
            if (locationManager && region) {
                LocationManagerAndRegion *locationManagerAndRegion = [[LocationManagerAndRegion alloc] initWithLocationManager:locationManager beaconRegion:region];
                [locationManagerAndBeacons_ addObject:locationManagerAndRegion];
            }
        }
        
        beacons_ = [[NSMutableArray alloc] init];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    for (LocationManagerAndRegion *locationManagerAndRegion in locationManagerAndBeacons_) {
        [locationManagerAndRegion.locationManager startMonitoringForRegion:locationManagerAndRegion.beaconRegion];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    for (LocationManagerAndRegion *locationManagerAndRegion in locationManagerAndBeacons_) {
        [locationManagerAndRegion.locationManager stopMonitoringForRegion:locationManagerAndRegion.beaconRegion];
        locationManagerAndRegion.locationManager.delegate = nil;
    }
    
    [locationManagerAndBeacons_ removeAllObjects];

}

#pragma mark - Private methods

- (void)removeBeaconFromBeacons:(NSArray*)beacons
{
    NSMutableArray *removeTargets = [NSMutableArray array];

    for (CLBeacon *beacon in beacons) {
        for (BeaconAndDate *removeBeaconAndDate in beacons_) {
            if ([beacon.proximityUUID isEqual:removeBeaconAndDate.beacon.proximityUUID] &&
                [beacon.major isEqual:removeBeaconAndDate.beacon.major] &&
                [beacon.minor isEqual:removeBeaconAndDate.beacon.minor]) {
                [removeTargets addObject:removeBeaconAndDate];
            }
        }
    }
    [beacons_ removeObjectsInArray:removeTargets];
}

#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    for (LocationManagerAndRegion *locationManagerAndRegion in locationManagerAndBeacons_) {
        if (locationManagerAndRegion.locationManager == manager) {
            [locationManagerAndRegion.locationManager requestStateForRegion:region];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    switch (state) {
        case CLRegionStateInside:
            if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
                CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
                [manager startRangingBeaconsInRegion:beaconRegion];
            }
            break;
        case CLRegionStateOutside:
        case CLRegionStateUnknown:
        default:
            if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
                CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;;
                [manager stopRangingBeaconsInRegion:beaconRegion];
            }
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [manager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [manager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Fail Monitoring" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
    [alertView show];
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    [self removeBeaconFromBeacons:beacons];

    NSDate *nowDate = [NSDate date];
    for (CLBeacon *beacon in beacons) {
        BeaconAndDate *beaconAndDate = [[BeaconAndDate alloc] initWithBeacon:beacon date:nowDate];

        [beacons_ addObject:beaconAndDate];
    }
    
    NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    [beacons_ sortUsingDescriptors:[NSArray arrayWithObject:sortByDate]];
    
    [self.tableView reloadData];
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSString *message = [NSString stringWithFormat:@"%@\n\n%@", [error localizedDescription],[region.proximityUUID UUIDString]];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Fail beacon for region" message:message delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
    [alertView show];
}

#pragma mark - Tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [beacons_ count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }

    BeaconAndDate *beaconAndDate = [beacons_ objectAtIndex:indexPath.row];
    NSString *proximity;
    
    switch (beaconAndDate.beacon.proximity) {
        case CLProximityImmediate:
            proximity = @"Immediate";
            break;
        case CLProximityNear:
            proximity = @"Near";
            break;
        case CLProximityFar:
            proximity = @"Far";
            break;
        case CLProximityUnknown:
            proximity = @"Unknown";
            break;
        default:
            break;
    }
    
    cell.textLabel.text = [beaconAndDate.beacon.proximityUUID UUIDString];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Major: %@, Minor: %@, Prox:%@, Ac: %.2fm",
                                 [beaconAndDate.beacon.major stringValue], [beaconAndDate.beacon.minor stringValue], proximity, beaconAndDate.beacon.accuracy];

    return cell;
}

@end
