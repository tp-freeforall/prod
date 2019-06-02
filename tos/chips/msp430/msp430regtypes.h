/**
 * Copyright (c) 2011, 2014, 2016 Eric B. Decker
 * Copyright (c) 2009 DEXMA SENSORS SL
 * Copyright (c) 2000-2003 The Regents of the University of California.  
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
 * - Neither the name of the copyright holder nor the names of
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
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 * @author Xavier Orduna <xorduna@dexmatech.com>
 * @author Eric B. Decker <cire831@gmail.com>
 */

#ifndef _H_MSP430REGTYPES_H
#define _H_MSP430REGTYPES_H

/*
 * With the mspgcc (gcc 3.2.3) toolchain the following was used to
 * generate this file.   With mspgcc4 (gcc 4.4.5), uniarch, and TI_HEADERS
 * this is no longer true.
 *
 * The union mechanism really doesn't work.  There are way too many
 * inconsistencies between the different processors in the msp430 collection.
 * One possible solution is to split the processor dependencies into their
 * own directories, for example the msp430f5438a has its own msp430regtypes.h
 * and the correct directory gets searched after the processor is selected.
 *
 * Rather, this file is maintained by hand and is essentially the union of
 * the cpu definitions that are currently being used and supported by the
 * msp430 TinyOS trunk.
 *
 * These values get used in various low level msp430 drivers.  At some point
 * it may make sense to figure a different way to do this and then get rid
 * of this file.   Well maybe next year.  :-)
 *
 * (The following is no longer supported.   Kept for historical reference).
 * To generate the primary contents of this file seen below, in
 * mspgcc/msp430/include/, execute the following command:
 *
 * find . | xargs perl -ne '
 *   BEGIN { %t = qw(b uint8_t w uint16_t); }
 *    if( /\bsfr([bw])\s*\(\s*(\w+)/ && length($2) > 1 ) {
 *      $r{$2} = $t{$1};
 *      print "#define TYPE_$2 $t{$1}\n" if /\bsfr([bw])\s*\(\s*(\w+)/;
 *    } elsif( /^#define\s+(\w+)\s+(\w+)\s+$/ ) {
 *       print "#define TYPE_$1 $r{$2}\n" if $r{$2};
 *    }
 *   ' | sort -u
 */

#define TYPE_ACTL uint16_t
#define TYPE_ADAT uint16_t
#define TYPE_ADC10AE uint8_t
#define TYPE_ADC10CTL0 uint16_t
#define TYPE_ADC10CTL1 uint16_t
#define TYPE_ADC10DTC0 uint8_t
#define TYPE_ADC10DTC1 uint8_t
#define TYPE_ADC10MEM uint16_t
#define TYPE_ADC10SA uint16_t
#define TYPE_ADC12CTL0 uint16_t
#define TYPE_ADC12CTL1 uint16_t
#define TYPE_ADC12IE uint16_t
#define TYPE_ADC12IFG uint16_t
#define TYPE_ADC12IV uint16_t
#define TYPE_ADC12MCTL0 uint8_t
#define TYPE_ADC12MCTL1 uint8_t
#define TYPE_ADC12MCTL2 uint8_t
#define TYPE_ADC12MCTL3 uint8_t
#define TYPE_ADC12MCTL4 uint8_t
#define TYPE_ADC12MCTL5 uint8_t
#define TYPE_ADC12MCTL6 uint8_t
#define TYPE_ADC12MCTL7 uint8_t
#define TYPE_ADC12MCTL8 uint8_t
#define TYPE_ADC12MCTL9 uint8_t
#define TYPE_ADC12MCTL10 uint8_t
#define TYPE_ADC12MCTL11 uint8_t
#define TYPE_ADC12MCTL12 uint8_t
#define TYPE_ADC12MCTL13 uint8_t
#define TYPE_ADC12MCTL14 uint8_t
#define TYPE_ADC12MCTL15 uint8_t
#define TYPE_ADC12MEM0 uint16_t
#define TYPE_ADC12MEM1 uint16_t
#define TYPE_ADC12MEM2 uint16_t
#define TYPE_ADC12MEM3 uint16_t
#define TYPE_ADC12MEM4 uint16_t
#define TYPE_ADC12MEM5 uint16_t
#define TYPE_ADC12MEM6 uint16_t
#define TYPE_ADC12MEM7 uint16_t
#define TYPE_ADC12MEM8 uint16_t
#define TYPE_ADC12MEM9 uint16_t
#define TYPE_ADC12MEM10 uint16_t
#define TYPE_ADC12MEM11 uint16_t
#define TYPE_ADC12MEM12 uint16_t
#define TYPE_ADC12MEM13 uint16_t
#define TYPE_ADC12MEM14 uint16_t
#define TYPE_ADC12MEM15 uint16_t
#define TYPE_AEN uint16_t
#define TYPE_AIN uint16_t
#define TYPE_BCSCTL1 uint8_t
#define TYPE_BCSCTL2 uint8_t
#define TYPE_BCSCTL3 uint8_t
#define TYPE_BTCNT1 uint8_t
#define TYPE_BTCNT2 uint8_t
#define TYPE_BTCTL uint8_t
#define TYPE_CACTL1 uint8_t
#define TYPE_CACTL2 uint8_t

/*
 * WARNING: All clocking in TinyOS is done as powers of 2.  Time is done as
 * binary millisecs, binary micro-secs, etc.   binary MHz (MiHz).   However,
 * TI specifies their calibration constants using decimal MHz.  Your mileage will vary.
 *
 * Also on newer processors (particularily with variable core voltages) TI specifies
 * the maximum frequency as a power of ten MHz.   This presents more problems for
 * TinyOS' insistence that time is binary.
 */
