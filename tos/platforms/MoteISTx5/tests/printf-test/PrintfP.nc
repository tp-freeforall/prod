
/**
 *  Testing types and variables in tinyos
 *  Use UART to prinft
 **/

#include <stdio.h>

module PrintfP @safe()
{
  uses interface Leds;
  uses interface Boot;
 }
implementation
{
  #define MHZ 1000000
  
  uint32_t frequency = 12000000; //1 MHz
  float dco0_max [] = {0.2, 0.36, 0.75, 1.51, 3.2, 6.0, 10.7, 19.6};
  float dco31_min [] = {0.7, 1.47, 3.17, 6.07, 12.3, 23.7, 39.0, 60.0};
  bool rangefound = FALSE;
  float ratio = 1.12;
  uint8_t RSELx = 0;
  
  void uwait(uint16_t u) {
    uint16_t t0 = TA0R;
    while((TA0R - t0) <= u);
  }
  
	void printfFloat(float toBePrinted) {
		uint32_t fi, f0, f1, f2;
		char c;
		float f = toBePrinted;

		if (f<0){
			c = '-'; f = -f;
		} else {
			c = ' ';
		}

		// integer portion.
		fi = (uint32_t) f;

		// decimal portion...get index for up to 3 decimal places.
		f = f - ((float) fi);
		f0 = f*10;   f0 %= 10;
		f1 = f*100;  f1 %= 10;
		f2 = f*1000; f2 %= 10;
		printf("\n\n%c%ld.%d%d%d", c, fi, (uint8_t) f0, (uint8_t) f1,  (uint8_t) f2);
		}

	event void Boot.booted(){

	printf("Searching RSELx for the frequency of %d MHz.\n", (uint8_t)(frequency/MHZ));
	while(!rangefound){
		if((frequency >= (uint32_t)((dco0_max[RSELx]*ratio)*MHZ)) && (frequency < (uint32_t)((dco31_min[RSELx]/ratio)*MHZ))){
			rangefound = TRUE;
			printf("RSELx found. Use RSELx = %d!\n", RSELx);
			}
		else{
			RSELx++;
			printf("Try RSELx = %d...\n", RSELx);
		}
	}
  }
}

