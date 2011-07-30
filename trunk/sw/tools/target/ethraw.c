#include <sys/socket.h>
#include <sys/ioctl.h>
#include <linux/if_packet.h>
#include <linux/if_ether.h>
#include <linux/if_arp.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

const char *eth_device_str = "eth0";

int main(int argc, char **argv)
{
  int i, s;
  int res;
  int ifindex;

  struct sockaddr_ll socket_address;
  struct ifreq ifr;

  unsigned char buffer[ETH_FRAME_LEN];

  unsigned char* etherhead = buffer;

  unsigned char* data = buffer + 14;

  struct ethhdr *eh = (struct ethhdr *)etherhead;

  unsigned char src_mac[ETH_ALEN];
  unsigned char dst_mac[ETH_ALEN] = {0x23, 0x04, 0x75, 0xC8, 0x28, 0xE5};

  s = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
  if (s == -1) {
    perror("socket");
    exit(1);
  }

  /*retrieve ethernet interface index*/
  strncpy(ifr.ifr_name, eth_device_str, IFNAMSIZ);
  if (ioctl(s, SIOCGIFINDEX, &ifr) == -1) {
    perror("ioctl:SIOCGIFINDEX");
    exit(1);
  }
  ifindex = ifr.ifr_ifindex;
  /*retrieve corresponding MAC address */
  if (ioctl(s, SIOCGIFHWADDR, &ifr) == -1) {
    perror("ioctl:SIOCGIFHWADDR");
    exit(1);
  }

  for (i = 0; i < 6; i++) {
    src_mac[i] = ifr.ifr_hwaddr.sa_data[i];
  }


  memset(&socket_address, 0, sizeof(socket_address));

  socket_address.sll_family   = PF_PACKET;
  socket_address.sll_protocol = htons(ETH_P_IP);

  socket_address.sll_ifindex  = ifindex;

  socket_address.sll_hatype   = ARPHRD_ETHER;
  socket_address.sll_pkttype  = PACKET_OTHERHOST;
  socket_address.sll_halen    = ETH_ALEN;

  for (i = 0; i < 6; i++) {
    socket_address.sll_addr[i] = dst_mac[i];
  }

  /*set the frame header*/
  memcpy(buffer, dst_mac, ETH_ALEN);
  memcpy(buffer+ETH_ALEN, src_mac, ETH_ALEN);
  eh->h_proto = 0x00;

  /*fill the frame with some data*/
  for (i = 0; i < 1500; i++) {
    data[i] = (unsigned char)i;
  }

  /*send the packet*/
  res = sendto(s, buffer, ETH_FRAME_LEN, 0,
               (struct sockaddr*)&socket_address, sizeof(socket_address));
  if (res == -1) {
    perror("sendto");
    exit(1);
  }

  printf("Sent raw ethernet frame from %02X:%02X:%02X:%02X:%02X:%02X to %02X:%02X:%02X:%02X:%02X:%02X\n",
         src_mac[0], src_mac[1], src_mac[2], src_mac[3], src_mac[4], src_mac[5],
         dst_mac[0], dst_mac[1], dst_mac[2], dst_mac[3], dst_mac[4], dst_mac[5]);

  return 0;
}