#define TYPE_CALBC1_1MHZ  uint8_t
#define TYPE_CALBC1_8MHZ  uint8_t
#define TYPE_CALBC1_12MHZ uint8_t
#define TYPE_CALBC1_16MHZ uint8_t
#define TYPE_CALDCO_1MHZ  uint8_t
#define TYPE_CALDCO_8MHZ  uint8_t
#define TYPE_CALDCO_12MHZ uint8_t
#define TYPE_CALDCO_16MHZ uint8_t

#define TYPE_CAPD uint8_t
#define TYPE_CBCTL uint8_t
#define TYPE_CCR0 uint16_t
#define TYPE_CCR1 uint16_t
#define TYPE_CCR2 uint16_t
#define TYPE_CCTL0 uint16_t
#define TYPE_CCTL1 uint16_t
#define TYPE_CCTL2 uint16_t

/*
 * Are these two still used?
 */
#define TYPE_DAC12CTL0 uint16_t
#define TYPE_DAC12IFG uint16_t

#define TYPE_DAC12_0CTL uint16_t
#define TYPE_DAC12_0DAT uint16_t
#define TYPE_DAC12_1CTL uint16_t
#define TYPE_DAC12_1DAT uint16_t

#if defined(__MSP430_HAS_DMAX_3__)
#define TYPE_DMA0DA uint32_t
#define TYPE_DMA0SA uint32_t
#define TYPE_DMA1DA uint32_t
#define TYPE_DMA1SA uint32_t
#define TYPE_DMA2DA uint32_t
#define TYPE_DMA2SA uint32_t
#else
#define TYPE_DMA0DA uint16_t
#define TYPE_DMA0SA uint16_t
#define TYPE_DMA1DA uint16_t
#define TYPE_DMA1SA uint16_t
#define TYPE_DMA2DA uint16_t
#define TYPE_DMA2SA uint16_t
#endif

#define TYPE_DCOCTL uint8_t
#define TYPE_DMA0CTL uint16_t
#define TYPE_DMA0DAL uint16_t
#define TYPE_DMA0SAL uint16_t
#define TYPE_DMA0SZ uint16_t
#define TYPE_DMA1CTL uint16_t
#define TYPE_DMA1DAL uint16_t
#define TYPE_DMA1SAL uint16_t
#define TYPE_DMA1SZ uint16_t
#define TYPE_DMA2CTL uint16_t
#define TYPE_DMA2DAL uint16_t
#define TYPE_DMA2SAL uint16_t
#define TYPE_DMA2SZ uint16_t
#define TYPE_DMACTL0 uint16_t
#define TYPE_DMACTL1 uint16_t
#define TYPE_DMACTL2 uint16_t
#define TYPE_DMACTL3 uint16_t
#define TYPE_DMACTL4 uint16_t
#define TYPE_EPCTL uint8_t
#define TYPE_ESPCTL uint16_t
#define TYPE_FCTL1 uint16_t
#define TYPE_FCTL2 uint16_t
#define TYPE_FCTL3 uint16_t
#define TYPE_FLL_CTL0 uint8_t
#define TYPE_FLL_CTL1 uint8_t
#define TYPE_I2CDCTL uint8_t

/*
 * I2CDR is the old old name.  Should get converted to using I2CDRB.
 */
#define TYPE_I2CDR  uint8_t
#define TYPE_I2CDRB uint8_t
#define TYPE_I2CDRW uint16_t
#define TYPE_I2CIE uint8_t
#define TYPE_I2CIFG uint8_t
#define TYPE_I2CIV uint16_t
#define TYPE_I2CNDAT uint8_t
#define TYPE_I2COA uint16_t
#define TYPE_I2CPSC uint8_t
#define TYPE_I2CSA uint16_t
#define TYPE_I2CSCLH uint8_t
#define TYPE_I2CSCLL uint8_t
#define TYPE_I2CTCTL uint8_t
#define TYPE_IE1 uint8_t
#define TYPE_IE2 uint8_t
#define TYPE_IFG1 uint8_t
#define TYPE_IFG2 uint8_t

#define TYPE_LCDACTL uint8_t
#define TYPE_LCDAPCTL0 uint8_t
#define TYPE_LCDAPCTL1 uint8_t
#define TYPE_LCDAVCTL0 uint8_t
#define TYPE_LCDAVCTL1 uint8_t
#define TYPE_LCDCTL uint8_t

#define TYPE_LCDM1 uint8_t
#define TYPE_LCDM2 uint8_t
#define TYPE_LCDM3 uint8_t
#define TYPE_LCDM4 uint8_t
#define TYPE_LCDM5 uint8_t
#define TYPE_LCDM6 uint8_t
#define TYPE_LCDM7 uint8_t
#define TYPE_LCDM8 uint8_t
#define TYPE_LCDM9 uint8_t
#define TYPE_LCDMA uint8_t
#define TYPE_LCDMB uint8_t
#define TYPE_LCDMC uint8_t
#define TYPE_LCDMD uint8_t
#define TYPE_LCDME uint8_t
#define TYPE_LCDMF uint8_t
#define TYPE_LCDM10 uint8_t
#define TYPE_LCDM11 uint8_t
#define TYPE_LCDM12 uint8_t
#define TYPE_LCDM13 uint8_t
#define TYPE_LCDM14 uint8_t
#define TYPE_LCDM15 uint8_t
#define TYPE_LCDM16 uint8_t
#define TYPE_LCDM17 uint8_t
#define TYPE_LCDM18 uint8_t
#define TYPE_LCDM19 uint8_t
#define TYPE_LCDM20 uint8_t

#define TYPE_MAC  uint16_t
#define TYPE_MACS uint16_t
#define TYPE_MBCTL uint16_t
#define TYPE_MBIN0 uint16_t
#define TYPE_MBIN1 uint16_t
#define TYPE_MBOUT0 uint16_t
#define TYPE_MBOUT1 uint16_t
#define TYPE_ME1 uint8_t
#define TYPE_ME2 uint8_t

#define TYPE_OA0CTL0 uint8_t
#define TYPE_OA0CTL1 uint8_t
#define TYPE_OA1CTL0 uint8_t
#define TYPE_OA1CTL1 uint8_t
#define TYPE_OA2CTL0 uint8_t
#define TYPE_OA2CTL1 uint8_t

