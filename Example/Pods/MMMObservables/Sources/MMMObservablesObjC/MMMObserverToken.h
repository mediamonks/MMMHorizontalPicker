//
// MMMObservables. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import <Foundation/Foundation.h>

/** 
 * Sort of a cookie which can be returned by different addObserver methods.
 * It allows to remove the observer explicitely using #remove method or implicitely when the token is deallocated.
 */
@protocol MMMObserverToken <NSObject>

/** Removes the observer associated with the token. */
- (void)removeObserver;

@end
