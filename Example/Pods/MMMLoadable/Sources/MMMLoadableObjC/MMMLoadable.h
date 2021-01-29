//
// MMMLoadable. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/** 
 * \file
 *
 * This is yet another implementation of a "promise" pattern (aka "deferred", "future", etc).
 * Unlike the implementation in jQuery and similar, state transitions backwards (like from 'resolved'
 * to 'in progress') are allowed here and therefore the resolved value can be available no matter
 * the current state.
 *
 * This is convenient to pair with view models when a typical pattern is to display a loading indicator of some
 * sort while the contents is being fetched and then to either display the downloaded data or indicate an error
 * with some means to retry the load (i.e. 'sync' the loadable again). The contents, if available in a loadable,
 * is not changed until the next successful sync, which again fits the usual UI patterns where data is displayed
 * even during a refresh.
 *
 * I was calling them 'loadable objects' originally because I did not know this pattern at the time (2012)
 * when I needed a model for nodes of a data graph that could be loaded (or refreshed) on demand as the user
 * was navigating through the app. The nodes would contain a bunch of values corresponding to a single API call.
 * While the nodes were refreshing the previously loaded values could still be used in the UI. Same for the case
 * when attempts to refresh were failing.
 */

/** 
 * Main states a loadable object can be in.
 * I was using 'loading'/'loaded successfully'/'failed to load' before, but this is less natural when
 * we are uploading/saving something, so went with 'syncing'.
 */
typedef NS_CLOSED_ENUM(NSInteger, MMMLoadableState) {

	/** 
	 * Nothing is happening with the object now.
	 * It's been never synced or the result of the last sync is not known or important.
	 * (Promises — 'not ready'.)
	 */
	MMMLoadableStateIdle,

	/** 
	 * The object is being synced now (e.g. the contents is being downloaded or saved somewhere).
	 * (Promises — 'in-progress'.)
	 */
	MMMLoadableStateSyncing,

	/** 
	 * The object has been successfuly synced and its contents (promises — value) is available now.
	 * (Promises — 'resolved'.)
	 * (A name is a bit longer than just 'synced' here so it's easier to differentiate from 'syncing'.)
	 */
	MMMLoadableStateDidSyncSuccessfully,

	/** 
	 * The object has not been able to sync for some reason.
	 * (Promises — 'rejected'.)
	 */
	MMMLoadableStateDidFailToSync
};

/** As always, it can be handy to print the current state. */
extern NSString *NSStringFromMMMLoadableState(MMMLoadableState state);

@protocol MMMLoadableObserver;

/** 
 * A protocol for a "read only" view on a loadable object which allows to observe the state
 * but does not allow to sync the contents (i.e. trigger a refresh, upload, etc depending on the context).
 * (It's similar to the difference between "Promise" in "Deferred" in jQuery.)
 *
 * Note that there is no explicit "value" property here, the extension of the protocol should specify additional fields
 * ("contents" properties) that together constitute the "value" of the promise.
 */
NS_SWIFT_NAME(MMMPureLoadableProtocol)
@protocol MMMPureLoadable <NSObject>

/** The state of the loadable, such as 'idle' or 'syncing'.
 * The 'loadable' prefix allows to have a 'state' property for somethingn else in the same object. */
@property (nonatomic, readonly) MMMLoadableState loadableState;

/**
 * Optional error object describing the failure to sync the loadable.
 *
 * The message should be never shown to the user. If different error conditions have to be communicated to the user,
 * then they should be indicated via the `code` property of the error and the frontend should select appropriate copy
 * based on it; alternatively, there can be an additional property providing more information.
 */
@property (nonatomic, readonly, nullable) NSError *error;

/** 
 * YES, if the contents associated with this loadable (a bunch of properties collectively constituting the "value"
 * of the promise, depending on the context) can be used now.
 *
 * Note that unlike promises the contents can be available even when the state says the last sync has failed.
 * (It can be the value fetched on a previous sync or the one fetched initially from a cache, etc;
 * it might be not fresh perhaps, but still be available to be displayed in the UI, for example).
 *
 * Note that if the state of the loadable is 'did sync successfully' then 'contentsAvailable' must be YES;
 * the reverse is not true.
 *
 * This property can change only together with `loadableState`.
 *
 * TODO: rename to something like 'ready' to play better with the cases when a loadable is not about fetching
 * contents but about completion of something.
 */
