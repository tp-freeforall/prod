
#define FIBONACCI_A 0
#define FIBONACCI_B 1

module TasksP {
  uses interface Timer<TMilli> as Timer0;
  provides interface Tasks;
  uses interface Tasks as TaskDone;
}
implementation {
 
  uint32_t a = FIBONACCI_A;
  uint32_t b = FIBONACCI_B;
  uint32_t i = 0;
  uint32_t sum = 0;
  uint16_t num_iterations;
  uint16_t totalIterations;
  uint32_t time_deadline;
  bool deadline_miss=FALSE;

  //tasks
  task void fibonacci(void){
  /**
   * Here is the single iteration.
   * On each iteration it performs the parameter @iterations is decremented.
   *  
   */
   // printf("N=%d, %lu\n", num_iterations, a);
    sum = a + b;
    a = b;
    b = sum;    
	//signal iteration done
	num_iterations--;
	signal TaskDone.FibonacciIterationDone();
  }
  
  //commands
  command error_t Tasks.getFibonacci(uint16_t iterations, uint32_t deadline){
    deadline_miss = FALSE;
    num_iterations = iterations;
    totalIterations = iterations;
    time_deadline = deadline;
    
      call Timer0.startOneShot(deadline);

      //printf("Posted fibonacci\nIterations:%d, deadline: %lu, deadline miss: %d\n",num_iterations, time_deadline, deadline_miss);
      post fibonacci();
  
    return SUCCESS;
  }
  
  //events
  event void TaskDone.FibonacciIterationDone(){
    uint32_t t0, now;
	  if(num_iterations && !deadline_miss)
	    post fibonacci();
	  else{
		if(!deadline_miss){
		  call Timer0.stop();
		  t0=call Timer0.gett0();
		  now=call Timer0.getNow();
      //printf("fibonacci is done in: %lu\n", now-t0);
      signal Tasks.FibonacciDone(totalIterations, t0, now, SUCCESS);
	      }       
	    }
  }
  
  event void Timer0.fired() { 
	  //deadline missed!
	  uint32_t now,t0;
	  deadline_miss = TRUE;
      t0=call Timer0.gett0();
      now=call Timer0.getNow();
      
     // printf("timer fired in fibonacci: %lu\n", now-t0);
      signal Tasks.FibonacciDone(num_iterations, now, t0, FAIL);
  }
  
  event void TaskDone.FibonacciDone(uint16_t iterations, uint32_t startTime, uint32_t endTime, error_t status){ }
  
}
