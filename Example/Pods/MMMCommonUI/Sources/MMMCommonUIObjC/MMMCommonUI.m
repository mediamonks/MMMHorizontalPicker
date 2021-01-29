//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMCommonUI.h"

@import MMMLog;
@import MMMCommonCore;

UIColor *MMMDebugColor(NSInteger index) {
	static dispatch_once_t onceToken;
	static NSArray *colors;
	dispatch_once(&onceToken, ^{
		// Taken from this palette: https://color.adobe.com/Vitamin-C-color-theme-492199/
		colors = @[
			[UIColor colorWithRed:0.0000 green:0.2627 blue:0.3451 alpha:1.0],
			[UIColor colorWithRed:0.1216 green:0.5412 blue:0.4392 alpha:1.0],
			[UIColor colorWithRed:0.7451 green:0.8588 blue:0.2235 alpha:1.0],
			[UIColor colorWithRed:1.0000 green:0.8824 blue:0.1020 alpha:1.0],
			[UIColor colorWithRed:0.9922 green:0.4549 blue:0.0000 alpha:1.0]
		];
	});
	return colors[(index * 6793) % colors.count];
}

void MMMDrawBorder(CGRect r, UIRectEdge edge, UIColor *color, CGFloat width) {

	CGFloat halfBorderWidth = width / 2;
	CGRect borderRect = UIEdgeInsetsInsetRect(
		r,
		UIEdgeInsetsMake(
			((edge & UIRectEdgeTop) == 0) ? 0 : halfBorderWidth,
			((edge & UIRectEdgeLeft) == 0) ? 0 : halfBorderWidth,
			((edge & UIRectEdgeBottom) == 0) ? 0 : halfBorderWidth,
			((edge & UIRectEdgeRight) == 0) ? 0 : halfBorderWidth
		)
	);

	CGContextRef c = UIGraphicsGetCurrentContext();

	// Note that we begin with the not shifted Y coordinate on purpose
	CGContextMoveToPoint(c, CGRectGetMinX(borderRect), CGRectGetMinY(r));

	if (edge & UIRectEdgeLeft)
		CGContextAddLineToPoint(c, CGRectGetMinX(borderRect), CGRectGetMaxY(borderRect));
	else
		CGContextMoveToPoint(c, CGRectGetMinX(borderRect), CGRectGetMaxY(borderRect));

	if (edge & UIRectEdgeBottom)
		CGContextAddLineToPoint(c, CGRectGetMaxX(borderRect), CGRectGetMaxY(borderRect));
	else
		CGContextMoveToPoint(c, CGRectGetMaxX(borderRect), CGRectGetMaxY(borderRect));

	if (edge & UIRectEdgeRight)
		CGContextAddLineToPoint(c, CGRectGetMaxX(borderRect), CGRectGetMinY(borderRect));
	else
		CGContextMoveToPoint(c, CGRectGetMaxX(borderRect), CGRectGetMinY(borderRect));

	if (edge & UIRectEdgeTop)
		CGContextAddLineToPoint(c, CGRectGetMinX(borderRect), CGRectGetMinY(borderRect));

	CGContextSetLineCap(c, kCGLineCapButt);
	CGContextSetLineJoin(c, kCGLineJoinMiter);
	CGContextSetLineWidth(c, width);

	[color setStroke];
	CGContextStrokePath(c);
}

CGFloat MMMPixelScale() {
	static CGFloat scale = 1;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		scale = [UIScreen mainScreen].scale;
	});
	return scale;
}

