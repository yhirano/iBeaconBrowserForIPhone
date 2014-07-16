/*
 * Copyright (c) 2014 Yuichi Hirano
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import <CoreLocation/CoreLocation.h>
#import "iBeasonSampleConfig.h"
#import "BeaconBrowserViewController.h"
#import "BeaconCell.h"
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

    // Create CLLocationManager and CLBeaconRegion and add to locationManagerAndBeacons_ list.
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
    
    // Start monitoring.
    for (LocationManagerAndRegion *locationManagerAndRegion in locationManagerAndBeacons_) {
        [locationManagerAndRegion.locationManager startMonitoringForRegion:locationManagerAndRegion.beaconRegion];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    // Stop monitoring.
    for (LocationManagerAndRegion *locationManagerAndRegion in locationManagerAndBeacons_) {
        [locationManagerAndRegion.locationManager stopMonitoringForRegion:locationManagerAndRegion.beaconRegion];
        locationManagerAndRegion.locationManager.delegate = nil;
    }
    
    [locationManagerAndBeacons_ removeAllObjects];

}

#pragma mark - Private methods

// Remove beacon info from beacons_ list.
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
            // モニタリング監視時に、現在自分が、iBeacon監視でどういう状態にいるかを知らせてくれるように要求する。
            // これを呼ばないと locationManager: didDetermineState: forRegion: が呼ばれないので注意。
            [locationManagerAndRegion.locationManager requestStateForRegion:region];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    switch (state) {
        case CLRegionStateInside:
            // リージョン内にいる場合は、通知の受け取りを開始する
            if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
                CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
                [manager startRangingBeaconsInRegion:beaconRegion];
            }
            break;
        case CLRegionStateOutside:
        case CLRegionStateUnknown:
        default:
            // リージョン内にいる場合は、通知の受け取りを停止する
            if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
                CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;;
                [manager stopRangingBeaconsInRegion:beaconRegion];
            }
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    // リージョンの境界を越えて入った時にも同じく通知を開始する
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [manager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    // リージョンの境界を越えて出ていった時にも同じく通知を停止する
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
    // ビーコンから通知を受けた場合は、beacons_リストに入っている同じビーコンの情報を一旦削除する
    [self removeBeaconFromBeacons:beacons];

    // そしてそのビーコンの情報を追加する（ビーコン情報の削除と追加で、beacons_リストの更新）
    NSDate *nowDate = [NSDate date];
    for (CLBeacon *beacon in beacons) {
        BeaconAndDate *beaconAndDate = [[BeaconAndDate alloc] initWithBeacon:beacon date:nowDate];

        [beacons_ addObject:beaconAndDate];
    }
    
    // beacons_リストを日付で更新
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
    BeaconCell *cell = (BeaconCell*)[tableView dequeueReusableCellWithIdentifier:@"BeaconCell"];
    
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
    
    cell.proxyimityUUIDLabel.text = [beaconAndDate.beacon.proximityUUID UUIDString];
    cell.majorLabel.text = [NSString stringWithFormat:@"Major: %@", [beaconAndDate.beacon.major stringValue]];
    cell.minorLabel.text = [NSString stringWithFormat:@"Minor: %@", [beaconAndDate.beacon.minor stringValue]];
    cell.proximityLabel.text = [NSString stringWithFormat:@"Proximity: %@", proximity];
    cell.accuracyLabel.text = [NSString stringWithFormat:@"Accuracy: %.2fm", beaconAndDate.beacon.accuracy];
    cell.rssiLabel.text = [NSString stringWithFormat:@"Accuracy: %lddBm", beaconAndDate.beacon.rssi];

    return cell;
}

@end
