/** Test module to provide NIC-specific implementations that can be
 * contrasted with the default implementation. */
module NicASpecificP {
  uses {
    interface NetworkInterface;
  }
  provides {
    interface Init;
    interface NicASpecific;
    interface NetworkLinkInterface;
    interface NetworkInterfaceIdentifier;
  }
} implementation {

  const void* lastMessage_;
  unsigned int lastMessageLength_;
  static uint8_t interfaceIdentifier_ = 0xA5;

  typedef struct link_header_t{
      uint16_t source_family;
      uint16_t dest_family;
      uint16_t length;
  } link_header_t;

  command error_t Init.init ()
  {
    call NetworkInterface.setInterfaceState(IFF_POINTTOPOINT);
    return SUCCESS;
  }

  event void NetworkInterface.interfaceState (oip_nic_state_t state) { }

  command int NetworkLinkInterface.storeLinkHeader (const struct sockaddr* saddr,
                                                    const struct sockaddr* daddr,
                                                    unsigned int len,
                                                    uint8_t* dst)
  {
    link_header_t* lhp = (link_header_t*)dst;
    if (0 != lhp) {
      lhp->source_family = saddr->sa_family;
      lhp->dest_family = daddr->sa_family;
      lhp->length = len;
    }
    return sizeof(*lhp);
  }
  
  command error_t NetworkLinkInterface.transmit (const void* message,
                                                 unsigned int len)
  {
    lastMessage_ = message;
    lastMessageLength_ = len;
    return SUCCESS;
  }

  command const uint8_t* NetworkInterfaceIdentifier.interfaceIdentifier ()
  {
    return (const uint8_t*)&interfaceIdentifier_;
  }

  command uint8_t NetworkInterfaceIdentifier.interfaceIdentifierLength_bits ()
  {
    return 8 * sizeof(interfaceIdentifier_);
  }

  command void NicASpecific.provideRxMetadata (const void* rx_metadata)
  {
    signal NetworkLinkInterface.provideRxMetadata(rx_metadata);
  }

}

