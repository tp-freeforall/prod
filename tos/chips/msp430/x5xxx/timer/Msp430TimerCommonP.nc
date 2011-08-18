
module Msp430TimerCommonP @safe() {
  provides {
#if defined(__MSP430_HAS_T0A3__) || defined(__MSP430_HAS_T0A5__)
    interface Msp430TimerEvent as VectorTimer0_A0;
    interface Msp430TimerEvent as VectorTimer0_A1;
#endif /* __MSP430_HAS_T0A3__ || __MSP430_HAS_T0A5__ */

#if defined(__MSP430_HAS_T0B7__)
    interface Msp430TimerEvent as VectorTimer0_B0;
    interface Msp430TimerEvent as VectorTimer0_B1;
#endif /* __MSP430_HAS_T0B7__ */

#if defined(__MSP430_HAS_T1A2__) || defined(__MSP430_HAS_T1A3__) || defined(__MSP430_HAS_T1A5__)
    interface Msp430TimerEvent as VectorTimer1_A0;
    interface Msp430TimerEvent as VectorTimer1_A1;
#endif /* __MSP430_HAS_T1A2__ || __MSP430_HAS_T1A3__ || __MSP430_HAS_T1A5__ */

#if defined(__MSP430_HAS_T2A3__)
    interface Msp430TimerEvent as VectorTimer2_A0;
    interface Msp430TimerEvent as VectorTimer2_A1;
#endif /* __MSP430_HAS_T2A3__ */
  }
}
implementation {
#if defined(__MSP430_HAS_T0A3__) || defined(__MSP430_HAS_T0A5__)
  TOSH_SIGNAL(TIMER0_A0_VECTOR) { signal VectorTimer0_A0.fired(); }
  TOSH_SIGNAL(TIMER0_A1_VECTOR) { signal VectorTimer0_A1.fired(); }
#endif /* __MSP430_HAS_T0A3__ || __MSP430_HAS_T0A5__ */

#if defined(__MSP430_HAS_T0B7__)
  TOSH_SIGNAL(TIMER0_B0_VECTOR) { signal VectorTimer0_B0.fired(); }
  TOSH_SIGNAL(TIMER0_B1_VECTOR) { signal VectorTimer0_B1.fired(); }
#endif /* __MSP430_HAS_T0B7__ */

#if defined(__MSP430_HAS_T1A2__) || defined(__MSP430_HAS_T1A3__) || defined(__MSP430_HAS_T1A5__)
  TOSH_SIGNAL(TIMER1_A0_VECTOR) { signal VectorTimer1_A0.fired(); }
  TOSH_SIGNAL(TIMER1_A1_VECTOR) { signal VectorTimer1_A1.fired(); }
#endif /* __MSP430_HAS_T1A2__ || __MSP430_HAS_T1A3__ || __MSP430_HAS_T1A5__ */

#if defined(__MSP430_HAS_T2A3__)
  TOSH_SIGNAL(TIMER2_A0_VECTOR) { signal VectorTimer2_A0.fired(); }
  TOSH_SIGNAL(TIMER2_A1_VECTOR) { signal VectorTimer2_A1.fired(); }
#endif /* __MSP430_HAS_T2A3__ */
}