NSMutableAttributedString *MMMParseSimpleHTML(
	NSString *text,
	NSDictionary *baseAttributes,
	NSDictionary *regularAttributes,
	NSDictionary *emphasizedAttributes
) {

	NSError *__autoreleasing error = nil;

	NSAttributedString *attributedString = [[NSAttributedString alloc]
		initWithData:[text dataUsingEncoding:NSUTF8StringEncoding]
		options:@{
			NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType,
			NSCharacterEncodingDocumentAttribute : @(NSUTF8StringEncoding),
		}
		documentAttributes:nil
		error:&error
	];

	if (!attributedString) {
		return nil;
	}

	//
	// We get default fonts and colors (e.g. Times New Roman/black) from the above conversion.
	// Let's go through all the attributes and adjust the ones we are interested in.
	//
	NSMutableAttributedString *result = [attributedString mutableCopy];

	[attributedString
		enumerateAttributesInRange:NSMakeRange(0, attributedString.length)
		options:0
		usingBlock:^(NSDictionary<NSString *, id> *attrs, NSRange range, BOOL *stop) {

			// Let's cleanup all the attributes first, except for links
			for (NSString *attrName in attrs) {
				if (![attrName isEqualToString:NSLinkAttributeName]) {
					[result removeAttribute:attrName range:range];
				}
			}

			// We need to preserve emphasized text, so let's look for bold weight font and replace it with ours.
			UIFont *font = attrs[NSFontAttributeName];
			if (font) {
				if (font.fontDescriptor.symbolicTraits & UIFontDescriptorTraitBold) {
					[result addAttributes:emphasizedAttributes range:range];
				} else {
					[result addAttributes:regularAttributes range:range];
				}
			}
		}
	];

	// Note that we are adding base attributes afterwards, so they should not contains fonts, for example. 
	[result addAttributes:baseAttributes range:NSMakeRange(0, attributedString.length)];

	//
	// The conversion above can add extra newlines at the end of the resulting string, let's get rid of them
	//
	NSCharacterSet *charactersToTrim = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSInteger i = result.length - 1;
	while (i >= 0 && [charactersToTrim characterIsMember:[result.string characterAtIndex:i]])
		i--;
	if (i < result.length)
		[result deleteCharactersInRange:NSMakeRange(i + 1, result.length - (i + 1))];

	return result;
}

#pragma mark - MMMCaseTransform

NSAttributedStringKey const MMMCaseTransformAttributeName = @"MMMCaseTransform";

MMMCaseTransform const MMMCaseTransformOriginal = @"original";
MMMCaseTransform const MMMCaseTransformUppercased = @"uppercased";

@implementation NSAttributedString (MMMTempleMMMCommonUI)

- (NSAttributedString *)mmm_attributedStringApplyingCaseTransformWithLocale:(NSLocale *)locale {

	NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithAttributedString:self];

	[result
		enumerateAttribute:MMMCaseTransformAttributeName 
		inRange:NSMakeRange(0, result.length)
		// Note that the longest effective range is not required for uppercasing,
		// but will be needed for Title Case or similar transform.
		options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired // Nice. 61 characters.
		usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
			
			if (value == nil || [value isEqual:MMMCaseTransformOriginal]) {

				// Nothing to do, preserving the original case.
				// (Note that we are called for the parts of the string where our attribute is not assigned,
				// this is when the value is nil.)

			} else if ([value isEqual:MMMCaseTransformUppercased]) {
			
				[result
					replaceCharactersInRange:range 
					withString:[[result.string substringWithRange:range] uppercaseStringWithLocale:locale]
				];

			} else {
				NSAssert(NO, @"Unsupported value for '%@' attribute: '%@'", MMMCaseTransformAttributeName, value);
			}
		}
	];
	
	return result;
}

@end

@implementation NSDictionary (MMMTempleMMMCommonUI)

- (NSDictionary *)mmm_withAttributes:(NSDictionary *)attributes {
	NSMutableDictionary *result = [self mutableCopy];
	[result addEntriesFromDictionary:attributes];
	return result;
}

- (NSDictionary *)mmm_withColor:(UIColor *)color {
	NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:self];
	result[NSForegroundColorAttributeName] = color;
	return result;
}

- (NSDictionary *)mmm_withParagraphStyle:(void (^)(NSMutableParagraphStyle *ps))block {

	NSMutableDictionary *result = [self mutableCopy];

	NSMutableParagraphStyle *ps = result[NSParagraphStyleAttributeName];
	if (!ps) {
		ps = [[NSMutableParagraphStyle alloc] init];
		result[NSParagraphStyleAttributeName] = ps;
	} else if (![ps isKindOfClass:[NSMutableParagraphStyle class]]) {
		result[NSParagraphStyleAttributeName] = [ps mutableCopy];
	}

	block(ps);

	return result;
}

- (NSDictionary *)mmm_withAlignment:(NSTextAlignment)alignment {

	return [self mmm_withParagraphStyle:^(NSMutableParagraphStyle *ps) {
		ps.alignment = alignment;
	}];
}

