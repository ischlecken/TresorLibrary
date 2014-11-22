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

#ifndef CRYPTO_H
#define CRYPTO_H

#include <limits.h>
#include <machine/endian.h>

#ifndef BRG_UI8
#  define BRG_UI8
#  if UCHAR_MAX == 255u
     typedef unsigned char uint_8t;
#  else
#    error Please define uint_8t as an 8-bit unsigned integer type in brg_types.h
#  endif
#endif

#ifndef BRG_UI16
#  define BRG_UI16
#  if USHRT_MAX == 65535u
     typedef unsigned short uint_16t;
#  else
#    error Please define uint_16t as a 16-bit unsigned short type in brg_types.h
#  endif
#endif

#ifndef BRG_UI32
#  define BRG_UI32
#  if UINT_MAX == 4294967295u
#    define li_32(h) 0x##h##u
     typedef unsigned int uint_32t;
#  elif ULONG_MAX == 4294967295u
#    define li_32(h) 0x##h##ul
     typedef unsigned long uint_32t;
#  else
#    error Please define uint_32t as a 32-bit unsigned integer type in brg_types.h
#  endif
#endif

#ifndef BRG_UI64
#  if defined( UINT_MAX ) && UINT_MAX > 4294967295u
#    if UINT_MAX == 18446744073709551615u
#      define BRG_UI64
#      define li_64(h) 0x##h##u
       typedef unsigned int uint_64t;
#    endif
#  elif defined( ULONG_MAX ) && ULONG_MAX > 4294967295u
#    if ULONG_MAX == 18446744073709551615ul
#      define BRG_UI64
#      define li_64(h) 0x##h##ul
       typedef unsigned long uint_64t;
#    endif
#  elif defined( ULLONG_MAX ) && ULLONG_MAX > 4294967295u
#    if ULLONG_MAX == 18446744073709551615ull
#      define BRG_UI64
#      define li_64(h) 0x##h##ull
       typedef unsigned long long uint_64t;
#    endif
#  elif defined( ULONG_LONG_MAX ) && ULONG_LONG_MAX > 4294967295u
#    if ULONG_LONG_MAX == 18446744073709551615ull
#      define BRG_UI64
#      define li_64(h) 0x##h##ull
       typedef unsigned long long uint_64t;
#    endif
#  endif
#endif

#if !defined( BRG_UI64 )
#  error Please define uint_64t as an unsigned 64 bit type in brg_types.h
#endif


/*  These defines are used to declare buffers in a way that allows
    faster operations on longer variables to be used.  In all these
    defines 'size' must be a power of 2 and >= 8

    dec_unit_type(size,x)       declares a variable 'x' of length 
                                'size' bits

    dec_bufr_type(size,bsize,x) declares a buffer 'x' of length 'bsize' 
                                bytes defined as an array of variables
                                each of 'size' bits (bsize must be a 
                                multiple of size / 8)

    ptr_cast(x,size)            casts a pointer to a pointer to a 
                                varaiable of length 'size' bits
*/

#define ui_type(size)               uint_##size##t
#define dec_unit_type(size,x)       typedef ui_type(size) x
#define dec_bufr_type(size,bsize,x) typedef ui_type(size) x[bsize / (size >> 3)]
#define ptr_cast(x,size)            ((ui_type(size)*)(x))


#define IS_BIG_ENDIAN      4321 /* byte 0 is most significant (mc68k) */
#define IS_LITTLE_ENDIAN   1234 /* byte 0 is least significant (i386) */

/* Now attempt to set the define for platform byte order using any  */
/* of the four forms SYMBOL, _SYMBOL, __SYMBOL & __SYMBOL__, which  */
/* seem to encompass most endian symbol definitions                 */

