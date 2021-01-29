//
// MMMCommonCore. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMCommonCore.h"

#if !TARGET_OS_WATCH && !SWIFT_PACKAGE

#import <UIKit/UIKit.h>

BOOL MMMIsSystemVersionGreaterOrEqual(NSString *version) {
	return [version compare:[[UIDevice currentDevice] systemVersion] options:NSNumericSearch] != NSOrderedDescending;
}

#endif

NSString *MMMPathRelativeToAppBundle(NSString *path) {

	static NSMutableDictionary<NSString *, NSString *> *pathToPrefix = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		pathToPrefix = [[NSMutableDictionary alloc] init];
		pathToPrefix[NSTemporaryDirectory()] = @"Temp";
		pathToPrefix[[[NSBundle mainBundle] bundlePath]] = @"App";
		pathToPrefix[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]] = @"Documents";
		pathToPrefix[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0]] = @"Library";
		pathToPrefix[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0]] = @"Caches";
	});

	for (NSString *p in pathToPrefix.keyEnumerator) {
		if ([path hasPrefix:p]) {
			NSString *prefix = [NSString stringWithFormat:@"<%@>", pathToPrefix[p]];
			return [prefix stringByAppendingPathComponent:[path substringFromIndex:p.length]];
		}
	}

	return path;
}

NSString *_MMMStringForEnumerationValue(NSString *enumTypeName, NSString *enumValueName) {

	NSCAssert([enumValueName hasPrefix:enumTypeName],
		@"All values of enumeration %@ are assumed to have their names beginning with '%@'",
		enumTypeName, enumTypeName
	);

	NSString *pascalCaseString = [enumValueName substringFromIndex:[enumTypeName length]];

	//
	// Let's turn the PascalCase string we've got into a kebab-case one, so it is easier to read in the logs.
	//
	static dispatch_once_t onceToken;
	static NSRegularExpression *regexp;
	dispatch_once(&onceToken, ^{
		NSError *error = nil;
		regexp = [NSRegularExpression 
			regularExpressionWithPattern:@"(\\p{Lu}|\\d){2,}(?=\\p{Lu}\\p{Ll}|\\z) # Abbreviations including numbers\n"
				@"|\\p{Lu}?\\p{Ll}+ # Normal parts\n"
				@"|\\d+ # Numbers\n" 
			options:NSRegularExpressionAllowCommentsAndWhitespace 
			error:&error
		];
		NSCAssert(regexp != nil, @"");
	});
	NSMutableString *__block result = [[NSMutableString alloc] init];
	[regexp
		enumerateMatchesInString:pascalCaseString
		options:0
		range:NSMakeRange(0, pascalCaseString.length)
		usingBlock:^(NSTextCheckingResult *r, NSMatchingFlags flags, BOOL *stop) {

			NSString *s = [[pascalCaseString substringWithRange:r.range] lowercaseString];
			if ([result length] > 0)
				[result appendString:@"-"];
			[result appendString:s];
		}
	];

	return result;
}

@implementation NSDictionary (MMMTemple)

- (NSDictionary *)mmm_extendedWithDictionary:(NSDictionary *)d {

	if (!d || [d count] == 0)
		return self;

	NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:self];
	[result addEntriesFromDictionary:d];
	return result;
}

@end

//
//
//
@implementation NSScanner (MMMTemple)

- (unichar)mmm_scanNextCharacter {

	if ([self isAtEnd])
		return 0;

	unichar result = [self.string characterAtIndex:self.scanLocation];

	self.scanLocation++;

	return result;
}

@end

//
//
//
@implementation NSMutableCharacterSet (MMMTemple)

- (void)mmm_addCharactersFrom:(unichar)first to:(unichar)last {
	[self addCharactersInRange:NSMakeRange(first, last - first + 1)];
}

@end

//
//
//
@implementation NSObject (MMMTemple)

- (id)mmm_stripNSNull {
	return ((id)self == [NSNull null]) ? nil : self;
}

