
#include "EXTERN.h"   /* std perl include */
#include "perl.h"     /* std perl include */
#include "ppport.h"
#include "XSUB.h"  /* for the win32 perlCAPI crap */

#if defined(CONTEXT) && defined(__osf__)
#undef CONTEXT
#endif

#include "pdl.h"
#include "pdlthread.h"
#include "pdlmagic.h"

#define PDL_TMP  0        /* Flags */
#define PDL_PERM 1

#define BIGGESTOF(a,b) ( a->nvals>b->nvals ? a->nvals : b->nvals )

/* our croak replacement */

#ifdef PDL_CORE
#define barf pdl_barf
#else
#define barf PDL->pdl_barf
#endif

typedef int Logical;

/*************** Function prototypes *********************/


/* pdlcore.c */

int     pdl_howbig (int datatype);           /* Size of data type (bytes) */
pdl*    SvPDLV ( SV* sv );                   /* Map SV* to pdl struct */
void	SetSV_PDL( SV *sv, pdl *it );	     /* Outputting a pdl from.. */
SV*     pdl_copy( pdl* a, char* option );     /* call copy method */
PDL_Long *    pdl_packdims ( SV* sv, int*ndims ); /* Pack dims[] into SV aref */
void    pdl_unpackdims ( SV* sv, PDL_Long *dims,  /* Unpack */
                         int ndims );
void*   pdl_malloc ( int nbytes );           /* malloc memory - auto free()*/

void pdl_makescratchhash(pdl *ret,double data, int datatype);
PDL_Long pdl_safe_indterm(PDL_Long dsz, PDL_Long at, char *file, int lineno);
void pdl_barf(const char* pat,...); /* General croaking utility */

/* pdlapi.c */

void pdl_vaffinechanged(pdl *it, int what);
void pdl_trans_mallocfreeproc(struct pdl_trans *tr);
void pdl_make_trans_mutual(pdl_trans *trans);
void pdl_destroytransform_nonmutual(pdl_trans *trans,int ensure);

void pdl_vafftrans_free(pdl *it);
void pdl_vafftrans_remove(pdl * it);
void pdl_make_physvaffine(pdl *it);
void pdl_vafftrans_alloc(pdl *it);

pdl *pdl_null();
pdl *pdl_get_convertedpdl(pdl *pdl,int type);

void pdl_destroytransform(pdl_trans *trans,int ensure);
pdl *pdl_make_now(pdl *it);

pdl *pdl_hard_copy(pdl *src);

#define pdl_new() pdl_create(PDL_PERM)
#define pdl_tmp() pdl_create(PDL_TMP)
pdl* pdl_external_new();
pdl* pdl_external_tmp();
pdl* pdl_create(int type);
void pdl_destroy(pdl *it);
void pdl_setdims(pdl* it, PDL_Long* dims, int ndims);
void pdl_reallocdims ( pdl *it,int ndims );  /* reallocate dims and incs */
void pdl_reallocthreadids ( pdl *it,int ndims );  /* reallocate threadids */
void pdl_resize_defaultincs ( pdl *it );     /* Make incs out of dims */
void pdl_unpackarray ( HV* hash, char *key, int *dims, int ndims );
void pdl_print(pdl *it);
void pdl_dump(pdl *it);
void pdl_allocdata(pdl *it);

int *pdl_get_threadoffsp(pdl_thread *thread); /* For pthreading */
void pdl_thread_copy(pdl_thread *from,pdl_thread *to);
void pdl_clearthreadstruct(pdl_thread *it);
void pdl_initthreadstruct(int nobl,pdl **pdls,int *realdims,int *creating,int npdls,
	pdl_errorinfo *info,pdl_thread *thread,char *flags);
int pdl_startthreadloop(pdl_thread *thread,void (*func)(pdl_trans *),pdl_trans *);
int pdl_iterthreadloop(pdl_thread *thread,int which);
void pdl_freethreadloop(pdl_thread *thread);
void pdl_thread_create_parameter(pdl_thread *thread,int j,int *dims,
				 int temp);
