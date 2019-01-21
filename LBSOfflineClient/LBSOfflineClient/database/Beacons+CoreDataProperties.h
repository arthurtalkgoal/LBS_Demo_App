//
//  Beacons+CoreDataProperties.h
//  LBSOfflineClient
//
//  Created by HU Siyan on 3/12/2018.
//  Copyright © 2018 HU Siyan. All rights reserved.
//
//

#import "Beacons+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Beacons (CoreDataProperties)

+ (NSFetchRequest<Beacons *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *areaId;
@property (nullable, nonatomic, copy) NSString *enterThres;
@property (nullable, nonatomic, copy) NSString *id;
@property (nullable, nonatomic, copy) NSString *location;
@property (nullable, nonatomic, copy) NSString *mac;
@property (nullable, nonatomic, copy) NSString *major;
@property (nullable, nonatomic, copy) NSString *minor;
@property (nullable, nonatomic, copy) NSString *psudoLocation;
@property (nullable, nonatomic, copy) NSString *relatedPolygon;
@property (nullable, nonatomic, copy) NSString *thresDiff;
@property (nullable, nonatomic, copy) NSString *uuid;
@property (nonatomic) BOOL enabled;
@property (nullable, nonatomic, copy) NSString *farThres;
@property (nonatomic) BOOL floorSwitch;
@property (nullable, nonatomic, copy) NSString *relatedRegion;

@end

NS_ASSUME_NONNULL_END
