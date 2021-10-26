//
//  ZPNetManager.m
//  SourceCode
//
//  Created by 川闽祺派 on 2021/5/21.
//

#import "ZPNetManager.h"
//NSInteger testAge;
@interface ZPNetManager()

@end
@implementation ZPNetManager

- (void)setConfig:(void (^)(personModel *model))block{
    personModel *testmodel = [personModel new];
    testmodel.name = @"以前";
    if (block) {
        block(testmodel);
    }
    NSLog(@"manager:%@ ",testmodel.name);
    
}

@end



@implementation personModel



@end
