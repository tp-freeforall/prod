  
typedef struct uartMessage{
    uint32_t freq; //actual frequency
    uint32_t time; //time elapsed
    uint16_t iter; //iteration number
    uint16_t num; //number of the fib sequence
    float current; //current being consumed
    float voltage; //battery voltage
    bool lock;
} uartMessage;
  
