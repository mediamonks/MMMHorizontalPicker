//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/** 
 * A little helper for velocity/acceleration calculations: you feed it values with timestamps and can get the most recent 
 * acceleration/velocity values.
 */
@interface MMMVelocityMeter : NSObject

/** Resets the state of the meter, all values added before are forgotten. */
- (void)reset;

/** Adds a coordinate and a corresponding timestamp. */
- (void)addValue:(CGFloat)value timestamp:(NSTimeInterval)timestamp;

/** Adds a coordinate with the current timstamp. */
- (void)addValue:(CGFloat)value;

/** Calculates velocity and acceleration based on recently added values. */
- (void)calculateVelocity:(CGFloat *)velocity acceleration:(CGFloat *)acceleration;

@end

typedef NS_ENUM(NSInteger, MMMAnimationCurve) {

	MMMAnimationCurveLinear,
	MMMAnimationCurveEaseOut,
	MMMAnimationCurveEaseIn,
	MMMAnimationCurveEaseInOut,

	// "Softer" versions are closer to the linear curve.
	MMMAnimationCurveSofterEaseIn,
	MMMAnimationCurveSofterEaseOut,
	MMMAnimationCurveSofterEaseInOut
};

/** Animation curve opposite to the given one, e.g. EaseIn for EaseOut. */
extern MMMAnimationCurve MMMReverseAnimationCurve(MMMAnimationCurve curve);

/** 
 * Minimalistic animation helpers.
 *
 * Terminology:
 *  - Normalized time — time value from the [0; 1] range.
 *  - Curved time — normalized time transformed using one of the predefined animation curves.
 */
@interface MMMAnimation : NSObject

/** Time obtained by curving the given normalized time (from [0; 1] range). */
+ (CGFloat)curvedTimeForTime:(CGFloat)time curve:(MMMAnimationCurve)curve;

/** 
 * Inverse function for curvedTimeForTime:curve:, i.e. when we know the value returned by curvedTimeForTime:curve:
 * and want the time value passed there. 
 * This should be used sparingly (not every frame) as the implementation is no very efficient.
 */
+ (CGFloat)timeForCurvedTime:(CGFloat)time curve:(MMMAnimationCurve)curve;

/** 
 * Time obtained by clamping the given time into [startTime; startTime + duration], normalizing to [0; 1] range,
 * and then curving using a preset curve. 
 */
+ (CGFloat)curvedTimeForTime:(CGFloat)t startTime:(CGFloat)startTime duration:(CGFloat)duration curve:(MMMAnimationCurve)curve;

/** A float between 'from' and 'to' corresponding to already normalized and curved time. */
+ (CGFloat)interpolateFrom:(CGFloat)from to:(CGFloat)to time:(CGFloat)time;

/** This has been renamed. Use the version above. */
+ (CGFloat)interpolateFrom:(CGFloat)from to:(CGFloat)to curvedTime:(CGFloat)time DEPRECATED_ATTRIBUTE;

/** 
 * Value between two floats corresponding to the given time and timing curve.
 * If the time is less then startTime, then 'from' is returned.
 * If the time is greater then startTime + duration, then 'to' is returned.
 */
+ (CGFloat)interpolateFrom:(CGFloat)from to:(CGFloat)to time:(CGFloat)time startTime:(CGFloat)startTime duration:(CGFloat)duration curve:(MMMAnimationCurve)curve;

/**
 * A color between 'from' and 'to' corresponding to already normalized and curved time. 
 * Only RGB colors are supported.
 * Interpolation is done along a straight line in the RGB space. 
 */
+ (UIColor *)colorFrom:(UIColor *)from to:(UIColor *)to time:(CGFloat)time;

/**
 * A point on the line between given points corresponding to already normalized and curved time.
 */
+ (CGPoint)pointFrom:(CGPoint)from to:(CGPoint)to time:(CGFloat)time;

@end

@class MMMAnimationHandle;

/** 
 * Called on every update cycle of MMMAnimator for the given animation item.
 *
 * The time is always within [0; 1] range here, which will correspond to the the [start; start + duration] interval of 
 * real time clock.
 *
 * Unless the item is cancelled it is guaranteed that the block will be called for 0 and 1 values.
 */
