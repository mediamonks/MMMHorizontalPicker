//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MMMScrollViewShadows.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Collection view supporting top & bottom shadows.
 */
@interface MMMCollectionView : UICollectionView

/** Uses UICollectionViewFlowLayout by default. */
- (instancetype)initWithSettings:(MMMScrollViewShadowsSettings *)settings NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
