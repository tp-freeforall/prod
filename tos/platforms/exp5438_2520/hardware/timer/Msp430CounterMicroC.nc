/*
 * Copyright (c) 2011, 2013, Eric B. Decker
 * Copyright (c) 2010, People Power Co.
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

/**
 * Msp430CounterMicroC provides the standard 1 MiHz counter for the MSP430.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * @see  Please refer to TEP 102 for more information about this component and its
 *          intended use.
 *
 * The cc430f5137 and the msp430f5138{,a} (both x5 family) have at a minimum the
 * T0A5 and T1A3 timer h/w.  We assign T1A to the 32KiHz timer and T0A to the
 * 1 MiHz (TMicro) timer (see Msp430CounterMicro).
 *
 * We are overriding the default set up which is TA0 -> 32KiHz and TA1 -> 1MHz.
 */

configuration Msp430CounterMicroC {
  provides interface Counter<TMicro,uint16_t> as Msp430CounterMicro;
}
implementation {
  components Msp430TimerC,
    new Msp430CounterC(TMicro) as Counter;

  Msp430CounterMicro = Counter;
  Counter.Msp430Timer -> Msp430TimerC.Timer0_A;
}
