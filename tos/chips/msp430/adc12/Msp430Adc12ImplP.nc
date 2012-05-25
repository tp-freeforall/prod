/*
 * Copyright (c) 2011, Eric B. Decker
 * Copyright (c) 2010, People Power Co.
 * Copyright (c) 2006, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
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
 *
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 * @author Eric B. Decker <cire831@gmail.com>
 * ========================================================================
 */

#if (! ADC12_USE_PLATFORM_ADC) && defined(ADC12_P6PIN_AUTO_CONFIGURE)
/* Convert ADC12_P6PIN_AUTO_CONFIGURE to new signal */
#define ADC12_PIN_AUTO_CONFIGURE 1
#endif /* P6PIN auto configure without PlatformAdcC */

#include <Msp430Adc12.h>
module Msp430Adc12ImplP @safe()
{
  provides {
    interface Init;
    interface Msp430Adc12SingleChannel as SingleChannel[uint8_t id];
    interface Msp430Adc12MultiChannel as MultiChannel[uint8_t id];
    interface Msp430Adc12Overflow as Overflow[uint8_t id];
    interface AsyncStdControl as DMAExtension[uint8_t id];
  }
  uses {
    interface ArbiterInfo as ADCArbiterInfo;
    interface HplAdc12;
    interface Msp430Timer as TimerA;
    interface Msp430TimerControl as ControlA0;
    interface Msp430TimerControl as ControlA1;
    interface Msp430Compare as CompareA0;
    interface Msp430Compare as CompareA1;
    interface HplMsp430GeneralIO as A0;
    interface HplMsp430GeneralIO as A1;
    interface HplMsp430GeneralIO as A2;
    interface HplMsp430GeneralIO as A3;
    interface HplMsp430GeneralIO as A4;
    interface HplMsp430GeneralIO as A5;
#if 6 < ADC12_PINS_AVAILABLE
    interface HplMsp430GeneralIO as A6;
    interface HplMsp430GeneralIO as A7;
#if 8 < ADC12_PINS_AVAILABLE
    interface HplMsp430GeneralIO as A8;
    interface HplMsp430GeneralIO as A9;
    interface HplMsp430GeneralIO as A10;
    interface HplMsp430GeneralIO as A11;
    interface HplMsp430GeneralIO as A12;
    interface HplMsp430GeneralIO as A13;
    interface HplMsp430GeneralIO as A14;
    interface HplMsp430GeneralIO as A15;
#endif /* ADC12_PINS_AVAILABLE : 8 */
#endif /* ADC12_PINS_AVAILABLE : 6 */
  }
}
implementation
{ 

#ifdef ADC12_TIMERA_ENABLED
  #warning Accessing TimerA for ADC12 
#endif

  enum {
    SINGLE_DATA = 1,
    SINGLE_DATA_REPEAT = 2,
    MULTIPLE_DATA = 4,
    MULTIPLE_DATA_REPEAT = 8,
    MULTI_CHANNEL = 16,
    CONVERSION_MODE_MASK = 0x1F,

    ADC_BUSY = 32,                /* request pending */
    USE_TIMERA = 64,              /* TimerA used for SAMPCON signal */
    ADC_OVERFLOW = 128,
  };

  uint8_t state;                  /* see enum above */
  
  uint16_t resultBufferLength;    /* length of buffer */
  uint16_t *COUNT_NOK(resultBufferLength) resultBufferStart;
  uint16_t resultBufferIndex;     /* offset into buffer */
  uint8_t numChannels;            /* number of channels (multi-channel conversion) */
  uint8_t clientID;               /* ID of client that called getData() */

  command error_t Init.init()
  {
    adc12ctl0_t ctl0;

    atomic {
      call HplAdc12.stopConversion(); 	/* data unreliable */
      call HplAdc12.resetIFGs(); 	/* clear relicts from SWReset */
      ctl0 = call HplAdc12.getCtl0();
      ctl0.adc12tovie = 1;
      ctl0.adc12ovie = 1;
      call HplAdc12.setCtl0(ctl0);
#ifdef __MSP430_HAS_REF__
      // Clear REFMSTR: use ADC12CTL to configure reference generate for backwards compatibility
      REFCTL0 &= (~REFMSTR);
#endif // __MSP430_HAS_REF__
    }
    return SUCCESS;
  }

  void prepareTimerA(uint16_t interval, uint16_t csSAMPCON, uint16_t cdSAMPCON)
  {
#ifdef ADC12_TIMERA_ENABLED
    msp430_compare_control_t ccResetSHI = {
      ccifg : 0, cov : 0, out : 0, cci : 0, ccie : 0,
      outmod : 0, cap : 0, clld : 0, scs : 0, ccis : 0, cm : 0 };

    call TimerA.setMode(MSP430TIMER_STOP_MODE);
    call TimerA.clear();
    call TimerA.disableEvents();
    call TimerA.setClockSource(csSAMPCON);
    call TimerA.setInputDivider(cdSAMPCON);
    call ControlA0.setControl(ccResetSHI);
    call CompareA0.setEvent(interval-1);
    call CompareA1.setEvent((interval-1)/2);
#endif
  }
    
  void startTimerA()
  {
#ifdef ADC12_TIMERA_ENABLED
    msp430_compare_control_t ccSetSHI = {
      ccifg : 0, cov : 0, out : 1, cci : 0, ccie : 0,
      outmod : 0, cap : 0, clld : 0, scs : 0, ccis : 0, cm : 0 };
    msp430_compare_control_t ccResetSHI = {
      ccifg : 0, cov : 0, out : 0, cci : 0, ccie : 0,
      outmod : 0, cap : 0, clld : 0, scs : 0, ccis : 0, cm : 0 };
    msp430_compare_control_t ccRSOutmod = {
      ccifg : 0, cov : 0, out : 0, cci : 0, ccie : 0,
      outmod : 7, cap : 0, clld : 0, scs : 0, ccis : 0, cm : 0 };
    // manually trigger first conversion, then switch to Reset/set conversionMode
    call ControlA1.setControl(ccResetSHI);
    call ControlA1.setControl(ccSetSHI);   
    //call ControlA1.setControl(ccResetSHI); 
    call ControlA1.setControl(ccRSOutmod);
    call TimerA.setMode(MSP430TIMER_UP_MODE); // go!
#endif
  }   
  
  void configureAdcPin( uint8_t inch )
  {
#if ADC12_PIN_AUTO_CONFIGURE
    switch (inch)
    {
      case 0: call A0.selectModuleFunc(); call A0.makeInput(); break;
      case 1: call A1.selectModuleFunc(); call A1.makeInput(); break;
      case 2: call A2.selectModuleFunc(); call A2.makeInput(); break;
      case 3: call A3.selectModuleFunc(); call A3.makeInput(); break;
      case 4: call A4.selectModuleFunc(); call A4.makeInput(); break;
      case 5: call A5.selectModuleFunc(); call A5.makeInput(); break;
#if 6 < ADC12_PINS_AVAILABLE
      case 6: call A6.selectModuleFunc(); call A6.makeInput(); break;
      case 7: call A7.selectModuleFunc(); call A7.makeInput(); break;
#if 8 < ADC12_PINS_AVAILABLE
      case 8: call A8.selectModuleFunc(); call A8.makeInput(); break;
      case 9: call A9.selectModuleFunc(); call A9.makeInput(); break;
      case 10: call A10.selectModuleFunc(); call A10.makeInput(); break;
      case 11: call A11.selectModuleFunc(); call A11.makeInput(); break;
      case 12: call A12.selectModuleFunc(); call A12.makeInput(); break;
      case 13: call A13.selectModuleFunc(); call A13.makeInput(); break;
      case 14: call A14.selectModuleFunc(); call A14.makeInput(); break;
      case 15: call A15.selectModuleFunc(); call A15.makeInput(); break;
#endif /* ADC12_PINS_AVAILABLE : 8 */
#endif /* ADC12_PINS_AVAILABLE : 6 */
    }
#endif
  }
  
  void resetAdcPin( uint8_t inch )
  {
#if ADC12_PIN_AUTO_CONFIGURE
    switch (inch)
    {
      case 0: call A0.selectIOFunc(); break;
      case 1: call A1.selectIOFunc(); break;
      case 2: call A2.selectIOFunc(); break;
      case 3: call A3.selectIOFunc(); break;
      case 4: call A4.selectIOFunc(); break;
      case 5: call A5.selectIOFunc(); break;
#if 6 < ADC12_PINS_AVAILABLE
      case 6: call A6.selectIOFunc(); break;
      case 7: call A7.selectIOFunc(); break;
#if 8 < ADC12_PINS_AVAILABLE
      case 8: call A8.selectIOFunc(); break;
      case 9: call A9.selectIOFunc(); break;
      case 10: call A10.selectIOFunc(); break;
      case 11: call A11.selectIOFunc(); break;
      case 12: call A12.selectIOFunc(); break;
      case 13: call A13.selectIOFunc(); break;
      case 14: call A14.selectIOFunc(); break;
      case 15: call A15.selectIOFunc(); break;
#endif /* ADC12_PINS_AVAILABLE : 8 */
#endif /* ADC12_PINS_AVAILABLE : 6 */
    }
#endif
  }
  
  async command error_t SingleChannel.configureSingle[uint8_t id](
      const msp430adc12_channel_config_t *config)
  {
    error_t result = ERESERVE;
#ifdef ADC12_CHECK_ARGS
    if (!config || config->inch == INPUT_CHANNEL_NONE)
      return EINVAL;
#endif
    atomic {
      if (state & ADC_BUSY)
        return EBUSY;
      if (call ADCArbiterInfo.userId() == id){
        adc12ctl1_t ctl1 = {
          adc12busy: 0,
          conseq: 0,
          adc12ssel: config->adc12ssel,
          adc12div: config->adc12div,
          issh: 0,
          shp: 1,
          shs: 0,
          cstartadd: 0
        };
        adc12memctl_t memctl = {
          inch: config->inch,
          sref: config->sref,
          eos: 1
        };        
        adc12ctl0_t ctl0 = call HplAdc12.getCtl0();
        ctl0.msc = 1;
        ctl0.sht0 = config->sht;
        ctl0.sht1 = config->sht;

        state = SINGLE_DATA;
        call HplAdc12.setCtl0(ctl0);
        call HplAdc12.setCtl1(ctl1);
        call HplAdc12.setMCtl(0, memctl);
        call HplAdc12.setIEFlags(0x01);
        result = SUCCESS;
      } 
    }
    return result;
  }

  async command error_t SingleChannel.configureSingleRepeat[uint8_t id](
      const msp430adc12_channel_config_t *config,
      uint16_t jiffies)
  {
    error_t result = ERESERVE;
#ifdef ADC12_CHECK_ARGS
#ifndef ADC12_TIMERA_ENABLED
    if (jiffies>0) 
      return EINVAL;
#endif
    if (!config || config->inch == INPUT_CHANNEL_NONE || jiffies == 1 || jiffies == 2)
      return EINVAL;
#endif
    atomic {
      if (state & ADC_BUSY)
        return EBUSY;
      if (call ADCArbiterInfo.userId() == id) {
        adc12ctl1_t ctl1 = {
          adc12busy: 0,
          conseq: 2,
          adc12ssel: config->adc12ssel,
          adc12div: config->adc12div,
          issh: 0,
          shp: 1,
          shs: (jiffies == 0) ? 0 : 1,
          cstartadd: 0
        };
        adc12memctl_t memctl = {
          inch: config->inch,
          sref: config->sref,
          eos: 1
        };        
        adc12ctl0_t ctl0 = call HplAdc12.getCtl0();
        ctl0.msc = (jiffies == 0) ? 1 : 0;
        ctl0.sht0 = config->sht;
        ctl0.sht1 = config->sht;

        state = SINGLE_DATA_REPEAT;
        call HplAdc12.setCtl0(ctl0);
        call HplAdc12.setCtl1(ctl1);
        call HplAdc12.setMCtl(0, memctl);
        call HplAdc12.setIEFlags(0x01);
        if (jiffies){
          state |= USE_TIMERA;   
          prepareTimerA(jiffies, config->sampcon_ssel, config->sampcon_id);
        }
        result = SUCCESS;
      }     
    }
    return result;
  }

  async command error_t SingleChannel.configureMultiple[uint8_t id](
      const msp430adc12_channel_config_t *config,
      uint16_t *buf, uint16_t length, uint16_t jiffies) {

    error_t result = ERESERVE;

#ifdef ADC12_CHECK_ARGS
#ifndef ADC12_TIMERA_ENABLED
    if (jiffies>0) 
      return EINVAL;
#endif
    if (!config || config->inch == INPUT_CHANNEL_NONE || !buf || !length || jiffies == 1 || jiffies == 2)
      return EINVAL;
#endif
    atomic {
      if (state & ADC_BUSY)
        return EBUSY;
      if (call ADCArbiterInfo.userId() == id){
        adc12ctl1_t ctl1 = {
          adc12busy: 0,
          conseq: (length > 16) ? 3 : 1,
          adc12ssel: config->adc12ssel,
          adc12div: config->adc12div,
          issh: 0,
          shp: 1,
          shs: (jiffies == 0) ? 0 : 1,
          cstartadd: 0
        };
        adc12memctl_t memctl = {
          inch: config->inch,
          sref: config->sref,
          eos: 0
        };        
        uint16_t i, mask = 1;
        adc12ctl0_t ctl0 = call HplAdc12.getCtl0();
        ctl0.msc = (jiffies == 0) ? 1 : 0;
        ctl0.sht0 = config->sht;
        ctl0.sht1 = config->sht;

        state = MULTIPLE_DATA;
	resultBufferStart = NULL;
        resultBufferLength = length;
        resultBufferStart = buf;
        resultBufferIndex = 0;
        call HplAdc12.setCtl0(ctl0);
        call HplAdc12.setCtl1(ctl1);
        for (i=0; i<(length-1) && i < 15; i++)
          call HplAdc12.setMCtl(i, memctl);
        memctl.eos = 1;  
        call HplAdc12.setMCtl(i, memctl);
        call HplAdc12.setIEFlags(mask << i);        
        
        if (jiffies){
          state |= USE_TIMERA;
          prepareTimerA(jiffies, config->sampcon_ssel, config->sampcon_id);
        }
        result = SUCCESS;
      }      
    }
    return result;
  }

  async command error_t SingleChannel.configureMultipleRepeat[uint8_t id](
      const msp430adc12_channel_config_t *config,
      uint16_t *buf, uint8_t length, uint16_t jiffies) {

    error_t result = ERESERVE;

#ifdef ADC12_CHECK_ARGS
#ifndef ADC12_TIMERA_ENABLED
    if (jiffies>0) 
      return EINVAL;
#endif
    if (!config || config->inch == INPUT_CHANNEL_NONE || !buf || !length || length > 16 || jiffies == 1 || jiffies == 2)
      return EINVAL;
#endif
    atomic {
      if (state & ADC_BUSY)
        return EBUSY;
      if (call ADCArbiterInfo.userId() == id){
        adc12ctl1_t ctl1 = {
          adc12busy: 0,
          conseq: 3,
          adc12ssel: config->adc12ssel,
          adc12div: config->adc12div,
          issh: 0,
          shp: 1,
          shs: (jiffies == 0) ? 0 : 1,
          cstartadd: 0
        };
        adc12memctl_t memctl = {
          inch: config->inch,
          sref: config->sref,
          eos: 0
        };        
        uint16_t i, mask = 1;
        adc12ctl0_t ctl0 = call HplAdc12.getCtl0();
        ctl0.msc = (jiffies == 0) ? 1 : 0;
        ctl0.sht0 = config->sht;
        ctl0.sht1 = config->sht;

        state = MULTIPLE_DATA_REPEAT;
	resultBufferStart = NULL;
        resultBufferLength = length;
        resultBufferStart = buf;
        resultBufferIndex = 0;            

        call HplAdc12.setCtl0(ctl0);
        call HplAdc12.setCtl1(ctl1);
        for (i=0; i<(length-1) && i < 15; i++)
          call HplAdc12.setMCtl(i, memctl);
        memctl.eos = 1;  
        call HplAdc12.setMCtl(i, memctl);
        call HplAdc12.setIEFlags(mask << i);        
        
        if (jiffies){
          state |= USE_TIMERA;
          prepareTimerA(jiffies, config->sampcon_ssel, config->sampcon_id);
        }
        result = SUCCESS;
      }
    }
    return result;
  }

  async command error_t SingleChannel.getData[uint8_t id]()
  {
    atomic {
      if (call ADCArbiterInfo.userId() == id){
        if ((state & MULTIPLE_DATA_REPEAT) && !resultBufferStart)
          return EINVAL;
        if (state & ADC_BUSY)
          return EBUSY;
        state |= ADC_BUSY;
        clientID = id;
        configureAdcPin((call HplAdc12.getMCtl(0)).inch);
        call HplAdc12.startConversion();
        if (state & USE_TIMERA)
          startTimerA(); 
        return SUCCESS;
      }
    }
    return FAIL;
  }

  async command error_t MultiChannel.configure[uint8_t id](
      const msp430adc12_channel_config_t *config,
      adc12memctl_t *memctl, uint8_t numMemctl, uint16_t *buf, 
      uint16_t numSamples, uint16_t jiffies) {

    error_t result = ERESERVE;

#ifdef ADC12_CHECK_ARGS
#ifndef ADC12_TIMERA_ENABLED
    if (jiffies>0) 
      return EINVAL;
#endif
    /* note: numSamples % (numMemctl+1) is expensive and should be reworked */
    if (!config || config->inch == INPUT_CHANNEL_NONE || !memctl || !numMemctl ||
	numMemctl > 15 || !numSamples || 
        !buf || jiffies == 1 || jiffies == 2 || numSamples % (numMemctl+1) != 0)
      return EINVAL;
#endif
    atomic {
      if (state & ADC_BUSY)
        return EBUSY;
      if (call ADCArbiterInfo.userId() == id){
        adc12ctl1_t ctl1 = {
          adc12busy: 0,
          conseq: (numSamples > numMemctl+1) ? 3 : 1, 
          adc12ssel: config->adc12ssel,
          adc12div: config->adc12div,
          issh: 0,
          shp: 1,
          shs: (jiffies == 0) ? 0 : 1,
          cstartadd: 0
        };
        adc12memctl_t firstMemctl = {
          inch: config->inch,
          sref: config->sref,
          eos: 0
        };     
        uint16_t i, mask = 1;
        adc12ctl0_t ctl0 = call HplAdc12.getCtl0();
        ctl0.msc = (jiffies == 0) ? 1 : 0;
        ctl0.sht0 = config->sht;
        ctl0.sht1 = config->sht;

        state = MULTI_CHANNEL;
	resultBufferStart = NULL;
        resultBufferLength = numSamples;
        resultBufferStart = buf;
        resultBufferIndex = 0;
        numChannels = numMemctl+1;
        call HplAdc12.setCtl0(ctl0);
        call HplAdc12.setCtl1(ctl1);
        call HplAdc12.setMCtl(0, firstMemctl);
        for (i=0; i<(numMemctl-1) && i < 14; i++){
          memctl[i].eos = 0;
          call HplAdc12.setMCtl(i+1, memctl[i]);
        }
        memctl[i].eos = 1;
        call HplAdc12.setMCtl(i+1, memctl[i]);
        call HplAdc12.setIEFlags(mask << (i+1));        
        
        if (jiffies){
          state |= USE_TIMERA;
          prepareTimerA(jiffies, config->sampcon_ssel, config->sampcon_id);
        }
        result = SUCCESS;
      }      
    }
    return result;
  }

  async command error_t MultiChannel.getData[uint8_t id]()
  {
    uint8_t i;
    atomic {
      if (call ADCArbiterInfo.userId() == id){
        if (!resultBufferStart)
          return EINVAL;
        if (state & ADC_BUSY)
          return EBUSY;
        state |= ADC_BUSY;
        clientID = id;
        for (i=0; i<numChannels; i++)
          configureAdcPin((call HplAdc12.getMCtl(i)).inch);
        call HplAdc12.startConversion();
        if (state & USE_TIMERA)
          startTimerA(); 
        return SUCCESS;
      }
    }
    return FAIL;
  }
  
  void stopConversion()
  {
    uint8_t i;
#ifdef ADC12_TIMERA_ENABLED
    if (state & USE_TIMERA)
      call TimerA.setMode(MSP430TIMER_STOP_MODE);
#endif
    resetAdcPin( (call HplAdc12.getMCtl(0)).inch );
    if (state & MULTI_CHANNEL){
      for (i=1; i<numChannels; i++)
        resetAdcPin( (call HplAdc12.getMCtl(i)).inch );
    }
    atomic {
      call HplAdc12.stopConversion();
      call HplAdc12.resetIFGs(); 
      state &= ~ADC_BUSY;
    }
  }

  async command error_t DMAExtension.start[uint8_t id]()
  { 
    atomic {
      if (call ADCArbiterInfo.userId() == id){
        call HplAdc12.setIEFlags(0);
        call HplAdc12.resetIFGs();
        return SUCCESS;
      }
    }
    return FAIL;
  }
  
  async command error_t DMAExtension.stop[uint8_t id]()
  {
    stopConversion();
    return SUCCESS;
  }
  
  async event void TimerA.overflow(){}
  async event void CompareA0.fired(){}
  async event void CompareA1.fired(){}

  async event void HplAdc12.conversionDone(uint16_t iv)
  {
    bool overflow = FALSE;
    uint16_t *resultBuffer;

    if (iv <= 4){ // check for overflow
      if (iv == 2)
        signal Overflow.memOverflow[clientID]();
      else
        signal Overflow.conversionTimeOverflow[clientID]();
      // only if the client didn't ask for data as fast as possible (jiffies was not zero)
      if (!(call HplAdc12.getCtl0()).msc)
        overflow = TRUE;
      if (call HplAdc12.getIEFlags() == 0)
        return; // DMA serves interrupts
    }
    switch (state & CONVERSION_MODE_MASK) 
    { 
      case SINGLE_DATA:
        stopConversion();
        signal SingleChannel.singleDataReady[clientID](call HplAdc12.getMem(0));
        break;
      case SINGLE_DATA_REPEAT:
        {
          error_t repeatContinue;
          repeatContinue = signal SingleChannel.singleDataReady[clientID](
                call HplAdc12.getMem(0));
          if (repeatContinue != SUCCESS)
            stopConversion();
          break;
        }
#ifndef ADC12_ONLY_WITH_DMA
      case MULTI_CHANNEL:
        {
          uint16_t i = 0, k;
          resultBuffer = resultBufferStart + resultBufferIndex;
          do {
            *resultBuffer++ = call HplAdc12.getMem(i);
          } while (++i < numChannels);
          resultBufferIndex += numChannels;
          if (overflow || resultBufferLength == resultBufferIndex){
            stopConversion();
            resultBuffer -= resultBufferIndex;
            k = resultBufferIndex - numChannels;
            resultBufferIndex = 0;
            signal MultiChannel.dataReady[clientID](resultBuffer, 
                overflow ? k : resultBufferLength);
          }
        }
        break;
      case MULTIPLE_DATA:
        {
          uint16_t i = 0, length, k;
          resultBuffer = resultBufferStart + resultBufferIndex;
          if (resultBufferLength - resultBufferIndex > 16) 
            length = 16;
          else
            length = resultBufferLength - resultBufferIndex;
          do {
            *resultBuffer++ = call HplAdc12.getMem(i);
          } while (++i < length);
          resultBufferIndex += length;
          if (overflow || resultBufferLength == resultBufferIndex){
            stopConversion();
            resultBuffer -= resultBufferIndex;
            k = resultBufferIndex - length;
            resultBufferIndex = 0;
            signal SingleChannel.multipleDataReady[clientID](resultBuffer,
               overflow ? k : resultBufferLength);
          } else if (resultBufferLength - resultBufferIndex > 15)
            return;
          else {
            // last sequence < 16 samples
            adc12memctl_t memctl = call HplAdc12.getMCtl(0);
            memctl.eos = 1;
            call HplAdc12.setMCtl(resultBufferLength - resultBufferIndex, memctl);
          }
        }
        break;
      case MULTIPLE_DATA_REPEAT:
        {
          uint8_t i = 0;
          resultBuffer = resultBufferStart;
          do {
            *resultBuffer++ = call HplAdc12.getMem(i);
          } while (++i < resultBufferLength);
          
          resultBufferStart = signal SingleChannel.multipleDataReady[clientID](
              resultBuffer-resultBufferLength,
              overflow ? 0 : resultBufferLength);
          if (!resultBufferStart)  
            stopConversion();
          break;
        }
#endif

      default:
        stopConversion();
        break;
      } // switch
  }

  default async event error_t SingleChannel.singleDataReady[uint8_t id](uint16_t data) {
    return FAIL;
  }

  default async event uint16_t* SingleChannel.multipleDataReady[uint8_t id](
	uint16_t *buf, uint16_t numSamples) { return 0; }

  default async event void MultiChannel.dataReady[uint8_t id](
	uint16_t *buffer, uint16_t numSamples) {};

  default async event void Overflow.memOverflow[uint8_t id]() {}
  default async event void Overflow.conversionTimeOverflow[uint8_t id]() {}
}