#define TYPE_PORT_OUT uint8_t
#define TYPE_PORT_IN uint8_t
#define TYPE_PORT_DIR uint8_t
#define TYPE_PORT_SEL uint8_t
#define TYPE_PORT_REN uint8_t
#define TYPE_PORT_DS uint8_t

#define TYPE_P1IN  uint8_t
#define TYPE_P1OUT uint8_t
#define TYPE_P1DIR uint8_t
#define TYPE_P1REN uint8_t
#define TYPE_P1DS  uint8_t
#define TYPE_P1SEL uint8_t
#define TYPE_P1IES uint8_t
#define TYPE_P1IE  uint8_t
#define TYPE_P1IFG uint8_t

#define TYPE_P2IN  uint8_t
#define TYPE_P2OUT uint8_t
#define TYPE_P2DIR uint8_t
#define TYPE_P2REN uint8_t
#define TYPE_P2DS  uint8_t
#define TYPE_P2SEL uint8_t
#define TYPE_P2IES uint8_t
#define TYPE_P2IE  uint8_t
#define TYPE_P2IFG uint8_t

#define TYPE_P3IN  uint8_t
#define TYPE_P3OUT uint8_t
#define TYPE_P3DIR uint8_t
#define TYPE_P3REN uint8_t
#define TYPE_P3DS  uint8_t
#define TYPE_P3SEL uint8_t

#define TYPE_P4IN  uint8_t
#define TYPE_P4OUT uint8_t
#define TYPE_P4DIR uint8_t
#define TYPE_P4REN uint8_t
#define TYPE_P4DS  uint8_t
#define TYPE_P4SEL uint8_t

#define TYPE_P5IN  uint8_t
#define TYPE_P5OUT uint8_t
#define TYPE_P5DIR uint8_t
#define TYPE_P5REN uint8_t
#define TYPE_P5DS  uint8_t
#define TYPE_P5SEL uint8_t

#define TYPE_P6IN  uint8_t
#define TYPE_P6OUT uint8_t
#define TYPE_P6DIR uint8_t
#define TYPE_P6REN uint8_t
#define TYPE_P6DS  uint8_t
#define TYPE_P6SEL uint8_t

#define TYPE_P7IN  uint8_t
#define TYPE_P7OUT uint8_t
#define TYPE_P7DIR uint8_t
#define TYPE_P7REN uint8_t
#define TYPE_P7DS  uint8_t
#define TYPE_P7SEL uint8_t

#define TYPE_P8IN  uint8_t
#define TYPE_P8OUT uint8_t
#define TYPE_P8DIR uint8_t
#define TYPE_P8REN uint8_t
#define TYPE_P8DS  uint8_t
#define TYPE_P8SEL uint8_t

#define TYPE_P9IN  uint8_t
#define TYPE_P9OUT uint8_t
#define TYPE_P9DIR uint8_t
#define TYPE_P9REN uint8_t
#define TYPE_P9DS  uint8_t
#define TYPE_P9SEL uint8_t

#define TYPE_P10IN  uint8_t
#define TYPE_P10OUT uint8_t
#define TYPE_P10DIR uint8_t
#define TYPE_P10REN uint8_t
#define TYPE_P10DS  uint8_t
#define TYPE_P10SEL uint8_t

#define TYPE_P11IN  uint8_t
#define TYPE_P11OUT uint8_t
#define TYPE_P11DIR uint8_t
#define TYPE_P11REN uint8_t
#define TYPE_P11DS  uint8_t
#define TYPE_P11SEL uint8_t

#define TYPE_PADIR_H uint8_t
#define TYPE_PADIR_L uint8_t
#define TYPE_PADIR uint16_t
#define TYPE_PADS_H uint8_t
#define TYPE_PADS_L uint8_t
#define TYPE_PADS uint16_t
#define TYPE_PAIE_H uint8_t
#define TYPE_PAIE_L uint8_t
#define TYPE_PAIES_H uint8_t
#define TYPE_PAIES_L uint8_t
#define TYPE_PAIES uint16_t
#define TYPE_PAIE uint16_t
#define TYPE_PAIFG_H uint8_t
#define TYPE_PAIFG_L uint8_t
#define TYPE_PAIFG uint16_t
#define TYPE_PAIN_H uint8_t
#define TYPE_PAIN_L uint8_t
#define TYPE_PAIN uint16_t
#define TYPE_PAOUT_H uint8_t
#define TYPE_PAOUT_L uint8_t
#define TYPE_PAOUT uint16_t
#define TYPE_PAREN_H uint8_t
#define TYPE_PAREN_L uint8_t
#define TYPE_PAREN uint16_t
#define TYPE_PASEL_H uint8_t
#define TYPE_PASEL_L uint8_t
#define TYPE_PASEL uint16_t

#define TYPE_PBDIR_H uint8_t
#define TYPE_PBDIR_L uint8_t
#define TYPE_PBDIR uint16_t
#define TYPE_PBDS_H uint8_t
#define TYPE_PBDS_L uint8_t
#define TYPE_PBDS uint16_t
#define TYPE_PBIE_H uint8_t
#define TYPE_PBIE_L uint8_t
#define TYPE_PBIES_H uint8_t
#define TYPE_PBIES_L uint8_t
#define TYPE_PBIES uint16_t
#define TYPE_PBIE uint16_t
#define TYPE_PBIFG_H uint8_t
#define TYPE_PBIFG_L uint8_t
#define TYPE_PBIFG uint16_t
#define TYPE_PBIN_H uint8_t
#define TYPE_PBIN_L uint8_t
#define TYPE_PBIN uint16_t
#define TYPE_PBOUT_H uint8_t
#define TYPE_PBOUT_L uint8_t
#define TYPE_PBOUT uint16_t
#define TYPE_PBREN_H uint8_t
#define TYPE_PBREN_L uint8_t
#define TYPE_PBREN uint16_t
#define TYPE_PBSEL_H uint8_t
#define TYPE_PBSEL_L uint8_t
#define TYPE_PBSEL uint16_t

