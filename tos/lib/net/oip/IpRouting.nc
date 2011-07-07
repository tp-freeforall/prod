#include <net/if.h>
#include <sys/socket.h>
interface IpRouting {
  command oip_network_id_t nicForDestination (const struct sockaddr* addr);
  command bool routeOnInterface (oip_network_id_t nic_id1);
}