typedef void (^MMMAnimatorUpdateBlock)(MMMAnimationHandle *item, CGFloat time);

/**
 * Called when the animation item has been finished.
 */
typedef void (^MMMAnimatorDoneBlock)(MMMAnimationHandle *item, BOOL cancelled);

/**
 * Minimalistic animator object in the spirit of helpers defined in MMMAnimation.
 *
 * You add animation items, which are basically a set of blocks that will be called every frame on the main run loop and 
 * when it's done or cancelled.
 *
 * It's not for every case, it's for those moments when you know the duration in advance and just need to animate a
 * simple custom property and don't want to subclass CALayer or mess with its multithreaded delegates.
 *
 * The animator object does not take care of interpolation of values nor time curves, the normalized time passed into 
 * update blocks can be transformed and values can be interpolated using simple helpers in MMMAnimation.
 */
@interface MMMAnimator : NSObject

+ (instancetype)shared;

/** 
 * Schedules a new animation item.
 *
 * The `updateBlock` is called on every update cycle within the animation's duration. It is guaranteed to be called with
 * zero time even if cancelled before the next run loop cycle. The update block is also guaranteed to be called with 
 * time being 1 unless is cancelled earlier.
 *
 * The `doneBlock` is called after the animation finishes or is cancelled.
 *
 * The `repeatCount` parameter can be set to 0 to mean infinite repeat count.
 *
 * In case `repeatCount` is different from 1, then `autoreverse` influences the way the time changes when passed to 
 * the `updateBlock`: if YES, then it'll grow from 0 to 1 and then from 1 to 0 on the next repeat, changing back to 
 * from 0 to 1 after this, etc; if NO, then it'll always from from 0 to 1 on every repeat step.   
 *
 * The animation will start on the next cycle of the refresh timer and will have the timestamp of this cycle as its 
 * actual start time, so there is no need in explicit transactions: all animation added on the same run loop cycle are 
 * guaranteed to be run in sync.
 * 
 * Keep the object returned. The animation stops when the reference to this object is released.
 */
- (MMMAnimationHandle *)addAnimationWithDuration:(CGFloat)duration
	updateBlock:(MMMAnimatorUpdateBlock)updateBlock
	doneBlock:(MMMAnimatorDoneBlock)doneBlock;

- (MMMAnimationHandle *)addAnimationWithDuration:(CGFloat)duration
	repeatCount:(NSInteger)repeatCount
	autoreverse:(BOOL)autoreverse
	updateBlock:(MMMAnimatorUpdateBlock)updateBlock
	doneBlock:(MMMAnimatorDoneBlock)doneBlock;

/** Despite the +shared method defined above you can still create own instances of this class. */
- (id)init NS_DESIGNATED_INITIALIZER;

@end

@interface MMMAnimator ()

/** 
 * For unit tests only: will synchronously run all the animations already in the animator and the ones added within
 * the given block in the specified number of steps, executing the given block after each step.
 * This is used in view-based tests for those views that run all their animations using MMMAnimator. 
 *
 * The idea is that an animated action is triggered in the `animationsBlock` (e.g. `hideAnimated:YES`) and then the 
 * `stepBlock` is called in the very beginning and in exactly `numberOfSteps - 1` moments afterwards. The moments will be
 * selected, so they are spaced equally and the last one is exactly at the end of the longest animation item.
 */
- (void)_testRunInNumberOfSteps:(NSInteger)numberOfSteps
	animations:(void (NS_NOESCAPE ^)(void))animationsBlock
	forEachStep:(void (NS_NOESCAPE ^)(NSInteger stepIndex))stepBlock;

@end

/**
 * Sort of a handle returned by MMMAnimator when a new animation is scheduled. 
 * Keep it around, otherwise the animation will be cancelled.
 */
@interface MMMAnimationHandle : NSObject

/** YES, if the animation has not been finished yet. */
@property (nonatomic, readonly) BOOL inProgress;

/** Finishes animation before its designated end time. */
- (void)cancel;

- (id)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
