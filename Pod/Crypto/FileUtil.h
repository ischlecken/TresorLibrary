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
#import "TresorAlgorithmInfo.h"

@protocol WipeFileDelegate <NSObject>
-(BOOL) wipeStatus:(int)state pass:(int)pass actualBytes:(int)a fileSize:(int)s;
@end

@interface TresorFileUtil : NSObject

@property (strong, nonatomic,readonly) NSURL*    vaultDirectory;
@property (strong, nonatomic,readonly) NSURL*    templatesDirectory;
@property (strong, nonatomic,readonly) NSURL*    documentsDirectory;
@property (strong, nonatomic,readonly) NSURL*    libraryDirectory;
@property (strong, nonatomic,readonly) NSURL*    cachesDirectory;
@property (strong, nonatomic,readonly) NSURL*    tmpDirectory;

-(BOOL)            deleteFile:(NSString*)fileName didFailWithError:(NSError**)error;
-(BOOL)            deleteFileURL:(NSURL*)fileURL didFailWithError:(NSError**)error;
-(NSString*)       getFullPath:(NSString*)fileName;
-(NSError*)        copyIfNoExists:(NSString*)fileName;
-(BOOL)            wipeFile:(NSString*)fileName pass:(int)pass usingDelegate:(id<WipeFileDelegate>)delegate didFailWithError:(NSError**)error;
-(BOOL)            wipeFile:(NSString*)fileName usingDelegate:(id<WipeFileDelegate>)delegate didFailWithError:(NSError**)error;
-(NSData*)         hash:(NSString*)fileName withAlgorithm:(TresorAlgorithmInfo*)algorithm error:(NSError **)outError;
+(TresorFileUtil*) sharedInstance;

@end
