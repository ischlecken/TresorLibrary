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
 */
#include <stdlib.h>
#include <Security/SecRandom.h>
#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonCryptor.h>
#include <CommonCrypto/CommonKeyDerivation.h>
#include "commoncrypto.h"
#include "md5.h"
#include "sha1.h"
#include "sha2.h"
#include "aes.h"
#include "twofish.h"
#include "pwd2key.h"


#define COMMON_CHECK_ERROR( condition,errCode ) \
if( condition ) \
{ result = errCode; \
  goto cleanUp; \
}


/**
 *
 */
int CommonCryptoMD5(BufferT* in,BufferT* digest,bool useCommon)
{ int result = EXIT_SUCCESS;
  
  if( in!=NULL && digest!=NULL )
  { if( digest->length!=MD5_DIGEST_SIZE )
      result = EXIT_FAILURE;
    else
    { 
      if( useCommon )
      { CC_MD5_CTX    ctx;
      
        CC_MD5_Init(&ctx);
        CC_MD5_Update(&ctx, in->data,in->length);
        CC_MD5_Final(digest->data, &ctx);  
      } /* of if */
      else
      { MD5ContextT ctx[1];
        int         internalErrCode = EXIT_SUCCESS;
        
        internalErrCode = md5_begin(ctx);
        COMMON_CHECK_ERROR( internalErrCode!=MD5_OK,internalErrCode );
        
        internalErrCode = md5_hash(ctx, in);
        COMMON_CHECK_ERROR( internalErrCode!=MD5_OK,internalErrCode );
        
        internalErrCode = md5_end(ctx,digest);
        COMMON_CHECK_ERROR( internalErrCode!=MD5_OK,internalErrCode );
        
        internalErrCode = buffer_check(digest);
        COMMON_CHECK_ERROR( internalErrCode!=BUFFER_OK,internalErrCode );
      } /* of else */
    } /* of else */
  } /* of if */
cleanUp:

  return result;
} /* of CommonCryptoMD5() */


/**
 *
 */
int CommonCryptoSHA1(BufferT* in,BufferT* digest,bool useCommon)
{ int result = EXIT_SUCCESS;
  
  if( in!=NULL && digest!=NULL )
  { if( digest->length!=SHA1_DIGEST_SIZE )
      result = EXIT_FAILURE;
    else
    { 
      if( useCommon )
      { CC_SHA1_CTX    ctx;
        
        CC_SHA1_Init(&ctx);
        CC_SHA1_Update(&ctx, in->data,in->length);
        CC_SHA1_Final(digest->data, &ctx); 
      } /* of if */
      else
      { SHA1ContextT ctx[1];
        int          internalErrCode = EXIT_SUCCESS;
        
        internalErrCode = sha1_begin(ctx);
        COMMON_CHECK_ERROR( internalErrCode!=SHA1_OK,internalErrCode );
        
        internalErrCode = sha1_hash(ctx, in);
        COMMON_CHECK_ERROR( internalErrCode!=SHA1_OK,internalErrCode );
        
        internalErrCode = sha1_end(ctx,digest);
        COMMON_CHECK_ERROR( internalErrCode!=SHA1_OK,internalErrCode );
        
        internalErrCode = buffer_check(digest);
        COMMON_CHECK_ERROR( internalErrCode!=BUFFER_OK,internalErrCode );
      } /* of else */
    } /* of else */
  } /* of if */
cleanUp:
  
  return result;
} /* of CommonCryptoSHA1() */



/**
 *
 */
