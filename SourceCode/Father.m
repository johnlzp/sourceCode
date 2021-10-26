//
//  Father.m
//  SourceCode
//
//  Created by 川闽祺派 on 2021/5/22.
//

#import "Father.h"
#import <objc/runtime.h>
#import "son.h"

@implementation Father

- (void)printtest{
    NSLog(@"%@",self.age);
}

- (void)dealloc{
    NSLog(@"dealloc");
}


+ (void)addEat{
    NSLog(@"%s",__func__);
}

- (void)other{
    NSLog(@"%s",__func__);
}

//因为OC的方法会默认传入两个隐式参数，self 和 _cmd
void c_other(id self, SEL _cmd){
    NSLog(@"%s",__func__);
}

//类方法的返回方法签名
//+ (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector{
//    if (aSelector == @selector(foot:)) {
//        return [NSMethodSignature signatureWithObjCTypes:"i@ii"];
//    }
//    return [super methodSignatureForSelector:aSelector];
//}
//
////类方法的转发调用
//+ (void)forwardInvocation:(NSInvocation *)anInvocation{
//    //让son去调用foot:方法
//    //target：如果是类方法就要传类对象，否则就是实例对象
////    [anInvocation invokeWithTarget:[[son alloc]init]];
//    [anInvocation invokeWithTarget:[son class]];
//    int ret;
//    int foot;
//    //获取参数，因为有两个隐式参数receiver:self  SEL:_cmd，所以foot参数就是第2位
//    [anInvocation getArgument:&foot atIndex:2];
//    //获取返回值
//    [anInvocation getReturnValue:&ret];
//    NSLog(@"最终结果:%zd  参数:%zd",ret,foot);
//}



//转发消息给其他对象
//转发对象方法
- (id)forwardingTargetForSelector:(SEL)aSelector{
    if (aSelector == @selector(test)) {
        //这里表示将该消息转发给son，让son对象去调用son自己的test方法
        //如果son没有实现test方法,就会不做任何处理
        return [[son alloc]init];
    }
    //return nil表示不把消息转发给任何对象，也就是不让任何对象去处理
    return [super forwardingTargetForSelector:aSelector];
}

//转发类方法
+ (id)forwardingTargetForSelector:(SEL)aSelector{
    if (aSelector == @selector(test)) {
        //这里return之后，相当于走了消息发送机制 = object_msgSend([[son alloc]init],@selector(test))，
        //所以如果这里返回的是[son class]就相当于是调用了son的类方法 + (void)test，
        //返回的是[[son alloc]init]就相当于是调用了对象方法 - (void)test
        return [son class];//[[son alloc]init];
    }
    return [super forwardingTargetForSelector:aSelector];
}

//当forwardingTargetForSelector方法不把消息转发给任何对象的时候，就会来到这个方法
//返回一个方法签名(方法的参数和返回值)
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector{
    if (aSelector == @selector(test)) {
        //如果这里return nil就表示参数为nil，如果参数为nil就不会进入forwardInvocation方法里面了
        return [NSMethodSignature signatureWithObjCTypes:"v16@0i8"];
    }
    return [super methodSignatureForSelector:aSelector];
}

//methodSignatureForSelector方法返回的方法签名会封装到这个方法里面
//NSInvocation：封装了一个方法调用，包括：方法参数、方法调用者、方法名
//调用者：anInvocation.target
//方法名：anInvocation.selector
//方法参数：[anInvocation getArgument:NULL atIndex:0]，这个参数就是在调用方法时，传进来的参数。如:[person test:8]那么8就是参数
- (void)forwardInvocation:(NSInvocation *)anInvocation{
    //让son对象去调用son自己的test方法
    //如果son没有实现test方法就会报错EXC_BAD_ACCESS
//    anInvocation.target = [[son alloc]init];
//    [anInvocation invoke];
    [anInvocation invokeWithTarget:[[son alloc]init]];
}



////动态添加类方法
//+ (BOOL)resolveClassMethod:(SEL)sel{
//    if (sel == @selector(fatherEat)) {
//        //这里是获取类方法
//        //第一个参数传本类类对象和 元类类对象都可以，因为底层就是会根据类对象一直找到元类对象，通过元类对象去查找类方法(走消息发送那一套流程)
//        Method addmethod = class_getClassMethod(self, @selector(addEat));
//        //添加类方法
//        //第一个参数是要添加方法的类对象，因为类方法时放在元类对象的方法列表里面的，所以这里应该传元类对象(否则还是会找不到该方法)
//        class_addMethod(object_getClass(self), sel, method_getImplementation(addmethod), method_getTypeEncoding(addmethod));
//
//        return YES;
//    }
//    return [super resolveClassMethod:sel];
//}
//
////动态添加C对象方法
//+ (BOOL)resolveInstanceMethod:(SEL)sel{
//    if (sel == @selector(test)) {
//        //添加c_other函数
//        //C函数的名字就是函数的地址，所以直接传c_other函数的名字就可以获取到c_other的地址，就可以直接拿到函数的实现
//        class_addMethod(self, sel, (IMP)c_other, "v16@0:8");
//        return YES;
//    }
//
//    return [super resolveClassMethod:sel];
//}

- (void)vddTest{
    
}
@end
