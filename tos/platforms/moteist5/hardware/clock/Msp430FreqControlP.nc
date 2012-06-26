/*
 * Copyright (c) 2011, João Gonçalves
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the University of California nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdio.h>
#include "freq_control_const.h"

module Msp430FreqControlP @safe() {
  provides {
     interface FreqControl;
  }
  uses{
     interface Leds;
     interface Pmm;
  }
} implementation {

const uint8_t FLLD_val [] = {1, 2, 4, 8, 16};
const uint8_t FLLREFDIV_val [] = {1, 2, 4, 6, 8, 12};

const float dco0_max [] = {0.2, 0.36, 0.75, 1.51, 3.2, 6.0, 10.7, 19.6};
const float dco31_min [] = {0.7, 1.47, 3.17, 6.07, 12.3, 23.7, 39.0, 60.0};
  
  command uint8_t FreqControl.getFLLD(void){
    uint8_t flld;
      atomic flld = ((UCSCTL2 & FLLD_BITS) >> 12);
      if(flld > 4)
        return 32;
    return FLLD_val[flld];
   }
  
  command uint16_t FreqControl.getFLLN(void){
    atomic return (UCSCTL2 & FLLN_BITS);
  }

  command uint8_t FreqControl.getFLLREFDIV(void){
    uint8_t fllrefdiv;
      atomic fllrefdiv = (UCSCTL3 & FLLREFDIV);
      if (fllrefdiv > 5)
        return 16;
    return FLLREFDIV_val[fllrefdiv]; 
  }

  command uint8_t FreqControl.getMCLKSource(){
    atomic return (UCSCTL4 & 0x0007);  //mclk source bits
  }
  
  command uint32_t FreqControl.getMCLKFreq(uint8_t source){
       /*
        * The purpose is to return the freq value of whatever sources MCLK. 
        * Frequency value in kHz.
        * Only DCOCLK and DCOCLKDIV is implemented.
        */
    switch(source){
      case SELM__XT1CLK:   
      case SELM__VLOCLK:      
      case SELM__REFOCLK:   
      case SELM__DCOCLK:
        return call FreqControl.getDCOFreq(FALSE);       
      case SELM__DCOCLKDIV:{     
        return call FreqControl.getDCOFreq(TRUE);
      }
      case SELM__XT2CLK:       
      default:{
        printf("err: Can't Find MCLK source.\r\n");
        return 0;
      } 
    }
    return 0;
  }
  
  command error_t FreqControl.setMCLKFreq(uint32_t value){
    uint32_t freq;
    uint8_t source;
    error_t result;
    /*
     *  Before changing the frequency call setMinRequiredVCore(freq)
     *  and verify if we need to change the core voltage
     */
    source = call FreqControl.getMCLKSource();
    freq = call FreqControl.getMCLKFreq(source);
    
    if(freq == value){
       //printf("#error: MCLK frequency is already: %d Hz.\r\n", (uint8_t)(freq/1000000));
       return FAIL;
    }
    
    if(value > freq)
       if(call Pmm.setMinRequiredVCore(value)!=SUCCESS)
          return FAIL;
      
    switch (source) {
      case SELM__XT1CLK:
        printf("err: MCLK is sourced by XT1.\r\n");
        break;    
      case SELM__VLOCLK:
        printf("err: MCLK is sourced by VLOCLK.\r\n");
        break;    
      case SELM__REFOCLK:
        printf("err: MCLK is sourced by REFOCLK.\r\n");
        break;    
      case SELM__DCOCLK:
        //printf("MCLK is sourced by DCOCLK.\r\n");
        result = call FreqControl.setDCOFreq(value, FALSE);
        break;
      case SELM__DCOCLKDIV:
        //printf("MCLK is sourced by DCOCLKDIV.\r\n");
        result = call FreqControl.setDCOFreq(value, TRUE);
        break;
      case SELM__XT2CLK:
        printf("err:MCLK is sourced by XT2CLK.\r\n");
        break;    
      default:
       printf("err: Can't Find MCLK source.\r\n");
       return FAIL;
     }

    if(value < freq){
      if(call Pmm.setMinRequiredVCore(value)!=SUCCESS)
      { /* Do nothing, wont break anything besides waisting more energy */}
          
    }
   return result;
  }

  command uint32_t FreqControl.getDCOFreq(bool isdcoclkdiv){
     uint8_t fllrefdiv, flld; 
     uint16_t flln;
     uint32_t freq,  fllref;
       flln = call FreqControl.getFLLN();
       flld = call FreqControl.getFLLD();
       fllrefdiv = call FreqControl.getFLLREFDIV();
   /*
    * I'm assuming the FLL in enabled, so let's find what's it's source.
    * Knowing the FLL reference one can calculate the DCO frequency:
    * fDCOCLK = FLLD*(FLLN+1)*fFLLREF/FLLREFDIV
    * fDCOCLKDIV = (FLLN+1)*fFLLREF/FLLREFDIV
    * Only XT1 is implemented.
    */       
    switch(call FreqControl.getFLLsource()){
      case SELREF_0:
        fllref=(uint32_t) XT1_FREQ; // 000 XT1CLK
        break;
      case SELREF_1: //001 Reserved for future use. Defaults to XT1CLK.
      case SELREF_2: //010 REFOCLK
      case SELREF_3: //011 Reserved for future use. Defaults to REFOCLK.
      case SELREF_4: //100 Reserved for future use. Defaults to REFOCLK.
      case SELREF_5: //101 XT2CLK when available, otherwise REFOCLK.
      case SELREF_6: //110 Reserved for future use. XT2CLK when available, otherwise REFOCLK.
      case SELREF_7: //111 No selection. For the 'F543x and 'F541x non-A versions only, this defaults to XT2CLK. 
    }

    if(isdcoclkdiv){
      freq = (flln+1)*fllref/fllrefdiv;
     // printf("Actual DCO configuration:\nFLLN = %d\nFLLD = %d\nFLLREF frequency = %lu Hz\nFLLREFDIV = %d.\r\n", flln, flld, fllref, fllrefdiv);
     // printf("\nActual DCOCLKDIV frequency is: %lu Hz.\r\n", freq);
      return (freq); 
    }
    
    freq = flld*(flln+1)*fllref/fllrefdiv;
    //printf("Actual DCO Configuration:\nFLLN = %d\nFLLD = %d\nFLLREF frequency = %lu Hz\nFLLREFDIV = %d.\r\n",flln, flld, fllref, fllrefdiv);
    //printf("\nActual DCOCLK frequency is: %lu Hz.\r\n", freq);
    return (freq); 
  }

  command error_t FreqControl.setDCORange(uint32_t value){  
	bool rangefound = FALSE;
	float ratio = 1.12;
	uint8_t RSELx = 0;
	uint8_t flld;
	
    flld = call FreqControl.getFLLD();
    
	//printf("Actual RSELx is: %x.\n", UCSCTL1);
	//printf("Searching RSELx for the frequency of %d MHz.\n", (uint8_t)(value/MHZ));
	
	while(!rangefound){
		if((value >= (uint32_t)((dco0_max[RSELx]*ratio)*MHZ)) && (value < (uint32_t)((dco31_min[RSELx]/ratio)*MHZ))){
			rangefound = TRUE;
			//printf("RSELx found. Use RSELx = %d!\n", RSELx);
			}
		else{
			RSELx++;
			//printf("Try RSELx = %d...\n", RSELx);
		}  
    }
    UCSCTL1 &= 0xFF8E; //Clean DCORSEL bits and enable modulation
    //printf("Cleaned UCSCTL1. It is now: %x.\n", UCSCTL1);
    UCSCTL1 |= (RSELx<<4); // Set RSELx bits
    
    //printf("UCSCTL1 RSELx bits changed to: %x . \r\n", UCSCTL1);
    //printf("For the desired DCOCLK frequency of: %d MHz. \r\n", (uint8_t)(value/MHZ));
    //printf("DCOCLKDIV is at: %d MHz. \r\n", (uint8_t)(value/(flld*MHZ)));
    return SUCCESS;
  }
 
   command error_t FreqControl.setDCOFreq(uint32_t value, bool isdcoclkdiv){
      uint8_t flld, fllrefdiv; 
      uint8_t count = 0;
      /*
       *  Only XT1 as FLL reference is implemented. 
       *  To find DCO config values do: (fFLLREFDIV*fDCO/fFFLLREF) - 1
       *  Make a call to setDCORange to ajust the DCO range to the desired frequency
       *  Just going to find the FLLN value, use fFLLFREFDIV = 1
       */
       flld = call FreqControl.getFLLD();
       fllrefdiv = call FreqControl.getFLLREFDIV();
       if(isdcoclkdiv)
         value = value * flld;  // the DCOCLK is flld times bigger than DCOCLKDIV
       switch(call FreqControl.getFLLsource()){
        uint32_t fllref;
        case SELREF_0:
          fllref = (uint32_t) XT1_FREQ;
          atomic{           
            __bis_SR_register(SR_SCG0);  // Disable FLL control
            if(call FreqControl.setDCORange(value) != SUCCESS){
             printf("err: Could not set new DCO range. \r\n");
             return FAIL;
            }
            //printf("\n\nSetting DCO Frequency to %d MHz.\nThe reference frequency is %lu Hz.\nFLLD is %d.\nFLLREFDIV is %d.\n\n", (uint16_t)(value/1000000), fllref, flld, fllrefdiv);
            //printf("Going to change the FLLN to %d.\r\n\n", (uint16_t) (((value)*fllrefdiv/(fllref*flld)) - 1));
            
            UCSCTL2 &= (~FLLN_BITS);
            UCSCTL2 |= (uint16_t) (((value)*fllrefdiv/(fllref*flld)) - 1);
            //printf("Wrote: %x to UCSCTL2.\r\n", UCSCTL2);
            
            __bic_SR_register(SR_SCG0);  // Enable the FLL control loop
                       
            // Loop until DCO fault flag is cleared.  Ignore OFIFG, since it
            // incorporates XT1 and XT2 fault detection.
            do {
              if(count == 5)
                printf("err: Wait for DCO to settle...\r\n");
              else if(count == 10)
					count = 0;
              count++;
              UCSCTL7 &= ~(XT2OFFG + XT1LFOFFG + XT1HFOFFG + DCOFFG);
              // Clear XT2,XT1,DCO fault flags
              SFRIFG1 &= ~OFIFG;         // Clear fault flags
            } while (UCSCTL7 & DCOFFG); // Test DCO fault flag
            //printf("DCO OK!\r\n");
          }         
         
          return SUCCESS;
        default:
          printf("err: cant find FLL source. \r\n");
          return FAIL;
    }
    return SUCCESS;
  }

  command uint8_t FreqControl.getFLLsource(){
    atomic return (UCSCTL3 & FLLREF);  
  }
}
