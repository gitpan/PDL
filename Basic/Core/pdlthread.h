

typedef struct pdl_errorinfo {
	char *funcname;
	char **paramnames;
	int nparamnames;
} pdl_errorinfo;

/* XXX To avoid mallocs, these should also have "default" values */
typedef struct pdl_thread {
	pdl_errorinfo *einfo;
	int ndims;	/* Number of dimensions threaded over */
	int nimpl;	/* Number of these that are implicit */
	int npdls;	/* Number of pdls involved */
	int nextra;
	int *inds;	/* Indices for each of the dimensions */
	int *dims;	/* Dimensions of each dimension */
	int *offs;	/* Offsets for each of the pdls */
	int *incs;	/* npdls * ndims array of increments. Fast because
	 		   of constant indices for first loops */
	int *realdims;
	pdl **pdls;	
} pdl_thread;


/* No extra vars */
#define PDL_THREADINIT(thread,pdls,realdims,creating,npdls,info) \
	  PDL->initthreadstruct(0,pdls,realdims,creating,npdls,info,&thread)

#define PDL_THREAD_DECLS(thread)

#define PDL_THREADCREATEPAR(thread,ind,dims) \
	  PDL->thread_create_parameter(&thread,ind,dims)
#define PDL_THREADSTART(thread) PDL->startthreadloop(&thread)

#define PDL_THREADITER(thread,ptrs) PDL->iterthreadloop(&thread,0,NULL)

#define PDL_THREAD_INITP(thread,which,ptr) /* Nothing */
#define PDL_THREAD_P(thread,which,ptr) ((ptr)+(thread).offs[ind])
#define PDL_THREAD_UPDP(thread,which,ptr) /* Nothing */



