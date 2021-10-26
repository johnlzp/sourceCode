// AFNetworkActivityIndicatorManager.m
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AFNetworkActivityIndicatorManager.h"

#if TARGET_OS_IOS
#import "AFURLSessionManager.h"

typedef NS_ENUM(NSInteger, AFNetworkActivityManagerState) {
    AFNetworkActivityManagerStateNotActive,//没有请求
    AFNetworkActivityManagerStateDelayingStart,//请求延迟开始
    AFNetworkActivityManagerStateActive,//请求进行中
    AFNetworkActivityManagerStateDelayingEnd//请求延迟结束
};

static NSTimeInterval const kDefaultAFNetworkActivityManagerActivationDelay = 1.0;
static NSTimeInterval const kDefaultAFNetworkActivityManagerCompletionDelay = 0.17;

static NSURLRequest * AFNetworkRequestFromNotification(NSNotification *notification) {
    if ([[notification object] respondsToSelector:@selector(originalRequest)]) {
        return [(NSURLSessionTask *)[notification object] originalRequest];
    } else {
        return nil;
    }
}

typedef void (^AFNetworkActivityActionBlock)(BOOL networkActivityIndicatorVisible);

@interface AFNetworkActivityIndicatorManager ()
@property (readwrite, nonatomic, assign) NSInteger activityCount;
@property (readwrite, nonatomic, strong) NSTimer *activationDelayTimer;
@property (readwrite, nonatomic, strong) NSTimer *completionDelayTimer;
@property (readonly, nonatomic, getter = isNetworkActivityOccurring) BOOL networkActivityOccurring;
@property (nonatomic, copy) AFNetworkActivityActionBlock networkActivityActionBlock;
@property (nonatomic, assign) AFNetworkActivityManagerState currentState;
@property (nonatomic, assign, getter=isNetworkActivityIndicatorVisible) BOOL networkActivityIndicatorVisible;

- (void)updateCurrentStateForNetworkActivityChange;
@end

@implementation AFNetworkActivityIndicatorManager

+ (instancetype)sharedManager {
    static AFNetworkActivityIndicatorManager *_sharedManager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedManager = [[self alloc] init];
    });

    return _sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    //设置状态为没有request活跃
    self.currentState = AFNetworkActivityManagerStateNotActive;
    //开始下载通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingTaskDidResumeNotification object:nil];
    //挂起通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidFinish:) name:AFNetworkingTaskDidSuspendNotification object:nil];
    //完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidFinish:) name:AFNetworkingTaskDidCompleteNotification object:nil];
    //开始延迟
    self.activationDelay = kDefaultAFNetworkActivityManagerActivationDelay;
    //结束延迟
    self.completionDelay = kDefaultAFNetworkActivityManagerCompletionDelay;

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_activationDelayTimer invalidate];
    [_completionDelayTimer invalidate];
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
    if (enabled == NO) {
        [self setCurrentState:AFNetworkActivityManagerStateNotActive];
    }
}

- (void)setNetworkingActivityActionWithBlock:(void (^)(BOOL networkActivityIndicatorVisible))block {
    self.networkActivityActionBlock = block;
}

- (BOOL)isNetworkActivityOccurring {
    @synchronized(self) {
        return self.activityCount > 0;
    }
}

- (void)setNetworkActivityIndicatorVisible:(BOOL)networkActivityIndicatorVisible {
    if (_networkActivityIndicatorVisible != networkActivityIndicatorVisible) {
        [self willChangeValueForKey:@"networkActivityIndicatorVisible"];
        @synchronized(self) {
             _networkActivityIndicatorVisible = networkActivityIndicatorVisible;
        }
        [self didChangeValueForKey:@"networkActivityIndicatorVisible"];
        //支持自定义的Block，去自己控制小菊花
        if (self.networkActivityActionBlock) {
            self.networkActivityActionBlock(networkActivityIndicatorVisible);
        } else {
            //否则默认AF根据该Bool，去控制状态栏小菊花是否显示
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:networkActivityIndicatorVisible];
        }
    }
}

- (void)setActivityCount:(NSInteger)activityCount {
	@synchronized(self) {
		_activityCount = activityCount;
	}

    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateCurrentStateForNetworkActivityChange];
    });
}

//增加活跃请求
- (void)incrementActivityCount {
    //活跃的网络数+1，并手动发送KVO
    [self willChangeValueForKey:@"activityCount"];
	@synchronized(self) {
		_activityCount++;
	}
    [self didChangeValueForKey:@"activityCount"];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateCurrentStateForNetworkActivityChange];
    });
}

