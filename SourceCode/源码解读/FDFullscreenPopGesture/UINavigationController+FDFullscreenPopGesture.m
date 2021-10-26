// The MIT License (MIT)
//
// Copyright (c) 2015-2016 forkingdog ( https://github.com/forkingdog )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import "UINavigationController+FDFullscreenPopGesture.h"
#import <objc/runtime.h>

@interface _FDFullscreenPopGestureRecognizerDelegate : NSObject <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UINavigationController *navigationController;

@end

// 这个类实现了自定义手势的代理方法
@implementation _FDFullscreenPopGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
    // Ignore when no view controller is pushed into the navigation stack.
    //当没有控制器入栈的时候，不触发手势
    if (self.navigationController.viewControllers.count <= 1) {
        return NO;
    }
    
    // Disable when the active view controller doesn't allow interactive pop.
    // 如果控制器的fd_interactivePopDisabled属性为NO不触发手势
    // 因为栈是先进后出，这个方法时控制器的侧滑手势响应方法，所以获取lastObject就是当前页面控制器
    //（fd_interactivePopDisabled是作者对UIViewController添加的一个属性）
    UIViewController *topViewController = self.navigationController.viewControllers.lastObject;
    if (topViewController.fd_interactivePopDisabled) {
        return NO;
    }

    // 如果导航控制器正在执行转场动画，则不触发手势
    // Ignore pan gesture when the navigation controller is currently in transition.
    if ([[self.navigationController valueForKey:@"_isTransitioning"] boolValue]) {
        return NO;
    }
    
    // Prevent calling the handler when the gesture begins in an opposite direction.
    // 当手势从相反的方向开始时(从右划向左边)，不触发手势
    CGPoint translation = [gestureRecognizer translationInView:gestureRecognizer.view];
    if (translation.x <= 0) {
        return NO;
    }
    
    return YES;
}

@end

typedef void (^_FDViewControllerWillAppearInjectBlock)(UIViewController *viewController, BOOL animated);

@interface UIViewController (FDFullscreenPopGesturePrivate)

@property (nonatomic, copy) _FDViewControllerWillAppearInjectBlock fd_willAppearInjectBlock;

@end

@implementation UIViewController (FDFullscreenPopGesturePrivate)

+ (void)load
{
    Method originalMethod = class_getInstanceMethod(self, @selector(viewWillAppear:));
    Method swizzledMethod = class_getInstanceMethod(self, @selector(fd_viewWillAppear:));
    //交换viewWillAppear方法
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (void)fd_viewWillAppear:(BOOL)animated
{
    // Forward to primary implementation.
    //调用原来的方法实现
    [self fd_viewWillAppear:animated];
    
    if (self.fd_willAppearInjectBlock) {
        self.fd_willAppearInjectBlock(self, animated);
    }
}

- (_FDViewControllerWillAppearInjectBlock)fd_willAppearInjectBlock
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setFd_willAppearInjectBlock:(_FDViewControllerWillAppearInjectBlock)block
{
    objc_setAssociatedObject(self, @selector(fd_willAppearInjectBlock), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

@implementation UINavigationController (FDFullscreenPopGesture)

+ (void)load
{
    // Inject "-pushViewController:animated:"
    Method originalMethod = class_getInstanceMethod(self, @selector(pushViewController:animated:));
    Method swizzledMethod = class_getInstanceMethod(self, @selector(fd_pushViewController:animated:));
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (void)fd_pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    //self.interactivePopGestureRecognizer：表示当前页面的系统侧滑pop手势
    //interactivePopGestureRecognizer.view：手势附加到的视图，并且返回的是一个UILayoutContainerView，(UILayoutContainerView就是window 上的第一个 subview)
    //self.fd_fullscreenPopGestureRecognizer：自定义的手势
    //这里就是判断自定义的手势是否已经添加到了系统侧滑手势所在的UILayoutContainerView上面(也就是替换系统手势)
    if (![self.interactivePopGestureRecognizer.view.gestureRecognizers containsObject:self.fd_fullscreenPopGestureRecognizer]) {
        
        // Add our own gesture recognizer to where the onboard screen edge pan gesture recognizer is attached to.
        //将自定义手势添加到系统侧滑手势响应的view上面
        [self.interactivePopGestureRecognizer.view addGestureRecognizer:self.fd_fullscreenPopGestureRecognizer];

        // Forward the gesture events to the private handler of the onboard gesture recognizer.
        //获取系统侧滑手势响应的target数组
        NSArray *internalTargets = [self.interactivePopGestureRecognizer valueForKey:@"targets"];
        //获取当前页面的系统侧滑手势响应的target
        id internalTarget = [internalTargets.firstObject valueForKey:@"target"];
        //handleNavigationTransition：是系统侧滑手势响应的action
        SEL internalAction = NSSelectorFromString(@"handleNavigationTransition:");
        //拦截系统侧滑手势，更换响应的target
        self.fd_fullscreenPopGestureRecognizer.delegate = self.fd_popGestureRecognizerDelegate;
        //替换系统侧滑手势
        [self.fd_fullscreenPopGestureRecognizer addTarget:internalTarget action:internalAction];

        // Disable the onboard gesture recognizer.
        //关闭系统侧滑手势
        self.interactivePopGestureRecognizer.enabled = NO;
        
    }
    
    // Handle perferred navigation bar appearance.(处理首选导航条外观)
    // 这个方法控制了导航控制器中的子控制器是否有独立控制导航栏显示或者隐藏的权利
    // fd_viewControllerBasedNavigationBarAppearanceEnabled属性默认为YES
    // 也就是说，默认会根据控制的分类属性fd_prefersNavigationBarHidden来控制栏的隐藏或者显示
    // 如果fd_viewControllerBasedNavigationBarAppearanceEnabled为NO
    // 那么导航控制器的导航栏的显示与否，控制器无权决定
    [self fd_setupViewControllerBasedNavigationBarAppearanceIfNeeded:viewController];
    
    // Forward to primary implementation.
    [self fd_pushViewController:viewController animated:animated];
}

- (void)fd_setupViewControllerBasedNavigationBarAppearanceIfNeeded:(UIViewController *)appearingViewController
{
    //控制器是否允许自定义导航栏控制器
    if (!self.fd_viewControllerBasedNavigationBarAppearanceEnabled) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    // UIViewController (FDFullscreenPopGesturePrivate) 定义了一个block
    // 从这里我们可以看到，只有在 fd_viewControllerBasedNavigationBarAppearanceEnabled == YES的时候
    // 才会给block赋值，才会执行block，
    // block中会根据fd_prefersNavigationBarHidden 判断是否要显示或者隐藏导航栏
    _FDViewControllerWillAppearInjectBlock block = ^(UIViewController *viewController, BOOL animated) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf setNavigationBarHidden:viewController.fd_prefersNavigationBarHidden animated:animated];
        }
    };
    
    // Setup will appear inject block to appearing view controller.
    // Setup disappearing view controller as well, because not every view controller is added into
    // stack by pushing, maybe by "-setViewControllers:".
    // 1.对即将入栈的控制器的fd_willAppearInjectBlock属性进行赋值
    // 2.在push前，也对栈顶的控制器fd_willAppearInjectBlock赋值
    // 3.请注意，这个时候栈顶的控制器不一定是push入栈的，也有可能是通过-setViewControllers:方法入栈
    appearingViewController.fd_willAppearInjectBlock = block;
    //获取上一个入栈的控制器
    UIViewController *disappearingViewController = self.viewControllers.lastObject;
    if (disappearingViewController && !disappearingViewController.fd_willAppearInjectBlock) {
        // 在有新的控制器入栈前，检查栈顶控制器block属性是否有值，如果没有，就赋值
        disappearingViewController.fd_willAppearInjectBlock = block;
    }
}