int CommonCryptoSHA256(BufferT* in,BufferT* digest,bool useCommon)
{ int result = EXIT_SUCCESS;
  
  if( in!=NULL && digest!=NULL )
  { if( digest->length!=SHA256_DIGEST_SIZE )
      result = EXIT_FAILURE;
    else
    { if( useCommon )
      { CC_SHA256_CTX    ctx;
        
        CC_SHA256_Init(&ctx);
        CC_SHA256_Update(&ctx, in->data,in->length);
        CC_SHA256_Final(digest->data, &ctx);  
      } /* of if */
      else
      { SHA256ContextT ctx[1];
        int            internalErrCode = EXIT_SUCCESS;
        
        internalErrCode = sha256_begin(ctx);
        COMMON_CHECK_ERROR( internalErrCode!=SHA2_OK,internalErrCode );
        
        internalErrCode = sha256_hash(ctx, in);
        COMMON_CHECK_ERROR( internalErrCode!=SHA2_OK,internalErrCode );
        
        internalErrCode = sha256_end(ctx,digest);
        COMMON_CHECK_ERROR( internalErrCode!=SHA2_OK,internalErrCode );
        
        internalErrCode = buffer_check(digest);
        COMMON_CHECK_ERROR( internalErrCode!=BUFFER_OK,internalErrCode );
      } /* of else */
    } /* of else */
  } /* of if */
cleanUp:
  
  return result;
} /* of CommonCryptoSHA256() */


/**
 *
 */
int CommonCryptoSHA512(BufferT* in,BufferT* digest,bool useCommon)
{ int result = EXIT_SUCCESS;
  
  if( in!=NULL && digest!=NULL )
  { if( digest->length!=SHA512_DIGEST_SIZE )
      result = EXIT_FAILURE;
    else
    { if( useCommon )
      { CC_SHA512_CTX    ctx;

        CC_SHA512_Init(&ctx);
        CC_SHA512_Update(&ctx, in->data,in->length);
        CC_SHA512_Final(digest->data, &ctx);  
      } /* of if */
      else
      { SHA512ContextT ctx[1];
        int            internalErrCode = EXIT_SUCCESS;
        
        internalErrCode = sha512_begin(ctx);
        COMMON_CHECK_ERROR( internalErrCode!=SHA2_OK,internalErrCode );
        
        internalErrCode = sha512_hash(ctx, in);
        COMMON_CHECK_ERROR( internalErrCode!=SHA2_OK,internalErrCode );
        
        internalErrCode = sha512_end(ctx,digest);
        COMMON_CHECK_ERROR( internalErrCode!=SHA2_OK,internalErrCode );
        
        internalErrCode = buffer_check(digest);
        COMMON_CHECK_ERROR( internalErrCode!=BUFFER_OK,internalErrCode );
      } /* of else */
    } /* of else */
  } /* of if */
cleanUp:
  
  return result;
} /* of CommonCryptoSHA512() */

/**
 *
 */
