//
//  Father.h
//  SourceCode
//
//  Created by 川闽祺派 on 2021/5/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Father : NSObject
@property(nonatomic,copy)NSString *age;
@property(nonatomic,copy)void (^recircleBlock)(void);
- (void)printtest;
+ (void)test;
- (int)foot:(int)count;
+ (int)foot:(int)count;
+ (void)fatherEat;
@end

NS_ASSUME_NONNULL_END
