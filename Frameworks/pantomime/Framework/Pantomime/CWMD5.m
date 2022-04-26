/*
**  CWMD5.m
**
**  Copyright (c) 2002-2007 Ludovic Marcotte
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**
**  This library is free software; you can redistribute it and/or
**  modify it under the terms of the GNU Lesser General Public
**  License as published by the Free Software Foundation; either
**  version 2.1 of the License, or (at your option) any later version.
**  
**  This library is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
**  Lesser General Public License for more details.
**  
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#import <Pantomime/CWMD5.h>
#import <Pantomime/CWConstants.h>
#import <Pantomime/NSData+Extensions.h>

#include <string.h>
#include <sys/types.h>  // For byte order on Mac OS X.

#define word32 unsigned int

struct MD5Context {
  word32 buf[4];
  word32 bits[2];
  unsigned char in[64];
};

void MD5Init(struct MD5Context *context);
void MD5Update(struct MD5Context *context, unsigned char const *buf,
               unsigned len);
void MD5Final(unsigned char digest[16], struct MD5Context *context);
void MD5Transform(word32 buf[4], word32 const in[16]);

void md5_hmac(unsigned char *digest, const unsigned char* text, int text_len, const unsigned char* key, int key_len);

//
//
//
@implementation CWMD5

- (id) initWithData: (NSData *) theData
{
  self = [super init];
  if (self)
    {
      _data = RETAIN(theData);
      _has_computed_digest = NO;
    }
  return self;
}


//
//
//
- (void) dealloc
{
  RELEASE(_data);
  [super dealloc];
}


//
//
//
- (void) computeDigest
{
  struct MD5Context ctx;
  unsigned char *bytes;
  unsigned len;
  
  // If we already have computed the digest
  if (_has_computed_digest)
    {
      return;
    }

  bytes = (unsigned char *)[_data bytes];
  len = [_data length];

  MD5Init(&ctx);
  MD5Update(&ctx, bytes, len);
  MD5Final(_digest, &ctx);

  _has_computed_digest = YES;
}


//
//
//
- (NSData *) digest
{
  if (!_has_computed_digest)
    {
      return nil;
    }
  
  return [NSData dataWithBytes: _digest  length: 16];
}


//
//
//
- (NSString *) digestAsString
{
  if (!_has_computed_digest)
    {
      return nil;
    }
  else
    {
      NSMutableString *aMutableString;
      int i;

      aMutableString = [[NSMutableString alloc] init];
      
      for (i = 0; i < 16; i++)
	{
	  [aMutableString appendFormat: @"%02x", (unsigned int)_digest[i]];
	}
      
      return AUTORELEASE(aMutableString);
    }
}


//
// The challenge phrase used is the one that has been initialized
// with this object. The digest MUST have been computed first.
//
- (NSString *) hmacAsStringUsingPassword: (NSString *) thePassword
{
  if (!_has_computed_digest)
    {
      return nil;
    }
  else
    {
      NSMutableString *aMutableString;
      unsigned char result[16];
      unsigned char *s;
      int i;

      s = (unsigned char*)[_data cString];
      md5_hmac(result, s, strlen((char*)s), (unsigned char*)[thePassword cString], [thePassword length]);
      
      aMutableString = [[NSMutableString alloc] init];

      for (i = 0; i < 16; i++)
	{
	  [aMutableString appendFormat: @"%02x", (unsigned int)result[i]];
	}
      
      return AUTORELEASE(aMutableString);
    }
}

@end


/*
 * This code implements the MD5 message-digest algorithm.
 * The algorithm is due to Ron Rivest.  This code was
 * written by Colin Plumb in 1993, no copyright is claimed.
 * This code is in the public domain; do with it what you wish.
 *
 * Equivalent code is available from RSA Data Security, Inc.
 * This code has been tested against that, and is equivalent,
 * except that you don't need to include two pages of legalese
 * with every copy.
 *
 * To compute the message digest of a chunk of bytes, declare an
 * MD5Context structure, pass it to MD5Init, call MD5Update as
 * needed on buffers full of bytes, and then call MD5Final, which
 * will fill a supplied 16-byte array with the digest.
 */
#if BYTE_ORDER == BIG_ENDIAN
static void byteReverse(unsigned char *buf, unsigned longs);

/*
 * Note: this code is harmless on little-endian machines.
 */