- (_FDFullscreenPopGestureRecognizerDelegate *)fd_popGestureRecognizerDelegate
{   // "懒加载"自定义手势
    // 先获取该手势，如果获取不到，再创建，获取到了 直接返回
    _FDFullscreenPopGestureRecognizerDelegate *delegate = objc_getAssociatedObject(self, _cmd);

    if (!delegate) {
        delegate = [[_FDFullscreenPopGestureRecognizerDelegate alloc] init];
        delegate.navigationController = self;
        
        objc_setAssociatedObject(self, _cmd, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return delegate;
}

//全屏侧滑手势
- (UIPanGestureRecognizer *)fd_fullscreenPopGestureRecognizer
{
    UIPanGestureRecognizer *panGestureRecognizer = objc_getAssociatedObject(self, _cmd);

    if (!panGestureRecognizer) {
        panGestureRecognizer = [[UIPanGestureRecognizer alloc] init];
        panGestureRecognizer.maximumNumberOfTouches = 1;
        
        objc_setAssociatedObject(self, _cmd, panGestureRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return panGestureRecognizer;
}

- (BOOL)fd_viewControllerBasedNavigationBarAppearanceEnabled
{
    // 获取NSNumber对象,注意了，如果NSnumber的value为0的时候，
    // if条件也会判断为真，因为NSnumber是对象，对象空的时候为nil而不是0
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) {
        // 如果number为0，那么boolValue得到的结果就为NO，反之YES
        return number.boolValue;
    }
    // 代码如果执行到这，说明没设置该属性，默认为YES
    self.fd_viewControllerBasedNavigationBarAppearanceEnabled = YES;
    return YES;
}

- (void)setFd_viewControllerBasedNavigationBarAppearanceEnabled:(BOOL)enabled
{
    // 注意，这里@(enable)是将bool值包装成一个NSNumber类型的对象
    SEL key = @selector(fd_viewControllerBasedNavigationBarAppearanceEnabled);
    objc_setAssociatedObject(self, key, @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIViewController (FDFullscreenPopGesture)

- (BOOL)fd_interactivePopDisabled
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFd_interactivePopDisabled:(BOOL)disabled
{
    objc_setAssociatedObject(self, @selector(fd_interactivePopDisabled), @(disabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fd_prefersNavigationBarHidden
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFd_prefersNavigationBarHidden:(BOOL)hidden
{
    objc_setAssociatedObject(self, @selector(fd_prefersNavigationBarHidden), @(hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
