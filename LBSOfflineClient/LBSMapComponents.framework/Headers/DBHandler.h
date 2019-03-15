//
//  DBHandler.h
//  LBSOfflineClient
//
//  Created by HU Siyan on 30/11/2018.
//  Copyright © 2018 HU Siyan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DBHandlerDelegate <NSObject>

- (void)LoadingCompleted:(BOOL)now;

@end

@interface DBHandler : NSObject

@property (weak, nonatomic) id <DBHandlerDelegate> delegate;

+ (DBHandler *)instance;
- (void)startLoadWithSiteName:(NSString *)siteName andPath:(NSString *)site_Path;

- (NSArray *)fetchAllObjectsForEntity:(NSString *)entityName orderedBy:(nullable NSString *)orderProperty ascending:(BOOL)ascending;
- (NSArray *)fetchObjectsForEntity:(NSString *)entityName AtKey:(NSString *)key withValue:(NSString *)value orderedBy:(nullable NSString *)orderProperty ascending:(BOOL)ascending;
- (id)fetchObjectForEntity:(NSString *)entityName ForId:(NSString *)idStr;

@end

NS_ASSUME_NONNULL_END
