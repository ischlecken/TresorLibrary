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

/* CC == CommonCrypto */
typedef NS_ENUM(UInt8, TresorAlgorithmT)
{ tresorAlgorithmUnknown    = 0,
  
  tresorAlgorithmAES128     = 1,
  tresorAlgorithmAES128CC   = 2,
  tresorAlgorithmAES192     = 3,
  tresorAlgorithmAES192CC   = 4,
  tresorAlgorithmAES256     = 5,
  tresorAlgorithmAES256CC   = 6,
  tresorAlgorithmCASTCC     = 7,
  tresorAlgorithmTwofish256 = 8,
  
  tresorAlgorithmPBKDF2     = 9,
  tresorAlgorithmPBKDF2CC   = 10,
  
  tresorAlgorithmMD5        = 11,
  tresorAlgorithmMD5CC      = 12,
  tresorAlgorithmSHA256     = 13,
  tresorAlgorithmSHA256CC   = 14,
  tresorAlgorithmSHA512     = 15,
  tresorAlgorithmSHA512CC   = 16,
  tresorAlgorithmSHA1       = 17,
  tresorAlgorithmSHA1CC     = 18
};

@interface TresorAlgorithmInfo : NSObject
@property TresorAlgorithmT type;
@property NSString*        name;
@property NSUInteger       blockSize;
@property NSUInteger       keySize;


+(TresorAlgorithmInfo*) tresorAlgorithmInfoForName:(NSString*)name;
+(TresorAlgorithmInfo*) tresorAlgorithmInfoForType:(TresorAlgorithmT)type;
@end

/*==================================END-OF-FILE==========================================*/
