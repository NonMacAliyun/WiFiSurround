//
//  network.m
//  WiFi_Souround
//
//  Created by Non on 16/7/20.
//  Copyright © 2016年 NonMac. All rights reserved.
//

#import "network.h"

@implementation network
- (id)init
{
    self = [super init];
    networks = [[NSMutableDictionary alloc] init];
    libHandle = dlopen("/System/Frameworks/CoreTelephony.framework/CoreTelephony", RTLD_LAZY);
    char *error;
    if (libHandle == NULL && (error = dlerror()) != NULL)  {
        NSLog(@"%s",error);
        exit(1);
    }
    apple80211Open = dlsym(libHandle, "Apple80211Open");
    apple80211Bind = dlsym(libHandle, "Apple80211BindToInterface");
    apple80211Close = dlsym(libHandle, "Apple80211Close");
    apple80211Scan = dlsym(libHandle, "Apple80211Scan");
    apple80211Open(&airportHandle);
    apple80211Bind(airportHandle, @"en0");
    return self;
}

- (NSDictionary *)network:(NSString *) BSSID
{
    return [networks objectForKey:@"BSSID"];
}

- (NSDictionary *)networks
{
    return networks;
}

- (void)scanNetworks
{
    NSLog(@"Scanning WiFi Channels…");
    NSDictionary *parameters = [[NSDictionary alloc] init];
    NSArray *scan_networks; //is a CFArrayRef of CFDictionaryRef(s) containing key/value data on each discovered network
    apple80211Scan(airportHandle, &scan_networks, (__bridge void *)(parameters));
    NSLog(@"===–======\n%@",scan_networks);
    for (int i = 0; i < [scan_networks count]; i++) {
        [networks setObject:[scan_networks objectAtIndex: i] forKey:[[scan_networks objectAtIndex: i] objectForKey:@"BSSID"]];
    }
    NSLog(@"Scanning WiFi Channels Finished.");
}

- (NSUInteger)numberOfNetworks
{
    return [networks count];
}

- ( NSString * ) description {
    NSMutableString *result = [[NSMutableString alloc] initWithString:@"Networks State: \n"];
    for (id key in networks){
        [result appendString:[NSString stringWithFormat:@"%@ (MAC: %@), RSSI: %@, Channel: %@ \n",
                              [[networks objectForKey: key] objectForKey:@"SSID_STR"], //Station Name
                              key, //Station BBSID (MAC Address)
                              [[networks objectForKey: key] objectForKey:@"RSSI"], //Signal Strength
                              [[networks objectForKey: key] objectForKey:@"CHANNEL"]  //Operating Channel
                              ]];
    }
    return [NSString stringWithString:result];
}

- (void) dealloc {
    apple80211Close(airportHandle);
}

@end
