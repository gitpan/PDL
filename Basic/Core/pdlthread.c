/* XXX NOTE THAT IT IS NOT SAFE TO USE ->pdls MEMBER OUTSIDE
   INITTHREADSTRUCT! */

#define PDL_CORE      /* For certain ifdefs */
#include "pdl.h"      /* Data structure declarations */
#include "pdlcore.h"  /* Core declarations */


#define MAX2(a,b) if((b)>(a)) a=b;

static void *strndup(void *ptr, int size) {
	if(size == 0) return 0; else
	{
	void *newptr = malloc(size);
	int i;
	for(i=0; i<size; i++) ((char *)newptr)[i] = ((char *)ptr)[i];
	return newptr;
	}
}

int *pdl_get_threadoffsp(pdl_thread *thread)
{
  if(thread->gflags & PDL_THREAD_MAGICKED) {
  	int thr = pdl_magic_get_thread(thread->pdls[thread->mag_nthpdl]);
	return thread->offs + thr * thread->npdls;
  }
/* The non-multithreaded case: return just the usual offsets */
  return thread->offs;
}

int *pdl_get_threadoffsp_int(pdl_thread *thread, int *nthr)
{
  if(thread->gflags & PDL_THREAD_MAGICKED) {
  	int thr = pdl_magic_get_thread(thread->pdls[thread->mag_nthpdl]);
	*nthr = thr;
	return thread->offs + thr * thread->npdls;
  }
  *nthr = 0;
/* The non-multithreaded case: return just the usual offsets */
  return thread->offs;
}

void pdl_thread_copy(pdl_thread *from,pdl_thread *to) {
	to->gflags = from->gflags;
	to->einfo = from->einfo;
	to->ndims = from->ndims;
	to->nimpl = from->nimpl;
	to->npdls = from->npdls;
	to->inds = strndup(from->inds,sizeof(*to->inds)*to->ndims);
	to->dims = strndup(from->dims,sizeof(*to->dims)*to->ndims);
	to->offs = strndup(from->offs,sizeof(*to->offs)*to->npdls);
	to->incs = strndup(from->incs,sizeof(*to->offs)*to->npdls*to->ndims);
	to->realdims = from->realdims;
	to->flags = strndup(from->flags,to->npdls);
	to->pdls = strndup(from->pdls,sizeof(*to->pdls)*to->npdls); /* XX MEMLEAK */
	to->mag_nthpdl = from->mag_nth;
	to->mag_nthpdl = from->mag_nthpdl;
}

void pdl_freethreadloop(pdl_thread *thread) {
	free(thread->inds);
	free(thread->dims);
	free(thread->offs);
	free(thread->incs);
/*	free(thread->realdims); */
	free(thread->flags);
	free(thread->pdls);
	pdl_clearthreadstruct(thread);
}

void pdl_clearthreadstruct(pdl_thread *it) {
	it->einfo = 0;it->inds = 0;it->dims = 0;
	it->ndims = it->nimpl = it->npdls = 0; it->offs = 0;
	it->pdls = 0;it->incs = 0; it->realdims=0; it->flags=0;
}

/* The assumptions this function makes:
 *  pdls is dynamic and may go away -> copied
 *  realdims is static and is NOT copied and NOT freed!!!
 *  creating is only used inside this routine.
 *  errorinfo is assumed static.
 *  usevaffine is assumed static. (uses if exists)
 *
 * Only the first thread-magicked pdl is taken into account.
 */
