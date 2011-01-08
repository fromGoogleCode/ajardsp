#define A_SIZE 128

int result_max = -1000;
int result_min = 1000;
int a[A_SIZE];

int find_max(int *p)
{
  int i;
  int max = 0;

  for (i = 0; i < A_SIZE; i++)
    {
      if (p[i] > max)
        max = p[i];
    }

  return max;
}

int find_min(int *p)
{
  int i;
  int min = 0;

  for (i = 0; i < A_SIZE; i++)
    {
      if (p[i] < min)
        min = p[i];
    }

  return min;
}


int main(void)
{
  int i;

  for (i = 0; i < sizeof(a)/sizeof(a[0]); i++)
    {
      a[i] = i;
    }

  a[23] = 0x0aaa;
  a[27] = 0x0ccc;
  a[50] = 0x0bbb;
  a[17] = -234;

  result_max = find_max(a);
  result_min = find_min(a);

  return 0;
}