int CommonCryptoAES128Encrypt(BufferT* in,BufferT* key,BufferT* iv,BufferT* out,bool useCommon)
{ int result = EXIT_SUCCESS;
  
  if( key==NULL || in==NULL || out==NULL || iv==NULL || 
      (key->length!=AES128_KEY_SIZE && key->length!=AES192_KEY_SIZE && key->length!=AES256_KEY_SIZE) || 
      in->length==0 || in->length>out->length || in->data==NULL || out->data==NULL ||
      iv->data==NULL || iv->length!=AES_BLOCK_SIZE
    )
  { result = EXIT_FAILURE;
    
    goto cleanUp;
  } /* of if */
  
  int outBufferSize = AES_BLOCK_SIZE * (in->length/AES_BLOCK_SIZE + 1);
  
  if( outBufferSize!=out->length )
  { result = EXIT_FAILURE;
    
    goto cleanUp;
  } /* of if */
  
  if( useCommon )
  { CCCryptorRef    ctx;
    CCCryptorStatus ccStatus = CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, key->data, key->length, iv->data,&ctx);
    
    COMMON_CHECK_ERROR( ccStatus!=kCCSuccess,ccStatus );
    
    size_t dataOutMoved = 0;
    void*  dataOut      = out->data;
    size_t dataLen      = out->length;
    
    ccStatus = CCCryptorUpdate(ctx, in->data, in->length, dataOut,dataLen, &dataOutMoved);
    COMMON_CHECK_ERROR( ccStatus!=kCCSuccess,ccStatus );
    
    dataOut += dataOutMoved;
    dataLen -= dataOutMoved;
    
    ccStatus = CCCryptorFinal(ctx,dataOut,dataLen, &dataOutMoved);
    COMMON_CHECK_ERROR( ccStatus!=kCCSuccess,ccStatus );
    
    ccStatus = CCCryptorRelease(ctx);
    COMMON_CHECK_ERROR( ccStatus!=kCCSuccess,ccStatus );
    
  } /* of if */
  else
  { AESContextT       ctx[1];
    int               internalErrCode = EXIT_SUCCESS;
    unsigned char*    str             = in->data;
    int               strLen          = in->length;
    int               cipherBlocks    = strLen/AES_BLOCK_SIZE + 1;
    unsigned char*    cryptResultPtr  = out->data;
    
    BUFFER_T(AES_BLOCK_SIZE,cryptBuffer);
    
    memcpy(cryptBuffer.data, iv->data, iv->length);
    
    internalErrCode = aes_begin(ctx,key,iv);
    COMMON_CHECK_ERROR( internalErrCode!=AES_OK,internalErrCode );
    
    for( int i=0;i<cipherBlocks;i++ )
    { BUFFER_T(AES_BLOCK_SIZE,plainBuffer);
      
      int sLen = strLen>0 ? (strLen>=AES_BLOCK_SIZE ? AES_BLOCK_SIZE : strLen) : 0;
      
      if( sLen>0 )
        memcpy(plainBuffer.data,str,sLen);
      
      if( sLen<AES_BLOCK_SIZE )
      { if( sLen<=0 )
          memset(plainBuffer.data,AES_BLOCK_SIZE,AES_BLOCK_SIZE);
        else
          memset(plainBuffer.data+sLen,AES_BLOCK_SIZE-sLen,AES_BLOCK_SIZE-sLen);
      } /* of if */
      
      internalErrCode = aes_encrypt(ctx,(BufferT*) &plainBuffer,(BufferT*)&cryptBuffer);
      COMMON_CHECK_ERROR( internalErrCode!=AES_OK,internalErrCode );
      
      memcpy(cryptResultPtr, cryptBuffer.data, AES_BLOCK_SIZE);
      
      if( sLen>0 )
      { str            += sLen;
        strLen         -= sLen;
        cryptResultPtr += AES_BLOCK_SIZE;
      } /* of if */
    } /* of for */
    
    internalErrCode = aes_end(ctx);
    COMMON_CHECK_ERROR( internalErrCode!=AES_OK,internalErrCode );
  } /* of else */
cleanUp:
                  
  return result;
} /* of CommonCryptoAES128Encrypt() */

/**
 *
 */
