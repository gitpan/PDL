
/* pdlapi.c - functions for manipulating pdl structs */


#include "pdl.h"      /* Data structure declarations */
#include "pdlcore.h"  /* Core declarations */

/* Uncomment the following if you have core dumps or strange
 * behaviour - it may reveal the cause by croaking because of
 * bad magic number. 
 */

/* #define DONT_REALLY_FREE  
 */

/* This define causes the affine transformations not to be
 * optimized away so $a->slice(...) will always made physical.
 * Uncommenting this define is not recommended at the moment
 */

/* #define DONT_OPTIMIZE
 * #define DONT_VAFFINE
 */

extern Core PDL;

static int has_children(pdl *it) {
	PDL_DECL_CHILDLOOP(it) 
	PDL_START_CHILDLOOP(it) 
		return 1;
	PDL_END_CHILDLOOP(it) 
	return 0;
}

static int is_child_of(pdl *it,pdl_trans *trans) {
	int i;
	for(i=trans->vtable->nparents; i<trans->vtable->npdls; i++) {
		if(trans->pdls[i] == it)  return 1;
	}
	return 0;
}

static int is_parent_of(pdl *it,pdl_trans *trans) {
	int i;
	for(i=0; i<trans->vtable->nparents; i++) {
		if(trans->pdls[i] == it)  return 1;
	}
	return 0;
}

pdl *pdl_null() {
	PDL_Long d[1] = {0};
	pdl *it = pdl_new();
	pdl_makescratchhash(it,0.0);
	pdl_setdims(it,d,1);
	it->state |= PDL_NOMYDIMS;
	return it;
}

pdl *pdl_get_convertedpdl(pdl *old,int type) {
	if(old->datatype != type) {
		pdl *it;
		it = pdl_null();
		PDL.converttypei_new(old,it,type);
		if(it->datatype != type) { croak("FOOBAR! HELP!\n"); }
		return it;
	} else {
		return old;
	}
}

void pdl_allocdata(pdl *it) {
	int i;
	int nvals=1;
	SV *bar;
	for(i=0; i<it->ndims; i++) {
			nvals *= it->dims[i];
	}
	it->nvals = nvals;
	PDLDEBUG_f(printf("pdl_allocdata %d, %d, %d\n",it, it->nvals,
		it->datatype));

	pdl_grow(it,nvals);
	PDLDEBUG_f(pdl_dump(it));

	it->state |= PDL_ALLOCATED;
}

/* Return a new pdl - type is PDL_PERM or PDL_TMP - the latter is auto-freed
   when current perl context is left */

/* Note pdl_new() and pdl_tmp() are macroes defined in pdlcore.h */


pdl* pdl_create(int type) {  
     int i;
     pdl* it;

     if(type == PDL_TMP) {croak("PDL internal error. FIX!\n");}

     it = (pdl*) malloc(sizeof(pdl));
     if (it==NULL) 
        croak("Out of Memory\n");

     it->magicno = PDL_MAGICNO;
     it->state = 0;
     it->datatype = 0;
     it->trans = NULL;
     it->vafftrans = NULL;
     it->sv = NULL;
     it->datasv = 0;
     it->data = 0;

     it->dims = it->def_dims;
     it->dimincs = it->def_dimincs;
     it->ndims = 0;

     it->nthreadids = 0;
     it->threadids = it->def_threadids;
     it->threadids[0] = 0;
     
     for(i=0; i<PDL_NCHILDREN; i++) {it->children.trans[i]=NULL;}
     it->children.next = NULL;

     it->living_for = 0;
     it->progenitor = 0;
     it->future_me = 0;

     it->magic = 0;

     PDLDEBUG_f(printf("CREATE %d\n",it));
     return it;
}

/* Explicit free. Do not use, use destroy instead, which causes this
   to be called when the time is right */
void pdl__free(pdl *it) {
    pdl_children *p1,*p2;
    PDL_CHKMAGIC(it);
    it->magicno = 0x42424245;
    PDLDEBUG_f(printf("FREE %d\n",it));
#ifndef DONT_REALLY_FREE
    if(it->dims       != it->def_dims)       free((void*)it->dims);
    if(it->dimincs    != it->def_dimincs)    free((void*)it->dimincs);
    if(it->threadids  != it->def_threadids)  free((void*)it->threadids);

    if(it->vafftrans) {
    	pdl_vafftrans_free(it);
    }

    p1 = it->children.next;
    while(p1) {
    	p2 = p1->next;
	free(p1);
	p1 = p2;
    }
    
/* Free the phys representation */
/* XXX MEMLEAK */
/*    it->vtable->freetrans(it,it->trans); */
    if(it->datasv) 
	    SvREFCNT_dec(it->datasv);
    free(it); 
#endif
}

void pdl__destroy_childtranses(pdl *it,int ensure) {
	PDL_DECL_CHILDLOOP(it);
	PDL_START_CHILDLOOP(it)
		pdl_destroytransform(PDL_CHILDLOOP_THISCHILD(it),ensure);
	PDL_END_CHILDLOOP(it)
}

