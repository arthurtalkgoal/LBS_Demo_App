//
//  POI.h
//  LBSOfflineSDK
//
//  Created by HU Siyan on 14/1/2019.
//  Copyright © 2019 HU Siyan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface POI : NSObject

@property (nonatomic, strong) id _id;
@property (nonatomic, strong) NSString *areaId;

@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) NSArray *vertex;
@property (nonatomic, assign) CGPoint tempCentre;

@property (nonatomic, assign) CGRect rect;
@property (nonatomic, assign) CGPoint center;

- (nullable NSArray *)contains:(CGPoint)pnt;

@end

NS_ASSUME_NONNULL_END
