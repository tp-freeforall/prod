#define MOTEIST_NODE_ID 1 //for MoteIST
#define MICA_NODE_ID 2
#define ITERATIONS 200
#define DEADLINE 500 //0.1 sec
#define PERIOD 1000 //1 sec


enum {
  AM_BLINKTORADIO = 6,
  TIMER_PERIOD_MILLI = 1000,
  DEADLINE_MISS = 4,
  DEADLINE_MET = 3,
  STARTED = 2,
  START = 1,
  REQUEST = 0
};

typedef nx_struct MicaMsg {
  nx_uint16_t nodeid; //node id
  nx_uint8_t state; // state of operation
  nx_uint8_t task_i; //number of iterations to perform the task: passing 0 means deadline missed
  nx_uint16_t deadline; //deadline for the task: passing 0 means this is a request to start
  nx_uint16_t missed; //number of missed deadlines so far
  nx_uint16_t met;
  
} MicaMsg;

typedef nx_struct MoteISTMsg {
  nx_uint16_t nodeid; //node id
  nx_uint16_t state; 
} MoteISTMsg;


/*
 * The MicaMsg struct
 * 
 * parameter @state has the state of mica's operation such as:
 * 0 - requesting
 * 1 - start order
 * 2 - deadline met
 * 3 - deadline missed
 */