@end

//
//
//
static NSString *MMMShellEscapedString(NSString *s) {
	return s ? [s stringByReplacingOccurrencesOfString:@"'" withString:@"'''"] : nil;
}

NSString *MMMCurlStringFromRequest(NSURLRequest *request) {

	NSMutableString *headers = [[NSMutableString alloc] init];
	for (NSString *name in request.allHTTPHeaderFields) {
		NSString *value = request.allHTTPHeaderFields[name];
		if ([headers length] > 0)
			[headers appendString:@" "];
		[headers appendFormat:@"-H '%@: %@'", MMMShellEscapedString(name), MMMShellEscapedString(value)];
	}

	NSString *dataBinary = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];

	return [NSString
		stringWithFormat:@"curl -i -X %@ '%@' %@ --data-binary '%@'",
			request.HTTPMethod,
			request.URL,
			headers,
			MMMShellEscapedString(dataBinary)
	];
}

//
//
//
NSString *MMMStringForLoggingFromData(NSData *data, NSInteger maxStringLength) {

	// Most likely we either got nothing or something textual, so let's try reading it as a string first.
	// Note that we might end up with very long string here, however truncating the data before the conversion
	// would be tricky as we would need to avoid cutting a UTF-8 sequence.
	NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (!s) {
		// Cannot be decoded as UTF-8, then let's have a hex dump at least. We can truncate the data a bit this time.
		s = [[data subdataWithRange:NSMakeRange(0, MIN((maxStringLength + 1) / 2, data.length))] description];
	}

	NSInteger budget = maxStringLength - 2;

	NSMutableString *result = [[NSMutableString alloc] initWithCapacity:MIN(32, maxStringLength)];
	[result appendString:@"'"];

	if (s.length <= budget) {

		[result appendString:s];

	} else {

		static NSString * const ellipsis = @"...";
		budget -= ellipsis.length;

		[result appendString:[s substringToIndex:MAX(4, MIN(s.length, budget))]];
		[result appendString:ellipsis];
	}

	[result appendString:@"'"];

	return result;

}

//
//
//
@implementation NSError (MMMTemple)

- (NSString *)mmm_description {

	NSMutableString *result = [[NSMutableString alloc] init];

	NSError *e = self;
	// Note that Swift errors returning `nil` for underlyingError might end up with NSNull there.
	while (e && ![e isKindOfClass:[NSNull class]]) {

		if ([result length] > 0)
			[result appendString:@" > "];

		// Treating the -1 error code as "other" kind of error, where only the message matters for diagnostics.
		if (e.code != -1)
			[result appendString:[NSString stringWithFormat:@"%@ (%@#%ld)", e.localizedDescription, e.domain, (long)e.code]];
		else
			[result appendString:[NSString stringWithFormat:@"%@ (%@)", e.localizedDescription, e.domain]];

		e = e.userInfo[NSUnderlyingErrorKey];
	}

	return result;
}

- (NSError *)mmm_underlyingError {
	return self.userInfo[NSUnderlyingErrorKey];
}

+ (NSError *)mmm_errorWithDomain:(NSString *)domain message:(NSString *)message {
	return [self mmm_errorWithDomain:domain code:-1 message:message underlyingError:nil];
}

+ (NSError *)mmm_errorWithDomain:(NSString *)domain
	message:(NSString *)message
	underlyingError:(NSError *)underlyingError
{
	return [self mmm_errorWithDomain:domain code:-1 message:message underlyingError:underlyingError];
}

+ (NSError *)mmm_errorWithDomain:(NSString *)domain
	code:(NSInteger)code
	message:(NSString *)message
	underlyingError:(NSError *)underlyingError
{
	NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
	userInfo[NSLocalizedDescriptionKey] = message;
	if (underlyingError) {
		userInfo[NSUnderlyingErrorKey] = underlyingError;
	}
	return [NSError errorWithDomain:domain code:code userInfo:userInfo];
}

@end

