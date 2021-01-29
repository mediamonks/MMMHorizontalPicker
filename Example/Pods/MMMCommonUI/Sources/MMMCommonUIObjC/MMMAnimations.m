//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMAnimations.h"

#import "MMMCommonUI.h"

typedef struct {
	NSTimeInterval timestamp;
	CGFloat value;
} MMMVelocityMeterSample;

#define MMMVelocityMeterMaxSamples 3

@implementation MMMVelocityMeter {
	NSInteger _numberOfSamples;
	NSInteger _lastSampleIndex;
	MMMVelocityMeterSample _samples[MMMVelocityMeterMaxSamples];
}

- (id)init {
	if (self = [super init]) {
	}
	return self;
}

- (void)reset {
	_numberOfSamples = 0;
	_lastSampleIndex = -1;
}

- (MMMVelocityMeterSample)sampleAtIndex:(NSInteger)index {
	NSInteger i = _lastSampleIndex - index;
	if (i < 0)
		i += MMMVelocityMeterMaxSamples;
	return _samples[i];
}

- (void)addValue:(CGFloat)value {
	[self addValue:value timestamp:[NSDate timeIntervalSinceReferenceDate]];
}

- (void)addValue:(CGFloat)value timestamp:(NSTimeInterval)timestamp {

	MMMVelocityMeterSample sample;
	sample.timestamp = timestamp;
	sample.value = value;

	if (_numberOfSamples > 0 && [self sampleAtIndex:0].timestamp == timestamp) {

		// Let's protect against same timestamps just in case by rewriting the last entry.
		_samples[_lastSampleIndex] = sample;

	} else {

		_lastSampleIndex++;
		if (_lastSampleIndex >= MMMVelocityMeterMaxSamples)
			_lastSampleIndex -= MMMVelocityMeterMaxSamples;
		_samples[_lastSampleIndex] = sample;

		if (_numberOfSamples < MMMVelocityMeterMaxSamples)
			_numberOfSamples++;
	}
}

- (void)calculateVelocity:(CGFloat *)velocity acceleration:(CGFloat *)acceleration {

	CGFloat v = 0;
	CGFloat a = 0;

	if (_numberOfSamples <= 1) {

		v = a = 0;

	} else if (_numberOfSamples == 2) {

		MMMVelocityMeterSample s0 = [self sampleAtIndex:0];
		MMMVelocityMeterSample s1 = [self sampleAtIndex:1];
		v = (s0.value - s1.value) / (s0.timestamp - s1.timestamp);
		a = 0;

	} else if (_numberOfSamples >= 3) {

		MMMVelocityMeterSample s0 = [self sampleAtIndex:0];
		MMMVelocityMeterSample s1 = [self sampleAtIndex:1];
		MMMVelocityMeterSample s2 = [self sampleAtIndex:2];

		CGFloat v0 = (s0.value - s1.value) / (s0.timestamp - s1.timestamp);
		CGFloat v1 = (s1.value - s2.value) / (s1.timestamp - s2.timestamp);
		a = (v0 - v1) / (s0.timestamp - s1.timestamp);
		v = v0;
	}

	if (velocity)
		*velocity = v;
	if (acceleration)
		*acceleration = a;
}

@end

//
//
//
MMMAnimationCurve MMMReverseAnimationCurve(MMMAnimationCurve curve) {

	switch (curve) {

		case MMMAnimationCurveLinear:
		case MMMAnimationCurveEaseInOut:
		case MMMAnimationCurveSofterEaseInOut:
			return curve;

		case MMMAnimationCurveEaseOut:
			return MMMAnimationCurveEaseIn;
		case MMMAnimationCurveEaseIn:
			return MMMAnimationCurveEaseOut;

		case MMMAnimationCurveSofterEaseIn:
			return MMMAnimationCurveSofterEaseOut;
		case MMMAnimationCurveSofterEaseOut:
			return MMMAnimationCurveSofterEaseIn;
	}
}

//
//
//
@implementation MMMAnimation

