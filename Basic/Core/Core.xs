
/* 
   Core.xs

*/

#include <unistd.h>
#include <sys/mman.h>
#include <fcntl.h>

#include "EXTERN.h"   /* std perl include */
#include "perl.h"     /* std perl include */
#include "XSUB.h"     /* XSUB include */

#if defined(CONTEXT)
#undef CONTEXT
#endif

#define PDL_CORE      /* For certain ifdefs */
#include "pdl.h"      /* Data structure declarations */
#include "pdlcore.h"  /* Core declarations */

/* Return a integer or numeric scalar as approroate */

#define setflag(reg,flagval,val) (val?(reg |= flagval):(reg &= ~flagval))

#define SET_RETVAL_NV x->datatype<PDL_F ? (RETVAL=newSViv( (IV)result )) : (RETVAL=newSVnv( result ))

#ifndef __CYGWIN32__
#define USE_MMAP
#endif

Core PDL; /* Struct holding pointers to shared C routines */

#ifdef FOO
Core *pdl__Core_get_Core() /* INTERNAL TO CORE! DON'T CALL FROM OUTSIDE */
{
	return PDL;
}
#endif

int pdl_debugging=0;

#define CHECKP(p)    if ((p) == NULL) barf("Out of memory")

static int* pdl_packint( SV* sv, int *ndims ) {

   SV*  bar;
   AV*  array;
   int i;
   int *dims;

   if (!(SvROK(sv) && SvTYPE(SvRV(sv))==SVt_PVAV))  /* Test */
       return NULL;
   array = (AV *) SvRV(sv);   /* dereference */
     *ndims = (int) av_len(array) + 1;  /* Number of dimensions */
   /* Array space */
   dims = (int *) pdl_malloc( (*ndims) * sizeof(*dims) );
   CHECKP(dims);

   for(i=0; i<(*ndims); i++) {
      bar = *(av_fetch( array, i, 0 )); /* Fetch */
      dims[i] = (int) SvIV(bar); 
   }
   return dims;
} 

static SV* pdl_unpackint ( PDL_Long *dims, int ndims ) {

   AV*  array;
   int i;

   array = newAV();

   for(i=0; i<ndims; i++) /* if ndims == 0, nothing stored -> ok */
         av_store( array, i, newSViv( (IV)dims[i] ) );

   return (SV*) array;
}

MODULE = PDL::Core     PACKAGE = PDL


# Destroy a PDL - note if a hash do nothing, the $$x{PDL} component
# will be destroyed anyway on a separate call

void
DESTROY(sv)
  SV *	sv;
  CODE:
    pdl *self;
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV) 
       1; /* Do nothing */
    else {
       self = SvPDLV(sv);
       PDLDEBUG_f(printf("DESTROYING %d\n",self);)
       if (self != NULL) 
          pdl_destroy(self);
    }

# Return the transformation object or an undef otherwise.

SV *
get_trans(self)
	pdl *self;
	CODE:
	ST(0) = sv_newmortal();
	if(self->trans)  {
		sv_setref_pv(ST(0), "PDL::Trans", (void*)(self->trans));
	} else {
		ST(0) = &sv_undef;
	}

# This will change in the future, as can be seen from the name ;)
# the argument passing is a real quick hack: you can pass 3 integers
# and nothing else.

MODULE = PDL::Core	PACKAGE = PDL::Trans
void
call_trans_foomethod(trans,i1,i2,i3)
	pdl_trans *trans
	int i1
	int i2
	int i3
	CODE:
	PDL_TR_CHKMAGIC(trans);
	pdl_trans_changesoon(trans,PDL_PARENTDIMSCHANGED|PDL_PARENTDATACHANGED);
	if(trans->vtable->foomethod == NULL) {
		barf("This transformation doesn't have a foomethod!");
	}
	(trans->vtable->foomethod)(trans,i1,i2,i3);
	pdl_trans_changed(trans,PDL_PARENTDIMSCHANGED|PDL_PARENTDATACHANGED);

MODULE = PDL::Core	PACKAGE = PDL

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


