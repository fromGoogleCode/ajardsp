typedef struct node {
  int val;
  struct node *next_p;
}node_t;

node_t *first_p;
int sum = -1;

node_t nodes[16];

void link_first(node_t *n_p)
{
  n_p->next_p = first_p;
  first_p = n_p;
}

int sum_nodes(node_t *n_p)
{
  int s = 0;

  while (n_p) {
    s += n_p->val;
    n_p = n_p->next_p;
  }

  return s;
}

void main(void)
{
  int i;

  for (i = 0; i < sizeof(nodes)/sizeof(nodes[0]); i++) {
    nodes[i].val = i;
  }

  link_first(&nodes[5]);
  link_first(&nodes[2]);
  link_first(&nodes[7]);
  link_first(&nodes[3]);
  link_first(&nodes[1]);
  link_first(&nodes[6]);

  sum = sum_nodes(first_p);
}
