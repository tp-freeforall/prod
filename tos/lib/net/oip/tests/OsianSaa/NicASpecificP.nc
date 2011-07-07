/** Test module to provide NIC-specific implementations that can be
 * contrasted with the default implementation. */
module NicASpecificP {
  uses {
    interface NetworkInterface;
  }
  provides {
    interface Init;
    interface NetworkInterfaceIdentifier;
  }
} implementation {

  static uint8_t interfaceIdentifier_[] = { 0xfe, 0xdc, 0xba, 0x98,
                                            0x76, 0x54, 0x32, 0x10 };

  command error_t Init.init ()
  {
    call NetworkInterface.setInterfaceState(IFF_POINTTOPOINT);
    return SUCCESS;
  }

  event void NetworkInterface.interfaceState (oip_nic_state_t state) { }

  command const uint8_t* NetworkInterfaceIdentifier.interfaceIdentifier ()
  {
    return (const uint8_t*)interfaceIdentifier_;
  }

  command uint8_t NetworkInterfaceIdentifier.interfaceIdentifierLength_bits ()
  {
    return 8 * sizeof(interfaceIdentifier_);
  }

}

