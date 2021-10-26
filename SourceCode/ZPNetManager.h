//
//  ZPNetManager.h
//  SourceCode
//
//  Created by 川闽祺派 on 2021/5/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
//typedef <#existing#> <#new#>;
//NSInteger testAge = 3;
@class personModel;
@interface ZPNetManager : NSObject

- (void)setConfig:(void(^)(personModel *model))block;
//@property(nonatomic,copy)void ();
@end

@interface personModel : NSObject

@property(nonatomic,strong)NSString *name;
@property(nonatomic,strong)NSString *age;

@end
NS_ASSUME_NONNULL_END
