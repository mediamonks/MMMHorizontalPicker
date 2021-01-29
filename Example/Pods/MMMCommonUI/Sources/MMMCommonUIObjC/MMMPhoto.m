//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMPhoto.h"

#import "MMMPhotoLibraryLoadableImage.h"
@import Photos;

//
//
//
@implementation MMMPhotoFromLibrary

- (id)initWithLocalIdentifier:(NSString *)localIdentifier {
	if (self = [super init]) {
		_localIdentifier = localIdentifier;
	}
	return self;
}

- (PHImageContentMode)PHImageContentModeFromContentMode:(MMMPhotoContentMode)contentMode {
	switch (contentMode) {
		case MMMPhotoContentModeAspectFit:
			return PHImageContentModeAspectFit;
		case MMMPhotoContentModeAspectFill:
			return PHImageContentModeAspectFill;
	}
}

- (id<MMMLoadableImage>)imageForTargetSize:(CGSize)targetSize contentMode:(MMMPhotoContentMode)contentMode {
	return [[MMMPhotoLibraryLoadableImage alloc]
		initWithLocalIdentifier:_localIdentifier
		targetSize:targetSize
		contentMode:[self PHImageContentModeFromContentMode:contentMode]
	];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: asset '%@'>", self.class, _localIdentifier];
}

@end

//
//
//
@implementation MMMPhotoFromUIImage {
	MMMImmediateLoadableImage *_loadable;
	UIImage *_image;
}

- (id)initWithImage:(UIImage *)image {

	if (self = [super init]) {

		// TODO: downscale it to the size that makes sense asap, then get rid of the original
		_image = image;
	}

	return self;
}

- (id<MMMLoadableImage>)imageForTargetSize:(CGSize)targetSize contentMode:(MMMPhotoContentMode)contentMode {

	// TODO: For now we don't trim it for different target sizes, but maybe we should downscale when a thumbnail is requested.
	if (!_loadable) {
		_loadable = [[MMMImmediateLoadableImage alloc] initWithImage:_image];
	}

	return _loadable;
}

@end

//
//
//
@implementation WIGTestPlaceholderPhoto {
	NSInteger _index;
}

- (instancetype)initWithIndex:(NSInteger)index {

    if (self = [super init]) {
    	_index = index;
    }

    return self;
}

- (id<MMMLoadableImage>)imageForTargetSize:(CGSize)targetSize contentMode:(MMMPhotoContentMode)contentMode {
	NSString *url = [NSString stringWithFormat:@"https://loremflickr.com/%li/%li?lock=%li", (long)targetSize.width, (long)targetSize.height, (long)_index];
	return [[MMMPublicLoadableImage alloc] initWithURL:[NSURL URLWithString:url]];
}

@end
