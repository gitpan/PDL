
/* 

  Example C routine for how to use callext() in PDL 
  - return log x to base y vector.

  On Solaris this would be compiled:

  cc -o testcallext.so -G -Kpic testcallext.c

  to generate dynamically loadable code. For other systems
  see the man pages on your C compiler or the Perl config 
  information.

*/

#include <stdio.h>
#include <math.h>
#include "PDL/Core/pdl.h"  /* data structure defs */

/* This is the action routine */

void loglog_doit( double *x, double *y, int nvals) {

   int i;

   for (i=0; i<nvals; i++)
      x[i] = log(x[i])/log(y[i]);
}

/* 
   This is the hook routine - npdl is the number of
   arguments and *pdllist is an array of pdl* structures
*/

int loglog_ext(int npdl, pdl **pdllist) {

   pdl* x;
   pdl* y;

   /* Check pdllist */

   printf("\nExecuting C external routine\n\n");

   if (npdl != 2) {
      fprintf(stderr, "Error in number of arguments\n");
      return (0); /* Failure */
   }

   x = pdllist[0]; y = pdllist[1];
    
   if (x->datatype != PDL_D || y->datatype != PDL_D) {
      fprintf(stderr, "Error in data type of arguments\n");
      return (0); /* Failure */
   }

   if (x->nvals != y->nvals) {
      fprintf(stderr, "Number of data values unequal in arguments\n");
      return(0); /* Failure */
   }

   /* Now do the buisness! */

   loglog_doit( (double*) x->data, (double*) y->data, x->nvals); 

   return(1);  /* Success! */
}