// We'll define our normal animation curves via "ease in".
// The larger the 'k' coefficient the greater slope our ease function will have at t = 1.
static inline CGFloat MMMAnimationUtils_EaseIn(const CGFloat t, const CGFloat k) {
	CGFloat tt = t * t;
	return (k - 2) * t * tt + (3 - k) * tt;
}

static inline CGFloat MMMAnimationUtils_BaseCurve(CGFloat time, MMMAnimationCurve curve, CGFloat k) {

	switch (curve) {

		case MMMAnimationCurveLinear:
			return time;

		case MMMAnimationCurveEaseIn:
		case MMMAnimationCurveSofterEaseIn:
			return MMMAnimationUtils_EaseIn(time, k);

		case MMMAnimationCurveEaseOut:
		case MMMAnimationCurveSofterEaseOut:
			return 1 - MMMAnimationUtils_EaseIn(1 - time, k);

		case MMMAnimationCurveEaseInOut:
		case MMMAnimationCurveSofterEaseInOut:
			if (time <= .5f) {
				return .5f * MMMAnimationUtils_EaseIn(time / .5f, k);
			} else {
				return 1 - (.5f * MMMAnimationUtils_EaseIn(1 - (time - .5f) / .5f, k));
			}

		default:
			NSCAssert(NO, @"");
			return 0;
	}
}

+ (CGFloat)timeForCurvedTime:(CGFloat)time curve:(MMMAnimationCurve)curve {

	// Assuming all our curves are monotonous, so we can use simple binary search here.
	CGFloat l = 0;
	CGFloat r = 1;
	do {
		CGFloat m = (l + r) / 2;
		CGFloat f = [self curvedTimeForTime:m curve:curve];
		if (f < time) {
			l = m;
		} else {
			r = m;
		}
	} while (fabs(r - l) > 1e-6);

	return l;
}

+ (CGFloat)curvedTimeForTime:(CGFloat)time curve:(MMMAnimationCurve)curve {

	// Similar to `interpolateFrom:to:time`, the time was expected to be in [0; 1] range before,
	// however for bounce-type animations it's handy to allow it to go outside the range.
	// Extending the domain of the function here simply by not curving values outside the range.
	if (time <= 0 || 1 < time)
		return time;

	switch (curve) {

		case MMMAnimationCurveLinear:
		case MMMAnimationCurveEaseIn:
		case MMMAnimationCurveEaseOut:
		case MMMAnimationCurveEaseInOut:
			return MMMAnimationUtils_BaseCurve(time, curve, 2.5);

		case MMMAnimationCurveSofterEaseIn:
		case MMMAnimationCurveSofterEaseOut:
		case MMMAnimationCurveSofterEaseInOut:
			return MMMAnimationUtils_BaseCurve(time, curve, 1.25);
	}
}

+ (CGFloat)curvedTimeForTime:(CGFloat)t startTime:(CGFloat)startTime duration:(CGFloat)duration curve:(MMMAnimationCurve)curve {

	NSAssert(duration > 0, @"Positive duration is expected in %s", sel_getName(_cmd));

	CGFloat time = (t - startTime) / duration;
	if (time < 0)
		time = 0;
	else if (time > 1)
		time = 1;

	return [self curvedTimeForTime:time curve:curve];
}

+ (CGFloat)interpolateFrom:(CGFloat)from to:(CGFloat)to curvedTime:(CGFloat)time {
	return [self interpolateFrom:from to:to time:time];
}

+ (CGFloat)interpolateFrom:(CGFloat)from to:(CGFloat)to time:(CGFloat)time {
	// Note that we were asserting before that the time had to be within [0; 1]. This was meant to catch possible
	// issues only as interpolation could be done (and be useful) with the time out of this range.
	return from * (1 - time) + to * time;
}

+ (CGFloat)interpolateFrom:(CGFloat)from to:(CGFloat)to time:(CGFloat)time
	startTime:(CGFloat)startTime duration:(CGFloat)duration curve:(MMMAnimationCurve)curve
{
	CGFloat t = [self curvedTimeForTime:time startTime:startTime duration:duration curve:curve];
	return from * (1 - t) + to * t;
}