//
//
//
NSString *MMMQueryStringFromParametersEscape(NSString *s) {

	if (!s || (id)s == [NSNull null]) {
		return @"";
	}

	// We don't want to encode all the characters, otherwise it'll be hard to read posted data.
	static NSMutableCharacterSet *allowedCharacters;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{

		allowedCharacters = [[NSMutableCharacterSet alloc] init];

		// From https://tools.ietf.org/html/rfc3986#page-23:
		// query = *( pchar / "/" / "?" )
		// pchar = unreserved / pct-encoded / sub-delims / ":" / "@"
		// unreserved = ALPHA / DIGIT / "-" / "." / "_" / "~"
		// sub-delims = "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="

		// 'unreserved' are allowed.
		[allowedCharacters addCharactersInRange:NSMakeRange('A', 'Z' - 'A' + 1)];
		[allowedCharacters addCharactersInRange:NSMakeRange('a', 'z' - 'a' + 1)];
		[allowedCharacters addCharactersInRange:NSMakeRange('0', '9' - '0' + 1)];
		[allowedCharacters addCharactersInString:@"-._~"];

		// 'sub-delims' (except '=' and '&') are allowed in parameter names/values.
		// (Though '+' can be trated as a space, so needs escaping.)
		[allowedCharacters addCharactersInString:@"!$'()*,;"];

		// And let's don't forget these as well.
		[allowedCharacters addCharactersInString:@":@"];

		// "/" and "? are technically allowed within the query, but it can be risky to keep them unescaped.
	});

	return [s stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
}

NSString *MMMQueryStringFromParameters(NSDictionary *parameters) {

	NSMutableString *result = [[NSMutableString alloc] init];

	for (NSString *key in [[parameters allKeys] sortedArrayUsingSelector:@selector(compare:)]) {

		NSCAssert([key isKindOfClass:[NSString class]], @"");

		if ([result length] > 0) {
			[result appendString:@"&"];
		}

		[result appendString:MMMQueryStringFromParametersEscape(key)];
		[result appendString:@"="];
		[result appendString:MMMQueryStringFromParametersEscape(parameters[key])];
	}

	return result;
}

//
//
//
@implementation NSString (MMMTemple)

- (NSString *)mmm_stringBySubstitutingVariables:(NSDictionary *)vars {

	// TODO: ineffective implementation here, should be improved for large strings or large number of substitutions
	NSString *result = self;
	for (NSString *key in [vars allKeys]) {
		NSString *term = [NSString stringWithFormat:@"${%@}", key];
		result = [result stringByReplacingOccurrencesOfString:term withString:[vars[key] description]];
	}

	return result;
}

@end

//
//
//
@implementation NSDate (MMMTemple)

+ (NSDate *)mmm_dateWithInternetTimeString:(NSString *)s {

	static NSString * const formatterKey = @"mmm_dateWithInternetTimeStringFormatter";

	NSDateFormatter *formatter = [NSThread currentThread].threadDictionary[formatterKey];
	if (!formatter) {
		formatter = [[NSDateFormatter alloc] init];
		formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
		formatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
		[[NSThread currentThread].threadDictionary setObject:formatter forKey:formatterKey];
	}

	static NSArray<NSString *> *formats = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		formats = @[
			@"yyyy-MM-dd'T'HH:mm:ss'.'SSSSZZZ",
			@"yyyy-MM-dd'T'HH:mm:ssZZZ",
			@"yyyy-MM-dd'T'HH:mm:ss",
			@"yyyy-MM-dd'T'HH:mm:ss'.'SSSS",
            @"yyyy-MM-dd",
			@"yyyyMMdd'T'HHmmss'.'SSSSZZZ",
			@"yyyyMMdd'T'HHmmssZZZ",
			@"yyyyMMdd'T'HHmmss'.'SSSS",
			@"yyyyMMdd'T'HHmmss",
		];
	});

	// In addition to strict RFC3339 we are trying a couple of more of similar formats in case it fails.
	for (NSString *format in formats) {
		formatter.dateFormat = format;
		NSDate *result = [formatter dateFromString:s];
		if (result)
			return result;
	}

	return nil;
}