/* Must think about.
  A piddle may be 
   - a parent of something - just ensure & destroy
   - a child of something - just ensure & destroy
   - parent of two pdls which both propagate backwards - mustn't destroy.
   - both parent and child at same time, to something that propagates.
  Therefore, simple rules:
   - allowed to destroy if
      1. a parent with max. 1 backwards propagating transformation
      2. a child with no children & this is not the mutator of the family
         (otherwise the mutator might be my child).

  When the mutator or progenitor of a family is destroyed, it must check
  whether the other is also destroyed and if it is, destroy the family.

  Also, when a piddle is destroyed, it must tell its children and/or
  parent so that 

  XXX Currently, will not destroy if any back-propagating children.

  Family may be destroyed, if either
   -nothing flowing out, in which case both mutated_to and
    futureprogenitor hash = 0
   -nothing flowing in 

*/
void pdl_destroy(pdl *it) {
    int nback=0,nforw=0,nundest=0,nundestp=0;
    PDL_DECL_CHILDLOOP(it);
    PDL_CHKMAGIC(it);
    PDLDEBUG_f(printf("Destr. %d\n",it);)
    if(it->state & PDL_DESTROYING) {
    	return;
    }
    it->state |= PDL_DESTROYING;
    /* Clear the sv field so that there will be no dangling ptrs */
    if(it->sv) {
	    sv_setiv(it->sv,0x4242);
	    it->sv = NULL;
    }

    if(it->progenitor || it->living_for || it->future_me) {
    	/* XXXXXXXXX Shouldn't do this! BAD MEMLEAK */
	goto soft_destroy;
    }
    /* 1. count the children that do flow */
    PDL_START_CHILDLOOP(it)
	if(PDL_CHILDLOOP_THISCHILD(it)->flags & (PDL_ITRANS_DO_DATAFLOW_F|
						 PDL_ITRANS_DO_DATAFLOW_B))
		nforw ++;
	if(PDL_CHILDLOOP_THISCHILD(it)->flags & PDL_ITRANS_DO_DATAFLOW_B)
		nback ++;
	if(PDL_CHILDLOOP_THISCHILD(it)->flags & PDL_ITRANS_FORFAMILY)
		nundest ++;
    PDL_END_CHILDLOOP(it)

    if(it->trans && (it->trans->flags & PDL_ITRANS_FORFAMILY))
    	nundestp ++;

/* XXX FIX */
    if(nundest || nundestp) goto soft_destroy;

/* First case where we may not destroy */
    if(nback > 1) goto soft_destroy;
    
/* Also not here */
    if(it->trans && nforw) goto soft_destroy;

    pdl__destroy_childtranses(it,1);

    if(it->trans) {
        /* Because there might be other children, must ensure */
    	pdl_destroytransform(it->trans,1);
    }

/* Here, this is a child but has no children */
    goto hard_destroy;


   hard_destroy:
#ifdef OIFSJEFLESJF
/* Now, check for progenitor-stuff. */
    if(it->progenitor) {
      if(!(it->progenitor->sv)) {
	      pdl__family_destroy_if(it->progenitor);
      } else 
       	goto soft_destroy;
    } else if(it->living_for) {
    	pdl__family_fut_destroy_if(it);
    }
#endif

/* ... and now we drink */
   pdl__free(it);

   return;

  soft_destroy:
    PDLDEBUG_f(printf("May have dependencies, not destr. %d\n",it);)
    it->state &= ~PDL_DESTROYING;
}


/* Straight copy, no dataflow */
pdl *pdl_hard_copy(pdl *src) {
	int i;
	pdl *it = pdl_null();
	it->state = 0;

	pdl_make_physical(src); /* Wasteful XXX... should be lazier */
	
	it->datatype = src->datatype;
	
	pdl_setdims(it,src->dims,src->ndims);
	pdl_allocdata(it);

	if(src->ndims == 1 && src->dims[0] == 0) 
		it->state |= PDL_NOMYDIMS;

	pdl_reallocthreadids(it,src->nthreadids);
	for(i=0; i<src->nthreadids; i++) {
		it->threadids[i] = src->threadids[i];
	}

	memcpy(it->data,src->data, pdl_howbig(it->datatype) * it->nvals);

	return it;

}

/* Dump a tranformation (don't dump the pdls, just pointers to them */
void pdl_dump_trans (pdl_trans *it, int nspac) {
	int i;
	char *spaces = malloc(nspac+1); for(i=0; i<nspac; i++) spaces[i]=' ';
	spaces[i] = '\0';
	printf("%sDUMPTRANS %d (%s)\n",spaces,it,it->vtable->name);
/*	if(it->vtable->dump) {it->vtable->dump(it);} */
	printf("%s   INPUTS: (",spaces);
	for(i=0; i<it->vtable->nparents; i++) 
		printf("%s%d",(i?" ":""),it->pdls[i]);
	printf(")     OUTPUTS: (");
	for(;i<it->vtable->npdls; i++) 
		printf("%s%d",(i?" ":""),it->pdls[i]);
	printf(")\n");
	free(spaces);
}

