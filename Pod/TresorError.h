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
#ifdef __OBJC__


#define kTresorErrorDomain     @"TresorErrorDomain"
#define kTresorErrorCoreDomain @"TresorErrorCoreDomain"

enum
{
  TresorErrorUnknown                    = -1,
  TresorErrorIllegalArgument            = -2,

  TresorErrorPadding                    = -3,
  TresorErrorBufferAlloc                = -4,
  TresorErrorHash                       = -5,
  TresorErrorCipher                     = -6,
  
  TresorErrorUnexpectedClassInPath      = -20,
  TresorErrorUnexpectedObjectClass      = -21,
  TresorErrorPathMismatch               = -22,
  TresorErrorPathShouldNotBeNil         = -23,
  TresorErrorPayloadShouldNotBeNil      = -24,
  TresorErrorPayloadIsNotDecrypted      = -25,
  TresorErrorNoPassword                 = -26,
  TresorErrorNoPaddingFound             = -27,
  TresorErrorPaddingHashMismatch        = -28,
  TresorErrorNoPayloadClassNameFound    = -29,
  TresorErrorNoPayloadDataFound         = -30,
  
  TresorErrorCouldNotSerializePayload   = -31,
  TresorErrorCouldNotDeserializePayload = -32,
  
  TresorErrorCouldNotFindPINMasterKey   = -33,
  TresorErrorKeyForPayloadNotSet        = -34,
  TresorErrorCommitPayloadoidNotSet     = -35,
};

#define _TRESORERROR(errCode) [[NSError alloc] initWithDomain:kTresorErrorDomain code:errCode userInfo:nil]

#define TRESOR_CHECKERROR( condition,errCode,description,intErrCode ) \
if( condition ) \
{ createTresorError(outError, errCode, description,intErrCode); \
\
goto cleanUp; \
}

void createTresorError(NSError** outError,int errCode,NSString* description,int internalErrCode);
#endif
/*=================================================END-OF-FILE==================================================*/