@end

#pragma mark -

//
//
//
@implementation UIColor (MMMTempleMMMCommonUI)

- (BOOL)mmm_isTransparent {
	return CGColorGetAlpha(self.CGColor) < 1;
}

+ (NSError *)mmm_colorWithStringErrorWithMessage:(NSString *)message {
	return [NSError
		errorWithDomain:@"UIColor+MMMTemple"
		code:-1
		userInfo:@{ NSLocalizedDescriptionKey : message }
	];
}

+ (instancetype)mmm_colorWithString:(NSString *)s {

	NSError *error = nil;

	UIColor *result = [self mmm_colorWithString:s error:&error];

	NSAssert(
		result != nil,
		@"Could not parse color literal '%@': %@. (Use %s if you want to catch errors)",
		s, error.localizedDescription,
		sel_getName(@selector(mmm_colorWithString:error:))
	);

	return result;
}

+ (instancetype)mmm_colorWithString:(NSString *)s error:(NSError * __autoreleasing *)error {

	static dispatch_once_t onceToken;
	static NSCharacterSet *hexCharacters = nil;
	dispatch_once(&onceToken, ^{
		hexCharacters = [NSCharacterSet characterSetWithCharactersInString:@"01234567890abcdefABCDEF"];
	});

	NSScanner *scanner = [NSScanner scannerWithString:s];
	scanner.caseSensitive = NO;

	if ([scanner scanString:@"rgb" intoString:NULL]) {

		if (error) {
			*error = [self mmm_colorWithStringErrorWithMessage:@"We don't support rgb() or rgba() formats"];
		}

		return nil;

	} else {

		// Assuming a hexadecimal string at this point, just skipping the leading hash, if any
		[scanner scanString:@"#" intoString:NULL];

		// We could use scanHexInt: directly, but we want to ensure it's exactly 6 character string to crash early if we encounter something suspicious
		NSString *hex = nil;
		if (![scanner scanCharactersFromSet:hexCharacters intoString:&hex] || [hex length] != 6) {
			if (error)
				*error = [self mmm_colorWithStringErrorWithMessage:@"Expected exactly 6 hexadecimal characters"];
			return nil;
		}

		if (![scanner isAtEnd]) {
			if (error) {
				*error = [self mmm_colorWithStringErrorWithMessage:@"Got unexpected characters at the end of the input string"];
			}
			return nil;
		}

		// OK, now when we know the string consists of strictly 6 hex characters we still can use a scanner
		unsigned result = 0;
		if (![[NSScanner scannerWithString:hex] scanHexInt:&result]) {
			if (error) {
				*error = [self mmm_colorWithStringErrorWithMessage:@"Unexpected failure"];
			}
			NSAssert(NO, @"");
			return nil;
		}

		return [UIColor
			colorWithRed:((result >> 16) & 0xFF) / 255.0
			green:((result >> 8) & 0xFF) / 255.0
			blue:(result & 0xFF) / 255.0
			alpha:1
		];
	}
}

@end

CGFloat MMMHeightOfAreaCoveredByStatusBar(UIView *view, CGRect rect) {

	CGRect statusBarRect = [view convertRect:[UIApplication sharedApplication].statusBarFrame fromView:nil];

	// This is to work around the problem with UI rotations: it is possible that the status bar is still portrait
	// while the view is already landscape, and it can also be hidden (zero height);
	// in this case the height calculated as below will be large and will cause layout issues.
	// Returning 0 now assumming that the view using this function will eventually recalculate the status bar height
	// in response to UIApplicationDidChangeStatusBarFrameNotification.
	if (CGRectGetHeight(statusBarRect) <= 0 || CGRectGetHeight(statusBarRect) > CGRectGetWidth(statusBarRect))
		return 0;

	return MAX(0, CGRectGetMaxY(statusBarRect) - CGRectGetMinY(rect));
}

//
//
//
@implementation UIImage (MMMTempleMMMCommonUI)

