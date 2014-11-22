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
#import "TresorUtilConstant.h"
#include "crypto.h"

#define kVaultAlgoKeyIterations 10000

NSString* const VaultAlgorithmString[] =
{ [vaultAES128]=@"_aes128",[vaultAES128CC]=@"aes128",
  [vaultAES192]=@"_aes192",[vaultAES192CC]=@"aes192",
  [vaultAES256]=@"_aes256",[vaultAES256CC]=@"aes256",
  [vaultCASTCC]=@"cast",
  [vaultTwofish256]=@"twofish256",
  nil 
};


AlgorithmInfoT VaultAlgorithmInfo[] = 
{ [vaultAES128]     = { cryptAlgoAES128,AES_BLOCK_SIZE,AES128_KEY_SIZE,kVaultAlgoKeyIterations },
  [vaultAES192]     = { cryptAlgoAES192,AES_BLOCK_SIZE,AES192_KEY_SIZE,kVaultAlgoKeyIterations },
  [vaultAES256]     = { cryptAlgoAES256,AES_BLOCK_SIZE,AES256_KEY_SIZE,kVaultAlgoKeyIterations },
  [vaultAES128CC]   = { cryptAlgoAES128CC,AES_BLOCK_SIZE,AES128_KEY_SIZE,kVaultAlgoKeyIterations },
  [vaultAES192CC]   = { cryptAlgoAES192CC,AES_BLOCK_SIZE,AES192_KEY_SIZE,kVaultAlgoKeyIterations },
  [vaultAES256CC]   = { cryptAlgoAES256CC,AES_BLOCK_SIZE,AES256_KEY_SIZE,kVaultAlgoKeyIterations },
  [vaultCASTCC]     = { cryptAlgoCASTCC,CAST_BLOCK_SIZE,CAST16_KEY_SIZE,kVaultAlgoKeyIterations },
  [vaultTwofish256] = { cryptAlgoTWOFISH256,TWOFISH_BLOCK_SIZE,TWOFISH_KEY_SIZE,kVaultAlgoKeyIterations }
};

VaultAlgorithmT getVaultAlgorithm(NSString* name)
{ VaultAlgorithmT result = vaultUnknown;
  
  if( name )
    for( int i=0;VaultAlgorithmString[i]!=nil;i++ )
      if( [VaultAlgorithmString[i] isEqualToString:name] )
      { result = i;
        
        break;
      } /* of if */
    
  return result;
}
/*====================================================END-OF-FILE==========================================================*/