static void byteReverse(unsigned char *buf, unsigned longs)
{
  word32 t;
  do {
    t = (word32) ((unsigned) buf[3] << 8 | buf[2]) << 16 |
      ((unsigned) buf[1] << 8 | buf[0]);
    *(word32 *) buf = t;
    buf += 4;
  } while (--longs);
}
#elif BYTE_ORDER == LITTLE_ENDIAN
#define byteReverse(buf, len)	/* Nothing */
#else
#warning BROKEN - Compiler byte order check failed for some reason. The MD5 code might not work properly.
#endif

/*
 * Start MD5 accumulation.  Set bit count to 0 and buffer to mysterious
 * initialization constants.
 */
void MD5Init(struct MD5Context *ctx)
{
  ctx->buf[0] = 0x67452301;
  ctx->buf[1] = 0xefcdab89;
  ctx->buf[2] = 0x98badcfe;
  ctx->buf[3] = 0x10325476;
  
  ctx->bits[0] = 0;
  ctx->bits[1] = 0;
}

/*
 * Update context to reflect the concatenation of another buffer full
 * of bytes.
 */
void MD5Update(struct MD5Context *ctx, unsigned char const *buf, unsigned len)
{
  register word32 t;
  
  /* Update bitcount */
  t = ctx->bits[0];
  if ((ctx->bits[0] = t + ((word32) len << 3)) < t)
    ctx->bits[1]++;		/* Carry from low to high */
  ctx->bits[1] += len >> 29;
  
  t = (t >> 3) & 0x3f;	/* Bytes already in shsInfo->data */
  
  /* Handle any leading odd-sized chunks */
  if (t) {
    unsigned char *p = (unsigned char *) ctx->in + t;
    
    t = 64 - t;
    if (len < t) {
      memmove(p, buf, len);
      return;
    }
    memmove(p, buf, t);
    byteReverse(ctx->in, 16);
    MD5Transform(ctx->buf, (word32 *) ctx->in);
    buf += t;
    len -= t;
  }
  /* Process data in 64-byte chunks */
  
  while (len >= 64) {
    memmove(ctx->in, buf, 64);
    byteReverse(ctx->in, 16);
    MD5Transform(ctx->buf, (word32 *) ctx->in);
    buf += 64;
    len -= 64;
  }
  
  /* Handle any remaining bytes of data. */
  memmove(ctx->in, buf, len);
}

/*
 * Final wrapup - pad to 64-byte boundary with the bit pattern 
 * 1 0* (64-bit count of bits processed, MSB-first)
 */
void MD5Final(unsigned char digest[16], struct MD5Context *ctx)
{
  unsigned int count;
  unsigned char *p;
  
  /* Compute number of bytes mod 64 */
  count = (ctx->bits[0] >> 3) & 0x3F;
  
  /* Set the first char of padding to 0x80.  This is safe since there is
     always at least one byte free */
  p = ctx->in + count;
  *p++ = 0x80;
  
  /* Bytes of padding needed to make 64 bytes */
  count = 64 - 1 - count;
  
  /* Pad out to 56 mod 64 */
  if (count < 8) {
    /* Two lots of padding:  Pad the first block to 64 bytes */
    memset(p, 0, count);
    byteReverse(ctx->in, 16);
    MD5Transform(ctx->buf, (word32 *) ctx->in);
    
    /* Now fill the next block with 56 bytes */
    memset(ctx->in, 0, 56);
  } else {
    /* Pad block to 56 bytes */
    memset(p, 0, count - 8);
  }
  byteReverse(ctx->in, 14);
  
  /* Append length in bits and transform */
  ((word32 *) ctx->in)[14] = ctx->bits[0];
  ((word32 *) ctx->in)[15] = ctx->bits[1];
  
  MD5Transform(ctx->buf, (word32 *) ctx->in);
  byteReverse((unsigned char *) ctx->buf, 4);
  memmove(digest, ctx->buf, 16);
  memset(&ctx, 0, sizeof(ctx));	/* In case it's sensitive */
}

/* The four core functions - F1 is optimized somewhat */

/* #define F1(x, y, z) (x & y | ~x & z) */
#define F1(x, y, z) (z ^ (x & (y ^ z)))
#define F2(x, y, z) F1(z, x, y)
#define F3(x, y, z) (x ^ y ^ z)
#define F4(x, y, z) (y ^ (x | ~z))

/* This is the central step in the MD5 algorithm. */
#define MD5STEP(f, w, x, y, z, data, s) \
	( w += f(x, y, z) + data,  w = w<<s | w>>(32-s),  w += x )

