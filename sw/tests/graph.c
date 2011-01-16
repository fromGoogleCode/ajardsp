int result = 0;
int graph[640];

int rd_gpio_2(void)
{
  int value;

  asm __volatile__ ("mvfs16  %0, $gpio2"
                    : "=r" (value)
                    : /* No inputs */
                    : /* No clobbers */
                    );

  return value;
}

void wr_gpio_2(int value)
{
  asm("mvts16  %0, $gpio2"
      : /* No outputs */
      : "r" (value)
      : /* No clobbers */
      );
}

void disp_array(int *p)
{
  int i;

  avg(p);

  /* Reset x-pos to zero */
  rd_gpio_2();

  for (i = 0; i < 640; i++) {
    wr_gpio_2(p[i]);
  }
}

void avg(int *p)
{
  int i, j;

  for (i = 8; i < 640; i++) {
    int s = 0;
#if 1
    for (j = 0; j < 16; j++) {
      s += p[i - j];
    }
#else
    s = p[i - 2] + p[i - 1] + p[i + 1] + p[i - 2]; // + p[i - 4] + p[i - 5] + p[i - 6] + p[i - 7];
#endif
    p[i] = s >> 4;
  }
}

int main(void)
{
  int i;
  int j;
  int *p;

  p = graph;

  for (i = 0; i < 640; i++) {
    if (i & (1 << 6))
      graph[i] = 100;
    else
      graph[i] = 380;
  }
#if 0
  for (j = 0; j < 300; j++) {
    avg(p);
  }
#endif
  disp_array(graph);
}
