//
//  son.m
//  SourceCode
//
//  Created by 川闽祺派 on 2021/5/22.
//

#import "son.h"
#import <objc/runtime.h>
@implementation son

//struct objc_super {
//    __unsafe_unretained _Nonnull id receiver;//消息接收者
//    __unsafe_unretained _Nonnull Class super_class;//消息接收者的父类
//};

- (void)sonTestMe{
//    NSLog(@"sont");
    
    //objc_msgSend(self, sel_registerName("class")));
    NSLog(@"self-class:%@",[self class]);//son
    
    //objc_msgSendSuper({self, class_getSuperclass(objc_getClass("son"))}, sel_registerName("class"));
    //class_getSuperclass(objc_getClass("son"))是表示获取父类的类对象，所以这里也可以换成下面写法
    //objc_msgSendSuper({self, [Father class], sel_registerName("class"));
    NSLog(@"super-class:%@",[super class]);//son
    
//    objc_msgSend(self, sel_registerName("superclass"));
    NSLog(@"self-superclass:%@",[self superclass]);//Father
    
//    objc_msgSendSuper({self, class_getSuperclass(objc_getClass("son"))}, sel_registerName("superclass"));
    NSLog(@"super-superclass:%@",[super superclass]);//Father
    
    
//    objc_msgSendSuper(struct objc_super * super, SEL op, ...)
}
//
//- (int)foot:(int)count{
//    NSLog(@"%s",__func__);
//    return count *10;
//}
//
//+ (int)foot:(int)count{
//    NSLog(@"%s",__func__);
//    return count *10;
//}
//
//+ (void)test{
////    NSLog(@"父类");
////    void(^blockSonTest)(void) = ^{
//        //这个self会被捕获到block结构体内部
////        NSLog(@"-------%p",self);
////    };
//    NSLog(@"%s",__func__);
//}
//
//- (void)test{
////    NSLog(@"父类");
////    void(^blockSonTest)(void) = ^{
//        //这个self会被捕获到block结构体内部
////        NSLog(@"-------%p",self);
////    };
//    NSLog(@"%s",__func__);
//}

//- (void)test{
//    void(^blockTest)(void) = ^{
//        //这个self会被捕获到block结构体内部
//        NSLog(@"-------%p",self.name);
//    };
//    NSLog(@"%s",__func__);
//}
@end
