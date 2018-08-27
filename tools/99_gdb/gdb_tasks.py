# Setup required to use this module
#
# copy gdb_tasks.py to <app>/.gdb_tasks.py
# and add "source .gdb/.gdb_tasks.py" to the <app>/.gdbinit file.
#

from __future__ import print_function
from binascii   import hexlify

task_dict = {
}

def task_name(task_id):
    t_name = task_dict.get(task_id, None)
    if t_name == None:
        t_name = 't' + str(task_id)
    else:
        t_name = '{}/{}'.format(t_name, task_id)
    return t_name


post_spaces  = 40
post_format  = '{:3d}{}{:08x} {:5s} {}'
run_format   = '{:3d}   {:08x}  {:5s}  {}'
end_format   = '{:3d}   {:08x}  {:5s}  {:18s}  0x{:x} ({}, {:5.3f})'
oops_format  = '{:3d}   {:08x}  {:5s}  {} oops'


class TaskTrace(gdb.Command):
    """Display the TinyOS Task Trace."""
    def __init__ (self):
        super(TaskTrace, self).__init__("task_trace", gdb.COMMAND_USER)

    def invoke (self, args, from_tty):
        last_run = 0

        POST  = int(gdb.parse_and_eval('SchedulerBasicP__TT_POST'))
        RUN   = int(gdb.parse_and_eval('SchedulerBasicP__TT_RUN'))
        END   = int(gdb.parse_and_eval('SchedulerBasicP__TT_END'))

        NUM_TASKS = int(gdb.parse_and_eval('SchedulerBasicP__NUM_TASKS'))

        nxt  = int(gdb.parse_and_eval('SchedulerBasicP__nxt_tt'))
        xmax = int(gdb.parse_and_eval('sizeof(SchedulerBasicP__task_trace)/'
                                      'sizeof(SchedulerBasicP__task_trace[0])'))

        last = nxt - 1
        if last < 0:
            last = xmax - 1

        cur = nxt
        if cur >= xmax: cur = 0

        while True:
            ttp        = gdb.parse_and_eval('SchedulerBasicP__task_trace[0d{}]'.format(cur))
            task_num   = int(ttp['num'])
            ttype      = ttp['ttype']
            ttype_name = ttype.__str__().replace('SchedulerBasicP__TT_','')
            ttype_num  = int(ttype)
            val        = int(ttp['val'])

            if ttype == POST:
                print(post_format.format(cur, post_spaces*' ', val, ttype_name, task_name(task_num)))
            elif ttype == RUN:
                last_run = val
                print(run_format.format(cur, val, ttype_name, task_name(task_num)))
            elif ttype == END:
                if last_run == 0:
                    delta = 0
                else:
                    delta = val - last_run
                    last_run = 0
                print(end_format.format(cur, val, ttype_name,
                                        task_name(task_num),
                                        delta, delta, delta/1024.))
            else:
                print(oops_format.format(cur, val, ttype_name, task_name(task_num)))

            if cur == last:
                break
            cur += 1
            if cur >= xmax:
                cur = 0

TaskTrace()
