
configuration WatchDogC() {
  provides interface SWReset;
}
implementation {
  components WatchDogP;
  SWReset = WatchDogP;
}
