//
//  ViewController.m
//  WiFi_Souround
//
//  Created by Non on 16/7/19.
//  Copyright © 2016年 NonMac. All rights reserved.
//

#import "ViewController.h"

//定位
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
//基站

//wifi
#import "network.h"
#import <NetworkExtension/NetworkExtension.h>


//蓝牙
#import <CoreBluetooth/CoreBluetooth.h>
//地磁3轴
#import <CoreMotion/CoreMotion.h>

#import "NSNumber+Transform.h"

#import <NetworkExtension/NetworkExtension.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import "NetworkManager.h"


#import <Foundation/Foundation.h>
#include <dlfcn.h>
#import <UIKit/UIKit.h>
#include <stdio.h>
#include <stdlib.h>


#define WRITETOFILETIMES @"WRITETOFILETIMES"

@interface NearbyPeripheralInfo : NSObject
@property (nonatomic,strong) CBPeripheral *peripheral;
@property (nonatomic,strong) NSDictionary *advertisementData;
@property (nonatomic,strong) NSNumber *RSSI;
@end

@implementation NearbyPeripheralInfo
@end

@interface ViewController ()<CLLocationManagerDelegate, CBCentralManagerDelegate, MKMapViewDelegate>

//IBOutlet
@property (weak, nonatomic) IBOutlet UIButton *startRecordBtn;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) CLLocationDegrees latitude, longitude, altitude;

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

@property (nonatomic, strong) NSTimer *logoutTimer;
@property (nonatomic, strong) NSMutableString *totalLogString;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[[UIAlertView alloc] initWithTitle:@"提醒"
                                message:@"请确保开启了蓝牙、wifi、定位功能"
                               delegate:nil
                      cancelButtonTitle:@"ok"
                      otherButtonTitles:nil] show];
    if (![[NSUserDefaults standardUserDefaults] objectForKey:WRITETOFILETIMES]) {
        [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:WRITETOFILETIMES];
        writeToFileTime = 0;
    } else {
        writeToFileTime = [[[NSUserDefaults standardUserDefaults] objectForKey:WRITETOFILETIMES] intValue];
    }
    
//    [[NetworkManager sharedNetworksManager] scan];
    
    [self setUpLocation];
    [self setUpCellStation];
    [self setUpWifi];
    [self setUpBluetooth];
    [self setUpMagnetic];
}

- (void)setUpLocation {
    return;
    self.locationManager = [[CLLocationManager alloc] init];
    //如果没有授权则请求用户授权
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined){
        [self.locationManager requestWhenInUseAuthorization];
    }else {
        [self.locationManager requestWhenInUseAuthorization];
        
        //设置代理
        self.locationManager.delegate = self;
        //设置定位精度
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        //定位频率,每隔多少米定位一次
        self.locationManager.distanceFilter = 0.1;
        //启动跟踪定位
        [self.locationManager disallowDeferredLocationUpdates];
        [self.locationManager startUpdatingLocation];
    }
}

- (void)setUpCellStation {
    return;
    [[[UIAlertView alloc] initWithTitle:@"cell强度"
                                message:[NSString stringWithFormat:@"%d", getSignalStrength()]
                               delegate:self
                      cancelButtonTitle:@"ok"
                      otherButtonTitles:nil] show];
    NSLog(@"=================%d", getSignalStrength());
}

int getSignalStrength()
{
    void *libHandle = dlopen("/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony", RTLD_LAZY);
    int (*CTGetSignalStrength)();
    CTGetSignalStrength = dlsym(libHandle, "CTGetSignalStrength");
    if( CTGetSignalStrength == NULL) NSLog(@"Could not find CTGetSignalStrength");
    int result = CTGetSignalStrength();
    dlclose(libHandle);
    return result;
}

- (void)setUpWifi {
    [self fetchSSIDInfo];
    return;
    
    for(NEHotspotNetwork *hotspotNetwork in [NEHotspotHelper supportedNetworkInterfaces]) {
        double signalStrength = hotspotNetwork.signalStrength;
        NSLog(@"SignalStrength %@",signalStrength);
    }
    
    return;
    NSLog(@"——–");
    network *networksManager = [[network alloc] init];
    [networksManager scanNetworks];
    NSLog(@"—–wifi description———-\n%@",[networksManager description]);
    NSLog(@"—-wifi size ——\n%d",[networksManager numberOfNetworks]);
    NSLog(@"====");
    
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

- (IBAction)startRecord {
    self.logoutTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                        target:self
                                                      selector:@selector(logout)
                                                      userInfo:nil
                                                       repeats:YES];
    self.startRecordBtn.enabled = NO;
    self.totalLogString = [[NSMutableString alloc] init];
}

