

/* Magic stuff */

struct pdl_magic;

/* If no copy, not copied with the pdl */
typedef struct pdl_magic_vtable {
	void *(*cast)(struct pdl_magic *); /* Cast the spell */
	struct pdl_magic *(*copy)(struct pdl_magic *);
} pdl_magic_vtable;

#define PDL_MAGIC_MARKCHANGED 0x0001
#define PDL_MAGIC_MUTATEDPARENT 0x0002
#define PDL_MAGIC_DELAYED     0x8000

#define PDL_MAGICSTART \
		int what; /* when is this magic to be called */ \
		pdl_magic_vtable *vtable; \
		struct pdl_magic *next; \
		pdl *pdl

#define PDL_TRMAGICSTART \
		int what; /* when is this magic to be called */ \
		pdl_magic_vtable *vtable; \
		struct pdl_magic *next; \
		pdl_trans *tr

typedef struct pdl_magic {
	PDL_MAGICSTART;
} pdl_magic;

typedef struct pdl_magic_perlfunc {
	PDL_MAGICSTART;
	SV *sv;         	/* sub{} or subname (perl_call_sv) */
} pdl_magic_perlfunc;

typedef struct pdl_magic_fammut {
	PDL_MAGICSTART;
	pdl_trans *ftr;
} pdl_magic_fammut;

/* - tr magics */

typedef struct pdl_trmagic {
	PDL_TRMAGICSTART;
} pdl_trmagic;

typedef struct pdl_trmagic_family {
	PDL_TRMAGICSTART;
	pdl *fprog,*tprog;
	pdl *fmut,*tmut;
} pdl_trmagic_family;

/* __ = Don't call from outside pdl if you don't know what you're doing */

void pdl__magic_add(pdl *,pdl_magic *);
void pdl__magic_rm(pdl *,pdl_magic *);

void *pdl__call_magic(pdl *,int which);
int pdl__ismagic(pdl *);

pdl_magic *pdl_add_svmagic(pdl *,SV *);

/* A kind of "dowhenidle" system */

void pdl_add_delayed_magic(pdl_magic *);
void pdl_run_delayed_magic();

pdl_trans *pdl_find_mutatedtrans(pdl *it);
