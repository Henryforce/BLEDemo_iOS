//
//  MasterViewController.h
//  BLEDemo
//
//  Created by Henry Serrano on 3/11/15.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define BLEService @"dfb0"
#define BLECharacteristic @"dfb1"

@interface MasterViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, CBCentralManagerDelegate, CBPeripheralDelegate, UITextFieldDelegate>{
    CBCentralManager *manager;
    CBPeripheral *mainPeripheral;
    CBCharacteristic *mainCharacteristic;
    
    NSMutableArray *peripherals;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *dataField;
@property (weak, nonatomic) IBOutlet UILabel *receiveText;

- (IBAction)sendData:(id)sender;

@end

