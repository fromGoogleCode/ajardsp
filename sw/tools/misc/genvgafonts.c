
/* http://www.win.tue.nl/~aeb/linux/kbd/font-formats-1.html */

#include <stdlib.h>
#include <stdio.h>

#define PSF1_MAGIC0     0x36
#define PSF1_MAGIC1     0x04

#define PSF1_MODE512    0x01
#define PSF1_MODEHASTAB 0x02
#define PSF1_MODEHASSEQ 0x04
#define PSF1_MAXMODE    0x05

#define PSF1_SEPARATOR  0xFFFF
#define PSF1_STARTSEQ   0xFFFE

struct psf1_header {
        unsigned char magic[2];     /* Magic number */
        unsigned char mode;         /* PSF font mode */
        unsigned char charsize;     /* Character size */
};

int main(int argc, char **argv)
{
  FILE *fp = NULL;
  struct psf1_header psf1_h;
  int i,j,k,l;
  unsigned char character[128];
  int opt_init = 0;

  for (i = 1; i < argc; i++)
    {
      if (argv[i][0] == '-')
        {
          if (argv[i][1] == 'i')
            opt_init = 1;
        }
      else
        {
          fp = fopen(argv[1], "r");
        }
    }

  if (fp == NULL)
    {
      fprintf(stderr, "%s: Usage: %s <psf1 font file> [-i]\n", argv[0], argv[0]);
      exit(1);
    }

  fread(&psf1_h, sizeof(psf1_h), 1, fp);

  if (psf1_h.magic[0] != PSF1_MAGIC0 || psf1_h.magic[1] != PSF1_MAGIC1)
    {
      fprintf(stderr, "%s: Error %s is not in PSF1 format\n", argv[0], argv[1]);
      exit(1);
    }

  printf("charsize: %d\n", psf1_h.charsize);

  k = 0;
  l = 0;
  if (opt_init == 0)
    {
      while (!feof(fp))
        {
          fread(character, sizeof(unsigned char), psf1_h.charsize, fp);

          {
            printf("--%d-%c--\n", k, isprint(k) ? k : ' ');
            for (i = 0; i < psf1_h.charsize; i++)
              {
                int j;
                for (j = 0; j < sizeof(unsigned char) * 8; j++)
                  {
                    printf("%c", (character[i] >> (7 - j)) & 1 ? 'X' : ' ');
                  }
                printf("\n");
              }
          }
          k++;
          if (l == 0x40)
            l = 0;
        }
    }
  else
    {
      while (!feof(fp))
        {
          const char hex_map[] = "0123456789abcdef";
          unsigned char buf[32];

          fread(buf, sizeof(char), 32, fp);

          printf(".INIT_%02X(256'h", k);
          for (i = 0; i < 32; i++)
            {
              printf("%02x", buf[32-1-i]);
            }
          printf("),\n");
          k++;
        }
    }


  return 0;
}
