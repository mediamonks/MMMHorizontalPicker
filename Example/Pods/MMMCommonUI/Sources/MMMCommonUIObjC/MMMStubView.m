//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMStubView.h"

#import "MMMCommonUI.h"
#import "MMMLayout.h"

@implementation MMMStubView {
	UILabel *_label;
	NSString *_text;
	NSInteger _index;
}

- (id)initWithText:(NSString *)text index:(NSInteger)index {

	if (self = [super initWithFrame:CGRectZero]) {

		_text = text;
		_index = index;

		self.opaque = YES;
		self.translatesAutoresizingMaskIntoConstraints = NO;

		_label = [[UILabel alloc] init];
		_label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17];
		_label.textColor = [UIColor whiteColor];
		_label.numberOfLines = 0;
		_label.textAlignment = NSTextAlignmentCenter;
		[self addSubview:_label];

		self.backgroundColor = MMMDebugColor(_index);
		_label.text = ([_text length] > 0) ? _text : [NSString stringWithFormat:@"Stub #%ld", (long)_index];
		_label.textColor = MMMDebugColor(_index + 1);
	}

	return self;
}

- (void)layoutSubviews {

	CGRect b = self.bounds;
	b.origin = CGPointZero;
	b = UIEdgeInsetsInsetRect(b, UIEdgeInsetsMake(10, 10, 10, 10));

	CGSize labelSize = [_label sizeThatFits:CGSizeMake(b.size.width, b.size.height)];
	_label.frame = [MMMLayoutUtils rectWithSize:labelSize withinRect:b contentMode:UIViewContentModeCenter];

	self.contentSize = CGSizeMake(self.bounds.size.width, self.bounds.size.height * 2);
}

@end

