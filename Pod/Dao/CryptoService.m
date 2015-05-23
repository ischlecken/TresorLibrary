/*
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see http://www.gnu.org/licenses/.
 *
 * Copyright (c) 2014 ischlecken.
 */
#import "CryptoService.h"
#import "DecryptedObjectCache.h"
#import "TresorModel.h"
#import "TresorError.h"
#import "Macros.h"
#import "Payload.h"
#import "Key.h"
#import "MasterKey.h"
#import "Commit.h"

#import "TresorDaoCategories.h"
#import "JSONModel.h"
#import "NSString+Date.h"
#import "NSData+Crypto.h"
#import "TresorAlgorithmInfo.h"
#import "NSString+Crypto.h"


@implementation CryptoService

/**
 *
 */
+(CryptoService*) sharedInstance
{ static CryptoService*   _inst = nil;
  static dispatch_once_t  oncePredicate;
  
  dispatch_once(&oncePredicate, ^{ _inst = [self new]; });
  
  return _inst;
}


/**
 *
 */
-(PMKPromise*) decryptPayload:(Payload*)payload
{ PMKPromise* result = nil;
  
  if( self.delegate==nil )
    @throw [NSException exceptionWithName:@"DelegateNotSetException" reason:nil userInfo:nil];
  
  id decryptedPayload = [[DecryptedObjectCache sharedInstance] decryptedObjectForUniqueId:[payload uniqueObjectId]];
  
  if( decryptedPayload )
    result = [PMKPromise promiseWithValue:payload];
  else
  { MasterKey* masterKey = [[payload vault] pinMasterKey];
    
    if( masterKey==nil )
      result = [PMKPromise promiseWithResolverBlock:^(PMKResolver resolve)
      { resolve(_TRESORERROR(TresorErrorCouldNotFindPINMasterKey));
      }];
    else
    { PMKPromise* decryptedPayloadKey = [self.delegate decryptedMasterKey:masterKey];
      
      if( decryptedPayloadKey )
        result = decryptedPayloadKey
        .then(^(NSData* decryptedMasterKey)
        { return [payload decryptPayloadUsingDecryptedMasterKey:decryptedMasterKey]; });
    } /* of else */
  } /* of else */
  
  return result;
}

/**
 *
 */
-(PMKPromise*) encryptObject:(id)object forCommit:(Commit*)commit
{ PMKPromise* result = nil;
  
  if( self.delegate==nil )
    @throw [NSException exceptionWithName:@"DelegateNotSetException" reason:nil userInfo:nil];
  
  MasterKey* masterKey = [commit.vault pinMasterKey];
  if( masterKey==nil )
    result = [PMKPromise promiseWithResolverBlock:^(PMKResolver resolve)
    { resolve(_TRESORERROR(TresorErrorCouldNotFindPINMasterKey));
    }];
  else
  { PMKPromise* decryptedPayloadKey = [self.delegate decryptedMasterKey:masterKey];
    
    if( decryptedPayloadKey )
      result = decryptedPayloadKey
      .then(^(NSData* decryptedMasterKey)
      { return [Payload payloadWithObject:object inCommit:commit usingDecryptedMasterKey:decryptedMasterKey]; });
  } /* of else */
  
  return result;
}

@end
