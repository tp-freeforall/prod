configuration TestAppC {
} implementation {
  components TestP;

  components MainC;
  TestP.Boot -> MainC;

  components new TimerMilliC();
  TestP.TimerMilli -> TimerMilliC;

  components DisplayCodeC;
  TestP.StdControl -> DisplayCodeC;
  TestP.Code0 -> DisplayCodeC.DisplayCode[0];
  TestP.Code2 -> DisplayCodeC.DisplayCode[2];
  TestP.Code5 -> DisplayCodeC.DisplayCode[5];
  TestP.Code10 -> DisplayCodeC.DisplayCode[10];

#include <unittest/config_impl.h>
}
