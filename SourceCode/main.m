//
//  main.m
//  SourceCode
//
//  Created by 川闽祺派 on 2021/5/19.
//

//#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "AppDelegate.h"
//#import "Father+add.h"
#import "Father.h"
//#import "son.h"
#import <objc/runtime.h>

typedef void(^ZPBlock)(void);

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        Father *fa = [[Father alloc] init];
//        [father performSelector:@selector(vddTest)];
        [Father class];
        [NSObject class];
        NSObject.self;
        fa.class;
//        Father *fa = ((Father *(*)(id, SEL))(void *)objc_msgSend)((id)((Father *(*)(id, SEL))(void *)objc_msgSend)((id)objc_getClass("Father"), sel_registerName("alloc")), sel_registerName("init"));
//
//        ((Class (*)(id, SEL))(void *)objc_msgSend)((id)objc_getClass("Father"), sel_registerName("class"));
//        ((Class (*)(id, SEL))(void *)objc_msgSend)((id)objc_getClass("NSObject"), sel_registerName("class"));
//        ((id (*)(id, SEL))(void *)objc_msgSend)((id)objc_getClass("NSObject"), sel_registerName("self"));
//        ((Class (*)(id, SEL))(void *)objc_msgSend)((id)fa, sel_registerName("class"));
//        [Father class];
//        [NSObject class];
//        NSObject.self;
//        fa.class;
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}

//void test3(){
//    ZPBlock testblock;
//    {
//        Father *father = [[Father alloc]init];
//        father.age = @"10";
//        __weak Father *fatherTwo = [[Father alloc]init];
//        fatherTwo.age = @"20";
//
//        //下面的这个block因为没有强指针引用，所以在ARC下就是stackBlock，
//        //不管father使用__strong还是__weak修饰所以不会对father产生强引用
//        ^{
//            NSLog(@"%@",father.age);
//        };
//
//        //因为在ARC下变量的修饰符默认是__strong，所以该block会被编译器执行copy操作变成mallocBlock，
//        //如果fatherTwo用weak修饰，那么block底层的__main_block_copy_0函数内部_Block_object_assign方法会对block结构体内的fatherTwo进行一次弱引用，所以对fatherTwo产生强引用
//        //如果fatherTwo用strong修饰，道理同上，那么会对fatherTwo产生强引用
//        testblock = ^{
//            NSLog(@"%@",fatherTwo.age);
//        };
//    }
//    //因为father没有被强引用，所以会被释放掉
//    //因为fatherTwo被强引用，所以不会释放掉
//    NSLog(@"----------");
//}

//        int age = 10;
//        __weak void(^testblock)(void) = ^{
//            NSLog(@"%d",age);
//        };
//        NSLog(@"%@",[testblock class]);


//ZPBlock testblock;
//{
//    Father *father = [[Father alloc]init];
//    father.age = @"20";
////            testblock =
//    ^{
//        NSLog(@"%@",father.age);
//    };
//}
//NSLog(@"----------");
//NSLog(@"%@",[testblock class]);
