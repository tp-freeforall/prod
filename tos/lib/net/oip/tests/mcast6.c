/* Summary from experimentation
 *
 * - Receive must bind the port in order to have packets delivered
 *
 * - If bind is not to a unicast address, the sin6_scope_id field must
 *   be set correctly.  (The wildcard address and link local addresses
 *   are not unicast addresses; neither is a multicast address.)
 *
 * - It appears receive must bind to the multicast address to receive
 *   packets.
 */
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <net/if.h>
#include <netdb.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdio.h>
#include <poll.h>
#include <getopt.h>

int address_family = AF_INET6;
int socket_type = SOCK_DGRAM;
int protocol = IPPROTO_UDP;
int do_send = 0;
int do_receive = 0;
int do_bind = 0;
int do_bind_interface_address = 0;
int do_bind_multicast_address = 0;
int do_bind_port = 0;
int do_loop = 0;
in_port_t port = 60000;
int multicast_ttl = 1;
const char* interface_device;
int multicast_if_index = 0;
const char* interface_address;
const char* multicast_address = "ff12::1";
int delay_ms = 1000;

enum {
  GAO_RESERVED,
  GAO_do_send,
  GAO_do_receive,
  GAO_do_bind,
  GAO_do_bind_interface_address,
  GAO_do_bind_multicast_address,
  GAO_do_bind_port,
  GAO_do_loop,
  GAO_port,
  GAO_multicast_ttl,
  GAO_interface_device,
  GAO_multicast_if_index,
  GAO_interface_address,
  GAO_multicast_address,
  GAO_delay_ms,
  GAO_list_interfaces,
};

const struct option options[] = {
  { "do-send", no_argument, 0, GAO_do_send }, /* s */
  { "do-receive", no_argument, 0, GAO_do_receive }, /* r */
  { "do-bind", no_argument, 0, GAO_do_bind }, /* b */
  { "do-bind-interface-address", no_argument, 0, GAO_do_bind_interface_address },
  { "do-bind-multicast-address", no_argument, 0, GAO_do_bind_multicast_address},
  { "do-bind-port", no_argument, 0, GAO_do_bind_port },
  { "do-loop", required_argument, 0, GAO_do_loop }, /* l */
  { "port", required_argument, 0, GAO_port },
  { "multicast-ttl", required_argument, 0, GAO_multicast_ttl },
  { "interface-device", required_argument, 0, GAO_interface_device }, /* i: */
  { "multicast-if-index", required_argument, 0, GAO_multicast_if_index }, /* I */
  { "interface-address", required_argument, 0, GAO_interface_address },
  { "multicast-address", required_argument, 0, GAO_multicast_address }, /* m: */
  { "delay-ms", required_argument, 0, GAO_delay_ms },
  { "list-interfaces", no_argument, 0, GAO_list_interfaces },
  { 0 }
};
#define OPT_STRING "srblI:p:i:m:"

const char* nameForGAO (int gao)
{
  const struct option* op = options;
  while (op->name) {
    if (op->val == gao) {
      return op->name;
    }
    ++op;
  }
  return 0;
}

void usage (const char* progname)
{
  fprintf(stderr, "%s: bad user\n", progname);
}

void listInterfaces ()
{
  struct if_nameindex* ifni;
  struct if_nameindex* p;

  ifni = if_nameindex();
  if (! ifni) {
    perror("if_nameindex");
    exit(1);
  }
  p = ifni;
  while (p->if_name) {
    printf("Interface %s index %d\n", p->if_name, p->if_index);
    ++p;
  }
  if_freenameindex(ifni);
}

void displayAddressInfo (const struct sockaddr* addr,
                         socklen_t len)
{
  int rc;
  char host[NI_MAXHOST];
  char serv[NI_MAXSERV];

  rc = getnameinfo(addr, len,
                   host, sizeof(host),
                   serv, sizeof(serv),
                   NI_NUMERICHOST | NI_NUMERICSERV);
  if (0 == rc) {
    printf("%s port %s\n", host, serv);
  } else {
    printf("ERROR %s\n", gai_strerror(rc));
  }
}

