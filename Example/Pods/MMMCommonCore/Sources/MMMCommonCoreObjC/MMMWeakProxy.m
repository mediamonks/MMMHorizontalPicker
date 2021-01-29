//
// MMMCommonCore. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMWeakProxy.h"

@implementation MMMWeakProxy {
	id __weak _target;
}

+ (instancetype)proxyWithTarget:(id)target {
	return [[self alloc] initWithTarget:target];
}

- (id)initWithTarget:(id)target {
	if (self = [super init]) {
		_target = target;
	}
	return self;
}

- (void)forwardInvocation:(NSInvocation *)invocation {

	id target = _target;
	if (!target)
		return;

	[invocation invokeWithTarget:target];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {

	id target = _target;
	if (!target)
		return [NSMethodSignature signatureWithObjCTypes:"@:"];

    return [target methodSignatureForSelector:aSelector];
}

// Apparently there is an internal method in NSObject also called `addObserver:`, so a similarly named method
// of MMMLoadable would not be forwarded without this.
- (void)addObserver:(id)observer {
	id target = _target;
	if (!target)
		return;
	[target addObserver:observer];
}

@end
