//
//  Areas+CoreDataProperties.h
//  LBSMapComponents
//
//  Created by HU Siyan on 6/3/2019.
//  Copyright © 2019 HU Siyan. All rights reserved.
//
//

#import "Areas+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Areas (CoreDataProperties)

+ (NSFetchRequest<Areas *> *)fetchRequest;

@property (nonatomic) float altitude;
@property (nullable, nonatomic, copy) NSString *id;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *level_code;

@end

NS_ASSUME_NONNULL_END
