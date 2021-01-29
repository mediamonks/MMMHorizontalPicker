//
// MMMTemple.
// Copyright (C) 2015-2020 MediaMonks. All rights reserved.
//

#import "MMMNavigationStack.h"

@import MMMLog;

@class MMMNavigationStack_Item;

/** 
 * This is what we actually store for each node of the current navigation path. 
 */
@interface MMMNavigationStack_Entry : NSObject

/** This is set to nil as well when the entry is removed from the stack. */
@property(nonatomic, readonly, weak) MMMNavigationStack *parent;

/** Internal/diagnostics name of the navigation item. */
@property(nonatomic, readonly) NSString *name;

@property(nonatomic, readonly, weak) id<MMMNavigationStackItemDelegate> delegate;

@property(nonatomic, readonly, weak) id controller;

/** A link back to the token object used to access this entry from the outside. */
@property(nonatomic, readwrite, weak) MMMNavigationStack_Item *item;

/** The index of the entry in the stack. This is redundant, used only for convenience here. */
@property(nonatomic, readwrite) NSInteger depth;

/** Marks the entry as removed from the stack by settings its parent to nil. */
- (void)markAsRemoved;

/** YES, if the entry has no parent, i.e. was removed from the stack. */
@property (nonatomic, readonly, getter=isRemoved) BOOL removed;

- (id)initWithParent:(MMMNavigationStack *)parent
	name:(NSString *)name
	delegate:(id<MMMNavigationStackItemDelegate>)delegate
	controller:(id)controller
	depth:(NSInteger)depth NS_DESIGNATED_INITIALIZER;

- (id)init NS_UNAVAILABLE;

@end

@implementation MMMNavigationStack_Entry

- (id)initWithParent:(MMMNavigationStack *)parent
	name:(NSString *)name
	delegate:(id<MMMNavigationStackItemDelegate>)delegate
	controller:(id)controller
	depth:(NSInteger)depth
{
	if (self = [super init]) {
		_parent = parent;
		_name = [name copy];
		_delegate = delegate;
		_controller = controller;
		_depth = depth;
	}
	return self;
}

- (NSString *)debugDescription {
	return [NSString stringWithFormat:@"<%@:%p '%@' (%@, presented by %@)>", self.class, self, _name, _controller, _delegate];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"'%@' (%@ via %@)", _name, [_controller class], [_delegate class]];
}

- (void)markAsRemoved {
	_parent = nil;
}

- (BOOL)isRemoved {
	return _parent != nil;
}

@end

//
// Methods MMMNavigationStackItem is allowed to call.
//
@interface MMMNavigationStack ()
- (void)didDeallocItemForEntry:(MMMNavigationStack_Entry *)entry;
- (void)didPopEntry:(MMMNavigationStack_Entry *)entry successfully:(BOOL)successfully;
- (BOOL)popToEntry:(MMMNavigationStack_Entry *)entry completion:(MMMNavigationStackCompletion)completion;
@end

/** 
 * And this is a token object that is returned to the called when an item is pushed. 
 */
@interface MMMNavigationStack_Item : NSObject <MMMNavigationStackItem>

@property (nonatomic, readonly) MMMNavigationStack_Entry *entry;

- (id)initWithEntry:(MMMNavigationStack_Entry *)entry NS_DESIGNATED_INITIALIZER;

- (id)init NS_UNAVAILABLE;

@end

//
//
//
@implementation MMMNavigationStack_Item

- (nonnull id)initWithEntry:(MMMNavigationStack_Entry *)entry {
	if (self = [super init]) {
		_entry = entry;
	}
	return self;
}

- (void)dealloc {
	[_entry.parent didDeallocItemForEntry:_entry];
}

- (void)didPop {
	[_entry.parent didPopEntry:_entry successfully:YES];
}

- (void)didFailToPop {
	[_entry.parent didPopEntry:_entry successfully:NO];
}

- (BOOL)popAllAfterThisItemWithCompletion:(MMMNavigationStackCompletion)completion {
	return [_entry.parent popToEntry:_entry completion:completion];
}

@end

/** 
 * We allow multiple simultaneous pop requests, so we store all of them. 
 */
@interface MMMNavigationStack_PopRequest : NSObject

@property (nonatomic, readonly, weak) MMMNavigationStack_Entry *entry;

@property (nonatomic, readonly) MMMNavigationStackCompletion completion;

