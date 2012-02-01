/*
 * Copyright (c) 2011 João Gonçalves
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holders nor the names of
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

/*
 * Simple test application to test ADC
 * 2 Channels convertion
 * @author: João Gonçalves <joao.m.goncalves@ist.utl.pt>
 */

#include "Timer.h"
#include <stdio.h>
#include "Msp430Adc12.h"

#ifdef ADC12_TIMERA_ENABLED
#undef ADC12_TIMERA_ENABLED
#endif

#define SAMPLES 15

module FastADCC{
 provides {
    interface AdcConfigure<const msp430adc12_channel_config_t*> as AdcConfigure;
  }
  uses interface Boot;
  uses interface Leds; 
  uses interface Msp430Adc12MultiChannel as adc;
  uses interface Resource;
}

implementation{
      
  uint16_t adb[SAMPLES];  

  msp430adc12_channel_config_t adcconfig = {
    inch: INPUT_CHANNEL_A1,
    sref: REFERENCE_VREFplus_AVss,
    ref2_5v: REFVOLT_LEVEL_2_5,
    adc12ssel: SHT_SOURCE_ACLK,
    adc12div: SHT_CLOCK_DIV_1,
    sht: SAMPLE_HOLD_1024_CYCLES,
    sampcon_ssel: SAMPCON_SOURCE_SMCLK,
    sampcon_id: SAMPCON_CLOCK_DIV_1
  };
 
  /*adc12memctl_t channelconfig = {
    inch: INPUT_CHANNEL_A2,
    sref: REFVOLT_LEVEL_2_5, 
    eos: 1
  };*/
   adc12memctl_t channelconfig [] = { 
    {INPUT_CHANNEL_A2, REFVOLT_LEVEL_2_5, 0},
    {INPUT_CHANNEL_A3, REFVOLT_LEVEL_2_5, 1}
  };
  adc12memctl_t * adcchannelconfig = (adc12memctl_t *) channelconfig;
  
  async command const msp430adc12_channel_config_t* AdcConfigure.getConfiguration(){
    return &adcconfig; // must not be changed
  }

//prototypes
  void printadb();
  void printfFloat(float toBePrinted);
  void showerror();
  error_t configure();
    
  event void Boot.booted(){
    P1DIR |= 0x40;                       // P1.6 to output direction
    P2DIR |= 0x01;                       // P2.0 to output direction
    P1SEL |= 0x40;                       // P1.6 Output SMCLK
    P2SEL |= 0x01;                       // 2.0 Output MCLK
    printf("Booting...\n"); 
    call Resource.request();
  }
  
  event void Resource.granted(){
    error_t e = FAIL;
      while(e != SUCCESS){
        e = configure();
      }
	  if(call adc.getData() != SUCCESS)
	    printf("Conversion didn't start!\n");
  } 
  
 
  async event void adc.dataReady(uint16_t *buffer, uint16_t numSamples){
  /** 
   * Conversion results are ready. Results are stored in the buffer in the
   * order the channels where specified in the <code>configure()</code>
   * command, i.e. every (numMemctl+1)-th entry maps to the same channel. 
   * 
   * @param buffer Conversion results (lower 12 bit are valid, respectively).
   * @param numSamples Number of results stored in <code>buffer</code> 
   */   
    printadb();
    if(call adc.getData() != SUCCESS)
	    printf("Conversion didn't start!\n");
  }
  void uwait(uint16_t u) {
    uint16_t t0 = TA0R;
    while((TA0R - t0) <= u);
  }
  //functions
  
  void printadb(){
    uint8_t i;
    uint32_t VCurrentMean = 0;
    uint32_t VCoreMean = 0;
    uint32_t VbatMean = 0;
    
    float Gain = 37.5; //(Gm*Rout)
    float refVolt = 2.5;
    float Nmax = 4095;
    float Rsense = 1.01;
    float curr=0;
    float bat =0;
    float core=0;
    
    for(i = 0; i < SAMPLES; i++){
      printf("adb[%d] = %d ->", i, adb[i]);
      core = (float)adb[i]*2.5/4095;
      printfFloat(core);
    }
    uwait(1024*6);
    /*
    for(i = 0; i < SAMPLES; i+=3){
      VCurrentMean += adb[i];
      VbatMean += adb[i+1];
      VCoreMean += adb[i+2];
    }
      VCurrentMean /= (SAMPLES/3);  //bits
      VCoreMean /= (SAMPLES/3); // bits
      VbatMean /= (SAMPLES/3); // bits
      curr = ((float)VCurrentMean)*2.5/Nmax);
      curr /= (Gain*Rsense);
      curr = curr *1000;//value in mA
      
      bat = (((float)VCoreMean)*2.5/Nmax)*2; //value in V
      
      core = ((float)VCoreMean)*1.5/Nmax; // in V
      //currentMean = (currentMean*1000)/(Gain*Rsense); //current in mA, Rsense = 1.01 Ohm
      //voltageMean *= 2; // multiply by 2 to get total battery voltage
      printf("Current,Supply,Vcore\n");
      printfFloat(curr);
      printf(",");
      printfFloat(bat);
      printf(",");
      printfFloat(core);
      printf("\n");
      //printf("%d,%lu,%lu,%lu,%lu,%lu\n", Number, ActFreq, Time, VCurrentMean, VbatMean, VCoreMean);
      */
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
		printf("%c%ld.%d%d%d\n", c, fi, (uint8_t) f0, (uint8_t) f1,  (uint8_t) f2);
  } 
  
  void showerror(){
    call Leds.led0On();
  }
  
  error_t configure(){
    error_t e;
      e = call adc.configure(&adcconfig, adcchannelconfig, 2, adb, SAMPLES, 0);
    if(e != SUCCESS){
		showerror();
        printf("error %d\n", e);
    }
    return e;
  }
  
}
