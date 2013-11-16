/**
 * Copyright @ 2008 Eric B. Decker
 * @author Eric B. Decker
 */

configuration TraceC {
  provides interface Trace;
}

implementation {
  components TraceP;
  Trace = TraceP;

#ifdef TRACE_USE_PLATFORM
  components PlatformC;
  TraceP.Platform -> PlatformC;
#else
#ifdef TRACE_MICRO
  components LocalTimeMicroC;
  TraceP.LocalTime -> LocalTimeMicroC;
#else
  components LocalTimeMilliC;
  TraceP.LocalTime -> LocalTimeMilliC;
#endif
#endif  /* TRACE_USE_PLATFORM */

  components PanicC;
  TraceP.Panic -> PanicC;
}
