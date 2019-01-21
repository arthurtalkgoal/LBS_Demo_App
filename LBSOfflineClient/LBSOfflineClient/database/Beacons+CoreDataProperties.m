//
//  Beacons+CoreDataProperties.m
//  LBSOfflineClient
//
//  Created by HU Siyan on 3/12/2018.
//  Copyright © 2018 HU Siyan. All rights reserved.
//
//

#import "Beacons+CoreDataProperties.h"

@implementation Beacons (CoreDataProperties)

+ (NSFetchRequest<Beacons *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Beacons"];
}

@dynamic areaId;
@dynamic enterThres;
@dynamic id;
@dynamic location;
@dynamic mac;
@dynamic major;
@dynamic minor;
@dynamic psudoLocation;
@dynamic relatedPolygon;
@dynamic thresDiff;
@dynamic uuid;
@dynamic enabled;
@dynamic farThres;
@dynamic floorSwitch;
@dynamic relatedRegion;

@end