void pdl_dump_spac(pdl *it,int nspac)
{
	PDL_DECL_CHILDLOOP(it)
	int i;
	char *spaces = malloc(nspac+1); for(i=0; i<nspac; i++) spaces[i]=' ';
	spaces[i] = '\0';
	printf("%sDUMPING %d     datatype: %d\n",spaces,it,it->datatype);
	printf("%s   State: %d, transv: %d, trans: %d, sv: %d\n",spaces,
		it->state, (it->trans?it->trans->vtable:0), it->trans, it->sv);
	if(it->datasv) {
		printf("%s   Data SV: %d, Svlen: %d, data: %d, nvals: %d\n", spaces,
			it->datasv, SvCUR((SV*)it->datasv), it->data, it->nvals);
	}
	printf("%s   Dims: %d (",spaces,it->dims);
	for(i=0; i<it->ndims; i++) {
		printf("%s%d",(i?" ":""),it->dims[i]);
	}; 
	printf(")\n%s   ThreadIds: %d (",spaces,it->threadids);
	for(i=0; i<it->nthreadids+1; i++) {
		printf("%s%d",(i?" ":""),it->threadids[i]);
	} 
	if(PDL_VAFFOK(it)) {
		printf(")\n%s   Vaffine ok: %d, o:%d, i:(",
			spaces,it->vafftrans->from,it->vafftrans->offs);
		for(i=0; i<it->ndims; i++) {
			printf("%s%d",(i?" ":""),it->vafftrans->incs[i]);
		}
	}
	if(it->state & PDL_ALLOCATED) {
		printf(")\n%s   First values: (",spaces);
		for(i=0; i<it->nvals && i<10; i++) {
			printf("%s%f",(i?" ":""),pdl_get_offs(it,i));
		}
	} else {
		printf(")\n%s   (not allocated",spaces);
	}
	printf(")\n");
	if(it->trans) {
		pdl_dump_trans(it->trans,nspac+3);
	}
	printf("%s   CHILDREN:\n",spaces);
	PDL_START_CHILDLOOP(it)
		pdl_dump_trans(PDL_CHILDLOOP_THISCHILD(it),nspac+4);
	PDL_END_CHILDLOOP(it)
	/* XXX phys etc. also */
	free(spaces);
}

void pdl_dump (pdl *it) {
	pdl_dump_spac(it,0);
}


/* Reallocate this PDL to have ndims dimensions. The previous dims
   are copied. */

void pdl_reallocdims(pdl *it,int ndims) {
   int i;
   if (it->ndims < ndims) {  /* Need to realloc for more */
      if(it->dims != it->def_dims) free(it->dims);
      if(it->dimincs != it->def_dimincs) free(it->dimincs);
      if (ndims>PDL_NDIMS) {  /* Need to malloc */
         it->dims = malloc(ndims*sizeof(*(it->dims)));
         it->dimincs = malloc(ndims*sizeof(*(it->dimincs)));
         if (it->dims==NULL || it->dimincs==NULL)
            croak("Out of Memory\n");
      }
      else {
         it->dims = it->def_dims;
         it->dimincs = it->def_dimincs;
      }
   }
   it->ndims = ndims;
}    

/* Reallocate n threadids. Set the new extra ones to the end */
/* XXX Check logic */
void pdl_reallocthreadids(pdl *it,int n) {
	int i;
	unsigned char *olds; int nold;
	if(n <= it->nthreadids) {
		it->nthreadids = n; it->threadids[n] = it->ndims; return;
	}
	nold = it->nthreadids; olds = it->threadids;
	if(n >= PDL_NTHREADIDS-1) {
		it->threadids = malloc(sizeof(*(it->threadids))*(n+1));
	} else {
		/* already is default */
	}
	it->nthreadids = n;

	if(it->threadids != olds) {
		for(i=0; i<nold && i<n; i++)
			it->threadids[i] = olds[i];
	}
	if(olds != it->def_threadids) { free(olds); }
	  
	for(i=nold; i<it->nthreadids; i++) {
		it->threadids[i] = it->ndims;
	}
}

/* Calculate default increments and grow the PDL data */

void pdl_resize_defaultincs(pdl *it) {
	int inc = 1;
	int i=0;
	for(i=0; i<it->ndims; i++) {
		it->dimincs[i] = inc; inc *= it->dims[i];
	}
	it->nvals = inc;
        it->state &= ~PDL_ALLOCATED; /* Need to realloc when phys */
#ifdef DONT_OPTIMIZE
	pdl_allocdata(it);
#endif
}

/* Init dims & incs - if *incs is NULL ignored (but space is always same for both)  */

void pdl_setdims(pdl* it, PDL_Long * dims, int ndims) {
   int i;

   pdl_reallocdims(it,ndims);

   for(i=0; i<ndims; i++)
      it->dims[i] = dims[i];

   pdl_resize_defaultincs(it);

   pdl_reallocthreadids(it,0);  /* XXX Maybe trouble */
}

/* This is *not* careful! */
void pdl_setdims_careful(pdl *it)
{
	pdl_resize_defaultincs(it);
#ifdef DONT_OPTIMIZE
	pdl_allocdata(it);
#endif
        pdl_reallocthreadids(it,0); /* XXX For now */
}

