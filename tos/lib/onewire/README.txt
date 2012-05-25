This directory contains the interfaces and implementation of a low-level
driver implementation of the one-wire protocol, as well as interfaces and
implementations of reusable onewire components that streamline the
development of user code and promote safe use of the bus.

From the perspective of a developer implementing a driver for a one-wire
device, one should create a new instance of OneWireBusClientC and use the
Resource, OneWireMaster, and OneWireDeviceInstanceManager that this exposes
to deal with the details of using the bus and maintaining the list of
currently-attached devices. The driver implementer should provide a component
which provides the OneWireDeviceType interface, this lets the discovery
process properly associate device instances with the correct bus clients.
Only when a component has obtained the resource from its OneWireBusClientC
should it use the OneWireMaster.

There is one important compiler flag to know about:

* MAX_ONEWIRE_DEVICES specifies how many physical one-wire devices, total,
  may exist on the bus at one time. If this is set to 1, then the generic
  multi-device discovery and addressing protocols will be replaced with
  specialized single-device discovery and addressing protocols. If more
  physical devices are attached at run-time than this flag specifies, then
  the last devices to be discovered will be ignored. Devices are discovered
  in ascending order by ID, LSB first.

Both of these flags indicate how much space to set aside for caches of device
IDs at the OneWireDeviceMapper (8 bytes x MAX_ONEWIRE_DEVICES) and at each
OneWireDeviceInstanceManager instance (8 bytes x MAX_ONEWIRE_DEVICES_PER_TYPE
 x number of DeviceInstanceManager instances)

On a side note, if only official devices manufactured by dallas
semiconductors/maxim(?) are in use, they are supposed to follow a standard
numbering scheme:

* The 7 least-significant bits of the ID is the family code, which indicates
  the specific type of device on the bus.

* If the most-significant bit of the least-significant byte is a 1, this
  indicates that the device is a customer-specific subtype of the type
  indicated by the family code. If this is the case, then the 12
  most-significant bits of the serial number identify the customer code.

* the implementation provided leaves this logic entirely generic. some
  optimizations would definitely be possible if all devices in use follow
  the standards to a T, but in a research setting (where developers may be
  building their own peripherals, for instance), it's not really appropriate.

TODOs
* "strict" implementation

** DeviceType is specified by family code and customer code.

** If there are no customer codes in use, or there are no two device types
   with the same family code and different customer codes, then
   instanceManagers have fixed overhead (just store the first device index
   and the number of devices for the type)

* ID comparison C function in OneWireMasterP, declaration in OneWireMaster.h
  (since comparing 64-bit ints in tinyos is not straightforward) 

* port original TestDs1825 code to use generic onewire code
