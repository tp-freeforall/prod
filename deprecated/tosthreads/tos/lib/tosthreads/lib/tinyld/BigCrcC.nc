configuration BigCrcC {
  provides interface BigCrc;
}

implementation {
  components Crc16C, BigCrcP;
  BigCrc = BigCrcP;
  BigCrcP.Crc16 -> Crc16C;
}