void pdl_print(pdl *it) {
#ifdef FOO
   int i;
   printf("PDL %d: sv = %d, data = %d, datatype = %d, nvals = %d, ndims = %d\n",
   	(int)it, (int)(it->hash), (int)(it->data), it->datatype, it->nvals, it->ndims);
   printf("Dims: ");
   for(i=0; i<it->ndims; i++) {
   	printf("%d(%d) ",it->dims[i],it->dimincs[i]);
   }
   printf("\n");
#endif
}

double pdl_get(pdl *it,int *inds) {
	int i;
	int offs=0; 
	for(i=0; i<it->ndims; i++)
		offs += it->dimincs[i] * inds[i];
	return pdl_get_offs(it,offs);
}

double pdl_get_offs(pdl *it, PDL_Long offs) {
	PDL_Long dummy1=offs+1; PDL_Long dummy2=1;
	return pdl_at(it->data, it->datatype, &offs, &dummy1, &dummy2, 0, 1);
}

void pdl_put_offs(pdl *it, PDL_Long offs, double value) {
	PDL_Long dummy1=offs+1; PDL_Long dummy2=1;
	pdl_set(it->data, it->datatype, &offs, &dummy1, &dummy2, 0, 1, value);
}


void pdl__addchildtrans(pdl *it,pdl_trans *trans,int nth)
{
	int i; pdl_children *c;
	trans->pdls[nth] = it;
	c = &it->children;
	do {
		for(i=0; i<PDL_NCHILDREN; i++) {
			if(! c->trans[i]) {
				c->trans[i] = trans; return;
			}
		}
		if(!c->next) break;
		c=c->next;
	} while(1) ;
	c->next = malloc(sizeof(pdl_children));
	c->next->trans[0] = trans;
	for(i=1; i<PDL_NCHILDREN; i++) 
		c->next->trans[i] = 0;
	c->next->next = 0;
}

/* Problem with this function: when transformation is destroyed,
 * there may be several different children with the same name.
 * Therefore, we cannot croak :(
 */
void pdl__removechildtrans(pdl *it,pdl_trans *trans,int nth,int all)
{
	int i; pdl_children *c; int flag = 0;
	if(all) {
		for(i=0; i<trans->vtable->nparents; i++) 
			if(trans->pdls[i] == it)	
				trans->pdls[i] = NULL;
	} else {
		trans->pdls[nth] = 0;
	}
	c = &it->children;
	do {
		for(i=0; i<PDL_NCHILDREN; i++) {
			if(c->trans[i] == trans) {
				c->trans[i] = NULL;
				flag = 1;
				if(!all) return;
				/* return;  Cannot return; might be many times
				  (e.g. $a+$a) */
			}
		}
		c=c->next;
	} while(c);
	if(!flag) 
		croak("Child not found for pdl %d, %d\n",it, trans);
}

void pdl__removeparenttrans(pdl *it, pdl_trans *trans, int nth)
{
	trans->pdls[nth] = 0;
	it->trans = 0;
}

void pdl_make_physdims(pdl *it) {
	int i;
	PDLDEBUG_f(printf("Make_physdims %d\n",it));
        PDL_CHKMAGIC(it);
	if(!(it->state & (PDL_PARENTDIMSCHANGED | PDL_PARENTREPRCHANGED))) 
		return;
	it->state &= ~(PDL_PARENTDIMSCHANGED | PDL_PARENTREPRCHANGED);
	for(i=0; i<it->trans->vtable->nparents; i++) {
		pdl_make_physdims(it->trans->pdls[i]);
	}
	it->trans->vtable->redodims(it->trans);
	pdl_allocdata(it);
	PDLDEBUG_f(printf("Make_physdims_exit %d\n",it));
}

void pdl_writeover(pdl *it) {
	pdl_make_physdims(it);
	pdl_children_changesoon(it,PDL_PARENTDATACHANGED);
	it->state &= ~PDL_PARENTDATACHANGED;
}

/* Order is important: do childtrans first, then parentrans. */

void pdl_set_trans_childtrans(pdl *it, pdl_trans *trans,int nth)
{
	pdl__addchildtrans(it,trans,nth);
/* Determine if we want to do dataflow */
	if(it->state & PDL_DATAFLOW_F) 
		trans->flags |= PDL_ITRANS_DO_DATAFLOW_F;
	if(it->state & PDL_DATAFLOW_B) 
		trans->flags |= PDL_ITRANS_DO_DATAFLOW_B;
}

/* This is because for "+=" (a = a + b) we must check for
   previous parent transformations and mutate if they exist
   if no dataflow. */

