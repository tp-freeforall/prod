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

  components LocalTimeMilliC, PanicC;
  TraceP.LocalTime -> LocalTimeMilliC;
  TraceP.Panic -> PanicC;
}
