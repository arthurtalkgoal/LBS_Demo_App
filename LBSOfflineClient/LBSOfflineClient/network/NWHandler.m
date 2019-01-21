//
//  NWHandler.m
//  LBSOfflineClient
//
//  Created by HU Siyan on 6/12/2018.
//  Copyright © 2018 HU Siyan. All rights reserved.
//

#import "NWHandler.h"
#import <AFNetworking/AFNetworking.h>

@interface NWHandler () {
    NSString *base_url;
    NSString *port_num;
    
    NSString *clientID, *clientSecret, *userName, *userPassword, *userID;
    NSString *access_token, *refresh_token, *token_type;
}

@end

@implementation NWHandler

static NWHandler *_instance = nil;
static AFHTTPSessionManager *_manager = nil;

+ (NWHandler *)instance {
    if (_instance) {
        return _instance;
    }
    @synchronized ([NWHandler class]) {
        if (!_instance) {
            _instance = [[self alloc]init];
            [_instance initiate];
        }
        return _instance;
    }
    return nil;
}

- (void)initiate {
    if (!_manager) {
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        [securityPolicy setValidatesDomainName:NO];
        [securityPolicy setAllowInvalidCertificates:YES];
        
        _manager = [AFHTTPSessionManager manager];
        _manager.securityPolicy = securityPolicy;
        
        [_manager.requestSerializer setCachePolicy:NSURLRequestReloadIgnoringCacheData];
        [_manager.operationQueue waitUntilAllOperationsAreFinished];
    }
    
    if (![clientID length]) {
        clientID = CLIENT_ID;
    }
    
    if (![clientSecret length]) {
        clientSecret = CLIENT_SECRET;
    }
    
    [self setBaseUrl:BASE_URL portNumber:PORT];
}

- (void)setBaseUrl:(NSString *)baseURL portNumber:(NSInteger)port {
    base_url = baseURL;
    port_num = [NSString stringWithFormat:@"%ld", (long)port];
}

#pragma mark - Server Access Grant
- (void)serverAccessGrantByUserName:(NSString *)user_name andPssword:(NSString *)pass_word success:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure {
    
    userName = user_name;
    userPassword = pass_word;
    
    _manager.requestSerializer  = [AFJSONRequestSerializer  serializer];
    NSString *auth_value = [NSString stringWithFormat:@"Basic %@", [self base64Encryption:[NSString stringWithFormat:@"%@:%@", clientID, clientSecret]]];
    [_manager.requestSerializer setValue:auth_value forHTTPHeaderField:@"Authorization"];
    
    NSString *uploadUrl = [NSString stringWithFormat:@"%@:%@/auth/token", base_url, port_num];
    _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    NSDictionary *para_dict = @{@"grant_type":@"password", @"username":userName, @"password":userPassword};
    [_manager POST:uploadUrl parameters:para_dict progress:^(NSProgress * _Nonnull uploadProgress) {
        NSLog(@"%lld", [uploadProgress totalUnitCount]);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *token_dict = responseObject;
        self->access_token = [token_dict objectForKey:@"access_token"];
        NSLog(@"Access token: %@", self->access_token);
        self->refresh_token = [token_dict objectForKey:@"refresh_token"];
        NSLog(@"refresh token: %@", self->refresh_token);
        self->token_type = [token_dict objectForKey:@"token_type"];
        NSLog(@"token_type: %@", self->token_type);
        if (self->access_token && self->refresh_token && self->token_type) {
            success(responseObject);
        } else {
            NSError *error = [NSError errorWithDomain:@"Successful respond with wrong informaiton" code:0 userInfo:nil];
            failure(error);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"Debug: %@",errResponse);
        failure(error);
    }];
    
}

