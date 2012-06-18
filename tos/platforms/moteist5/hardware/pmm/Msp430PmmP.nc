/*
 * Copyright (c) 2011 João Gonçalves
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

/* ***********************************************************
* THIS PROGRAM IS PROVIDED "AS IS". TI MAKES NO WARRANTIES OR
* REPRESENTATIONS, EITHER EXPRESS, IMPLIED OR STATUTORY,
* INCLUDING ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS
* FOR A PARTICULAR PURPOSE, LACK OF VIRUSES, ACCURACY OR
* COMPLETENESS OF RESPONSES, RESULTS AND LACK OF NEGLIGENCE.
* TI DISCLAIMS ANY WARRANTY OF TITLE, QUIET ENJOYMENT, QUIET
* POSSESSION, AND NON-INFRINGEMENT OF ANY THIRD PARTY
* INTELLECTUAL PROPERTY RIGHTS WITH REGARD TO THE PROGRAM OR
* YOUR USE OF THE PROGRAM.
*
* IN NO EVENT SHALL TI BE LIABLE FOR ANY SPECIAL, INCIDENTAL,
* CONSEQUENTIAL OR INDIRECT DAMAGES, HOWEVER CAUSED, ON ANY
* THEORY OF LIABILITY AND WHETHER OR NOT TI HAS BEEN ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGES, ARISING IN ANY WAY OUT
* OF THIS AGREEMENT, THE PROGRAM, OR YOUR USE OF THE PROGRAM.
* EXCLUDED DAMAGES INCLUDE, BUT ARE NOT LIMITED TO, COST OF
* REMOVAL OR REINSTALLATION, COMPUTER TIME, LABOR COSTS, LOSS
* OF GOODWILL, LOSS OF PROFITS, LOSS OF SAVINGS, OR LOSS OF
* USE OR INTERRUPTION OF BUSINESS. IN NO EVENT WILL TI'S
* AGGREGATE LIABILITY UNDER THIS AGREEMENT OR ARISING OUT OF
* YOUR USE OF THE PROGRAM EXCEED FIVE HUNDRED DOLLARS
* (U.S.$500).
*
* Unless otherwise stated, the Program written and copyrighted
* by Texas Instruments is distributed as "freeware".  You may,
* only under TI's copyright in the Program, use and modify the
* Program without any charge or restriction.  You may
* distribute to third parties, provided that you transfer a
* copy of this license to the third party and the third party
* agrees to these terms by its first use of the Program. You
* must reproduce the copyright notice and any other legend of
* ownership on each copy or partial copy, of the Program.
*
* You acknowledge and agree that the Program contains
* copyrighted material, trade secrets and other TI proprietary
* information and is protected by copyright laws,
* international copyright treaties, and trade secret laws, as
* well as other intellectual property laws.  To protect TI's
* rights in the Program, you agree not to decompile, reverse
* engineer, disassemble or otherwise translate any object code
* versions of the Program to a human-readable form.  You agree
* that in no event will you alter, remove or destroy any
* copyright notice included in the Program.  TI reserves all
* rights not specifically granted under this license. Except
* as specifically provided herein, nothing in this agreement
* shall be construed as conferring by implication, estoppel,
* or otherwise, upon you, any license or other right under any
* TI patents, copyrights or trade secrets.
*
* You may not use the Program in non-TI devices.
* ********************************************************* */

#include<stdio.h>

#if !defined(__MSP430_HAS_PMM__)
#error "Msp430PmmP: processor not supported, need PMM"
#endif

#define _HAL_PMM_DISABLE_SVML_
#define _HAL_PMM_DISABLE_SVSL_
#define _HAL_PMM_DISABLE_FULL_PERFORMANCE_

#define PMM_STATUS_OK     SUCCESS
#define PMM_STATUS_ERROR  FAIL

//****************************************************************************//
#ifdef _HAL_PMM_DISABLE_SVML_
#define _HAL_PMM_SVMLE SVMLE
#else
#define _HAL_PMM_SVMLE 0
#endif
#ifdef _HAL_PMM_DISABLE_SVSL_
#define _HAL_PMM_SVSLE SVSLE
#else
#define _HAL_PMM_SVSLE 0
#endif
#ifdef _HAL_PMM_DISABLE_FULL_PERFORMANCE_
#define _HAL_PMM_SVSFP SVSLFP
#else
#define _HAL_PMM_SVSFP 0
#endif

