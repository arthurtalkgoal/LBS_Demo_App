//
//  Position.h
//  LBSOfflineSDK
//
//  Created by HU Siyan on 26/11/2018.
//  Copyright © 2018 HU Siyan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Position : NSObject

@property (nonatomic, assign) double x, y;
@property (nonatomic, strong) NSString *areaId;
@property (nonatomic, assign) long long timestamp;

- (instancetype)initWithAreaId:(NSString *)areaId location:(CGPoint)loc;
- (BOOL)isEqual:(Position *)object;
- (BOOL)inSameArea:(Position *)object;
- (NSString *)model2String;

- (CGPoint)location;

@end

NS_ASSUME_NONNULL_END
