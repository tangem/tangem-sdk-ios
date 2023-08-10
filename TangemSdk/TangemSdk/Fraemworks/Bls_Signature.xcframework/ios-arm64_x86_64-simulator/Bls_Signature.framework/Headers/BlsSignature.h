#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BlsSignature: NSObject

+ (NSString *)publicKeyFrom:(NSString *)privateKey with:(NSError **)error;
+ (NSString *)augSchemeMplG2Map:(NSString *)hashPublicKey and:(NSString*)hashMessage with:(NSError **)error;
+ (NSString *)aggregate: (NSArray<NSString *> *)signatures with:(NSError **)error;
+ (BOOL)verify: (NSArray<NSString *> *)signatures with:(NSString *)publicKey and:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