int
donttouch(self)
  pdl *self;
  CODE:
    RETVAL = (self->state & PDL_DONTTOUCHDATA) != 0;
  OUTPUT:
    RETVAL


int
allocated(self)
  pdl *self;
  CODE:
    RETVAL = (self->state & PDL_ALLOCATED) != 0;
  OUTPUT:
    RETVAL

int
vaffine(self)
  pdl *self;
  CODE:
    RETVAL = (self->state & PDL_OPT_VAFFTRANSOK) != 0;
  OUTPUT:
    RETVAL

int
anychgd(self)
  pdl *self;
  CODE:
    RETVAL = (self->state & PDL_ANYCHANGED) != 0;
  OUTPUT:
    RETVAL

int
address(self)
  pdl *self;
  CODE:
    RETVAL = (int) self;
  OUTPUT:
    RETVAL

int
dimschgd(self)
  pdl *self;
  CODE:
    RETVAL = (self->state & PDL_PARENTDIMSCHANGED) != 0;
  OUTPUT:
    RETVAL



pdl *
pdl_hard_copy(src)
	pdl *src;

pdl *
sever(src)
	pdl *src;
	CODE:
		if(src->trans) {
			pdl_destroytransform(src->trans,1);
		}
		RETVAL=src;
	OUTPUT:
		RETVAL

int
set_data_by_mmap(it,fname,len,writable,shared,creat,mode,trunc)
	pdl *it
	char *fname
	int len
	int writable
	int shared
	int creat
	int mode
	int trunc
	CODE:
#ifdef USE_MMAP
		int fd;
		pdl_freedata(it);
		fd = open(fname,(writable && shared ? O_RDWR : O_RDONLY)|
			(creat ? O_CREAT : 0),mode);
		if(fd < 0) {
			barf("Error opening file");
		}
		if(trunc) {
			ftruncate(fd,0);   /* Clear all previous data */
			ftruncate(fd,len); /* And make it long enough */
		}
		it->data = mmap(0,len,PROT_READ | (writable ? 
					PROT_WRITE : 0),
				(shared ? MAP_SHARED : MAP_PRIVATE),
				fd,0);

		PDLDEBUG_f(printf("PDL::MMap: mapped to %d\n",it->data);)
		if(!it->data)
			barf("Error mmapping!");
		it->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
		pdl_add_deletedata_magic(it, pdl_delete_mmapped_data, len);
#else
	barf("mmap not supported on this architecture");
#endif
		RETVAL = 1;
	OUTPUT:
		RETVAL


int
set_data_by_offset(it,orig,offset)
      pdl *it
      pdl *orig
      int offset
      CODE:
              pdl_freedata(it);
              it->data = ((char *) orig->data) + offset;
              it->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
              RETVAL = 1;
      OUTPUT:
              RETVAL

int
nelem(x)
	pdl *x
	CODE:
		pdl_make_physdims(x);
		RETVAL = x->nvals;
	OUTPUT:
		RETVAL

# Convert PDL to new datatype (called by float(), int() etc.)

# SV *
# convert(a,datatype)
#    pdl*	a
#    int	datatype
#    CODE:
#     pdl* b;
#     pdl_make_physical(a);
#     RETVAL = pdl_copy(a,""); /* Init value to return */
#     b = SvPDLV(RETVAL);      /* Map */
#     pdl_converttype( &b, datatype, PDL_PERM );
#     PDLDEBUG_f(printf("converted %d, %d, %d, %d\n",a, b, a->datatype, b->datatype));

#     OUTPUT:
#      RETVAL


# Call my howbig function

int
howbig_c(datatype)
   int	datatype
   CODE:
     RETVAL = pdl_howbig(datatype);
   OUTPUT:
     RETVAL

MODULE = PDL::Core     PACKAGE = PDL::Core

int
set_debugging(i)
	int i;
	CODE:
	RETVAL = pdl_debugging;
	pdl_debugging = i;
	OUTPUT:
	RETVAL