#define TYPE_PCDIR_H uint8_t
#define TYPE_PCDIR_L uint8_t
#define TYPE_PCDIR uint16_t
#define TYPE_PCDS_H uint8_t
#define TYPE_PCDS_L uint8_t
#define TYPE_PCDS uint16_t
#define TYPE_PCIN_H uint8_t
#define TYPE_PCIN_L uint8_t
#define TYPE_PCIN uint16_t
#define TYPE_PCOUT_H uint8_t
#define TYPE_PCOUT_L uint8_t
#define TYPE_PCOUT uint16_t
#define TYPE_PCREN_H uint8_t
#define TYPE_PCREN_L uint8_t
#define TYPE_PCREN uint16_t
#define TYPE_PCSEL_H uint8_t
#define TYPE_PCSEL_L uint8_t
#define TYPE_PCSEL uint16_t

#define TYPE_PDDIR_H uint8_t
#define TYPE_PDDIR_L uint8_t
#define TYPE_PDDIR uint16_t
#define TYPE_PDDS_H uint8_t
#define TYPE_PDDS_L uint8_t
#define TYPE_PDDS uint16_t
#define TYPE_PDIN_H uint8_t
#define TYPE_PDIN_L uint8_t
#define TYPE_PDIN uint16_t
#define TYPE_PDOUT_H uint8_t
#define TYPE_PDOUT_L uint8_t
#define TYPE_PDOUT uint16_t
#define TYPE_PDREN_H uint8_t
#define TYPE_PDREN_L uint8_t
#define TYPE_PDREN uint16_t
#define TYPE_PDSEL_H uint8_t
#define TYPE_PDSEL_L uint8_t
#define TYPE_PDSEL uint16_t

#define TYPE_PEDIR_H uint8_t
#define TYPE_PEDIR_L uint8_t
#define TYPE_PEDIR uint16_t
#define TYPE_PEDS_H uint8_t
#define TYPE_PEDS_L uint8_t
#define TYPE_PEDS uint16_t
#define TYPE_PEIN_H uint8_t
#define TYPE_PEIN_L uint8_t
#define TYPE_PEIN uint16_t
#define TYPE_PEOUT_H uint8_t
#define TYPE_PEOUT_L uint8_t
#define TYPE_PEOUT uint16_t
#define TYPE_PEREN_H uint8_t
#define TYPE_PEREN_L uint8_t
#define TYPE_PEREN uint16_t
#define TYPE_PESEL_H uint8_t
#define TYPE_PESEL_L uint8_t
#define TYPE_PESEL uint16_t

#define TYPE_PFDIR_H uint8_t
#define TYPE_PFDIR_L uint8_t
#define TYPE_PFDIR uint16_t
#define TYPE_PFDS_H uint8_t
#define TYPE_PFDS_L uint8_t
#define TYPE_PFDS uint16_t
#define TYPE_PFIN_H uint8_t
#define TYPE_PFIN_L uint8_t
#define TYPE_PFIN uint16_t
#define TYPE_PFOUT_H uint8_t
#define TYPE_PFOUT_L uint8_t
#define TYPE_PFOUT uint16_t
#define TYPE_PFREN_H uint8_t
#define TYPE_PFREN_L uint8_t
#define TYPE_PFREN uint16_t
#define TYPE_PFSEL_H uint8_t
#define TYPE_PFSEL_L uint8_t
#define TYPE_PFSEL uint16_t

#define TYPE_PJDIR_H uint8_t
#define TYPE_PJDIR_L uint8_t
#define TYPE_PJDIR uint16_t
#define TYPE_PJDS_H uint8_t
#define TYPE_PJDS_L uint8_t
#define TYPE_PJDS uint16_t
#define TYPE_PJIN_H uint8_t
#define TYPE_PJIN_L uint8_t
#define TYPE_PJIN uint16_t
#define TYPE_PJOUT_H uint8_t
#define TYPE_PJOUT_L uint8_t
#define TYPE_PJOUT uint16_t
#define TYPE_PJREN_H uint8_t
#define TYPE_PJREN_L uint8_t
#define TYPE_PJREN uint16_t
#define TYPE_PJSEL_H uint8_t
#define TYPE_PJSEL_L uint8_t
#define TYPE_PJSEL uint16_t

#define TYPE_MPY uint16_t
#define TYPE_MPYS uint16_t
#define TYPE_OP2 uint16_t

#define TYPE_RESHI uint16_t
#define TYPE_RESLO uint16_t

#define TYPE_RTCCTL uint8_t
#define TYPE_RTCDAY uint8_t
#define TYPE_RTCDOW uint8_t
#define TYPE_RTCHOUR uint8_t
#define TYPE_RTCMIN uint8_t
#define TYPE_RTCMON uint8_t
#define TYPE_RTCNT1 uint8_t
#define TYPE_RTCNT2 uint8_t
#define TYPE_RTCNT3 uint8_t
#define TYPE_RTCNT4 uint8_t
#define TYPE_RTCSEC uint8_t
#define TYPE_RTCTL uint8_t
#define TYPE_RTCYEARH uint8_t
#define TYPE_RTCYEARL uint8_t