module Msp430PmmP {
  provides interface Pmm;
}
implementation {


//****************************************************************************//
// Set VCore
//****************************************************************************//

  command error_t Pmm.setMinRequiredVCore(uint32_t freq){
    error_t err;
    if(freq <= (8000000)){ 
      err=call Pmm.SetVCore(0);
     }
  
    else if(((8000000) < freq) && (freq<= (12000000))){
      //printf("increasing PMM to 1 for the freq of %lu\n", freq);
      err=call Pmm.SetVCore(1);
     }

    else if(((12000) < freq) && (freq <= (20000000))){ 
      err=call Pmm.SetVCore(2);
     }

    else if((20000000 < freq)){ 
      err=call Pmm.SetVCore(3);
     }

    else 
      return FAIL;
    
    return err;
  }

//****************************************************************************//
// Set VCore
//****************************************************************************//
command error_t Pmm.SetVCore (uint8_t level){
  uint8_t actlevel;
  error_t status = 0;
  level &= PMMCOREV_3;                       // Set Mask for Max. level
  actlevel = (PMMCTL0 & PMMCOREV_3);         // Get actual VCore

  //printf("Actual VCore is %d. Changing to %d...\r\n", actlevel, level);

  while (((level != actlevel) && (status == 0)) || (level < actlevel))		// step by step increase or decrease
  {
    if (level > actlevel)
      status =  call Pmm.SetVCoreUp(++actlevel);
     //printf("Vcore set up to %d, status is %d\n", actlevel, status);
    if (level < actlevel)
      status = call Pmm.SetVCoreDown(--actlevel);
    }
  
  /*if (status == SUCCESS)
    printf("%d, ", level);
  else
    printf("Could not change VCore to %d. Actual VCore remains %d. \r\n", level, actlevel);*/
  return status;
}

//****************************************************************************//
// Set VCore Up
//****************************************************************************//
command error_t Pmm.SetVCoreUp (uint8_t level)
{
  uint8_t PMMRIE_backup,SVSMHCTL_backup;

  // Open PMM registers for write access
  PMMCTL0_H = 0xA5;

  // Disable dedicated Interrupts to prevent that needed flags will be cleared
  PMMRIE_backup = PMMRIE;
  PMMRIE &= ~(SVSMHDLYIE | SVSMLDLYIE | SVMLVLRIE | SVMHVLRIE | SVMHVLRPE);
  // Set SVM highside to new level and check if a VCore increase is possible
  SVSMHCTL_backup = SVSMHCTL;
  PMMIFG &= ~(SVMHIFG | SVSMHDLYIFG);
  SVSMHCTL = SVMHE | SVMHFP | (SVSMHRRL0 * level);
  // Wait until SVM highside is settled
  while ((PMMIFG & SVSMHDLYIFG) == 0);
  // Disable full-performance mode to save energy
  SVSMHCTL &= ~_HAL_PMM_SVSFP ;
  // Check if a VCore increase is possible
  if ((PMMIFG & SVMHIFG) == SVMHIFG){			//-> Vcc is to low for a Vcore increase
    printf("err: Vcc is to low for a Vcore increase\n");
  
  	// recover the previous settings
  	PMMIFG &= ~SVSMHDLYIFG;
  	SVSMHCTL = SVSMHCTL_backup;
  	// Wait until SVM highside is settled
  	while ((PMMIFG & SVSMHDLYIFG) == 0);
  	// Clear all Flags
  	PMMIFG &= ~(SVMHVLRIFG | SVMHIFG | SVSMHDLYIFG | SVMLVLRIFG | SVMLIFG | SVSMLDLYIFG);
  	// backup PMM-Interrupt-Register
  	PMMRIE = PMMRIE_backup;
  	
  	// Lock PMM registers for write access
  	PMMCTL0_H = 0x00;
  	return PMM_STATUS_ERROR;                       // return: voltage not set
  }
  // Set also SVS highside to new level			//-> Vcc is high enough for a Vcore increase
  SVSMHCTL |= SVSHE | (SVSHRVL0 * level);
  // Set SVM low side to new level
  SVSMLCTL = SVMLE | SVMLFP | (SVSMLRRL0 * level);
  // Wait until SVM low side is settled
  while ((PMMIFG & SVSMLDLYIFG) == 0);
  // Clear already set flags
  PMMIFG &= ~(SVMLVLRIFG | SVMLIFG);
  // Set VCore to new level
  PMMCTL0_L = PMMCOREV0 * level;
  // Wait until new level reached
  if (PMMIFG & SVMLIFG)
  while ((PMMIFG & SVMLVLRIFG) == 0);
  // Set also SVS/SVM low side to new level
  PMMIFG &= ~SVSMLDLYIFG;
  SVSMLCTL |= SVSLE | (SVSLRVL0 * level);
  // wait for lowside delay flags
  while ((PMMIFG & SVSMLDLYIFG) == 0);

// Disable SVS/SVM Low
// Disable full-performance mode to save energy
  SVSMLCTL &= ~(_HAL_PMM_DISABLE_SVSL_+_HAL_PMM_DISABLE_SVML_+_HAL_PMM_SVSFP );

  // Clear all Flags
  PMMIFG &= ~(SVMHVLRIFG | SVMHIFG | SVSMHDLYIFG | SVMLVLRIFG | SVMLIFG | SVSMLDLYIFG);
  // backup PMM-Interrupt-Register
  PMMRIE = PMMRIE_backup;

  // Lock PMM registers for write access
  PMMCTL0_H = 0x00;
  return PMM_STATUS_OK;                               // return: OK
}

//****************************************************************************//
// Set VCore down (Independent from the enabled Interrupts in PMMRIE)
//****************************************************************************/
command error_t Pmm.SetVCoreDown (uint8_t level)
{
  unsigned int PMMRIE_backup;

  // Open PMM registers for write access
  PMMCTL0_H = 0xA5;

  // Disable dedicated Interrupts to prevent that needed flags will be cleared
  PMMRIE_backup = PMMRIE;
  PMMRIE &= ~(SVSMHDLYIE | SVSMLDLYIE | SVMLVLRIE | SVMHVLRIE | SVMHVLRPE);

  // Set SVM high side and SVM low side to new level
  PMMIFG &= ~(SVMHIFG | SVSMHDLYIFG | SVMLIFG | SVSMLDLYIFG);
  SVSMHCTL = SVMHE | SVMHFP | (SVSMHRRL0 * level);
  SVSMLCTL = SVMLE | SVMLFP | (SVSMLRRL0 * level);
  // Wait until SVM high side and SVM low side is settled
  while ((PMMIFG & SVSMHDLYIFG) == 0 || (PMMIFG & SVSMLDLYIFG) == 0);

  // Set VCore to new level
  PMMCTL0_L = PMMCOREV0 * level;

  // Set also SVS highside and SVS low side to new level
  PMMIFG &= ~(SVSHIFG | SVSMHDLYIFG | SVSLIFG | SVSMLDLYIFG);
  SVSMHCTL |= SVSHE | SVSHFP | (SVSHRVL0 * level);
  SVSMLCTL |= SVSLE | SVSLFP | (SVSLRVL0 * level);
  // Wait until SVS high side and SVS low side is settled
  while ((PMMIFG & SVSMHDLYIFG) == 0 || (PMMIFG & SVSMLDLYIFG) == 0);
  // Disable full-performance mode to save energy
  SVSMHCTL &= ~_HAL_PMM_SVSFP;
// Disable SVS/SVM Low
// Disable full-performance mode to save energy
  SVSMLCTL &= ~(_HAL_PMM_DISABLE_SVSL_+_HAL_PMM_DISABLE_SVML_+_HAL_PMM_SVSFP );
	
  // Clear all Flags
  PMMIFG &= ~(SVMHVLRIFG | SVMHIFG | SVSMHDLYIFG | SVMLVLRIFG | SVMLIFG | SVSMLDLYIFG);
  // backup PMM-Interrupt-Register
  PMMRIE = PMMRIE_backup;
  // Lock PMM registers for write access
  PMMCTL0_H = 0x00;

  if ((PMMIFG & SVMHIFG) == SVMHIFG)
    return PMM_STATUS_ERROR;					 	// Highside is still to low for the adjusted VCore Level
  else return PMM_STATUS_OK;						// Return: OK
}
}