- (void)serverAccessRefresh:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure {
    _manager.requestSerializer  = [AFJSONRequestSerializer  serializer];
    NSString *auth_value = [NSString stringWithFormat:@"Basic %@", [self base64Encryption:[NSString stringWithFormat:@"%@:%@", clientID, clientSecret]]];
    [_manager.requestSerializer setValue:auth_value forHTTPHeaderField:@"Authorization"];
    
    NSString *uploadUrl = [NSString stringWithFormat:@"%@:%@/auth/token", base_url, port_num];
    _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    NSDictionary *para_dict = @{@"grant_type":@"refresh_token", @"refresh_token":refresh_token};
    [_manager POST:uploadUrl parameters:para_dict progress:^(NSProgress * _Nonnull uploadProgress) {
        NSLog(@"%lld", [uploadProgress totalUnitCount]);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *token_dict = responseObject;
        //self->userID = [token_dict objectForKey:@"access_token"];
        self->access_token = [token_dict objectForKey:@"access_token"];
        NSLog(@"Access token: %@", self->access_token);
        self->refresh_token = [token_dict objectForKey:@"refresh_token"];
        NSLog(@"refresh token: %@", self->refresh_token);
        self->token_type = [token_dict objectForKey:@"token_type"];
        NSLog(@"token_type: %@", self->token_type);
        if (self->access_token && self->refresh_token && self->token_type) {
            success(responseObject);
        } else {
            NSError *error = [NSError errorWithDomain:@"Successful respond with wrong informaiton" code:0 userInfo:nil];
            failure(error);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)serverAccessUserID:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure {
    NSString *auth_value = [NSString stringWithFormat:@"%@ %@", @"Bearer", access_token];
    _manager.requestSerializer = [AFJSONRequestSerializer new];
    _manager.requestSerializer  = [AFJSONRequestSerializer  serializer];
    [_manager.requestSerializer setValue:auth_value forHTTPHeaderField:@"authorization"];

    NSString *uploadUrl = [NSString stringWithFormat:@"%@:%@/api/user", base_url, port_num];
    _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [_manager GET:uploadUrl parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        NSLog(@"%lld", [downloadProgress totalUnitCount]);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *token_dict = responseObject;
        NSDictionary *userid_dict = [token_dict objectForKey:@"data"];
        if (userid_dict) {
            self->userID = [userid_dict objectForKey:@"_id"];
        }
        if (self->userID) {
            success(responseObject);
        } else {
            NSError *error = [NSError errorWithDomain:@"Successful respond with wrong informaiton" code:0 userInfo:nil];
            failure(error);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
    }];
}

#pragma mark - Upload
- (void)upload:(NSDictionary *)transData
       atLevel:(NSString *)level_code
       success:(void (^)(id responseObject))success
       failure:(void (^)(NSError *error))failure {
    NSString *auth_value = [NSString stringWithFormat:@"Bearer %@" ,access_token];
    _manager.requestSerializer  = [AFJSONRequestSerializer  serializer];
    [_manager.requestSerializer setValue:auth_value forHTTPHeaderField:@"Authorization"];

    NSString *uploadUrl = [NSString stringWithFormat:@"%@:%@/api/tracking/position/track/user/%@/%@", base_url, port_num, userID, level_code];
    
    _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [_manager POST:uploadUrl parameters:transData progress:^(NSProgress * _Nonnull uploadProgress) {
        NSLog(@"%lld", [uploadProgress totalUnitCount]);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"Get Response: %@", responseObject);
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        //NSLog(@"%@", task.response.description);
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        failure(error);
    }];
}

#pragma mark - Private Functions
- (void)parseTokenDictionary:(id)responseObject {
    
}

- (NSString *)base64Encryption:(NSString *)for_encrypted {
    NSData *plainData = [for_encrypted dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String;
    if ([plainData respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
        base64String = [plainData base64EncodedStringWithOptions:kNilOptions];  // iOS 7+
    } else {
        base64String = [plainData base64Encoding];                              // pre iOS7
    }
    
    return base64String;
}

@end
