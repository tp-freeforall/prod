Demonstrate use of RFC868 Time Protocol service.

Ensure you have a BridgePppRadio node running somewhere to give access to
the radio network.

Run:

   python timeserver.py

in a dedicated window.  This program listens on the radio network NIC for
multicast packets, and sends the current date and time to the soliciting
node.

Build and install the program on one or more nodes.  On boot, they will
attempt to contact the timeserver to initialize their real-time clocks.
Having done so, they will print the current time to their console once per
minute.

Each node will also support the RFC868 Time Protocol.  Use the standard Unix
utility rdate to query its time via UDP:

   rdate -u fe80::b2c8:ad64:307:e8df%ppp0

You may find it amusing to bracket such a query with retrival of the host
time, to see how far it drifts.

linux[122]$ date ; rdate -u fe80::b2c8:ad64:307:e8df%ppp0 ; date
Thu Nov 18 15:40:09 CST 2010
rdate: [fe80::b2c8:ad64:307:e8df%ppp0]  Thu Nov 18 15:40:12 2010

Thu Nov 18 15:40:09 CST 2010

Don't expect an exact match, since the resolution of the time is one second,
and there's some latency involved that is not being corrected.  If you're
within two seconds or so, you're doing well.

Try using the withxt1 extra when building to enable or disable the external
crystal, if your SuRF board has one, to see how that affects long-term
stability.
