
configuration SWResetC() {
  provides interface SWReset;
}
implementation {
  components WatchDogC;
  SWReset = WatchDogC;
}
