//
//  NSObject+ZPModelMaperSecond.m
//  SourceCode
//
//  Created by 川闽祺派 on 2021/6/5.
//

#import "NSObject+ZPModelMaperSecond.h"
#import <objc/runtime.h>
@implementation NSObject (ZPModelMaperSecond)
+ (instancetype)zp_modelWithJson:(id)dict{
    //创建对应模型对象
    id object = [[self alloc]init];
    unsigned int count = 0;
    //1.获取成员属性数组
    Ivar *ivarList = class_copyIvarList(self, &count);
    //2.遍历所有的成员属性名，一个一个去字典中取出对应的value给模型属性赋值
    for (int i = 0; i < count; i++) {
        //2.1 获取成员属性
        Ivar ivar = ivarList[i];
        //2.2 获取成员属性名 C -> OC字符串
        NSString *ivarName = [NSString stringWithCString:ivar_getName(ivar) encoding:NSUTF8StringEncoding];
        //2.3 成员属性名 -> 字典key
        NSString *key = [ivarName substringFromIndex:1];
        //2.4 去字典中取出对应value给模型属性赋值
        id value = dict[key];
        //获取成员属性类型
        NSString *ivarType = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivar)];
        //二级转换，字典中还有字典，也需要把对应字典转换成模型
        if ([value isKindOfClass:[NSDictionary class]] && ![ivarType containsString:@"NS"]) {//是字典对象,并且属性名对应类型是自定义类型
            //处理类型字符串 @\"ZPTestModel\" -> ZPTestModel
            ivarType = [ivarType stringByReplacingOccurrencesOfString:@"@" withString:@""];
            ivarType = [ivarType stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            // 自定义对象,并且值是字典
            // value:ZPTestModel字典 -> ZPTestModel模型
            // 获取模型(ZPTestModel)类对象
            Class modalClass = NSClassFromString(ivarType);
            
            // 字典转模型
            if (modalClass) {
                // 字典转模型 ZPTestModel
                value = [modalClass zp_modelWithJson:value];
            }
        }
        
        // 三级转换：NSArray中也是字典，把数组中的字典转换成模型.
        // 判断值是否是数组
        if ([value isKindOfClass:[NSArray class]]) {
            // 判断对应类有没有实现字典数组转模型数组的协议
            if ([self respondsToSelector:@selector(zp_dictWithModelClass)]) {
                // 转换成id类型，就能调用任何对象的方法
                id idSelf = self;
                // 获取数组中字典对应的模型
                NSString *type =  [idSelf zp_dictWithModelClass][key];
                // 生成模型
                Class classModel = NSClassFromString(type);
                NSMutableArray *arrM = [NSMutableArray array];
                // 遍历字典数组，生成模型数组
                for (NSDictionary *dict in value) {
                    // 字典转模型
                    id model =  [classModel zp_modelWithJson:dict];
                    [arrM addObject:model];
                }
                
                // 把模型数组赋值给value
                value = arrM;
                
            }
        }
        
        // 2.5 KVC字典转模型
        if (value) {
            [object setValue:value forKey:key];
        }
    }
    return object;
}
@end
