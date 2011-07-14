#define LCD_E  0x0010
#define LCD_RS 0x0020

int result = -1;
int lcd_rs = 0;

void wait_us(int us)
{
  us <<= 4;

  while (us--) {
    asm("nop");
  }
}

void wait_ms(int ms)
{

  while (ms--) {
    wait_us(1000);
  }
}

//#define wait_us(x)
//#define wait_ms(x)

int rd_gpio(void)
{
  int value;

  asm("mvfs16  %0, $gpio"
      : "=r" (value)
      : /* No inputs */
      : /* No clobbers */
      );

  return value;
}

void wr_ext(long value, void *addr_low, void *addr_high)
{
  asm("stext32 %0, %1, %2"
      : /* No outputs */
      : "r" (addr_low), "r" (addr_high), "r" (value)
      : /* No clobbers */
      );
}

void wr_gpio(int value)
{
  wr_ext(value, (void*)0x0008, (void*)0xC000);
}

void wr_lcd_nibble(int nibble)
{
  nibble &= 0xf;

  wr_gpio(lcd_rs | nibble);
  wr_gpio(lcd_rs |LCD_E | nibble);
  wr_gpio(lcd_rs |nibble);
}

void wr_lcd_byte(int byte)
{
  wr_lcd_nibble((byte >> 4) & 0xf);
  wait_us(1);
  wr_lcd_nibble(byte & 0xf);
  wait_us(40);
}


void set_lcd_dd_addr(int addr)
{
  int old_lcd_rs = lcd_rs;
  lcd_rs = 0;
  wr_lcd_nibble(((addr >> 4) & 0xf) | 0x8);
  wait_us(1);
  wr_lcd_nibble(addr & 0xf);
  wait_us(40);
  lcd_rs = old_lcd_rs;
}

void wr_lcd_str(char *p)
{
  while (*p) {
    wr_lcd_byte(*p);
    p++;
  }
}

char str0[] = "Hello world";
char str1[] = "from ajardsp-gcc";

int main(void)
{
  int *p;
  int cnt = 0;

  /* Do the init */
  lcd_rs = 0;

  wr_lcd_nibble(0x3);

  wait_ms(5);

  wr_lcd_nibble(0x3);

  wait_us(100);

  wr_lcd_nibble(0x3);

  wait_us(40);

  wr_lcd_nibble(0x2);

  wait_us(40);

  wr_gpio(0);

  wait_us(50);

  wr_lcd_byte(0x28);

  wait_us(250);

  wr_lcd_byte(0x06);

  wait_us(250);

  wr_lcd_byte(0x0c);

  wait_us(250);

  wr_lcd_byte(0x01);

  wait_ms(2);

  lcd_rs = LCD_RS;

  set_lcd_dd_addr(0);

  wr_lcd_str(str0);
  wr_lcd_byte(0x30 + rd_gpio());
  set_lcd_dd_addr(0x40);
  wr_lcd_str(str1);

  wr_lcd_byte(rd_gpio());

#if 0
  while (1) {
    set_lcd_dd_addr(0);
    wr_lcd_byte(0x30 + rd_gpio());
  }
#endif

#if 0
  while (1) {
    if (rd_gpio()) {
      wr_lcd_byte(cnt++);
    }
    set_lcd_dd_addr(0);
  }
#endif
  return 0;
}