void pdl_croak_param(pdl_errorinfo *info,int j, char *pat, ...);

void pdl_setdims_careful(pdl *pdl);
void pdl_put_offs(pdl *pdl,PDL_Long offs, double val);
double pdl_get_offs(pdl *pdl,PDL_Long offs);
double pdl_get(pdl *pdl,int *inds);
void pdl_set_trans(pdl *it, pdl *parent, pdl_transvtable *vtable);

void pdl_make_physical(pdl *it);
void pdl_make_physdims(pdl *it);

void pdl_children_changesoon(pdl *it, int what);
void pdl_changed(pdl *it, int what, int recursing);
void pdl_separatefromparent(pdl *it);

void pdl_trans_changesoon(pdl_trans *trans,int what);
void pdl_trans_changed(pdl_trans *trans,int what);

void pdl_set_trans_childtrans(pdl *it, pdl_trans *trans,int nth);
void pdl_set_trans_parenttrans(pdl *it, pdl_trans *trans,int nth);

/* pdlhash.c */

pdl*    pdl_getcache( HV* hash );       /* Retrieve address of $$x{PDL} */
pdl*    pdl_fillcache( HV* hash, SV* ref);       /* Fill/create $$x{PDL} cache */
void    pdl_fillcache_partial( HV *hash, pdl *thepdl ) ;
SV*     pdl_getKey( HV* hash, char* key );  /* Get $$x{Key} SV* with deref */
void pdl_flushcache( pdl *thepdl );	     /* flush cache */

/* pdlfamily.c */

void pdl_family_create(pdl *from,pdl_trans *trans,int ind1,int ind2);
pdl *pdl_family_clone2now(pdl *from); /* Use pdl_make_now instead */


/* pdlconv.c */

void pdl_writebackdata_vaffine(pdl *it);
void pdl_readdata_vaffine(pdl *it);

void   pdl_swap(pdl** a, pdl** b);             /* Swap two pdl ptrs */
void   pdl_converttype( pdl** a, int targtype, /* Change type of a pdl */
                        Logical changePerl );
void   pdl_coercetypes( pdl** a, pdl **b, Logical changePerl ); /* Two types to same */
void   pdl_grow  ( pdl* a, int newsize);      /* Change pdl 'Data' size */
void   pdl_retype( pdl* a, int newtype);      /* Change pdl 'Datatype' value */
void** pdl_twod( pdl* x );                    /* Return 2D pointer to data array */

/* pdlsections.c */

int  pdl_get_offset(PDL_Long* pos, PDL_Long* dims, PDL_Long *incs, PDL_Long offset, int ndims);      /* Offset of pixel x,y,z... */
int  pdl_validate_section( int* sec, int* dims,           /* Check section */
                           int ndims );
void pdl_row_plusplus ( int* pos, int* dims,              /* Move down one row */
                        int ndims );
void pdl_subsection( char *y, char*x, int datatype,      /* Take subsection */
                 int* sec, int* dims, int *incs, int offset, int* ndims);
void pdl_insertin( char*y, int* ydims, int nydims,        /* Insert pdl in pdl */
                   char*x, int* xdims, int nxdims,
                   int datatype, int* pos);
double pdl_at( void* x, int datatype, PDL_Long* pos, PDL_Long* dims, /* Value at x,y,z,... */
             PDL_Long *incs, PDL_Long offset, int ndims);
void  pdl_set( void* x, int datatype, PDL_Long* pos, PDL_Long* dims, /* Set value at x,y,z... */
                PDL_Long *incs, PDL_Long offs, int ndims, double value);
void pdl_axisvals( pdl* a, int axis );               /* Fill with axis values */

/* pdlstats.c */

double pdl_min(void*x, int n, int datatype);
double pdl_max(void*x, int n, int datatype);
double pdl_sum(void*x, int n, int datatype);

/* pdlmoremaths.c */

void pdl_convolve (pdl* c, pdl* a, pdl* b); /* Real space convolution */
void pdl_hist (pdl* c, pdl* a, double min, double step) ; /* Histogram of data */
void pdl_matrixmult( pdl *c, pdl* a, pdl* b);  /* Matrix multiplication */