int logoutSum = 0;
int writeToFileTime = 0;
- (void)logout {
    NSString *singleItem = [self getALogItem];
    NSLog(@"%@", singleItem);
    logoutSum++;
    [self.totalLogString appendString:singleItem];
    if (logoutSum == 15) {
        logoutSum = 0;
        [_logoutTimer invalidate];
        self.startRecordBtn.enabled = YES;
        NSString *path = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Documents/%d.txt", writeToFileTime]];
        [[NSUserDefaults standardUserDefaults] setObject:@(++writeToFileTime) forKey:WRITETOFILETIMES];
        [[self.totalLogString dataUsingEncoding:NSUTF8StringEncoding]
         writeToFile:path
         atomically:YES];
    }
}

- (NSString *)getALogItem {
    static NSDate *date;
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-DD hh:mm:ss";
    });
    date = [NSDate date];
    
    return [NSString stringWithFormat:@"%@ [%ld], %f;%f;%f, , %@, %@, %f;%f;%f\n",
            [dateFormatter stringFromDate:date],
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
//    [blueItem appendString:@"[ "];
    for (NSUInteger count = 0; count < [self.bluetoothsArray count]; count++) {
        NearbyPeripheralInfo *info = self.bluetoothsArray[count];
        NSString *finalSignal = (count == [self.bluetoothsArray count] - 1)? @"": @";";
        [blueItem appendString:[NSString stringWithFormat:@"%@|RSSI:%@%@",info.peripheral.name, [info.RSSI stringValue], finalSignal]];
    }
//    [blueItem appendString:@" ]"];
    return blueItem;
}

- (NSString *)getWifiItem {
    [self fetchSSIDInfo];
    return [NSString stringWithFormat:@"%@;", self.wifiName];
}

- (id)fetchSSIDInfo {
//    NSArray * networkInterfaces = [NEHotspotHelper supportedNetworkInterfaces];
//    NSLog(@"Networks %@",networkInterfaces);
//    
//    //获取wifi列表
//    
//    for(NEHotspotNetwork *hotspotNetwork in [NEHotspotHelper supportedNetworkInterfaces]) {
//        NSString *ssid = hotspotNetwork.SSID;
//        NSString *bssid = hotspotNetwork.BSSID;
//        BOOL secure = hotspotNetwork.secure;
//        BOOL autoJoined = hotspotNetwork.autoJoined;
//        double signalStrength = hotspotNetwork.signalStrength;
//    }
//    return  nil;
    
    
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
//    NSLog(@"Supported interfaces: %@", ifs);
    id info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
//        NSLog(@"%@ => %@", ifnam, info);
        
//        NSLog(@"%@", [[NSString alloc] initWithData:info[@"SSIDDATA"] encoding:NSUTF8StringEncoding]);
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
    
    self.latitude = location.coordinate.latitude;
    self.longitude = location.coordinate.longitude;
    self.altitude = location.altitude;
}

#pragma mark - CLLocationDelegate
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
        status == kCLAuthorizationStatusAuthorizedAlways) {
        manager.distanceFilter = 0.1;
        manager.desiredAccuracy = kCLLocationAccuracyBest;
        [manager disallowDeferredLocationUpdates];
        [manager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    NSLog(@"%lu", (unsigned long)[locations count]);
    CLLocation *location = [locations firstObject];
    NSLog(@"\n经度：%f \n纬度：%f \n海拔：%f \n指向：%f \n速度：%f",
          location.coordinate.longitude,
          location.coordinate.latitude,
          location.altitude,
          location.course,
          location.speed);
    
    self.latitude = location.coordinate.latitude;
    self.longitude = location.coordinate.longitude;
    self.altitude = location.altitude;
}



#pragma mark - CBCentralManager Delegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    return;
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CBCentralManagerStatePoweredOff");
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@"CBCentralManagerStatePoweredOn");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"CBCentralManagerStateResetting");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"CBCentralManagerStateUnauthorized");
            break;
        case CBCentralManagerStateUnknown:
            NSLog(@"CBCentralManagerStateUnknown");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"CBCentralManagerStateUnsupported");
            break;
        default:
            break;
    }
}

//发现蓝牙设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
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
