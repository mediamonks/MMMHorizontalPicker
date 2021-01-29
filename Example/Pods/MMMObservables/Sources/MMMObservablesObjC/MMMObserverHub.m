//
// MMMObservables. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMObserverHub.h"

#ifdef DEBUG
#define MMM_OBSERVER_HUB_DIAGNOSTICS 1
#else
#define MMM_OBSERVER_HUB_DIAGNOSTICS 0
#endif

/**
 * A record about a single observer. 
 * We could wrap each observer reference into an NSValue, but being able to store a bit more info can be useful
 * for diagnostics at least.
 */
@interface MMMObserverHubEntry : NSObject

@property (nonatomic, weak, readonly) id<NSObject> observer;

/** This is used for comparison when the weak reference above is nullified. It is a valid case when an object is being
 * destructed and has already nullified all the weak references to it but needs to remove itself from observer hubs.
 * Note that using unsafe_unretained id here as we did before does not prevent the compiler to trying to retain it
 * when comparing to the observer reference to be removed.
 */
@property (nonatomic, readonly) void *unsafeObserver;

#if MMM_OBSERVER_HUB_DIAGNOSTICS
/** A description of the observer we capture when an entry is created to be able to show some diagnostics 
 * when the observer weak reference is gone. */
@property (nonatomic, readonly) NSString *debugContext;
#endif

- (id)initWithObserver:(id<NSObject>)observer NS_DESIGNATED_INITIALIZER;

- (id)init NS_UNAVAILABLE;

@end

@implementation MMMObserverHubEntry

- (id)initWithObserver:(id<NSObject>)observer {

	if (self = [super init]) {

		_observer = observer;
		_unsafeObserver = (__bridge void *)observer;

		#if MMM_OBSERVER_HUB_DIAGNOSTICS
		_debugContext = NSStringFromClass(observer.class);
		#endif
	}

	return self;
}

- (NSUInteger)hash {
	return (NSUInteger)_observer;
}

- (BOOL)isEqual:(MMMObserverHubEntry *)entry {

	if (![entry isKindOfClass:self.class])
		return NO;

	return (self.observer == entry.observer);
}

- (NSString *)description {
	#if MMM_OBSERVER_HUB_DIAGNOSTICS
	if (_observer)
		return [NSString stringWithFormat:@"<%@: -> %@>", self.class, _debugContext];
	else
		return [NSString stringWithFormat:@"<%@: -> deallocated %@>", self.class, _debugContext];
	#else
	return [NSString stringWithFormat:@"<%@: -> %@>", self.class, _observer];
	#endif
}

@end

//
//
//
@interface MMMObserverHub ()

/** Called from MMMObserverHubToken to remove the observer. */
- (void)removeEntry:(MMMObserverHubEntry *)entry;

@end

/** 
 * An object returned by a 'safe' version of addObserver. 
 * Removes the entry associated with the token when deallocated or when removeObserver is called.
 */
@interface MMMObserverHubToken : NSObject <MMMObserverToken>

- (id)initWithHub:(MMMObserverHub *)hub entry:(MMMObserverHubEntry *)entry;

@end

@implementation MMMObserverHubToken {
	MMMObserverHub * __weak _hub;
	MMMObserverHubEntry * __weak _entry;
}

- (id)initWithHub:(MMMObserverHub *)hub entry:(MMMObserverHubEntry *)entry {
	if (self = [super init]) {
		_hub = hub;
		_entry = entry;
	}
	return self;
}

- (void)dealloc {
	[self removeObserver];
}

- (void)removeObserver {
	MMMObserverHub *hub = _hub;
	MMMObserverHubEntry *entry = _entry;
	if (hub && entry) {
		_hub = nil;
		_entry = nil;
		[hub removeEntry:entry];
	}
}

@end

//
//
//
@implementation MMMObserverHub {

	#if MMM_OBSERVER_HUB_DIAGNOSTICS
	// We use this for nicer diagnostic messages only
	Class _observableClass;
	#endif

	// This is an array of observers used normally
	NSMutableArray *_entries;

	// And this one is where additions or removals are done while the hub is within forEachObserver:
	NSMutableArray *_shadowEntries;

	// Greater than zero if we are inside of forEachObserver: now
	NSInteger _notifyingCount;
}

#if MMM_OBSERVER_HUB_DIAGNOSTICS

- (NSString *)debugDescription {
	return [NSString stringWithFormat:@"<%@: %@, entries: %@>", self.class, _observableClass, _entries];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %@>", self.class, _observableClass];
}

#endif

- (id)init {
	NSAssert(NO, @"%s is not a designated initializer for %@", sel_getName(_cmd), self.class); 
	return [self initWithObservable:nil];
}

- (id)initWithObservable:(id<NSObject>)observable {

	if (self = [super init]) {

		#if MMM_OBSERVER_HUB_DIAGNOSTICS
		_observableClass = observable.class;
		#endif

		// The array of entries is lazily created in effectiveEntries
	}

	return self;
}

