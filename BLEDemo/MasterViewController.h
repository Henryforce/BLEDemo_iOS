//
//  MasterViewController.h
//  BLEDemo
//
//  Created by Henry Serrano on 3/11/15.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController<CBCentralManagerDelegate>{
    CBCentralManager *manager;
    CBPeripheral *mainPeripheral;
    
    NSMutableArray *peripherals;
}

@property (strong, nonatomic) DetailViewController *detailViewController;


@end

