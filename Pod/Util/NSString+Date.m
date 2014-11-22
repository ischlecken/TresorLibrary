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
#import "NSString+Date.h"

@implementation NSString(TresorUtilDate)


/**
 *
 */
+(NSString*) stringISODate
{ return [NSString stringISODateForDate:[NSDate date]]; }

/**
 *
 */
+(NSString*) stringISOTimestamp
{ return [NSString stringISOTimestampForDate:[NSDate date]]; }

/**
 *
 */
+(NSString*) stringISODateForDate:(NSDate*)date
{ static NSDateFormatter* sformatter = nil;
  
  if( sformatter==nil )
  { sformatter = [[NSDateFormatter alloc] init];
    
    [sformatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [sformatter setDateFormat:@"yyyy'-'MM'-'dd"];
    [sformatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
  } /* of if */
  
  return [sformatter stringFromDate:date];
}

/**
 *
 */
+(NSString*) stringISOTimestampForDate:(NSDate*)date
{ static NSDateFormatter* sformatter = nil;
  
  if( sformatter==nil )
  { sformatter = [[NSDateFormatter alloc] init];
    
    [sformatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [sformatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss"];
    [sformatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
  } /* of if */
  
  return [sformatter stringFromDate:date];
}


/**
 *
 */
+(NSString*) stringRFC3339TimestampForDate:(NSDate*)date
{ static NSDateFormatter* sformatter = nil;
  
  if( sformatter==nil )
  { sformatter = [[NSDateFormatter alloc] init];
    
    [sformatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [sformatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [sformatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
  } /* of if */
  
  return [sformatter stringFromDate:date];
}

/**
 *
 */
+(NSDate*) isoTimestampValue:(NSString*)ts
{ static NSDateFormatter* sformatter = nil;
  
  if( sformatter==nil )
  { sformatter = [[NSDateFormatter alloc] init];
    
    [sformatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [sformatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss"];
    [sformatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
  } /* of if */
  
  NSDate* result = [sformatter dateFromString:ts];
  
  return result;
}


/**
 *
 */
+(NSDate*) rfc3339TimestampValue:(NSString*)ts
{ static NSDateFormatter* sformatter = nil;
  
  if( sformatter==nil )
  { sformatter = [[NSDateFormatter alloc] init];
    
    [sformatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [sformatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [sformatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
  } /* of if */
  
  NSDate* result = [sformatter dateFromString:ts];
  
  return result;
}


/**
 *
 */
+(NSDate*) timestampValue:(NSString*)ts
{ static NSDateFormatter* sformatter = nil;
  
  if( sformatter==nil )
  { sformatter = [[NSDateFormatter alloc] init];
    
    [sformatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [sformatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss"];
    [sformatter setTimeZone:[NSTimeZone localTimeZone]];
  } /* of if */
  
  NSDate* result = [sformatter dateFromString:ts];
  
  return result;
}

@end
/*=================================================END-OF-FILE============================================================================*/
