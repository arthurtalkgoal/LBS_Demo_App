//
//  Pois+CoreDataProperties.m
//  LBSOfflineClient
//
//  Created by HU Siyan on 14/1/2019.
//  Copyright © 2019 HU Siyan. All rights reserved.
//
//

#import "Pois+CoreDataProperties.h"

@implementation Pois (CoreDataProperties)

+ (NSFetchRequest<Pois *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Pois"];
}

@dynamic id;
@dynamic areaId;
@dynamic name;
@dynamic svg_name;
@dynamic vertex;

@end
