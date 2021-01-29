//
// MMMLoadable. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

@import UIKit;

#import "MMMLoadable.h"

NS_ASSUME_NONNULL_BEGIN

/** 
 * We need thumbnail images in a couple of places and they are not typically accessible immediately even if they sit in
 * a local cache or DB. So here is a simple protocol based on MMMLoadable (which is kind of a "promise" object) to wrap
 * such images.
 */
@protocol MMMLoadableImage <MMMLoadable>

/** The image itself. As always, this is available only when `contentsAvailable` is YES. */
@property (nonatomic, readonly, nullable) UIImage *image;

@end

/**
 * An image from the app's bundle (accessible via `+imageNamed:` method of UIImage) wrapped into MMMLoadableImage 
 * and loaded asynchronously.
 */
@interface MMMNamedLoadableImage : MMMLoadable <MMMLoadableImage>

- (id)initWithName:(NSString *)name NS_DESIGNATED_INITIALIZER;

- (id)init NS_UNAVAILABLE;

@end

/**
 * MMMLoadableImage-compatible wrapper for images that are immediatey available.
 */
@interface MMMImmediateLoadableImage : MMMLoadable <MMMLoadableImage>

- (id)initWithImage:(nullable UIImage *)image NS_DESIGNATED_INITIALIZER;

- (id)init NS_UNAVAILABLE;

@end

/** 
 * Implementation of MMMLoadableImage for images that are publically accessible via a URL.
 * This is very basic, using the shared instance of NSURLSession, so any caching will happen there.
 */
@interface MMMPublicLoadableImage : MMMLoadable <MMMLoadableImage>

- (id)initWithURL:(nullable NSURL *)url NS_DESIGNATED_INITIALIZER;

- (id)init NS_UNAVAILABLE;

@end

/**
 * This is used in unit tests when we want to manipulate the state of a MMMLoadableImage to verify it produces the needed 
 * effects on the views being tested.
 */
@interface MMMTestLoadableImage : MMMTestLoadable <MMMLoadableImage>

- (void)setDidSyncSuccessfullyWithImage:(nullable UIImage *)image;

@end

/**
 * Sometimes an object implementing MMMLoadableImage is created much later than when it would be convenient to have one.
 *
 * A proxy can be used in this case, so the users still have a reference to MMMLoadableImage and can begin observing it
 * or request a sync asap. Later when the actual reference is finally available it is supplied to the proxy which begins
 * mirroring its state.
 *
 * As always, this is meant to be used only in the implementation, with only id<MMMLoadableImage> visible publically.
 */
@interface MMMLoadableImageProxy : MMMLoadableProxy <MMMLoadableImage>

/** The image being proxied. */
@property (nonatomic, readwrite, nullable) id<MMMLoadableImage> loadable;

@end

NS_ASSUME_NONNULL_END
