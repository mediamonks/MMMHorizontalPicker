//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MMMScrollViewShadows.h"
#import "MMMPreferredSizeChanges.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * A table view supporting top and bottom shadows.
 */
@interface MMMTableView : UITableView <MMMPreferredSizeChanges>

/** */
- (id)initWithSettings:(MMMScrollViewShadowsSettings *)settings style:(UITableViewStyle)style;

/** Note that UITableViewStylePlain is used. */
- (id)initWithSettings:(MMMScrollViewShadowsSettings *)settings;

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/// When enabled, then `reloadData` is automatically called whenever any of the cells report potential size
/// changes via `mmm_setPreferredSizeCouldChange`. See `MMMPreferredSizeChanges` for more info.
///
/// This feature is disabled by default for compatibility with the current code.
@property (nonatomic, readwrite) BOOL shouldHandlePotentialCellSizeChanges;

@end

NS_ASSUME_NONNULL_END
