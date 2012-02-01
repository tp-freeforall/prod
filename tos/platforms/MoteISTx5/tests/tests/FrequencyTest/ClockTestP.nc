
/**
 * Output MCLK and SMCLK on Boot.
 * Toggle One Led to know the OS is alive
 **/

#include "Timer.h"
#include <stdio.h>
#include "../../../../chips/msp430/x5xxx/usci/msp430usci.h"


module ClockTestP @safe()
{
  //uses interface Timer<TMilli> as Timer0;
  uses interface Leds;
  uses interface Boot;
  uses interface FreqControl;
  
  //uses interface UartByte;
 }
implementation
{
  uint32_t wait = 7536640;
   
  void uwait(uint32_t u) {
    uint32_t t0 = TA0R;
    while((TA0R - t0) <= u);
  }

	void frequency_swype(uint32_t start_freq, uint32_t end_freq, uint32_t step){
		while(start_freq <= end_freq){
			printf("Setting MCLK frequency to %lu Hz.\n", start_freq);
			if(call FreqControl.setMCLKFreq(start_freq) == FAIL )
				printf("Could not change the frequency to: %lu Hz. \r\n", start_freq);
			else
				printf("MCLK frequency is now %lu Hz. \r\n\n", start_freq);
		start_freq = start_freq + step;
    uwait(wait*5);
		}
  }
    
  event void Boot.booted(){
    uint32_t start_freq = 500000;
    uint32_t end_freq = 25000000; 
    uint32_t step = 500000;
    uint8_t source;
    uint32_t freq;
    
    P1DIR |= 0x40;  // P1.6 to output direction
    P2DIR |= 0x01;  // P2.0 to output direction
    P1SEL |= 0x40;  // P1.6 Output SMCLK
    P2SEL |= 0x01;  // 2.0 Output MCLK

    printf("#\n\n|************* Starting frequency swype *************|\n\n");
    
    if(call FreqControl.getMCLKSource() != SELM__DCOCLKDIV){
      printf("#MCLK is not sourced by DCOCLKDIV.\n\n");
      return;
    }
    printf("#MCLK is sourced by DCOCLKDIV.\n\n");
    //printf("#VCore will be ajusted to the frequency of MCLK.\n");
    printf("#Start swype at %lu Hz and end at %lu Hz. Use %lu Hz of step.\n", start_freq, end_freq, step);
    
    frequency_swype(start_freq, end_freq, step);
    printf("#\n\n|************* Frequency swype finished *************|\n\n");

  }
}

