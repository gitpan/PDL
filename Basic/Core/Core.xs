
/* 
   Core.xs

*/

#include "EXTERN.h"   /* std perl include */
#include "perl.h"     /* std perl include */
#include "XSUB.h"     /* XSUB include */

#include "pdl.h"      /* Data structure declarations */
#include "pdlcore.h"  /* Core declarations */

/* Return a integer or numeric scalar as approroate */

#define setflag(reg,flagval,val) (val?(reg |= flagval):(reg &= ~flagval))

#define SET_RETVAL_NV x->datatype<PDL_F ? (RETVAL=newSViv( (IV)result )) : (RETVAL=newSVnv( result ))

Core PDL; /* Struct holding pointers to shared C routines */

#ifdef FOO
Core *pdl__Core_get_Core() /* INTERNAL TO CORE! DON'T CALL FROM OUTSIDE */
{
	return PDL;
}
#endif

int pdl_debugging=0;

MODULE = PDL::Core     PACKAGE = PDL


# Destroy a PDL - delete the $$x{PDL} cache

void
DESTROY(self)
  pdl *	self;
  CODE:
    PDLDEBUG_f(printf("DESTROYING %d\n",self);)
    if (self != NULL) 
       pdl_destroy(self);

int
fflows(self)
	pdl *self
	CODE:
	RETVAL = ((self->state & PDL_DATAFLOW_F) > 0);
	OUTPUT:
	RETVAL

int
bflows(self)
	pdl *self
	CODE:
	RETVAL = ((self->state & PDL_DATAFLOW_B) > 0);
	OUTPUT:
	RETVAL


int
is_inplace(self)
  pdl *self;
  CODE:
    RETVAL = (self->state & PDL_INPLACE) != 0;
  OUTPUT:
    RETVAL

void 
set_inplace(self,val)
  pdl *self;
  int val;
  CODE:
    setflag(self->state,PDL_INPLACE,val);

pdl *
pdl_hard_copy(src)
	pdl *src;


MODULE = PDL::Core     PACKAGE = PDL::Core

int
nelem(x)
	pdl *x
	CODE:
		pdl_make_physdims(x);
		RETVAL = x->nvals;
	OUTPUT:
		RETVAL

int
set_debugging(i)
	int i;
	CODE:
	RETVAL = pdl_debugging;
	pdl_debugging = i;
	OUTPUT:
	RETVAL

# Convert PDL to new datatype (called by float(), int() etc.)

SV *
convert(a,datatype)
   pdl*	a
   int	datatype
   CODE:
    pdl* b;
    pdl_make_physical(a);
    RETVAL = pdl_copy(a,""); /* Init value to return */
    b = SvPDLV(RETVAL);      /* Map */
    pdl_converttype( &b, datatype, PDL_PERM );

    OUTPUT:
     RETVAL



# Call my howbig function

int
howbig(datatype)
   int	datatype
   CODE:
     RETVAL = pdl_howbig(datatype);
   OUTPUT:
     RETVAL

SV *
at_c(x,position)
   pdl*	x
   PDL_Long *	pos = NO_INIT
   CODE:
    int npos;
    double result;

    pdl_make_physical( x );

    pos = pdl_packdims( ST(1), &npos);
    if (pos == NULL || npos != x->ndims) 
       croak("Invalid position");

    result = pdl_at( x->data, x->datatype, pos, x->dims, x->dimincs, 0, x->ndims);

    SET_RETVAL_NV ;    

    OUTPUT:
     RETVAL

void
list_c(x)
	pdl *x
	PPCODE:
	PDL_Long *inds;
	int ind;
	int stop = 0;
        pdl_make_physical( x );
	inds = pdl_malloc(sizeof(PDL_Long) * x->ndims); /* GCC -> on stack :( */
	EXTEND(sp,x->nvals);
	for(ind=0; ind < x->ndims; ind++) inds[ind] = 0;
	while(!stop) {
		PUSHs(sv_2mortal(newSVnv(pdl_at( x->data, x->datatype,
			inds, x->dims, x->dimincs, 0, x->ndims))));
		stop = 1;
		for(ind = 0; ind < x->ndims; ind++) 
			if(++(inds[ind]) >= x->dims[ind]) 
				inds[ind] = 0; 
			else 
				{stop = 0; break;}
	}

