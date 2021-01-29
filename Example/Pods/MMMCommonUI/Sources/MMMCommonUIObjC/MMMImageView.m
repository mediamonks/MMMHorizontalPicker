//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMImageView.h"

#import "MMMCommonUI.h"
#import "MMMLayout.h"

@implementation MMMImageView {

	// I need a subview that can go outside of our bounds and displays our image, UIImageView can still do this perfectly,
	// we just don't let it play with the alignment rect.
	UIImageView *_imageView;

	NSLayoutConstraint *_aspectRatioConstraint;
}

- (id)init {
	return [self initWithImage:nil highlightedImage:nil];
}

- (id)initWithImage:(UIImage *)image {
	return [self initWithImage:image highlightedImage:nil];
}

- (id)initWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage {

	if (self = [super initWithFrame:CGRectZero]) {

		self.translatesAutoresizingMaskIntoConstraints = NO;
		self.userInteractionEnabled = NO;

		_imageView = [[UIImageView alloc] init];
		[self addSubview:_imageView];

		self.image = image;
		self.highlightedImage = highlightedImage;
	}
	
	return self;
}

- (void)setContentMode:(UIViewContentMode)contentMode {
	// TODO: we can support content modes too, aspect fit/fill could be useful
	NSAssert(NO, @"We don't support %s", sel_getName(_cmd));
}

- (UIImage *)currentImage {
	return self.highlighted ? (_highlightedImage ?: _image) : _image;
}

- (void)imageDidChange {

	// Don't show it alignment rect, it cannot handle it.
	_imageView.image = [[self currentImage] imageWithAlignmentRectInsets:UIEdgeInsetsZero];

	[self invalidateIntrinsicContentSize];
	[self setNeedsUpdateConstraints];
	[self setNeedsLayout];
}

- (void)setImage:(UIImage *)image {
	_image = image;
	[self imageDidChange];
}

- (void)setHighlightedImage:(UIImage *)highlightedImage {
	_highlightedImage = highlightedImage;
	[self imageDidChange];
}

- (void)setHighlighted:(BOOL)highlighted {
	if (_highlighted != highlighted) {
		_highlighted = highlighted;
		[self imageDidChange];
	}
}

- (void)updateConstraints {

	[super updateConstraints];

	_aspectRatioConstraint.active = NO;

	if (![self currentImage])
		return;

	CGSize s = [self intrinsicContentSize];
	_aspectRatioConstraint = [NSLayoutConstraint
		constraintWithItem:self attribute:NSLayoutAttributeWidth
		relatedBy:NSLayoutRelationEqual
		toItem:self attribute:NSLayoutAttributeHeight
		multiplier:s.width / s.height constant:0
	];
	_aspectRatioConstraint.active = YES;
}

- (void)layoutSubviews {

	if (![self currentImage])
		return;

	CGRect b = self.bounds;

	CGSize imageAlignmentRectSize = [self intrinsicContentSize];

	CGPoint scale = CGPointMake(b.size.width / imageAlignmentRectSize.width, b.size.height / imageAlignmentRectSize.height);

	UIEdgeInsets insets = _image.alignmentRectInsets;
	insets.top *= scale.y;
	insets.left *= scale.x;
	insets.right *= scale.x;
	insets.bottom *= scale.y;

	_imageView.frame = MMMPixelIntegralRect(CGRectMake(
		b.origin.x - insets.left,
		b.origin.y - insets.top,
		insets.left + b.size.width + insets.right,
		insets.top + b.size.height + insets.bottom
	));
}

- (CGSize)intrinsicContentSize {
	UIImage *image = [self currentImage];
	if (image) {
		return MMMPixelIntegralSize(MMMDeflateSize(image.size, image.alignmentRectInsets));
	} else {
		return CGSizeZero;
	}
}

@end