void pdl_set_trans_parenttrans(pdl *it, pdl_trans *trans,int nth)
{
	int i; int nthind;
	if((it->trans || is_parent_of(it,trans)) 
	   /* && (it->state & PDL_DATAFLOW_F) */ ) {
		/* XXX What if in several places */
		nthind=-1;
		for(i=0; i<trans->vtable->nparents; i++)
			if(trans->pdls[i] == it) nthind = i;
		croak("Sorry, families not allowed now (i.e. You cannot modify dataflowing pdl)\n");
		pdl_family_create(it,trans,nthind,nth);
	} else {
		it->trans = trans;
		it->state |= PDL_PARENTDIMSCHANGED | PDL_PARENTDATACHANGED ;
		trans->pdls[nth] = it;
#ifdef FOOBARBAR
		if(trans->flags & PDL_ITRANS_DO_DATAFLOW_F)
			it->state |= PDL_DATAFLOW_F;
		if(trans->flags & PDL_ITRANS_DO_DATAFLOW_B)
			it->state |= PDL_DATAFLOW_B;
#endif
	}
}

/* Called with a filled pdl_trans struct.
 * Sets the parent and trans fields of the piddles correctly,
 * creating families and the like if necessary.
 * Alternatively may just execute transformation
 * that would require families but is not dataflown.
 */
void pdl_make_trans_mutual(pdl_trans *trans) 
{
  int i;
  int fflag=0;
  int cfflag=0;
  int pfflag=0;
  PDL_TR_CHKMAGIC(trans);

/* Then, set our children. This is: */
/* First, determine whether any of our children already have
 * a parent, and whether they need to be updated. If this is
 * the case, we need to do some thinking. */

  for(i=trans->vtable->nparents; i<trans->vtable->npdls; i++) {
  	if(trans->pdls[i]->trans) fflag ++;
	if(trans->pdls[i]->state & PDL_DATAFLOW_ANY) cfflag++;
  }
  for(i=0; i<trans->vtable->nparents; i++)
	if(trans->pdls[i]->state & PDL_DATAFLOW_ANY)
		pfflag++;

/* If children are flowing, croak. It's too difficult to handle
 * properly */

  if(cfflag) 
	croak("Sorry, cannot flowing families right now\n");

/* Same, if children have trans yet parents are flowing */
  if(pfflag && fflag) 
	croak("Sorry, cannot flowing families right now (2)\n");

/* Now, if parents are not flowing, just execute the transformation */

  if(!pfflag && !(trans->flags & PDL_ITRANS_DO_DATAFLOW_ANY)) {
  	int *wd = malloc(sizeof(int) * trans->vtable->npdls);
	  for(i=trans->vtable->nparents; i<trans->vtable->npdls; i++) {
	  	pdl_children_changesoon(trans->pdls[i],
			wd[i]=(trans->pdls[i]->state & PDL_NOMYDIMS ?
			 PDL_PARENTDIMSCHANGED : PDL_PARENTDATACHANGED));
	  }
	  for(i=trans->vtable->nparents; i<trans->vtable->npdls; i++) {
	  	if(trans->pdls[i]->state & PDL_NOMYDIMS) {
			trans->pdls[i]->state &= ~PDL_NOMYDIMS;
			trans->pdls[i]->state |= PDL_MYDIMS_TRANS;
			trans->pdls[i]->trans = trans;
		}
	  }
#ifdef BARBARBAR /* Not done */
	  for(i=trans->vtable->nparents; i<trans->vtable->npdls; i++)
		trans->pdls[i]->state  |=
		   PDL_PARENTDIMSCHANGED | PDL_PARENTDATACHANGED;
#endif
	pdl_destroytransform_nonmutual(trans,1);
	/* Es ist vollbracht */
	for(i=trans->vtable->nparents; i<trans->vtable->npdls; i++) {
#ifndef DONT_VAFFINE
		if( PDL_VAFFOK(trans->pdls[i]) &&
		    (trans->vtable->per_pdl_flags[i] & PDL_TPDL_VAFFINE_OK) )  {
		    	if(wd[i] & PDL_PARENTDIMSCHANGED) 
				pdl_changed(trans->pdls[i],
					PDL_PARENTDIMSCHANGED,0);
		    	pdl_vaffinechanged(
				trans->pdls[i],PDL_PARENTDATACHANGED);
		} else
#endif
			pdl_changed(trans->pdls[i],wd[i],0);
	}
      free(wd);
  } else {
	  for(i=0; i<trans->vtable->nparents; i++)
		pdl_set_trans_childtrans(trans->pdls[i],trans,i);
	  for(i=trans->vtable->nparents; i<trans->vtable->npdls; i++) 
		pdl_set_trans_parenttrans(trans->pdls[i],trans,i);
	  if(!(trans->flags&PDL_ITRANS_REVERSIBLE)) 
		trans->flags &= ~PDL_ITRANS_DO_DATAFLOW_B;
	  for(i=trans->vtable->nparents; i<trans->vtable->npdls; i++) {
	  	if(trans->pdls[i]->state & PDL_NOMYDIMS) {
			trans->pdls[i]->state &= ~PDL_NOMYDIMS;
			trans->pdls[i]->state |= PDL_MYDIMS_TRANS;
		}
	  }
  }


#ifdef FOO
/* If we are not flowing, we must disappear */
  if(!(trans->flags & PDL_ITRANS_DO_DATAFLOW_ANY)) {
  	pdl_destroytransform(trans,1);
  }
#endif

}



