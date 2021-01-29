//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

/** 
 * A simple table view cell wrapping the given view. 
 *
 * This is handy when you have a view already and just want to show it as one more cell.
 *
 * The view being wrapped should support Auto Layout and inflate its height properly. The cell has its `selectionStyle` 
 * set to `UITableViewCellSelectionStyleNone` as these kind of cells typically do not appear selected.
 */
@interface MMMViewWrappingCell<ViewType> : MMMTableViewCell

/** The view this cell wraps. It is added into the `contentView` and is laid out to fully fill it. */
@property (nonatomic, readonly) ViewType wrappedView;

- (id)initWithView:(ViewType)view reuseIdentifier:(NSString *)reuseIdentifier;
- (id)initWithView:(ViewType)view reuseIdentifier:(NSString *)reuseIdentifier inset:(UIEdgeInsets)inset;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
