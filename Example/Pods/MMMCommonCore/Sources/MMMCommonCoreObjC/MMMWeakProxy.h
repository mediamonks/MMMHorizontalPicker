//
// MMMCommonCore. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** 
 * This is to be able to cut strong references, such as the ones NSTimer creates to its targets.
 * The proxy will forward all method calls to the target, but at the same time won't hold a reference to the target.
 */
@interface MMMWeakProxy : NSObject

+ (instancetype)proxyWithTarget:(id)target;

- (id)initWithTarget:(id)target NS_DESIGNATED_INITIALIZER;

- (id)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
