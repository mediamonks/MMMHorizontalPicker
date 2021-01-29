//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMLoadable.h"
#import "MMMLoadableImage.h"

@import Photos;

NS_ASSUME_NONNULL_BEGIN

/**
 * Wraps images in the Photo Library as MMMLoadableImage. This is when you have an asset identifier already
 * and then want to load the corresponding image.
 *
 * Note that this implementation is not suitable for the case when you need a lots of small thumbnails.
 * It's better to user the Photos framework directly in this case. This is more suitable for fetching a bunch of larger images.
 */
@interface MMMPhotoLibraryLoadableImage : MMMLoadable <MMMLoadableImage>

/** The identifier of the the PHAsset which is used to find it in the Photo Library. */
@property (nonatomic, readonly) NSString *localIdentifier;

/** The approximate size of the target image. Passed on initialization.
 * The resulting image won't be cropped and should be be able to "aspect fit" into a rectangle of this size,
 * though the actual size of the image can be larger. */
@property (nonatomic, readonly) CGSize targetSize;

- (id)initWithLocalIdentifier:(NSString *)localIdentifier
	targetSize:(CGSize)targetSize
	contentMode:(PHImageContentMode)contentMode NS_DESIGNATED_INITIALIZER;

- (id)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
