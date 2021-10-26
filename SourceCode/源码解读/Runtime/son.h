//
//  son.h
//  SourceCode
//
//  Created by 川闽祺派 on 2021/5/22.
//

#import "Father.h"

NS_ASSUME_NONNULL_BEGIN

@interface son : Father
@property(nonatomic,strong)NSString *name;
@property(nonatomic,assign)NSInteger age;
- (int)foot:(int)count;
+ (int)foot:(int)count;
- (void)sonTestMe;
//+ (void)test;

//- (void)test;

@end

NS_ASSUME_NONNULL_END