+ (UIColor *)colorFrom:(UIColor *)from to:(UIColor *)to time:(CGFloat)time {

	CGFloat c1[4];
	CGFloat c2[4];

	if ([from getRed:&c1[0] green:&c1[1] blue:&c1[2] alpha:&c1[3]]
		&& [to getRed:&c2[0] green:&c2[1] blue:&c2[2] alpha:&c2[3]]
	) {
		return [UIColor
			colorWithRed:[MMMAnimation interpolateFrom:c1[0] to:c2[0] time:time]
			green:[MMMAnimation interpolateFrom:c1[1] to:c2[1] time:time]
			blue:[MMMAnimation interpolateFrom:c1[2] to:c2[2] time:time]
			alpha:[MMMAnimation interpolateFrom:c1[3] to:c2[3] time:time]
		];
	} else if ([from getWhite:&c1[0] alpha:&c1[1]] && [to getWhite:&c2[0] alpha:&c2[1]]) {
		return [UIColor
			colorWithWhite:[MMMAnimation interpolateFrom:c1[0] to:c2[0] time:time]
			alpha:[MMMAnimation interpolateFrom:c1[1] to:c2[1] time:time]
		];
	} else {
		NSAssert(NO, @"%s: both colors should use the same space (either RGB or grayscale)", sel_getName(_cmd));
		return from;
	}
}

+ (CGPoint)pointFrom:(CGPoint)from to:(CGPoint)to time:(CGFloat)time {
	return CGPointMake(
		[self interpolateFrom:from.x to:to.x time:time],
		[self interpolateFrom:from.y to:to.y time:time]
	);
}

@end

//
//
//

typedef NS_ENUM(NSInteger, MMMAnimatorItemState) {

	/** The item is added to the animator, but has not got a start time assigned and the corresponding block 
	 * has not been called yet. */
	MMMAnimatorItemStateIdle,

	/** The animation corresponding to this item is in progress. The update block has been called at least once. */
	MMMAnimatorItemStateStarted,

	/** The animation corresponding to this item has been finished. 
	 * The update block has been called at least once and the done block has been called as well. */
	MMMAnimatorItemStateFinished
};

//
//
//
@interface MMMAnimatorItem : NSObject

@property (nonatomic, readonly) MMMAnimator *animator;

@property (nonatomic, readwrite) MMMAnimatorItemState state;

@property (nonatomic, readonly) NSTimeInterval duration;

/** The timestamp of the first frame when the animation has been started. */
@property (nonatomic, readwrite) NSTimeInterval timestamp;

@property (nonatomic, readonly) MMMAnimatorUpdateBlock updateBlock;

@property (nonatomic, readonly) MMMAnimatorDoneBlock doneBlock;

@property (nonatomic, readonly) NSInteger repeatCount;

@property (nonatomic, readonly) BOOL autoreverse;

- (id)initWithAnimator:(MMMAnimator *)animator
	duration:(CGFloat)duration
	repeatCount:(NSInteger)repeatCount
	autoreverse:(BOOL)autoreverse
	updateBlock:(MMMAnimatorUpdateBlock)updateBlock
	doneBlock:(MMMAnimatorDoneBlock)doneBlock NS_DESIGNATED_INITIALIZER;

- (id)init NS_UNAVAILABLE;

@end

@implementation MMMAnimatorItem {
	MMMAnimator * __weak _animator;
}

- (id)initWithAnimator:(MMMAnimator *)animator
	duration:(CGFloat)duration
	repeatCount:(NSInteger)repeatCount
	autoreverse:(BOOL)autoreverse
	updateBlock:(MMMAnimatorUpdateBlock)updateBlock
	doneBlock:(MMMAnimatorDoneBlock)doneBlock
{
	if (self = [super init]) {

		_animator = animator;

		_duration = duration;
		NSAssert(_duration > 0, @"Invalid duration of the animation");

		_updateBlock = updateBlock;
		NSAssert(_updateBlock != nil, @"The update block has to be provided");

		_repeatCount = repeatCount;
		if (_repeatCount <= 0)
			_repeatCount = INT_MAX;

		_autoreverse = autoreverse;

		_doneBlock = doneBlock;
	}

	return self;
}