- (void)dealloc {
/*!
	NSAssert(
		_shadowEntries == 0 && _notifyingCount == 0,
		@"The observer hub deallocated while going through observers: %@", [self debugDescription]
	);
	NSAssert(
		_entries.count == 0,
		@"Not all observers have been removed: %@", [self debugDescription]
	);
*/
}

/** 
 * An array of entries that is OK to modify now.
 * This is the normal entries array most of the time, but can be its shadow copy when we are notifying the observers.
 */
- (NSMutableArray *)effectiveEntries {

	if (!_entries)
		_entries = [[NSMutableArray alloc] init];

	if (_notifyingCount == 0)
		return _entries;

	// OK, a rare case when we are notifying the observers now, but need to add or remove something.
	// It's easy to do such edits on a copy of the original entries array, so return it.

	if (!_shadowEntries)
		_shadowEntries = [[NSMutableArray alloc] initWithArray:_entries];

	return _shadowEntries;
}

- (MMMObserverHubEntry *)_addObserver:(id<NSObject>)observer {

	if (observer == nil) {
		NSAssert(NO, @"Trying to install a nil observer in %@", self);
		return nil;
	}

	NSMutableArray *entries = [self effectiveEntries];

	MMMObserverHubEntry *entry = [[MMMObserverHubEntry alloc] initWithObserver:observer];

	// We consider this an error if the same observer is added more than once.
	// Of course it can happen that an object installs itself as on observer without knowing that it has installed itself
	// before in the superclass, for example. It's not a good situation anyway as observer's methods can be called
	// more than once. It can be prevented by always using new proxy objects as observers, so observers are always unique.
	// Still IMO it can happen more often that observers are added twice because they have not been removed first,
	// so it's better to signal this as error asap.
	NSAssert(
		[entries indexOfObject:entry] == NSNotFound,
		@"Trying to install the same observer more than once in %@: %@", self, observer
	);

	[entries addObject:entry];

	return entry;
}

- (BOOL)addObserver:(id<NSObject>)observer {
	return [self _addObserver:observer] != nil;
}

- (id<MMMObserverToken>)safeAddObserver:(id<NSObject>)observer {
	MMMObserverHubEntry *entry = [self _addObserver:observer];
	return entry ? [[MMMObserverHubToken alloc] initWithHub:self entry:entry] : nil;
}

- (BOOL)removeObserver:(id<NSObject>)observer {

	NSAssert(observer != nil, @"Trying to remove a nil observer in %@", self);

	NSMutableArray *entries = [self effectiveEntries];
	for (NSInteger i = 0; i < entries.count; i++) {

		MMMObserverHubEntry *entry = entries[i];

		// Here we are trying to use unsafeObserver only when the weak reference is gone, which can legitimitly happen
		// when removeObserver is called from the observer's dealloc.
		if ((!entry.observer && entry.unsafeObserver == (__bridge void *)observer)
			|| (entry.observer == observer))
		{
			[entries removeObjectAtIndex:i];
			return YES;
		}
	}

	NSAssert(NO, @"Trying to remove an object that has been removed already or has not been added in %@", self);
	return NO;
}

- (void)removeEntry:(MMMObserverHubEntry *)entry {

	if (!entry)
		return;

	NSMutableArray *entries = [self effectiveEntries];

	NSAssert([entries indexOfObjectIdenticalTo:entry] != NSNotFound, @"Trying to remove an observer %@ which was not installed in %@", entry, self);

	[entries removeObjectIdenticalTo:entry];
}

- (void)forEachObserver:(void (NS_NOESCAPE^)(id<NSObject> observer))block {

	_notifyingCount++;

	// Performing notifications while within a notification loop already is possible,
	// but can lead to unwanted results in certain cases.
	// Imagine we have two observers with didStart and didEnd methods and when we are notifying observer 1 about
	// didStart it causes somehow a notification about didEnd. We start notifying observer 1 and 2 about didEnd,
	// but observer 2 has not seen the notification about didStart yet, which can be a problem.
	// Cases like this can be resolved by queuing notifications instead of sending them directly,
	// but this is something the user of the class should take care of, here we simly crash early.
	NSAssert(
		_notifyingCount <= 1,
		@"Nesting calls to %s is possible in principle, but might lead to unexpected results. Enqueue them instead.",
		sel_getName(_cmd)
	);

	for (MMMObserverHubEntry *entry in _entries) {

		id<NSObject> observer = entry.observer;
		if (observer) {

			// We don't want to call an observer on this iteration in a rare case when it has been removed
			// while we were notifying them. Shadow entries are not nil only when something was added
			// or removed while we were going through this loop, so relatively expensive search there
			// is performed only when needed.
			if (_shadowEntries && [_shadowEntries indexOfObjectIdenticalTo:entry] == NSNotFound)
				continue;

			block(observer);

		} else {
			//! NSAssert(NO, @"An observer has been deallocated but not removed from %@: %@", self, entry);
		}
	}

	if (--_notifyingCount == 0) {

		// When we are done notifying we can update the array of entries with the changed ones.
		if (_shadowEntries) {
			_entries = _shadowEntries;
			_shadowEntries = nil;
		}

	}
}

- (BOOL)isEmpty {
	return [self effectiveEntries].count == 0;
}

@end
