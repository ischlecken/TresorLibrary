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
#import <sys/stat.h>
#include <CommonCrypto/CommonDigest.h>
#import "Macros.h"
#import "FileUtil.h"
#import "buffer.h"
#import "TresorError.h"
#include "md5.h"
#include "sha1.h"

#define COMMON_CHECK_ERROR( condition,errCode ) \
if( condition ) \
{ result = errCode; \
  goto cleanUp; \
}

@interface TresorFileUtil ()
{ NSFileManager* _fileManager;
}
@end

@implementation TresorFileUtil

/**
 *
 */
-(id) init
{ self = [super init];
  
  if( self )
  { _fileManager        = [NSFileManager defaultManager];
    _vaultDirectory     = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"vault"];
    _templatesDirectory = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"templates"];
    _documentsDirectory = [[NSURL alloc] initFileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] isDirectory:YES];
    _cachesDirectory    = [[NSURL alloc] initFileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory  , NSUserDomainMask, YES) objectAtIndex:0] isDirectory:YES];
    _libraryDirectory   = [[NSURL alloc] initFileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory , NSUserDomainMask, YES) objectAtIndex:0] isDirectory:YES];
    _tmpDirectory       = [[NSURL alloc] initFileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
  } /* of if */
  
  return self;
}


/**
 *
 */
-(NSString*) getFullPath:(NSString*)fileName
{ NSString* result = nil;

  if( fileName!=nil )
    result = [[self.documentsDirectory path] stringByAppendingPathComponent:fileName];

  return result;
}


/**
 *
 */
-(BOOL) deleteFileURL:(NSURL*)fileURL didFailWithError:(NSError**)error
{ BOOL result    = FALSE;
  NSString* path = [fileURL path];
  
  if( [_fileManager fileExistsAtPath:path] )
  { NSLog(@"remove fileURL %@",path);
    
    result = [_fileManager removeItemAtPath:path error:error];
  } /* of if */
  
  return result;
}

/**
 *
 */
-(BOOL) deleteFile:(NSString*)fileName didFailWithError:(NSError**)error
{ NSString* path   = [self getFullPath:fileName];
  BOOL      result = FALSE;
  
  if( [_fileManager fileExistsAtPath:path] )
  { NSLog(@"remove file %@",path);
    
    result = [_fileManager removeItemAtPath:path error:error];
  } /* of if */
  
  return result;
}

/**
 *
 */
-(NSData*) hash:(NSString*)fileName withAlgorithm:(TresorAlgorithmInfo*)algorithm error:(NSError **)outError
{ NSData*  result          = nil;
  int      internalErrCode = EXIT_SUCCESS;
  BufferT* digest          = NULL;
  int      bytesRead       = 0;
  int      fd              = 0;
  BufferT* buffer          = buffer_alloc(1024, NULL);
  TRESOR_CHECKERROR( buffer==NULL,TresorErrorHash,@"buffer not allocated",0 );

  fd              = open([fileName UTF8String],O_RDONLY);
  TRESOR_CHECKERROR( fd<0,TresorErrorHash,@"file open failed",errno );
  
  switch( algorithm.type )
  { case tresorAlgorithmMD5:
    case tresorAlgorithmMD5CC:
      { digest = buffer_alloc((unsigned)algorithm.blockSize, NULL);
        TRESOR_CHECKERROR( digest==NULL,TresorErrorHash,@"buffer not allocated",0 );
        
        TRESOR_CHECKERROR( internalErrCode!=EXIT_SUCCESS,TresorErrorHash,@"CommonCryptoMD5 failed",internalErrCode );
      }
      break;
    case tresorAlgorithmSHA1CC:
      { digest = buffer_alloc((unsigned)algorithm.blockSize, NULL);
        TRESOR_CHECKERROR( digest==NULL,TresorErrorHash,@"buffer not allocated",0 );
        
        CC_SHA1_CTX ctx;
        CC_SHA1_Init(&ctx);
        
        while( (bytesRead=(unsigned int)read(fd,buffer->data,buffer->length))>0 )
        { BufferT in;
          buffer_init(&in,bytesRead, buffer->data);
          
          CC_SHA1_Update(&ctx,in.data,in.length);
        } /* of while */
        TRESOR_CHECKERROR( bytesRead==-1,TresorErrorHash,@"read failed",errno );
        
        CC_SHA1_Final(digest->data, &ctx);
      }
      break;
    case tresorAlgorithmSHA1:
      { digest = buffer_alloc((unsigned)algorithm.blockSize, NULL);
        TRESOR_CHECKERROR( digest==NULL,TresorErrorHash,@"buffer not allocated",0 );
      
        SHA1ContextT ctx[1];
        
        internalErrCode = sha1_begin(ctx);
        TRESOR_CHECKERROR( internalErrCode!=SHA1_OK,TresorErrorHash,@"sha1_begin failed",internalErrCode );
        
        while( (bytesRead=(int)read(fd,buffer->data,buffer->length))>0 )
        { BufferT in;
          buffer_init(&in,bytesRead, buffer->data);
          
          internalErrCode = sha1_hash(ctx,&in);
          TRESOR_CHECKERROR( internalErrCode!=SHA1_OK,TresorErrorHash,@"sha1_hash failed",internalErrCode );
        } /* of while */
        TRESOR_CHECKERROR( bytesRead==-1,TresorErrorHash,@"read failed",errno );
        
        internalErrCode = sha1_end(ctx,digest);
        TRESOR_CHECKERROR( internalErrCode!=SHA1_OK,TresorErrorHash,@"sha1_end failed",internalErrCode );
        
        internalErrCode = buffer_check(digest);
        TRESOR_CHECKERROR( internalErrCode!=BUFFER_OK,TresorErrorHash,@"buffer_check failed",internalErrCode );
      }
      break;
    case tresorAlgorithmSHA256:
    case tresorAlgorithmSHA256CC:
      { digest = buffer_alloc((unsigned)algorithm.blockSize, NULL);
        TRESOR_CHECKERROR( digest==NULL,TresorErrorHash,@"buffer not allocated",0 );
        
        TRESOR_CHECKERROR( internalErrCode!=EXIT_SUCCESS,TresorErrorHash,@"CommonCryptoSHA256 failed",internalErrCode );
      }
      break;
    case tresorAlgorithmSHA512:
    case tresorAlgorithmSHA512CC:
      { digest = buffer_alloc((unsigned)algorithm.blockSize, NULL);
        TRESOR_CHECKERROR( digest==NULL,TresorErrorHash,@"buffer not allocated",0 );
      
        TRESOR_CHECKERROR( internalErrCode!=EXIT_SUCCESS,TresorErrorHash,@"CommonCryptoSHA512 failed",internalErrCode );
      }
      break;
    default:
      break;
  } // of switch
  
  if( digest!=NULL )
    result = [[NSData alloc] initWithBytes:digest->data length:digest->length];
  
cleanUp:
  if( fd>0 )
    close(fd);
  
  free(digest);
  free(buffer);
  
  return result;
} /* of hashWithAlgorithm: */