/*
 * The core of the MD5 algorithm, this alters an existing MD5 hash to
 * reflect the addition of 16 longwords of new data.  MD5Update blocks
 * the data and converts bytes into longwords for this routine.
 */
void MD5Transform(word32 buf[4], word32 const in[16])
{
  register word32 a, b, c, d;
  
  a = buf[0];
  b = buf[1];
  c = buf[2];
  d = buf[3];
  
  MD5STEP(F1, a, b, c, d, in[0] + 0xd76aa478, 7);
  MD5STEP(F1, d, a, b, c, in[1] + 0xe8c7b756, 12);
  MD5STEP(F1, c, d, a, b, in[2] + 0x242070db, 17);
  MD5STEP(F1, b, c, d, a, in[3] + 0xc1bdceee, 22);
  MD5STEP(F1, a, b, c, d, in[4] + 0xf57c0faf, 7);
  MD5STEP(F1, d, a, b, c, in[5] + 0x4787c62a, 12);
  MD5STEP(F1, c, d, a, b, in[6] + 0xa8304613, 17);
  MD5STEP(F1, b, c, d, a, in[7] + 0xfd469501, 22);
  MD5STEP(F1, a, b, c, d, in[8] + 0x698098d8, 7);
  MD5STEP(F1, d, a, b, c, in[9] + 0x8b44f7af, 12);
  MD5STEP(F1, c, d, a, b, in[10] + 0xffff5bb1, 17);
  MD5STEP(F1, b, c, d, a, in[11] + 0x895cd7be, 22);
  MD5STEP(F1, a, b, c, d, in[12] + 0x6b901122, 7);
  MD5STEP(F1, d, a, b, c, in[13] + 0xfd987193, 12);
  MD5STEP(F1, c, d, a, b, in[14] + 0xa679438e, 17);
  MD5STEP(F1, b, c, d, a, in[15] + 0x49b40821, 22);
  
  MD5STEP(F2, a, b, c, d, in[1] + 0xf61e2562, 5);
  MD5STEP(F2, d, a, b, c, in[6] + 0xc040b340, 9);
  MD5STEP(F2, c, d, a, b, in[11] + 0x265e5a51, 14);
  MD5STEP(F2, b, c, d, a, in[0] + 0xe9b6c7aa, 20);
  MD5STEP(F2, a, b, c, d, in[5] + 0xd62f105d, 5);
  MD5STEP(F2, d, a, b, c, in[10] + 0x02441453, 9);
  MD5STEP(F2, c, d, a, b, in[15] + 0xd8a1e681, 14);
  MD5STEP(F2, b, c, d, a, in[4] + 0xe7d3fbc8, 20);
  MD5STEP(F2, a, b, c, d, in[9] + 0x21e1cde6, 5);
  MD5STEP(F2, d, a, b, c, in[14] + 0xc33707d6, 9);
  MD5STEP(F2, c, d, a, b, in[3] + 0xf4d50d87, 14);
  MD5STEP(F2, b, c, d, a, in[8] + 0x455a14ed, 20);
  MD5STEP(F2, a, b, c, d, in[13] + 0xa9e3e905, 5);
  MD5STEP(F2, d, a, b, c, in[2] + 0xfcefa3f8, 9);
  MD5STEP(F2, c, d, a, b, in[7] + 0x676f02d9, 14);
  MD5STEP(F2, b, c, d, a, in[12] + 0x8d2a4c8a, 20);
  
  MD5STEP(F3, a, b, c, d, in[5] + 0xfffa3942, 4);
  MD5STEP(F3, d, a, b, c, in[8] + 0x8771f681, 11);
  MD5STEP(F3, c, d, a, b, in[11] + 0x6d9d6122, 16);
  MD5STEP(F3, b, c, d, a, in[14] + 0xfde5380c, 23);
  MD5STEP(F3, a, b, c, d, in[1] + 0xa4beea44, 4);
  MD5STEP(F3, d, a, b, c, in[4] + 0x4bdecfa9, 11);
  MD5STEP(F3, c, d, a, b, in[7] + 0xf6bb4b60, 16);
  MD5STEP(F3, b, c, d, a, in[10] + 0xbebfbc70, 23);
  MD5STEP(F3, a, b, c, d, in[13] + 0x289b7ec6, 4);
  MD5STEP(F3, d, a, b, c, in[0] + 0xeaa127fa, 11);
  MD5STEP(F3, c, d, a, b, in[3] + 0xd4ef3085, 16);
  MD5STEP(F3, b, c, d, a, in[6] + 0x04881d05, 23);
  MD5STEP(F3, a, b, c, d, in[9] + 0xd9d4d039, 4);
  MD5STEP(F3, d, a, b, c, in[12] + 0xe6db99e5, 11);
  MD5STEP(F3, c, d, a, b, in[15] + 0x1fa27cf8, 16);
  MD5STEP(F3, b, c, d, a, in[2] + 0xc4ac5665, 23);
  
  MD5STEP(F4, a, b, c, d, in[0] + 0xf4292244, 6);
  MD5STEP(F4, d, a, b, c, in[7] + 0x432aff97, 10);
  MD5STEP(F4, c, d, a, b, in[14] + 0xab9423a7, 15);
  MD5STEP(F4, b, c, d, a, in[5] + 0xfc93a039, 21);
  MD5STEP(F4, a, b, c, d, in[12] + 0x655b59c3, 6);
  MD5STEP(F4, d, a, b, c, in[3] + 0x8f0ccc92, 10);
  MD5STEP(F4, c, d, a, b, in[10] + 0xffeff47d, 15);
  MD5STEP(F4, b, c, d, a, in[1] + 0x85845dd1, 21);
  MD5STEP(F4, a, b, c, d, in[8] + 0x6fa87e4f, 6);
  MD5STEP(F4, d, a, b, c, in[15] + 0xfe2ce6e0, 10);
  MD5STEP(F4, c, d, a, b, in[6] + 0xa3014314, 15);
  MD5STEP(F4, b, c, d, a, in[13] + 0x4e0811a1, 21);
  MD5STEP(F4, a, b, c, d, in[4] + 0xf7537e82, 6);
  MD5STEP(F4, d, a, b, c, in[11] + 0xbd3af235, 10);
  MD5STEP(F4, c, d, a, b, in[2] + 0x2ad7d2bb, 15);
  MD5STEP(F4, b, c, d, a, in[9] + 0xeb86d391, 21);
  
  buf[0] += a;
  buf[1] += b;
  buf[2] += c;
  buf[3] += d;
}

