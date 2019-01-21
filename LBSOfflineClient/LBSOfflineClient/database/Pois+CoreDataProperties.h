//
//  Pois+CoreDataProperties.h
//  LBSOfflineClient
//
//  Created by HU Siyan on 14/1/2019.
//  Copyright © 2019 HU Siyan. All rights reserved.
//
//

#import "Pois+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Pois (CoreDataProperties)

+ (NSFetchRequest<Pois *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *id;
@property (nullable, nonatomic, copy) NSString *areaId;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *svg_name;
@property (nullable, nonatomic, copy) NSString *vertex;

@end

NS_ASSUME_NONNULL_END