#if defined( BIG_ENDIAN ) && defined( LITTLE_ENDIAN )
#  if defined( BYTE_ORDER ) && BYTE_ORDER == BIG_ENDIAN
#    define PLATFORM_BYTE_ORDER IS_BIG_ENDIAN
#  elif defined( BYTE_ORDER ) && BYTE_ORDER == LITTLE_ENDIAN
#    define PLATFORM_BYTE_ORDER IS_LITTLE_ENDIAN
#  endif
#elif defined( BIG_ENDIAN )
#  define PLATFORM_BYTE_ORDER IS_BIG_ENDIAN
#elif defined( LITTLE_ENDIAN )
#  define PLATFORM_BYTE_ORDER IS_LITTLE_ENDIAN
#endif

#if defined( _BIG_ENDIAN ) && defined( _LITTLE_ENDIAN )
#  if defined( _BYTE_ORDER ) && _BYTE_ORDER == _BIG_ENDIAN
#    define PLATFORM_BYTE_ORDER IS_BIG_ENDIAN
#  elif defined( _BYTE_ORDER ) && _BYTE_ORDER == _LITTLE_ENDIAN
#    define PLATFORM_BYTE_ORDER IS_LITTLE_ENDIAN
#  endif
#elif defined( _BIG_ENDIAN )
#  define PLATFORM_BYTE_ORDER IS_BIG_ENDIAN
#elif defined( _LITTLE_ENDIAN )
#  define PLATFORM_BYTE_ORDER IS_LITTLE_ENDIAN
#endif

#if defined( __BIG_ENDIAN ) && defined( __LITTLE_ENDIAN )
#  if defined( __BYTE_ORDER ) && __BYTE_ORDER == __BIG_ENDIAN
#    define PLATFORM_BYTE_ORDER IS_BIG_ENDIAN
#  elif defined( __BYTE_ORDER ) && __BYTE_ORDER == __LITTLE_ENDIAN
#    define PLATFORM_BYTE_ORDER IS_LITTLE_ENDIAN
#  endif
#elif defined( __BIG_ENDIAN )
#  define PLATFORM_BYTE_ORDER IS_BIG_ENDIAN
#elif defined( __LITTLE_ENDIAN )
#  define PLATFORM_BYTE_ORDER IS_LITTLE_ENDIAN
#endif

#if defined( __BIG_ENDIAN__ ) && defined( __LITTLE_ENDIAN__ )
#  if defined( __BYTE_ORDER__ ) && __BYTE_ORDER__ == __BIG_ENDIAN__
#    define PLATFORM_BYTE_ORDER IS_BIG_ENDIAN
#  elif defined( __BYTE_ORDER__ ) && __BYTE_ORDER__ == __LITTLE_ENDIAN__
#    define PLATFORM_BYTE_ORDER IS_LITTLE_ENDIAN
#  endif
#elif defined( __BIG_ENDIAN__ )
#  define PLATFORM_BYTE_ORDER IS_BIG_ENDIAN
#elif defined( __LITTLE_ENDIAN__ )
#  define PLATFORM_BYTE_ORDER IS_LITTLE_ENDIAN
#endif

/*  if the platform byte order could not be determined, then try to */
/*  set this define using common machine defines                    */
#if !defined(PLATFORM_BYTE_ORDER)
#error Please edit lines 126 or 128 in brg_endian.h to set the platform byte order
#endif

#define ARRAYSIZE(x) ( sizeof(x)/sizeof(x[0]) )

#define SUCCESS(x) { int result = x; if( result!=EXIT_SUCCESS ) return result; }

#define MD5_DIGEST_SIZE     16
#define SHA1_DIGEST_SIZE    20
#define SHA224_DIGEST_SIZE  28
#define SHA256_DIGEST_SIZE  32
#define SHA384_DIGEST_SIZE  48
#define SHA512_DIGEST_SIZE  64

#define AES_BLOCK_SIZE      16
#define AES128_KEY_SIZE     16
#define AES192_KEY_SIZE     24
#define AES256_KEY_SIZE     32

#define CAST_BLOCK_SIZE      8
#define CAST16_KEY_SIZE     16

#define BLOWFISH_BLOCK_SIZE  8
#define BLOWFISH56_KEY_SIZE 56

#define TWOFISH_BLOCK_SIZE       16
#define TWOFISH_KEY_SIZE         32

#endif
/*============================================================================END-OF-FILE============================================================================*/

