
/* pdlapi.c - functions for manipulating pdl structs */


#include "pdl.h"      /* Data structure declarations */
#include "pdlcore.h"  /* Core declarations */


/* Return a new pdl - type is PDL_PERM or PDL_TMP - the latter is auto-freed
   when current perl context is left */

/* Note pdl_new() and pdl_tmp() are macroes defined in pdlcore.h */

pdl* pdl_create(int type) {  
                             
     pdl* it;

     it = (pdl*) (type == PDL_TMP ? pdl_malloc(sizeof(pdl)) : malloc(sizeof(pdl)));
     if (it==NULL) 
        croak("Out of Memory\n");
     
     it->dims = it->def_dims;             it->incs = it->def_incs; 
     it->threaddims = it->def_threaddims; it->threadincs = it->def_threadincs; 
     it->ndims = 0; it->nvals=0;
     return it;
}

void pdl_dump (pdl *it) {
	printf("DUMPING\n");
}

void pdl_destroy(pdl *it) {

    if(it->dims != it->def_dims)   free((void*)it->dims);
    if(it->incs != it->def_incs)   free((void*)it->incs);
    if(it->threaddims != it->def_threaddims) free((void*)it->threaddims);
    if(it->threadincs != it->def_threadincs) free((void*)it->threadincs);
    free(it);
}

/* Makes in map on to same data as out */

void pdl_clone( pdl* in, pdl* out ) {
     out->nvals    = in->nvals;
     out->datatype = in->datatype;
     out->data     = in->data;
     out->ndims    = in->ndims;
     out->offs     = in->offs;
     out->nthreaddims = in->nthreaddims;
     pdl_setdims( out, in->dims, in->ndims, in->incs);
     if (in->threaddims) 
        pdl_setthreaddims( out, in->threaddims, in->ndims, in->threadincs);
     else
        out->threaddims=0;
}

/* Reallocate this PDL to have ndims dimensions. The previous dims
   are copied. */

void pdl_reallocdims(pdl *it,int ndims) {
   int *olddims = it->dims; int *oldincs = it->incs;
   int i;
   if (it->ndims < ndims) {  /* Need to realloc for more */
      if (ndims>PDL_NDIMS) {  /* Need to malloc */
         it->dims = (int*) malloc(ndims*sizeof(int));
         it->incs = (int*) malloc(ndims*sizeof(int));
         if (it->dims==NULL || it->incs==NULL)
            croak("Out of Memory\n");
      }
      else {
         it->dims = it->def_dims;
         it->incs = it->def_incs;
      }
      for(i=0; i< it->ndims; i++) { /* it->ndims is always smaller here */
      	 it->dims[i] = olddims[i];
	 it->incs[i] = oldincs[i];
      }
      if (olddims != it->def_dims)  /* Was malloced */
          free(oldincs);
      if (oldincs != it->def_incs)  /* Was malloced */
          free(oldincs);
   }
   it->ndims = ndims;
}    

/* Calculate default increments and grow the PDL data */

void pdl_resize_defaultincs(pdl *it) {
	int inc = 1;
	int i=0;
	for(i=0; i<it->ndims; i++) {
		it->incs[i] = inc; inc *= it->dims[i];
	}
	it->nvals = inc;
	pdl_grow(it,it->nvals);
}
 
/* Init dims & incs - if *incs is NULL ignored (but space is always same for both)  */

void pdl_setdims(pdl* it, int* dims, int ndims, int* incs) {
   int i;

   pdl_reallocdims(it,ndims);

   for(i=0; i<ndims; i++)
      it->dims[i] = dims[i];

   if (incs==NULL) {  /* Default incs */
      int inc=1;
      for(i=0; i<it->ndims; i++) {
         it->incs[i] = inc; inc *= it->dims[i];
      }
   } else { for(i=0; i<ndims; i++)
         it->incs[i] = incs[i];
   }
}

/* Init threaddims & threadincs - NO DEFAULTS! */

void pdl_setthreaddims(pdl* it, int* threaddims, int nthreaddims, int* threadincs) {
   int i;

   if (it->nthreaddims != nthreaddims) {  /* Need to change */
      if (it->threaddims != it->def_threaddims)  /* Was malloced */
          free(it->threadincs);
      if (it->threadincs != it->def_threadincs)  /* Was malloced */
          free(it->threadincs);
      if (nthreaddims>PDL_NDIMS) {  /* Need to malloc */
         it->threaddims = (int*) malloc(nthreaddims*sizeof(int));
         it->threadincs = (int*) malloc(nthreaddims*sizeof(int));
         if (it->threaddims==NULL || it->threadincs==NULL)
            croak("Out of Memory\n");
      }
      else {
         it->threaddims = it->def_threaddims;
         it->threadincs = it->def_threadincs;
      }
   }
   it->nthreaddims = nthreaddims;
   for(i=0; i<nthreaddims; i++)
      it->threaddims[i] = threaddims[i];

   for(i=0; i<nthreaddims; i++)
      it->threadincs[i] = threadincs[i];
  
}