int CommonCryptoAES128Decrypt(BufferT* in,BufferT* key,BufferT* iv,BufferT* out,bool useCommon)
{ int result = EXIT_SUCCESS;
  
  if( key==NULL || in==NULL || out==NULL || iv==NULL || 
      (key->length!=AES128_KEY_SIZE && key->length!=AES192_KEY_SIZE && key->length!=AES256_KEY_SIZE) || 
      in->length==0 || in->length>out->length || in->data==NULL || out->data==NULL || (in->length%AES_BLOCK_SIZE)!=0 ||
      iv->data==NULL || iv->length!=AES_BLOCK_SIZE
    )
  { result = EXIT_FAILURE;
    
    goto cleanUp;
  } /* of if */
  
  if( useCommon )
  { CCCryptorRef    ctx;
    CCCryptorStatus ccStatus = CCCryptorCreate(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, key->data, key->length, iv->data,&ctx);
    
    COMMON_CHECK_ERROR( ccStatus!=kCCSuccess,ccStatus );
    
    size_t dataOutMoved = 0;
    void*  dataOut      = out->data;
    size_t dataLen      = out->length;
    
    ccStatus = CCCryptorUpdate(ctx, in->data, in->length, dataOut,dataLen, &dataOutMoved);
    COMMON_CHECK_ERROR( ccStatus!=kCCSuccess,ccStatus );
    
    dataOut += dataOutMoved;
    dataLen -= dataOutMoved;
    
    ccStatus = CCCryptorFinal(ctx,dataOut,dataLen, &dataOutMoved);
    COMMON_CHECK_ERROR( ccStatus!=kCCSuccess,ccStatus );
    
    dataLen -= dataOutMoved;
    
    ccStatus = CCCryptorRelease(ctx);
    COMMON_CHECK_ERROR( ccStatus!=kCCSuccess,ccStatus );
    
    out->length -= dataLen;
  } /* of if */
  else
  { AESContextT ctx[1];
    int         internalErrCode = EXIT_SUCCESS;
    
    internalErrCode = aes_begin(ctx,key,iv);
    COMMON_CHECK_ERROR( internalErrCode!=AES_OK,internalErrCode );
    
    int cipherBlocks = in->length/AES_BLOCK_SIZE;
    
    BUFFER_T(AES_BLOCK_SIZE,ivBuffer);
    memcpy(ivBuffer.data, iv->data, iv->length);
    
    for( int i=0;i<cipherBlocks;i++ )
    { BUFFER_T(AES_BLOCK_SIZE,cryptBuffer);
      BUFFER_T(AES_BLOCK_SIZE,plainBuffer);
      
      memcpy(cryptBuffer.data,in->data+i*AES_BLOCK_SIZE,AES_BLOCK_SIZE);
      
      internalErrCode = aes_decrypt(ctx,(BufferT*) &cryptBuffer,(BufferT*)&plainBuffer);
      COMMON_CHECK_ERROR( internalErrCode!=AES_OK,internalErrCode );
      
      //for( int k=0;k<plainBuffer.length;k++ )
      //  plainBuffer.data[k] ^= ivBuffer.data[k];
      
      memcpy(ivBuffer.data, cryptBuffer.data, cryptBuffer.length);
      
      memcpy(out->data+i*AES_BLOCK_SIZE,plainBuffer.data,AES_BLOCK_SIZE);
    } /* of for */
    
    internalErrCode = aes_end(ctx);
    COMMON_CHECK_ERROR( internalErrCode!=AES_OK,internalErrCode );
    
    unsigned char padding = out->data[cipherBlocks*AES_BLOCK_SIZE - 1];        
    COMMON_CHECK_ERROR( padding>AES_BLOCK_SIZE,EXIT_FAILURE );
    
    unsigned char paddingBlock[AES_BLOCK_SIZE];          
    memset(paddingBlock,padding,padding);
    
    unsigned char* paddingBlock0 = out->data+cipherBlocks*AES_BLOCK_SIZE - padding;
    COMMON_CHECK_ERROR( memcmp(paddingBlock0,paddingBlock,padding)!=0,EXIT_FAILURE );
    
    memset(paddingBlock0,0,padding);
    
    out->length -= padding;
  } /* of else */
cleanUp:
  
  return result;
} /* of CommonCryptoAES128Decrypt() */

/**
 *
 */
