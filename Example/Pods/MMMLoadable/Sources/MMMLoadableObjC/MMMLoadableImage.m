//
// MMMLoadable. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMLoadableImage.h"
#import "MMMLoadable+Subclasses.h"

@import MMMCommonCore;
@import MMMLog;

//
//
//
@implementation MMMImmediateLoadableImage

@synthesize image=_image;

- (id)initWithImage:(UIImage *)image {

	if (self = [super init]) {

		_image = image;

		[self didFinish];
	}

	return self;
}

- (BOOL)isContentsAvailable {
	return _image != nil;
}

- (void)didFinish {
	if (_image) {
		self.loadableState = MMMLoadableStateDidSyncSuccessfully;
	} else {
		self.loadableState = MMMLoadableStateDidFailToSync;
	}
}

- (void)doSync {
	// Nothing to do for this one, either synced initially or never.
	[self didFinish];
}

@end

//
//
//
@implementation MMMNamedLoadableImage {
	NSString *_name;
}

@synthesize image = _image;

- (id)initWithName:(NSString *)name {

	if (self = [super init]) {
		_name = name;
	}

	return self;
}

- (BOOL)isContentsAvailable {
	return _image != nil;
}

- (void)didFinishWithImage:(UIImage *)image {

	_image = image;

	if (_image) {

		[self setDidSyncSuccessfully];

	} else {

		MMM_LOG_ERROR(@"Could not load the image named '%@'", _name);

		[self setFailedToSyncWithError:nil];

		// This class is for images coming from the app's bundle, so the loading failure is most likely a
		// programmer's error and we need to crash asap.
		NSAssert(NO, @"Image '%@' is not in the bundle?", _name);
	}
}

- (void)doSyncDeferred {
	UIImage *image = [UIImage imageNamed:_name];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self didFinishWithImage:image];
	});
}

- (void)doSync {
	dispatch_async(
		dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
		^{
			// Yes, I want to capture self in this case since there is no way to cancel the load from our bundle anyway.
			[self doSyncDeferred];
		}
	);
}

@end

//
//
//
@implementation MMMPublicLoadableImage {
	NSURL *_url;
	UIImage *_image;
	NSURLSession *_session;
	NSURLSessionTask *_downloadTask;
}

@synthesize image=_image;

// TODO: this is not nice: without the cache the image could be reused in MMMTemple

+ (NSCache *)cache {

	static dispatch_once_t onceToken;
	static NSCache *cache = nil;
	dispatch_once(&onceToken, ^{
		cache = [[NSCache alloc] init];
		// Max 100 images
		cache.countLimit = 100;
		// Max 1 Mpixel
		cache.totalCostLimit = 100 * 100 * 100;
	});

	return cache;
}

- (id)initWithURL:(NSURL *)url {

	id cacheKey = url ?: [NSNull null];

	id cachedInstance = [[MMMPublicLoadableImage cache] objectForKey:cacheKey];
	if (cachedInstance)
		return cachedInstance;

	if (self = [super init]) {
		_url = url;
		_session = [NSURLSession sharedSession];
	}

	[[MMMPublicLoadableImage cache] setObject:self forKey:cacheKey cost:0];

	return self;
}

- (void)dealloc {
	[_downloadTask cancel];
}

- (BOOL)isContentsAvailable {
	return _image != nil;
}

- (void)doSync {

	if (!_url) {
		[self didFailWithError:[self errorWithMessage:@"No URL provided"]];
		return;
	}

	_downloadTask = [_session
		dataTaskWithURL:_url
		completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			if (error)
				[self didFailWithError:error];
			else
				[self didFinishSuccessfullyWithResponse:response data:data];
		}
	];
	[_downloadTask resume];
}

- (void)dispatch:(void (^)(void))block {
	dispatch_async(dispatch_get_main_queue(), block);
}

- (NSError *)errorWithMessage:(NSString *)message {
	return [NSError
		errorWithDomain:NSStringFromClass(self.class)
		code:1
		userInfo:@{
			NSLocalizedDescriptionKey : message
		}
	];
}

- (void)setFailedToSyncWithError:(NSError *)error {

	MMM_LOG_ERROR(@"Failed to fetch the image at '%@': %@", _url, [error localizedDescription]);

	[super setFailedToSyncWithError:error];
}

- (void)didFailWithError:(NSError *)error {

	[self dispatch:^{
		[self setFailedToSyncWithError:error];
	}];
}

- (void)didFinishSuccessfullyWithResponse:(NSURLResponse *)response data:(NSData *)data {

	NSAssert(![NSThread isMainThread], @"");

	if (!response) {
		[self didFailWithError:[self errorWithMessage:@"No response"]];
		return;
	}

	if (!data || [data length] == 0) {
		[self didFailWithError:[self errorWithMessage:@"Empty response"]];
		return;
	}

	if (![[response MIMEType] isEqual:@"image/jpeg"] && ![[response MIMEType] isEqual:@"image/jp2"] &&
        ![[response MIMEType] isEqual:@"image/png"] && ![[response MIMEType] isEqual:@"image/gif"] &&
        // Some backends just cannot configure themselves properly, so let's accept generic byte streams as well.
        ![[response MIMEType] isEqual:@"application/octet-stream"]
    ) {

		[self didFailWithError:[self errorWithMessage:[NSString
			stringWithFormat:@"Unsupported MIME type: '%@'", [response MIMEType]
		]]];

		return;
	}

	UIImage *image = [[UIImage alloc] initWithData:data];
	if (image) {

		MMM_LOG_TRACE(@"Successfully fetched a %ldx%ld image from %@", (long)image.size.width, (long)image.size.height, _url);

		// Now we know the size of the image, let's update the cost in the cache.
		[[MMMPublicLoadableImage cache] setObject:self forKey:_url cost:image.size.width * image.size.height];

		[[MMMNetworkConditioner shared]
			conditionBlock:^(NSError *error) {
				[self dispatch:^{
					if (error) {
						[self didFailWithError:error];
					} else {
						self->_image = image;
						self.loadableState = MMMLoadableStateDidSyncSuccessfully;
					}
				}];
			}
			inContext:NSStringFromClass(self.class)
			estimatedResponseLength:data.length
		];

	} else {
		[self didFailWithError:[self errorWithMessage:@"Could not decode the image data"]];
	}
}

@end

//
//
//
@implementation MMMTestLoadableImage

@synthesize image = _image;

- (void)setDidSyncSuccessfullyWithImage:(nullable UIImage *)image {
	_image = image;
	[self setDidSyncSuccessfully];
}

- (BOOL)isContentsAvailable {
	return _image != nil;
}

@end

//
//
//
@implementation MMMLoadableImageProxy

@dynamic loadable;

- (UIImage *)image {
	return self.loadable.image;
}

@end