/**
 *
 */
-(BOOL) wipeFile:(NSString*)fileName pass:(int)pass usingDelegate:(id<WipeFileDelegate>)delegate didFailWithError:(NSError**)error
{ int           fd     = open([fileName UTF8String],O_RDWR);
  unsigned char buffer[1024];
  struct stat   s;
  int           bw = 0;
  
  if( fd<0 )
    return FALSE;
  
  if( fstat(fd, &s)!=0 )
    return FALSE;
  
  int nw = (int)s.st_size;
  
  switch( pass )
  {
    case 1:
      memset(buffer, 0x55, sizeof(buffer));
      break;
    case 2:
      memset(buffer, 0xAA, sizeof(buffer));
      break;
    case 3:
      { NSData* r = [[NSData alloc] initWithRandom:sizeof(buffer)];
      
        [r getBytes:buffer length:sizeof(buffer)];
      }
      break;
    default:
      break;
  }

  if( delegate )
    [delegate wipeStatus:0 pass:pass actualBytes:0 fileSize:(int)s.st_size];
  
  int bytesWritten = 0;
  
  for( ;nw;nw -=bw )
  { bw = (int)write(fd, buffer, MIN(nw, sizeof(buffer)));
    
    if( bw!=-1 )
      bytesWritten += bw;
    
    if( delegate && ![delegate wipeStatus:1 pass:pass actualBytes:bytesWritten fileSize:(int)s.st_size] )
      break;
    
    if( bw==-1 )
      break;
  } /* of for */
  
  if( delegate )
    [delegate wipeStatus:2 pass:pass actualBytes:(int)s.st_size fileSize:(int)s.st_size];
  
  if( bw==-1 )
    return FALSE;
  
  if( close(fd)==-1 )
    return FALSE;
  
  return TRUE;
}

/**
 *
 */
-(BOOL) wipeFile:(NSString*)fileName usingDelegate:(id<WipeFileDelegate>)delegate didFailWithError:(NSError**)error
{ _NSLOG(@"fileName=%@",fileName);
  
  for( int pass=1;pass<=3;pass++ )
    if( ![self wipeFile:fileName pass:pass usingDelegate:delegate didFailWithError:error] )
      return FALSE;
  
  return TRUE;
}


/**
 *
 */
-(NSError*) copyIfNoExists:(NSString*)fileName
{ NSURL*         f0          = [self.templatesDirectory URLByAppendingPathComponent:fileName];
  NSURL*         f1          = [self.documentsDirectory URLByAppendingPathComponent:fileName];
  NSError*       error       = nil;
  
  if( ![_fileManager fileExistsAtPath:[f1 path]] )
  { _NSLOG(@"copy template file %@...",fileName);
    
    [_fileManager copyItemAtURL:f0 toURL:f1 error:&error];
  } /* of if */
  
  return error;
}

/**
 *
 */
+(TresorFileUtil*) sharedInstance
{ static TresorFileUtil* sharedInstance = nil;
  static dispatch_once_t onceToken;
  
  dispatch_once(&onceToken, ^{sharedInstance = [[TresorFileUtil alloc] init]; });
  
  return sharedInstance;
}
@end
