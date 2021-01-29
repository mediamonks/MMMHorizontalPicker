//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MMMShadowViewSetting;

typedef void (^ _Nonnull MMMShadowViewSettingBlock)(MMMShadowViewSetting *setting);

/**
 * Holds configuration for MMMShadowView.
 */
@interface MMMShadowViewSetting : NSObject

/** Default is black color. */
@property (nonatomic, readwrite) UIColor *color;

/** Default is 0. */
@property (nonatomic, readwrite) CGFloat opacity;

/** Default is zero. */
@property (nonatomic, readwrite) CGSize offset;

/** Default is 0. */
@property (nonatomic, readwrite) CGFloat radius;

/** Default is zero. */
@property (nonatomic, readwrite) UIEdgeInsets insets;

/** Default is white color. */
@property (nonatomic, readwrite) UIColor *backgroundColor;

/** Default is 0. */
@property (nonatomic, readwrite) CGFloat cornerRadius;

// TODO: Add support for path.

- (id)init;

- (id)initWithBlock:(MMMShadowViewSettingBlock)block;

@end

#pragma mark - 

/**
* Helper view for adding custom layer shadows, while taking the the shadow sizes in conserderation for its final frame.
*/
@interface MMMShadowView : UIView

/** View that can accepts and lay out subviews. */
@property (nonatomic, readonly) UIView *contentView;

@property (nonatomic, readwrite, nullable) NSArray<MMMShadowViewSetting *> *settings;

- (id)init;
- (id)initWithSettings:(nullable NSArray<MMMShadowViewSetting *> *)settings;

- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
