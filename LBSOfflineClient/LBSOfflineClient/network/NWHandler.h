//
//  NWHandler.h
//  LBSOfflineClient
//
//  Created by HU Siyan on 6/12/2018.
//  Copyright © 2018 HU Siyan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NWSettings.h"

NS_ASSUME_NONNULL_BEGIN

@interface NWHandler : NSObject


+ (NWHandler *)instance;

- (void)serverAccessGrantByUserName:(NSString *)user_name andPssword:(NSString *)pass_word success:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure;
- (void)serverAccessRefresh:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure;
- (void)serverAccessUserID:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure;
- (void)upload:(NSDictionary *)transData atLevel:(NSString *)level_code success:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure;

@end

NS_ASSUME_NONNULL_END
