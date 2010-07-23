// Copyright (c) 2010, Denis Markovic
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// 3. Neither the name of the <ORGANIZATION> nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include <stdio.h>
#include <string.h>

typedef unsigned short uint16;
typedef unsigned int   uint32;

uint16 FlToFl16(float flnum)
{
  int mant, exp, sign;
  uint32 num;
  uint16 fl16;

  num = *((uint32 *) &flnum);

  mant  = num & 0x7fffff;
  mant |= 1UL<<23;

  exp  = (num >> 23) & 0xff;
  exp -= 127;

  sign = (num >> 31) & 1;

  printf("s%d  e%d  m%x\n",sign,exp,mant);

  fl16 = 0;
  fl16 |= sign << 15;
  fl16 |= ((exp + 63) & 0x7f) << 8;
  fl16 |= (mant >>(23 - 8)) & 0xff;

  return fl16;
}

uint16 F16Mul(uint16 a, uint16 b)
{
  int ma,mb,sa,sb,ea,eb;
  int m,s,e;
  uint16 res;

  printf("MulIn: %hx %hx\n",a,b);

  sa = a >> 15;
  sb = b >> 15;

  ea = (a >> 8) & 0x7f;ea -= 63;
  eb = (b >> 8) & 0x7f;eb -= 63;

  ma = (a & 0xff) | 0x100;
  mb = (b & 0xff) | 0x100;

  printf("Mul inner 0: s%d  e%d  m%x\n",sa,ea,ma);
  printf("Mul inner 1: s%d  e%d  m%x\n",sb,eb,mb);

  e = ea + eb + 63;
  s = sa ^ sb;


  m = ma * mb;

  if(m&(0x20000)) {
    m>>=9;
    e++;
  } else
    m>>=8;


  printf("Mul inner: s%d  e%d  m%x\n",s,e,m);

  res = (s << 15) | ((e) << 8) | (m & 0xff);

  printf("\nMulOut: %04hx * %04hx = %04hx\n\n",a,b,res);

  return res;
}

float Fl16ToFl(uint16 fl16)
{
  int mant, exp, sign;
  uint32 num;

  mant = fl16 & 0xff;
  mant |= 1UL<<8;

  exp  = (fl16 >> 8) & 0x7f;
  exp -= 63;

  sign = (fl16 >> 15) & 1;

  printf("s%d  e%d  m%x\n",sign,exp,mant);

  num = 0;
  num |= sign << 31;
  num |= ((exp + 127) & 0xff) << 23;
  num |= (mant <<(23 - 8)) & 0x7fffff;

  return *((float *)&num);
}

#if WITH_MAIN

int main(int argc, char **argv)
{
  int i;
  uint32 num;
  float numfl;

  if(argc  == 1) {
    fprintf(stderr,"Usage: %s number    (e.g. %%10001, 0xa1b, 12.312)\n",argv[0]);
    return 1;
  }

  if((argv[1][0] == '%') || ((argv[1][0] == '0') && (argv[1][1]=='x'))) {
    if(argv[1][0] == '%') {
      printf("Read binary fl ...\n");
      for(i=1,num=0; i<strlen(argv[1]); i++)
      {
	num<<=1;
	num |= (argv[1][i] == '1');
      }
    } else {
      printf("Read hex fl16 ...\n");
      sscanf(argv[1],"0x%x",&num);
    }
    numfl = Fl16ToFl((uint16) num);
    printf("conv %hx to %x\n",(uint16)num,*((uint32*)&numfl));
  } else {
    /* assume float input */
    printf("Read Float ...");
    sscanf(argv[1],"%f",&numfl);
    printf("Read %f\n",numfl);
    num = (uint32) FlToFl16(numfl);
  }

  printf("Allres: 0x%04x (%f == 0x%08x)\n",num,numfl,*((uint32 *) &numfl));

  {
    float a=0.15, b=0.3, c;

    printf("Here: %f\n",Fl16ToFl(FlToFl16(a)));
    c = Fl16ToFl(F16Mul(FlToFl16(a),FlToFl16(b)));
    printf("Mul : %f * %f = %f (%08x)\n\n",a,b,c, *((uint32 *)&c));
    printf("Mul : %x * %x = %x \n\n",FlToFl16(a),FlToFl16(b),FlToFl16(c));
    {
    uint16 m1 = 0x3c33,m2=0x3d33,r;
    for (i = 0; i < 5; i++)
    {
      r = F16Mul(m1,m2);
      printf("%x * %x = %x\n",m1,m2,r);
      m1++; m2++;
    }
    }
  }

  return 0;
}

#endif
