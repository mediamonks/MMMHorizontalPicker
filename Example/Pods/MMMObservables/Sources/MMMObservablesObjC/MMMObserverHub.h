//
// MMMObservables. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MMMObserverToken.h"

/** 
 * Helps with implementation of observable objects where you need to add/remove observer functionality done properly.
 * In most cases an array of weak references would work well enough, but sometimes tricky cases (like removal of
 * observers while they are being notified) should be handled as well.
 *
 * Please note that the helper is not thread-safe, it handles reentrancy, but makes no assumptions about threading.
 *
 * A class using this helper will typically expose its own add/remove observer methods, will forward their invocation
 * to a private instance of this helper, and will use forEachObserver: to notify all the registered observers.
 */
@interface MMMObserverHub<__covariant ObserverType:id<NSObject> > : NSObject

/** 
 * Initializes with an optional object for which this observer hub is used. 
 * The object will be used only for diagnostics in DEBUG.
 */
- (id)initWithObservable:(id<NSObject>)observable NS_DESIGNATED_INITIALIZER;

- (id)init NS_UNAVAILABLE;

/** YES, when no observers are added to the hub now. This is somewhat internal, but can be handy to know. */
@property (nonatomic, readonly, getter=isEmpty) BOOL empty;

/** 
 * Adds an observer and returns a token which should be used to remove it.
 * The observer is removed once the token is deallocated or token's #removeObserver method is called.
 */
 - (id<MMMObserverToken>)safeAddObserver:(ObserverType)observer;

/** 
 * Adds an observer to the hub and returns YES.
 *
 * The same observer is not allowed to be added twice; every observer must be removed before the observer
 * or the hub is deallocated.
 * Returns NO in case the above is not followed and assertions are disabled.
 */
- (BOOL)addObserver:(ObserverType)observer;

/** 
 * Removes an observer from the hub and returns YES.
 *
 * Trying to remove an object that has already been removed (or has never been installed) is considered a programmer's
 * error and will crash in DEBUG; NO is returned in case assertions are disabled.
 */
- (BOOL)removeObserver:(ObserverType)observer;

/** 
 * Runs the given block for each of the observers ensuring removals and additions of observers done meanwhile
 * are handled correctly. 
 */
- (void)forEachObserver:(void (NS_NOESCAPE ^)(ObserverType observer))block;

@end