SV *
at_c(x,position)
   pdl*	x
   PDL_Long *	pos = NO_INIT
   CODE:
    int npos;
    double result;

      pdl_make_physvaffine( x );

    pos = pdl_packdims( ST(1), &npos);
    if (pos == NULL || npos != x->ndims) 
       barf("Invalid position");

    result=pdl_at(PDL_REPRP(x), x->datatype, pos, x->dims,
        (PDL_VAFFOK(x) ? x->vafftrans->incs : x->dimincs), PDL_REPROFFS(x),
	x->ndims);

    SET_RETVAL_NV ;    

    OUTPUT:
     RETVAL

void
list_c(x)
	pdl *x
	PPCODE:
	PDL_Long *inds,*incs,offs;
	void *data;
	int ind;
	int stop = 0;
        pdl_make_physvaffine( x );
	inds = pdl_malloc(sizeof(PDL_Long) * x->ndims); /* GCC -> on stack :( */

	data = PDL_REPRP(x);
	incs = (PDL_VAFFOK(x) ? x->vafftrans->incs : x->dimincs);
	offs = PDL_REPROFFS(x);
	EXTEND(sp,x->nvals);
	for(ind=0; ind < x->ndims; ind++) inds[ind] = 0;
	while(!stop) {
		PUSHs(sv_2mortal(newSVnv(pdl_at( data, x->datatype,
			inds, x->dims, incs, offs, x->ndims))));
		stop = 1;
		for(ind = 0; ind < x->ndims; ind++) 
			if(++(inds[ind]) >= x->dims[ind]) 
				inds[ind] = 0; 
			else 
				{stop = 0; break;}
	}

void
listref_c(x)
	pdl *x
	PPCODE:
	PDL_Long *inds,*incs,offs;
	void *data;
	int ind;
	int lind;
	int stop = 0;
	AV *av;
        pdl_make_physvaffine( x );
	inds = pdl_malloc(sizeof(PDL_Long) * x->ndims); /* GCC -> on stack :( */
	data = PDL_REPRP(x);
	incs = (PDL_VAFFOK(x) ? x->vafftrans->incs : x->dimincs);
	offs = PDL_REPROFFS(x);
	av = newAV();
	av_extend(av,x->nvals);
	lind=0;
	for(ind=0; ind < x->ndims; ind++) inds[ind] = 0;
	while(!stop) {
		av_store(av,lind,newSVnv(pdl_at( data, x->datatype,
			inds, x->dims, incs, offs, x->ndims)));
		lind++;
		stop = 1;
		for(ind = 0; ind < x->ndims; ind++) 
			if(++(inds[ind]) >= x->dims[ind]) 
				inds[ind] = 0; 
			else 
				{stop = 0; break;}
	}
	EXTEND(sp,1);
	PUSHs(sv_2mortal(newRV_noinc((SV *)av)));

void
set_c(x,position,value)
   pdl*	x
   PDL_Long *	pos = NO_INIT
   double	value
   CODE:
    int npos;

    pdl_make_physvaffine( x );

    pos = pdl_packdims( ST(1), &npos);
    if (pos == NULL || npos != x->ndims) 
       barf("Invalid position");

    pdl_children_changesoon( x , PDL_PARENTDATACHANGED );
    pdl_set(PDL_REPRP(x), x->datatype, pos, x->dims,
        (PDL_VAFFOK(x) ? x->vafftrans->incs : x->dimincs), PDL_REPROFFS(x),
	x->ndims,value);
    if (PDL_VAFFOK(x))
       pdl_vaffinechanged(x, PDL_PARENTDATACHANGED);
    else
       pdl_changed( x , PDL_PARENTDATACHANGED , 0 );


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
   PDL.get_threadoffsp = pdl_get_threadoffsp;
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
   PDL.make_physical = pdl_make_physical;
   PDL.make_physdims = pdl_make_physdims;
   PDL.pdl_barf      = pdl_barf;
   
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

int
isnull(self)
	pdl *self;
	CODE:
		RETVAL= !!(self->state & PDL_NOMYDIMS);
	OUTPUT:
		RETVAL


void
pdl_make_physical(self)
	pdl *self;


void
pdl_make_physdims(self)
	pdl *self;

void
pdl_dump(x)
  pdl *x;

