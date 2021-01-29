//
// MMMLog. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#if defined(_MMM_LOG)
#error Overrides of _MMM_LOG() are not supported anymore.
#endif

/** Message severity levels for MMMLog(). Yes, 3 is enough. */
typedef NS_ENUM(NSInteger, MMMLogLevel) {

	/**
	 * Level for messages that are mostly used for debugging/testing and that can be potentially (not necessarily!)
	 * disabled in Release builds or even per `.m` module in ObjC.
	 *
	 * This is the noisiest level by definition but still try keeping the noise to the minimum by disabling the most
	 * noisy traces (too frequent or less useful) when the thing you are working on is ready. Keeping important traces
	 * can be very helpful when diagnosing production crashes though, so use your best judgement.
	 *
	 * Once again, don't assume that traces are not visible in Release builds. Don't log sensitive information, such as
	 * names, emails, passwords, authentication tokens, etc or at least use `MMMSensitiveInfo()` to redact them in
	 * Release builds.
	 */
	MMMLogLevelTrace = 0,

	/**
	 * Level for important non-error messages that can be useful for diagnostics even in Release builds.
	 *
	 * These can be important app events, outcomes or steps of certain important flows, e.g. a user has signed in,
	 * switched to certain screen, disabled certain setting. In other words, anything you would be glad you have logged
	 * when checking a crash report in Crashltyics or analysing a bug happening only for the client.
	 *
	 * A notice on sensitive info applies here as well, see `MMMLogLevelTrace`.
	 */
	MMMLogLevelInfo,

	/**
	 * Level for important error messages.
	 *
	 * Although every error can be useful for diagnostics, try to make sure that multiple errors of the same kind won't
	 * be logged in a row. For example, if you are parsing an array of 100 elements where every element gives a parsing
	 * error that you log, then this might clutter the log output potentially removing earlier useful messages from it.
	 * Consider stopping parsing at the first failure instead.
	 *
	 * A notice on sensitive info applies here as well, see `MMMLogLevelTrace`.
	 */
	MMMLogLevelError
};

/**
 * The main entry point of our simple logging system. The output of our `MMM_LOG_*` macros and corresponding
 * Swift helpers is funneled here.
 *
 * The messages go directly to the console by default (via `NSLog()`), but this can be overriden
 * in the app using `MMMLogOverrideOutputWithBlock()`.
 *
 * The `context` parameter is a string identifying the source of the log message. Normally it's a name of the
 * corresponding class possibly with a few bits identifying a particular instance outputting the message.
 */
extern void MMMLog(MMMLogLevel level, NSString *context, NSString *message) NS_REFINED_FOR_SWIFT;

typedef void (^MMMLogOutputBlock)(MMMLogLevel level, NSString *source, NSString *message);

/**
 * Allows the app to override the default output of `MMMLog()`.
 *
 * Note that there can be only a single override and once it's set the default behaviour is gone. (It's allowed to
 * reset the handler back to nil though.)
 */
extern void MMMLogOverrideOutputWithBlock(MMMLogOutputBlock _Nullable block) NS_SWIFT_NAME(MMMLogOverrideOutput(_:));

/// Formatter that is used by the default `MMMLog()` handler. You can use it in your override to match the output.
extern NSString *MMMLogFormat(MMMLogLevel level, NSString *context, NSString *message);

/// You can use this with `MMMLogOverrideOutput()` to redirect messages to `OSLog` aka `os_log` aka Apple's unified logging system.
///
/// App's bundle ID is going to be used for 'subsystem' and the passed `context` for 'category'.
extern void MMMLogOutputToOSLog(MMMLogLevel level, NSString *context, NSString *message);

/// Use this with `MMMLogOverrideOutput()` to redirect messages to XCode console in a way similar to `NSLog()` but less noisy.
///
/// E.g.:
/// 	|15:37:20.91|  - AppDelegate#dc0  Initialized
///
/// Instead of:
/// 	2020-02-25 16:37:20.863758+0100 MMMLogExample[56602:2050564]  - AppDelegate#dc0  Initialized
///
/// In addition to being less noisy it does not truncate very long messages (unlike `NSLog()` or `CLSNSLogv()`),
/// so perhaps don't use this in Release builds or make sure to not log unbounded strings.
extern void MMMLogOutputToConsole(MMMLogLevel level, NSString *context, NSString *message);

/**
 * Used by `MMM_LOG_*` macros to generate a `context` string needed by `MMMLog()` function from the given ObjC object.
 *
 * The implementation uses class name with a bit of extra context returned by the object's
 * `mmm_instanceNameForLogging` method.
 */
extern NSString *MMMLogContextFromObject(NSObject *obj) NS_REFINED_FOR_SWIFT;

@interface NSObject (MMMLog)

/**
 * Addition context that should be added to the class name when this instance is logging something via MMM_LOG_* macros.
 * This is handy when different instances of the same class can output something at the same time and we want to
 * distinguish their output in the logs.
 *
 * The default implementation uses last couple digits of the object's address by default. It might be handy to override
 * this with some kind of object's identifier, index or name instead.
 */
- (NSString *)mmm_instanceNameForLogging;

/** Same as `-mmm_instanceNameForLogging` but for the class itself. */
+ (NSString *)mmm_instanceNameForLogging;

@end

/**
 * Outputs a diagnostic (trace) message.
 *
 * Define `MMM_LOG_TRACE_DISABLED` macro before importing `MMMLog.h` in order to disable it just for your `.m` module.
 */
#define MMM_LOG_TRACE(message, ...) \
	MMMLog(MMMLogLevelTrace, MMMLogContextFromObject(self), [NSString stringWithFormat:message, ## __VA_ARGS__ ])

#if defined(MMM_LOG_TRACE_DISABLED)
#undef MMM_LOG_TRACE
#define MMM_LOG_TRACE(message, ...)
#endif

/**
 * Outputs an important non-error diagnostic message that normally should be logged even in Release builds of the app
 * (to the console, via Crashlytics, etc). Should not be noisy.
 */
#define MMM_LOG_INFO(message, ...) \
	MMMLog(MMMLogLevelInfo, MMMLogContextFromObject(self), [NSString stringWithFormat:message, ## __VA_ARGS__ ])

/**
 * Outputs an important error message that should be logged even in Release builds of the app
 * (to the console, via Crashlytics, etc).
 */
#define MMM_LOG_ERROR(message, ...) \
	MMMLog(MMMLogLevelError, MMMLogContextFromObject(self), [NSString stringWithFormat:message, ## __VA_ARGS__ ])

/** Traces the current Objective-C method via MMM_LOG_TRACE() macro. */
#define MMM_LOG_TRACE_METHOD() \
	MMM_LOG_TRACE(@"Entering `%s`", sel_getName(_cmd))

/// The actual implementation of `MMMSensitiveInfo()` for Release builds truncating the passed value.
extern NSString *_MMMSensitiveInfo(NSString *value, NSInteger maxChars);

/**
 * Used to wrap sensitive strings such as emails or auth tokens when tracing them.
 * The strings are returned unchanged in Debug, but only the first maxChars characters are returned in Release
 * (`-maxChars` last characters in case `maxChars` is negative).
 */
static inline NSString *MMMSensitiveInfo(NSString *value, NSInteger maxChars) {
#if DEBUG
	return value;
#else
	return _MMMSensitiveInfo(value, maxChars);
#endif
}

NS_ASSUME_NONNULL_END