@end

@interface MMMAnimationHandle ()

@property (nonatomic, readonly) MMMAnimatorItem *item;

- (id)initWithItem:(MMMAnimatorItem *)item NS_DESIGNATED_INITIALIZER;

@end

@interface MMMAnimator ()

/** This is the method directly for the handle. */
- (void)cancelAnimationForHandle:(MMMAnimationHandle *)handle;

@end

@implementation MMMAnimationHandle

- (id)initWithItem:(MMMAnimatorItem *)item {

	if (self = [super init]) {
		_item = item;
	}

	return self;
}

- (void)dealloc {
	[self cancel];
}

- (BOOL)inProgress {
	return (_item.state != MMMAnimatorItemStateFinished);
}

- (void)cancel {

	if (_item.state == MMMAnimatorItemStateFinished)
		return;

	MMMAnimator *animator = _item.animator;
	if (animator) {
		[animator cancelAnimationForHandle:self];
	}
}

@end

//
//
//
@implementation MMMAnimator {

	CADisplayLink *_displayLink;

	// A mapping of NSValue-wrapped weak handles into the actual animation items.
	NSMutableDictionary<NSValue *, MMMAnimatorItem *> *_items;

	//
	// To be able to override the shared animator from unit tests.
	//
	NSInteger _testingCounter;
	NSTimeInterval _testTime;
}

static MMMAnimator *sharedInstance = nil;

+ (instancetype)shared {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});
	return sharedInstance;
}

