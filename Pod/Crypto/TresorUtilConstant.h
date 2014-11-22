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
#import "NSData+Crypto.h"

typedef enum 
{ vaultAES128     = 0,
  vaultAES128CC   = 1,
  vaultAES192     = 2,
  vaultAES192CC   = 3,
  vaultAES256     = 4,
  vaultAES256CC   = 5,
  vaultCASTCC     = 6,
  vaultTwofish256 = 7,
  vaultUnknown    = 99
} VaultAlgorithmT;

typedef struct
{ TresorCryptoAlgorithmT cryptoAlgorithm;
  NSUInteger             blockSize;
  NSUInteger             keySize;
  NSUInteger             keyIterations;
} AlgorithmInfoT;

extern NSString* const VaultAlgorithmString[];
extern AlgorithmInfoT  VaultAlgorithmInfo[];

VaultAlgorithmT getVaultAlgorithm(NSString* name);
/*==================================END-OF-FILE==========================================*/
