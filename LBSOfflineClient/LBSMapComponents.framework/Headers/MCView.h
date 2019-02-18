//
//  MCView.h
//  LBSMapComponents
//
//  Created by HU Siyan on 30/1/2019.
//  Copyright © 2019 HU Siyan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Floor.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum MVPinType : NSUInteger {
    MVPinFrom,
    MVPinTo,
    MVPinLoc,
    MVPinTap,
} MVPinType;

@interface MCView : UIView

@property (nonatomic, assign) BOOL navigating;

- (instancetype)initWithFrame:(CGRect)frame;
- (BOOL)addFloor:(NSArray<Floor *> *)new_floors;
- (void)showMapView;
- (void)hideMapView;
- (void)deallocMapView;

- (void)showLevelView;
- (void)hideLevelView;
- (void)deallocLevelView;

- (void)moveto:(CGPoint)coor areaId:(NSString *)areaId;

@end

NS_ASSUME_NONNULL_END