@property (nonatomic, readonly, getter = isContentsAvailable) BOOL contentsAvailable;

/**
 * Adds a state change observer for this loadable. 
 * You can use this method directly or use MMMLoadableObserver proxy object for more convenient installation and removal.
 */
- (void)addObserver:(id<MMMLoadableObserver>)observer NS_SWIFT_NAME(addObserver(_:));

/** 
 * Removes the observer installed earlier.
 * Note that forgetting to remove one or trying to remove it more than once is considered a programmer's error.
 */
- (void)removeObserver:(id<MMMLoadableObserver>)observer NS_SWIFT_NAME(removeObserver(_:));

@end

/**
 * A property or a getter marked with this can be used only if `contentsAvailable` of the corresponding object is YES.
 *
 * This is an empty macro that can be optionally used to annotate properties/getters collectively comprising a 'value'
 * of an object conforming to MMMPureLoadable, i.e. this is not functional, needed for documentation only.
 */
#define MMM_CONTENTS

/** 
 * A part of the 'loadable' interface allowing to trigger a refresh (sync).
 */
NS_SWIFT_NAME(MMMLoadableProtocol)
@protocol MMMLoadable <MMMPureLoadable>

/** Asks the loadable to sync now (e.g. download the associated contents).
 * If syncing is already in progress, then the call is ignored. */
- (void)sync;

/** YES, if the loadable needs to be synced because it was never synced, or a cache timeout has expired,
 * or properties were changed and need to be uploaded, etc. */
@property (nonatomic, readonly) BOOL needsSync;

/** Calls `sync` if `needsSync` is YES or if the state is different from 'did sync successfully'. */
- (void)syncIfNeeded;

@end

/** 
 * Protocol observers of loadable objects should conform to.
 * You can use it directly in your classes observing loadables or employ a proxy object defined below
 * which allows to use blocks or selectors and which won't forget to remove itself when deallocated.
 */
NS_SWIFT_NAME(MMMLoadableObserverProtocol)
@protocol MMMLoadableObserver <NSObject>

/** 
 * Called whenever the loadable object changes (or sometimes when it might change).
 * Note that in addition to `loadableState` this also covers `contentsAvailable` and the actual
 * "content" properties of the object (i.e. the value of the promise).
 *
 * This is usually called on the main thread.
 */
- (void)loadableDidChange:(id<MMMPureLoadable>)loadable;

@end

/** A block which is called when a lodable object is changed, see MMMLoadableObserver#loadableDidChange. */
typedef void (^MMMLoadableObserverDidChangeBlock)(id<MMMPureLoadable> loadable);

/** 
 * An proxy that sets itself as an observer of a loadable object and then forwards "did change" notifications
 * to a block or a target/selector pair. This way your custom objects don't have to conform to `MMMLoadableObserver`
 * protocol exposing it in their public interfaces.
 *
 * When initialized it adds itself as an observer of the given loadable and removes itself automatically
 * when deallocated or when its `remove` method is called.
 *
 * Both initializers return `nil` when the passed `loadable` is `nil`. This is handy when resubscribing to (possibile)
 * different loadables many times and storing an instance of the observer in the same variable over and over: there is
 * no need to check the target loadable and/or nillify the previous observer to unsubscribe.
 */
@interface MMMLoadableObserver : NSObject

/**
 * Adds itself as an observer of the given loadable forwarding "did change" notifications to the given block.
 *
 * Returns `nil` when the passed `loadable` is `nil` as well. See also the docs on the class.
 */
- (nullable id)initWithLoadable:(nullable id<MMMPureLoadable>)loadable block:(MMMLoadableObserverDidChangeBlock)block;

/**
 * Adds itself as an observer of the given loadable forwarding "did change" notifications to the given target/selector.
 *
 * Returns `nil` when the passed `loadable` is `nil` as well. See also the docs on the class.
 */
