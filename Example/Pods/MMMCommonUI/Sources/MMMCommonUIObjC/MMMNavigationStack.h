//
// MMMUtil.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^MMMNavigationStackCompletion)(BOOL success);

@protocol MMMNavigationStackItem;
@protocol MMMNavigationStackItemDelegate;

/**
 * This is to track the navigation state of the app and have the possibility to programmatically return to registered points of 
 * the navigation path. The actual navigation entities of the app (usually view controllers) must cooperate in order to
 * achieve this.
 *
 * The possibility to go back is needed to properly handle in-app links. We have a basic mechanism for this (MMMNavigation) 
 * which allows to "open" a part of a link and forward the remaining parts to the corresponding handler down the navigation tree.
 * The handlers thus need to be able to "close" current navigation path before opening something new.
 * 
 * Although navigation in the app is better represented by a tree, we assume here that at least the _current_ path in this tree 
 * can be represented as a stack. Each element of the stack can correspond to a modal view controller or alert view, for example, 
 * but it can also correspond to a special state of the app or a screen.
 */
@interface MMMNavigationStack : NSObject

+ (instancetype)shared;

/** 
 * Notifies the stack about a new modal navigation context facing the user now, such as a modal view controller being presented or
 * any other special state of the UI which would require either the assistance from the user or navigation items' delegate 
 * in order to return to the previous navigation step.
 *
 * Again, navigation steps are not limited to modal view controllers, there can be any entity responsible for the current
 * state of the UI which wants to clean it up properly when asked for via the correspondng delegate.
 *
 * The optional `controller` parameter might be a view controller corresponding to the new navigation item. This can be used by
 * this controller with `popAllAfterController:completion:` method in order to cancel/pop all the navigation items added after it.
 *
 * A nil is returned if it's not possible to push anything now (because the stack is in the middle of a change).
 *
 * For now trying to push something when "popping" is in progress is considered a programmer's error however and it will crash 
 * in Debug.
 */
- (nullable id<MMMNavigationStackItem>)pushItemWithName:(NSString *)name delegate:(id<MMMNavigationStackItemDelegate>)delegate controller:(nullable id)controller;

//~ - (id<MMMNavigationStackItem>)pushItemWithName:(NSString *)name delegate:(id<MMMNavigationStackItemDelegate>)delegate;

- (BOOL)popAllAfterController:(id)controller completion:(MMMNavigationStackCompletion)completion;

@end

/**
 * This is the delegate corresponding to each navigation item in the stack.
 * Its main purpose is to be able to handle popping of the corresponding navigation item.
 */
@protocol MMMNavigationStackItemDelegate <NSObject>

/** 
 * Should perform all the work necessary to pop the corresponding UI navigation item and must call `didPop` method
 * on the corresponding item when done.
 *
 * Note that when the delegate is asked to pop, then all the items on top of it in the stack have been popped aready,
 * so the delegate should not ask the stack to do it. In fact asking for it and waiting for completion might freeze the popping 
 * process as pop completion callbacks are called only after all the whole popping process completes.
 */
- (void)popNavigationStackItem:(id<MMMNavigationStackItem>)item;

@end

/**
 * A token corresponding to a single node (item) of the current UI navigation path.
 * Note that a reference to the token must be stored somewhere or the corresponding item will be popped right away.
 */
@protocol MMMNavigationStackItem <NSObject>

/** 
 * Should be called by the item's delegate when the navigation item has been popped as a result of user's action
 * and must be called when MMMNavigationStack calling `popNavigationStackItem` of the corresponding delegate.
 */
- (void)didPop;

/**
 * Should be called by the navigation item's delegate in rare caes when the corresponding item cannot be popped.
 */
- (void)didFailToPop;

/** 
 * Pops all the items currently on the stack above this item, so this one becomes the top. This is an asynchronous operation 
 * because it might involving several navigation steps.
 * 
 * Returns YES, if the request to pop was accepted for execution; NO otherwise. The latter means programmers error (such as
 * popping while another pop is in progress) and will terminate the app when assertions are enabled. 
 *
 * Note that the completion handler is executed ony if the request has been accepted.
 */
- (BOOL)popAllAfterThisItemWithCompletion:(MMMNavigationStackCompletion)completion;

@end

NS_ASSUME_NONNULL_END
