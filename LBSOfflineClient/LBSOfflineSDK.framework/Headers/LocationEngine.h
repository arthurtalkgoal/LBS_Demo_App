//
//  LocationEngine.h
//  LBSOfflineSDK
//
//  Created by HU Siyan on 6/11/2018.
//  Copyright © 2018 HU Siyan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LocationEngineDelegate <NSObject>
@optional
- (void)updateLocation:(Position *)point;
- (void)updatePOI:(NSArray<POI *> *)poi_rels;
@end

typedef enum PositioningTool : NSUInteger {
    default_wifi_gps,
    BLE_beacon,
    Geomagnetic,
    StepCounter,
    Other_peripheral
} PositioningTool;

@interface LocationEngine : NSObject

@property (nonatomic, strong) id <LocationEngineDelegate> delegate;
@property (nonatomic, strong) ThreadSafeMutableArray *locations;

+ (instancetype)sharedinstance;
- (void)accessChecking:(UIViewController *)vc;
- (void)positioningTurnedOn:(BOOL)on For:(PositioningTool)toolType;
- (void)timerInterval:(NSInteger)interval forType:(PositioningTool)toolType;
- (BOOL)addRefData_Beacons:(NSArray<BeaconData *> *)beacon_db;
- (void)addRefData_POIs:(NSArray<POI *> *)POIs;

- (void)start;
- (void)end;

@end

NS_ASSUME_NONNULL_END
