// This file is part of AjarDSP
//
// Copyright (c) 2010, Markus Lavin
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

#define DMEM_SIZE 256
#define IMEM_SIZE 1024

#define CMD_WRITE_IMEM 0xc0
#define CMD_WRITE_DMEM 0xc1
#define CMD_RESET     0xc2
#define CMD_START     0xc3
#define CMD_READ_DMEM 0xc4


void target_reset(int fd)
{
  unsigned char cmd = CMD_RESET;
  int i;
  /* Ok, 16 resets are a bit much but >= 8 required depending on state */
  for (i = 0; i < 16; i++) {
    write(fd, &cmd, sizeof(cmd));
  }
}

void target_start(int fd)
{
  unsigned char cmd = CMD_START;
  write(fd, &cmd, sizeof(cmd));
}


void target_write_dmem(int fd, char* dmemfile, int length)
{
  unsigned char cmd = CMD_WRITE_DMEM;
  unsigned short addr = 0;
  int i;
  FILE* fp;

  fp = fopen(dmemfile, "r");
  while (length > 0 && !feof(fp)) {
    unsigned int uintegers[4];

    if (4 == fscanf(fp, "%02x%02x%02x%02x", &uintegers[0], &uintegers[1],
                    &uintegers[2], &uintegers[3])) {
      unsigned char byte;

      write(fd, &cmd, sizeof(cmd));
      write(fd, &addr, sizeof(addr));

      byte = (unsigned char)uintegers[0];
      write(fd, &byte, sizeof(byte));

      byte = (unsigned char)uintegers[1];
      write(fd, &byte, sizeof(byte));

      byte = (unsigned char)uintegers[2];
      write(fd, &byte, sizeof(byte));

      byte = (unsigned char)uintegers[3];
      write(fd, &byte, sizeof(byte));
    }

    addr+=2;
    length-=2;

  }
  fclose(fp);
}

void target_read_dmem(int fd, char* filename, int read_length, int file_length)
{
  unsigned char cmd = CMD_READ_DMEM;
  unsigned short addr = 0;
  int i;
  FILE* fp;

  fp = fopen(filename, "w");


  for (i = 0; i < read_length/2; i++) {
    int j;
    unsigned char bytes[4];

    write(fd, &cmd, sizeof(cmd));
    write(fd, &addr, sizeof(addr));

    for (j = 0; j < 4; j++) {
      read(fd, &bytes[j], sizeof(bytes[0]));
    }
    fprintf(fp, "%02x%02x\n", bytes[0], bytes[1]);
    fprintf(fp, "%02x%02x\n", bytes[2], bytes[3]);

    addr+=2;
  }

  for (i = 0; i < file_length - read_length; i++) {
    fprintf(fp, "dead\n");
  }

  fclose(fp);
}

void target_write_imem(int fd, char* imemfile, int length)
{
  unsigned char cmd = CMD_WRITE_IMEM;
  unsigned short addr = 0;
  int i;
  FILE* fp;

  length /= 4;

  fp = fopen(imemfile, "r");
  while (length > 0 && !feof(fp)) {

    write(fd, &cmd, sizeof(cmd));
    write(fd, &addr, sizeof(addr));

    addr++;

    for (i = 0; i < 8; i++) {
      unsigned char byte;
      unsigned int uinteger;
      fscanf(fp, "%02x", &uinteger);
      byte = (unsigned char)uinteger;
      write(fd, &byte, sizeof(byte));
    }
    length--;
  }
}

int main(int argc, char **argv)
{
  int fd;
  int i;
  unsigned char c;
  struct termios termios;

  fd = open("/dev/ttyS0", O_RDWR);

  tcgetattr(fd, &termios);
  cfsetispeed(&termios, B115200);
  cfsetospeed(&termios, B115200);
  cfmakeraw(&termios);
  tcsetattr(fd, TCSANOW, &termios);

  target_reset(fd);
  if (argc > 1) {
    target_write_imem(fd, argv[1], IMEM_SIZE);
  }

  if (argc > 2) {
    target_write_dmem(fd, argv[2], DMEM_SIZE);
  }

  target_start(fd);

  sleep(1);

  if (argc > 3) {
    target_read_dmem(fd, argv[3], DMEM_SIZE, 0xffff);
  }

  close(fd);

  return 0;
}
