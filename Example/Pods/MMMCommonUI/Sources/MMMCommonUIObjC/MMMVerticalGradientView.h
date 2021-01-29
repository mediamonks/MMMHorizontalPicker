//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

@import UIKit;

#import "MMMAnimations.h"

NS_ASSUME_NONNULL_BEGIN

/** 
 * A view displaying a gradient from top to bottom. The linearity of the gradient can be controlled.
 * Can be handy for shadow overlays, etc.
 */
@interface MMMVerticalGradientView : UIView

- (nonnull id)initWithTopColor:(UIColor *)topColor bottomColor:(UIColor *)bottomColor curve:(MMMAnimationCurve)curve NS_DESIGNATED_INITIALIZER;

- (nonnull id)initWithTopColor:(UIColor *)topColor bottomColor:(UIColor *)bottomColor;

- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