void pdl_initthreadstruct(int nobl,
	pdl **pdls,int *realdims,int *creating,int npdls,
	pdl_errorinfo *info,pdl_thread *thread, char *flags) {
	int i; int j;
	int ndims=0; int nth;
	int mx;
	int nids;
	int nimpl;
	int nthid;

	int mydim;

	int *nthreadids;
	int nthr = 0; int nthrd;

	thread->gflags = 0;

	thread->npdls = npdls;
	thread->pdls = strndup(pdls,sizeof(*pdls)*npdls);
	thread->realdims = realdims; 
	thread->ndims = 0;

	thread->mag_nth = -1;
	thread->mag_nthpdl = -1;

	nids=0;
	mx=0;
/* Find the max. number of threadids */
	for(j=0; j<npdls; j++) {
		if(creating[j]) continue;
		MAX2(nids,pdls[j]->nthreadids);
		MAX2(mx,pdls[j]->threadids[0] - realdims[j]);
	}
	nthreadids = pdl_malloc(sizeof(int)*nids);
	ndims += mx;  nimpl = mx; thread->nimpl = nimpl;
	for(j=0; j<npdls; j++) {
		if(creating[j]) continue;
		/* Check for magical piddles (parallelized) */
		if((!nthr) &&
		  pdls[j]->magic && 
		  (nthr = pdl_magic_thread_nthreads(pdls[j],&nthrd))) {
			thread->mag_nthpdl = j;
			thread->mag_nth = nthrd - realdims[j];
			if(thread->mag_nth < 0) {
				die("Cannot magick non-threaded dims");
			}
		}
		
		for(i=0; i<nids; i++) {
			mx=0; if(pdls[j]->nthreadids <= nids) {
				MAX2(mx,
				     pdls[j]->threadids[i+1] 
				     - pdls[j]->threadids[i]);
			}
			ndims += mx;
			nthreadids[i] = mx;
		}
	}

	if(nthr) {
		thread->gflags |= PDL_THREAD_MAGICKED;
	}

	if(ndims < nobl) { /* If too few, add enough implicit dims */
		thread->nextra = nobl - ndims;
		ndims += thread->nextra;
	} else {
		thread->nextra = 0;
	}

	thread->ndims = ndims;
	thread->nimpl = nimpl;
	thread->inds = malloc(sizeof(int) * thread->ndims);
	thread->dims = malloc(sizeof(int) * thread->ndims);
	thread->offs = malloc(sizeof(int) * thread->npdls
			* (nthr>0 ? nthr : 1));
	thread->incs = malloc(sizeof(int) * thread->ndims * npdls);
	thread->flags = malloc(sizeof(char) * npdls);
	nth=0; /* Index to dimensions */

	/* populate the per_pdl_flags */

	for (i=0;i<npdls; i++) {
	  thread->flags[i] = 0;
	  if (PDL_VAFFOK(pdls[i]) && VAFFINE_FLAG_OK(flags,i))
	    thread->flags[i] |= PDL_THREAD_VAFFINE_OK;
	}
	flags = thread->flags; /* shortcut for the remainder */

/* Make implicit inds */

	for(i=0; i<nimpl; i++) {
		thread->dims[nth] = 1;
		for(j=0; j<thread->npdls; j++) {
			thread->incs[nth*npdls+j] = 0;
			if(creating[j]) continue;
			if(thread->pdls[j]->threadids[0]-
					thread->realdims[j] <= i)
				continue;
			if(pdls[j]->dims[i+realdims[j]] != 1) {
				if(thread->dims[nth] != 1) {
					if(thread->dims[nth] !=
						pdls[j]->dims[i+realdims[j]]) {
						pdl_croak_param(info,j,"Mismatched Implicit thread dimension %d: should be %d, is %d",
							i,
							thread->dims[nth],
							pdls[j]->dims[i+thread->realdims[j]]);
					}
				} else {
					thread->dims[nth] = 
						pdls[j]->dims[i+realdims[j]];
				}
				thread->incs[nth*npdls+j] = 
					PDL_TREPRINC(pdls[j],flags[j],i+realdims[j]);
			}
		}
		nth++;
	}

/* Go through everything again and make the real things */

	for(nthid=0; nthid<nids; nthid++) {
	for(i=0; i<nthreadids[nthid]; i++) {
		thread->dims[nth] = 1;
		for(j=0; j<thread->npdls; j++) {
			thread->incs[nth*npdls+j] = 0;
			if(creating[j]) continue;
			if(thread->pdls[j]->nthreadids < nthid)
				continue;
			if(thread->pdls[j]->threadids[nthid+1]-
			   thread->pdls[j]->threadids[nthid]
					<= i) continue;
			mydim = i+thread->pdls[j]->threadids[nthid];
			if(pdls[j]->dims[mydim] 
					!= 1) {
				if(thread->dims[nth] != 1) {
					if(thread->dims[nth] !=
						pdls[j]->dims[mydim]) {
						pdl_croak_param(info,j,"Mismatched Implicit thread dimension %d: should be %d, is %d",
							i,
							thread->dims[nth],
							pdls[j]->dims[i+thread->realdims[j]]);
					}
				} else {
					thread->dims[nth] = 
						pdls[j]->dims[mydim];
				}
				thread->incs[nth*npdls+j] = 
					PDL_TREPRINC(pdls[j],flags[j],mydim);
			}
		}
		nth++;
	}
	}


/* Make sure that we have the obligatory number of threaddims */

	for(; nth<ndims; nth++) {
		thread->dims[nth]=1;
		for(j=0; j<npdls; j++) 
			thread->incs[nth*npdls+j] = 0;
	}
/* If threading, make the true offsets and dims.. */

	if(nthr > 0) {
		int n1 = thread->dims[thread->mag_nth] / nthr;
		int n2 = thread->dims[thread->mag_nth] % nthr;
		if(n2) {
			die("Cannot magick-thread with non-divisible n!");
		}
		thread->dims[thread->mag_nth] = n1;
	}
}

