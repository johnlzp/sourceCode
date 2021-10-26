//
//  RuntimeViewController.m
//  SourceCode
//
//  Created by 川闽祺派 on 2021/5/21.
//

#import "RuntimeViewController.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "son.h"
@interface RuntimeViewController ()
@property(nonatomic,strong)NSString *testStr;
@property(nonatomic,strong)void (^myblock)(void);
@end

@implementation RuntimeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [self test];
    [self block];
//    [self blockTest3];
}

int global_i = 1;
static int static_global_j = 2;
- (void)block{
    static int static_k = 3;
//    int val = 4;
//    self.testStr = @"test";
//    son *s = [[son alloc]init];
//    s.name = @"我是";
//    s.age = 10;
    __weak typeof(self)weakSelf = self;
    void (^myblock)(void) = ^{
//    self.myblock = ^{
        global_i ++;
        global_i ++;
        static_global_j ++;
        static_k ++;
////        s.name = [NSString stringWithFormat:@"%@儿子",s.name];
////        s.age += 10;
//        weakSelf.testStr = [NSString stringWithFormat:@"%@",weakSelf.testStr];
////        NSLog(@"里面name : %@, 年龄%ld",s.name,s.age);
//        NSLog(@"Block中 global_i = %d,static_global_j = %d,static_k = %d,val = %d",global_i,static_global_j,static_k,val);
    };
//    
    global_i ++;
    static_global_j ++;
    static_k ++;
//    val ++;
//    NSLog(@"外面name : %@, 年龄%ld",s.name,s.age);
//    NSLog(@"Block外 global_i = %d,static_global_j = %d,static_k = %d,val = %d",global_i,static_global_j,static_k,val);
    NSLog(@"%@",myblock);
    myblock();
}

//- (void)blockTest3{
//    __block id block_obj = [[NSObject alloc]init];
//    id obj = [[NSObject alloc]init];
//
//    NSLog(@"block_obj = [%@ , %p] , obj = [%@ , %p]",block_obj , &block_obj , obj , &obj);
//
//    void (^myBlock)(void) = ^{
//        NSLog(@"***Block中****block_obj = [%@ , %p] , obj = [%@ , %p]",block_obj , &block_obj , obj , &obj);
//    };
//
//    myBlock();
//}
//
//- (void)test{
////    son *s = [[son alloc]init];
////    [[son class]test];
//
//    //以下代码在MRC中运行
//    __block int i = 0;
//    NSLog(@"%p",&i);//0x7ffee9b630f8
////    void (^myblock)(void) = ^{
//////    self.myblock = ^{
////        i ++;
////        NSLog(@"这是Block 里面%p",&i);//0x600002225d18   0x60000215d3d8
////    };
////    NSLog(@"%@",myblock);
////    myblock();
////    NSLog(@"%@",^{NSLog(@"这是Block 里面%p",&i);});
//    __block int temp = 10;
//
//       NSLog(@"%@",^{NSLog(@"*******%d %p",temp ++,&temp);});
//}
//
//-(void)study:(NSString *)subject :(NSString *)bookName
//{
//    NSLog(@"Invorking method on %@ object with selector %@",[self class],NSStringFromSelector(_cmd));
//}

@end
