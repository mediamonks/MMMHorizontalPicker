//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// A view supporting this will be notified when one of the child views indicates potential changes in its contents
/// that might influence its size via `mmm_setPreferredSizeCouldChange`.
///
/// This is handy with views that do not fully rely on Auto Layout, like UITableView,
/// where a change in the size of a cell would require it to reload this cell.
///
/// The implementation is responsible for coalescing notification and avoiding notification loops.
@protocol MMMPreferredSizeChanges <NSObject>

- (void)mmm_preferredSizeCouldChangeForSubview:(UIView *)subview;

@end

@interface UIView (MMMPreferredSizeChanges)

/// Signals to one of the interested parent views (supporting `MMMPreferredSizeChanges`)
/// that the size of this view could have potentially changed and they should measure things again.
///
/// This helps with containers that do not primarily rely on Auto Layout, like UITableView.
- (void)mmm_setPreferredSizeCouldChange;

@end

NS_ASSUME_NONNULL_END
