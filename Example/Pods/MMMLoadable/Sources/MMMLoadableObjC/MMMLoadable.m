//
// MMMLoadable. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMLoadable.h"
#import "MMMLoadable+Subclasses.h"

@import MMMCommonCore;

#pragma mark - MMMLoadable

NSString *NSStringFromMMMLoadableState(MMMLoadableState state) {
	MMM_ENUM_NAME_BEGIN(MMMLoadableState, state)
		MMM_ENUM_CASE(MMMLoadableStateIdle)
		MMM_ENUM_CASE(MMMLoadableStateSyncing)
		MMM_ENUM_CASE(MMMLoadableStateDidSyncSuccessfully)
		MMM_ENUM_CASE(MMMLoadableStateDidFailToSync)
	MMM_ENUM_NAME_END()
}

//
//
//
@interface MMMLoadable ()
@property (nonatomic, readwrite) MMMLoadableState loadableState;
@property (nonatomic, readwrite) NSError *error;
@end

@implementation MMMLoadable {
	MMMObserverHub<id<MMMLoadableObserver>> *_observerHub;
}

- (id)init {
	if (self = [super init]) {
		_observerHub = [[MMMObserverHub alloc] initWithObservable:self];
	}
	return self;
}

- (void)setLoadableState:(MMMLoadableState)loadableState {
	// Note that we do not check if the state is the same and notify the observers anyway.
	// This is handy when we are already in 'did load' state and want to communicate changes in the contents
	// happening without transitions between loadable states.
	_loadableState = loadableState;
	[self notifyDidChange];
}

- (void)setSyncing {
	self.loadableState = MMMLoadableStateSyncing;
}

- (void)setFailedToSyncWithError:(NSError *)error {
	if (_loadableState != MMMLoadableStateDidFailToSync) {
		_error = error;
		self.loadableState = MMMLoadableStateDidFailToSync;
	}
}

- (void)setDidSyncSuccessfully {
	_error = nil;
	self.loadableState = MMMLoadableStateDidSyncSuccessfully;
}

- (void)syncIfNeeded {
	if (self.needsSync)
		[self sync];
}

- (void)sync {

	if (self.loadableState == MMMLoadableStateSyncing) {
		// Syncing is in progress already, ignoring the new request
		return;
	}

	// It makes sense to reset the error to ensure it won't remain from the previous failure especially
	// in case the subclass touches `loadableState` directly instead of using `setFailedToSyncWithError:`
	// or `setDidSyncSuccessfully:`.
	_error = nil;

	self.loadableState = MMMLoadableStateSyncing;

	[self doSync];
}

#pragma mark - Overridables

- (BOOL)isContentsAvailable {
	return NO;
}

- (BOOL)needsSync {
	return !self.contentsAvailable
		|| (self.loadableState == MMMLoadableStateDidFailToSync)
		|| (self.loadableState == MMMLoadableStateIdle);
}

- (void)doSync {
	MMM_MUST_BE_IMPLEMENTED();
}

#pragma mark -

- (MMMObserverHub *)observerHub {
	return _observerHub;
}

- (BOOL)hasObservers {
	return !_observerHub.empty;
}

- (void)didAddFirstObserver {
	// Nothing to do here, but subclasses can override.
}

- (void)didRemoveLastObserver {
	// Nothing to do here, but subclasses can override.
}

- (void)addObserver:(id<MMMLoadableObserver>)observer {

	BOOL wasEmpty = [_observerHub isEmpty];

	[_observerHub addObserver:observer];

	if (wasEmpty) {
		NSAssert(![_observerHub isEmpty], @"");
		[self didAddFirstObserver];
	}
}

- (void)removeObserver:(id<MMMLoadableObserver>)observer {

	if ([_observerHub removeObserver:observer] && [_observerHub isEmpty])
		[self didRemoveLastObserver];
}

- (void)notifyDidChange {
	[_observerHub forEachObserver:^(id<MMMLoadableObserver> observer) {
		[observer loadableDidChange:self];
	}];
}

- (NSString *)debugDescription {
	return [NSString stringWithFormat:@"<%@: %p; %@, contents available: %d, needs sync: %d>",
		self.class,
		self,
		NSStringFromMMMLoadableState(self.loadableState),
		self.contentsAvailable,
		self.needsSync
	];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %@, contents available: %d, needs sync: %d>",
		self.class,
		NSStringFromMMMLoadableState(self.loadableState),
		self.contentsAvailable,
		self.needsSync
	];
}

