/*
 * Copyright (c) 2008-2012, SOWNet Technologies B.V.
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * Periodically checks for stack overflow and resets the watchdog.
 * If a stack overflow is detected, an assertion is generated.
 * 
 * Based on:
 * http://osdir.com/ml/hardware.texas-instruments.msp430.gcc.cvs/2004-06/msg00011.html
 */
module StackGuardWatchDogP {
	
	provides interface Init;
	
	uses {
		interface Boot;
		interface Timer<TMilli>;
	}
	
}

implementation {

	// we use a hardcoded number so we can compile with or without asserts
	enum {
		ASSERT_STACK_OVERFLOW = 1
	};
	
	/**
	 * A constant that is unlikely to be a valid address/a value that occours in the code.
	 */
	#define STACK_GUARD_INIT 0xcf55
	
	/** 
	 * Access to the stack pointer.
	 */
	register void* __stackptr asm("r1");

	/** 
	 * Address after the last used byte of the last segment in RAM (defined by the linker).
	 */
	extern uint8_t _end __attribute__((C)) ;

	/**
	 * A pointer to __noinit_end, but aligned to a word boundary.
	 * If the stack would grow too large, this location would be overwritten.
	 */
	uint16_t* stackGuard;
	
	/** 
	 * Initialize the stack checking mechanisms.
	 *  - fill unused memory with a pattern for manual max stack depth evaluation
	 *  - set up the stackGuard
	 */
	void stackProtectionInit() {
		uint16_t* address;
		
		// align stackGuard to the nearest word boundary if _end is on an odd address
		uint16_t p = (uint16_t) &_end;
		stackGuard = (uint16_t*) (p + (p & 1));
		
		// fill free memory with a pattern for debug purpose (see max stack depth)
		for (address = stackGuard; address < (uint16_t*) __stackptr; address++){
			*address = 0x5aa5;
		}
		
		// init stack guard
		*stackGuard = STACK_GUARD_INIT;
	}
	
	/**
	 * This checks for stack overflows. It will perform a device reset if there
	 * was an overflow.
	 * 
	 * It cannot help if the stack overflow is huge and overwrites vital
	 * variables or exeeds the amount of RAM. But it works very well if important
	 * stuff is at the beginning in the RAM and less important data at the end.
	 * That way a log message could be printed, maybe even some error recovery
	 * done. However, the simplest and probably best thing to do, is perform
	 * a device reset.
	 */
	void stackCheck() {
		if (*stackGuard != STACK_GUARD_INIT) {
			// fatal error: the stack guard was altered -> stack overflow
			// if assertions are enabled, use them; else, just reboot by tripping the watchdog
#ifdef assert
			assert(FALSE, ASSERT_STACK_OVERFLOW);
#else
			atomic WDTCTL = 0;
#endif
		}
	}

	/**
	 * Reset the watchdog timer.
	 */
	void resetWatchdog() {
		atomic WDTCTL = WDT_ARST_1000;
	}
	
	command error_t Init.init() {
		// re-enable the watchdog as soon as possible
		resetWatchdog();
		stackProtectionInit();
		return SUCCESS;
	}
	
	event void Timer.fired() {
		stackCheck();
		resetWatchdog();
	}
	
	event void Boot.booted() {
		resetWatchdog();
		call Timer.startPeriodic(500);
	}
	
}
