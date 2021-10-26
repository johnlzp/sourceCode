//
//  Father+add.h
//  SourceCode
//
//  Created by 川闽祺派 on 2021/6/25.
//

#import "Father.h" 

NS_ASSUME_NONNULL_BEGIN

@interface Father (add)
@property(nonatomic,strong)NSString *son;
- (void)play:(NSString *)name;

+ (void)eat:(NSString *)food;
@end

NS_ASSUME_NONNULL_END
