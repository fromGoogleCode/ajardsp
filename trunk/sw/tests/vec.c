
int cvec[128];
int incval = 5;
int result = -1;

int dostuff(void)
{
	int i;
	for (i = 0; i < sizeof(cvec)/sizeof(cvec[0]); i++)
		cvec[i] = i*incval;

	return 0;
}

int dotprod(int *a, int *b, int n)
{
  int i;
  int s = 0;

  for (i = 0; i < n; i++) {
    s += a[i]*b[i];
  }

  s += a[5] + b[3];

  return s;
}

int main(void)
{
#if 0
  result = dostuff();
#else
  int i;
  for (i = 0; i < sizeof(cvec)/sizeof(cvec[0]); i++) {
    cvec[i] = i;
  }

  result = dotprod(cvec, cvec, sizeof(cvec)/sizeof(cvec[0]));
#endif

  return result;
}

int add(int a, int b, int c)
{
	return a + b + c;
}


