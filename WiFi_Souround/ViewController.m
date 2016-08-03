//
//  ViewController.m
//  WiFi_Souround
//
//  Created by Non on 16/7/19.
//  Copyright © 2016年 NonMac. All rights reserved.
//

#import <NetworkExtension/NetworkExtension.h>
#import "ViewController.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

//定位
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
//基站

//wifi
#import "network.h"
#import <SystemConfiguration/CaptiveNetwork.h>

//蓝牙
#import <CoreBluetooth/CoreBluetooth.h>
//地磁3轴
#import <CoreMotion/CoreMotion.h>


#import "RecordListVC.h"

#import "NSNumber+Transform.h"

#define WRITETOFILETIMES @"WRITETOFILETIMES"

@interface NearbyPeripheralInfo : NSObject
@property (nonatomic,strong) CBPeripheral *peripheral;
@property (nonatomic,strong) NSDictionary *advertisementData;
@property (nonatomic,strong) NSNumber *RSSI;
@end

@implementation NearbyPeripheralInfo
@end

@interface ViewController ()<CBCentralManagerDelegate, MKMapViewDelegate>

//IBOutlet
@property (weak, nonatomic) IBOutlet UIButton *recordListBtn;
@property (weak, nonatomic) IBOutlet UIButton *startRecordBtn;
@property (weak, nonatomic) IBOutlet UIButton *recenterBtn;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *latitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *longitudeLabel;

//Location
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) CLLocationDegrees latitude, longitude, altitude;


//Motion
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, assign) double magneticX, magneticY, magneticZ;
@property (nonatomic, strong) NSOperationQueue *magenticQueue;

//wifi
@property (nonatomic, strong) NSString *wifiName;


//Bluetooth
@property (nonatomic,strong) NSMutableArray *bluetoothsArray;
@property (nonatomic,strong) CBCentralManager *centralManager;
@property (nonatomic,strong) CBPeripheral *selectedPeripheral;
@property (nonatomic,strong) NSTimer *scanTimer;


//Recorder
@property (nonatomic, strong) NSTimer *logoutTimer;
@property (nonatomic, strong) NSMutableString *totalLogString;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [[[UIAlertView alloc] initWithTitle:@"提醒"
//                                message:@"请确保开启了蓝牙、wifi、定位功能"
//                               delegate:nil
//                      cancelButtonTitle:@"ok"
//                      otherButtonTitles:nil] show];
    if (![[NSUserDefaults standardUserDefaults] objectForKey:WRITETOFILETIMES]) {
        [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:WRITETOFILETIMES];
        writeToFileTime = 0;
    } else {
        writeToFileTime = [[[NSUserDefaults standardUserDefaults] objectForKey:WRITETOFILETIMES] intValue];
    }
    [NSTimer scheduledTimerWithTimeInterval:1
                                     target:self
                                   selector:@selector(updateTimeLabel)
                                   userInfo:nil
                                    repeats:YES];
    
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    
    [self buildView];
    [self setUpLocation];
    [self setUpCellStation];
    [self setUpWifi];
    [self setUpBluetooth];
    [self setUpMagnetic];
    
    [self showWiFiSignalStrength];
    [self testMethod];
}

- (void)showWiFiSignalStrength {
    [[[UIAlertView alloc] initWithTitle:@"wifi信号强度"
                                message:[NSString stringWithFormat:@"%@", getSignalStrength()]
                               delegate:nil
                      cancelButtonTitle:@"ok"
                      otherButtonTitles:nil] show];
}

- (void)updateTimeLabel {
    NSDate *currentDate = [NSDate date];
    self.timeLabel.text = [NSString stringWithFormat:@"%ld\n%@", [NSNumber UIntegerFromDouble:[currentDate timeIntervalSince1970]], [self.dateFormatter stringFromDate:currentDate]];
}

- (void)buildView {
    self.startRecordBtn.backgroundColor = [UIColor lightGrayColor];
    self.startRecordBtn.layer.cornerRadius = 5;
    self.recordListBtn.backgroundColor = [UIColor lightGrayColor];
    self.recordListBtn.layer.cornerRadius = 5;
    self.recenterBtn.backgroundColor = [UIColor lightGrayColor];
    self.recenterBtn.layer.cornerRadius = 5;
}

- (void)setUpLocation {
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager  requestWhenInUseAuthorization];
}

