
/**
 * @author Mark Hays
 */
 
interface CrcX<t> {
  async command t crc(void* buf, uint8_t len);
  
  async command t seededCrc(t startCrc, void *buf, uint8_t len);
}

