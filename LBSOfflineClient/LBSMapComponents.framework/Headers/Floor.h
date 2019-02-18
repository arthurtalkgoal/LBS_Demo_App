//
//  Floor.h
//  LBSMapComponents
//
//  Created by HU Siyan on 30/1/2019.
//  Copyright © 2019 HU Siyan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Floor : NSObject

@property (nonatomic, strong) NSString *_id;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *image_path;
@property (nonatomic, assign) float scale;
@property (nonatomic, assign) float altitude;

@end

NS_ASSUME_NONNULL_END
