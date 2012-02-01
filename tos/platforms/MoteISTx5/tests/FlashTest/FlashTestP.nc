
/**
 * 
 **/

#include "Timer.h"
#include <stdio.h>

module FlashTestP @safe()
{
  //uses interface Timer<TMilli> as Timer0;
  uses interface Leds;
  uses interface Boot;
  uses interface Settings;
  uses interface Init;
  uses interface Msp430Flash;
 }
implementation
{
   
  void uwait(uint16_t u) {
    uint16_t t0 = TA0R;
    while((TA0R - t0) <= u);
  }
  
  //prototypes
  void test(void);
  
  uint8_t data[] = {9,33,3,2,5,6,9,25};
  event void Boot.booted(){
   printf("Booted.\n");
   
  if(call Msp430Flash.isFirstBoot() == TRUE);
    printf("It's First boot\n");
   
   call Init.init(); // this is the first client
   //if(call Client.FlashTestClient() == SUCCESS) // this is the second client
    // printf("First Client: Second Client as called init");
        
  }
  
  event void Settings.requestLogin(){
    error_t status;
    uint8_t i;
    
    printf("First Client: ");
    printf("Request login.\n");
   
    status = call Settings.login((void*) data, sizeof(data)*sizeof(uint8_t));
    switch (status){
	  case EINVAL:{
        printf("This is the first boot, nothing in flash memory.\n");
        
        printf("Storing ");
        for(i=0; i<sizeof(data); i++)
          printf("%d ", data[i]);
          
        if(call Settings.store() == SUCCESS)
          printf("\nDone!\n");
        break;
      }
      case SUCCESS:{
	    printf("First Client loaded: ");
	    /*printf("Loading to flash: ");
	    for(i=0; i<sizeof(data); i++){
	      data[i] = 11;
	      printf("%d ", data[i]);
	    }  
	    if(call Settings.store() == SUCCESS){
	      printf("First Client: ");
	      printf("Data is now loaded from flash.\n");
        }*/
        for(i=0; i<sizeof(data); i++)
	      printf("%d ", data[i]);
	    printf("\n");
        break;
      }
      case FAIL:{
		printf("The client cannot login at this time because you weren't paying attention to the instructions. :).\n");
	    break;
      }
      default:
       //error
    }
  }
}