@end

//
// Note that I don't want to inherit MMMLoadable from this class, so the implementation is duplicated.
//
@interface MMMPureLoadable ()
@property (nonatomic, readwrite) MMMLoadableState loadableState;
@property (nonatomic, readwrite) NSError *error;
@end

@implementation MMMPureLoadable {
	MMMObserverHub<id<MMMLoadableObserver>> *_observerHub;
}

- (id)init {
	if (self = [super init]) {
		_observerHub = [[MMMObserverHub alloc] initWithObservable:self];
	}
	return self;
}

- (void)setLoadableState:(MMMLoadableState)loadableState {
	// Note that we do not check if the state is the same and notify the observers anyway.
	// This is handy when we are already in 'did load' state and want to communicate changes in the contents
	// happening without transitions between loadable states.
	_loadableState = loadableState;
	[self notifyDidChange];
}

- (void)setSyncing {
	self.loadableState = MMMLoadableStateSyncing;
}

- (void)setFailedToSyncWithError:(NSError *)error {
	if (_loadableState != MMMLoadableStateDidFailToSync) {
		_error = error;
		self.loadableState = MMMLoadableStateDidFailToSync;
	}
}

- (void)setDidSyncSuccessfully {
	_error = nil;
	self.loadableState = MMMLoadableStateDidSyncSuccessfully;
}

#pragma mark - Overridables

- (BOOL)isContentsAvailable {
	return NO;
}

#pragma mark -

- (MMMObserverHub<id<MMMLoadableObserver>> *)observerHub {
	return _observerHub;
}

- (BOOL)hasObservers {
	return !_observerHub.empty;
}

- (void)didAddFirstObserver {
	// Nothing to do here, but subclasses can override.
}

- (void)didRemoveLastObserver {
	// Nothing to do here, but subclasses can override.
}

- (void)addObserver:(id<MMMLoadableObserver>)observer {

	BOOL wasEmpty = [_observerHub isEmpty];

	[_observerHub addObserver:observer];

	if (wasEmpty) {
		NSAssert(![_observerHub isEmpty], @"");
		[self didAddFirstObserver];
	}
}

- (void)removeObserver:(id<MMMLoadableObserver>)observer {

	if ([_observerHub removeObserver:observer] && [_observerHub isEmpty])
		[self didRemoveLastObserver];
}

- (void)notifyDidChange {
	[_observerHub forEachObserver:^(id<MMMLoadableObserver> observer) {
		[observer loadableDidChange:self];
	}];
}

- (NSString *)debugDescription {
	return [NSString stringWithFormat:@"<%@: %p; %@, contents available: %d>",
		self.class,
		self,
		NSStringFromMMMLoadableState(self.loadableState),
		self.contentsAvailable
	];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %@, contents available: %d>",
		self.class,
		NSStringFromMMMLoadableState(self.loadableState),
		self.contentsAvailable
	];
}

@end

//
//
//
@implementation MMMAutosyncLoadable	{
	MMMWeakProxy *_autosyncTimerProxy;
	NSTimer *_autosyncTimer;
}

- (id)init {

	if (self = [super init]) {

		#if !TARGET_OS_WATCH
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(applicationDidEnterBackground:)
			name:UIApplicationDidEnterBackgroundNotification
			object:nil
		];
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(applicationDidBecomeActive:)
			name:UIApplicationDidBecomeActiveNotification
			object:nil
		];
		#endif
	}

	return self;
}

- (void)dealloc {

	#if !TARGET_OS_WATCH
	[[NSNotificationCenter defaultCenter]
		removeObserver:self
		name:UIApplicationDidBecomeActiveNotification
		object:nil
	];

	[[NSNotificationCenter defaultCenter]
		removeObserver:self
		name:UIApplicationDidEnterBackgroundNotification
		object:nil
	];
	#endif

	[self clearAutosyncTimer];
}

#pragma mark - Autosync timer

- (NSTimeInterval)autosyncInterval {
	return 60;
}

- (NSTimeInterval)autosyncIntervalWhileInBackground {
	return -1;
}

- (void)clearAutosyncTimer {
	[_autosyncTimer invalidate];
	_autosyncTimer = nil;
	_autosyncTimerProxy = nil;
}