int CommonCryptoCASTEncrypt(BufferT* in,BufferT* key,BufferT* iv,BufferT* out,bool useCommon)
{ int result = EXIT_SUCCESS;
  
  if( key==NULL || in==NULL || out==NULL || iv==NULL || 
     (key->length<kCCKeySizeMinCAST || key->length>kCCKeySizeMaxCAST) || 
     in->length==0 || in->length>out->length || in->data==NULL || out->data==NULL ||
     iv->data==NULL || iv->length!=kCCBlockSizeCAST
     )
  { result = EXIT_FAILURE;
    
    goto cleanUp;
  } /* of if */
  
  int outBufferSize = kCCBlockSizeCAST * (in->length/kCCBlockSizeCAST + 1);
  
  if( outBufferSize!=out->length )
  { result = EXIT_FAILURE;
    
    goto cleanUp;
  } /* of if */
  
  if( useCommon )
  { CCCryptorRef    ctx;
    CCCryptorStatus ccStatus = CCCryptorCreate(kCCEncrypt, kCCAlgorithmCAST, kCCOptionPKCS7Padding, key->data, key->length, iv->data,&ctx);
    
    COMMON_CHECK_ERROR( ccStatus!=kCCSuccess,ccStatus );
    
    size_t dataOutMoved = 0;
    void*  dataOut      = out->data;
    size_t dataLen      = out->length;
    
    ccStatus = CCCryptorUpdate(ctx, in->data, in->length, dataOut,dataLen, &dataOutMoved);
    COMMON_CHECK_ERROR( ccStatus!=kCCSuccess,ccStatus );
    
    dataOut += dataOutMoved;
    dataLen -= dataOutMoved;
    
    ccStatus = CCCryptorFinal(ctx,dataOut,dataLen, &dataOutMoved);
    COMMON_CHECK_ERROR( ccStatus!=kCCSuccess,ccStatus );
    
    ccStatus = CCCryptorRelease(ctx);
    COMMON_CHECK_ERROR( ccStatus!=kCCSuccess,ccStatus );
  } /* of if */
cleanUp:
  
  return result;
} /* of CommonCryptoCASTEncrypt() */

/**
 *
 */
int CommonCryptoCASTDecrypt(BufferT* in,BufferT* key,BufferT* iv,BufferT* out,bool useCommon)
{ int result = EXIT_SUCCESS;
  
  if( key==NULL || in==NULL || out==NULL || iv==NULL || 
     (key->length<kCCKeySizeMinCAST || key->length>kCCKeySizeMaxCAST) || 
     in->length==0 || in->length>out->length || in->data==NULL || out->data==NULL || (in->length%kCCBlockSizeCAST)!=0 ||
     iv->data==NULL || iv->length!=kCCBlockSizeCAST
     )
  { result = EXIT_FAILURE;
    
    goto cleanUp;
  } /* of if */
  
  if( useCommon )
  { CCCryptorRef    ctx;
    CCCryptorStatus ccStatus = CCCryptorCreate(kCCDecrypt, kCCAlgorithmCAST, kCCOptionPKCS7Padding, key->data, key->length, iv->data,&ctx);
    
    COMMON_CHECK_ERROR( ccStatus!=kCCSuccess,ccStatus );
    
    size_t dataOutMoved = 0;
    void*  dataOut      = out->data;
    size_t dataLen      = out->length;
    
    ccStatus = CCCryptorUpdate(ctx, in->data, in->length, dataOut,dataLen, &dataOutMoved);
    COMMON_CHECK_ERROR( ccStatus!=kCCSuccess,ccStatus );
    
    dataOut += dataOutMoved;
    dataLen -= dataOutMoved;
    
    ccStatus = CCCryptorFinal(ctx,dataOut,dataLen, &dataOutMoved);
    COMMON_CHECK_ERROR( ccStatus!=kCCSuccess,ccStatus );
    
    dataLen -= dataOutMoved;
    
    ccStatus = CCCryptorRelease(ctx);
    COMMON_CHECK_ERROR( ccStatus!=kCCSuccess,ccStatus );
    
    out->length -= dataLen;
  } /* of if */
cleanUp:
  
  return result;
} /* of CommonCryptoCASTDecrypt() */


/**
 *
 */
