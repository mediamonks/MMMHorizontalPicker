//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MMMAutoLayoutScrollViewContentView;
@class MMMScrollViewShadowsSettings;

/** 
 * A vertical scroll view with a content view and preconfigured constraints, so there is no need in creating
 * a scroll view / content view sandwitch manually every time.
 *
 * It also supports top and bottom shadows that are displayed only when the content is clipped.
 * The shadows can be enabled individually and they can sit either flush with the edges of the scroll view
 * or can be inset according to `adjustedContentInset`, which can be handy when vertical `safeAreaInsets` need
 * to be taken into account. (Note that `contentInsetAdjustmentBehavior` has to be either `None` or `Always`
 * on this view since "automatic" options can lead to cyclic calculations.) Also note that scroll indicators
 * are disabled here by default.
 *
 * Begin by adding your controls and constraints into the `contentView` ensuring that its size can be derived from your
 * constraints alone. Avoid constraints to the scroll view itself or outside views unless you are prepared to deal
 * with the consequences.
 *
 * Note that the width of the `contentView` will be constrainted hard to be equal to the width of the scroll view
 * and its height will be constrained with prio 251 to be at least as large as the height of the scroll view.
 */
@interface MMMAutoLayoutScrollView : UIScrollView

/** This is where your content subviews should be added. */
@property (nonatomic, readonly) MMMAutoLayoutScrollViewContentView *contentView;

/** Initializes with the given config.
 * Note that changing the config after the initialization has no effect on the view. */
- (id)initWithSettings:(MMMScrollViewShadowsSettings *)settings NS_DESIGNATED_INITIALIZER;

/** Initializes with default settings, a shortcut for `initWithSettings:[[MMMScrollViewShadowsSettings alloc] init]`. */
- (id)init;

- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

@end

/** A subview of MMMAutoLayoutScrollView where all the subviews should be added.
 * (It's not different from UIView, but making it of its own class helps when browsing view hierarchies.) */
@interface MMMAutoLayoutScrollViewContentView : UIView
@end

NS_ASSUME_NONNULL_END
