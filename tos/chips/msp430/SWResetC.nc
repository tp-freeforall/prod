
configuration SWResetC {
  provides interface SWReset;
}
implementation {
  components SWResetP;
  SWReset = SWResetP;
}
