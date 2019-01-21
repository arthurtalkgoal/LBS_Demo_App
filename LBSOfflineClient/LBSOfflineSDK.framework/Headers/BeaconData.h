//
//  BeaconData.h
//  LBSOfflineSDK
//
//  Created by HU Siyan on 6/11/2018.
//  Copyright © 2018 HU Siyan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BeaconData : NSObject

@property (nonatomic, strong) NSString *beacon_uuid;
@property (nonatomic, strong) NSString *beacon_mac;
@property (assign, nonatomic) NSInteger major, minor;
@property (nonatomic, strong) Position *location;
@property (assign, nonatomic) double entreThreshold, farThreshold;
@property (assign, nonatomic) CGRect relatedPoly;

- (NSString *)identification;

@end

NS_ASSUME_NONNULL_END