- (nonnull id)initWithEntry:(MMMNavigationStack_Entry *)entry completion:(MMMNavigationStackCompletion)completion NS_DESIGNATED_INITIALIZER;

- (nonnull id)init NS_UNAVAILABLE;

@end

@implementation MMMNavigationStack_PopRequest

- (nonnull id)initWithEntry:(MMMNavigationStack_Entry *)entry completion:(MMMNavigationStackCompletion)completion {
	if (self = [super init]) {
		_entry = entry;
		_completion = completion;
	}
	return self;
}

@end

//
//
//
typedef NS_ENUM(NSInteger, MMMNavigationStackState) {
	MMMNavigationStackStateIdle,
	MMMNavigationStackStatePopping
};

//
//
//
@implementation MMMNavigationStack {

	MMMNavigationStackState _state;

	NSMutableArray<MMMNavigationStack_Entry *> *_entries;

	// Pending pop requests.
	NSMutableArray<MMMNavigationStack_PopRequest *> *_popRequests;

	// Pop requests that were satisfied, but not yet completed.
	NSMutableArray<MMMNavigationStack_PopRequest *> *_completedPopRequests;

	MMMNavigationStack_Entry *_poppingNow;
}

+ (nonnull instancetype)shared {
	static MMMNavigationStack *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[MMMNavigationStack alloc] init];
	});
	return shared;
}