#define TYPE_RXBUF uint8_t
#define TYPE_RXBUF0 uint8_t
#define TYPE_RXBUF_0 uint8_t
#define TYPE_RXBUF1 uint8_t
#define TYPE_RXBUF_1 uint8_t
#define TYPE_SCFI0 uint8_t
#define TYPE_SCFI1 uint8_t
#define TYPE_SCFQCTL uint8_t
#define TYPE_SD16AE uint8_t
#define TYPE_SD16CCTL0 uint16_t
#define TYPE_SD16CCTL1 uint16_t
#define TYPE_SD16CCTL2 uint16_t
#define TYPE_SD16CONF0 uint8_t
#define TYPE_SD16CONF1 uint8_t
#define TYPE_SD16CTL uint16_t
#define TYPE_SD16INCTL0 uint8_t
#define TYPE_SD16INCTL1 uint8_t
#define TYPE_SD16INCTL2 uint8_t
#define TYPE_SD16IV uint16_t
#define TYPE_SD16MEM0 uint16_t
#define TYPE_SD16MEM1 uint16_t
#define TYPE_SD16MEM2 uint16_t
#define TYPE_SD16PRE0 uint8_t
#define TYPE_SD16PRE1 uint8_t
#define TYPE_SD16PRE2 uint8_t
#define TYPE_SIFCNT uint16_t
#define TYPE_SIFCTL0 uint16_t
#define TYPE_SIFCTL1 uint16_t
#define TYPE_SIFCTL2 uint16_t
#define TYPE_SIFCTL3 uint16_t
#define TYPE_SIFCTL4 uint16_t
#define TYPE_SIFDACR0 uint16_t
#define TYPE_SIFDACR1 uint16_t
#define TYPE_SIFDACR2 uint16_t
#define TYPE_SIFDACR3 uint16_t
#define TYPE_SIFDACR4 uint16_t
#define TYPE_SIFDACR5 uint16_t
#define TYPE_SIFDACR6 uint16_t
#define TYPE_SIFDACR7 uint16_t
#define TYPE_SIFDEBUG uint16_t
#define TYPE_SIFTPSMV uint16_t
#define TYPE_SIFTSM0 uint16_t
#define TYPE_SIFTSM1 uint16_t
#define TYPE_SIFTSM2 uint16_t
#define TYPE_SIFTSM3 uint16_t
#define TYPE_SIFTSM4 uint16_t
#define TYPE_SIFTSM5 uint16_t
#define TYPE_SIFTSM6 uint16_t
#define TYPE_SIFTSM7 uint16_t
#define TYPE_SIFTSM8 uint16_t
#define TYPE_SIFTSM9 uint16_t
#define TYPE_SIFTSM10 uint16_t
#define TYPE_SIFTSM11 uint16_t
#define TYPE_SIFTSM12 uint16_t
#define TYPE_SIFTSM13 uint16_t
#define TYPE_SIFTSM14 uint16_t
#define TYPE_SIFTSM15 uint16_t
#define TYPE_SIFTSM16 uint16_t
#define TYPE_SIFTSM17 uint16_t
#define TYPE_SIFTSM18 uint16_t
#define TYPE_SIFTSM19 uint16_t
#define TYPE_SIFTSM20 uint16_t
#define TYPE_SIFTSM21 uint16_t
#define TYPE_SIFTSM22 uint16_t
#define TYPE_SIFTSM23 uint16_t
#define TYPE_SUMEXT uint16_t
#define TYPE_SVSCTL uint8_t
#define TYPE_SWCTL uint8_t
#define TYPE_TA0CCR0 uint16_t
#define TYPE_TA0CCR1 uint16_t
#define TYPE_TA0CCR2 uint16_t
#define TYPE_TA0CCTL0 uint16_t
#define TYPE_TA0CCTL1 uint16_t
#define TYPE_TA0CCTL2 uint16_t
#define TYPE_TA0CTL uint16_t
#define TYPE_TA0IV uint16_t
#define TYPE_TA0R uint16_t
#define TYPE_TA1CCR0 uint16_t
#define TYPE_TA1CCR1 uint16_t
#define TYPE_TA1CCR2 uint16_t
#define TYPE_TA1CCR3 uint16_t
#define TYPE_TA1CCR4 uint16_t
#define TYPE_TA1CCTL0 uint16_t
#define TYPE_TA1CCTL1 uint16_t
#define TYPE_TA1CCTL2 uint16_t
#define TYPE_TA1CCTL3 uint16_t
#define TYPE_TA1CCTL4 uint16_t
#define TYPE_TA1CTL uint16_t
#define TYPE_TA1IV uint16_t
#define TYPE_TACCR0 uint16_t
#define TYPE_TACCR1 uint16_t
#define TYPE_TACCR2 uint16_t
#define TYPE_TACCTL0 uint16_t
#define TYPE_TACCTL1 uint16_t
#define TYPE_TACCTL2 uint16_t
#define TYPE_TACTL uint16_t
#define TYPE_TAIV uint16_t
#define TYPE_TAR uint16_t
#define TYPE_TAR1 uint16_t
#define TYPE_TBCCR0 uint16_t
#define TYPE_TBCCR1 uint16_t
#define TYPE_TBCCR2 uint16_t
#define TYPE_TBCCR3 uint16_t
#define TYPE_TBCCR4 uint16_t
#define TYPE_TBCCR5 uint16_t
#define TYPE_TBCCR6 uint16_t
#define TYPE_TBCCTL0 uint16_t
#define TYPE_TBCCTL1 uint16_t
#define TYPE_TBCCTL2 uint16_t
#define TYPE_TBCCTL3 uint16_t
#define TYPE_TBCCTL4 uint16_t
#define TYPE_TBCCTL5 uint16_t
#define TYPE_TBCCTL6 uint16_t
#define TYPE_TBCTL uint16_t
#define TYPE_TBIV uint16_t
#define TYPE_TBR uint16_t
#define TYPE_TCCTL uint8_t
#define TYPE_TLV_ADC12_1_LEN uint8_t
#define TYPE_TLV_ADC12_1_TAG uint8_t
#define TYPE_TLV_CHECKSUM uint16_t
#define TYPE_TLV_DCO_30_LEN uint8_t
#define TYPE_TLV_DCO_30_TAG uint8_t
#define TYPE_TPCNT1 uint8_t
#define TYPE_TPCNT2 uint8_t
#define TYPE_TPCTL uint8_t
#define TYPE_TPD uint8_t
#define TYPE_TPE uint8_t
#define TYPE_TXBUF uint8_t
#define TYPE_TXBUF0 uint8_t
#define TYPE_TXBUF1 uint8_t
#define TYPE_TXBUF_0 uint8_t
#define TYPE_TXBUF_1 uint8_t
#define TYPE_U0BR0 uint8_t
#define TYPE_U0BR1 uint8_t
#define TYPE_U0CTL uint8_t
#define TYPE_U0MCTL uint8_t
#define TYPE_U0RCTL uint8_t
#define TYPE_U0RXBUF uint8_t
#define TYPE_U0TCTL uint8_t
#define TYPE_U0TXBUF uint8_t
#define TYPE_U1BR0 uint8_t
#define TYPE_U1BR1 uint8_t
#define TYPE_U1CTL uint8_t
#define TYPE_U1MCTL uint8_t
#define TYPE_U1RCTL uint8_t
#define TYPE_U1RXBUF uint8_t
#define TYPE_U1TCTL uint8_t
#define TYPE_U1TXBUF uint8_t
#define TYPE_UBR0 uint8_t
#define TYPE_UBR00 uint8_t
#define TYPE_UBR01 uint8_t
#define TYPE_UBR0_0 uint8_t
#define TYPE_UBR0_1 uint8_t
#define TYPE_UBR1 uint8_t
#define TYPE_UBR10 uint8_t
#define TYPE_UBR11 uint8_t
#define TYPE_UBR1_0 uint8_t
#define TYPE_UBR1_1 uint8_t