- (id)init {

	if (self = [super init]) {

		NSAssert(
			[NSRunLoop currentRunLoop] == [NSRunLoop mainRunLoop],
			@"%@ must be accessed from the main run loop", self.class
		);

		_items = [[NSMutableDictionary alloc] init];

		_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
		[_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
		[_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:UITrackingRunLoopMode];
	}

	return self;
}

- (void)dealloc {

	for (NSValue *key in [_items allKeys]) {
		MMMAnimatorItem *item = _items[key];
		[self finalizeItem:item forKey:key cancelled:YES];
	}

	[_displayLink invalidate];
}

- (void)update {

	NSTimeInterval timestamp = _displayLink.timestamp;

	if (_testingCounter > 0)
		timestamp = _testTime;

	NSMutableArray *keysToRemove = nil;
	for (NSValue *key in [_items allKeys]) {

		MMMAnimatorItem *item = _items[key];
		if (!item)
			continue;

		NSInteger repeatCount;
		CGFloat localTime;
		if (item.state == MMMAnimatorItemStateIdle) {

			// The item was scheduled on a previous run loop cycle, let's assign a timestamp to it.
			item.timestamp = timestamp;
			item.state = MMMAnimatorItemStateStarted;
			localTime = 0;
			repeatCount = 0;

		} else {

			CGFloat time = (timestamp - item.timestamp) / item.duration;
			if (time < 0)
				time = 0;
			if (time > item.repeatCount)
				time = item.repeatCount;

			repeatCount = (NSInteger)floor(time);
			localTime = time - repeatCount;
			if (repeatCount == item.repeatCount)
				localTime = 1;
			if (item.autoreverse && repeatCount % 2 == 1)
				localTime = 1 - localTime;
		}

		item.updateBlock([key nonretainedObjectValue], localTime);

		// If that was the last update, then remember the item to remove later.
		if (item.repeatCount >= 0 && repeatCount >= item.repeatCount) {
			if (!keysToRemove) {
				keysToRemove = [[NSMutableArray alloc] init];
			}
			[keysToRemove addObject:key];
		}
	}

	if ([keysToRemove count] > 0) {

		for (NSValue *key in keysToRemove) {

			MMMAnimatorItem *item = _items[key];
			if (item)
				[self finalizeItem:item forKey:key cancelled:NO];
		}

		[self pauseOrResumeUpdates];
	}
}

- (void)pauseOrResumeUpdates {
	_displayLink.paused = (_testingCounter > 0) || (_items.count == 0);
}

- (MMMAnimationHandle *)addAnimationWithDuration:(CGFloat)duration
	updateBlock:(MMMAnimatorUpdateBlock)updateBlock
	doneBlock:(MMMAnimatorDoneBlock)doneBlock
{
	return [self
		addAnimationWithDuration:duration
		repeatCount:1
		autoreverse:NO
		updateBlock:updateBlock
		doneBlock:doneBlock
	];
}

- (MMMAnimationHandle *)addAnimationWithDuration:(CGFloat)duration
	repeatCount:(NSInteger)repeatCount
	autoreverse:(BOOL)autoreverse
	updateBlock:(MMMAnimatorUpdateBlock)updateBlock
	doneBlock:(MMMAnimatorDoneBlock)doneBlock
{
	NSAssert(
		[NSRunLoop currentRunLoop] == [NSRunLoop mainRunLoop],
		@"%@ must be accessed from the main run loop", self.class
	);

	MMMAnimatorItem *item = [[MMMAnimatorItem alloc]
		initWithAnimator:self
		duration:duration
		repeatCount:repeatCount
		autoreverse:autoreverse
		updateBlock:updateBlock
		doneBlock:doneBlock
	];

	MMMAnimationHandle *handle = [[MMMAnimationHandle alloc] initWithItem:item];

	NSValue *key = [NSValue valueWithNonretainedObject:handle];

	_items[key] = item;

	[self pauseOrResumeUpdates];

	return handle;
}

- (void)finalizeItem:(MMMAnimatorItem *)item forKey:(id)key cancelled:(BOOL)cancelled {

	if (item.state == MMMAnimatorItemStateIdle || item.state == MMMAnimatorItemStateStarted) {

		// In case the item has not been active yet we still need to call the update block for time being 0 before we
		// remove it, so at least the initial update of the corresponding property can be made.
		if (item.state == MMMAnimatorItemStateIdle) {
			item.updateBlock([key nonretainedObjectValue], 0);
		}

		item.state = MMMAnimatorItemStateFinished;

		if (item.doneBlock)
			item.doneBlock([key nonretainedObjectValue], cancelled);

	} else if (item.state == MMMAnimatorItemStateFinished) {

		// Already finished, nothing to do

	} else {

		NSAssert(NO, @"");
	}

	[_items removeObjectForKey:key];
}

- (void)cancelAnimationForHandle:(MMMAnimationHandle *)handle {

	NSAssert(
		[NSRunLoop currentRunLoop] == [NSRunLoop mainRunLoop],
		@"%@ must be accessed from the main run loop", self.class
	);

	NSValue *key = [NSValue valueWithNonretainedObject:handle];

	MMMAnimatorItem *item = _items[key];
	if (item) {
		[self finalizeItem:item forKey:key cancelled:YES];
	}
}

#pragma mark -

- (void)_testRunInNumberOfSteps:(NSInteger)numberOfSteps
	animations:(void (NS_NOESCAPE^)(void))animationsBlock
	forEachStep:(void (NS_NOESCAPE^)(NSInteger stepIndex))stepBlock
{
	NSAssert(numberOfSteps >= 2, @"");

	if (++_testingCounter == 0) {
		[self pauseOrResumeUpdates];
	}

	animationsBlock();

	// Make sure all the current animation items will get the initial timestamp.
	_testTime = 0;
	[self update];

	// Very first step, to not call update twice.
	stepBlock(0);

	// Find the most distant end of animation.
	NSTimeInterval maxTime = 0;
	for (MMMAnimatorItem *item in [_items allValues]) {

		//~ NSAssert(item.repeatCount == 1, @"We don't support repeatCount for animations tested via %s", sel_getName(_cmd));

		NSTimeInterval endTime = item.timestamp + item.duration;
		if (endTime > maxTime) {
			maxTime = endTime;
		}
	}

	// Go through all the steps.
	for (NSInteger i = 1; i < numberOfSteps; i++) {

		_testTime = maxTime * i / (numberOfSteps - 1);
		[self update];

		stepBlock(i);
	}

	if (--_testingCounter == 0) {
		[self pauseOrResumeUpdates];
	}
}

@end
