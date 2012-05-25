README for Clock
Author/Contact: cire831@gmail.com

Description:

Clock is simple test code for checking the 1 mis (possibly ms) ticker
vs. the 1 uis (possibly us) ticker.

The program is intended to be run using a JTAG and breakpoints put
in strategic places.    This can easily be modified to output either
via a network stack or direct printf.

Whether the tickers are binary or decimal units is determined by the
platform and its constraints.  It is recommended that the same kind
of units be used, either both binary or both decimal units.
