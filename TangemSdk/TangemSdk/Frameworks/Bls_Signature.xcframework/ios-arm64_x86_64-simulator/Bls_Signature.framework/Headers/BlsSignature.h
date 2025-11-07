#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_CLOSED_ENUM(NSInteger, BlsSignatureErrorCode) {
    /// Non-hex or bad charset
    BlsSignatureErrorInvalidHex            = 100,

    /// NSData argument was not exactly 32 bytes.
    BlsSignatureErrorInvalidByteCount      = 101,

    /// Crypto/state preconditions (optional bucket for things like bad POP)
    BlsSignatureErrorInvalidPOP            = 102,

    /// Underlying C++ std::invalid_argument exception.
    BlsSignatureErrorCppInvalidArgument    = 103,

    /// Underlying C++ exception.
    BlsSignatureErrorCppRuntime            = 104,

    /// Unknown error.
    BlsSignatureErrorUnknown               = 105,
};

FOUNDATION_EXPORT NSErrorDomain const BlsSignatureErrorDomain;

@interface BlsSignature: NSObject

+ (NSString *)publicKeyFrom:(NSString *)privateKey with:(NSError **)error;
+ (NSString *)publicKeyFromData:(NSData *)privateKey with:(NSError **)error;
+ (NSString *)augSchemeMplG2Map:(NSString *)hashPublicKey and:(NSString*)hashMessage with:(NSError **)error;
+ (NSString *)aggregate: (NSArray<NSString *> *)signatures with:(NSError **)error;
+ (BOOL)verify: (NSArray<NSString *> *)signatures with:(NSString *)publicKey and:(NSString *)message;
+ (NSString *)signHash:(NSString *)hash privateKey:(NSData *)privateKey with:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
