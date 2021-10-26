//
//  NSObject+ZPModelMaper.m
//  SourceCode
//
//  Created by 川闽祺派 on 2021/6/4.
//

#import "NSObject+ZPModelMaper.h"
#import <objc/runtime.h>
const char *kZPPropertyList = @"kZPPropertyList";
@implementation NSObject (ZPModelMaper)
+ (instancetype)zp_modelWithJson:(id)dict{
    //实例对象
    id model = [[self alloc]init];
    //使用字典设置对象信息
    //获得self的属性列表
    NSArray *propertyList = [self zp_objectProperties];
    //遍历字典
    [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        //判断key是否在propertyList中
        if ([propertyList containsObject:key]) {
            //获取成员属性类型
            //类型经常变，抽出来
            NSString *ivarType;
            if ([obj isKindOfClass:NSClassFromString(@"__NSCFString")]) {
                ivarType = @"NSString";
            }else if ([obj isKindOfClass:NSClassFromString(@"__NSCFArray")]) {
                ivarType = @"NSArray";
            }else if ([obj isKindOfClass:NSClassFromString(@"__NSCFNumber")]) {
                ivarType = @"NSNumber";
            }else if ([obj isKindOfClass:NSClassFromString(@"__NSCFDictionary")]) {
                ivarType = @"NSDictionary";
            }
            
            //二级转换，字典中还有字典，也需要把对应字典转换成模型
            //判断下value，是不是字典
            if ([obj isKindOfClass:NSClassFromString(@"__NSCFDictionary")]) {//是字典对象，并且属性名称对应类型是自定义类型
                //value:ZPCustomizationModel字典 -> ZPCustomizationModel模型
                //获取模型(ZPCustomizationModel)类对象
                NSString *ivarType = [self zp_dictWithModelClass][key];
                Class modalClass = NSClassFromString(ivarType);
                //字典转模型
                if (modalClass) {
                    obj = [modalClass zp_modelWithJson:obj];
                }
            }
            
            //三级转换:NSArray也是字典，把数组中的字典转换成模型
            //判断值是否是数组
            if ([obj isKindOfClass:[NSArray class]]){
                //判断对应类有没有实现字典数组转模型数组的协议
                if ([self respondsToSelector:@selector(zp_dictWithModelClass)]) {
                    //转换成id类型,方便调用任何对象的方法
                    id idSelf = self;
                    //获取数组中字典对应的模型
                    NSString *type = [idSelf zp_dictWithModelClass][key];
                    //生成模型
                    Class classModel = NSClassFromString(type);
                    NSMutableArray *arrM = [NSMutableArray array];
                    //遍历字典数组，生成模型数组
                    for (NSDictionary *dict in obj) {
                        //字典转模型
                        id model = [classModel zp_modelWithJson:dict];
                        [arrM addObject:model];
                    }
                    //把模型赋值给value
                    obj = arrM;
                }
            }
            
            //KVC字典转模型
            if (obj) {
                //说明属性存在，可以使用KVC设置数值
                [model setValue:obj forKey:key];
            }
            
        }
        
    }];
    
    //返回对象
    return model;
}

//+ (NSDictionary *)zp_dictWithModelClass{
//    return @{@"custom_list" : @"ZPTestModel", @"basic_list" : @"ZPTestModel"};
//}

+ (NSArray *)zp_objectProperties{
    //获取关联对象(属性)
    NSArray *plistArray = objc_getAssociatedObject(self, kZPPropertyList);
    //如果plistArray有值，则直接返回
    if (plistArray) {
        return plistArray;
    }
    
    unsigned int outCount = 0;
    
    //调用运行时方法，取得类的属性列表
    //参数1:要获取的类
    //参数2:类属性的个数指针
    //返回值:所有属性的数组，C语言中，数组的名字，就是指向第一个元素的地址
    /* retain, creat, copy 需要release */
    objc_property_t *propertyList = class_copyPropertyList([self class], &outCount);
    NSMutableArray *mtArray = [NSMutableArray array];
    //遍历所有的属性
    for (unsigned int i = 0; i < outCount; i++) {
        //获取属性
        objc_property_t property = propertyList[i];
        //从property中获取属性名称
        const char *propertyName_C = property_getName(property);
        //将C字符串转化成OC字符串
        NSString *propertyName_OC = [NSString stringWithCString:propertyName_C encoding:NSUTF8StringEncoding];
        //加入数组
        [mtArray addObject:propertyName_OC];
    }
    //设置关联对象
    //参数1:被关联的对象
    //参数2:动态添加的属性的key
    //参数3:动态添加的属性的value
    //参数4:对象的引用关系(策略)
    objc_setAssociatedObject(self, kZPPropertyList, mtArray.copy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    free(propertyList);
    return mtArray.copy;
}
@end