//减少活跃请求
- (void)decrementActivityCount {
    [self willChangeValueForKey:@"activityCount"];
	@synchronized(self) {
		_activityCount = MAX(_activityCount - 1, 0);
	}
    [self didChangeValueForKey:@"activityCount"];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateCurrentStateForNetworkActivityChange];
    });
}

//请求开始
- (void)networkRequestDidStart:(NSNotification *)notification {
    if ([AFNetworkRequestFromNotification(notification) URL]) {
        //增加请求活跃数
        [self incrementActivityCount];
    }
}

//请求结束
- (void)networkRequestDidFinish:(NSNotification *)notification {
    if ([AFNetworkRequestFromNotification(notification) URL]) {
        //减少请求活跃数
        [self decrementActivityCount];
    }
}

#pragma mark - Internal State Management
//设置当前小菊花状态
- (void)setCurrentState:(AFNetworkActivityManagerState)currentState {
    @synchronized(self) {
        if (_currentState != currentState) {
            //KVO
            [self willChangeValueForKey:@"currentState"];
            _currentState = currentState;
            switch (currentState) {
                //如果为不活跃
                case AFNetworkActivityManagerStateNotActive:
                    //取消两个延迟用的timer
                    [self cancelActivationDelayTimer];
                    [self cancelCompletionDelayTimer];
                    //设置小菊花不可见
                    [self setNetworkActivityIndicatorVisible:NO];
                    break;
                case AFNetworkActivityManagerStateDelayingStart:
                    //开启一个定时器延迟去转菊花
                    [self startActivationDelayTimer];
                    break;
                case AFNetworkActivityManagerStateActive:
                    ////如果是活跃状态
                    //取消延迟完成的timer
                    [self cancelCompletionDelayTimer];
                    //开始转菊花
                    [self setNetworkActivityIndicatorVisible:YES];
                    break;
                case AFNetworkActivityManagerStateDelayingEnd:
                    //延迟完成状态
                    //开启延迟完成timer
                    [self startCompletionDelayTimer];
                    break;
            }
            [self didChangeValueForKey:@"currentState"];
        }
        
    }
}

- (void)updateCurrentStateForNetworkActivityChange {
    //如果允许是小菊花
    if (self.enabled) {
        switch (self.currentState) {
            //不活跃
            case AFNetworkActivityManagerStateNotActive:
                //判断活跃数，大于0为YES
                if (self.isNetworkActivityOccurring) {
                    //设置状态为延迟开始
                    [self setCurrentState:AFNetworkActivityManagerStateDelayingStart];
                }
                break;
            case AFNetworkActivityManagerStateDelayingStart:
                //No op. Let the delay timer finish out.
                break;
            case AFNetworkActivityManagerStateActive:
                if (!self.isNetworkActivityOccurring) {
                    [self setCurrentState:AFNetworkActivityManagerStateDelayingEnd];
                }
                break;
            case AFNetworkActivityManagerStateDelayingEnd:
                if (self.isNetworkActivityOccurring) {
                    [self setCurrentState:AFNetworkActivityManagerStateActive];
                }
                break;
        }
    }
}

//开始任务到结束的时间，默认为1秒，如果1秒就结束，那么不转菊花，延迟去开始转
- (void)startActivationDelayTimer {
    //只执行一次
    self.activationDelayTimer = [NSTimer
                                 timerWithTimeInterval:self.activationDelay target:self selector:@selector(activationDelayTimerFired) userInfo:nil repeats:NO];
    //添加到主线程runloop去触发
    [[NSRunLoop mainRunLoop] addTimer:self.activationDelayTimer forMode:NSRunLoopCommonModes];
}

- (void)activationDelayTimerFired {
    //活跃状态，即活跃数大于1才转
    if (self.networkActivityOccurring) {
        [self setCurrentState:AFNetworkActivityManagerStateActive];
    } else {
        [self setCurrentState:AFNetworkActivityManagerStateNotActive];
    }
}

//完成任务到下一个任务开始，默认为0.17秒，如果0.17秒就开始下一个，那么不停  延迟去结束菊花转
- (void)startCompletionDelayTimer {
    [self.completionDelayTimer invalidate];
    self.completionDelayTimer = [NSTimer timerWithTimeInterval:self.completionDelay target:self selector:@selector(completionDelayTimerFired) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.completionDelayTimer forMode:NSRunLoopCommonModes];
}

- (void)completionDelayTimerFired {
    [self setCurrentState:AFNetworkActivityManagerStateNotActive];
}

- (void)cancelActivationDelayTimer {
    [self.activationDelayTimer invalidate];
}

- (void)cancelCompletionDelayTimer {
    [self.completionDelayTimer invalidate];
}

@end

#endif
