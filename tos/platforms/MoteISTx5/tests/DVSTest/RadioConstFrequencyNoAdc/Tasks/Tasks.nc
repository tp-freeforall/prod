interface Tasks{
	
	/*
	 * Calculates the fibonacci sequence numbers to the number of the parameter iterations.
	 * The param deadline is the deadline in miliseconds.
	 */
	
	error_t command getFibonacci(uint16_t iterations, uint32_t deadline);
    
    /*
    *this event is used for each iteration done in TasksP
    */
    
    event void FibonacciIterationDone(void);
    /*
    *This signals the stop of the interations for the fibonacci sequence numbers
    * returns
    * num_iterations: the remanining iterations at the time the event was signaled, if any.
    * actualTime: the actual time the event was signaled
    * status: FAIL if it missed the deadline
    *         SUCCESS if it has finished before deadline
    */
	event void FibonacciDone(uint16_t iterations, uint32_t elapsedTime, error_t status); 
}
