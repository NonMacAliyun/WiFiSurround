//
//  NSNumber+Transform.m
//  WiFi_Souround
//
//  Created by Non on 16/7/21.
//  Copyright © 2016年 NonMac. All rights reserved.
//

#import "NSNumber+Transform.h"

@implementation NSNumber (Transform)

+ (NSUInteger)UIntegerFromDouble:(double)aDouble {
    return [[NSNumber numberWithDouble:aDouble] unsignedIntegerValue];
}

+ (NSString *)StringFromDouble:(double)aDouble {
    return [[NSNumber numberWithDouble:aDouble] stringValue];
}

+ (double)DoubleFrom6Double:(double)aDouble {
    return [[NSString stringWithFormat:@"%.6f", aDouble] doubleValue];
}

@end
