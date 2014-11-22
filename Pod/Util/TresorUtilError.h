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

#define kErrorListAdded @"errorListAdded"

extern NSString *const TresorUtilErrorDomain;
extern NSArray* gErrorList;

typedef enum
{ AddErrorNothing    = 0,
  AddErrorExitApp    = 1,
  AddErrorUIFeedback = 2,
  AddErrorAlert      = 4
} AddErrorActionType;


@interface ErrorDescription : NSObject
@property(nonatomic,strong) NSString*          msg;
@property(nonatomic,strong) NSError*           error;
@property(nonatomic,strong) NSDate*            timestamp;
@property(nonatomic,assign) AddErrorActionType action;
-(NSString*) errorMessage;
@end

enum
{ VaultErrorUnknown                   = -1,
  VaultErrorDigestMismatch            = -2,
  VaultErrorLastError                 = -3
};

#define _TRESORUTIL_CHECK_ERROR0( condition,errCode,description,intErrCode ) \
  if( condition ) \
  { intError = createError0(errCode, description,intErrCode); \
    \
    goto cleanUp; \
  }

#define _TRESORUTIL_CHECK_ERROR1( condition,errCode,description,intErrCode ) \
if( condition ) \
{ intError = createError1(errCode, description,intErrCode); \
  \
  goto cleanUp; \
}

#define _TRESORUTIL_SHOW_ERROR( error,exitOnError ) \
  if( error!=nil ) \
  { addToErrorList(@"VaultError",error,exitOnError ? AddErrorExitApp : AddErrorNothing); goto cleanUp; } \


NSError* createError0(int errCode,NSString* description,int internalErrCode);
NSError* createError1(int errCode,NSString* description,NSError* underlyingError);
void     raiseException(NSError* error,NSString* name);
void     addToErrorList(NSString* msg,NSError* error,AddErrorActionType action);
/*=======================================END-OF-FILE===============================================*/