#define TYPE_UC0IE uint8_t
#define TYPE_UC0IFG uint8_t
#define TYPE_UC1IE uint8_t
#define TYPE_UC1IFG uint8_t

#define TYPE_UCA0ABCTL uint8_t
#define TYPE_UCA0BR0 uint8_t
#define TYPE_UCA0BR1 uint8_t
#define TYPE_UCA0BRW_H uint8_t
#define TYPE_UCA0BRW_L uint8_t
#define TYPE_UCA0BRW uint16_t
#define TYPE_UCA0CTL0 uint8_t
#define TYPE_UCA0CTL1 uint8_t
#define TYPE_UCA0CTLW0_H uint8_t
#define TYPE_UCA0CTLW0_L uint8_t
#define TYPE_UCA0CTLW0 uint16_t
#define TYPE_UCA0CTLW1_H uint8_t
#define TYPE_UCA0CTLW1_L uint8_t
#define TYPE_UCA0CTLW1 uint16_t
#define TYPE_UCA0ICTL_H uint8_t
#define TYPE_UCA0ICTL_L uint8_t
#define TYPE_UCA0ICTL uint16_t
#define TYPE_UCA0IE uint8_t
#define TYPE_UCA0IFG uint8_t
#define TYPE_UCA0IRCTL_H uint8_t
#define TYPE_UCA0IRCTL_L uint8_t
#define TYPE_UCA0IRCTL uint16_t
#define TYPE_UCA0IRRCTL uint8_t
#define TYPE_UCA0IRTCTL uint8_t
#define TYPE_UCA0IV uint16_t
#define TYPE_UCA0MCTL uint8_t
#define TYPE_UCA0MCTLW_H uint8_t
#define TYPE_UCA0MCTLW_L uint8_t
#define TYPE_UCA0MCTLW uint16_t
#define TYPE_UCA0STAT uint8_t
#define TYPE_UCA0STATW uint8_t
#define TYPE_UCA0RXBUF uint8_t
#define TYPE_UCA0TXBUF uint8_t

#define TYPE_UCA1ABCTL uint8_t
#define TYPE_UCA1BR0 uint8_t
#define TYPE_UCA1BR1 uint8_t
#define TYPE_UCA1BRW_H uint8_t
#define TYPE_UCA1BRW_L uint8_t
#define TYPE_UCA1BRW uint16_t
#define TYPE_UCA1CTL0 uint8_t
#define TYPE_UCA1CTL1 uint8_t
#define TYPE_UCA1CTLW0_H uint8_t
#define TYPE_UCA1CTLW0_L uint8_t
#define TYPE_UCA1CTLW0 uint16_t
#define TYPE_UCA1CTLW1_H uint8_t
#define TYPE_UCA1CTLW1_L uint8_t
#define TYPE_UCA1CTLW1 uint16_t
#define TYPE_UCA1ICTL_H uint8_t
#define TYPE_UCA1ICTL_L uint8_t
#define TYPE_UCA1ICTL uint16_t
#define TYPE_UCA1IE uint8_t
#define TYPE_UCA1IFG uint8_t
#define TYPE_UCA1IRCTL_H uint8_t
#define TYPE_UCA1IRCTL_L uint8_t
#define TYPE_UCA1IRCTL uint16_t
#define TYPE_UCA1IRRCTL uint8_t
#define TYPE_UCA1IRTCTL uint8_t
#define TYPE_UCA1IV uint16_t
#define TYPE_UCA1MCTL uint8_t
#define TYPE_UCA1MCTLW_H uint8_t
#define TYPE_UCA1MCTLW_L uint8_t
#define TYPE_UCA1MCTLW uint16_t
#define TYPE_UCA1STAT uint8_t
#define TYPE_UCA1STATW uint8_t
#define TYPE_UCA1RXBUF uint8_t
#define TYPE_UCA1TXBUF uint8_t

