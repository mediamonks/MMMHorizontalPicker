//
// MMMCommonCore. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#if !TARGET_OS_WATCH

/** 
 * YES, if the current iOS version is greater or equal to the provided version string. 
 */
extern BOOL MMMIsSystemVersionGreaterOrEqual(NSString *version);

#endif

/** 
 * This can be used for bodies of methods that are not designated initializers for a class, for example:
 *
 * \code
 * - (id)init {
 *     MMM_NON_DESIGNATED_INITIALIZER();
 * }
 * \endcode
 *
 * Will throw internal inconsitency exception with a nice message (via NSAssert) and return nil.
 *
 * Note that this is not needed anymore as much when the compiler can enforce designated initializers.
 */
#define MMM_NON_DESIGNATED_INITIALIZER() \
	NSAssert(NO, @"%s is not a designated initializer for %@", sel_getName(_cmd), self.class); \
	return nil;

/** 
 * Throws an assertion failure with a message indicating that the method this macro is used within must be implemented.
 *
 * This is handy for those methods that must be implemented in subclasses, for example:
 *
 * \code 
 * - (void)doSomethingImportant {
 *     MMM_MUST_BE_IMPLEMENTED();
 * }
 * \endcode
 */
#define MMM_MUST_BE_IMPLEMENTED() \
	NSAssert(NO, @"%s must be implemented in %@", sel_getName(_cmd), self.class);

/**
 * Throws an assertion failure in case the given shared instance is nil with a message indicating that
 * an instance of the current class must be explicitly initialized somewhere.
 */
#define MMM_NOT_REALLY_A_SINGLETON(sharedInstance) \
	NSAssert( \
		(sharedInstance) != nil, \
		@"An instance of %@ must be explicitly initialized before its '%s' method can be used", \
		self, sel_getName(_cmd) \
	);

/** 
 * For a path in one of the known subfolders of the app's sandbox (such as Library or Caches) returns a relative path prefixed 
 * with tokens like <Library> or <Bundle>. Returns the path unchanged in case it does not seem to be in a known folder.
 * Simple comparison is performed, the path is not normalized beforehand, etc. 
 * This is used only for direct output to logs, i.e. it's human readable and the format should not be relied upon.
 */
extern NSString *MMMPathRelativeToAppBundle(NSString *path);

/** @{ */

/** 
 * These macro are used to help building those function returning a diagnostic string for a value of enumeration.
 *
 * Example:
 * \begincode
	extern NSString *NSStringFromUGAContentTagType(UGAContentTagType tagType) {
		MMM_ENUM_NAME_BEGIN(UGAContentTagType, tagType)
			MMM_ENUM_CASE(UGAContentTagTypeMealType)
			...
			MMM_ENUM_CASE(UGAContentTagTypeProductType)
			MMM_ENUM_CASE(UGAContentTagTypeTipType)
		MMM_ENUM_NAME_END()
	}
 * \endcode
 *
 * (NSStringFromUGAContentTagType(UGAContentTagTypeMealType) will return @"MealType" in this case.)
 */

#define _MM_ENUM_STRING(value) @ #value

extern NSString *_MMMStringForEnumerationValue(NSString *enumTypeName, NSString *enumValueName);

#define MMM_ENUM_NAME_BEGIN(type, value) \
	type __value = value; \
	NSString * const __typeName = _MM_ENUM_STRING(type); \
	switch (__value) {

#define MMM_ENUM_CASE(value) \
	case value: \
		return _MMMStringForEnumerationValue(__typeName, _MM_ENUM_STRING(value));

// Note that we are not adding the default clause here, this will allow to get compiler warnings whenever a new enumeration value is added
#define MMM_ENUM_NAME_END() \
	} \
	return [NSString stringWithFormat:@"#%ld", (long)__value];

/** @} */

//
//
//
@interface NSDictionary (MMMTemple)

/**
 * A dictionary built from the receiver by adding values from another dictionary.
 * The other dictionary can be nil.
 * This is to make it more convenient to add stuff to literal dictionaries, such as Auto Layot metrics dictionaries
 * or CoreText attribute dictionaries. 
 */
- (NSDictionary *)mmm_extendedWithDictionary:(NSDictionary *)d;

@end

//
//
//
@interface NSScanner (MMMTemple)

/** Grabs and returns the next character or 0 in case it's the scanner is at end. */
- (unichar)mmm_scanNextCharacter NS_REFINED_FOR_SWIFT;

@end

//
//
//
@interface NSMutableCharacterSet (MMMTemple)

/** Convenience shortcut for `addCharactersInRange`. Adds a range of characters from first to last (including them both). */
- (void)mmm_addCharactersFrom:(unichar)fist to:(unichar)last;

@end

//
//
//
@interface NSObject (MMMTemple)

/** The receiver itself, or nil, if the receiver is [NSNull null]. */
- (id)mmm_stripNSNull;

@end

/**
 * Roughly a curl-equivanlent string for the given request. 
 * It's handy to dump all the outgoing requests this way.
 */
extern NSString *MMMCurlStringFromRequest(NSURLRequest *request);

/**
 * A string version of the given NSData object suitable for logging. Typically used with network responses, when we get
 * something we cannot even parse, then we log at least the beginning of it.
 * We try to interpret it as a UTF-8 encoded string first, and if it's not possible, then resort to a hex dump.
 * The result will be shorter than `maxStringLength` characters (unless this parameter is unreasonably small)
 * and an ellipsis will be added in case of truncation.
 */
