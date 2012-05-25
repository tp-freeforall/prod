interface HplMsp430UsciA{
  async command uint8_t getAbctl();
  async command void setAbctl(uint8_t v);
  async command uint8_t getIrtctl();
  async command void setIrtctl(uint8_t v);
  async command uint8_t getIrrctl();
  async command void setIrrctl(uint8_t v);
}
