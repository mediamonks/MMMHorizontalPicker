//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MMMScrollViewShadowsSettings;

/**
 * A helper for adding top and bottom shadows into any UIScrollView-based class.
 * You create an instance in your subclass and forward calls from layoutSubviews.
 */
@interface MMMScrollViewShadows : NSObject

- (nonnull id)initWithScrollView:(nonnull UIScrollView *)scrollView
	settings:(nonnull MMMScrollViewShadowsSettings *)settings NS_DESIGNATED_INITIALIZER;

- (nonnull id)init NS_UNAVAILABLE;

/** Have to be called from `layoutSubviews` of our scroll view subclass to update the state of the shadows. */
- (void)layoutSubviews;

/** YES, if additional content view clipping might be needed for the current shadow settings. */
- (BOOL)mightNeedClippingView;

/** Same as `layoutSubviews` above but also updates `clipToBounds` property of the given view in case there are visible
 * shadows that are not flush with the edges of our scroll view, i.e. when top/bottomShadowShouldUseContentInsets
 * are used with settings and the corresponding insets are not zero now. */
- (void)layoutSubviewsWithClippingView:(nullable UIView *)clippingView;

@end

/**
 * Holds configuration for MMMScrollViewShadows that can be set only on initialization time.
 */
@interface MMMScrollViewShadowsSettings : NSObject

/** The base shadow color is black with this amount of transparency applied to it. */
@property (nonatomic, readwrite) CGFloat shadowAlpha;

/**
 * The value between 0 and 1 telling how close to an elliptical curve the shadow's border should be.
 *
 *  - when it's 0, then the shadow is a normal rectangular one.
 *
 *  - when it's 1, then the gradient of the top (bottom) shadow forms an arc crossing the center of a shadow view and
 *    its both corners.
 *
 * All values in-between adjust the point at which the gradient crosses the sides of the shadow views.
 *
 * (The default value is 0.5.)
 */
@property (nonatomic, readwrite) CGFloat shadowCurvature;

/** Disabled by default. */
@property (nonatomic, readwrite) BOOL topShadowEnabled;

/** The height of the top shadow view. (5px by default.) */
@property (nonatomic, readwrite) CGFloat topShadowHeight;

/** YES, if the top shadow should be offset from the top edge of the scroll view by the top offset of content insets.
 * The default value is NO. */
@property (nonatomic, readwrite) BOOL topShadowShouldUseContentInsets;

/** Disabled by default. */
@property (nonatomic, readwrite) BOOL bottomShadowEnabled;

/** The height of the bottom shadow view. (10px by default.) */
@property (nonatomic, readwrite) CGFloat bottomShadowHeight;

/** YES, if the bottom shadow should be offset from the bottom edge of the scroll view by the bottom offset of content insets.
 * The default value is NO. */
@property (nonatomic, readwrite) BOOL bottomShadowShouldUseContentInsets;

- (nonnull id)init NS_DESIGNATED_INITIALIZER;

@end

//

typedef NS_ENUM(NSInteger, MMMScrollViewShadowAlignment) {
	MMMScrollViewShadowAlignmentTop,
	MMMScrollViewShadowAlignmentBottom
};

/// A view that's used internally to render shadows in MMMAutoLayoutScrollView.
/// Open for reuse in cases we want to display compatible shadows but differntly controlled.
/// Note that this does not support Auto Layout, you have to manage its frame.
@interface MMMScrollViewShadowView : UIView

- (id)initWithAlignment:(MMMScrollViewShadowAlignment)alignment
	settings:(MMMScrollViewShadowsSettings *)settings NS_DESIGNATED_INITIALIZER;

- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
