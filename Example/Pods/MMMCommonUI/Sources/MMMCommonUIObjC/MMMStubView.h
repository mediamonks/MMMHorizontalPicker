//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/** 
 * To be used during development as a placeholder for not yet implemented views.
 * It inherits a vertical scroll view so it's possible to see that gesture recognizers of the container do not interfere 
 * with a typical scrolling.
 */
@interface MMMStubView : UIScrollView

/** The text is optional, the index influences the background color. */
- (id)initWithText:(nullable NSString *)text index:(NSInteger)index NS_DESIGNATED_INITIALIZER;

- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