/*
** Function: md5_hmac
** Taken from the file RFC2104
** Written by Martin Schaaf <mascha@ma-scha.de>, modified by Ludovic Marcotte <ludovic@Sophos.ca>
*/
void
md5_hmac(unsigned char *digest,
	 const unsigned char* text, int text_len,
	 const unsigned char* key, int key_len)
{
  struct MD5Context context;
  unsigned char k_ipad[64];    /* inner padding -
				* key XORd with ipad
				*/
  unsigned char k_opad[64];    /* outer padding -
				* key XORd with opad
				*/
  /* unsigned char tk[16]; */
  int i;
  
  /* start out by storing key in pads */
  memset(k_ipad, 0, sizeof k_ipad);
  memset(k_opad, 0, sizeof k_opad);
  
  if (key_len > 64)
    {
      /* if key is longer than 64 bytes reset it to key=MD5(key) */
      struct MD5Context tctx;
      
      MD5Init(&tctx);
      MD5Update(&tctx, key, key_len);
      MD5Final(k_ipad, &tctx);
      MD5Final(k_opad, &tctx);
    } 
  else
    {
      memcpy(k_ipad, key, key_len);
      memcpy(k_opad, key, key_len);
    }
  
  /*
   * the HMAC_MD5 transform looks like:
   *
   * MD5(K XOR opad, MD5(K XOR ipad, text))
   *
   * where K is an n byte key
   * ipad is the byte 0x36 repeated 64 times
   * opad is the byte 0x5c repeated 64 times
   * and text is the data being protected
   */
  

  /* XOR key with ipad and opad values */
  for (i = 0; i < 64; i++)
    {
      k_ipad[i] ^= 0x36;
      k_opad[i] ^= 0x5c;
    }
  
  /*
   * perform inner MD5
   */
  MD5Init(&context);		       /* init context for 1st
					* pass */
  MD5Update(&context, k_ipad, 64);     /* start with inner pad */
  MD5Update(&context, text, text_len); /* then text of datagram */
  MD5Final(digest, &context);	       /* finish up 1st pass */
 
  /*
   * perform outer MD5
   */
  MD5Init(&context);		       /* init context for 2nd
					* pass */
  MD5Update(&context, k_opad, 64);     /* start with outer pad */
  MD5Update(&context, digest, 16);     /* then results of 1st
					 * hash */
  MD5Final(digest, &context);	       /* finish up 2nd pass */
}
