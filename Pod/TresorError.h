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
extern NSString* const TresorErrorDomain;

enum
{ TresorErrorUnknown               = -1,
  TresorErrorUnexpectedClassInPath = -2,
  TresorErrorUnexpectedObjectClass = -3,
  TresorErrorPathMismatch          = -4,
  TresorErrorPathShouldNotBeNil    = -5,
  TresorErrorPayloadShouldNotBeNil = -6,
  TresorErrorPayloadIsNotDecrypted = -7,
  TresorErrorNoPassword            = -8
};

#define _TRESORERROR(errCode) [[NSError alloc] initWithDomain:TresorErrorDomain code:errCode userInfo:nil]
#endif
/*============================================================================END-OF-FILE============================================================================*/