#define TYPE_UCA2ABCTL uint8_t
#define TYPE_UCA2BRW_H uint8_t
#define TYPE_UCA2BRW_L uint8_t
#define TYPE_UCA2BRW uint16_t
#define TYPE_UCA2CTLW0_H uint8_t
#define TYPE_UCA2CTLW0_L uint8_t
#define TYPE_UCA2CTLW0 uint16_t
#define TYPE_UCA2CTLW1_H uint8_t
#define TYPE_UCA2CTLW1_L uint8_t
#define TYPE_UCA2CTLW1 uint16_t
#define TYPE_UCA2ICTL_H uint8_t
#define TYPE_UCA2ICTL_L uint8_t
#define TYPE_UCA2ICTL uint16_t
#define TYPE_UCA2IE uint8_t
#define TYPE_UCA2IFG uint8_t
#define TYPE_UCA2IRCTL_H uint8_t
#define TYPE_UCA2IRCTL_L uint8_t
#define TYPE_UCA2IRCTL uint16_t
#define TYPE_UCA2IV uint16_t
#define TYPE_UCA2MCTL uint8_t
#define TYPE_UCA2MCTLW_H uint8_t
#define TYPE_UCA2MCTLW_L uint8_t
#define TYPE_UCA2MCTLW uint16_t
#define TYPE_UCA2STAT uint8_t
#define TYPE_UCA2STATW uint8_t
#define TYPE_UCA2RXBUF uint8_t
#define TYPE_UCA2TXBUF uint8_t

#define TYPE_UCA3ABCTL uint8_t
#define TYPE_UCA3BRW_H uint8_t
#define TYPE_UCA3BRW_L uint8_t
#define TYPE_UCA3BRW uint16_t
#define TYPE_UCA3CTLW0_H uint8_t
#define TYPE_UCA3CTLW0_L uint8_t
#define TYPE_UCA3CTLW0 uint16_t
#define TYPE_UCA3ICTL_H uint8_t
#define TYPE_UCA3ICTL_L uint8_t
#define TYPE_UCA3ICTL uint16_t
#define TYPE_UCA3IE uint8_t
#define TYPE_UCA3IFG uint8_t
#define TYPE_UCA3IRCTL_H uint8_t
#define TYPE_UCA3IRCTL_L uint8_t
#define TYPE_UCA3IRCTL uint16_t
#define TYPE_UCA3IV uint16_t
#define TYPE_UCA3MCTL uint8_t
#define TYPE_UCA3STAT uint8_t
#define TYPE_UCA3RXBUF uint8_t
#define TYPE_UCA3TXBUF uint8_t

#define TYPE_UCB0ADDMASK_H uint8_t
#define TYPE_UCB0ADDMASK_L uint8_t
#define TYPE_UCB0ADDMASK uint16_t
#define TYPE_UCB0ADDRX_H uint8_t
#define TYPE_UCB0ADDRX_L uint8_t
#define TYPE_UCB0ADDRX uint16_t
#define TYPE_UCB0BR0 uint8_t
#define TYPE_UCB0BR1 uint8_t
#define TYPE_UCB0BRW_H uint8_t
#define TYPE_UCB0BRW_L uint8_t
#define TYPE_UCB0BRW uint16_t
#define TYPE_UCB0CTL0 uint8_t
#define TYPE_UCB0CTL1 uint8_t
#define TYPE_UCB0CTLW0_H uint8_t
#define TYPE_UCB0CTLW0_L uint8_t
#define TYPE_UCB0CTLW0 uint16_t
#define TYPE_UCB0CTLW1_H uint8_t
#define TYPE_UCB0CTLW1_L uint8_t
#define TYPE_UCB0CTLW1 uint16_t
#define TYPE_UCB0I2CIE uint8_t
#define TYPE_UCB0I2COA0_H uint8_t
#define TYPE_UCB0I2COA0_L uint8_t
#define TYPE_UCB0I2COA0 uint16_t
#define TYPE_UCB0I2COA1_H uint8_t
#define TYPE_UCB0I2COA1_L uint8_t
#define TYPE_UCB0I2COA1 uint16_t
#define TYPE_UCB0I2COA2_H uint8_t
#define TYPE_UCB0I2COA2_L uint8_t
#define TYPE_UCB0I2COA2 uint16_t
#define TYPE_UCB0I2COA3_H uint8_t
#define TYPE_UCB0I2COA3_L uint8_t
#define TYPE_UCB0I2COA3 uint16_t
#define TYPE_UCB0I2COA_H uint8_t
#define TYPE_UCB0I2COA_L uint8_t
#define TYPE_UCB0I2COA uint16_t
#define TYPE_UCB0I2CSA_H uint8_t
#define TYPE_UCB0I2CSA_L uint8_t
#define TYPE_UCB0I2CSA uint16_t
#define TYPE_UCB0ICTL_H uint8_t
#define TYPE_UCB0ICTL_L uint8_t
#define TYPE_UCB0ICTL uint16_t
#define TYPE_UCB0IE uint8_t
#define TYPE_UCB0IFG uint8_t
#define TYPE_UCB0IV uint16_t
#define TYPE_UCB0STAT uint8_t
#define TYPE_UCB0STATW_H uint8_t
#define TYPE_UCB0STATW_L uint8_t
#define TYPE_UCB0STATW uint16_t
#define TYPE_UCB0TBCNT_H uint8_t
#define TYPE_UCB0TBCNT_L uint8_t
#define TYPE_UCB0TBCNT uint16_t
#define TYPE_UCB0RXBUF uint8_t
#define TYPE_UCB0TXBUF uint8_t

#define TYPE_UCB1BR0 uint8_t
#define TYPE_UCB1BR1 uint8_t
#define TYPE_UCB1BRW_H uint8_t
#define TYPE_UCB1BRW_L uint8_t
#define TYPE_UCB1BRW uint16_t
#define TYPE_UCB1CTL0 uint8_t
#define TYPE_UCB1CTL1 uint8_t
#define TYPE_UCB1CTLW0_H uint8_t
#define TYPE_UCB1CTLW0_L uint8_t
#define TYPE_UCB1CTLW0 uint16_t
#define TYPE_UCB1I2CIE uint8_t
#define TYPE_UCB1I2COA_H uint8_t
#define TYPE_UCB1I2COA_L uint8_t
#define TYPE_UCB1I2COA uint16_t
#define TYPE_UCB1I2CSA_H uint8_t
#define TYPE_UCB1I2CSA_L uint8_t
#define TYPE_UCB1I2CSA uint16_t
#define TYPE_UCB1ICTL_H uint8_t
#define TYPE_UCB1ICTL_L uint8_t
#define TYPE_UCB1ICTL uint16_t
#define TYPE_UCB1IE uint8_t
#define TYPE_UCB1IFG uint8_t
#define TYPE_UCB1IV uint16_t
#define TYPE_UCB1STAT uint8_t
#define TYPE_UCB1RXBUF uint8_t
#define TYPE_UCB1TXBUF uint8_t

