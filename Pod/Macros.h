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
 * This is an implementation of RFC2898, which specifies key derivation from
 * a password and a salt value.
 */

#ifndef IVAULTCOMMON_H
#define IVAULTCOMMON_H

#define _LSTR(_str)                   NSLocalizedString(_str, @"")
#define _NSLOG_SELECTOR               NSLog(@"0x%x %@ %@",(int)self,[self class],NSStringFromSelector(_cmd))
#define _NSLOG_FRAME(msg,frame)       NSLog(@"0x%x %@ %@ %@(%f,%f,%f,%f)",(int)self,[self class],NSStringFromSelector(_cmd),msg,frame.origin.x,frame.origin.y,frame.size.width,frame.size.height)
#define _NSLOG(format,...)            NSLog(@"0x%x %@ %@: " format,(int)self,[self class],NSStringFromSelector(_cmd), ##__VA_ARGS__)

#define _NSNULL(a)                    (a!=nil ? a : [NSNull null])

#define _RAD2DEG(x)                   ((x)*180.0/M_PI)
#define _DEG2RAD(x)                   (M_PI*(x)/180.0)

#define _ISIPHONE                     ([[UIDevice currentDevice] userInterfaceIdiom]==UIUserInterfaceIdiomPhone)
#define _ISIPAD                       ([[UIDevice currentDevice] userInterfaceIdiom]==UIUserInterfaceIdiomPad)
#define _ISPORTRAIT                   (UIDeviceOrientationIsPortrait(self.interfaceOrientation))

#endif
