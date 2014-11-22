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
#import "Macros.h"
#import "TresorUtilError.h"

NSString *const TresorUtilErrorDomain = @"TresorUtilErrorDomain";
NSArray*        gErrorList            = nil;

@implementation ErrorDescription

/**
 *
 */
-(NSString*) errorMessage
{ NSString* message =  nil;
  
  if( self.error.userInfo && self.error.userInfo[@"reason"] )
    message = self.error.userInfo[@"reason"];
  
  if( message==nil )
    message = [self.error localizedFailureReason];
  
  if( message==nil )
    message = [self.error localizedDescription];
  
  return message;
}
@end

/**
 *
 */
NSError* createError0(int errCode,NSString* description,int internalErrCode)
{ NSError* underlyingError = nil;

  if( internalErrCode!=0 )
    underlyingError = [[NSError alloc] initWithDomain:TresorUtilErrorDomain code:internalErrCode userInfo:nil];

  return createError1(errCode, description, underlyingError);
} /* of create360MobileError0() */

/**
 *
 */
NSError* createError1(int errCode,NSString* description,NSError* underlyingError)
{ NSString*     localizedDescription = _LSTR(description);

  NSArray* objArray        = nil;
  NSArray* keyArray        = nil;
  
  NSLog(@"createError1(errCode=%d,description=%@,underlyingError=%@)",errCode,description,underlyingError);

  if( underlyingError!=nil )
  { objArray        = [NSArray      arrayWithObjects     :localizedDescription     ,underlyingError     ,nil];
    keyArray        = [NSArray      arrayWithObjects     :NSLocalizedDescriptionKey,NSUnderlyingErrorKey,nil];
  } /* of if */
  else
  { objArray        = [NSArray      arrayWithObjects     :localizedDescription     ,nil];
    keyArray        = [NSArray      arrayWithObjects     :NSLocalizedDescriptionKey,nil];
  } /* of if */

  NSDictionary* eDict = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];

  return [[NSError alloc] initWithDomain:TresorUtilErrorDomain code:errCode userInfo:eDict];
} /* of create360MobileError1() */


/**
 *
 */
void addToErrorList(NSString* msg,NSError* error,AddErrorActionType action)
{ if( error!=nil )
  { NSLog(@"addToErrorList(msg=%@,error=%@,action=%ld)",msg,error,(long)action);
    
    ErrorDescription* ed = [[ErrorDescription alloc] init];
    
    ed.error     = error;
    ed.timestamp = [NSDate date];
    ed.msg       = msg;
    ed.action    = action;
    
    @synchronized(ed)
    { if( gErrorList==nil )
        gErrorList = [[NSMutableArray alloc] initWithCapacity:128];
      
      [((NSMutableArray*)gErrorList) addObject:ed];
    }
    
    if( action&AddErrorExitApp )
      exit(EXIT_FAILURE);
    
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                     [[NSNotificationCenter defaultCenter] postNotificationName:kErrorListAdded object:ed];
                   });
  } /* of if */
}


/**
 *
 */
void raiseException(NSError* error,NSString* name)
{ if( error )
  { NSString*     name     = NSObjectNotAvailableException;
    NSString*     reason   = [error localizedDescription];
    NSDictionary* userInfo = [error userInfo];
    
    NSException*  exception = [NSException exceptionWithName:name reason:reason userInfo:userInfo];
    
    @throw exception;
  } /* of if */
}
/*======================================END-OF-FILE====================================================================*/
