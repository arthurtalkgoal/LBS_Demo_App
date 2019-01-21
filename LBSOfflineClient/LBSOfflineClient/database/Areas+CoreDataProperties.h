//
//  Areas+CoreDataProperties.h
//  LBSOfflineClient
//
//  Created by HU Siyan on 3/12/2018.
//  Copyright © 2018 HU Siyan. All rights reserved.
//
//

#import "Areas+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Areas (CoreDataProperties)

+ (NSFetchRequest<Areas *> *)fetchRequest;

@property (nonatomic) float altitude;
@property (nullable, nonatomic, copy) NSString *id;
@property (nullable, nonatomic, copy) NSString *name;

@end

NS_ASSUME_NONNULL_END