extern NSString *MMMStringForLoggingFromData(NSData *data, NSInteger maxStringLength);

//
//
//
@interface NSError (MMMTemple)

/**
 * Description including underlying errors in a bit more readable form.
 * For example, the error code -1 is not shown and underlying errors are displayed in a chain that is easier to digest.
 */
- (NSString *)mmm_description;

/** A shortcut fetching the underlying error. */
- (nullable NSError *)mmm_underlyingError;

/** @{ */

/** A convenience initializer accepting an underlying error as a parameter (can be nil). */
+ (NSError *)mmm_errorWithDomain:(NSString *)domain
	code:(NSInteger)code
	message:(NSString *)message
	underlyingError:(nullable NSError *)underlyingError;

/** An initializer with the code being optional (set to -1, so is not displayed by mmm_description). */
+ (NSError *)mmm_errorWithDomain:(NSString *)domain
	message:(NSString *)message
	underlyingError:(nullable NSError *)underlyingError;

/** Another initializer hiding both the code (setting it to -1) and the underlyingError. */
+ (NSError *)mmm_errorWithDomain:(NSString *)domain
	message:(NSString *)message;

/** @} */

@end

/** 
 * Properly escaped URL query string from a dictionary of key-value pairs.
 * The keys are sorted alphabetically, so the same result is produced for the same dictionary. 
 */
extern NSString *MMMQueryStringFromParameters(NSDictionary<NSString *, NSString *> *parameters);

/** The function that is used by MMMQueryStringFromParameters() to escape parameter names or values. */
extern NSString *MMMQueryStringFromParametersEscape(NSString *s);

//
//
//
@interface NSString (MMMTemple)

/** 
 * Returns a string with variables in the form ${variable_name} being replaced with values from the provided dictionary
 * under the keys corresponding to "variable_name". This is handy for translatable strings, where the order of arguments 
 * might change and we don't want to use tricky syntax of stringWithFormat:.
 *
 * Note that keys are currently case-sensitive and the implementation is not very efficient, i.e. it should not be used 
 * with very long text.
 */
- (NSString *)mmm_stringBySubstitutingVariables:(NSDictionary *)vars;

@end

//
//
//
@interface NSDate (MMMTemple)

/** 
 * NSDate from internet timestamps, ISO8601-like strings like "2016-10-22T10:23:28Z". 
 * We support "Internet profile" of ISO8601, as described in RFC3339, and also allow the timezone or field separators to be absent. 
 */
+ (NSDate *)mmm_dateWithInternetTimeString:(NSString *)s;

@end

//
//
//
@interface NSArray<ObjectType> (MMMTemple)

/** The original array cut into subarrays with each slice except perhaps the last one consisting of maxLength elements. */
- (NSArray<ObjectType> *)mmm_arrayOfSlicesWithMaxLength:(NSInteger)maxLength
	NS_SWIFT_NAME(mmm_arrayOfSlices(withMaxLength:));

/** Performs the given block for each pair of the elements of the array from left to right,
 * like (a[0], [1]), then (a[1], [2]), etc, i.e. every element except for the first and the last will participate in two pairs. */
- (void)mmm_forEachPair:(void (NS_NOESCAPE ^)(ObjectType prev, ObjectType next))block
	NS_SWIFT_NAME(mmm_forEachPair(_:));

/** Performs the given block for every element of the array. */
- (void)mmm_forEach:(void (NS_NOESCAPE ^)(ObjectType obj, NSInteger index))block
	NS_SWIFT_NAME(mmm_forEach(_:)) NS_SWIFT_UNAVAILABLE("Use Swift's forEach(_:) instead");

/** Returns objects matching the given predicate block. */
- (NSArray<ObjectType> *)mmm_objectsMatching:(BOOL (NS_NOESCAPE ^)(ObjectType obj))block
	NS_SWIFT_UNAVAILABLE("Use Swift's filter(_:) instead");

/** Returns the first object for which the given predicate block returns YES; nil otherwise. */
- (ObjectType)mmm_firstObjectMatching:(BOOL (NS_NOESCAPE ^)(ObjectType obj))block
	NS_SWIFT_UNAVAILABLE("Use Swift's first(where:) instead");

@end

//
//
//
@interface NSMutableArray<ObjectType> (MMMTemple)

/** Removes objects matching the given predicate block. */
- (void)mmm_removeObjectsMatching:(BOOL (NS_NOESCAPE ^)(ObjectType obj))block
	NS_SWIFT_UNAVAILABLE("Use Swift's removeAll(where:) instead");

@end

//
//
//
@interface NSData (MMMTemple)

/**
 * NSData object with a hex-encoded string. E.e. @"001213" will give NSData consisting of 3 bytes 0x00, 0x12, and 0x13.
 * This is handy for unit tests where NSData objects are expected.
 * Note that we ignore any non-hex characters between individual bytes, so you can insert spaces, for example.
 */
+ (id)mmm_dataWithHexEncodedString:(NSString *)string;

@end

/**
 * YES, if the given string might be an email address.
 *
 * This is not a validation but a basic sanity check: only checking for the presence of at least one '@'
 * and at least one dot character.
 */
extern BOOL MMMSeemsLikeEmail(NSString *email);

NS_ASSUME_NONNULL_END
