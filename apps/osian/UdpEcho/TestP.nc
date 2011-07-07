module TestP {
  uses {
    interface Boot;
    interface SplitControl as Ppp;
  }
  
} implementation {

  event void Ppp.startDone (error_t error) { }
  event void Ppp.stopDone (error_t error) { }

  event void Boot.booted() {
    error_t rc;
    rc = call Ppp.start();
  }
}