- (void)setUpCellStation {
    return;
}

NSString* getSignalStrength()
{
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];

    CTCarrier *carrier = [info subscriberCellularProvider];
    NSString *mCarrier = [NSString stringWithFormat:@"%@",[carrier carrierName]];
    mCarrier = [NSString stringWithFormat:@"%@", [info performSelector:@selector(cellId)]];
    return mCarrier;

    void *libHandle = dlopen("/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony", RTLD_LAZY);
    int (*CTGetSignalStrength)();
    CTGetSignalStrength = dlsym(libHandle, "CTGetSignalStrength");
    if( CTGetSignalStrength == NULL) NSLog(@"Could not find CTGetSignalStrength");
    int result = CTGetSignalStrength();
    dlclose(libHandle);
    return [NSString stringWithFormat:@"%d", result];
    
//    char *methodName = "GetDidJustJoin";
//    void *libHandle = dlopen("/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony", RTLD_LAZY);
//    int (*CTGetSSID)();
//    CTGetSSID = dlsym(libHandle, methodName);
//    if( CTGetSSID == NULL) {
//        NSLog(@"Could not find %s", methodName);
//        return @"";
//    }
//    int result2 = CTGetSSID();
//    dlclose(libHandle);
//    return [NSString stringWithFormat:@"%d", result2];
}

- (void)testMethod {
    NSBundle *a = [NSBundle bundleWithPath:@"System/Library/PrivateFrameworks/AppleAccount.framework"];
    NSBundle *b = [NSBundle bundleWithPath:@"System/Library/PrivateFrameworks/ApplePushService.framework"];
    NSBundle *c = [NSBundle bundleWithPath:@"System/Library/PrivateFrameworks/CoreTelephony.framework"];
    if ([a load]) {
        if ([b load]) {
            [c load];
            NSLog(@"%s>>>>>>%d",__func__,__LINE__);
            Class aa = NSClassFromString(@"AADeviceInfo");
            Class bb = NSClassFromString(@"NEHotspotHelper");
            id BB = [[bb alloc] init];
            NSLog(@"%s>>>>>>%d>>>>>>%@",__func__,__LINE__, (NSString *)[aa performSelector:@selector(udid)]);
            NSLog(@"%s>>>>>>%d>>>>>>%@",__func__,__LINE__, [aa performSelector:@selector(productVersion)]);
            NSLog(@"%s>>>>>>%d>>>>>>%@",__func__,__LINE__, [aa performSelector:@selector(userAgentHeader)]);
            NSLog(@"%s>>>>>>%d>>>>>>%@",__func__,__LINE__, [aa performSelector:@selector(osVersion)]);
            NSLog(@"%s>>>>>>%d>>>>>>%@",__func__,__LINE__, [aa performSelector:@selector(appleIDClientIdentifier)]);
            NSLog(@"%s>>>>>>%d>>>>>>%@",__func__,__LINE__, [aa performSelector:@selector(clientInfoHeader)]);
            NSLog(@"%s>>>>>>%d>>>>>>%@",__func__,__LINE__, [aa performSelector:@selector(serialNumber)]);
            NSLog(@"%s>>>>>>%d>>>>>>%@",__func__,__LINE__, [aa performSelector:@selector(infoDictionary)]);
            NSLog(@"%s>>>>>>%d>>>>>>%@",__func__,__LINE__, [BB performSelector:@selector(SSID)]);
        }
    }
    return;
    
//    NSString *f = kNEHotspotHelperOptionDisplayName;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"WI-FI TAG", @"kNEHotspotHelperOptionDisplayName", nil];
    dispatch_queue_t queue = dispatch_queue_create("com.myapp.ex", 0);
    
    BOOL returnType = [NEHotspotHelper registerWithOptions:options queue:queue handler: ^(NEHotspotHelperCommand * cmd) {
        
        if(cmd.commandType == kNEHotspotHelperCommandTypeEvaluate ||
           cmd.commandType == kNEHotspotHelperCommandTypeFilterScanList)
        {
            for (NEHotspotNetwork* network  in cmd.networkList)
            {
                NSLog(@"%@", network.SSID);
                if ([network.SSID isEqualToString:@"WX_moses"])
                {
                    [network setConfidence:kNEHotspotHelperConfidenceHigh];
                    [network setPassword:@"mypassword"];
                    NSLog(@"Confidence set to high for ssid: %@ (%@)\n\n", network.SSID, network.BSSID);
                    //                    NSMutableArray *hotspotList = [NSMutableArray new];
                    //                    [hotspotList addObject:network];
                    
                    // This is required
                    NEHotspotHelperResponse *response = [cmd createResponse:kNEHotspotHelperResultSuccess];
                    [response setNetwork:network];
                    [response deliver];
                }
            }
        }
    }];
}