@end

//
//
//
@implementation NSArray (MMMTemple)

- (NSArray *)mmm_arrayOfSlicesWithMaxLength:(NSInteger)maxLength {

	NSMutableArray *result = [[NSMutableArray alloc] init];
	for (NSInteger i = 0; i < self.count;) {

		NSInteger sliceLength = MIN(maxLength, self.count - i);

		NSMutableArray *slice = [[NSMutableArray alloc] initWithCapacity:sliceLength];
		for (NSInteger j = 0; j < sliceLength; j++) {
			[slice addObject:self[i + j]];
		}

		[result addObject:slice];

		i += sliceLength;
	}

	return result;
}

- (void)mmm_forEach:(void (NS_NOESCAPE ^)(id obj, NSInteger index))block {
	NSInteger index = 0;
	for (id obj in self) {
		block(obj, index++);
	}
}

- (void)mmm_forEachPair:(void (NS_NOESCAPE ^)(id prev, id next))block {

	if (self.count == 0)
		return;

	for (NSInteger i = 0; i < self.count - 1; i++) {
		block(self[i], self[i + 1]);
	}
}

- (NSArray *)mmm_objectsMatching:(BOOL (NS_NOESCAPE ^)(id obj))block {

	NSMutableArray *result = [[NSMutableArray alloc] init];

	for (id obj in self) {
		if (block(obj)) {
			[result addObject:obj];
		}
	}

	return result;
}

- (id)mmm_firstObjectMatching:(BOOL (NS_NOESCAPE ^)(id obj))block {

	for (id obj in self) {
		if (block(obj))
			return obj;
	}
	
	return nil;
}

@end

//
//
//
@implementation NSMutableArray (MMMTemple)

- (void)mmm_removeObjectsMatching:(BOOL (NS_NOESCAPE^)(id obj))block {
	[self removeObjectsInArray:[self mmm_objectsMatching:block]];
}

@end

//
//
//
@implementation NSData (MMMTemple)

+ (id)mmm_dataWithHexEncodedString:(NSString *)string {

	NSMutableData *result = [[NSMutableData alloc] initWithCapacity:[string length] / 2];
	if (!result)
		return nil;

	[result setLength:[string length] / 2];

	uint8_t *dst = (uint8_t *)[result mutableBytes];

	// The current byte that
	uint8_t b = 0;

	// How maby nibs we've outputted into the curren byte, 0, 1 or 2.
	NSInteger nibs = 0;

	for (NSInteger i = 0; i < string.length; i++) {

		unichar ch = [string characterAtIndex:i];

		uint8_t nib;
		if ('0' <= ch && ch <= '9') {
			nib = ch - '0';
		} else if ('a' <= ch && ch <= 'f') {
			nib = 10 + ch - 'a';
		} else if ('A' <= ch && ch <= 'F') {
			nib = 10 + ch - 'A';
		} else {
			if (nibs == 0) {
				// We are ignoring non-hex digits between the bytes, because it can be convenient to separate them.
				continue;
			} else {
				// But we don't allow interruptions between the nibs, as it's not something common.
				return nil;
			}
		}

		b = (b << 4) | nib;
		nibs++;

		if (nibs == 2) {
			*dst++ = b;
			nibs = 0;
			b = 0;
		}
	}

	if (nibs != 0) {
		// Should have outputted the last byte in full.
		return nil;
	}

	[result setLength:dst - (uint8_t *)[result mutableBytes]];

	NSAssert(result.length <= [string length] / 2, @"");

	return result;
}

@end

BOOL MMMSeemsLikeEmail(NSString *email) {
	NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"^(.+)@(.+)\\.(.+)$" options:0 error:nil];
	return [re rangeOfFirstMatchInString:email options:0 range:NSMakeRange(0, email.length)].location == 0;
}
