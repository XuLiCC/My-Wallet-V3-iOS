//
//  HDNode.m
//  Blockchain
//
//  Created by Kevin Wu on 10/20/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "HDNode.h"
#import "BTCBigNumber.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "BTCData.h"
#import "RootService.h"
#import "NSString+NSString_EscapeQuotes.h"
#import "NSData+Hex.h"
#import "BTCCurvePoint.h"
#import "BTCBase58.h"
#import "BTCKeychain.h"
#import "BTCNetwork.h"
#import "BTCKey.h"
#import "BTCAddress.h"
#import "KeyPair.h"

@implementation HDNode {
    JSManagedValue *_network;
}

- (KeyPair *)keyPair
{
    KeyPair *keyPairObject = [[KeyPair alloc] initWithKey:self.keychain.key network:self.network];
    return keyPairObject;
}

- (JSValue *)network
{
    return _network.value;
}

- (JSValue *)chainCode
{
    return [app.wallet executeJSSynchronous:[NSString stringWithFormat:@"new Buffer('%@', 'hex')", [self.keychain.chainCode hexadecimalString]]];;
}

- (uint32_t)index
{
    return self.keychain.index;
}

- (uint32_t)parentFingerprint
{
    return self.keychain.parentFingerprint;
}

- (uint8_t)depth
{
    return self.keychain.depth;
}

- (id)initWithKeychain:(BTCKeychain *)keychain network:(JSValue *)network;
{
    if (self = [super init]) {
        self.keychain = keychain;
        if (network == nil || [network isNull] || [network isUndefined]) {
            network = [app.wallet executeJSSynchronous:@"MyWalletPhone.getNetworks().bitcoin"];
        }
        _network = [JSManagedValue managedValueWithValue:network];
        [[[JSContext currentContext] virtualMachine] addManagedReference:_network withOwner:self];
    }
    return self;
}

+ (HDNode *)fromSeed:(NSString *)seed network:(JSValue *)network
{
    // TODO: make TestNet compatible
    BTCNetwork *btcNetwork = [BTCNetwork mainnet];
    BTCKeychain *keychain = [[BTCKeychain alloc] initWithSeed:[seed dataUsingEncoding:NSUTF8StringEncoding] network:btcNetwork];

    return [[HDNode alloc] initWithKeychain:keychain network:network];
}

- (NSString *)getAddress
{
    return self.keychain.key.address.string;
}

+ (HDNode *)fromSeed:(NSString *)seed buffer:(JSValue *)network;
{
    return [HDNode fromSeed:seed network:network];
}

+ (HDNode *)fromSeed:(JSValue *)hex hex:(JSValue *)network
{
    JSValue *seed = [app.wallet executeJSSynchronous:[NSString stringWithFormat:@"new Buffer('%@', 'hex')", [hex toString]]];
    return [HDNode fromSeed:[seed toString] buffer:network];
}

+ (HDNode *)from:(NSString *)seed base58:(JSValue *)networks
{
    return [[HDNode alloc] initWithKeychain:[[BTCKeychain alloc] initWithExtendedKey:seed] network:networks];
}

- (NSString *)getIdentifier
{
    NSData *data = self.keychain.identifier;
    return [[NSString alloc] initWithBytes:(char *)data.bytes length:data.length encoding:NSUTF8StringEncoding];
}

- (JSValue *)getFingerprint
{
    return [JSValue valueWithInt32:self.keychain.fingerprint inContext:app.wallet.context];
}

- (JSValue *)getNetwork
{
    return [JSValue valueWithObject:self.keychain.network inContext:app.wallet.context];
}

- (JSValue *)getPublicKeyBuffer
{
    return [app.wallet executeJSSynchronous:[NSString stringWithFormat:@"new Buffer('%@', 'hex')", self.keychain.extendedPublicKey]];
}

- (BOOL)isNeutered
{
    return !self.keychain.isPrivate;
}

- (NSString *)toBase58:(JSValue *)isPrivate
{
    if (![isPrivate isUndefined]) {
        @throw [NSException exceptionWithName:@"HDNode Exception"
                                       reason:@"Unsupported argument in 2.0.0" userInfo:nil];
        return nil;
    }
    
    if (![self isNeutered]) {
        return self.keychain.extendedPrivateKey;
    } else {
        return self.keychain.extendedPublicKey;
    }
}

- (HDNode *)derive:(JSValue *)_index
{
    return [[HDNode alloc] initWithKeychain:[self.keychain derivedKeychainAtIndex:[_index toUInt32]] network:nil];
}

- (HDNode *)deriveHardened:(JSValue *)_index
{
    return [[HDNode alloc] initWithKeychain:[self.keychain derivedKeychainAtIndex:[_index toUInt32] hardened:YES] network:nil];
}

- (HDNode *)derivePath:(JSValue *)_path
{
    return [[HDNode alloc] initWithKeychain:[self.keychain derivedKeychainWithPath:[_path toString]] network:nil];
}

- (HDNode *)neutered
{
    return [[HDNode alloc] initWithKeychain:[[BTCKeychain alloc] initWithExtendedKey:self.keychain.extendedPublicKey] network:nil];
}

- (JSValue *)sign:(JSValue *)hash
{
    return [self.keyPair sign:hash];
}

- (KeyPair *)verif:(NSString *)hash y:(NSString *)signature
{
    return [self.keyPair verif:hash y:signature];
}

@end
