
#include "pdl.h"      /* Data structure declarations */
#include "pdlcore.h"  /* Core declarations */


static SV *getref_pdl(pdl *it) {
	SV *newref;
	if(!it->sv) {
		SV *ref;
		HV *stash = gv_stashpv("PDL",TRUE);
		SV *psv = newSViv((IV)it);
		it->sv = psv;
		newref = newRV_noinc(it->sv);
		(void)sv_bless(newref,stash);
	} else {
		newref = newRV_inc(it->sv);
		SvAMAGIC_on(newref);
	}
	return newref;
}

void SetSV_PDL ( SV *sv, pdl *it ) {
	SV *newref = getref_pdl(it); /* YUCK!!!! */
	sv_setsv(sv,newref);
	SvREFCNT_dec(newref);
}


/* Size of data type information */

int pdl_howbig (int datatype) {
    switch (datatype) {
    case PDL_B:
      return sizeof(PDL_Byte);
    case PDL_S:
      return sizeof(PDL_Short);
    case PDL_US:
      return sizeof(PDL_Ushort);
    case PDL_L:
      return sizeof(PDL_Long);
    case PDL_F:
      return sizeof(PDL_Float);
    case PDL_D:
      return sizeof(PDL_Double);
    default:
      croak("Unknown datatype code = %d",datatype);
    }
}

int pdl_whichdatatype (double nv) {
#define TESTTYPE(b,a) {a foo = nv; if(nv == foo) return b;}
	TESTTYPE(PDL_B,PDL_Byte)
	TESTTYPE(PDL_S,PDL_Short)
	TESTTYPE(PDL_US,PDL_Ushort)
	TESTTYPE(PDL_L,PDL_Long)
	TESTTYPE(PDL_F,PDL_Float)
	TESTTYPE(PDL_D,PDL_Double)
	croak("Something's gone wrong: %lf cannot be converted by whichdatatype",
		nv);
}

/* Make a scratch data existence for a pdl */

void pdl_makescratchhash(pdl *ret,double data) {
	HV *hash;
	SV *dat; PDL_Long fake[1];

	 /* Compress to smallest available type. This may have strange
	    results sometimes :( */
	ret->datatype = pdl_whichdatatype(data);
	ret->data = pdl_malloc(pdl_howbig(ret->datatype)); /* Wasteful */

       dat = newSVpv(ret->data,pdl_howbig(ret->datatype));

       ret->data = SvPV(dat,na);
       ret->datasv = dat;
#ifdef FOO
 /* Refcnt should be 1 already... */
       SvREFCNT_inc(ret->datasv); /* XXX MEMLEAK */
#endif

  /* This is an important point: it makes this whole piddle mortal
   * so destruction will happen at the right time. 
   * If there are dangling references, pdlapi.c knows not to actually
   * destroy the C struct. */
       sv_2mortal(getref_pdl(ret));

       pdl_setdims(ret, fake, 0); /* However, there are 0 dims in scalar */
       ret->nvals = 1;

       /* NULLs should be ok because no dimensions. */
       pdl_set(ret->data, ret->datatype, NULL, NULL, NULL, 0, 0, data);

}

/* 
  "Convert" a perl SV into a pdl (alright more like a mapping as
   the data block isn't actually copied)  - scalars are automatically
   converted
*/

