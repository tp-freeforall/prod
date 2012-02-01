#include <stdio.h>

module ClientP @safe(){
  uses interface Settings as FlashSettings;
}
 
implementation
{ 
  uint8_t data[] = {9,33,3,2,5,6,9,25};
  
  event void FlashSettings.requestLogin(){
    error_t status;
    uint8_t i;
    
    printf("Second Client: ");
    printf("Request login.\n");
   
    status = call FlashSettings.login((void*) data, sizeof(data)*sizeof(uint8_t));
    switch (status){
	  case EINVAL:{
        printf("Second Client Request Login -> EINVAL.\n");
        break;
      }
      case SUCCESS:{
	    /*printf("Second Client storing to flash: ");
	    for(i=0; i<sizeof(data); i++){
	      data[i] = 22;
	      printf("%d ", data[i]);
	    }  
	    if(call FlashSettings.store() == SUCCESS){
	      printf("Second Client: ");
	      printf("Data is now loaded from flash.\n");
	    }*/
	    printf("Second Client loaded from flash: ");
	    for(i=0; i<sizeof(data); i++)
	      printf("%d ", data[i]);
	    printf("\n ");
	    
	    break;
      }
      case FAIL:{
		printf("The client cannot login at this time because you weren't paying attention to the instructions. :).\n");
	    break;
      }
      
      default:
       //error
    }
  }
}