+ (NSString *)mmm_cacheKeyForNamed:(NSString *)name height:(CGFloat)height tintColor:(UIColor *)tintColor {

	const CGFloat *components = CGColorGetComponents(tintColor.CGColor);

	NSMutableString *colorKey = [[NSMutableString alloc] init];
	for (NSInteger i = 0; i < CGColorGetNumberOfComponents(tintColor.CGColor); i++) {
		[colorKey appendFormat:@"-%.3f", components[i]];
	}

	return [NSString stringWithFormat:@"%@-%.1f%@", name, height, colorKey];
}

+ (UIImage *)mmm_imageFromPDFWithPath:(NSString *)path rasterizedForHeight:(CGFloat)height tintColor:(UIColor *)tintColor {

	CGPDFDocumentRef document = nil;
	CGPDFPageRef page = nil;
	UIImage *resultImage = nil;

	do {

		document = CGPDFDocumentCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:path]);
		if (!document) {
			MMM_LOG_ERROR(@"Could not open image at '%@' as a PDF", MMMPathRelativeToAppBundle(path));
			NSAssert(NO, @"");
			break;
		}

		CGPDFPageRef page = CGPDFDocumentGetPage(document, 1);
		if (!page) {
			MMM_LOG_ERROR(@"Could not get the first page of the PDF document at '%@'", MMMPathRelativeToAppBundle(path));
			NSAssert(NO, @"");
			break;
		}

		CGRect pageRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);

		CGFloat roundedHeight = MMMPixelRound(height);

		CGFloat scale = roundedHeight <= 0 ? 1 : roundedHeight / pageRect.size.height;

		CGSize resultImageSize = CGSizeMake(MMMPixelRound(pageRect.size.width * scale), roundedHeight);

		UIGraphicsBeginImageContextWithOptions(resultImageSize, NO, 0);

		CGContextRef c = UIGraphicsGetCurrentContext();

		if (tintColor) {

			CGContextSaveGState(c);
			CGContextTranslateCTM(c, -pageRect.origin.x, -pageRect.origin.y + roundedHeight);
			CGContextScaleCTM(c, scale, -scale);
			CGContextDrawPDFPage(c, page);
			CGContextRestoreGState(c);

			[tintColor setFill];
			CGContextSetBlendMode(c, kCGBlendModeSourceIn);
			CGContextFillRect(c, CGRectMake(0, 0, resultImageSize.width, resultImageSize.height));

		} else {

			CGContextTranslateCTM(c, -pageRect.origin.x, -pageRect.origin.y + roundedHeight);
			CGContextScaleCTM(c, scale, -scale);
			CGContextDrawPDFPage(c, page);
		}

		resultImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();

		// The rendering mode UIImageRenderingModeAlwaysOriginal was selected before only when tintColor was provided.
		// I am sure this will cause incompatibilities with the older code, but always using "original" seems more logical.
		resultImage = [resultImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

	} while (0);

	if (page)
		CGPDFPageRelease(page);
	if (document)
		CGPDFDocumentRelease(document);

	return resultImage;
}

+ (UIImage *)mmm_imageFromPDFNamed:(NSString *)name rasterizedForHeight:(CGFloat)height tintColor:(UIColor *)tintColor {

	static NSCache *cache = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		cache = [[NSCache alloc] init];
		cache.totalCostLimit = 1 * 1024 * 1024;
	});

	NSString *keyName = [self mmm_cacheKeyForNamed:name height:height tintColor:tintColor];

	UIImage *result = [cache objectForKey:keyName];
	if (result)
		return result;

	NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"pdf"];
	if (!path) {
		MMM_LOG_ERROR(@"Could not find image named '%@'", name);
		NSAssert(NO, @"");
		return nil;
	}

	UIImage *resultImage = [self mmm_imageFromPDFWithPath:path rasterizedForHeight:height tintColor:tintColor];

	if (resultImage) {
		[cache setObject:resultImage forKey:keyName cost:resultImage.size.width * resultImage.size.height];
	}

	return resultImage;
}

+ (UIImage *)mmm_imageFromPDFNamed:(NSString *)name tintColor:(UIColor *)tintColor {
	return [self mmm_cacheKeyForNamed:name height:0 tintColor:tintColor];
}

+ (UIImage *)mmm_imageFromPDFNamed:(NSString *)name rasterizedForHeight:(CGFloat)height {
	return [self mmm_imageFromPDFNamed:name rasterizedForHeight:height tintColor:nil];
}

