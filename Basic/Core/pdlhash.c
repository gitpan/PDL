
/* pdlhash.c - functions for manipulating pdl hashes */


#include "pdl.h"      /* Data structure declarations */
#include "pdlcore.h"  /* Core declarations */

/* Free the data if possible; used by mmapper */
void pdl_freedata (pdl *a) {
	if(a->datasv) {
		SvREFCNT_dec(a->datasv);
		a->datasv=0;
		a->data=0;
	} else if(a->data) {
		die("Trying to free data of untouchable (mmapped?) pdl");
	}
}

/*  Utility to change the size of the data compt of a pdl */

void pdl_grow (pdl* a, int newsize) {

   SV* foo;
   HV* hash;
   int nbytes;
   int ncurr;
   STRLEN len;

   if(a->state & PDL_DONTTOUCHDATA) {
   	die("Trying to touch data of an untouchable (mmapped?) pdl");
   }

   if(a->datasv == NULL)
   	a->datasv = newSVpv("",0);

   foo = a->datasv;

   nbytes = newsize * pdl_howbig(a->datatype);
   ncurr  = SvCUR( foo );
   if (ncurr == nbytes) 
      return;    /* Nothing to be done */

   if (ncurr>nbytes)  /* Nuke back to zero */
      sv_setpvn(foo,"",0);

   if(nbytes > 100000000) {
   	die("Probably false alloc of over 100MB piddle!");
   }
      
   SvGROW ( foo, nbytes );   SvCUR_set( foo, nbytes );
   a->data = (void *) SvPV( foo, len ); a->nvals = newsize;
}

/* unpack dims array into Hash */

void pdl_unpackarray ( HV* hash, char *key, int *dims, int ndims ) {

   AV*  array;
   int i;

   array = newAV();
   hv_store(hash, key, strlen(key), newRV( (SV*) array), 0 );
  
   if (ndims==0 )
      return;

   for(i=0; i<ndims; i++)
         av_store( array, i, newSViv( (IV)dims[i] ) );
} 