pdl *pdl_make_now(pdl *it) {
	if(it->future_me) return it->future_me;
	if(!it->progenitor) return it;
	return pdl_family_clone2now(it);
}

void pdl_make_physical(pdl *it) {
	int i;
	DECL_RECURSE_GUARD;

	PDLDEBUG_f(printf("Make_physical %d\n",it));
        PDL_CHKMAGIC(it);

	START_RECURSE_GUARD;
	if(it->state & PDL_ALLOCATED && !(it->state & PDL_ANYCHANGED))  {
		goto mkphys_end;
	}
	if(!(it->state & PDL_ANYCHANGED))  {
		pdl_allocdata(it);
		goto mkphys_end;
	}
	if(!it->trans) {
		die("PDL Not physical but doesn't have parent");
	}
#ifndef DONT_OPTIMIZE
#ifndef DONT_VAFFINE
	if(it->trans->flags & PDL_ITRANS_ISAFFINE) {
		if(!PDL_VAFFOK(it))
			pdl_make_physvaffine(it);
	}
	if(PDL_VAFFOK(it)) {
		pdl_readdata_vaffine(it);
		it->state &= (~PDL_ANYCHANGED);
		goto mkphys_end;
	}
#endif
#endif
	PDL_TR_CHKMAGIC(it->trans);
	for(i=0; i<it->trans->vtable->nparents; i++) {
#ifndef DONT_OPTIMIZE
#ifndef DONT_VAFFINE
		if(it->trans->vtable->per_pdl_flags[i] &
		    PDL_TPDL_VAFFINE_OK)
		    	pdl_make_physvaffine(it->trans->pdls[i]);
		else
#endif
#endif
			pdl_make_physical(it->trans->pdls[i]);
	}
	if(!(it->state & PDL_ALLOCATED) ||
	   it->state & PDL_PARENTDIMSCHANGED ||
	   it->state & PDL_PARENTREPRCHANGED) {
		it->trans->vtable->redodims(it->trans);
	}
	if(!(it->state & PDL_ALLOCATED)) {
		pdl_allocdata(it);
	}
	/* Make parents physical first. XXX Needs more reasonable way */
	/* Already done
		for(i=0; i<it->trans->vtable->nparents; i++) {
			pdl_make_physical(it->trans->pdls[i]);
		}
	*/
	for(i=0; i<it->trans->vtable->npdls; i++) {
		if(!(it->trans->pdls[i]->state & PDL_ALLOCATED)) {
			croak("Trying to readdata without physicality");
		}
	}
	it->trans->vtable->readdata(it->trans);
	it->state &= (~PDL_ANYCHANGED) & (~PDL_OPT_ANY_OK);
	
  mkphys_end:
	PDLDEBUG_f(printf("Make_physical_exit %d\n",it));
	END_RECURSE_GUARD;
}
/* Change soon: if this is not writeback, separate from
   parent.
   If the children of this are not writeback, separate them.
 */

void pdl_children_changesoon(pdl *it, int what)
{
	pdl_children *c; int i;
	if(it->trans &&
	   !(it->trans->flags & PDL_ITRANS_DO_DATAFLOW_B)) {
		pdl_destroytransform(it->trans,1);
	} else if(it->trans) {
		if(!(it->trans->flags & PDL_ITRANS_REVERSIBLE)) {
			die("PDL: Internal error: Trying to reverse irreversible trans");
		}
		for(i=0; i<it->trans->vtable->nparents; i++) 
			pdl_children_changesoon(it->trans->pdls[i],what);
		return;
	} 
	c=&it->children;
	do {
		for(i=0; i<PDL_NCHILDREN; i++) {
			if(c->trans[i] && !(c->trans[i]->flags & 
						PDL_ITRANS_DO_DATAFLOW_F)) {
				pdl_destroytransform(c->trans[i],1);
			}
		}
		c=c->next;
	} while(c);
}

/* what should always be PARENTDATA */
void pdl_vaffinechanged(pdl *it, int what) 
{
	if(!PDL_VAFFOK(it)) {
		croak("Vaffine not ok!, trying to use vaffinechanged");
	}
	pdl_changed(it->vafftrans->from,what,0);
}

/* This is inefficient: _changed writes back, which it really should not,
   before a parent is used (?). */
void pdl_changed(pdl *it, int what, int recursing)
{
	pdl_children *c; int i; int j;
	if((it->state & what) == what) { return; }
	if(recursing) {
		it->state |= what;
		if(pdl__ismagic(it))
			pdl__call_magic(it,PDL_MAGIC_MARKCHANGED);
	}
	if(it->trans && !recursing && 
		(it->trans->flags & PDL_ITRANS_DO_DATAFLOW_B)) {
		if((it->trans->flags & PDL_ITRANS_ISAFFINE) &&
		   (PDL_VAFFOK(it))) {
			pdl_writebackdata_vaffine(it);
			pdl_changed(it->vafftrans->from,what,0);
		} else {
			if(!it->trans->vtable->writebackdata) {
				die("Internal error: got so close to reversing irrev.");
			}
			it->trans->vtable->writebackdata(it->trans);
			for(i=0; i<it->trans->vtable->nparents; i++) 
				pdl_changed(it->trans->pdls[i],what,0);
		}
	} else {
		c=&it->children;
		do {
			for(i=0; i<PDL_NCHILDREN; i++) {
				if(c->trans[i]) {
					for(j=c->trans[i]->vtable->nparents; 
						j<c->trans[i]->vtable->npdls;
						j++) {
						pdl_changed(c->trans[i]->pdls[j],what,1);
					}
				}
			}
			c=c->next;
		} while(c);
	}
}

