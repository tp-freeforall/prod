/* Copyright (c) 2010 People Power Co.
 * All rights reserved.
 *
 * This open source code was developed with funding from People Power Company
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the People Power Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * PEOPLE POWER CO. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 */

/** Specification for the DisplayCode capability
 *
 * A one-byte value indicates a specific code.  Each code is tied to a
 * particular condition, such as UART overflow, framing error, lack of
 * available transmission memory, etc.
 * 
 * The implementation assumes five LEDs are available for display: one
 * is used as a signal, while four indicate a binary value.
 * 
 * A task associated with a timer is normally used to display the active
 * codes.  For each code that is enabled, the behavior is:
 *  + Alternately flash a marker LED and the code value at [4] Hz for [2]
 *    seconds
 *  + Display the value one nybble at a time, starting from the highest nybble
 *    to be displayed.  When a high-order nybble within a byte is displayed,
 *    the marker LED is lit.  Each nybble is displayed for a duration of [2]
 *    seconds
 * 
 * As a special case, the "lock" method invoked on a particular code executes
 * the display sequence for that code alone, in asynchronous (but non-atomic)
 * context.  Invocation of this command does not return.  This is suitable to
 * mark fatal conditions.
 *
 * Note that we do not provide a component that provides the DisplayCode
 * interface for a code determined using the nesC unique() function.  Since
 * codes are interpreted by users, the numeric value should be documented and
 * used explicitly, so that it does not change when components are added to or
 * removed from the application.  It is the application developers
 * responsibility to ensure that the same code is not used for multiple
 * situations.
 * 
 * @note If the application is compiled with the NDEBUG macro defined, the
 * entire DisplayCode facility is stubbed out and will have no effect.  Be
 * aware that this includes the DisplayCode.lock() facility: in this case
 * execution will proceed with the code following the lock invocation.
 *
 * @note Code 0 has special handling.  If it is enabled, then its value is
 * displayed in the LEDs whenever no other code is enabled (the low bits of
 * the value are displayed regardless of the configured width).  When other
 * codes are enabled, it is displayed in the normal way.  This allows a
 * pass-through use of MultiLed without interfering with code displays.
 *
 * Inhibiting DisplayCode
 * ----------------------
 *
 * To enable non-code use of the LEDs in special modes without corrupting the
 * DisplayCode configuration, the StdControl interface is used to enable and
 * disable this functionality.  Unless the DisplayCodeC component is started,
 * all operations on individual display code are inhibited *except* for
 * DisplayCode.lock(), which functions as it would if the component were
 * started.
 *
 * The DisplayCode facility is automatically started on system initialization,
 * in SoftwareInit.  Components that have it linked in may use it assuming it
 * is available, and should not start or stop it when they themelves are
 * started or stopped.  An application that uses DisplayCode only for errors
 * rather than for general status information should explicitly stop it during
 * the Booted event, and explicitly start it at the point where the error is
 * detected.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
configuration DisplayCodeC {
  provides {
    interface StdControl;
    interface DisplayCode[ uint8_t code ];
  }
} implementation {
  components DisplayCodeP;
  DisplayCode = DisplayCodeP;
  StdControl = DisplayCodeP;

  components MainC;
  MainC.SoftwareInit -> DisplayCodeP;

  components DisplayCodeExternP;
  DisplayCodeExternP.DisplayCode -> DisplayCodeP;
  
#if ! NDEBUG
  components LedC;
  DisplayCodeP.MultiLed -> LedC;
  DisplayCodeP.Marker -> LedC.Led4;

  components new Alarm32khz32C();
  DisplayCodeP.Alarm32khz -> Alarm32khz32C;
#endif /* NDEBUG */
  
}
