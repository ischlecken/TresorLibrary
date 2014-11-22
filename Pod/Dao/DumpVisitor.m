//  Created by Feldmaus on 19.07.14.
//  Copyright (c) 2014 ischlecken. All rights reserved.
//
#import "DumpVisitor.h"
#import "Vault.h"
#import "Commit.h"
#import "Payload.h"
#import "PayloadItemList.h"
#import "PayloadItem.h"

@interface DumpVisitor ()
@property NSUInteger indentLevel;
@end

@implementation DumpVisitor

/**
 *
 */
-(NSString*) indent
{ NSMutableString* result = [[NSMutableString alloc] initWithCapacity:10];
  
  for( NSUInteger i=0;i<self.indentLevel;i++ )
    [result appendString:@"  "];

  return  result;
}

/**
 *
 */
-(void) visitVault:(Vault*)vault andState:(NSUInteger)state
{ if( state==0 )
    NSLog(@"%@%@",self.indent,vault);
  else
    NSLog(@"%@-------Vault-------",self.indent);
}

/**
 *
 */
-(void) visitCommit:(Commit*)commit andState:(NSUInteger)state
{ if( state==0 )
    NSLog(@"%@%@",self.indent,commit);
  else
    NSLog(@"%@-------Commit-------",self.indent);
}

/**
 *
 */
-(void) visitPayload:(Payload*)payload andState:(NSUInteger)state
{ if( state==0 )
    NSLog(@"%@%@",self.indent,payload);
  else
    NSLog(@"%@-------Payload-------",self.indent);
}

/**
 *
 */
-(void) visitPayloadItemList:(PayloadItemList*)payloadItemList andState:(NSUInteger)state
{ if( state==0 )
    NSLog(@"%@%@",self.indent,payloadItemList);
  
  if( state==0 )
    self.indentLevel++;
  else
    self.indentLevel--;

  if( state==1 ) 
    NSLog(@"%@-------PayloadItemList-------",self.indent);
}

/**
 *
 */
-(void) visitPayloadItem:(PayloadItem*)payloadItem andState:(NSUInteger)state
{ if( state==0 )
    NSLog(@"%@%@",self.indent,payloadItem);

  if( state==0 )
    self.indentLevel++;
  else
    self.indentLevel--;

  if( state==1 )
    NSLog(@"%@-------PayloadItem-------",self.indent);
}


@end
