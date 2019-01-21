//
//  Areas+CoreDataProperties.m
//  LBSOfflineClient
//
//  Created by HU Siyan on 3/12/2018.
//  Copyright © 2018 HU Siyan. All rights reserved.
//
//

#import "Areas+CoreDataProperties.h"

@implementation Areas (CoreDataProperties)

+ (NSFetchRequest<Areas *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Areas"];
}

@dynamic altitude;
@dynamic id;
@dynamic name;

@end
