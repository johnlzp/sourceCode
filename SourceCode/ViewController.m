//
//  ViewController.m
//  SourceCode
//
//  Created by 川闽祺派 on 2021/5/19.
//

#import "ViewController.h"
#import "AFNetworking.h"
#import "ZPNetManager.h"
#import "son.h"

@interface ViewController ()
@property(nonatomic,strong)dispatch_queue_t queue;
@property(nonatomic,weak)NSString *weakStr;
@property(nonatomic,strong)NSString *strongStr;
//@property(nonatomic,copy)void (^ZPTestBlock)(void);
@property(nonatomic,strong)id ZPTestBlock;
@end

@implementation ViewController{
    NSString *memStr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //不注释这句话,printtest方法打印结果就是123
    //注释这句话，printtest方法打印结果就是当前控制器viewcontroller
    NSString *test = @"123";
    id cls = [Father class];
    void *obj = &cls;
    [(__bridge id)obj printtest];
    
}

//* i 24 @ 0 : 8 i 16 f 20
- (int)test:(int)age height:(float)height{
    return 0;
}

- (void)tast1{
    int age = 10;//automatic re
    self.ZPTestBlock = ^{
        NSLog(@"%d",age);
    };
    NSLog(@"%@",[^{
        NSLog(@"%d",age);
    } class]);
}
- (void)tast2 {
    dispatch_async(self.queue, ^{
        //执行任务2
        dispatch_async(dispatch_get_main_queue(), ^{
            //任务2完成
        });
    });
}

- (void)networkTest{
    ZPNetManager *manager = [[ZPNetManager alloc]init];
    [manager setConfig:^(personModel * _Nonnull model) {
        NSLog(@"viewcon:%@",model.name);
        model.name = @"以后";
    }];
    
}

//死锁
- (void)lockTest{
    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
    dispatch_sync(queue, ^{
        dispatch_sync(queue, ^{
            NSLog(@"download1------%@",[NSThread currentThread]);
        });
        dispatch_sync(queue, ^{
            NSLog(@"download2------%@",[NSThread currentThread]);
        });
        dispatch_sync(queue, ^{
            NSLog(@"download3------%@",[NSThread currentThread]);
        });
    });
    
}

- (void)syncMain {

//    //打印当前线程
    NSLog(@"currentThread---%@",[NSThread currentThread]);
    NSLog(@"syncMain---begin");
    //    dispatch_queue_t queue = dispatch_get_main_queue();
    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_CONCURRENT);//dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        // 追加任务1
        for (int i = 0; i < 2; ++i) {
            //模拟耗时操作
            [NSThread sleepForTimeInterval:2];
            //打印当前线程
            NSLog(@"1---%@",[NSThread currentThread]);
        }
    });
    dispatch_barrier_async(queue, ^{
        NSLog(@"第一次");
    });
    dispatch_barrier_async(queue, ^{
        [NSThread sleepForTimeInterval:2];
        NSLog(@"第二次");
    });
    dispatch_barrier_async(queue, ^{
        NSLog(@"第三次");
    });
    dispatch_async(queue, ^{
        // 追加任务2
        for (int i = 0; i < 2; ++i) {
            //模拟耗时操作
            [NSThread sleepForTimeInterval:2];
            //打印当前线程
            NSLog(@"2---%@",[NSThread currentThread]);
        }
    });
//    dispatch_sync(queue, ^{
//        // 追加任务3
//        for (int i = 0; i < 2; ++i) {
//            //模拟耗时操作
//            [NSThread sleepForTimeInterval:2];
//            //打印当前线程
//            NSLog(@"3---%@",[NSThread currentThread]);
//        }
//    });
    NSLog(@"syncMain---end");
}

- (void)NSOperationTest{
    NSOperationQueue * queue = [[NSOperationQueue alloc] init];
    NSInvocationOperation * operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(longTimeOperation) object:@0];
    [queue addOperation:operation];
    for (int i = 0; i < 20; i++) {
        //创建一个任务
        NSInvocationOperation * operation2 = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(longTimeOperation) object:[NSNumber numberWithInt:i]];
        //将任务放到队列中
        [queue addOperation:operation2];
    }
    
}

- (void)longTimeOperation{
    NSLog(@"当前线程:%@",[NSThread currentThread]);
}

- (void)NSTest{
    //    NSInvocationOperation *invocationOperation = [self invocationOperationWithData:@"leichunfeng"];
    //    [invocationOperation start];
        NSBlockOperation *blockOperation = [self blockOperation];
        [blockOperation start];
    NSLog(@"最后");
}

#pragma mark - NSInvocationOperation
- (NSInvocationOperation *)invocationOperationWithData:(id)data {
    return [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(myTaskMethod1:) object:data];
}

- (NSInvocationOperation *)invocationOperationWithData:(id)data userInput:(NSString *)userInput {
    NSInvocationOperation *invocationOperation = [self invocationOperationWithData:data];
    if (userInput.length == 0) {
        invocationOperation.invocation.selector = @selector(myTaskMethod2:);
    }
    return invocationOperation;
}

#pragma mark - NSBlockOperation
- (NSBlockOperation *)blockOperation {
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"Start executing block1, mainThread: %@, currentThread: %@", [NSThread mainThread], [NSThread currentThread]);
        sleep(3);
        NSLog(@"Finish executing block1");
    }];
    [blockOperation addExecutionBlock:^{
        NSLog(@"Start executing block2, mainThread: %@, currentThread: %@", [NSThread mainThread], [NSThread currentThread]);
        sleep(3);
        NSLog(@"Finish executing block2");
    }];
    [blockOperation addExecutionBlock:^{
        NSLog(@"Start executing block3, mainThread: %@, currentThread: %@", [NSThread mainThread], [NSThread currentThread]);
        sleep(3);
        NSLog(@"Finish executing block3");
    }];
    return blockOperation;
}

- (void)executeOperationUsingOperationQueue {
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    
    NSInvocationOperation *invocationOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(taskMethod) object:nil];
    [operationQueue addOperation:invocationOperation];
    
    NSBlockOperation *blockOperation1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"11Start executing blockOperation1, mainThread: %@, currentThread: %@", [NSThread mainThread], [NSThread currentThread]);
        sleep(3);
        NSLog(@"11Finish executing blockOperation1");
    }];
    
    NSBlockOperation *blockOperation2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"22Start executing blockOperation2, mainThread: %@, currentThread: %@", [NSThread mainThread], [NSThread currentThread]);
        sleep(3);
        NSLog(@"22Finish executing blockOperation2");
    }];
    
    [operationQueue addOperations:@[ blockOperation1, blockOperation2 ] waitUntilFinished:NO];
    
    [operationQueue addOperationWithBlock:^{
        NSLog(@"33Start executing block, mainThread: %@, currentThread: %@", [NSThread mainThread], [NSThread currentThread]);
        sleep(3);
        NSLog(@"33Finish executing block");
    }];
    
//    [operationQueue waitUntilAllOperationsAreFinished];
    NSLog(@"最后");
}

- (void)taskMethod {
    NSLog(@"00Start executing %@, mainThread: %@, currentThread: %@", NSStringFromSelector(_cmd), [NSThread mainThread], [NSThread currentThread]);
    sleep(5);
    NSLog(@"00Finish executing %@", NSStringFromSelector(_cmd));
}
@end
