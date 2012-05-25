interface HplMsp430UsciB {
  async command uint8_t  getI2Cie();
  async command void     setI2Cie(uint8_t v);
  async command uint16_t getI2Coa();
  async command void     setI2Coa(uint16_t v);
  async command uint16_t getI2Csa();
  async command void     setI2Csa(uint16_t v);
}
