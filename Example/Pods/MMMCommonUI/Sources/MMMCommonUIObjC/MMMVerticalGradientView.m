//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMVerticalGradientView.h"

@implementation MMMVerticalGradientView {
	UIColor *_topColor;
	UIColor *_bottomColor;
	MMMAnimationCurve _curve;
}

- (id)initWithTopColor:(UIColor *)topColor bottomColor:(UIColor *)bottomColor {
	return [self initWithTopColor:topColor bottomColor:bottomColor curve:MMMAnimationCurveLinear];
}

- (id)initWithTopColor:(UIColor *)topColor bottomColor:(UIColor *)bottomColor curve:(MMMAnimationCurve)curve {

	if (self = [super initWithFrame:CGRectZero]) {

		_curve = curve;

		_topColor = topColor;
		_bottomColor = bottomColor;

		// We are going to redraw when frame changes. Perhaps a single gradient can be scaled well without rendering.
		self.contentMode = UIViewContentModeRedraw;

		self.translatesAutoresizingMaskIntoConstraints = NO;

		self.opaque = NO;
		self.userInteractionEnabled = NO;
	}

	return self;
}

- (void)drawRect:(CGRect)rect {

	CGRect b = self.bounds;

	CGContextRef c = UIGraphicsGetCurrentContext();

	NSInteger numberOfSteps = (_curve == MMMAnimationCurveLinear) ? 2 : MIN(1 + CGRectGetHeight(b) / 5, 50);

	NSMutableArray *colors = [[NSMutableArray alloc] initWithCapacity:numberOfSteps];
	CGFloat *steps = alloca(numberOfSteps * sizeof(CGFloat));
	for (NSInteger i = 0; i < numberOfSteps; i++) {
		steps[i] = (CGFloat)i / (numberOfSteps - 1);
		UIColor *c = [MMMAnimation colorFrom:_topColor to:_bottomColor time:[MMMAnimation curvedTimeForTime:steps[i] curve:_curve]];
		[colors addObject:(id)c.CGColor];
	}

	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, steps);
	CGColorSpaceRelease(colorSpace);

	CGContextDrawLinearGradient(
		c,
		gradient,
		b.origin,
		CGPointMake(b.origin.x, b.origin.y + b.size.height),
		0
	);
	CGGradientRelease(gradient);
}

@end