int CommonCryptoTwofishEncrypt(BufferT* in,BufferT* key,BufferT* iv,BufferT* out,bool useCommon)
{ int result = EXIT_SUCCESS;
  
  if( key==NULL || in==NULL || out==NULL || iv==NULL || 
      key->length!=TWOFISH_KEY_SIZE || 
      in->length==0 || in->length>out->length || in->data==NULL || out->data==NULL ||
      iv->data==NULL || iv->length!=TWOFISH_BLOCK_SIZE ||
      (TWOFISH_BLOCK_SIZE * (in->length/TWOFISH_BLOCK_SIZE + 1))!=out->length
    )
  { result = EXIT_FAILURE;
    
    goto cleanUp;
  } /* of if */

  int             tfStatus=0;
  TwofishContextT ctx[1];
  
  tfStatus = twofish_begin(ctx,key,iv);
  COMMON_CHECK_ERROR( tfStatus!=TWOFISH_OK, tfStatus);
  
  tfStatus = twofish_encrypt(ctx, in,out,1);
  COMMON_CHECK_ERROR( tfStatus!=TWOFISH_OK, tfStatus);
  
  tfStatus = twofish_end(ctx);
  COMMON_CHECK_ERROR( tfStatus!=TWOFISH_OK, tfStatus);

cleanUp:
  
  return result;
} /* of CommonCryptoTwofishEncrypt() */

/**
 *
 */
int CommonCryptoTwofishDecrypt(BufferT* in,BufferT* key,BufferT* iv,BufferT* out,bool useCommon)
{ int result = EXIT_SUCCESS;
  
  if( key==NULL || in==NULL || out==NULL || iv==NULL || 
      key->length!=TWOFISH_KEY_SIZE || 
      in->length==0 || in->length>out->length || in->data==NULL || out->data==NULL || (in->length%TWOFISH_BLOCK_SIZE)!=0 ||
      iv->data==NULL || iv->length!=TWOFISH_BLOCK_SIZE 
    )
  { result = EXIT_FAILURE;
    
    goto cleanUp;
  } /* of if */
  
  int             tfStatus=0;
  TwofishContextT ctx[1];
  
  tfStatus = twofish_begin(ctx,key,iv);
  COMMON_CHECK_ERROR( tfStatus!=TWOFISH_OK, tfStatus);
  
  tfStatus = twofish_decrypt(ctx, in,out,1);
  COMMON_CHECK_ERROR( tfStatus!=TWOFISH_OK, tfStatus);

  tfStatus = twofish_end(ctx);
  COMMON_CHECK_ERROR( tfStatus!=TWOFISH_OK, tfStatus);

cleanUp:
  
  return result;
} /* of CommonCryptoTwofishDecrypt() */

/**
 *
 */
int CommonCryptoRandomData(BufferT* data)
{ int result = EXIT_SUCCESS;
  
  if( data!=NULL && SecRandomCopyBytes(kSecRandomDefault,data->length,data->data)!=0 )
    result = EXIT_FAILURE;
  
  return result;
}

/**
 *
 */
int CommonCryptoDeriveKey(BufferT* pwd,BufferT* salt,BufferT* key,unsigned int iter,bool useCommon)
{ int result = EXIT_SUCCESS;
    
  if( pwd!=NULL && salt!=NULL && key!=NULL )
  { 
    if( useCommon )
    { CCCryptorStatus ccStatus= CCKeyDerivationPBKDF( kCCPBKDF2,
                                                      (const char*)pwd->data,
                                                      pwd->length,
                                                      salt->data,
                                                      salt->length,
                                                      kCCPRFHmacAlgSHA1,
                                                      iter,
                                                      key->data,
                                                      key->length
                                                     );
      
      COMMON_CHECK_ERROR( ccStatus!=kCCSuccess,ccStatus );
    } /* of if */
    else
    { int internalErrCode = deriveKey(pwd,salt,key,iter);
      
      COMMON_CHECK_ERROR( internalErrCode!=DERIVEKEY_OK ,internalErrCode );
    } /* of else */
  } /* of if */
cleanUp:
  
  return result;
} /* of CommonCryptoDeriveKey() */
/*============================================================================END-OF-FILE============================================================================*/