void
pdl_add_threading_magic(it,nthdim,nthreads)
	pdl *it
	int nthdim
	int nthreads

void
pdl_remove_threading_magic(it)
	pdl *it
	CODE:
		pdl_add_threading_magic(it,-1,-1);

MODULE = PDL::Core	PACKAGE = PDL	

SV *
get_dataref(self)
	pdl *self
	CODE:
	if(self->state & PDL_DONTTOUCHDATA) {
		barf("Trying to get dataref to magical (mmaped?) pdl");
	}
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
	if(self->state & PDL_DONTTOUCHDATA) {
		barf("Trying to touch dataref of magical (mmaped?) pdl");
	}
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
		pdl_make_physdims(x);
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
		pdl_children_changesoon(x,PDL_PARENTDIMSCHANGED|PDL_PARENTDATACHANGED);
		dims = pdl_packdims(ST(1),&ndims);
		pdl_reallocdims(x,ndims);
		for(i=0; i<ndims; i++) x->dims[i] = dims[i];
		pdl_resize_defaultincs(x);
		x->threadids[0] = ndims;
 /* make null != dims = [0] */
#ifndef ELIFJELFIJSEJIF
		x->state &= ~PDL_NOMYDIMS;
#else
		   if(ndims == 1 && dims[0] == 0) {
			x->state |= PDL_NOMYDIMS;
		   } else {
			x->state &= ~PDL_NOMYDIMS;
		   }
#endif
		pdl_changed(x,PDL_PARENTDIMSCHANGED|PDL_PARENTDATACHANGED,0);
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
sethdr(p,h)
	pdl *p
	SV *h
	CODE:
	HV* hash;
		if(p->hdrsv == NULL) {
		      p->hdrsv = (void*) newSViv(0);
		}
		if (!SvROK(h) || SvTYPE(SvRV(h)) != SVt_PVHV) 
		      barf("Not a HASH reference");		
		p->hdrsv = (void*) newRV( (SV*) SvRV(h) );