- (void)setupAutosyncTimer {

	[self clearAutosyncTimer];

	if (!self.hasObservers)
		return;

	#if !TARGET_OS_WATCH
	NSTimeInterval timeout;
	if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
		timeout = [self autosyncIntervalWhileInBackground];
	else
		timeout = [self autosyncInterval];
	#else
	NSTimeInterval timeout = [self autosyncInterval];
	#endif

	if (timeout <= 0)
		return;

	_autosyncTimerProxy = [[MMMWeakProxy alloc] initWithTarget:self];
	_autosyncTimer = [NSTimer
		scheduledTimerWithTimeInterval:timeout
		target:_autosyncTimerProxy
		selector:@selector(autosyncTimer)
		userInfo:nil
		repeats:NO
	];
}

- (void)autosyncTimer {
	if (self.needsSync)
		[self sync];
	else
		[self setupAutosyncTimer];
}

- (void)setLoadableState:(MMMLoadableState)loadableState {
	[super setLoadableState:loadableState];
	[self setupAutosyncTimer];
}

- (void)didAddFirstObserver {
	[self syncIfNeeded];
}

- (void)didRemoveLastObserver {
	[self setupAutosyncTimer];
}

- (void)applicationDidEnterBackground:(NSNotification *)n {
	[self clearAutosyncTimer];
}

- (void)applicationDidBecomeActive:(NSNotification *)n {
	[self syncIfNeeded];
}

@end

#pragma mark - MMMLoadableObserver

//
//
//
@interface MMMLoadableObserverBlockProxy : NSObject <MMMLoadableObserver>
@end

@implementation MMMLoadableObserverBlockProxy {
	MMMLoadableObserverDidChangeBlock _block;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %@>", self.class, _block];
}

- (id)initWithBlock:(MMMLoadableObserverDidChangeBlock)block {
	if (self = [super init]) {
		_block = block;
	}
	return self;
}

- (void)loadableDidChange:(id<MMMLoadable>)loadable {
	_block(loadable);
}

@end

//
//
//
@interface MMMLoadableObserverSelectorProxy : NSObject <MMMLoadableObserver>
@end

@implementation MMMLoadableObserverSelectorProxy {
	id<NSObject> __weak _target;
	SEL _selector;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %@#%@>", self.class, _target.class, NSStringFromSelector(_selector)];
}

- (id)initWithTarget:(id<NSObject>)target selector:(SEL)selector {

	if (self = [super init]) {
		_target = target;
		_selector = selector;
	}

	return self;
}

- (void)loadableDidChange:(id<MMMLoadable>)loadable {

	id target = _target;
	if (!target) {
		NSAssert(NO, @"A target of the observer proxy has been deallocated or the proxy was not removed");
		return;
	}

	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[target performSelector:_selector withObject:loadable];
	#pragma clang diagnostic pop
}

@end

//
//
//
@implementation MMMLoadableObserver {
	id<MMMPureLoadable> __weak _loadable;
	id<MMMLoadableObserver> _proxy;
}

- (id)initWithLoadable:(id<MMMPureLoadable>)loadable proxy:(id<MMMLoadableObserver>)proxy {

	// Short-circuit to nil in case the client tries to subscribe to already nil loadable.
	if (!loadable)
		return nil;

	if (self = [super init]) {

		_loadable = loadable;
		_proxy = proxy;

		[_loadable addObserver:_proxy];
	}

	return self;
}

- (nullable id)initWithLoadable:(nullable id<MMMPureLoadable>)loadable block:(MMMLoadableObserverDidChangeBlock)block {
	
	if (loadable) {
		return [self
			initWithLoadable:loadable
			proxy:[[MMMLoadableObserverBlockProxy alloc] initWithBlock:block]
		];
	}
	
	return nil;
}

- (nullable id)initWithLoadable:(nullable id<MMMPureLoadable>)loadable target:(id<NSObject>)target selector:(SEL)selector {
	
	if (loadable) {
		return [self
			initWithLoadable:loadable
			proxy:[[MMMLoadableObserverSelectorProxy alloc] initWithTarget:target selector:selector]
		];
	}
	
	return nil;
}

- (id)initWithLoadable:(id<MMMLoadable>)loadable observer:(id<MMMLoadableObserver>)observer {
	return [self initWithLoadable:loadable proxy:observer];
}

- (void)dealloc {
	// Ensure it's removed from the list of observers when deallocated
	[self remove];
}