/* Make sure transformation is done */
void pdl__ensure_trans(pdl_trans *trans,int what) 
{
	int j;
/* Make parents physical */
	int flag=0;
	int par_pvaf=0;
	flag |= what;
	PDL_TR_CHKMAGIC(trans);
	for(j=0; j<trans->vtable->nparents; j++) {
		pdl_make_physical(trans->pdls[j]);
	}
	for(; j<trans->vtable->npdls; j++) {
		if(trans->pdls[j]->trans != trans) {
#ifndef DONT_OPTIMIZE
#ifndef DONT_VAFFINE
			if(trans->vtable->per_pdl_flags[j] &
			    PDL_TPDL_VAFFINE_OK) {
			    	par_pvaf++;
				pdl_make_physvaffine(trans->pdls[j]);
			} else
#endif
#endif
				pdl_make_physical(trans->pdls[j]);
		} 
		flag |= trans->pdls[j]->state & PDL_ANYCHANGED;
	}
	if(flag & PDL_PARENTDIMSCHANGED) {
		trans->vtable->redodims(trans);
	}
	for(j=0; j<trans->vtable->npdls; j++) {
		if(trans->pdls[j]->trans == trans)
			PDL_ENSURE_ALLOCATED(trans->pdls[j]);
	}
	if(flag & PDL_PARENTDATACHANGED | flag & PDL_PARENTDIMSCHANGED) {
		int i;
		if(par_pvaf && (trans->flags & PDL_ITRANS_ISAFFINE)) {
			/* Assuming affine = p2child */
			pdl_make_physvaffine(trans->pdls[1]);
			pdl_readdata_vaffine(trans->pdls[1]);
		} else {
#ifdef DONT_VAFFINE 
			for(i=0; i<trans->vtable->npdls; i++) {
				if(!(trans->pdls[i]->state & PDL_ALLOCATED)) {
					croak("Trying to readdata without physicality");
				}
			}
#endif
			trans->vtable->readdata(trans);
		}
	}
	for(j=trans->vtable->nparents; j<trans->vtable->npdls; j++) {
		trans->pdls[j]->state &= ~PDL_ANYCHANGED;
	}
}

void pdl__ensure_transdims(pdl_trans *trans)
{
	int j;
	int flag=0;
	PDL_TR_CHKMAGIC(trans);
	for(j=0; j<trans->vtable->nparents; j++) {
		pdl_make_physdims(trans->pdls[j]);
	}
	trans->vtable->redodims(trans);
}

/* There is a potential problem here, calling
   pdl_destroy while the trans structure is not in a defined state.
   We shall ignore this problem for now and hope it goes away ;)
   (XXX FIX ME) */
/* XXX Two next routines are memleaks */
void pdl_destroytransform(pdl_trans *trans,int ensure)
{
	int j;
	pdl *foo;
	PDL_TR_CHKMAGIC(trans);
	if(ensure) {
		pdl__ensure_trans(trans,0);
	}
	for(j=0; j<trans->vtable->nparents; j++) {
		foo = trans->pdls[j];
		if(!foo) continue;
		PDL_CHKMAGIC(foo);
		pdl__removechildtrans(trans->pdls[j],trans,j,1);
		if(!(foo->state & PDL_DESTROYING) && !foo->sv) pdl_destroy(foo);
	}
	for(; j<trans->vtable->npdls; j++) {
		foo = trans->pdls[j];
		PDL_CHKMAGIC(foo);
		pdl__removeparenttrans(trans->pdls[j],trans,j);
		if(foo->vafftrans)
			pdl_vafftrans_remove(foo);
		if(!(foo->state & PDL_DESTROYING) && !foo->sv) pdl_destroy(foo);
	}
	PDL_TR_CLRMAGIC(trans);
#ifndef DONT_REALLY_FREE
	/* XXX MEMLEAK EVEN WITH FREE! */
	free(trans); 
#endif
}

void pdl_destroytransform_nonmutual(pdl_trans *trans,int ensure)
{
	int i;
	PDL_TR_CHKMAGIC(trans);
	if(ensure) {
		pdl__ensure_trans(trans,PDL_PARENTDIMSCHANGED);
	}
	for(i=trans->vtable->nparents; i<trans->vtable->npdls; i++) {
		trans->pdls[i]->state &= ~PDL_NOMYDIMS;
		if(trans->pdls[i]->trans == trans) 
			trans->pdls[i]->trans = 0;
	}
	PDL_TR_CLRMAGIC(trans);
	if(trans->vtable->freetrans) {
		trans->vtable->freetrans(trans);
	}
	if(trans->freeproc) {
		trans->freeproc(trans);
	}
}