- (nullable id)initWithLoadable:(nullable id<MMMPureLoadable>)loadable target:(id<NSObject>)target selector:(SEL)selector;

/** 
 * Removes this observer from the associated loadable. It is safe to call it more than once.
 * It's also called automatically when the proxy is deallocated.
 */
- (void)remove;

@end

/** 
 * An implementation of a lodable that might be used as a base.
 * Subclasses must override 'isContentsAvailable' and 'doSync', the latter being called from implementation
 * of sync/syncIfNeeded, see `MMMLoadable+Subclasses.h`.
 * (Only the general declaration is open here so you can inherit it in the classes exposed to the end user,
 * but still keep implementation details out of sight.)
 */
@interface MMMLoadable : NSObject <MMMLoadable>

- (id)init NS_DESIGNATED_INITIALIZER;

@end

/**
 * A basic implementation of `MMMPureLoadable` that does not require to override anything.
 * Typically you would have an object that instead of vending these objects directly would vend them as
 * `id<MMMPureLoadable>`, so the state controls are visible to your main object only and don't distract
 * the end user.
 */
@interface MMMPureLoadable : NSObject <MMMPureLoadable>

- (id)init NS_DESIGNATED_INITIALIZER;

/** @{ */

/** Again, these are open here and not in a separate header like for `MMMLoadable`, because you never
 * expose objects of this type to your clients directly, but vend them as id<MMMPureLoadable>. */

/** Transitions the object into the 'syncing' without touching the current value of `contentsAvailable`. */
- (void)setSyncing;

/** Transitions the object into the 'failed' state setting the `error` field to the given value
 * and `contentsAvailable` to NO. */
- (void)setFailedToSyncWithError:(nullable NSError *)error;

/** Transitions the object into the 'synced successfully' state clearing the `error` field
 * and setting `contentsAvailable` to YES. */
- (void)setDidSyncSuccessfully;

/** @} */

@end

/** 
 * `MMMLoadable` with simple autorefresh logic.
 * Again, see `MMMLoadable+Subclasses.h` if you want to see how to override things.
 */
@interface MMMAutosyncLoadable : MMMLoadable

- (id)init NS_DESIGNATED_INITIALIZER;

@end

/**
 * Defines how sync failures in child loadables of a loadable group affect the sync state of the whole group.
 */
typedef NS_ENUM(NSInteger, MMMLoadableGroupFailurePolicy) {
    
    /** 
	 * The whole group is considered "failed to sync" when any of the child loadables fails to sync. 
	 * (This is the default behavior that most of the code relies on.)
	 */
    MMMLoadableGroupFailurePolicyStrict,
    
    /**
     * The whole group never fails to sync, not even when all the loadables within the group fail.
	 * (In this case it's assumed that the user code will inspect the children and decide what to do.)
     */
    MMMLoadableGroupFailurePolicyNever
};

/** 
 * Allows to treat several "pure" loadables as one.
 *
 * Can be used standalone or subclassed (see `MMMLoadable+Subclasses.h` in this case.)
 *
 * Its loadable state in case of a "strict" failure policy (default) is:
 * - 'synced succesfully', when all the loadables in the group are synced successfully,
 * - 'failed to sync', when at least one of the loadables in the group has failed to sync;
 * - 'syncing', when at least one of the loadables in the group is still syncing and none has failed yet.
 *
 * The loadable state in case of "never" failure policy is:
 * - 'syncing', when at least one of the loadables in the group is still syncing;
 * - 'synced succesfully' otherwise.
 *
 * Regardless of the failure policy 'contentsAvailable' is `YES` when it is `YES` for all the objects in the group.
 *
 * The 'did change' event of the group is called when when the `loadableState` of the whole object changes or
 * when all the objects are loaded, then every time any of the objects emits 'did change'.
 */
@interface MMMPureLoadableGroup : NSObject <MMMPureLoadable>

- (id)initWithLoadables:(nullable NSArray<id<MMMPureLoadable>> *)loadables 
	failurePolicy:(MMMLoadableGroupFailurePolicy)failurePolicy;

