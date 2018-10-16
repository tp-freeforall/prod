# Setup required to use this module
#
# copy gdb_timers.py to <app>/.gdb_timers.py
# and add "source .gdb/.gdb_timers.py" to the <app>/.gdbinit file.
#

from __future__ import print_function
from binascii   import hexlify

timer_dict = {
}

def simple_timer_name(timer_id):
    t_name = 't' + str(timer_id)
    return t_name

def timer_name(timer_id):
    t_name = timer_dict.get(timer_id, None)
    if t_name == None:
        t_name = 't' + str(timer_id)
    else:
        t_name = '{}/{}'.format(t_name, timer_id)
    return t_name


class TimerTrace(gdb.Command):
    """Display TinyOS Virtual Timer Trace buffers."""
    def __init__ (self):
        super(TimerTrace, self).__init__("timerTrace", gdb.COMMAND_USER)

    def invoke (self, args, from_tty):
        start_format = '{:4d}  start {:8x}                       {:s}'
        stop_format  = '{:4d}  stop  {:8x}                       {:s}'
        usecs_format = '{:4d}        {:8x}                       {:s}'
        fired_format = '{:4d}                    fired    {:8x}  {:s}'
        end_format   = '{:4d}                    end      {:8x}  {:s}'
        delta_format = '{:4d}                    delta    {:8x}  {:s}'
        oops_format  = '{:4d}  oops  {:8x}  {:s}'

        START_LT    = int(gdb.parse_and_eval('VirtualizeTimerImplP__0__TVT_START_LT'))
        START_USECS = int(gdb.parse_and_eval('VirtualizeTimerImplP__0__TVT_START_USECS'))
        STOPPED     = int(gdb.parse_and_eval('VirtualizeTimerImplP__0__TVT_STOPPED'))
        FIRED       = int(gdb.parse_and_eval('VirtualizeTimerImplP__0__TVT_FIRED'))
        END         = int(gdb.parse_and_eval('VirtualizeTimerImplP__0__TVT_END'))
        DELTA       = int(gdb.parse_and_eval('VirtualizeTimerImplP__0__TVT_DELTA'))

        nxt  = int(gdb.parse_and_eval('VirtualizeTimerImplP__0__nxt_vt'))
        xmax = int(gdb.parse_and_eval('sizeof(VirtualizeTimerImplP__0__vtimer_trace)/'
                                      'sizeof(VirtualizeTimerImplP__0__vtimer_trace[0])'))

        last = nxt - 1
        if last < 0:
            last = xmax - 1

        cur = nxt
        if cur >= xmax: cur = 0

        while True:
            vtp        = gdb.parse_and_eval('VirtualizeTimerImplP__0__vtimer_trace[0d{}]'.format(cur))
            timer_num   = int(vtp['num'])
            ttype      = vtp['ttype']
            ttype_name = ttype.__str__().replace('VirtualizeTimerImplP__0__TVT_','')
            ttype_num  = int(ttype)
            val        = int(vtp['val'])

            if ttype == START_LT:
                print(start_format.format(timer_num, val, timer_name(timer_num)))
            elif ttype == START_USECS:
                print(usecs_format.format(timer_num, val, timer_name(timer_num)))
            elif ttype == STOPPED:
                print(stop_format.format(timer_num, val, timer_name(timer_num)))
            elif ttype == FIRED:
                print(fired_format.format(timer_num, val, timer_name(timer_num)))
            elif ttype == END:
                print(end_format.format(timer_num, val, timer_name(timer_num)))
            elif ttype == DELTA:
                print(delta_format.format(timer_num, val, timer_name(timer_num)))
            else:
                print(oops_format.format(timer_num, val, ttype_name,
                                         timer_name(timer_num)))

            if cur == last:
                break
            cur += 1
            if cur >= xmax:
                cur = 0

class DispTimers(gdb.Command):
    """Display TinyOS Virtual Timers."""
    def __init__ (self):
        super(DispTimers, self).__init__("dispTimers", gdb.COMMAND_USER)

    def invoke (self, args, from_tty):
        num = int(gdb.parse_and_eval('VirtualizeTimerImplP__0__NUM_TIMERS'))
        print('   t  state       t0        dt       max')
        for cur in range(num):
            tp = gdb.parse_and_eval('VirtualizeTimerImplP__0__m_timers[0d{}]'.format(cur))
            t0 = int(tp['t0'])
            dt = int(tp['dt'])
            fired_max = int(tp['fired_max_us'])
            oneshot = int(tp['isoneshot'])
            running = int(tp['isrunning'])
            print('  {:2d}    {:s}{:s}  {:8x}  {:8x}  {:8x}  {:s}'.format(
                cur,
                'O' if oneshot else 'o',
                'R' if running else 'r',
                t0, dt, fired_max, timer_name(cur)))

TimerTrace()
DispTimers()
