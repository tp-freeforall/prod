configuration TasksC {
	provides interface Tasks;
}
implementation {
	
  components TasksP, SerialPrintfC;
  Tasks = TasksP.Tasks;
  
  components new TimerMilliC() as Timer0;
  TasksP.Timer0 -> Timer0;
}
