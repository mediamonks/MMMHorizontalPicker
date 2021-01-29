//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMShadowView.h"

/**
 * Something that holds both a CALayer & MMMShadowViewSettings together.
 */
@interface MMMShadowLayerInfo : NSObject

@property (nonatomic, readonly) CALayer *layer;

@property (nonatomic, readonly) MMMShadowViewSetting *setting;

- (id)initWithLayer:(CALayer *)layer setting:(MMMShadowViewSetting *)setting NS_DESIGNATED_INITIALIZER;
- (id)init NS_UNAVAILABLE;

@end

#pragma mark - MMMShadowView

@implementation MMMShadowView {
	UIView *_contentView;
	NSMutableArray<MMMShadowLayerInfo *> *_layerInfo;
}

- (id)initWithSettings:(NSArray<MMMShadowViewSetting *> *)settings
{	
	self = [super initWithFrame:CGRectZero];
	if (self) {
	
		self.translatesAutoresizingMaskIntoConstraints = NO;
		self.contentMode = UIViewContentModeRedraw;
		self.backgroundColor = [UIColor clearColor];
		
		_layerInfo = [[NSMutableArray alloc] init];
		
		[self addSubview:[self contentView]];
		
		//
		// Layout
		//
		NSDictionary *views = NSDictionaryOfVariableBindings(_contentView);
		
		[NSLayoutConstraint activateConstraints:[NSLayoutConstraint 
			constraintsWithVisualFormat:@"H:|-0-[_contentView]-0-|" 
			options:0 metrics:nil views:views
		]];
		[NSLayoutConstraint activateConstraints:[NSLayoutConstraint 
			constraintsWithVisualFormat:@"V:|-0-[_contentView]-0-|" 
			options:0 metrics:nil views:views
		]];
		
		self.settings = settings;
	}
	return self;
}

- (id)init {
	return [self initWithSettings:nil];
}

- (UIView *)contentView {
	if (!_contentView) {
		_contentView = [[UIView alloc] initWithFrame:CGRectZero];
		_contentView.translatesAutoresizingMaskIntoConstraints = NO;
	}
	return _contentView;
}

- (void)layoutSubviews {
	
	[super layoutSubviews];
	
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	
	for (MMMShadowLayerInfo *info in _layerInfo) {
		info.layer.frame = UIEdgeInsetsInsetRect(_contentView.frame, info.setting.insets);
	}
	
	[CATransaction commit];
}

- (void)setSettings:(NSArray<MMMShadowViewSetting *> *)settings {
	if (_settings != settings) {
		_settings = settings;
		[self createLayers];
	}	
}

- (void)createLayers {
	
	for (MMMShadowLayerInfo *info in _layerInfo) {
		[info.layer removeFromSuperlayer];
	}
	[_layerInfo removeAllObjects];
	
	if (!_settings) {
		_settings = nil;
		return;
	}
	
	for (MMMShadowViewSetting *setting in _settings) {
	
		CALayer *layer = [CALayer layer];
		layer.backgroundColor = setting.backgroundColor.CGColor;
		layer.shadowColor = setting.color.CGColor;
		layer.shadowOffset = setting.offset;
		layer.shadowRadius = setting.radius;
		layer.shadowOpacity = setting.opacity;
		layer.cornerRadius = setting.cornerRadius;

		[self.layer addSublayer:layer];
		
		[_layerInfo addObject:[[MMMShadowLayerInfo alloc] initWithLayer:layer setting:setting]];
	}
	
	[self bringSubviewToFront:_contentView];
	
	[self invalidateIntrinsicContentSize];
}

- (UIEdgeInsets)alignmentRectInsets {

	UIEdgeInsets insets = UIEdgeInsetsZero;
	
	for (MMMShadowLayerInfo *info in _layerInfo) {
	
		CGSize offset = info.setting.offset;
		CGFloat radius = info.setting.radius;
		
		UIEdgeInsets b = UIEdgeInsetsMake(
			-offset.height + radius, 
			-offset.width + radius, 
			offset.height + radius, 
			offset.width + radius
		);
				
		// Don't want to depend on 'MMMMaxUIEdgeInsets()'.
		insets = UIEdgeInsetsMake(
			MAX(insets.top, b.top), 
			MAX(insets.left, b.left), 
			MAX(insets.bottom, b.bottom), 
			MAX(insets.right, b.right)
		);
	}
	
	return insets;
}

- (BOOL)requiresConstraintBasedLayout {
	return YES;
}

@end

#pragma mark - MMMShadowViewSetting

@implementation MMMShadowViewSetting

- (id)initWithBlock:(MMMShadowViewSettingBlock)block 
{
	self = [self init];
    if (self) {
		block(self);
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        
        _color = [UIColor blackColor];
        _opacity = 0.0;
        _offset = CGSizeZero;
        _radius = 0.0;
        _insets = UIEdgeInsetsZero;
        _backgroundColor = [UIColor whiteColor];
        _cornerRadius = 0.0;
    }
    return self;
}

@end

#pragma mark - MMMShadowLayerInfo

@implementation MMMShadowLayerInfo

- (id)initWithLayer:(CALayer *)layer setting:(MMMShadowViewSetting *)setting 
{
	self = [super init];
    if (self) {
        
        _layer = layer;
        _setting = setting;
    }
    return self;
}

@end
