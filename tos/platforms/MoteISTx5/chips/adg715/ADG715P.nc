module ADG715P {
  provides interface Init as DefaultInit;  
  uses {
    interface StdControl;
    interface I2CPacket<TI2CBasicAddr>;
    //interface Msp430UsciError;
  }
}
implementation{
	
 task void stop(){
	  call StdControl.stop();
  }
		
   
  command error_t DefaultInit.init() {
    uint8_t data = 0xFF;
    
    call StdControl.start(); //request I2C module

    //0x48 -  10010 0  0
    //        MSBs  A1 A0
    //0x7E -  all switches on (from D2 to D7)
    return call I2CPacket.write(I2C_START | I2C_STOP, 0x48, 1, &data);		//Turn all switches on
  }

  async event void I2CPacket.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data){ 
    post stop();
  }
  
  async event void I2CPacket.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data){}
}