- (void)remove {
	if (_loadable) {
		[_loadable removeObserver:_proxy];
		_loadable = nil;
	}
}

@end

//
//
//
@interface MMMPureLoadableGroup ()
@property (nonatomic, readwrite) NSArray<id<MMMPureLoadable>> *loadables;
@end

@implementation MMMPureLoadableGroup {
	MMMObserverHub<id<MMMLoadableObserver>> *_observerHub;
	MMMLoadableObserverSelectorProxy *_observerProxy;
	MMMLoadableGroupFailurePolicy _failurePolicy;
}

@synthesize loadables = _loadables;
@synthesize contentsAvailable = _contentsAvailable;
@synthesize loadableState = _loadableState;

- (id)initWithLoadables:(NSArray *)loadables failurePolicy:(MMMLoadableGroupFailurePolicy)failurePolicy {

	if (self = [super init]) {

		_failurePolicy = failurePolicy;

		// We don't want our subclasses to override our `loadableDidChange:` so we don't subscribe directly.
		_observerProxy = [[MMMLoadableObserverSelectorProxy alloc]
			initWithTarget:self
			selector:@selector(MMMPureLoadableGroup_loadableDidChange:)
		];

		_observerHub = [[MMMObserverHub alloc] initWithObservable:self];
        
		[self setLoadables:loadables];
	}

	return self;
}

- (id)initWithLoadables:(nullable NSArray<id<MMMPureLoadable>> *)loadables {
	return [self initWithLoadables:loadables failurePolicy:MMMLoadableGroupFailurePolicyStrict];
}

- (void)dealloc {
	// It is tempting to call setLoadables:nil, but this can trigger 'did change' when we don't really want it.
	for (id<MMMLoadable> loadable in _loadables) {
		[loadable removeObserver:_observerProxy];
	}
	_loadables = nil;
}

- (void)setLoadables:(NSArray *)loadables {

	for (id<MMMLoadable> loadable in _loadables) {
		[loadable removeObserver:_observerProxy];
	}

	_loadables = loadables;
	for (id<MMMLoadable> loadable in _loadables) {
		[loadable addObserver:_observerProxy];
	}

	[self updateState];
}

- (NSError *)error {

	// OK, let's use the error of the first failed object.
	for (id<MMMLoadable> l in _loadables) {
		if (l.loadableState == MMMLoadableStateDidFailToSync && l.error != nil) {
			return [NSError
				mmm_errorWithDomain:NSStringFromClass(self.class)
				message:[NSString stringWithFormat:@"Could not sync %@", l]
				underlyingError:l.error
			];
		}
	}

	return nil;
}

- (void)MMMPureLoadableGroup_loadableDidChange:(id<MMMPureLoadable>)loadable {
	[self updateState];
}

- (void)updateState {

	NSInteger failedCount = 0;
	NSInteger syncedCount = 0;
	NSInteger syncingCount = 0;
	for (id<MMMLoadable> loadable in _loadables) {
        switch (_failurePolicy) {
            case MMMLoadableGroupFailurePolicyStrict:
                if (loadable.loadableState == MMMLoadableStateDidFailToSync) {
                    failedCount++;
                } else if (loadable.loadableState == MMMLoadableStateDidSyncSuccessfully) {
                    syncedCount++;
                } else if (loadable.loadableState == MMMLoadableStateSyncing) {
                    syncingCount++;
                }
                break;
                
            case MMMLoadableGroupFailurePolicyNever:
                if (loadable.loadableState == MMMLoadableStateDidFailToSync 
					|| loadable.loadableState == MMMLoadableStateDidSyncSuccessfully
				) {
                    syncedCount++;
                } else if (loadable.loadableState == MMMLoadableStateSyncing) {
                    syncingCount++;
                }
                break;
        }
	}

	BOOL newContentsAvailable;
	if (_loadables.count == 0) {
		// Assuming no content in case the group is empty.
		// This way initializing the group with an empty array (something we do for convenience before setting the actual array)
		// won't lead to a useless 'did change' notification.
		newContentsAvailable = NO;
	} else {
	 	newContentsAvailable = YES;
		for (id<MMMLoadable> loadable in _loadables) {
			if (![loadable isContentsAvailable]) {
				newContentsAvailable = NO;
				break;
			}
		}
	}

	MMMLoadableState newLoadableState;
	if (failedCount > 0) {
		newLoadableState = MMMLoadableStateDidFailToSync;
	} else if (syncingCount > 0) {
		newLoadableState = MMMLoadableStateSyncing;
	} else if (syncedCount > 0 && syncedCount == _loadables.count) {
		newLoadableState = MMMLoadableStateDidSyncSuccessfully;
	} else {
		// Again, avoiding 'did sync' for empty groups, preferring 'idle'.
		// Same reason as for 'contentsAvailable' in the above.
		newLoadableState = MMMLoadableStateIdle;
	}

	// Not checking for the change in contentsAvailable when notifying because by our contract
	// it changes together with the state.
	// We are not propagating 'did change' notifications without the state change unless the common state
	// is 'did sync successfully', which means that the content properties (value of the promise) could have
	// changed without state transitions)
	if (newLoadableState != _loadableState
		|| newLoadableState == MMMLoadableStateDidSyncSuccessfully
	) {
		_contentsAvailable = newContentsAvailable;
		_loadableState = newLoadableState;

		[self groupDidChange];

		[self notifyDidChange];
	}
}

