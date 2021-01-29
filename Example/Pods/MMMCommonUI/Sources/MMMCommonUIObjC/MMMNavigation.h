//
// MMMUtil.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** 
 * Opening a deep link can involve following through one or more steps, for example:
 *
 * 1) make sure the main screen is visible and can switch between the pages; 
 * 2) move to the recipes page;
 * 3) open recipe with ID N; 
 * 4) scroll to ingredients, etc.
 *
 * This is a single step in such a chain.
 */
@interface MMMNavigationHop : NSObject

/** Name/ID of the hop. Supposed to be a flat string, like 'recipes', not a path. */
@property (nonatomic, readonly) NSString *action;

/** Optional parameters for this hop only. */
@property (nonatomic, readonly, nullable) NSDictionary<NSString*, id> *params;

- (id)initWithAction:(NSString *)action params:(nullable NSDictionary<NSString*, id> *)params NS_DESIGNATED_INITIALIZER;

- (id)initWithAction:(NSString *)action;

- (id)init NS_UNAVAILABLE;

@end

/** 
 * A navigation path is just a collection of one or more "hops".
 */
@interface MMMNavigationPath : NSObject

/** All the "hops" the link consists of. */
@property (nonatomic, readonly) NSArray<MMMNavigationHop *> *hops;

/** A new path obtained from the current one by removing the first hop. */
- (nullable MMMNavigationPath *)pathWithoutFirstHop;

/** The first hop in the path or nil if the path is empty. */
- (nullable MMMNavigationHop *)firstHop;

- (id)initWithHops:(NSArray<MMMNavigationHop *> *)hops NS_DESIGNATED_INITIALIZER;

/** 
 * Convenience initializer. Allows to use URIs like "main/recipes", to construct hops out of it. 
 * Note that it does not currently support hop parameters.
 */
- (id)initWithURI:(NSString *)uri;

- (id)init NS_UNAVAILABLE;

@end

typedef id MMMNavigationRequestId;

typedef void (^MMMNavigationCompletionBlock)(MMMNavigationRequestId requestId, BOOL finished);

/** 
 * Manages switching between different sections of the app (kind of internal URL router).
 * It's like a central hub accepting navigation requests and then passing them to the entities that able to perform them. 
 * (The entities that are able to open requests should register themselves as handlers.)
 */
@interface MMMNavigation : NSObject

+ (instancetype)root;

/** 
 * Starts the process of opening of the given path. Calls the completion block when done, the block receives ID of the 
 * corresponding request. Links are opened one by one. Any navigation request received while handling the current one 
 * will be queued.
 */
- (MMMNavigationRequestId)navigateTo:(MMMNavigationPath *)path completion:(MMMNavigationCompletionBlock)completion;

@end

@protocol MMMNavigationHandler;

typedef id MMMNavigationHandlerId;

@interface MMMNavigation (Handlers)

/** Adds a handler and returns a cookie/ID object that can be later used to remove it. */
- (MMMNavigationHandlerId)addHandler:(id<MMMNavigationHandler>)handler;

/** Removes a handler by its ID assigned by addHandler. */
- (void)removeHandlerWithId:(MMMNavigationHandlerId)handlerId;

@end

/**
 * Info about a navigation request that is passed to handlers.
 */
@interface MMMNavigationRequest : NSObject

/** A sequence of hops the request has started with. This is never changed during lifetime of the request. */
@property (nonatomic, readonly) MMMNavigationPath *originalPath;

/** The current sequence of hops to follow. Handlers can adjust this. */
@property (nonatomic, readonly) MMMNavigationPath *path;

/** Called by the handler when all the hops in the path were followed through. */
- (void)didFinishSuccessfully:(BOOL)successfully;

/** 
 * Called by the handler to indicate that the sequence of hops (possibly changed) should be continued by another handler.
 * The handler is supposed to conform to `MMMNavigationHandler` protocol and this will be checked for in this method.
 * The parameter here is not described as id<MMMNavigationHandler> to make it more convenient to call this method.
 */
- (void)continueWithPath:(MMMNavigationPath *)path handler:(id)handler;

@end

/** Protocol for entities able to fulfill in-app navigation requests. */
@protocol MMMNavigationHandler <NSObject>

/**
 * Returns NO, in case the handler is unable to perform the given request. (Another handler will be tried then.)
 * Returns YES, if the request has been accepted by the handler. 
 * The handler must call -didFinishSuccessfully: when it's done performing the request.
 */
- (BOOL)performNavigationRequest:(MMMNavigationRequest *)request;

@end

NS_ASSUME_NONNULL_END