int setAddressInfo (const char* hostname,
                    void* storage,
                    socklen_t socklen)
{
  struct addrinfo hints;
  struct addrinfo* result_list;
  struct addrinfo* resp;
  int rc;

  memset(&hints, 0, sizeof(hints));
  hints.ai_family = address_family;
  hints.ai_socktype = socket_type;
  hints.ai_protocol = protocol;

  rc = getaddrinfo(hostname, 0, &hints, &result_list);
  if (0 != rc) {
    fprintf(stderr, "GAI %s: %s\n", hostname, gai_strerror(rc));
    return -1;
  }
  resp = result_list;
  rc = 0;
  while (resp && (0 == rc)) {
    char host[NI_MAXHOST];
    char serv[NI_MAXSERV];
    
    rc = getnameinfo(resp->ai_addr, resp->ai_addrlen, host, sizeof(host), serv, sizeof(serv), 0);
    if (0 != rc) {
      printf("\nFailed getnameinfo on address: %d\n", rc);
    } else {
      int sc = -1;
      memcpy(storage, resp->ai_addr, resp->ai_addrlen);
      rc = resp->ai_addrlen;
    }
    resp = resp->ai_next;
  }
  freeaddrinfo(result_list);
  return rc;
}

char buffer[BUFSIZ];