- (void)addObserver:(id<MMMLoadableObserver>)observer {
	[_observerHub addObserver:observer];
}

- (void)removeObserver:(id<MMMLoadableObserver>)observer {
	[_observerHub removeObserver:observer];
}

- (void)groupDidChange {
	// This can be overriden in the subclasses of the group.
}

- (void)notifyDidChange {
	[_observerHub forEachObserver:^(id<MMMLoadableObserver> observer) {
		[observer loadableDidChange:self];
	}];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %@, contents available: %d>",
		self.class,
		NSStringFromMMMLoadableState(self.loadableState),
		self.contentsAvailable
	];
}

@end

//
//
//
@implementation MMMLoadableGroup

- (id)initWithLoadables:(NSArray<id<MMMLoadable>> *)loadables failurePolicy:(MMMLoadableGroupFailurePolicy)failurePolicy {
	return [super initWithLoadables:loadables failurePolicy:failurePolicy];
}

- (id)initWithLoadables:(nullable NSArray<id<MMMPureLoadable>> *)loadables {
	return [self initWithLoadables:loadables failurePolicy:MMMLoadableGroupFailurePolicyStrict];
}

- (void)setLoadables:(NSArray<id<MMMLoadable>> *)loadables {

	[super setLoadables:loadables];

	for (id<MMMLoadable> loadable in self.loadables) {
		NSAssert(
			[loadable conformsToProtocol:@protocol(MMMPureLoadable)],
			@"All objects in %@ must conform at least to %@", self.class, @protocol(MMMLoadable)
		);
	}
}

- (BOOL)needsSync {

	for (id<MMMLoadable> loadable in self.loadables) {
		if ([loadable conformsToProtocol:@protocol(MMMLoadable)] && [loadable needsSync]) {
			return YES;
		}
	}

	return NO;
}

- (void)sync {
	for (id<MMMLoadable> loadable in self.loadables) {
		if ([loadable conformsToProtocol:@protocol(MMMLoadable)]) {
			[loadable sync];
		}
	}
}

- (void)syncIfNeeded {
	for (id<MMMLoadable> loadable in self.loadables) {
		if ([loadable conformsToProtocol:@protocol(MMMLoadable)]) {
			[loadable syncIfNeeded];
		}
	}
}

@end

//
//
//
@interface MMMPureLoadableProxy () <MMMLoadableObserver>
@end

@implementation MMMPureLoadableProxy

- (void)dealloc {
	[_loadable removeObserver:self];
}

- (BOOL)isContentsAvailable {
	return _loadable ? _loadable.contentsAvailable : NO;
}

- (MMMLoadableState)loadableState {
	return _loadable ? _loadable.loadableState : super.loadableState;
}

- (NSError *)error {
	return _loadable ? _loadable.error : nil;
}

- (void)setLoadable:(id<MMMLoadable>)l {

	[_loadable removeObserver:self];

	_loadable = l;
	[_loadable addObserver:self];

	// We need to reset our loadable state only when the proxied object is removed (not sure if it's the actual use case).
	// But resetting it also triggers a notification and that's what we need in any case.
	super.loadableState = MMMLoadableStateIdle;
}

- (void)proxyDidChange {
}

- (void)notifyDidChange {
	[self proxyDidChange];
	[super notifyDidChange];
}

