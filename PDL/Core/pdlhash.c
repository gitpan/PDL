
/* pdlhash.c - functions for manipulating pdl hashes */


#include "pdl.h"      /* Data structure declarations */
#include "pdlcore.h"  /* Core declarations */


/* Retrieve cached pdl value from $$x{PDL} */

pdl* pdl_getcache( HV* hash ) {
   int address=0;
   SV** foo;

   if (hv_exists(hash, "PDL", strlen("PDL"))) {
      foo = hv_fetch( hash, "PDL", strlen("PDL"), 0);
      if (foo == NULL)
         croak("Unexpected error accessing Object 'PDL' component");
      address = SvIV(*foo);
   }
   return ( address==0? (pdl*) NULL : (pdl*) address );
}


/*  Utility to change the size of the data compt of a pdl */

void pdl_grow (pdl* a, int newsize) {

   SV* foo;
   HV* hash;
   int nbytes;
   int ncurr;
   int len;

   nbytes = newsize * pdl_howbig(a->datatype);
   ncurr  = SvCUR( (SV*)a->sv );
   if (ncurr == nbytes) 
      return;    /* Nothing to be done */

   hash = (HV*) SvRV( (SV*) a->sv ); 
   foo = pdl_getKey(hash, "Data");

   if (ncurr>nbytes)  /* Nuke back to zero */
      sv_setpvn(foo,"",0);
      
   SvGROW ( foo, nbytes );   SvCUR_set( foo, nbytes );
   a->data = SvPV( foo, len ); a->nvals = newsize;
}

/*  Utility to change the value of the data type field of a pdl  */

void pdl_retype (pdl* a, int newtype) {

   SV* foo;
   HV* hash; 

   if (a->datatype == newtype) 
      return;  /* Nothing to be done */

   hash = (HV*) SvRV( (SV*) a->sv ); 
   foo = pdl_getKey(hash, "Datatype");
   sv_setiv(foo, (IV) newtype);
   a->datatype = newtype;
}



/* Fills the cache associated with a PDL sv with new values from
   the PDL perl data strcuture */

pdl* pdl_fillcache( HV* hash ) {

   SV**   foo;
   SV *   bar;
   STRLEN len;
   int*   dims;
   int*   incs;
   int    ndims, nincs;
   pdl* thepdl = pdl_getcache( hash );

   if (thepdl == NULL ) { /* Doesn't exist so create out of the void */
      thepdl = pdl_new();
      hv_store(hash, "PDL", strlen("PDL"), newSViv((I32) thepdl), 0);
   }

   /* Transfer data items to return value */

   thepdl->data = SvPV(pdl_getKey( hash, "Data" ), len);

   thepdl->datatype = (int) SvNV( pdl_getKey( hash, "Datatype" ) ) ;

   thepdl->nvals = len / pdl_howbig(thepdl->datatype); 

   /* Copy dimensions info */

   foo = hv_fetch( hash, "Dims", strlen("Dims"), 0);
   if (foo == NULL)
      croak("Error accessing Object 'Dims' component");

   dims  = pdl_packdims( *foo, &ndims ); /* Pack into PDL */
   if (ndims> 0 && dims == NULL)
      croak("Error reading 'Dims' component");

   /* Fetch offset and increments, *if available* */

   foo = hv_fetch ( hash, "Incs", strlen("Incs"), 0);

   if(foo == NULL) {
      pdl_setdims(thepdl, dims, ndims, NULL);
   } else {
      incs = pdl_packdims( *foo, &nincs ); /* Pack */
      if(nincs != ndims) 
         croak("NDIMS AND NINCS UNEQUAL!\n");

      pdl_setdims(thepdl, dims, ndims, incs);
   }

   foo = hv_fetch (hash, "Offs", strlen("Offs"), 0);
   if(foo == NULL) {
   	thepdl->offs = 0;
   } else {
   	thepdl->offs = SvIV( *foo );
   }

   /* Fetch ThreadDims and ThreadIncs *if available* */

   foo = hv_fetch ( hash, "ThreadDims", strlen("ThreadDims"), 0);
   if(foo == NULL)
   	{thepdl->nthreaddims = 0; ndims = 0;}
   else
        dims = pdl_packdims(*foo, &ndims);
   
   if(ndims) {
      foo = hv_fetch ( hash, "ThreadIncs", strlen("ThreadIncs"), 0);
      if(foo == NULL)
         die("Threaddims but not ThreadIncs given!\n");
	
      incs = pdl_packdims (*foo, &nincs );
      if(nincs != ndims)  
         die("NThreaddims != NThreadIncs!\n");

      pdl_setthreaddims( thepdl, dims, ndims, incs);
    }
   return thepdl;
}

void pdl_flushcache( pdl *thepdl ) {
	SV *foo = (SV *)(thepdl->sv);
	HV *hash = (HV*) SvRV(foo); 

/* Data, nvals always ok (?) */

	SV *bar = pdl_getKey(hash,"Datatype");
	sv_setiv(bar, (IV) thepdl->datatype);

	pdl_unpackarray(hash,"Dims",thepdl->dims,thepdl->ndims);
	pdl_unpackarray(hash,"Incs",thepdl->incs,thepdl->ndims);
	pdl_unpackarray(hash,"ThreadDims",thepdl->threaddims,thepdl->nthreaddims);
	pdl_unpackarray(hash,"ThreadIncs",thepdl->threadincs,thepdl->nthreaddims);

}

/* 
   Get $$x{Data} etc. allowing for dereferencing - note we don't need
   to provide pdl_setKey etc. because once we have the SV* if we change
   it then it is changed in the original hash.
*/

SV* pdl_getKey( HV* hash, char* key ) {

   SV**   foo;
   SV*    bar;
   
   foo = hv_fetch( hash, key, strlen(key), 0);

   if (foo == NULL)
      croak("Error accessing Object %s component", key);

   /* Now, if key is a reference, we need to dereference it */

   bar = *foo;

   while(SvROK(bar)) {
   	bar = SvRV(bar);
   }
   return bar;
}


/* unpack dims array into Hash */

void pdl_unpackarray ( HV* hash, char *key, int *dims, int ndims ) {

   AV*  array;
   SV** foo;
   int i;

   array = newAV();
   hv_store(hash, key, strlen(key), newRV( (SV*) array), 0 );
  
   if (ndims==0 )
      return;

   for(i=0; i<ndims; i++)
         av_store( array, i, newSViv( (IV)dims[i] ) );
} 