/* Structure to hold pointers core PDL routines so as to be used by many modules */

#define PDL_CORE_VERSION 1

struct Core {
    I32    Version;
    pdl*   (*SvPDLV)      ( SV*  );
    void   (*SetSV_PDL)( SV *sv, pdl *it );
    pdl*   (*new)         ( );
    pdl*   (*tmp)         ( );
    pdl*   (*create)      (int type);
    void   (*destroy)     (pdl *it);
    pdl*   (*null)        ();
    SV*    (*copy)        ( pdl*, char* );
    void   (*converttype) ( pdl**, int, Logical );
    void** (*twod)        ( pdl* );
    void*  (*malloc)      ( int );
    int    (*howbig)      ( int );
    PDL_Long*   (*packdims)    ( SV* sv, int *ndims ); /* Pack dims[] into SV aref */
    void   (*setdims)     ( pdl* it, PDL_Long* dims, int ndims );
    void   (*unpackdims)  ( SV* sv, PDL_Long *dims,    /* Unpack */
                            int ndims );
    void   (*grow)        ( pdl* a, int newsize); /* Change pdl 'Data' size */
    void (*flushcache)( pdl *thepdl );	     /* flush cache */
    void (*reallocdims) ( pdl *it,int ndims );  /* reallocate dims and incs */
    void (*reallocthreadids) ( pdl *it,int ndims );
    void (*resize_defaultincs) ( pdl *it );     /* Make incs out of dims */

void (*thread_copy)(pdl_thread *from,pdl_thread *to);
void (*clearthreadstruct)(pdl_thread *it);
void (*initthreadstruct)(int nobl,pdl **pdls,int *realdims,int *creating,int npdls,
	pdl_errorinfo *info,pdl_thread *thread,char *flags);
int (*startthreadloop)(pdl_thread *thread,void (*func)(pdl_trans *),pdl_trans *);
int *(*get_threadoffsp)(pdl_thread *thread); /* For pthreading */
int (*iterthreadloop)(pdl_thread *thread,int which);
void (*freethreadloop)(pdl_thread *thread);
void (*thread_create_parameter)(pdl_thread *thread,int j,int *dims,
				int temp);
void (*add_deletedata_magic) (pdl *it,void (*func)(pdl *, int param), int param); /* Automagic destructor */
  

/* XXX NOT YET IMPLEMENTED */
void (*setdims_careful)(pdl *pdl);
void (*put_offs)(pdl *pdl,PDL_Long offs, double val);
double (*get_offs)(pdl *pdl,PDL_Long offs);
double (*get)(pdl *pdl,int *inds);
void (*set_trans_childtrans)(pdl *it, pdl_trans *trans,int nth);
void (*set_trans_parenttrans)(pdl *it, pdl_trans *trans,int nth);
pdl *(*make_now)(pdl *it);

pdl *(*get_convertedpdl)(pdl *pdl,int type);

void (*make_trans_mutual)(pdl_trans *trans);

/* Affine trans. THESE ARE SET IN ONE OF THE OTHER Basic MODULES
   and not in Core.xs ! */
void (*readdata_affine)(pdl_trans *tr);
void (*writebackdata_affine)(pdl_trans *tr);
void (*affine_new)(pdl *par,pdl *child,int offs,SV *dims,SV *incs);

/* Converttype. Similar */
void (*converttypei_new)(pdl *par,pdl *child,int type);

void (*trans_mallocfreeproc)(struct pdl_trans *tr);

void (*make_physical)(pdl *it);
void (*make_physdims)(pdl *it);
void (*pdl_barf) (const char* pat,...); /* Not plain 'barf' as this
                                  is a macro - KGB */
void (*allocdata) (pdl *it);
  PDL_Long (*safe_indterm)(PDL_Long dsz, PDL_Long at, char *file, int lineno);
};

typedef struct Core Core;

Core *pdl__Core_get_Core(); /* INTERNAL TO CORE! DON'T CALL FROM OUTSIDE */