int main (int argc,
          char* argv[])
{
  int rc;
  int fd;
  int i;

  struct sockaddr_storage interface_saddr_storage;
  struct sockaddr* interface_saddr = (struct sockaddr*)&interface_saddr_storage;
  socklen_t interface_saddr_len = 0;
  struct sockaddr_storage multicast_saddr_storage;
  struct sockaddr* multicast_saddr = (struct sockaddr*)&multicast_saddr_storage;
  socklen_t multicast_saddr_len = 0;
  struct sockaddr_storage bind_saddr_storage;
  struct sockaddr* bind_saddr = (struct sockaddr*)&bind_saddr_storage;
  socklen_t bind_saddr_len = 0;
  struct sockaddr_storage sendto_saddr_storage;
  struct sockaddr* sendto_saddr = (struct sockaddr*)&sendto_saddr_storage;
  socklen_t sendto_saddr_len = 0;
  struct sockaddr_storage recvfrom_saddr_storage;
  struct sockaddr* recvfrom_saddr = (struct sockaddr*)&recvfrom_saddr_storage;
  socklen_t recvfrom_saddr_len = 0;

  struct pollfd pfd;
  extern char* optarg;
  int c;

  while (0 <= (c = getopt_long(argc, argv, OPT_STRING, options, 0))) {
    switch (c) {
      default:
        printf("Unhandled option %d\n", c);
      case '?':
        usage(argv[0]);
        exit(1);
      case 's':
      case GAO_do_send:
        do_send = 1;
        break;
      case 'r':
      case GAO_do_receive:
        do_receive = 1;
        break;
      case 'b':
      case GAO_do_bind:
        do_bind = 1;
        break;
      case GAO_do_bind_interface_address:
        do_bind_interface_address = 1;
        break;
      case GAO_do_bind_multicast_address:
        do_bind_multicast_address = 1;
        break;
      case GAO_do_bind_port:
        do_bind_port = 1;
        break;
      case 'l':
      case GAO_do_loop:
        do_loop = 1;
        break;
      case GAO_port:
        port = strtoul(optarg, 0, 0);
        break;
      case GAO_multicast_ttl:
        multicast_ttl = strtoul(optarg, 0, 0);
        break;
      case 'I':
      case GAO_multicast_if_index:
        multicast_if_index = strtoul(optarg, 0, 0);
        break;
      case 'i':
      case GAO_interface_device:
        interface_device = optarg;
        break;
      case GAO_interface_address:
        interface_address = optarg;
        break;
      case GAO_multicast_address:
        multicast_address = optarg;
        break;
      case GAO_delay_ms:
        delay_ms = strtoul(optarg, 0, 0);
        break;
      case GAO_list_interfaces:
        listInterfaces();
        exit(0);
    }
  }
  
  printf("# %s ", argv[0]);
#define DUMP_FLAG_OPTION(_fl, _force) {               \
    if ((_fl) || (_force)) {                          \
      printf("--%s ", nameForGAO(GAO_##_fl));         \
    }                                                 \
  }
#define DUMP_INT_OPTION(_fl, _force) {                \
    if ((_fl) || (_force)) {                          \
      printf("--%s=%d ", nameForGAO(GAO_##_fl), _fl); \
    }                                                 \
  }
#define DUMP_STRING_OPTION(_fl, _force) {             \
    if ((_fl) || (_force)) {                          \
      printf("--%s=%s ", nameForGAO(GAO_##_fl), _fl); \
    }                                                 \
  }

  DUMP_FLAG_OPTION(do_send, 0);
  DUMP_FLAG_OPTION(do_receive, 0);
  DUMP_FLAG_OPTION(do_bind, 0);
  DUMP_FLAG_OPTION(do_bind_interface_address, 0);
  DUMP_FLAG_OPTION(do_bind_multicast_address, 0);
  DUMP_FLAG_OPTION(do_bind_port, 0);
  DUMP_FLAG_OPTION(do_loop, 0);
  DUMP_INT_OPTION(port, 0);
  DUMP_INT_OPTION(multicast_ttl, 0);
  DUMP_STRING_OPTION(interface_device, 0);
  DUMP_INT_OPTION(multicast_if_index, 1);
  DUMP_STRING_OPTION(interface_address, 0);
  DUMP_STRING_OPTION(multicast_address, 0);
  DUMP_INT_OPTION(delay_ms, 0);
  printf("\n");

  memset(&interface_saddr_storage, 0, sizeof(interface_saddr_storage));
  interface_saddr_len = 0;
  if (interface_address) {
    interface_saddr_len = setAddressInfo(interface_address, interface_saddr, sizeof(interface_saddr));
    if (0 < interface_saddr_len) {
      static char address_as_name[64];
      rc = getnameinfo(interface_saddr, interface_saddr_len, address_as_name, sizeof(address_as_name), 0, 0, 0);
      if (0 != rc) {
        fprintf(stderr, "interface getnameinfo: %s\n", gai_strerror(rc));
        exit(1);
      }
      interface_address = address_as_name;
    }
  }

  if (0 == multicast_if_index) {
    if (interface_device) {
      multicast_if_index = if_nametoindex(interface_device);
    } else {
      if (interface_saddr_len && (AF_INET6 == interface_saddr->sa_family)) {
        multicast_if_index = ((struct sockaddr_in6*)interface_saddr)->sin6_scope_id;
      }
    }
  }
  
  memset(&multicast_saddr_storage, 0, sizeof(multicast_saddr_storage));
  multicast_saddr_len = 0;
  if (multicast_address) {
    multicast_saddr_len = setAddressInfo(multicast_address, multicast_saddr, sizeof(multicast_saddr));
    if (0 < multicast_saddr_len) {
      static char address_as_name[64];
      rc = getnameinfo(multicast_saddr, multicast_saddr_len, address_as_name, sizeof(address_as_name), 0, 0, 0);
      if (0 != rc) {
        fprintf(stderr, "multicast getnameinfo: %s\n", gai_strerror(rc));
        exit(1);
      }
      multicast_address = address_as_name;
    }
  }

  if (do_bind) {
    do_bind_port = 1;
  }

  printf("# Post process: ");
  DUMP_INT_OPTION(multicast_if_index, 1);
  DUMP_STRING_OPTION(interface_address, 0);
  DUMP_STRING_OPTION(multicast_address, 1);
  printf("\n");

  fd = socket(address_family, socket_type, protocol);
  if (0 > fd) {
    perror("socket");
    exit(1);
  }

  i = 1;
  rc = setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &i, sizeof(i));
  if (0 != rc) {
    perror("setsockopt SO_REUSEADDR");
    exit(1);
  }

  memset(&bind_saddr_storage, 0, sizeof(bind_saddr_storage));
  bind_saddr->sa_family = address_family;

  memcpy(sendto_saddr, multicast_saddr, multicast_saddr_len);
  sendto_saddr_len = multicast_saddr_len;

  if (AF_INET6 == address_family) {
    struct sockaddr_in6* multicast_s6p = (struct sockaddr_in6*)multicast_saddr;
    struct sockaddr_in6* sendto_s6p = (struct sockaddr_in6*)sendto_saddr;
    struct ipv6_mreq mreq;

    sendto_s6p->sin6_port = htons(port);
    sendto_s6p->sin6_scope_id = multicast_if_index;

    memset(&mreq, 0, sizeof(mreq));
    memcpy(&mreq.ipv6mr_multiaddr, &multicast_s6p->sin6_addr, sizeof(mreq.ipv6mr_multiaddr));
    mreq.ipv6mr_interface = multicast_if_index;

    rc = setsockopt(fd, IPPROTO_IPV6, IPV6_MULTICAST_IF, &multicast_if_index, sizeof(multicast_if_index));
    if (0 != rc) {
      perror("setsockopt IPV6_MULTICAST_IF");
      exit(1);
    }
    rc = setsockopt(fd, IPPROTO_IPV6, IPV6_JOIN_GROUP, &mreq, sizeof(mreq));
    if (0 != rc) {
      perror("setsockopt IPV6_ADD_MEMBERSHIP");
      exit(1);
    }

    if (do_bind) {
      char host[NI_MAXHOST];
      struct sockaddr_in6* bind_s6p = (struct sockaddr_in6*)bind_saddr;

      if (do_bind_multicast_address) {
        memcpy(bind_saddr, multicast_saddr, multicast_saddr_len);
        bind_saddr_len = multicast_saddr_len;
      } else if (do_bind_interface_address) {
        memcpy(bind_saddr, interface_saddr, interface_saddr_len);
        bind_saddr_len = interface_saddr_len;
      } else {
        bind_saddr_len = sizeof(*bind_s6p);
      }
      bind_s6p->sin6_port = 0;
      if (do_bind_port) {
        bind_s6p->sin6_port = htons(port);
      }
      if (IN6_IS_ADDR_UNSPECIFIED(&bind_s6p->sin6_addr)
          || IN6_IS_ADDR_LINKLOCAL(&bind_s6p->sin6_addr)
          || IN6_IS_ADDR_MULTICAST(&bind_s6p->sin6_addr)) {
        bind_s6p->sin6_scope_id = multicast_if_index;
      }

      printf("Bind INET %s family %d scope_id %d port %d\n",
             inet_ntop(AF_INET6, &bind_s6p->sin6_addr, host, sizeof(host)),
             bind_s6p->sin6_family,
             bind_s6p->sin6_scope_id, ntohs(bind_s6p->sin6_port));

      rc = bind(fd, bind_saddr, bind_saddr_len);
      if (0 != rc) {
        perror("bind");
        exit(1);
      }

    }
  } else {
  }

  bind_saddr_len = sizeof(recvfrom_saddr_storage);
  rc = getsockname(fd, bind_saddr, &bind_saddr_len);
  if (0 == rc) {
    printf("Bind (%s): ", do_bind ? "invoked" : "default");
    displayAddressInfo(bind_saddr, bind_saddr_len);
  } else {
    perror("getsockname");
  }

  if (do_send) {
    printf("SendTo: ");
    displayAddressInfo(sendto_saddr, sendto_saddr_len);
  }

  i = do_loop;
  rc = setsockopt(fd, IPPROTO_IPV6, IPV6_MULTICAST_LOOP, &i, sizeof(i));
  if (0 != rc) {
    perror("setsockopt IPV6_MULTICAST_LOOP");
    exit(1);
  }

  i = multicast_ttl;
  rc = setsockopt(fd, IPPROTO_IPV6, IPV6_MULTICAST_HOPS, &i, sizeof(i));
  if (0 != rc) {
    perror("setsockopt IPV6_MULTICAST_HOPS");
    exit(1);
  }

  memset(&pfd, 0, sizeof(pfd));
  pfd.fd = fd;
  while (1) {
    int timeout_ms = delay_ms;
    const char payload[] = "payload";
    size_t payload_len = sizeof(payload);

    if (do_send) {
      rc = sendto(fd, payload, payload_len, 0,
                  sendto_saddr, sendto_saddr_len);
      if (payload_len != rc) {
        perror("sendto");
        exit(1);
      }
    }

    pfd.events = do_receive ? POLLIN : 0;
    rc = poll(&pfd, 1, timeout_ms);
    printf("poll %x %d: %x\n", pfd.events, rc, pfd.revents);
    if (pfd.revents & POLLIN) {
      recvfrom_saddr_len = sizeof(recvfrom_saddr_storage);
      rc = recvfrom(fd, buffer, sizeof(buffer), 0, recvfrom_saddr, &recvfrom_saddr_len);
      printf("recvfrom got %d from ", rc);
      displayAddressInfo(recvfrom_saddr, recvfrom_saddr_len);
    }
  }

  return 0;
}
