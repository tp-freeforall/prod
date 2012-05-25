#!/bin/sh
#
# Given implementations for USCI_A0 and USCI_B0, generate equivalent
# configurations for the higher-numbered module instances.
#
# Much of the USCI implementation is identical except for varying
# based on the instance number of the module to which a component
# belongs.  To avoid implementation divergence, we maintain and evolve
# only one of each type of component, and generate the remainder from
# that template.
#
# @author Peter A. Bigot <pab@peoplepowerco.com>
# @author Eric B. Decker <cire831@gmail.com>
#
# UART is implemented in USCI_A modules
# I2C  is implemented in USCI_B modules
# SPI  is implemented in USCI_A and USCI_B modules

# List of tags for USCI_Ax modules.  A0 is the master for A
# modules and Uart.

A_MODULES='A0 A1 A2 A3'

# List of tags for USCI_Ax modules.  B0 is the master for B
# modules and Spi (B and A) and I2C modules.

B_MODULES='B0 B1 B2 B3'

# Initialize a file that will contain a list of all generated files,
# so we can remove them during basic maintenance.  Their presence
# clutters the directory and makes it difficult to see what's really
# important.

rm -f generated.lst

clone_module () {
  source="$1" ; shift
  target="$1" ; shift
  basis="$1" ; shift
  clone="$1" ; shift
  ( cat<<EOText
/* DO NOT MODIFY
 * This file cloned from ${source} for ${clone} */
EOText
    cat ${source} \
      | sed -e "s@${basis}@${clone}@g"
  ) > ${target}
  echo ${target} >> generated.lst
}

# The base USCI module capability is independent of module type;
# we use A0 as the template.
for m in ${A_MODULES} ${B_MODULES} ; do
  if [ A0 = "${m}" ] ; then
    continue
  fi
  clone_module HplMsp430UsciInterruptsA0P.nc "HplMsp430UsciInterrupts${m}P.nc" A0 "${m}"
  clone_module Msp430UsciA0P.nc "Msp430Usci${m}P.nc" A0 "${m}"
done

# Clone the mode-specific configurations for a given module type
clone_mode_modules () {
  mode="${1}" ; shift
  basis="${1}" ; shift
  for source in Msp430Usci${mode}${basis}?.nc ; do
    for clone in "${@}" ; do
      target=`echo ${source} | sed -e "s@${basis}@${clone}@g"`
      clone_module ${source} ${target} ${basis} ${clone}
    done
  done
}

# Clone the mode-specific configurations
clone_mode_modules Uart ${A_MODULES}
clone_mode_modules Spi ${B_MODULES} ${A_MODULES}
clone_mode_modules I2C ${B_MODULES}
