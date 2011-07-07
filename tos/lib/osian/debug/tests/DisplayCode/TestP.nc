#include <stdio.h>

module TestP {
  uses {
    interface Boot;
    interface StdControl;
    interface DisplayCode as Code0;
    interface DisplayCode as Code2;
    interface DisplayCode as Code5;
    interface DisplayCode as Code10;
    interface Timer<TMilli> as TimerMilli;
  }
#include <unittest/module_spec.h>
} implementation {
#include <unittest/module_impl.h>

  uint8_t stage;

  task void stage_task ()
  {
    int duration_sec = 5;
    switch (stage++) {
      case 0:
        printf("Startup: nothing displayed\r\n");
        break;
      case 1:
        printf("Enabling code 0: static display of value 0x%x\r\n", call Code0.getValue());
        call Code0.enable(TRUE);
        break;
      case 2:
        duration_sec = 10;
        printf("Code5's id is %d\r\n", call Code5.id());
        printf("Blinking code5 for %u sec\r\n", duration_sec);
        call Code5.enable(TRUE);
        break;
      case 3:
        duration_sec = 10;
        printf("Disabling code 5 for %u seconds (code 0 enabled)\r\n", duration_sec);
        call Code5.enable(FALSE);
        break;
      case 4:
        duration_sec = 10;
        printf("Disabling code 0, enabling code 2 for %u seconds\r\n", duration_sec);
        call Code0.enable(FALSE);
        call Code2.enable(TRUE);
        break;
      case 5:
        duration_sec = 20;
        printf("Adding code 5 for %u seconds (should see both 2 and 5)\r\n", duration_sec);
        call Code5.enable(TRUE);
        break;
      case 6:
        duration_sec = 10;
        printf("Turning off code 2 for %u seconds (should see only 5)\r\n", duration_sec);
        call Code2.enable(FALSE);
        break;
      case 7:
        DisplayCode_enable(2, FALSE);
        DisplayCode_enable(5, FALSE);
        printf("Turning everything off for %u seconds (ends with garbage in display)\r\n", duration_sec);
        break;
      case 8:
        duration_sec = 20;
        printf("Enabling Code10 with previous value 0xEA56 for %u seconds\r\n", duration_sec);
        call Code10.enable(TRUE);
        break;
      case 9:
        duration_sec = 20;
        printf("Enabling code 2 with single nybble value 0x0D for %u seconds (code 10 remains active)\r\n", duration_sec);
        call Code2.setValueWidth(1);
        call Code2.setValue(0x0d);
        call Code2.enable(TRUE);
        break;
      case 10:
        duration_sec = 20;
        printf("Enabling code 0 with current value for %u seconds\r\n", duration_sec);
        call Code0.enable(TRUE);
        break;
      case 11:
        duration_sec = 20;
        call Code2.enable(FALSE);
        call Code10.enable(FALSE);
        printf("Disable everything: runs down leaves in Code0 for %u seconds\r\n", duration_sec);
        break;
      case 12:
        duration_sec = 30;
        printf("Run code 5 display for 2 reps, total duration %u seconds\r\n", duration_sec);
        printf("(NB: 0 + 2 x ( 2 + 0 ) at 6/0 2/2 = 22 sec with 8 sec in static code0)\r\n");
        call Code5.showLimited(2);
        break;
      default:
        printf("Locking code10 as 0x1234\r\n");
        call Code10.setValue(0x1234);
        ALL_TESTS_PASSED();
        call Code10.lock();
        printf("Unexpected return from lock\r\n");
        break;
    }
    call TimerMilli.startOneShot(duration_sec * 1024);
  }

  event void TimerMilli.fired ()
  {
    post stage_task();
  }

  void runStagedTest ()
  {
    printf("Starting staged test\r\n");
    call Code0.setValueWidth(2);
    call Code0.setValue(0x15);
    call Code10.setValueWidth(4);
    call Code10.setValue(0xEA56);
    post stage_task();
  }

  void testId ()
  {
    ASSERT_EQUAL(0, call Code0.id());
    ASSERT_EQUAL(2, call Code2.id());
    ASSERT_EQUAL(5, call Code5.id());
    ASSERT_EQUAL(10, call Code10.id());
  }

  void testGetSet ()
  {
    ASSERT_EQUAL(0, call Code0.getValue());
    call Code0.setValue(0x15);
    ASSERT_EQUAL(0x15, call Code0.getValue());
    call Code0.setValue(0);
    ASSERT_EQUAL(0, call Code0.getValue());

    ASSERT_EQUAL(0, call Code10.getValue());
    call Code10.setValue(0x1234);
    ASSERT_EQUAL(0x1234, call Code10.getValue());
    call Code10.setValue(0);
  }

  event void Boot.booted ()
  {
    testId();
    testGetSet();
    runStagedTest();
  }

}
