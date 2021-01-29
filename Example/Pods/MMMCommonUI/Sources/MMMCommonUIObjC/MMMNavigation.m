//
// MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMNavigation.h"

@import MMMLog;

//
//
//
@implementation MMMNavigationHop

- (nonnull id)initWithAction:(NSString *)action {
	return [self initWithAction:action params:nil];
}

- (nonnull id)initWithAction:(NSString *)action params:(NSDictionary *)params {
	if (self = [super init]) {
		_action = [action copy];
		_params = [params copy];
	}
	return self;
}

- (BOOL)isEqual:(MMMNavigationHop *)other {

	if (![other isKindOfClass:[MMMNavigationHop class]])
		return NO;

	if (![self.action isEqual:other.action])
		return NO;

	if (self.params && ![self.params isEqual:other.params])
		return NO;

	return YES;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: '%@' (%@)>", self.class, _action, _params];
}

@end

//
//
//
@implementation MMMNavigationPath

- (nonnull id)initWithURI:(NSString *)uri {

	NSArray *actions = [uri componentsSeparatedByString:@"/"];
	NSMutableArray *hops = [[NSMutableArray alloc] init];
	for (NSString *action in actions) {
		MMMNavigationHop *hop = [[MMMNavigationHop alloc] initWithAction:action];
		[hops addObject:hop];
	}

	return [self initWithHops:hops];
}

- (nonnull id)initWithHops:(NSArray<MMMNavigationHop *> *)hops {

	if (self = [super init]) {
		_hops = hops ? hops : @[];
	}

	return self;
}

- (MMMNavigationPath *)pathWithoutFirstHop {

	if ([self.hops count] == 0)
		return self;

	return [[MMMNavigationPath alloc] initWithHops:[self.hops subarrayWithRange:NSMakeRange(1, self.hops.count - 1)]];
}

- (MMMNavigationHop *)firstHop {
	return [self.hops firstObject];
}

- (NSString *)path {

	NSMutableArray *hopsStrings = [[NSMutableArray alloc] init];
	for (MMMNavigationHop *hop in _hops) {

		NSString *s;
		if ([hop.params count] > 0) {

			NSMutableArray *paramStrings = [[NSMutableArray alloc] init];
			for (NSString *key in hop.params) {
				[paramStrings addObject:[NSString stringWithFormat:@"%@: %@", key, hop.params[key]]];
			}

			s = [NSString stringWithFormat:@"%@{%@}", hop.action, [paramStrings componentsJoinedByString:@", "]];

		} else {
			s = [NSString stringWithFormat:@"%@", hop.action];
		}

		[hopsStrings addObject:s];
	}

	return [hopsStrings componentsJoinedByString:@"/"];
}

- (NSString *)debugDescription {
	return [NSString stringWithFormat:@"<%@:%p %@", self.class, self, [self path]];
}

- (NSString *)description {
	return [self path];
}

- (BOOL)isEqual:(MMMNavigationPath *)object {

	if (![object isKindOfClass:self.class])
		return NO;

	if (![self.hops isEqual:object.hops])
		return NO;

	return YES;
}

@end

//
//
//
@interface MMMNavigation ()

/** MMMNavigationRequests -didFinishSuccesfully: method redirects here. */
- (void)didFinishRequest:(MMMNavigationRequest *)request successfully:(BOOL)successfully;

/** A corresponding method of MMMNavigationRequests recdirects here as well. */
- (void)continueRequest:(MMMNavigationRequest *)request path:(MMMNavigationPath *)path handler:(id<MMMNavigationHandler>)handler;

@end

//
//
//
@interface MMMNavigationRequest ()
@property (nonatomic, readonly) MMMNavigationCompletionBlock completion;
@end

@implementation MMMNavigationRequest {
	MMMNavigation *__weak _hub;
}

- (nonnull id)initWithHub:(MMMNavigation *)hub
	path:(MMMNavigationPath *)path
	completion:(MMMNavigationCompletionBlock)completion
{
	if (self = [super init]) {
		_hub = hub;
		_originalPath = path;
		_completion = completion;
	}
	return self;
}

- (void)dealloc {
	MMM_LOG_TRACE(@"dealloc");
}

- (NSString *)debugDescription {
	return [NSString stringWithFormat:@"<%@:%p original: %@, current: %@>", self.class, self, self.originalPath, self.path];
}

- (NSString *)description {
	if ([self.originalPath isEqual:self.path])
		return [NSString stringWithFormat:@"navigation request '%@'", self.originalPath];
	else
		return [NSString stringWithFormat:@"navigation request '%@' ('%@')", self.originalPath, self.path];
}

- (void)didFinishSuccessfully:(BOOL)successfully {
	[_hub didFinishRequest:self successfully:successfully];
}

- (void)continueWithPath:(MMMNavigationPath *)path handler:(id<MMMNavigationHandler>)handler {
	_path = path;
	[_hub continueRequest:self path:path handler:handler];
}

@synthesize path=_path;

- (MMMNavigationPath *)path {
	return _path ? _path : _originalPath;
}

