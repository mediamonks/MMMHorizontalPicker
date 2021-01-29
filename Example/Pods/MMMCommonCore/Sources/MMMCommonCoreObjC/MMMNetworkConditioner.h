//
// MMMCommonCore. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MMMNetworkCondition;

typedef void (^MMMNetworkConditionerBlock)(NSError * _Nullable error);

/**
 * This is to help with network-related simulated delays and failures.
 */
@interface MMMNetworkConditioner : NSObject

+ (instancetype)shared;

/** If condition is nil, then simulation will be disabled. */
- (id)initWithCondition:(nullable id<MMMNetworkCondition>)condition NS_DESIGNATED_INITIALIZER;

- (id)init NS_UNAVAILABLE;

/** 
 * If simulation of errors and delays is turned on for this app, then the block will be called on the main queue
 * after a random delay and possibly with an error object (with its error message/code/domain being the same in all
 * cases).
 * In case the simulation is turned off, then the block is called immediatelly with error being nil.
 *
 * Usage example from MMMPublicLoadableImage:
 * \code
 * [[MMMNetworkConditioner shared]
 *     conditionBlock:^(NSError *error) {
 *         [self dispatch:^{
 *             if (error) {
 *                 [self didFailWithError:error];
 *             } else {
 *                 self->_image = image;
 *                 self.loadableState = MMMLoadableStateDidSyncSuccessfully;
 *             }
 *         }];
 *     }
 *     inContext:NSStringFromClass(self.class)
 *     estimatedResponseLength:data.length
 * ];
 * \endcode
 */
- (void)conditionBlock:(MMMNetworkConditionerBlock)block
	inContext:(NSString *)context
	estimatedResponseLength:(NSInteger)responseLength NS_REFINED_FOR_SWIFT;

@end

/** 
 * Protocol for the actual delay/error model.
 */
@protocol MMMNetworkCondition <NSObject>

- (NSTimeInterval)delayForEstimatedResponseLength:(NSInteger)responseLength context:(NSString *)context;
- (BOOL)shouldFailInContext:(NSString *)context;

@end

/** 
 * A network condition model with the given faulure rate and delays uniformely distributed within the given range.
 */
@interface MMMSimpleNetworkCondition : NSObject <MMMNetworkCondition>

- (id)initWithMinDelay:(NSTimeInterval)minDelay
	maxDelay:(NSTimeInterval)maxDelay 
	failureRate:(double)failureRate NS_DESIGNATED_INITIALIZER;

- (id)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
