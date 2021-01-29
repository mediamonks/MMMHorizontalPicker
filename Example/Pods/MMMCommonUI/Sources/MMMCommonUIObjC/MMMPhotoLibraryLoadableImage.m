//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMPhotoLibraryLoadableImage.h"

#import "MMMLoadable+Subclasses.h"
@import MMMCommonCore;

//
//
//
@implementation MMMPhotoLibraryLoadableImage {

	PHImageContentMode _contentMode;

	PHImageManager *_imageManager;

	PHImageRequestID _requestID;

	// YES, if _requestID is valid (because there is no official invalid value for PHImageRequestID documented).
	BOOL _requestIDValid;
}

@synthesize image = _image;

- (id)initWithLocalIdentifier:(NSString *)localIdentifier
	targetSize:(CGSize)targetSize
	contentMode:(PHImageContentMode)contentMode
{
	if (self = [super init]) {
		_localIdentifier = localIdentifier;
		_targetSize = targetSize;
		_contentMode = contentMode;
		_imageManager = [PHImageManager defaultManager];
	}

	return self;
}

- (BOOL)isContentsAvailable {
	return _image != nil;
}

- (NSError *)errorWithMessage:(NSString *)message {
	return [NSError mmm_errorWithDomain:NSStringFromClass(self.class) message:message];
}

- (void)doSyncDeferred {

	PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[ _localIdentifier ] options:nil];

	PHAsset *asset = result.firstObject;
	if (!asset) {
		[self setFailedToSyncWithError:[self
			errorWithMessage:[NSString stringWithFormat:@"Could not fetch the asset #%@", _localIdentifier]
		]];
		return;
	}

	PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];

	// We want the latest version of the image with all the edits, etc.
	// This is probably the default option, but it's not mentioned in the docs, so let's be explicit.
	options.version = PHImageRequestOptionsVersionCurrent;

	// We want the best quality image, getting several calls is not interesting as this class
	// is not designed to present a lot of images quickly, Photos should be used directly in this case.
	options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;

	// We are OK to get something larger than we want.
	options.resizeMode = PHImageRequestOptionsResizeModeFast;

	typeof(self) __weak weakSelf = self;
	_requestID = [_imageManager
		requestImageForAsset:asset
		targetSize:_targetSize
		contentMode:_contentMode
		options:options
		resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
			[[MMMNetworkConditioner shared]
				conditionBlock:^(NSError *error) {
					dispatch_async(dispatch_get_main_queue(), ^{
						typeof(self) strongSelf = weakSelf;
						if (error) {
							[strongSelf didFinishRequestWithError:error image:nil info:nil];
						} else {
							[strongSelf didFinishRequestWithError:nil image:result info:info];
						}
					});
				}
				inContext:NSStringFromClass(self.class)
				estimatedResponseLength:0
			];
		}
	];
	_requestIDValid = YES;
}

- (void)didFinishRequestWithError:(NSError *)error image:(UIImage *)image info:(NSDictionary *)info {

	if (image) {
		_image = image;
		[self setDidSyncSuccessfully];
	} else {
		[self setFailedToSyncWithError:error ?: [self
			errorWithMessage:[NSString
				stringWithFormat:@"Could not fetch the image for target size %@",
				NSStringFromCGSize(_targetSize)
			]
		]];
	}
}

- (void)doSync {

	// Let's offload this to a queue just in case the access to fetchAssetsWithLocalIdentifiers: is slow.
	typeof(self) __weak weakSelf = self;
	dispatch_async(
		dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
		^{
			typeof(self) strongSelf = weakSelf;
			[strongSelf doSyncDeferred];
		}
	);
}

@end
