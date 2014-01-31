/*
 * Copyright (c) 2010, Eric B. Decker
 * All rights reserved.
 */

interface BootParams {
  async command uint16_t getBootCount();
  async command uint8_t  getMajor();
  async command uint8_t  getMinor();
  async command uint8_t  getBuild();
}