/** Convenience initializer using the "strict" failure policy for compatibility with the current code. */
- (id)initWithLoadables:(nullable NSArray<id<MMMPureLoadable>> *)loadables;

- (id)init NS_UNAVAILABLE;

@end

/**
 * Similar to `MMMPureLoadableGroup` allows to treat a bunch of loadables as one.
 *
 * Can be used standalone or subclassed (see `MMMLoadable+Subclasses.h` in this case.)
 *
 * In addition to the behaviour of `MMMPureLoadableGroup`:
 * - `needsSync` is YES, if the same property is YES for at least one object in the group;
 * - `sync` and `syncIfNeeded` methods call the corresponding methods of every object in the group supporting them
 *   (note that some time before we required all objects in a "non-pure" group to support syncing, but it's not the case
 *   anymore).
 */
@interface MMMLoadableGroup : MMMPureLoadableGroup <MMMLoadable>

- (id)initWithLoadables:(nullable NSArray<id<MMMPureLoadable>> *)loadables 
	failurePolicy:(MMMLoadableGroupFailurePolicy)failurePolicy NS_DESIGNATED_INITIALIZER;

/** Convenience initializer using the "strict" failure policy for compatibility with the current code. */
- (id)initWithLoadables:(nullable NSArray<id<MMMPureLoadable>> *)loadables;

@end

/**
 * Sometimes an API expects a promise but you don't have a reference to it until some time later,
 * i.e. you need a promise for a promise.
 *
 * This proxy pretends its contents is unavailable and the state is idle until the actual promise is set.
 * After this all the properties are taken and the calls are forwarded from/to the actual object.
 *
 * You can inherit this and forward "contents" properties for your kind of loadable. 
 */
@interface MMMPureLoadableProxy : MMMPureLoadable <MMMPureLoadable>

@property (nonatomic, readwrite, nullable) id<MMMPureLoadable> loadable;

@end

/**
 * Same as MMMPureLoadableProxy but for MMMLoadable protocol.
 *
 * In case the user asks the proxy to sync before the actual object is set, then it actually enters 'syncing' state
 * and when the actual object is set, then a sync is triggered for it too.
 */
@interface MMMLoadableProxy : MMMLoadable <MMMLoadable>

@property (nonatomic, readwrite, nullable) id<MMMLoadable> loadable;

@end

/**
 * Can be used as a base for unit test (view) models conforming to MMMLoadable.
 * Basically allows to override properties of MMMLoadable from the outside (i.e. from a unit test).
 */
@interface MMMTestLoadable : NSObject <MMMLoadable>

/** @{ */
/** Properties of MMMLoadable we allow to change directly without sending "did change" automatically. */

@property (nonatomic, readwrite) BOOL needsSync;
@property (nonatomic, readwrite, getter = isContentsAvailable) BOOL contentsAvailable;
@property (nonatomic, readwrite, nullable) NSError *error;

/** @{ */
/** We allow to change `loadableState` directly and using shortcuts.
 * The "did change" notification is sent even when there was no actual change in the state. */

@property (nonatomic, readwrite) MMMLoadableState loadableState;

- (void)setIdle;
- (void)setSyncing;
- (void)setDidSyncSuccessfully;

/** Sets the error and changes the `loadableState` to "failed" which triggers "did change" notification. */
- (void)setDidFailToSyncWithError:(nullable NSError *)error;

/** @} */

/** Allows to force sending "did change" event from the outside or a subclass. */
- (void)notifyDidChange;

/** YES, if the object has at least one observer installed. */
@property (nonatomic, readonly) BOOL hasObservers;

/** @{ */
/** The counters allow to assert from the unit tests if certain methods were called. */

- (void)resetAllCallCounters;

@property (nonatomic, readonly) NSInteger syncIfNeededCounter;
@property (nonatomic, readonly) NSInteger syncCounter;
@property (nonatomic, readonly) NSInteger isContentsAvailableCounter;

@property (nonatomic, readonly) NSInteger addObserverCounter;
@property (nonatomic, readonly) NSInteger removeObserverCounter;

/** @} */

/** Subclasses can override to perform sync. Does nothing by default. */
- (void)doSync;

@end

NS_ASSUME_NONNULL_END
