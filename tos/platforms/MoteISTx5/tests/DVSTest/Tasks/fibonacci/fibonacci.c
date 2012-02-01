/**
 * You'll notice that we need to include a header file that
 * contains functions we need to use. Being a compiled language,
 * it's inefficient to include functions that aren't needed.
 * stdio.h contains functions for reading from and writing to the console
 */

#include <stdio.h>

/**
 * In C, the program executes the main function. You should also take note
 * that we must declare a return type for the function. In this case, it's
 * an integer, and we return 0 to indicate successful completion of the 
 * program.
 */

int fibonacci(unsigned long int n);

int main ()
{
  /* Notice that we need to declare our variables, and their type */

  unsigned long int n;

  /* printf prints a formated string to the stdout */

  printf("\nHow many numbers of the sequence would you like?\n");

  /* scanf reads a formated string from the stdin. We are expecting an integer here. */

  scanf("%d",&n);

  /* Here we call the fibonacci function */

  fibonacci(n);

  /* Finally, return 0 */

  return 0;
}

/**
 * This is the simple fibonacci sequence generator. Notice also, we
 * declare the type of variable we expect to be passed to the function.
 */

int fibonacci(unsigned long int n)
{
  /**
   * Here we declare and set our variables.
   */
  long unsigned int a = 0;
  long unsigned int b = 1;
  long unsigned int sum;
  int i;

  /**
   * Here is the standard for loop. This will step through, performing the code
   * inside the braces until i is equal to n.
   */
  for (i=0;i<n;i++)
  {
    printf("%ull\n",a);
    sum = a + b;
    a = b;
    b = sum;
  }
  return 0;
}