void
set_c(x,position,value)
   pdl*	x
   PDL_Long *	pos = NO_INIT
   double	value
   CODE:
    int npos;

    pdl_make_physical( x );

    pos = pdl_packdims( ST(1), &npos);
    if (pos == NULL || npos != x->ndims) 
       croak("Invalid position");

    pdl_children_changesoon( x , PDL_PARENTDATACHANGED );
    pdl_set( x->data, x->datatype, pos, x->dims, x->dimincs, 0, x->ndims, value);
    pdl_changed( x , PDL_PARENTDATACHANGED , 0 );


# Call an external C routine loaded dynamically - pass PDL args list

void
callext_c(...)
     PPCODE:
        int (*symref)(int npdl, pdl **x);
        int npdl = items-1;
        pdl **x;
        int i;

        symref = (int(*)(int, pdl**)) SvIV(ST(0));

        x = (pdl**) pdl_malloc( npdl * sizeof(pdl*) );
        for(i=0; i<npdl; i++) 
           x[i] = SvPDLV(ST(i+1));

        i = (*symref)(npdl, x);
        if (i==0)
           croak("Error calling external routine");

BOOT:

   /* Initialise structure of pointers to core C routines */

   PDL.SvPDLV      = SvPDLV;
   PDL.SetSV_PDL   = SetSV_PDL;
   PDL.copy        = pdl_copy;
   PDL.converttype = pdl_converttype;
   PDL.twod        = pdl_twod;
   PDL.malloc      = pdl_malloc;
   PDL.howbig      = pdl_howbig;
   PDL.packdims    = pdl_packdims;
   PDL.unpackdims  = pdl_unpackdims;
   PDL.grow        = pdl_grow;
   PDL.flushcache  = NULL;
   PDL.reallocdims = pdl_reallocdims;
   PDL.reallocthreadids = pdl_reallocthreadids;
   PDL.resize_defaultincs = pdl_resize_defaultincs;
   PDL.thread_copy = pdl_thread_copy;
   PDL.clearthreadstruct = pdl_clearthreadstruct;
   PDL.initthreadstruct = pdl_initthreadstruct;
   PDL.startthreadloop = pdl_startthreadloop;
   PDL.iterthreadloop = pdl_iterthreadloop;
   PDL.freethreadloop = pdl_freethreadloop;
   PDL.thread_create_parameter = pdl_thread_create_parameter;

   PDL.setdims_careful = pdl_setdims_careful;
   PDL.put_offs = pdl_put_offs;
   PDL.get_offs = pdl_get_offs;
   PDL.get = pdl_get;
   PDL.set_trans_childtrans = pdl_set_trans_childtrans;
   PDL.set_trans_parenttrans = pdl_set_trans_parenttrans;
   PDL.make_now = pdl_make_now;

   PDL.get_convertedpdl = pdl_get_convertedpdl;

   PDL.make_trans_mutual = pdl_make_trans_mutual;
   PDL.trans_mallocfreeproc = pdl_trans_mallocfreeproc;
   /* 
      "Publish" pointer to this structure in perl variable for use
       by other modules
   */

   sv_setiv(perl_get_sv("PDL::SHARE",TRUE), (IV) (void*) &PDL);

# version of eval() which propogates errors encountered in
# any internal eval(). Must be passed a code reference - could
# be use perl_eval_sv() but that is still buggy. This subroutine is 
# primarily for the perlDL shell to use.
#
# Thanks to Sarathy (gsar@engin.umich.edu) for suggesting this, though
# it needs to be wrapped up in the stack stuff to avoid certain SEGVs!

void
myeval(code)
  SV *	code;
  PROTOTYPE: $
  CODE:
   PUSHMARK(sp) ;
   perl_call_sv(code, G_EVAL|G_KEEPERR|GIMME);

MODULE = PDL::Core	PACKAGE = PDL	PREFIX = pdl_

pdl *
pdl_null(...)


void
pdl_make_physical(self)
	pdl *self;


void
pdl_make_physdims(self)
	pdl *self;

void
pdl_dump(x)
  pdl *x;

MODULE = PDL::Core	PACKAGE = PDL	