- (void)setUpWifi {
    [self fetchSSIDInfo];
    return;
}

- (void)setUpBluetooth {
    [self initWithCBCentralManager];
    [self startScanPeripherals];
}

- (void)startScanPeripherals
{
    if (!_scanTimer) {
        _scanTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(scanForPeripherals) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_scanTimer forMode:NSDefaultRunLoopMode];
    }
    if (_scanTimer && !_scanTimer.valid) {
        [_scanTimer fire];
    }
}

- (void)setUpMagnetic {
    self.magenticQueue = [[NSOperationQueue alloc] init];
    self.motionManager = [[CMMotionManager alloc] init];
    [self.motionManager startMagnetometerUpdatesToQueue:self.magenticQueue
                                            withHandler:^(CMMagnetometerData * _Nullable magnetometerData, NSError * _Nullable error) {
                                                self.magneticX = magnetometerData.magneticField.x;
                                                self.magneticY = magnetometerData.magneticField.y;
                                                self.magneticZ = magnetometerData.magneticField.z;
                                            }];
}

#pragma mark - IBActions
- (IBAction)startRecordBtnPressed {
    self.logoutTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                        target:self
                                                      selector:@selector(logout)
                                                      userInfo:nil
                                                       repeats:YES];
    self.startRecordBtn.enabled = NO;
    self.totalLogString = [[NSMutableString alloc] init];
    [self.bluetoothsArray removeAllObjects];
}

- (IBAction)recordListBtnPressed {
    RecordListVC *RLVC = [self.storyboard instantiateViewControllerWithIdentifier:@"RecordListVC"];
    RLVC.sourceSum = [[NSUserDefaults standardUserDefaults] objectForKey:WRITETOFILETIMES];
    [self.navigationController pushViewController:RLVC animated:YES];
}

- (IBAction)recenterBtnPressed {
    [self recenterMapView];
}

#pragma mark - CBCentralManager
- (void)initWithCBCentralManager {
    if (!_centralManager) {
        dispatch_queue_t queue = dispatch_get_main_queue();
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:queue options:@{CBCentralManagerOptionShowPowerAlertKey:@YES}];
        [_centralManager setDelegate:self];
    }
}

- (void)scanForPeripherals {
    if (_centralManager.state == CBCentralManagerStateUnsupported) {//设备不支持蓝牙
        
    }else {//设备支持蓝牙连接
        if (_centralManager.state == CBCentralManagerStatePoweredOn) {//蓝牙开启状态
            //[_centralManager stopScan];
            [_centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:[NSNumber numberWithBool:NO]}];
        }
    }
}

int logoutSum = 0;
int writeToFileTime = 0;
- (void)logout {
    NSString *singleItem = [self getALogItem];
    NSLog(@"%@", singleItem);
    logoutSum++;
    [self.totalLogString appendString:singleItem];
    [self.startRecordBtn setTitle:[NSString stringWithFormat:@"%d", 15 - logoutSum] forState:UIControlStateNormal];
    if (logoutSum == 15) {
        logoutSum = 0;
        [_logoutTimer invalidate];
        self.startRecordBtn.enabled = YES;
        NSString *path = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Documents/%d.txt", writeToFileTime]];
        [[NSUserDefaults standardUserDefaults] setObject:@(++writeToFileTime) forKey:WRITETOFILETIMES];
        [[self.totalLogString dataUsingEncoding:NSUTF8StringEncoding]
         writeToFile:path
         atomically:YES];
        [self.startRecordBtn setTitle:@"Shot" forState:UIControlStateNormal];
    }
}

