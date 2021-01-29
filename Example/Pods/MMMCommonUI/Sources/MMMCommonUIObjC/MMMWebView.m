//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMWebView.h"

@interface MMMWebViewScrollDelegate : NSObject<UIScrollViewDelegate>

- (instancetype)initWithShadows:(MMMScrollViewShadows *)shadows NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@implementation MMMWebViewScrollDelegate {
	MMMScrollViewShadows * __weak _shadows;
}

- (instancetype)initWithShadows:(MMMScrollViewShadows *)shadows {
	self = [super init];
	
	if (self) {
		_shadows = shadows;
	}
	
	return self;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[_shadows layoutSubviews];
}

@end

@implementation MMMWebView {
	MMMScrollViewShadows *_shadows;
	MMMWebViewScrollDelegate *_delegate;
}

- (instancetype)initWithSettings:(MMMScrollViewShadowsSettings *)settings
{
	return [self initWithSettings:settings configuration:[[WKWebViewConfiguration alloc] init]];
}

- (instancetype)initWithSettings:(MMMScrollViewShadowsSettings *)settings configuration:(WKWebViewConfiguration *)configuration
{
	self = [super initWithFrame:CGRectZero configuration:configuration];
    
    if (self) {
		_shadows = [[MMMScrollViewShadows alloc] initWithScrollView:self.scrollView settings:settings];
		_delegate = [[MMMWebViewScrollDelegate alloc] initWithShadows:_shadows];
		
		self.translatesAutoresizingMaskIntoConstraints = NO;
		self.scrollView.delegate = _delegate;
    }
    
    return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	[_shadows layoutSubviews];
}

@end