#define TYPE_UCB2BRW_H uint8_t
#define TYPE_UCB2BRW_L uint8_t
#define TYPE_UCB2BRW uint16_t
#define TYPE_UCB2CTLW0_H uint8_t
#define TYPE_UCB2CTLW0_L uint8_t
#define TYPE_UCB2CTLW0 uint16_t
#define TYPE_UCB2I2COA_H uint8_t
#define TYPE_UCB2I2COA_L uint8_t
#define TYPE_UCB2I2COA uint16_t
#define TYPE_UCB2I2CSA_H uint8_t
#define TYPE_UCB2I2CSA_L uint8_t
#define TYPE_UCB2I2CSA uint16_t
#define TYPE_UCB2ICTL_H uint8_t
#define TYPE_UCB2ICTL_L uint8_t
#define TYPE_UCB2ICTL uint16_t
#define TYPE_UCB2IE uint8_t
#define TYPE_UCB2IFG uint8_t
#define TYPE_UCB2IV uint16_t
#define TYPE_UCB2STAT uint8_t
#define TYPE_UCB2RXBUF uint8_t
#define TYPE_UCB2TXBUF uint8_t

#define TYPE_UCB3BRW_H uint8_t
#define TYPE_UCB3BRW_L uint8_t
#define TYPE_UCB3BRW uint16_t
#define TYPE_UCB3CTLW0_H uint8_t
#define TYPE_UCB3CTLW0_L uint8_t
#define TYPE_UCB3CTLW0 uint16_t
#define TYPE_UCB3I2COA_H uint8_t
#define TYPE_UCB3I2COA_L uint8_t
#define TYPE_UCB3I2COA uint16_t
#define TYPE_UCB3I2CSA_H uint8_t
#define TYPE_UCB3I2CSA_L uint8_t
#define TYPE_UCB3I2CSA uint16_t
#define TYPE_UCB3ICTL_H uint8_t
#define TYPE_UCB3ICTL_L uint8_t
#define TYPE_UCB3ICTL uint16_t
#define TYPE_UCB2IE uint8_t
#define TYPE_UCB2IFG uint8_t
#define TYPE_UCB3IV uint16_t
#define TYPE_UCB3STAT uint8_t
#define TYPE_UCB3RXBUF uint8_t
#define TYPE_UCB3TXBUF uint8_t

#define TYPE_UCSCTL0_H uint8_t
#define TYPE_UCSCTL0_L uint8_t
#define TYPE_UCSCTL0 uint16_t
#define TYPE_UCSCTL1_H uint8_t
#define TYPE_UCSCTL1_L uint8_t
#define TYPE_UCSCTL1 uint16_t
#define TYPE_UCSCTL2_H uint8_t
#define TYPE_UCSCTL2_L uint8_t
#define TYPE_UCSCTL2 uint16_t
#define TYPE_UCSCTL3_H uint8_t
#define TYPE_UCSCTL3_L uint8_t
#define TYPE_UCSCTL3 uint16_t
#define TYPE_UCSCTL4_H uint8_t
#define TYPE_UCSCTL4_L uint8_t
#define TYPE_UCSCTL4 uint16_t
#define TYPE_UCSCTL5_H uint8_t
#define TYPE_UCSCTL5_L uint8_t
#define TYPE_UCSCTL5 uint16_t
#define TYPE_UCSCTL6_H uint8_t
#define TYPE_UCSCTL6_L uint8_t
#define TYPE_UCSCTL6 uint16_t
#define TYPE_UCSCTL7_H uint8_t
#define TYPE_UCSCTL7_L uint8_t
#define TYPE_UCSCTL7 uint16_t
#define TYPE_UCSCTL8_H uint8_t
#define TYPE_UCSCTL8_L uint8_t
#define TYPE_UCSCTL8 uint16_t
#define TYPE_UCSCTL9_H uint8_t
#define TYPE_UCSCTL9_L uint8_t
#define TYPE_UCSCTL9 uint16_t

#define TYPE_UCTL uint8_t
#define TYPE_UCTL0 uint8_t
#define TYPE_UCTL1 uint8_t
#define TYPE_UCTL_0 uint8_t
#define TYPE_UCTL_1 uint8_t
#define TYPE_UMCTL uint8_t
#define TYPE_UMCTL0 uint8_t
#define TYPE_UMCTL1 uint8_t
#define TYPE_UMCTL_0 uint8_t
#define TYPE_UMCTL_1 uint8_t
#define TYPE_URCTL uint8_t
#define TYPE_URCTL0 uint8_t
#define TYPE_URCTL1 uint8_t
#define TYPE_URCTL_0 uint8_t
#define TYPE_URCTL_1 uint8_t

#define TYPE_USICCTL uint16_t
#define TYPE_USICKCTL uint8_t
#define TYPE_USICNT uint8_t
#define TYPE_USICTL0 uint8_t
#define TYPE_USICTL1 uint8_t
#define TYPE_USICTL uint16_t
#define TYPE_USISRH uint8_t
#define TYPE_USISRL uint8_t
#define TYPE_USISR uint16_t

#define TYPE_UTCTL uint8_t
#define TYPE_UTCTL0 uint8_t
#define TYPE_UTCTL1 uint8_t
#define TYPE_UTCTL_0 uint8_t
#define TYPE_UTCTL_1 uint8_t
#define TYPE_WDTCTL uint16_t

#endif  //_H_MSP430REGTYPES_H