SV *
gethdr(p)
	pdl *p
	CODE:
		if(p->hdrsv) {
		   RETVAL = newRV( (SV*) SvRV((SV*)p->hdrsv) );
		} else {
		   XSRETURN_UNDEF;
		}
	OUTPUT:
	 RETVAL

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
    	barf("Usage: threadover_n(pdl[,pdl...],sub)");
    {
	    int i,sd;
	    pdl **pdls = malloc(sizeof(pdl *) * npdls);
	    int *realdims = malloc(sizeof(int) * npdls);
	    pdl_thread thr;
	    SV *code = ST(items-1);
	    for(i=0; i<npdls; i++) {
		pdls[i] = SvPDLV(ST(i));
		/* XXXXXXXX Bad */
		pdl_make_physical(pdls[i]);
		realdims[i] = 0;
	    }
	    pdl_initthreadstruct(0,pdls,realdims,realdims,npdls,NULL,&thr,NULL);
	    pdl_startthreadloop(&thr,NULL,NULL);
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

void
threadover(...)
   CODE:
   {
    int npdls, nothers = -1;
    int targs = items - 4;
    if (items > 0) nothers = SvIV(ST(0));
    if(targs <= 0 || nothers < 0 || nothers >= targs) 
    	barf("Usage: threadover(nothers,pdl[,pdl...][,otherpars..],realdims,creating,sub)");
    npdls = targs-nothers;
    {
	    int i,j,nd1,nd2,dtype=0,nc=npdls;
	    SV* rdimslist = ST(items-3);
	    SV* cdimslist = ST(items-2);
	    SV *code = ST(items-1);
	    pdl_thread thr;
	    pdl **pdls = malloc(sizeof(pdl *) * npdls);
	    pdl **child = malloc(sizeof(pdl *) * npdls);
	    SV **csv = malloc(sizeof(SV *) * npdls);
	    SV **dims = malloc(sizeof(SV *) * npdls);
	    SV **incs = malloc(sizeof(SV *) * npdls);
	    SV **others = malloc(sizeof(SV *) * nothers);
	    int *creating = pdl_packint(cdimslist,&nd2);
	    int *realdims = pdl_packint(rdimslist,&nd1);
	    CHECKP(pdls); CHECKP(child); CHECKP(dims); 
	    CHECKP(incs); CHECKP(csv);

	    if (nd1 != npdls || nd2 < npdls)
		barf("threadover: need one realdim and creating flag "
		      "per pdl!");
	    for(i=0; i<npdls; i++) {
		pdls[i] = SvPDLV(ST(i+1));
		if (creating[i])
		  nc += realdims[i];
		else {
		  pdl_make_physical(pdls[i]); /* is this what we want?XXX */
		  dtype = PDLMAX(dtype,pdls[i]->datatype);
		}
	    }
	    for (i=npdls+1; i<=targs; i++)
		others[i-npdls-1] = ST(i);
	    if (nd2 < nc)
		barf("Not enough dimension info to create pdls");
#ifdef DEBUG_PTHREAD
		for (i=0;i<npdls;i++) { /* just for debugging purposes */
		printf("pdl %d Dims: [",i);
		for (j=0;j<realdims[i];j++)
			printf("%d ",pdls[i]->dims[j]);
		printf("] Incs: [");
		for (j=0;j<realdims[i];j++)
			printf("%d ",PDL_REPRINC(pdls[i],j));
		printf("]\n");
	        }
#endif
	    pdl_initthreadstruct(0,pdls,realdims,creating,npdls,
				NULL,&thr,NULL);
	    for(i=0, nc=npdls; i<npdls; i++)  /* create as necessary */
              if (creating[i]) {
		int *cp = creating+nc;
		pdls[i]->datatype = dtype;
		pdl_thread_create_parameter(&thr,i,cp,0);
		nc += realdims[i];
		pdl_make_physical(pdls[i]);
		PDLDEBUG_f(pdl_dump(pdls[i]));
		/* And make it nonnull, now that we've created it */
		pdls[i]->state &= (~PDL_NOMYDIMS);
	      }
	    pdl_startthreadloop(&thr,NULL,NULL);
	    for(i=0; i<npdls; i++) { /* will the SV*'s be properly freed? */
		dims[i] = newRV(pdl_unpackint(pdls[i]->dims,realdims[i]));
		incs[i] = newRV(pdl_unpackint(PDL_VAFFOK(pdls[i]) ?
		pdls[i]->vafftrans->incs: pdls[i]->dimincs,realdims[i]));
		/* need to make sure we get the vaffine (grand)parent */
		if (PDL_VAFFOK(pdls[i]))
		   pdls[i] = pdls[i]->vafftrans->from;
		child[i]=pdl_null();
		/*  instead of pdls[i] its vaffine parent !!!XXX */
		PDL.affine_new(pdls[i],child[i],thr.offs[i],dims[i],
						incs[i]);
		pdl_make_physical(child[i]); /* make sure we can get at
						the vafftrans          */
		csv[i] = sv_newmortal();
		SetSV_PDL(csv[i], child[i]); /* pdl* into SV* */
	    }
	    do {  /* the actual threadloop */
		pdl_trans_affine *traff;
	    	dSP;
		PUSHMARK(sp);
		EXTEND(sp,npdls);
		for(i=0; i<npdls; i++) {
		   /* just twiddle the offset - quick and dirty */
		   /* we must twiddle both !! */
		   traff = (pdl_trans_affine *) child[i]->trans;
		   traff->offs = thr.offs[i];
		   child[i]->vafftrans->offs = thr.offs[i];
		   child[i]->state |= PDL_PARENTDATACHANGED;
		   PUSHs(csv[i]);
		}
		for (i=0; i<nothers; i++)
		  PUSHs(others[i]);   /* pass the OtherArgs onto the stack */
	    	PUTBACK;
		perl_call_sv(code,G_DISCARD);
	    } while (pdl_iterthreadloop(&thr,0));
	    pdl_freethreadloop(&thr);
	    free(pdls);  /* should all these be done with pdl_malloc */
	    free(dims);  /* in case the sub barfs ? XXXX            */
	    free(child);
	    free(csv);
	    free(incs);
	    free(others);
    }
   }