pdl* SvPDLV ( SV* sv ) {

   pdl* ret;
   int fake[1];
   SV *sv2;

   if ( !SvROK(sv) ) {   /* Coerce scalar */
	SV *dat;
	double data;
       ret = pdl_new();  /* Scratch pdl */

/*       ret->sv = (void*) sv; !! */

/* Scratch hash for the pdl :( - slow but safest. */

	data = SvNV(sv);

	pdl_makescratchhash(ret,data);

       return ret;
   }

   if(SvTYPE(SvRV(sv)) == SVt_PVHV) {
   	HV *hash = (HV*)SvRV(sv);
	SV **svp = hv_fetch(hash,"PDL",3,0);
	if(svp == NULL) {
		croak("Hash given as a pdl - but not {PDL} key!");
	}
   	sv = *svp;
   }
       
   if (SvTYPE(SvRV(sv)) != SVt_PVMG)
      croak("Error - argument is not a recognised data structure"); 

   sv2 = (SV*) SvRV(sv); 

#ifdef FOIJFSOEFJSEOFJSOEIJFOISJFEFSF
   /* Now, do magic: check if there are more than this one ref
      to this internal sv. If there are, we've been "="'ed
      (assigned) elsewhere and therefore must copy to keep
      the semantics clear. This may at the moment be slightly
      inefficient but as a future optimization, SvPDLV may be replaced
      by SvPDLV_nodup in places where it is sure that this is ok. */

   if(SvREFCNT(sv2) > 1) {
   	pdl *tmp = (pdl *)SvIV(sv2);
	pdl *pnew = pdl_hard_copy(tmp);
   	printf("More than one ref; copying\n");

	SetSV_PDL(sv,pnew);
	ret = pnew;
   } else {
#else
	   ret = (pdl *)SvIV(sv2);
#endif
#ifdef FOOOOOOOO
   }
#endif

   if(ret->magicno != PDL_MAGICNO) {
   	croak("Fatal error: argument is probably not a piddle, or\
 magic no overwritten. You're in trouble, guv: %d %d %d\n",sv2,ret,ret->magicno);
   }
  
   return ret;
}

/* Make a new pdl object as a copy of an old one and return - implement by    
   callback to perl method "copy" or "new" (for scalar upgrade) */

SV* pdl_copy( pdl* a, char* option ) {

   SV* retval;
   char meth[20];

   dSP ;   int count ;

   retval = newSVpv("",0); /* Create the new SV */

   ENTER ;   SAVETMPS ;   PUSHMARK(sp) ;

   /* Push arguments */

#ifdef FOOBAR 
   if (sv_isobject((SV*)a->hash)) {
#endif
       XPUSHs(sv_2mortal(getref_pdl(a))); 
       strcpy(meth,"copy");    
       XPUSHs(sv_2mortal(newSVpv(option, 0))) ;    
#ifdef FOOBAR
   }
   else{
       XPUSHs(perl_get_sv("PDL::name",FALSE)); /* Default object */
       XPUSHs(sv_2mortal(getref_pdl(a))); 
       strcpy(meth,"new");    
   }
#endif

   PUTBACK ;

   count = perl_call_method(meth, G_SCALAR); /* Call Perl */

   SPAGAIN;

   if (count !=1) 
      croak("Error calling perl function\n");

   sv_setsv( retval, POPs ); /* Save the perl returned value */
  
   PUTBACK ;   FREETMPS ;   LEAVE ;

   return retval;  
}



/* Pack dims array - returns dims[] (pdl_malloced) and ndims */

PDL_Long* pdl_packdims ( SV* sv, int *ndims ) {

   SV*  bar;
   AV*  array;
   int i;
   PDL_Long *dims;

   if (!(SvROK(sv) && SvTYPE(SvRV(sv))==SVt_PVAV))  /* Test */
       return NULL;

   array = (AV *) SvRV(sv);   /* dereference */
  
   *ndims = (int) av_len(array) + 1;  /* Number of dimensions */

   dims = (PDL_Long *) pdl_malloc( (*ndims) * sizeof(*dims) ); /* Array space */
   if (dims == NULL)
      croak("Out of memory");

   for(i=0; i<(*ndims); i++) {
      bar = *(av_fetch( array, i, 0 )); /* Fetch */
      dims[i] = (int) SvIV(bar); 
   }
   return dims;
} 

/* unpack dims array into PDL SV* */

void pdl_unpackdims ( SV* sv, PDL_Long *dims, int ndims ) {

   AV*  array;
   HV* hash;
   int i;

   hash = (HV*) SvRV( sv ); 
   array = newAV();
   hv_store(hash, "Dims", strlen("Dims"), newRV( (SV*) array), 0 );
  
   if (ndims==0 )
      return;

   for(i=0; i<ndims; i++)
         av_store( array, i, newSViv( (IV)dims[i] ) );
} 

/*
   pdl_malloc - utility to get temporary memory space. Uses
   a mortal *SV for this so it is automatically freed when the current
   context is terminated without having to call free(). Naughty but
   nice!
*/


void* pdl_malloc ( int nbytes ) {
   
   SV* work;
   
   work = sv_2mortal(newSVpv("", 0));
   
   SvGROW( work, nbytes);
   
   return (void *) SvPV(work, na);
}



