//
//  MasterViewController.m
//  BLEDemo
//
//  Created by Henry Serrano on 3/11/15.
//

#import "MasterViewController.h"

@interface MasterViewController ()

@end

@implementation MasterViewController

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //init CBCentralManager and its delegate
    manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    peripherals = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *scanButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(scanBLEDevices:)];
    self.navigationItem.rightBarButtonItem = scanButton;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)scanBLEDevices:(id)sender {
    //we will search for devices that contain the service that our device is programmed to have
    [manager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:BLEService]] options:nil];
    
    //we are going to trigger a NSTimer to stop scanning after 2 seconds
    [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(stopScan:) userInfo:nil repeats:NO];
}

- (void) stopScan:(id)sender{
    NSTimer *timer = (NSTimer *)sender;
    [timer invalidate];
    
    [manager stopScan];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [peripherals count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    //We set the cell title according to the peripheral's name
    CBPeripheral *peripheral = [peripherals objectAtIndex:indexPath.row];
    cell.textLabel.text = peripheral.name;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    CBPeripheral *peripheral = [peripherals objectAtIndex:indexPath.row];
    
    [manager connectPeripheral:peripheral options:nil];
}

#pragma mark CBCentralManagerDelegate

//Every time we successfully connect to a peripheral this function will be called
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connected to %@", peripheral.name);
    
    //we'll save the reference, we'll use it when writing data
    mainPeripheral = peripheral;
    
    //set delegate and discover all available services
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
}

//This function is invoked after a connected device is disconnected, we also remove reference of its delegate
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%@ disconnected...", peripheral.name);
    [peripheral setDelegate:nil];
}

//If any error ocurrs it will be notified in this function
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%@", error);
}

//Add any discovered peripheral to the peripherals array
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if(![peripherals containsObject:peripheral]){
        [peripherals addObject:peripheral];
    }
    
    [self.tableView reloadData];
}

//The manager detects the bluetooth state from the iOS device and notifies
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    char* managerStrings[] = {
        "Unknown", "Resetting", "Unsupported",
        "Unauthorized", "PoweredOff", "PoweredOn"
    };
    
    NSString *auxString = [NSString stringWithFormat:@"Manager State: %s", managerStrings[central.state]];
    NSLog(@"%@", auxString);
}

#pragma mark CBPeripheral Delegate

- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error{
    for (CBService *aService in aPeripheral.services){
        NSLog(@"Service found with UUID: %@", aService.UUID);
        
        /* Device Information Service */
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:@"180A"]]){
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
        
        /* GAP (Generic Access Profile) for Device Name */
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:CBUUIDGenericAccessProfileString]]){
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
        
        /* Bluno Service */
        if([aService.UUID isEqual:[CBUUID UUIDWithString:BLEService]]){
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
    }
}

- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    
    if([service.UUID isEqual:[CBUUID UUIDWithString:CBUUIDGenericAccessProfileString]] ){
        for(CBCharacteristic *aChar in service.characteristics){
            /* Read device name */
            if([aChar.UUID isEqual:[CBUUID UUIDWithString:CBUUIDDeviceNameString]]){
                [aPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found a Device Name Characteristic");
            }
        }
    }
    if([service.UUID isEqual:[CBUUID UUIDWithString:@"180A"]]){
        for(CBCharacteristic *aChar in service.characteristics){
            /* Read manufacturer name */
            if([aChar.UUID isEqual:[CBUUID UUIDWithString:@"2A29"]]){
                [aPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found a Device Manufacturer Name Characteristic");
            }else if([aChar.UUID isEqual:[CBUUID UUIDWithString:@"2A23"]]){
                [aPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found System ID");
            }
        }
    }
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:BLEService]]){
        for (CBCharacteristic *aChar in service.characteristics){
            /* Read DATA Characteristic */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLECharacteristic]]){
                //we'll save the reference, needed when writing data
                mainCharacteristic = aChar;
                [aPeripheral setNotifyValue:YES forCharacteristic:aChar];
                NSLog(@"Found Bluno DATA Characteristic");
            }
        }
    }
}

- (void) peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    /* Value for device Name received */
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CBUUIDDeviceNameString]]){
        NSString * deviceName = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"Device Name = %@", deviceName);
    }
    /* Value for manufacturer name received */
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A29"]]){
        NSString *manufacturer = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"Manufacturer Name = %@", manufacturer);
    }
    /* Value for manufacturer name received */
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A23"]]){
        NSString *systemID = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"System ID = %@", systemID);
    }
    /* Data received */
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BLECharacteristic]]){
        NSString *data = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"Received Data = %@", data);
        
        [_receiveText setText:data];
    }
}

#pragma mark UITextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)aTextField
{
    [aTextField resignFirstResponder];
    return YES;
}

#pragma mark IBAction

- (IBAction)sendData:(id)sender{
    //Read data to send, convert it to NSData
    NSString *auxText = [_dataField text];
    NSData *auxData = [auxText dataUsingEncoding:NSUTF8StringEncoding];
    
    //Send the data by using the stored CBCharacteristic and CBPeripheral references
    [mainPeripheral writeValue:auxData forCharacteristic:mainCharacteristic type:CBCharacteristicWriteWithoutResponse];
}

@end
