#include "pdlcore.h"

/* Singly linked list */

void pdl__magic_add(pdl *it,pdl_magic *mag)
{
	pdl_magic **foo = &(it->magic);
	while(*foo) {
		foo = &((*foo)->next);
	}
	(*foo) = mag;
}

void pdl__magic_rm(pdl *it,pdl_magic *mag)
{
	pdl_magic **foo = &(it->magic);
	while(*foo) {
		if(*foo == mag) {
			*foo = (*foo)->next;
		}
		foo = &((*foo)->next);
	}
	die("PDL:Magic not found: Internal error\n");
}

/* Call magics */

void *pdl__call_magic(pdl *it,int which)
{
	void *ret = NULL;
	pdl_magic **foo = &(it->magic);
	while(*foo) {
		if((*foo)->what & which) {
			if((*foo)->what & PDL_MAGIC_DELAYED) 
				pdl_add_delayed_magic(*foo);
			else 
				ret = (void *)((*foo)->vtable->cast(*foo)); 
					/* Cast spell */
		}
		foo = &((*foo)->next);
	}
	return ret;
}

int pdl__ismagic(pdl *it) 
{
	return (it->magic != 0);
}

static pdl_magic **delayed=NULL;
static int ndelayed = 0;
void pdl_add_delayed_magic(pdl_magic *mag) {
	delayed = realloc(delayed,sizeof(*delayed)*++ndelayed);
	delayed[ndelayed-1] = mag;
}
void pdl_run_delayed_magic() {
	int i;
	pdl_magic **oldd = delayed; /* In case someone makes new delayed stuff */
	int nold = ndelayed;
	delayed = NULL;
	ndelayed = 0;
	for(i=0; i<nold; i++) {
		oldd[i]->vtable->cast(oldd[i]);
	}
	free(oldd);
}

/****************
 * 
 * ->bind - magic
 */

void *svmagic_cast(pdl_magic *mag)
{
	pdl_magic_perlfunc *magp = (pdl_magic_perlfunc *)mag;
	dSP;
	PUSHMARK(sp);
	perl_call_sv(magp->sv, G_DISCARD | G_NOARGS);
	return NULL;
}

static pdl_magic_vtable svmagic_vtable = {
	svmagic_cast,
	NULL
};

pdl_magic *pdl_add_svmagic(pdl *it,SV *func)
{
	AV *av;
	pdl_magic_perlfunc *ptr = malloc(sizeof(pdl_magic_perlfunc));
	ptr->what = PDL_MAGIC_MARKCHANGED | PDL_MAGIC_DELAYED;
	ptr->vtable = &svmagic_vtable;
	ptr->sv = newSVsv(func);
	ptr->pdl = it;
	ptr->next = NULL;
	pdl__magic_add(it,(pdl_magic *)ptr);
	if(it->state & PDL_ANYCHANGED)
		pdl_add_delayed_magic((pdl_magic *)ptr);
/* In order to have our SV destroyed in time for the interpreter, */
/* XXX Work this out not to memleak */
	av = perl_get_av("PDL::disposable_svmagics",TRUE);
	av_push(av,ptr->sv);
	return (pdl_magic *)ptr;
}


/****************
 * 
 * ->bind - magic
 */

pdl_trans *pdl_find_mutatedtrans(pdl *it)
{
	if(!it->magic) return;
	return pdl__call_magic(it,PDL_MAGIC_MUTATEDPARENT);
}

void *fammutmagic_cast(pdl_magic *mag)
{
	pdl_magic_fammut *magp = (pdl_magic_fammut *)mag;
	return magp->ftr;
}

struct pdl_magic_vtable familymutmagic_vtable = {
	fammutmagic_cast,
	NULL
};

pdl_magic *pdl_add_fammutmagic(pdl *it,pdl_trans *ft) 
{
	pdl_magic_fammut *ptr = malloc(sizeof(pdl_magic_fammut));
	ptr->what = PDL_MAGIC_MUTATEDPARENT;
	ptr->vtable = &familymutmagic_vtable;
	ptr->ftr = ft;
	ptr->pdl = it;
	ptr->next = NULL;
	pdl__magic_add(it,(pdl_magic *)ptr);
	return (pdl_magic *)ptr;
}

