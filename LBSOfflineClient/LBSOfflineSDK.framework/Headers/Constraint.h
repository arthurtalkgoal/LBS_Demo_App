//
//  Constraint.h
//  LBSOfflineSDK
//
//  Created by HU Siyan on 28/2/2019.
//  Copyright © 2019 HU Siyan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum Constraint_Type : NSUInteger {
    OutConstraint,
    InConstraint
} Constraint_Type;

@interface Constraint : POI

@property (nonatomic) Constraint_Type type;

- (CGPoint)dragPointOntoOutConstraint:(CGPoint)pnt;

@end

NS_ASSUME_NONNULL_END
