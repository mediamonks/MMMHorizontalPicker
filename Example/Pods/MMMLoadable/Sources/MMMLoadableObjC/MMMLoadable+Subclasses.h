//
// MMMLoadable. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMLoadable.h"

@import MMMObservables;

NS_ASSUME_NONNULL_BEGIN

/** 
 * Parts of the base lodable accessible to subclasses.
 */
@interface MMMLoadable (Subclasses)

/** Subclasses are able to change the loadable state of course. */
@property (nonatomic, readwrite) MMMLoadableState loadableState;

/** Subclasses can get access to the observer hub, so they can extend MMMLoadableObserver and provide more info to their observers. */
@property (nonatomic, readonly) MMMObserverHub *observerHub;

/** Subclasses must override this to return YES when the contents/value of the promise is available. */
@property (nonatomic, readonly, getter=isContentsAvailable) BOOL isContentsAvailable;

/** Subclasses might also override this to change when syncIfNeeded triggers sync. */
- (BOOL)needsSync;

/** 
 * Subclasses must override this or to perform the actual synchronization.
 * This is called from the implementation of 'sync' and loadableState is set to 'syncing' beforehand.
 * The implementation must properly change the 'loadableState' when done.
 */
- (void)doSync;

/** Subclasses can notify the observers about a change in the object as well. */
- (void)notifyDidChange;

/** Transitions the object into the 'syncing'. */
- (void)setSyncing;

/** Changes the state to 'failed to sync' and sets an optional error object. */
- (void)setFailedToSyncWithError:(nullable NSError *)error;

/** Transitions the object into the 'synced successfully' state. */
- (void)setDidSyncSuccessfully;

/** @{ */
/** 
 * Sometimes the subclasses need to know if there is someone observing them. These hooks allow to know this and do
 * something when the first observer is added or the last one is removed. 
 */

/** YES, if at least one observer is installed. */
- (BOOL)hasObservers;

/** Called after the very first observer is added (i.e. when hasObservers switches from NO to YES).  */
- (void)didAddFirstObserver;

/** Called when the last observer is removed (and thus hasObservers changes from YES to NO). */
- (void)didRemoveLastObserver;

/** @{ */

@end

/**
 * Parts of MMMPureLoadable accessible to subclasses.
 */
@interface MMMPureLoadable (Subclasses)

/** Subclasses are able to change the loadable state of course. */
@property (nonatomic, readwrite) MMMLoadableState loadableState;

/** Subclasses can get access to the observer hub, so they can extend MMMLoadableObserver and provide more info to their observers. */
@property (nonatomic, readonly) MMMObserverHub *observerHub;

/** Subclasses must override this to return YES when the contents/value of the promise is available. */
@property (nonatomic, readonly, getter=isContentsAvailable) BOOL isContentsAvailable;

/** Subclasses can notify the observers about a change in the object as well. */
- (void)notifyDidChange;

/** @{ */

/**
 * Sometimes the subclasses need to know if there is someone observing them. These hooks allow to know this and do
 * something when the first observer is added or the last one is removed.
 */

/** YES, if at least one observer is installed. */
- (BOOL)hasObservers;

/** Called after the very first observer is added (i.e. when hasObservers switches from NO to YES).  */
- (void)didAddFirstObserver;

/** Called when the last observer is removed (and thus hasObservers changes from YES to NO). */
- (void)didRemoveLastObserver;

/** @{ */

@end


//
//
//
@interface MMMAutosyncLoadable (Subclasses)

/** How often autorefresh for the object should be triggered while the app is active. */
- (NSTimeInterval)autosyncInterval;

/** 
 * How often autorefresh for the object should be triggered while the app is in background.
 * Return 0 or negative value to disable syncing while in background.
 */
- (NSTimeInterval)autosyncIntervalWhileInBackground;

@end

//
//
//
@interface MMMPureLoadableGroup (Subclasses)

/** Note that the contents of the group can be changed by subclasses any time after the initialization
 * (and this can be done more than once), so a nil can be passed to the designated initializer and then
 * this property can be adjusted after subobjects are initialized. */
@property (nonatomic, readwrite) NSArray<id<MMMPureLoadable>> *loadables;

- (void)notifyDidChange;

/**
 * Called when the state of the group changes and _before_ the observers are notified.
 * Subclasses can override this without calling super. This is preferred over overriding `notifyDidChange`.
 */
- (void)groupDidChange;

@end

//
//
//
@interface MMMLoadableProxy (Subclasses) 

/**
 * Called just before observers are notified.
 */
- (void)proxyDidChange;

@end

//
//
//
@interface MMMPureLoadableProxy (Subclasses) 

/**
 * Called just before observers are notified.
 */
- (void)proxyDidChange;

@end

NS_ASSUME_NONNULL_END