void pdl_thread_create_parameter(pdl_thread *thread,int j,int *dims,
				 int temp)
{
	int i;
	int td = temp ? 0 : thread->nimpl;

	if(!temp && thread->nimpl != thread->ndims - thread->nextra) {
		pdl_croak_param(thread->einfo,j,
			"Trying to create parameter while explicitly threading.\
See the manual for why this is impossible");
	}
	pdl_reallocdims(thread->pdls[j], thread->realdims[j] + td);
	for(i=0; i<thread->realdims[j]; i++)
		thread->pdls[j]->dims[i] = dims[i];
	if (!temp) 
	  for(i=0; i<thread->nimpl; i++) 
		thread->pdls[j]->dims[i+thread->realdims[j]] =
			thread->dims[i];
	thread->pdls[j]->threadids[0] = td + thread->realdims[j];
	pdl_resize_defaultincs(thread->pdls[j]);
	for(i=0; i<thread->nimpl; i++) {
		thread->incs[thread->npdls*i + j] =
		  temp ? 0 : 
		  PDL_REPRINC(thread->pdls[j],i+thread->realdims[j]);
	}
}

int pdl_startthreadloop(pdl_thread *thread,void (*func)(pdl_trans *),
			pdl_trans *t) {
	int i,j;
	int *offsp; int nthr;
	if((thread->gflags & (PDL_THREAD_MAGICKED | PDL_THREAD_MAGICK_BUSY))
	     == PDL_THREAD_MAGICKED) {
		thread->gflags |= PDL_THREAD_MAGICK_BUSY;
		if(!func) {
			die("NULL FUNCTION WHEN PTHREADING\n");
		}
		/* Do the threadloop magically (i.e. in parallel) */
		pdl_magic_thread_cast(thread->pdls[thread->mag_nthpdl],
			func,t);
		thread->gflags &= ~PDL_THREAD_MAGICK_BUSY;
		return 1; /* DON'T DO THREADLOOP AGAIN */
	}
	for(i=0; i<thread->ndims; i++) 
		thread->inds[i] = 0;
	offsp = pdl_get_threadoffsp_int(thread,&nthr);
	for(j=0; j<thread->npdls; j++) 
		offsp[j] = PDL_TREPROFFS(thread->pdls[j],thread->flags[j]) +
			(!nthr?0:
				nthr * thread->dims[thread->mag_nth] *
				    thread->incs[thread->mag_nth*thread->npdls + j]);
	return 0;
}

/* This will have to be macroized */
int pdl_iterthreadloop(pdl_thread *thread,int nth) {
	int i,j;
	int stop = 0;
	int stopdim;
	int *offsp; int nthr;
/*	printf("iterthreadloop\n"); */
	for(j=0; j<thread->npdls; j++)
		thread->offs[j] = PDL_TREPROFFS(thread->pdls[j],thread->flags[j]);
	for(i=nth; i<thread->ndims; i++) {
		thread->inds[i] ++;
		if(thread->inds[i] >= thread->dims[i]) 
			thread->inds[i] = 0;
		else 
		{	stopdim = i; stop = 1; break; }
	}
	if(stop) goto calc_offs;
	return 0;
calc_offs:
	offsp = pdl_get_threadoffsp_int(thread,&nthr);
	for(j=0; j<thread->npdls; j++) {
		offsp[j] = PDL_TREPROFFS(thread->pdls[j],thread->flags[j]) +
		(!nthr?0:
			nthr * thread->dims[thread->mag_nth] *
			    thread->incs[thread->mag_nth*thread->npdls + j]);
			;
		for(i=nth; i<thread->ndims; i++) {
			offsp[j] += thread->incs[i*thread->npdls+j] *
					thread->inds[i];
		}
	}
	return stopdim+1;
}

void pdl_croak_param(pdl_errorinfo *info,int j, char *pat, ...)
{
	va_list args;
	char *message; char *name;
	static char mesgbuf[200];
	va_start(args,pat);
	message = mess(pat,&args);
	/* Now, croak() overwrites this string. make a copy */
	strcpy(mesgbuf,message); message = mesgbuf;
	va_end(args);
	if(!info) {croak("PDL_CROAK_PARAM: Unknown: parameter %d: %s\n",
		j,message);
	} else {
		if(j >= info->nparamnames) 
			name = "ERROR: UNKNOWN PARAMETER";
		else	name = info->paramnames[j];
		croak("PDL: %s: Parameter '%s': %s\n",info->funcname,name,message);
	}
}


