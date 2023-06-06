//
//  tangem_ecdh.h
//  TangemSdk
//
//  Created by Alexander Osokin on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

#ifndef tangem_ecdh_h
#define tangem_ecdh_h

#include "secp256k1.h"
#include "secp256k1_ecdh.h"

static int ecdh_tangem_function(unsigned char *output, const unsigned char *x32, const unsigned char *y32, void *data) {
    memcpy (output, x32, 32);
    return 1;
}

/** An implementation of secp256k1_ecdh_hash_function */
SECP256K1_API_VAR const secp256k1_ecdh_hash_function secp256k1_ecdh_tangem;

const secp256k1_ecdh_hash_function secp256k1_ecdh_tangem = ecdh_tangem_function;

#endif /* tangem_ecdh_h */