- (nonnull id)init {
	if (self = [super init]) {
		_entries = [[NSMutableArray alloc] init];
		_popRequests = [[NSMutableArray alloc] init];
		_completedPopRequests = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)entriesDidChange {
	#if DEBUG
	NSMutableArray *names = [[NSMutableArray alloc] init];
	for (MMMNavigationStack_Entry *entry in _entries) {
		[names addObject:[NSString stringWithFormat:@"'%@'", entry.name]];
	}
	MMM_LOG_TRACE(@"%@", names.count == 0 ? @"<empty>" : [names componentsJoinedByString:@" -> "]);
	#endif
}

- (id<MMMNavigationStackItem>)pushItemWithName:(NSString *)name delegate:(id<MMMNavigationStackItemDelegate>)delegate {
	return [self pushItemWithName:name delegate:delegate controller:nil];
}

- (id<MMMNavigationStackItem>)pushItemWithName:(NSString *)name delegate:(id<MMMNavigationStackItemDelegate>)delegate controller:(id)controller {

	@synchronized (self) {

		MMMNavigationStack_Entry *entry = [[MMMNavigationStack_Entry alloc]
			initWithParent:self
			name:name
			delegate:delegate
			controller:controller
			depth:[_entries count]
		];
		if (_state != MMMNavigationStackStateIdle) {
			MMM_LOG_ERROR(@"Unable to push %@ into the navigation stack. Is \"popping\" in progress at the moment?", entry);
			NSAssert(NO, @"");
			return nil;
		}

		MMMNavigationStack_Item *item = [[MMMNavigationStack_Item alloc] initWithEntry:entry];		
		entry.item = item;

		MMM_LOG_TRACE(@"Pushing %@", entry);
		[_entries addObject:entry];
		[self entriesDidChange];

		return item;
	}
}

- (BOOL)controller:(UIViewController *)controller isAnscestorOf:(UIViewController *)child {

	if (![child isKindOfClass:[UIViewController class]]) {
		return controller == child;
	}

	UIViewController *c = child;
	while (c) {
		if (c == controller)
			return YES;
		c = c.parentViewController;
	}

	return NO;
}

- (BOOL)popAllAfterController:(id)controller completion:(MMMNavigationStackCompletion)completion {

	for (NSInteger i = _entries.count - 1; i >= 0; i--) {
		MMMNavigationStack_Entry *e = _entries[i];
		if ([self controller:e.controller isAnscestorOf:controller]) {
			[e.item popAllAfterThisItemWithCompletion:completion];
			return YES;
		}
	}

	if (completion)
		completion(NO);
	
	return NO;
}

- (void)didDeallocItemForEntry:(MMMNavigationStack_Entry *)entry {

	if (!entry.removed) {
		MMM_LOG_TRACE(@"Warning: the entry %@ is considered popped because the corresponding item was deallocated", entry);
		[self didPopEntry:entry successfully:YES];
	}
}

- (void)didPopEntry:(MMMNavigationStack_Entry *)entry successfully:(BOOL)successfuly {

	if (!successfuly) {

		MMM_LOG_TRACE(@"Could not pop %@, failing all pop requests", entry);

		for (MMMNavigationStack_PopRequest *r in _popRequests) {
			[_completedPopRequests addObject:r];
		}

		[_popRequests removeAllObjects];
		[self didFinishPoppingAllSuccessfully:NO];

		return;
	}

	if ([_entries lastObject] == entry) {

		MMM_LOG_TRACE(@"Popped %@", entry);
		[_entries removeLastObject];
		[entry markAsRemoved];
		[self entriesDidChange];

	} else {

		NSInteger index = [_entries indexOfObjectIdenticalTo:entry];
		if (index == NSNotFound) {

			MMM_LOG_ERROR(@"Popped %@ which was not in the stack, ignoring", entry);

		} else {

			//
			// The popping can happen even with items in the middle of the stack.
			//

			MMM_LOG_TRACE(@"Popped %@ from the middle of the stack", entry);
			[_entries removeObjectAtIndex:index];
			[entry markAsRemoved];
			[self entriesDidChange];

			// Need to correct the depth of the remaining entries, but there is no need in sorting the pop requests.
			for (NSInteger i = index; i < _entries.count; i++) {
				MMMNavigationStack_Entry *e = _entries[i];
				e.depth = e.depth - 1;
			}
		}
	}

	[self resumePoppingLater];
}

- (void)resumePoppingLater {

	if (_popRequests.count == 0) {
		// No need to check what can be popped as we don't have any pop requests.
		return;
	}

	dispatch_async(dispatch_get_main_queue(), ^{
		[self resumePopping];
	});
}

- (void)sortPopRequests {
	[_popRequests sortUsingComparator:^NSComparisonResult(MMMNavigationStack_PopRequest *obj1, MMMNavigationStack_PopRequest *obj2) {
		return (obj1.entry.depth < obj2.entry.depth) ? NSOrderedAscending : NSOrderedDescending;
	}];
}

- (BOOL)popToEntry:(MMMNavigationStack_Entry *)entry completion:(MMMNavigationStackCompletion)completion {

	@synchronized (self) {

		if (entry.parent != self) {
			NSAssert(NO, @"Trying to pop to the item which is not in the navigation stack?");
			return NO;
		}

		MMMNavigationStack_PopRequest *request = [[MMMNavigationStack_PopRequest alloc] initWithEntry:entry completion:completion];
		[_popRequests addObject:request];
		[self sortPopRequests];

		if (_state == MMMNavigationStackStatePopping) {
			MMM_LOG_TRACE(@"Popping everything before %@ as well", entry);
		} else {
			MMM_LOG_TRACE(@"Popping everything before %@", entry);
		}
		_state = MMMNavigationStackStatePopping;

		[self resumePoppingLater];

		return YES;
	}
}

- (void)didFinishPoppingAllSuccessfully:(BOOL)successfully {

	// All pop requests completed. Let's call completion handlers.
	NSArray *completed = [_completedPopRequests copy];
	[_completedPopRequests removeAllObjects];

	_state = MMMNavigationStackStateIdle;

	for (MMMNavigationStack_PopRequest *r in completed) {
		r.completion(YES);
	}
}

- (void)resumePopping {

	MMMNavigationStack_Entry *top = [_entries lastObject];
	if (!top) {
		_state = MMMNavigationStackStateIdle;
		return;
	}

	// First check if we've popped far enough for some of the pop requests.
	// Note that the requests are sorted by depth of the corresponding entry.
	while ([_popRequests count] > 0) {

		MMMNavigationStack_PopRequest *r = [_popRequests lastObject];
		if (r.entry != top) {
			// OK, no sense to check other requests, they should be connected with even less deeper entries.
			break;
		}

		MMM_LOG_TRACE(@"Done popping everything before %@", r.entry);
		[_completedPopRequests addObject:r];
		[_popRequests removeLastObject];
	}

	if ([_popRequests count] > 0) {

		// There is at least one pop request with the target below the current top, continue popping.
		MMM_LOG_TRACE(@"Asking %@ to pop", top);
		_poppingNow = top;
		[_poppingNow.delegate popNavigationStackItem:_poppingNow.item];

	} else {

		//~ MM_LOG_TRACE(@"Done popping navigation items");

		[self didFinishPoppingAllSuccessfully:YES];
	}
}

@end