void pdl_trans_mallocfreeproc(struct pdl_trans *tr) {
	free(tr);
}

#ifndef DONT_OPTIMIZE

/* Recursive! */
void pdl_vafftrans_remove(pdl * it)
{
	pdl_trans *t; int i;
	PDL_DECL_CHILDLOOP(it);
	PDL_START_CHILDLOOP(it)
		t = PDL_CHILDLOOP_THISCHILD(it);
		if(t->flags & PDL_ITRANS_ISAFFINE) {
			for(i=t->vtable->nparents; i<t->vtable->npdls; i++)
				pdl_vafftrans_remove(t->pdls[i]);
		}
	PDL_END_CHILDLOOP(it)
	pdl_vafftrans_free(it);
}

void pdl_vafftrans_free(pdl *it)
{
	if(it->vafftrans && it->vafftrans->incs)
		free(it->vafftrans->incs);
	if(it->vafftrans)
		free(it->vafftrans);
	it->vafftrans=0;
	it->state &= ~PDL_OPT_VAFFTRANSOK;
}

/* Current assumptions: only 
 * "slice" and "diagonal"-type things supported.
 * NO CLUMP!
 * This should be fixed.
 */

void pdl_make_physvaffine(pdl *it)
{
	pdl_trans *t;
	pdl_trans_affine *at;
	pdl *parent;
	pdl *current;
	int *incsleft = 0;
	int i,j;
	int inc;
	int newinc;
	int ninced;
	int flag;
	pdl_make_physdims(it);
	if(!it->trans) {
		pdl_make_physical(it);
		return;
		/* croak("Trying to make physvaffine without parent!\n"); */
	}
	if(!(it->trans->flags & PDL_ITRANS_ISAFFINE)) {
		pdl_make_physical(it);
		return;
	}
	PDL_ENSURE_VAFFTRANS(it);
	incsleft = malloc(sizeof(*incsleft)*it->ndims);
	for(i=0; i<it->ndims; i++) {
		it->vafftrans->incs[i] = it->dimincs[i];
	}

	flag=0;
	it->vafftrans->offs = 0;
	t=it->trans;
	current = it;
	while(t && (t->flags & PDL_ITRANS_ISAFFINE)) {
		at = (pdl_trans_affine *)t;
		parent = t->pdls[0];
		for(i=0; i<it->ndims; i++) {
			inc = it->vafftrans->incs[i];
			newinc = 0;
			for(j=current->ndims-1; j>=0; j--) {
				if(inc >= current->dimincs[j]) {
					ninced = inc / current->dimincs[j];
					if(it->dims[i] >= current->dims[j]) {
					  int foo=it->dims[i]; int k;
					  for(k=j+1; k<current->ndims; k++) {
						foo -= current->dimincs[k-1] *
							current->dims[k-1];
					  	if(foo<=0) break;
						if(at->incs[k] !=
						   at->incs[k-1] *
						   current->dims[k-1]) {
						   	flag=1;
						   	/* croak("Illegal vaffine; fix loop to break.\n"); */
						}
					  }
					}
					newinc += at->incs[j]*ninced;
					inc %= current->dimincs[j];
				}
			}
			incsleft[i] = newinc;
		}
		if(flag) break;
		for(i=0; i<it->ndims; i++) {
			it->vafftrans->incs[i] = incsleft[i];
		}
		{
			inc = it->vafftrans->offs;
			newinc = 0;
			for(j=current->ndims-1; j>=0; j--) {
				if(inc >= current->dimincs[j]) {
					ninced = inc / current->dimincs[j];
					if(it->dims[i] >= current->dims[j]) {
					  int foo=it->dims[i]; int k;
					  for(k=j+1; k<current->ndims; k++) {
						foo -= current->dimincs[k-1] *
							current->dims[k-1];
					  	if(foo<=0) break;
						if(at->incs[k] !=
						   at->incs[k-1] *
						   current->dims[k-1]) {
						   	flag=1;
						   	/* croak("Illegal vaffine; fix loop to break.\n"); */
						}
					  }
					}
					newinc += at->incs[j]*ninced;
					inc %= current->dimincs[j];
				}
			}
			it->vafftrans->offs = newinc;
			it->vafftrans->offs += at->offs;
		}
		t = parent->trans;
		current = parent;
	}
	it->vafftrans->from = current;
	it->state |= PDL_OPT_VAFFTRANSOK;
	pdl_make_physical(current);
}

void pdl_vafftrans_alloc(pdl *it)
{
	if(!it->vafftrans) {
		it->vafftrans = malloc(sizeof(*(it->vafftrans)));
		it->vafftrans->incs = 0;
		it->vafftrans->ndims = 0;
	}
	if(!it->vafftrans->incs || it->vafftrans->ndims < it->ndims ) {
		if(it->vafftrans->incs) free(it->vafftrans->incs);
		it->vafftrans->incs = malloc(sizeof(*(it->vafftrans->incs))
					     * it->ndims);
		it->vafftrans->ndims = it->ndims;
	}
}

#endif
