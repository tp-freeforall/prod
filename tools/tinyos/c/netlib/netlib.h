
#ifndef	__NETLIB_H__
#define	__NETLIB_H__

#include <netinet/in.h>
#include <netdb.h>

/* Following shortens all the typecasts of pointer arguments: */
#define	SA	struct sockaddr

/* Miscellaneous constants */
#define	MAXLINE		4096	/* max text line length */
#define	BUFFSIZE	8192	/* buffer size for reads and writes */


char *af2str(int af);
char *socktype2str(int sock_type);
char *sockproto2str(int sock_proto);
char *ai2str(struct addrinfo *ai);

char *sock_ntop(const struct sockaddr *sa, socklen_t salen);
char *Sock_ntop(const struct sockaddr *sa, socklen_t salen);

void err_dump(const char *, ...);
void err_msg(const char *, ...);
void err_quit(const char *, ...);
void err_ret(const char *, ...);
void err_sys(const char *, ...);

#endif	/* __NETLIB_H__ */