@end

@interface MMMNavigationHandlerInfo : NSObject
@property (nonatomic, readonly, weak) id<MMMNavigationHandler> handler;
@end

@implementation MMMNavigationHandlerInfo

- (nonnull id)initWithHandler:(id<MMMNavigationHandler>)handler {
	if (self = [super init]) {
		_handler = handler;
	}
	return self;
}

- (void)markAsRemoved {
	_handler = nil;
}

@end

//
//
//
@implementation MMMNavigation {

	// The request being performed currently (we always perform them one by one) or nil.
	MMMNavigationRequest *_currentRequest;

	// The requests to be executed are queued here first.
	NSMutableArray *_requestQueue;

	NSMutableArray<MMMNavigationHandlerInfo *> *_handlers;

	id<MMMNavigationHandler> _currentHandler;
}

+ (nonnull instancetype)root {
	static MMMNavigation *root = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		root = [[self alloc] init];
	});
	return root;
}

- (nonnull id)init {

	if (self = [super init]) {
		_requestQueue = [[NSMutableArray alloc] init];
		_handlers = [[NSMutableArray alloc] init];
	}

	return self;
}

- (MMMNavigationRequestId)navigateTo:(MMMNavigationPath *)path completion:(MMMNavigationCompletionBlock)completion {

	NSAssert([NSThread isMainThread], @"");

	MMMNavigationRequest *r = [[MMMNavigationRequest alloc] initWithHub:self path:path completion:completion];
	[_requestQueue addObject:r];

	[self checkRequestQueueLater];

	return r;
}

- (void)checkRequestQueueLater {
	[self performSelector:@selector(checkRequestQueue) withObject:nil afterDelay:0];
}

- (void)checkRequestQueue {

	if (_currentRequest) {
		MMM_LOG_TRACE(@"A navigation request is in progress already");
		return;
	}

	if ([_requestQueue count] == 0) {
		MMM_LOG_TRACE(@"No more pending navigation requests");
		return;
	}
	
	// Collecting garbage first.
	NSMutableArray *handlers = [[NSMutableArray alloc] init];
	for (MMMNavigationHandlerInfo *handlerInfo in _handlers) {
		if (handlerInfo.handler) {
			[handlers addObject:handlerInfo];
		}
	}
	_handlers = handlers;

	_currentRequest = [_requestQueue firstObject];
	[_requestQueue removeObjectAtIndex:0];

	MMM_LOG_TRACE(@"Will be executing %@", _currentRequest);

	for (MMMNavigationHandlerInfo *handlerInfo in _handlers) {
		_currentHandler = handlerInfo.handler;
		if ([_currentHandler performNavigationRequest:_currentRequest]) {
			MMM_LOG_TRACE(@"The current request was accepted by %@", _currentHandler);
			return;
		}
	}

	MMM_LOG_ERROR(@"No handler found for %@, failing it", _currentRequest);
	[_currentRequest didFinishSuccessfully:NO];

	[self checkRequestQueueLater];
}

#pragma mark -

- (void)didFinishRequest:(MMMNavigationRequest *)request successfully:(BOOL)successfully {

	NSAssert([NSThread isMainThread], @"");
	NSAssert(request == _currentRequest, @"");

	MMMNavigationCompletionBlock completionBlock = _currentRequest.completion;

	_currentRequest = nil;
	_currentHandler = nil;

	if (successfully)
		MMM_LOG_TRACE(@"Completed %@", request);
	else
		MMM_LOG_TRACE(@"Could not complete %@", request);

	if (completionBlock)
		completionBlock(request, successfully);

	[self checkRequestQueueLater];
}

- (void)continueRequest:(MMMNavigationRequest *)request path:(MMMNavigationPath *)path handler:(id<MMMNavigationHandler>)handler {

	NSAssert([NSThread isMainThread], @"");
	NSAssert(request == _currentRequest, @"");

	if ([handler conformsToProtocol:@protocol(MMMNavigationHandler)] && [handler performNavigationRequest:_currentRequest]) {

		_currentHandler = handler;
		MMM_LOG_TRACE(@"The request is continued by %@", _currentHandler);

	} else {

		if ([path.hops count] == 0) {

			MMM_LOG_TRACE(@"All hops are handled");
			[self didFinishRequest:_currentRequest successfully:YES];

		} else {
			MMM_LOG_ERROR(@"Cannot finish the current request (have some more hops, %@, but they cannot be continued by %@)", request.path, handler);
			[self didFinishRequest:_currentRequest successfully:NO];
		}
	}
}

#pragma mark -

- (MMMNavigationHandlerId)addHandler:(id<MMMNavigationHandler>)handler {
	MMMNavigationHandlerInfo *info = [[MMMNavigationHandlerInfo alloc] initWithHandler:handler];
	[_handlers addObject:info];
	return info;
}

- (void)removeHandlerWithId:(MMMNavigationHandlerId)handlerId {
	MMMNavigationHandlerInfo *info = handlerId;
	[info markAsRemoved];
}

@end