- (void)loadableDidChange:(id<MMMPureLoadable>)loadable {
	[self notifyDidChange];
}

@end

//
// Note that I did not want to bother with inheritance from MMMPureLoadableProxy in this case.
//
@interface MMMLoadableProxy () <MMMLoadableObserver>
@end

@implementation MMMLoadableProxy

- (void)dealloc {
	[_loadable removeObserver:self];
}

- (BOOL)isContentsAvailable {
	return _loadable ? _loadable.contentsAvailable : NO;
}

- (MMMLoadableState)loadableState {
	return _loadable ? _loadable.loadableState : super.loadableState;
}

- (NSError *)error {
	return _loadable ? _loadable.error : nil;
}

- (void)setLoadable:(id<MMMLoadable>)l {

	[_loadable removeObserver:self];

	_loadable = l;

	// If the user has asked as to sync before the actual object was set, then we need make the actual object syncing too.
	if (super.loadableState == MMMLoadableStateSyncing) {
		[self.loadable syncIfNeeded];
	}

	// And adding our observer after requesting sync, so we skip the first notification if any.
	[_loadable addObserver:self];

	// We need to reset our loadable state only when the proxied object is removed (not sure if it's the actual use case).
	// But resetting it also triggers a notification and that's what we need in any case.
	super.loadableState = MMMLoadableStateIdle;
}

- (void)proxyDidChange {
}

- (void)notifyDidChange {
	[self proxyDidChange];
	[super notifyDidChange];
}

- (void)loadableDidChange:(id<MMMPureLoadable>)loadable {
	[self notifyDidChange];
}

- (BOOL)needsSync {
	return self.loadable ? self.loadable.needsSync : YES;
}

-(void)syncIfNeeded {
	[self.loadable syncIfNeeded];
}

- (void)doSync {
	[self.loadable sync];
}

@end

//
//
//
@implementation MMMTestLoadable {
	MMMObserverHub<id<MMMLoadableObserver>> *_observerHub;
}

@synthesize loadableState = _loadableState;

- (id)init {
	if (self = [super init]) {
		_observerHub = [[MMMObserverHub alloc] initWithObservable:self];
	}
	return self;
}

- (BOOL)needsSync {
	// Let's have the default implementation the same as in the base MMMLoadable.
	// TODO: should we allow to override this from the outside?
	return !self.contentsAvailable || (self.loadableState == MMMLoadableStateDidFailToSync) || (self.loadableState == MMMLoadableStateIdle);
}

- (void)syncIfNeeded {

	_syncIfNeededCounter++;

	if ([self needsSync]) {
		[self sync];
	}
}

- (void)doSync {
	// Don't have to do anything here, subclasses might override this.
}

- (void)sync {

	_syncCounter++;

	if (self.loadableState == MMMLoadableStateSyncing)
		return;

	[self setSyncing];

	[self doSync];
}

- (BOOL)isContentsAvailable {
	_isContentsAvailableCounter++;
	return _contentsAvailable;
}

- (void)resetAllCallCounters {
	_syncIfNeededCounter = 0;
	_syncCounter = 0;
	_isContentsAvailableCounter = 0;
}

- (void)setLoadableState:(MMMLoadableState)loadableState {
	_loadableState = loadableState;
	[self notifyDidChange];
}

- (void)setIdle {
	self.loadableState = MMMLoadableStateIdle;
}

- (void)setSyncing {
	self.loadableState = MMMLoadableStateSyncing;
}

- (void)setDidSyncSuccessfully {
	_contentsAvailable = YES;
	self.loadableState = MMMLoadableStateDidSyncSuccessfully;
}

- (void)setDidFailToSyncWithError:(NSError *)error {
	self.error = error;
	self.loadableState = MMMLoadableStateDidFailToSync;
}

#pragma mark -

- (BOOL)hasObservers {
	return !_observerHub.empty;
}

- (void)notifyDidChange {
	[_observerHub forEachObserver:^(id<MMMLoadableObserver> observer) {
		[observer loadableDidChange:self];
	}];
}

- (void)addObserver:(id<MMMLoadableObserver>)observer {
	_addObserverCounter++;
	[_observerHub addObserver:observer];
}

- (void)removeObserver:(id<MMMLoadableObserver>)observer {
	_removeObserverCounter--;
	[_observerHub removeObserver:observer];
}

@end

