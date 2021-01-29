//
// MMMCommonCore. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMNetworkConditioner.h"

/**
 * A single record corresponding to each
 */
@interface MHNetworkConditionerItem : NSObject

/** Time when the corresponding block is scheduled. */
@property (nonatomic, readwrite) NSTimeInterval scheduledTime;

/** YES, if the corresponding request is destined to fail. */
@property (nonatomic, readwrite) BOOL shouldFail;

@property (nonatomic, readonly) MMMNetworkConditionerBlock block;

- (id)initWithParent:(MMMNetworkConditioner *)parent
	block:(MMMNetworkConditionerBlock)block
	context:(NSString *)context NS_DESIGNATED_INITIALIZER;

- (id)init NS_UNAVAILABLE;

@end

//
//
//
@implementation MHNetworkConditionerItem {
	MMMNetworkConditioner * __weak _parent;
	MMMNetworkConditionerBlock _block;
}

- (id)initWithParent:(MMMNetworkConditioner *)parent
	block:(MMMNetworkConditionerBlock)block
	context:(NSString *)context
{
	if (self = [super init]) {

		_parent = parent;
		_block = block;
		// Not really using the context now.
	}

	return self;
}

@end

//
//
//
@implementation MMMSimpleNetworkCondition {
	NSTimeInterval _minDelay;
	NSTimeInterval _maxDelay;
	double _failureRate;
}

- (id)initWithMinDelay:(NSTimeInterval)minDelay maxDelay:(NSTimeInterval)maxDelay failureRate:(double)failureRate {

	if (self = [super init]) {

		_minDelay = minDelay;
		_maxDelay = maxDelay;

		NSAssert(0 <= _minDelay && _minDelay <= _maxDelay, @"");

		_failureRate = failureRate;
		NSAssert(0 <= _failureRate && _failureRate <= 1, @"");
	}

	return self;
}

- (NSTimeInterval)delayForEstimatedResponseLength:(NSInteger)responseLength context:(NSString *)context {
	return _minDelay + (_maxDelay - _minDelay) * ((NSTimeInterval)arc4random() / UINT32_MAX);
}

- (BOOL)shouldFailInContext:(NSString *)context {
	return ((double)arc4random() / UINT32_MAX) < _failureRate;
}

@end

//
//
//
@implementation MMMNetworkConditioner {
	id<MMMNetworkCondition> _condition;
	NSMutableSet<MHNetworkConditionerItem *> *_items;
	NSTimer *_timer;
}

static MMMNetworkConditioner * __weak sharedInstance = nil;

+ (instancetype)shared {

	@synchronized (self) {

		if (sharedInstance == nil) {

			// There was an assert-crash in this case previously to force the developers to initialise a shared
			// instance early enough and with concrete parameters, however:
			//
			// 1) since the class is used under the hood in many utility classes, the developers are not always aware
			// about the requirement to initialise it;
			//
			// 2) unit tests make it invonvenient to have an explicit shared instance.
			//
			// So we do provide a default instance now, but only if the shared one was not explicitely initialised.
			// We also allow to switch to an explicit instance as soon as it is ready. This should not lead to any
			// problems in this particular case because multiple instances of this class with different settings
			// do not clash. I would not recommend to use this approach blindly everywhere though.
			
			static MMMNetworkConditioner * nullInstance = nil;
			static dispatch_once_t onceToken;
			dispatch_once(&onceToken, ^{
				nullInstance = [[MMMNetworkConditioner alloc] initWithCondition:nil];
			});
			return nullInstance;
		}

		return sharedInstance;
	}
}

- (id)initWithCondition:(id<MMMNetworkCondition>)condition {

	if (self = [super init]) {

		_condition = condition;

		_items = [[NSMutableSet alloc] init];

		if (!sharedInstance)
			sharedInstance = self;
	}

	return self;
}

- (void)conditionBlock:(MMMNetworkConditionerBlock)block
	inContext:(NSString *)context
	estimatedResponseLength:(NSInteger)responseLength
{
	if (!_condition) {
		block(nil);
		return;
	}

	MHNetworkConditionerItem *item = [[MHNetworkConditionerItem alloc] initWithParent:self block:block context:context];

	item.scheduledTime = [NSDate timeIntervalSinceReferenceDate] + [_condition delayForEstimatedResponseLength:responseLength context:context];

	item.shouldFail = [_condition shouldFailInContext:context];

	@synchronized (_items) {
		[_items addObject:item];
	}

	[self itemsDidChange];
}

- (void)itemsDidChange {
	[self scheduleTimer];
}

- (void)scheduleTimer {

	dispatch_async(dispatch_get_main_queue(), ^{

		[self->_timer invalidate];
		self->_timer = nil;

		@synchronized (self->_items) {

			if (self->_items.count == 0) {
				return;
			}

			NSTimeInterval earliestTime = -1;
			NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];

			for (MHNetworkConditionerItem *item in self->_items) {
				NSTimeInterval timeLeft = MAX(0, item.scheduledTime - now);
				if (earliestTime < 0 || timeLeft < earliestTime) {
					earliestTime = timeLeft;
				}
			}

			self->_timer = [NSTimer
				scheduledTimerWithTimeInterval:earliestTime
				target:self
				selector:@selector(timerTick)
				userInfo:nil
				repeats:NO
			];
            
            [[NSRunLoop mainRunLoop] addTimer:self->_timer forMode:NSRunLoopCommonModes];
		}
	});
}

- (NSError *)errorObject {
	return [NSError
		errorWithDomain:NSStringFromClass(self.class)
		code:-1
		userInfo:@{
			NSLocalizedDescriptionKey : [NSString 
				stringWithFormat:@"Simulated network failure. See %@ class for more info.",
				NSStringFromClass(self.class)
			]
		}
	];
}

- (void)timerTick {

	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];

	NSMutableSet *executed = [[NSMutableSet alloc] init];

	for (MHNetworkConditionerItem *item in [_items copy]) {

		if (item.scheduledTime <= now) {

			if (item.shouldFail)
				item.block([self errorObject]);
			else
				item.block(nil);

			[executed addObject:item];
		}
	}

	for (MHNetworkConditionerItem *item in executed) {
		[_items removeObject:item];
	}

	[self scheduleTimer];
}

@end
