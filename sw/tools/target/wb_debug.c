// This file is part of AjarDSP
//
// Copyright (c) 2010, 2011 Markus Lavin
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

#include <termios.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define CMD_WRITE 0xc1
#define CMD_READ  0xc2

#define _read(a,b,c)
#define _write(a,b,c)                            \
do {                                            \
  int i;                                        \
  unsigned char *p = (unsigned char*)b;         \
  for (i = 0; i < c; i++) {                     \
    fprintf(stderr, "%02X\n", p[i]);            \
  }                                             \
 } while (0)


#define D(x)


static FILE* uart_hex_file_fp = NULL;
static char *progname = "";

void print_usage(void)
{
  fprintf(stderr,
          "Usage: %s \n"
          "  --load-imem:<file>:<addr>:<max_length>\n"
          "  --load-dmem:<file>:<addr>:<max_length>\n"
          "  --dump:<addr>:<length>\n"
          "  --w32:<addr>:<value>\n\n", progname);

  fprintf(stderr, "Usage example: wb_debug --load-imem:../workdir/boot.imem:0xd0000000:0x40 --load-imem:../workdir/prog13.imem:0xd0000100:0x80 --load-dmem:../workdir/prog13.dmem:0xd0000500:0x40 --w32:0xc0000004:0x1\n");

  exit(1);
}

void wb_debug_w32(int fd, unsigned int addr, unsigned int data)
{
  unsigned char cmd = CMD_WRITE;

  D(printf("wb_debug_w32(fd=%d, addr=0x%08X, data=0x%08X\n", fd, addr, data));

  if (uart_hex_file_fp)
    {
      int i;
      fprintf(uart_hex_file_fp, "%02x\n", cmd);
      for (i = 0; i < 4; i++)
        fprintf(uart_hex_file_fp, "%02x\n", 0xff & (addr >> 8*i));

      for (i = 0; i < 4; i++)
        fprintf(uart_hex_file_fp, "%02x\n", 0xff & (data >> 8*i));
    }
  else
    {
      write(fd, &cmd, sizeof(cmd));
      write(fd, &addr, sizeof(addr));
      write(fd, &data, sizeof(data));
    }
}

void wb_debug_r32(int fd, unsigned int addr, unsigned int *data_p)
{
  unsigned char cmd = CMD_READ;

  write(fd, &cmd, sizeof(cmd));
  write(fd, &addr, sizeof(addr));
  read(fd, data_p, sizeof(unsigned int));
}


void vga_test(int fd)
{
  int i;

  wb_debug_w32(fd, 0xf0010004, 0x0);
  wb_debug_w32(fd, 0xf0010000, 0x2);

  for (i = 0; i < 320000/4; i++)
    {
      wb_debug_w32(fd, 0xf0000000 + i, 0x44444444);
    }
}



void pat_mem(int fd, unsigned int addr, unsigned int len)
{
  int i;

  len >>= 2;

  for (i = 0; i < len; i++)
    {
      unsigned int value;
      unsigned int nibble = i & 0xf;
      value = nibble << 28 | nibble << 24 | nibble << 20 | nibble << 16 | nibble << 12 | nibble << 8 | nibble << 4 | nibble << 0;
      printf("pat_mem: 0x%08X = 0x%08X\n", addr + 4*i, value);
      wb_debug_w32(fd, addr + 4*i, value);
    }
}

void fill_mem(int fd, unsigned int addr, unsigned int len, unsigned int value)
{
  int i;

  for (i = 0; i < len; i++)
    {
      wb_debug_w32(fd, addr + 4*i, value);
    }
}


void dump_mem(int fd, unsigned int addr, unsigned int len)
{
  int i;

  for (i = 0; i < len; i += 4)
    {
      unsigned int data;
      wb_debug_r32(fd, addr + i, &data);
      printf("0x%08X: 0x%08X\n", addr + i, data);
      fflush(stdout);
    }
  printf("\n");
}

void target_load_imem(int fd, char* imemfile, unsigned int address, int length)
{
  FILE* fp;

  fp = fopen(imemfile, "r");
  if (!fp)
    {
      fprintf(stderr, "%s: failed to open %s\n", progname, imemfile);
      print_usage();
    }


  while (!feof(fp))
    {
      unsigned int low;
      unsigned int high;

      fscanf(fp, "%08x%08x", &high, &low);

      wb_debug_w32(fd, address, low);
      length -= 4;
      address += 4;
      if (length <= 0)
        break;

      wb_debug_w32(fd, address, high);
      length -= 4;
      address += 4;
      if (length <= 0)
        break;
    }

  fclose(fp);
}

void target_load_dmem(int fd, char* dmemfile, unsigned int address, int length)
{
  FILE* fp;

  fp = fopen(dmemfile, "r");
  if (!fp)
    {
      fprintf(stderr, "%s: failed to open %s\n", progname, dmemfile);
      print_usage();
    }

  while (!feof(fp) && length > 0)
    {
      unsigned int low;
      unsigned int high;
      unsigned int complete;

      fscanf(fp, "%04x", &low);
      fscanf(fp, "%04x", &high);
      complete = high << 16 | low;

      wb_debug_w32(fd, address, complete);

      length -= 4;
      address += 4;
    }

  fclose(fp);
}

int main(int argc, char **argv)
{
  int fd;
  int i;
  struct termios termios;
  char *uart_tty = "/dev/ttyS0";

  progname = argv[0];

  uart_tty = getenv("AJARDSP_UART_TTY");
  if (!uart_tty)
    {
      uart_tty = "/dev/ttyS0";
    }

  fd = open(uart_tty, O_RDWR);

  tcgetattr(fd, &termios);
  cfsetispeed(&termios, B115200);
  cfsetospeed(&termios, B115200);
  cfmakeraw(&termios);
  tcsetattr(fd, TCSANOW, &termios);

  if (argc == 1)
    {
      print_usage();
      exit(1);
    }

  for (i = 1; i < argc; i++)
    {
      char *args[16];
      int args_found;;

      if (!(argv[i][0] == '-' && argv[i][1] == '-'))
        {
          print_usage();
          exit(1);
        }

      args_found = 0;

      args[args_found] = strtok(&argv[i][2], ":");

      while (args[args_found]) {
        args_found++;
        args[args_found] = strtok(NULL, ":");
      }

      if (!strcmp(args[0], "uart-hex") && args_found == 2)
        {
          uart_hex_file_fp = fopen(args[1], "w");
          if (!uart_hex_file_fp)
            {
              fprintf(stderr, "%s: failed to create uart-hex output file %s\n", progname, args[1]);
              exit(1);
            }
          continue;
        }


      if (!strcmp(args[0], "load-imem") && args_found == 4)
        {
          target_load_imem(fd, args[1], strtoul(args[2], NULL, 0), strtoul(args[3], NULL, 0));
          continue;
        }

      if (!strcmp(args[0], "load-dmem") && args_found == 4)
        {
          target_load_dmem(fd, args[1], strtoul(args[2], NULL, 0), strtoul(args[3], NULL, 0));
          continue;
        }

      if (!strcmp(args[0], "dump") && args_found == 3)
        {
          dump_mem(fd, strtoul(args[1], NULL, 0), strtoul(args[2], NULL, 0));
          continue;
        }

      if (!strcmp(args[0], "w32") && args_found == 3)
        {
          wb_debug_w32(fd, strtoul(args[1], NULL, 0), strtoul(args[2], NULL, 0));
          continue;
        }

        print_usage();
        exit(1);
    }

  close(fd);

  return 0;
}