SV *
get_dataref(self)
	pdl *self
	CODE:
	pdl_make_physical(self); /* XXX IS THIS MEMLEAK WITHOUT MORTAL? */
	RETVAL = (newRV(self->datasv));
	OUTPUT:
	RETVAL

int
get_datatype(self)
	pdl *self
	CODE:
	RETVAL = self->datatype;
	OUTPUT:
	RETVAL

int 
upd_data(self)
	pdl *self
	CODE:
	self->data = SvPV((SV*)self->datasv,na);
	XSRETURN(0);

void
set_dataflow_f(self,value)
	pdl *self;
	int value;
	CODE:
	if(value) 
		self->state |= PDL_DATAFLOW_F;
	else 
		self->state &= ~PDL_DATAFLOW_F;

void
set_dataflow_b(self,value)
	pdl *self;
	int value;
	CODE:
	if(value) 
		self->state |= PDL_DATAFLOW_B;
	else 
		self->state &= ~PDL_DATAFLOW_B;

int
getndims(x)
	pdl *x
	CODE:
		pdl_make_physdims(x);
		RETVAL = x->ndims;
	OUTPUT:
		RETVAL

int 
getdim(x,y)
	pdl *x
	int y
	CODE:
		RETVAL = x->dims[y];
	OUTPUT:
		RETVAL

int 
getnthreadids(x)
	pdl *x
	CODE:
		pdl_make_physdims(x);
		RETVAL = x->nthreadids;
	OUTPUT:
		RETVAL

int 
getthreadid(x,y)
	pdl *x
	int y
	CODE:
		RETVAL = x->threadids[y];
	OUTPUT:
		RETVAL

void
setdims(x,dims)
	pdl *x
	PDL_Long *dims = NO_INIT
	CODE:
	{
		int ndims; int i;
		dims = pdl_packdims(ST(1),&ndims);
		pdl_reallocdims(x,ndims);
		for(i=0; i<ndims; i++) x->dims[i] = dims[i];
		pdl_resize_defaultincs(x);
		x->threadids[0] = ndims;

		   if(ndims == 1 && dims[0] == 0) {
			x->state |= PDL_NOMYDIMS;
		   } else {
			x->state &= ~PDL_NOMYDIMS;
		   }
	}

void
dowhenidle()
	CODE:
		pdl_run_delayed_magic();
		XSRETURN(0);

void
bind(p,c)
	pdl *p
	SV *c
	PROTOTYPE: $&
	CODE:
		pdl_add_svmagic(p,c);
		XSRETURN(0);



void
set_datatype(a,datatype)
   pdl *a
   int datatype
   CODE:
    pdl_make_physical(a);
    if(a->trans) 
	    pdl_destroytransform(a->trans,1);
/*     if(! (a->state && PDL_NOMYDIMS)) { */
    pdl_converttype( &a, datatype, PDL_PERM );
/*     } */

void
threadover_n(...)
   CODE:
   {
    int npdls = items - 1;
    if(npdls <= 0) 
    	croak("Usage: threadover_n(pdl[,pdl...],sub)");
    {
	    int i,sd;
	    pdl **pdls = malloc(sizeof(pdl *) * npdls);
	    int *realdims = malloc(sizeof(int) * npdls);
	    pdl_thread thr;
	    SV *code = ST(items-1);
	    for(i=0; i<npdls; i++) {
		pdls[i] = SvPDLV(ST(i));
		realdims[i] = 0;
	    }
	    pdl_initthreadstruct(0,pdls,realdims,realdims,npdls,NULL,&thr);
	    pdl_startthreadloop(&thr);
	    sd = thr.ndims;
	    do {
	    	dSP;
		PUSHMARK(sp);
		EXTEND(sp,items);
		PUSHs(sv_2mortal(newSViv((sd-1))));
		for(i=0; i<npdls; i++) {
			PUSHs(sv_2mortal(newSVnv(
				pdl_get_offs(pdls[i],thr.offs[i]))));
		}
	    	PUTBACK;
		perl_call_sv(code,G_DISCARD);
	    } while(sd = pdl_iterthreadloop(&thr,0));
	    pdl_freethreadloop(&thr);
	    free(pdls);
	    free(realdims);
    }
   }