+ (UIImage *)mmm_rectangleWithSize:(CGSize)size color:(UIColor *)color {

	UIGraphicsBeginImageContextWithOptions(size, NO, 0);

	[color setFill];
	CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, size.width, size.height));

	UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	return result;
}

+ (UIImage *)mmm_singlePixelWithColor:(UIColor *)color {
	return [self mmm_rectangleWithSize:CGSizeMake(1, 1) color:color];
}

@end

@implementation UIViewController (MMMTempleMMMCommonUI)

- (void)mmm_modallyPresentViewController:(UIViewController *)viewController
	animated:(BOOL)animated
	completion:(void (^)(void))completion
{
	viewController.modalPresentationStyle = UIModalPresentationFullScreen;
	[self presentViewController:viewController animated:animated completion:completion];
}

@end

//
//
//
CGFloat MMMPhaseForDashedPattern(CGFloat lineLength, CGFloat dashLength, CGFloat skipLength) {

	// We want to tweak the phase so the start of the line looks (almost) the same as its end.
	// The idea here is that in order for the line to be cut symmetrically either the center of the dash or the center
	// of the skip part of the pattern should reside in the center of the line. We calculate two phases assuming either
	// dashed or skipped part in the center and then picking the one leading to the cut on the dashed part of the pattern.
	// Note that we don't want to cut in the middle of a pixel, that's why we have "pixel" rounds below.
	CGFloat patternWidth = dashLength + skipLength;

	// Half of the line length before the dashed part in the center.
	// | ----  ----  ... ----  --|--  ----  ...
	// [          dw                  ]
	CGFloat dw = (lineLength - dashLength) / 2 + patternWidth;
	CGFloat phaseDash = -MMMPixelRound(dw - floor(dw / patternWidth) * patternWidth);

	// Half of the line length with the skipped part in the center.
	// |--  ----  ----  ... ---- | ----  ...
	// [          sw                     ]
	CGFloat sw = (lineLength + skipLength) / 2 + patternWidth;
	CGFloat phaseSkip = -MMMPixelRound(sw - floor(sw / patternWidth) * patternWidth);

	if (phaseDash >= -skipLength && phaseSkip >= -skipLength) {
		// Let's try to make the skip smaller at least.
		return MAX(phaseDash, phaseSkip);
	} else {
		// Maximizing the dashed part.
		return MIN(phaseDash, phaseSkip);
	}
}

//
//
//
void MMMAddDashedCircle(CGPoint center, CGFloat radius, CGFloat dashLength, CGFloat skipLength) {

    CGContextRef context = UIGraphicsGetCurrentContext();

	//
	// Rendering the circle as a polygon, not as an ellipse, so we can control the number of segments it is divided
	// into, know it's exact length, so the adjustment of dashed pattern below work.
	// (No, it would not be 2 * M_PI with CGContextAddEllipseInRect().)
	//
	const NSInteger numberOfKnots = 64;
	for (NSInteger i = 0; i < numberOfKnots; i++) {
		double angle = 2 * M_PI * i / numberOfKnots;
		CGPoint p = CGPointMake(center.x + radius * cos(angle), center.y + radius * sin(angle));
		if (i == 0) {
			CGContextMoveToPoint(context, p.x, p.y);
		} else {
			CGContextAddLineToPoint(context, p.x, p.y);
		}
	}
	CGFloat circleLength = numberOfKnots * 2 * radius * sin(M_PI / numberOfKnots);
	CGContextClosePath(context);

	//
	// Setting/ajusting the dash pattern.
	//
    CGFloat lengths[] = { dashLength, skipLength };

	// Adjusting the dashed part of the pattern a little bit so it connects properly with the start of the circle.
	CGFloat patternLength = lengths[0] + lengths[1];
	NSInteger fullPatterns = roundf(circleLength / patternLength);
	CGFloat remainder = circleLength - fullPatterns * patternLength;
	lengths[0] += remainder / fullPatterns;

    CGContextSetLineDash(context, 0, lengths, sizeof(lengths) / sizeof(lengths[0]));

	//
	// Let's use reasonable defaults for the line's width and cap.
	// The user's code has a chance to override this before stroking the path.
	//
    CGContextSetLineWidth(context, 1);
    CGContextSetLineCap(context, kCGLineCapButt);
}
