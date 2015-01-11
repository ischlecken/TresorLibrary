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
 *
 * Copyright (c) 2014 ischlecken.
 */
#import "Payload.h"
#import "Key.h"

@protocol DecryptedPayloadKeyPromiseDelegate <NSObject>
-(PMKPromise*) decryptedPayloadKeyPromiseForPayload:(Payload*)payload;
@end

@interface CryptoService: NSObject
@property(weak) id<DecryptedPayloadKeyPromiseDelegate> delegate;

+(CryptoService*) sharedInstance;

+(NSData*)        encryptPayload:(id)payloadObject usingKey:(Key*)keyForPayload andDecryptedKey:(NSData*)decryptedKey andError:(NSError**)error;

-(PMKPromise*)    decryptPayload:(Payload*)payload;
-(PMKPromise*)    encryptPayload:(Payload*)payload forObject:(id)object;
@end

