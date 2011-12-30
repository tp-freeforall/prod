module PlatformSerialUsciP {
	provides interface StdControl;
	provides interface AsyncStdControl;
	provides interface Msp430UartConfigure;
	uses interface Resource;
}

implementation {

	#ifndef PLATFORM_SERIAL_BAUD_RATE
	#define PLATFORM_SERIAL_BAUD_RATE 57600
	#endif
	
	// build up, for example, UBR_4MIHZ_57600
	#define CONCAT2(a, b, c, d) a ## b ## c ## d
	#define CONCAT(a, b, c, d) CONCAT2(a, b, c, d)
	
	msp430_uart_union_config_t msp430_uart_config = {{
		ubr: CONCAT(UBR_, SMCLK_MIHZ, MIHZ_, PLATFORM_SERIAL_BAUD_RATE),
		umctl: CONCAT(UMCTL_, SMCLK_MIHZ, MIHZ_, PLATFORM_SERIAL_BAUD_RATE),
		ucmode: 0,	// UART mode
		ucspb: 0,		// 1 stop bit
		uc7bit: 0,		// 8 data bits
		ucpen: 0,		// no parity
		ucssel: 0x02,	// SMCLK
	}};

	command error_t StdControl.start(){
		return call Resource.immediateRequest();
	}
	
	command error_t StdControl.stop(){
		call Resource.release();
		return SUCCESS;
	}
	
	async command error_t AsyncStdControl.start(){
		return call Resource.immediateRequest();
	}
	
	async command error_t AsyncStdControl.stop(){
		call Resource.release();
		return SUCCESS;
	}
	
	event void Resource.granted(){}

	async command const msp430_uart_union_config_t* Msp430UartConfigure.getConfig() {
		return &msp430_uart_config;
	}
	
}
