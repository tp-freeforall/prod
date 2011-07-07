#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <netinet/in.h>

const char* my_inet_ntop (struct in6_addr* ip)
{
  static char buffer[8*5+1]; /* 8 4-char quads, 7 colon separators, 1 EOS */
  char *bp = buffer;
  const uint16_t* sp = (const uint16_t*)ip->s6_addr;
  const uint16_t* spe = sp + 8;
  int did_zero = 0;
  int zc = 0;
  int nzc = 0;
  
  while (sp < spe) {
    zc = 0;
    /* Emit text for all leading non-zero groups */
    while ((sp < spe) && (did_zero || (0 != *sp))) {
      bp += sprintf(bp, "%x:", ntohs(*sp++));
      ++nzc;
    }
    if ((sp < spe) && (! did_zero)) {
      /* See how many consecutive zeros are present.  We know there's
       * at least one. */
      while ((sp < spe) && (0 == *sp)) {
        ++zc;
        ++sp;
      }
      did_zero = (1 < zc);
      if (! did_zero) {
        /* Only one.  Don't bother with the shorthand for it. */
        *bp++ = '0';
      } else if (0 == nzc) {
        /* Short-hand zeros start the sequence */
        *bp++ = ':';
      }
      *bp++ = ':';
    }
  }
  if ((0 < nzc) && (0 == zc)) {
    /* Kill the trailing : from the last group */
    --bp;
  }
  /* Put EOS at right position (if all zeroes, there isn't one yet) */
  *bp = 0;
  return buffer;
}

int test_case (const char* s)
{
  struct in6_addr in6a;
  char output[INET6_ADDRSTRLEN];
    
  printf("%s => ", s);
  int rc = inet_pton(AF_INET6, s, in6a.s6_addr);
  if (1 != rc) {
    printf(" inet_pton %d\n", rc);
    return 1;
  } else {
    const char* rp = inet_ntop(AF_INET6, in6a.s6_addr, output, sizeof(output));
    if (0 == rp) {
      perror("!inet_ntop ");
    } else {
      printf("%s ", rp);
    }
    rp = my_inet_ntop(&in6a);
    printf("%s\n", rp);
    /* It is a goal, not a requirement, that we exactly match
     * inet_ntop.  Incidently, so far we do. */
    return strcmp(output, rp);
  }
}

int main (int argc,
          char* argv[])
{
  const char* test_cases[] = {
    "::",
    "::1",
    "1::",
    "0:1::2:0:0",
    "0:1::2:0:3",
    "0:1:200:0:3::0",
    "1::2:3",
  };
  const int ntest_cases = sizeof(test_cases) / sizeof(*test_cases);
  int failures = 0;
  int i;

  for (i = 0; i < ntest_cases; ++i) {
    failures += test_case(test_cases[i]);
  }
  for (i = 1; i < argc; ++i) {
    failures += test_case(argv[i]);
  }
  if (0 == failures) {
    printf("All tests passed\n");
  } else {
    printf("FAILED %d cases\n", failures);
  }
}
