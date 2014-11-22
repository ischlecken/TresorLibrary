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
#import "PromiseKit.h"

/**
 Executes @param block via `dispatch_after` after delay.
 @see dispatch_promise
 */
PMKPromise *dispatch_promise_after(dispatch_time_t after, id (^block)());

/**
 Executes @param block via `dispatch_after` on the specified queue after delay.
 @see dispatch_promise
 */
PMKPromise *dispatch_promise_on_after(dispatch_queue_t queue,dispatch_time_t after, id (^block)(void) );


@interface PMKPromise(Tresor)

/**
 Executes Promise action while condition returns true
 
 @return A new `Promise`
 */
+(PMKPromise*) whileWithCondition:(BOOL (^)(void))condition andAction:(PMKPromise* (^)(void))action;

@end