- (NSString *)getALogItem {
    static NSDate *date;
    date = [NSDate date];
    
    return [NSString stringWithFormat:@"%@ [%ld], %.6f;%.6f;%f, , %@, %@, %f;%f;%f\n",
            [self.dateFormatter stringFromDate:date],
            [NSNumber UIntegerFromDouble:[date timeIntervalSince1970]],
            self.longitude,
            self.latitude,
            self.altitude,
            [self getWifiItem],
            [self getBluetoothItem],
            self.magneticX,
            self.magneticY,
            self.magneticZ];
}

- (NSString *)getBluetoothItem {
    NSMutableString *blueItem = [[NSMutableString alloc] init];
    for (NSUInteger count = 0; count < [self.bluetoothsArray count]; count++) {
        NearbyPeripheralInfo *info = self.bluetoothsArray[count];
        NSString *finalSignal = (count == [self.bluetoothsArray count] - 1)? @"": @";";
        [blueItem appendString:[NSString stringWithFormat:@"%@|RSSI:%@%@",info.peripheral.name, [info.RSSI stringValue], finalSignal]];
    }
    return blueItem;
}

- (NSString *)getWifiItem {
    [self fetchSSIDInfo];
    return [NSString stringWithFormat:@"%@;", self.wifiName];
}

- (id)fetchSSIDInfo {
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    id info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info && [info count]) { break; }
    }
    self.wifiName = info[@"BSSID"];
    return info;
}

#pragma mark - MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    CLLocation *location = userLocation.location;
    NSLog(@"\n经度：%f \n纬度：%f \n海拔：%f \n指向：%f \n速度：%f",
          location.coordinate.longitude,
          location.coordinate.latitude,
          location.altitude,
          location.course,
          location.speed);
    
    BOOL needRecenterMap = NO;
    if (self.latitude == 0) {
        needRecenterMap = YES;
    }
    self.latitude = location.coordinate.latitude;
    self.longitude = location.coordinate.longitude;
    self.altitude = location.altitude;
    self.latitudeLabel.text = [NSString stringWithFormat:@"%.6f", self.latitude];
    self.longitudeLabel.text = [NSString stringWithFormat:@"%.6f", self.longitude];
    
    if (needRecenterMap) {
        [self recenterMapView];
    }
}

- (void)recenterMapView {
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(self.latitude, self.longitude);
    MKCoordinateSpan square = MKCoordinateSpanMake(0.001, 0.001);
    [self.mapView setRegion:MKCoordinateRegionMake(center, square) animated:YES];
}

#pragma mark - CBCentralManager Delegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    return;
}
//发现蓝牙设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    BOOL isExist = NO;
    NearbyPeripheralInfo *info = [[NearbyPeripheralInfo alloc] init];
    info.peripheral = peripheral;
    info.advertisementData = advertisementData;
    info.RSSI = RSSI;
    
    if (self.bluetoothsArray.count == 0) {
        [self.bluetoothsArray addObject:info];
    } else {
        for (int i = 0; i < _bluetoothsArray.count; i++) {
            NearbyPeripheralInfo *originInfo = [_bluetoothsArray objectAtIndex:i];
            CBPeripheral *per = originInfo.peripheral;
            if ([peripheral.identifier.UUIDString isEqualToString:per.identifier.UUIDString]) {
                isExist = YES;
                [_bluetoothsArray replaceObjectAtIndex:i withObject:info];
            }
        }
        if (!isExist) {
            [_bluetoothsArray addObject:info];
        }
    }
}


#pragma mark - Getter
- (NSMutableArray *)bluetoothsArray {
    if (!_bluetoothsArray) {
        _bluetoothsArray = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return _bluetoothsArray;
}

@end
