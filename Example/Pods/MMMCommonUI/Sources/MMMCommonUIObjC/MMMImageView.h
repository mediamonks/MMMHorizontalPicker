//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A limited replacement for UIImageView fixing its inability to properly work with images having
 * non-zero alignmentRectInsets when scaled.
 *
 * Note that this view is already constrained to the aspect ratio of the image's alignment rect,
 * so you should not use hard (equal) pins against both width and height or against all edges.
 */
@interface MMMImageView : UIView

@property (nonatomic, readwrite, nullable) UIImage *image;
@property (nonatomic, readwrite, nullable) UIImage *highlightedImage;

@property (nonatomic, readwrite, getter=isHighlighted) BOOL highlighted;

- (id)initWithImage:(nullable UIImage *)image highlightedImage:(nullable UIImage *)highlightedImage NS_DESIGNATED_INITIALIZER;

/** Convenience initializer. */
- (id)init;

/** Convenience initializer. */
- (id)initWithImage:(nullable UIImage *)image;

- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
