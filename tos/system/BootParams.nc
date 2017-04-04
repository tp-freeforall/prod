/*
 * Copyright (c) 2010, 2017 Eric B. Decker
 * All rights reserved.
 */

interface BootParams {
  async command uint16_t getBootCount();
  async command uint8_t  getMajor();
  async command uint8_t  getMinor();
  async command uint16_t getBuild();
}
