#include <sys/socket.h>
#include <linux/if_packet.h>
#include <linux/if_ether.h>
#include <linux/if_arp.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

int main(int argc, char **argv)
{
  int j;
  int s;

  struct sockaddr_ll socket_address;

  unsigned char buffer[ETH_FRAME_LEN];

  unsigned char* etherhead = buffer;

  unsigned char* data = buffer + 14;

  struct ethhdr *eh = (struct ethhdr *)etherhead;

  int res = 0;

  unsigned char src_mac[6]  = {0x27, 0x01, 0x02, 0xFA, 0x70, 0xAA};
  unsigned char dest_mac[6] = {0x23, 0x04, 0x75, 0xC8, 0x28, 0xE5};

  s = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
  if (s == -1) {
    perror(argv[0]);
  }

  socket_address.sll_family   = PF_PACKET;
  socket_address.sll_protocol = htons(ETH_P_IP);

  socket_address.sll_ifindex  = 2;


  socket_address.sll_hatype   = ARPHRD_ETHER;
  socket_address.sll_pkttype  = PACKET_OTHERHOST;
  socket_address.sll_halen    = ETH_ALEN;

  /*MAC - begin*/
  socket_address.sll_addr[0]  = 0x23;
  socket_address.sll_addr[1]  = 0x04;
  socket_address.sll_addr[2]  = 0x75;
  socket_address.sll_addr[3]  = 0xC8;
  socket_address.sll_addr[4]  = 0x28;
  socket_address.sll_addr[5]  = 0xE5;
  /*MAC - end*/
  socket_address.sll_addr[6]  = 0x00;/*not used*/
  socket_address.sll_addr[7]  = 0x00;/*not used*/

  /*set the frame header*/
  memcpy(buffer, dest_mac, ETH_ALEN);
  memcpy(buffer+ETH_ALEN, src_mac, ETH_ALEN);
  eh->h_proto = 0x00;

  /*fill the frame with some data*/
  for (j = 0; j < 1500; j++) {
    data[j] = (unsigned char)j;
  }

  /*send the packet*/
  res = sendto(s, buffer, ETH_FRAME_LEN, 0,
               (struct sockaddr*)&socket_address, sizeof(socket_address));
  if (res == -1) {
    perror(argv[0]);
  }

  return 0;
}
