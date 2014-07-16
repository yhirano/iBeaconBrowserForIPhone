//
//  BeaconCell.h
//  iBeaconBrowser
//
//  Created by Yuichi Hirano on 7/16/14.
//
//

#import <UIKit/UIKit.h>

@interface BeaconCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *proxyimityUUIDLabel;

@property (weak, nonatomic) IBOutlet UILabel *majorLabel;

@property (weak, nonatomic) IBOutlet UILabel *minorLabel;

@property (weak, nonatomic) IBOutlet UILabel *proximityLabel;

@property (weak, nonatomic) IBOutlet UILabel *accuracyLabel;

@property (weak, nonatomic) IBOutlet UILabel *rssiLabel;

@end
