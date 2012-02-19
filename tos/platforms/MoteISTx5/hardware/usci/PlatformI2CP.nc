module PlatformI2CP {
  provides interface StdControl;
  uses     interface Resource;
}
implementation {

  command error_t StdControl.start(){
    return call Resource.immediateRequest();
  }

  command error_t StdControl.stop(){
    return call Resource.release();
  }

  event void Resource.granted() { }
}
