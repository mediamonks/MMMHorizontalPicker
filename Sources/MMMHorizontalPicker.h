//
// MMMHorizontalPicker.
// Copyright (C) 2016-2021 MediaMonks. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MMMHorizontalPickerDelegate;

typedef NS_ENUM(NSInteger, MMMHorizontalPickerStyle) {

	/** In this mode all item views define their preferred width via Auto Layout. */
	MMMHorizontalPickerStyleDefault,

	/** In this mode the width of every item will be constrainted to the width of the picker adjusted to `contentInsets`. */
	MMMHorizontalPickerStylePaged,

	/** In this mode the width of every item will be constrainted to the width of the widest item adjusted to `contentInsets`. */
	MMMHorizontalPickerStyleUniform
};

/**
 * Allows to swipe horizontally through a lot of items ensuring only a handful of subviews are used.
 * The views corresponding to each element can be of different width and can use Auto Layout.
 *
 * NOTE: When widths of items are very different, then scrolling and panning can be a bit funky.
 */
@interface MMMHorizontalPicker : UIView

@property (nonatomic, readonly) MMMHorizontalPickerStyle style;

@property (nonatomic, weak, nullable) id<MMMHorizontalPickerDelegate> delegate;

/** All the item views will be positioned within the rect obtained by insetting the bounds by these insets. */
@property (nonatomic, readwrite) UIEdgeInsets contentInsets;

/** The distance to keep between two neigbour item views.
 * Note that this does not work as expected when dragging item views that are different in size. */
@property (nonatomic, readwrite) CGFloat spacing;

/** Optional view which when set is used to calculate prefered height of the picker. */
@property (nonatomic, readwrite, nullable) UIView *prototypeView;

/** The index of the item closest to the center of the picker's viewport. 
 * Note that when set it will be always clipped into [0; numbersOfItems - 1] range. */
@property (nonatomic, readwrite) NSInteger currentItemIndex;
- (void)setCurrentItemIndex:(NSInteger)currentItemIndex animated:(BOOL)animated;

/** Should be called when the number of items change. */
- (void)reload;

#pragma mark -

- (id)initWithStyle:(MMMHorizontalPickerStyle)style NS_DESIGNATED_INITIALIZER;

/** Convenience initializer using "default" picker style. */
- (id)init;

- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end

/** 
 */
@protocol MMMHorizontalPickerDelegate <NSObject>

@required

/** The total number of items. Note that this is read only once, when `reload` is called. */
- (NSInteger)numberOfItemsForHorizontalPicker:(MMMHorizontalPicker *)picker NS_SWIFT_NAME(numberOfItemsForHorizontalPicker(_:));

/** The delegate must provide a view showing the given item, it should use Auto Layout and at least the width should be defined. */
- (UIView *)horizontalPicker:(MMMHorizontalPicker *)picker viewForItemWithIndex:(NSInteger)index;

- (void)horizontalPickerDidChangeCurrentItemIndex:(MMMHorizontalPicker *)picker;

@optional

/** Called after an item view becomes invisible and is removed from the picker.
 * The delegate can choose to store it somewhere and reuse it later or can just forget it and simply use a new view next time. */
- (void)horizontalPicker:(MMMHorizontalPicker *)picker recycleView:(UIView *)view;

/** Called after the given item view is added into the view hierarchy. */
- (void)horizontalPicker:(MMMHorizontalPicker *)picker prepareView:(UIView *)view;

/**
 * Called every time the viewport position changes (every frame in case of animation or dragging) with an updated
 * "center proximity" value for each visible item view.
 *
 * "Center proximity" is a difference between the center of the item and the current viewport
 * position in "index space" coordinates.
 *
 * For example, if the current item is in the center of the view port already, then its "center proximiy" value will be 0,
 * and the same value for the view right (left) to the central item will be 1 (-1). When dragging the contents so the
 * right view gets closer to the center, then its center proximity will be continously approaching 0.
 *
 * This is handy when you need to dim or transforms items when they get farther from the center,
 * but be careful with doing heavy things here.
 */
- (void)horizontalPicker:(MMMHorizontalPicker *)picker updateView:(UIView *)view centerProximity:(CGFloat)centerProximity;

/**
 * Called when the picker scrolls to a new offset.
 */
- (void)horizontalPicker:(MMMHorizontalPicker *)picker didScroll:(CGFloat)offset;

@end

NS_ASSUME_NONNULL_END
