extern doublereal dasum_(integer *n, doublereal *dx, integer *incx);
extern int daxpy_(integer *n, doublereal *da, doublereal *dx, integer *incx, doublereal *dy, integer *incy);
extern doublereal ddot_(integer *n, doublereal *dx, integer *incx, doublereal *dy, integer *incy);
extern int dgeco_(doublereal *a, integer *lda, integer *n, integer *ipvt, doublereal *rcond, doublereal *z__);
/*:ref: dasum_ 7 3 4 7 4 */
/*:ref: dgefa_ 14 5 7 4 4 4 4 */
/*:ref: dscal_ 14 4 4 7 7 4 */
/*:ref: ddot_ 7 5 4 7 4 7 4 */
/*:ref: daxpy_ 14 6 4 7 7 4 7 4 */
extern int dgedi_(doublereal *a, integer *lda, integer *n, integer *ipvt, doublereal *det, doublereal *work, integer *job);
/*:ref: dscal_ 14 4 4 7 7 4 */
/*:ref: daxpy_ 14 6 4 7 7 4 7 4 */
/*:ref: dswap_ 14 5 4 7 4 7 4 */
extern int dgefa_(doublereal *a, integer *lda, integer *n, integer *ipvt, integer *info);
/*:ref: idamax_ 4 3 4 7 4 */
/*:ref: dscal_ 14 4 4 7 7 4 */
/*:ref: daxpy_ 14 6 4 7 7 4 7 4 */
extern int dpoco_(doublereal *a, integer *lda, integer *n, doublereal *rcond, doublereal *z__, integer *info);
/*:ref: dasum_ 7 3 4 7 4 */
/*:ref: dpofa_ 14 4 7 4 4 4 */
/*:ref: dscal_ 14 4 4 7 7 4 */
/*:ref: daxpy_ 14 6 4 7 7 4 7 4 */
/*:ref: ddot_ 7 5 4 7 4 7 4 */
extern int dpodi_(doublereal *a, integer *lda, integer *n, doublereal *det, integer *job);
/*:ref: dscal_ 14 4 4 7 7 4 */
/*:ref: daxpy_ 14 6 4 7 7 4 7 4 */
extern int dpofa_(doublereal *a, integer *lda, integer *n, integer *info);
/*:ref: ddot_ 7 5 4 7 4 7 4 */
extern int dscal_(integer *n, doublereal *da, doublereal *dx, integer *incx);
extern int dswap_(integer *n, doublereal *dx, integer *incx, doublereal *dy, integer *incy);
extern int fdump_(void);
extern integer i1mach_(integer *i__);
extern integer idamax_(integer *n, doublereal *dx, integer *incx);
extern integer isamax_(integer *n, real *sx, integer *incx);
extern integer j4save_(integer *iwhich, integer *ivalue, logical *iset);
extern logical lsame_(char *ca, char *cb, ftnlen ca_len, ftnlen cb_len);
extern E_f pythag_(real *a, real *b);
extern E_f r1mach_(integer *i__);
/*:ref: xermsg_ 14 8 13 13 13 4 4 124 124 124 */
extern int rs_(integer *nm, integer *n, real *a, real *w, integer *matz, real *z__, real *fv1, real *fv2, integer *ierr);
/*:ref: tred1_ 14 6 4 4 6 6 6 6 */
/*:ref: tqlrat_ 14 4 4 6 6 4 */
/*:ref: tred2_ 14 6 4 4 6 6 6 6 */
/*:ref: tql2_ 14 6 4 4 6 6 6 4 */
extern E_f sasum_(integer *n, real *sx, integer *incx);
extern int saxpy_(integer *n, real *sa, real *sx, integer *incx, real *sy, integer *incy);
extern E_f sdot_(integer *n, real *sx, integer *incx, real *sy, integer *incy);
extern int sgeco_(real *a, integer *lda, integer *n, integer *ipvt, real *rcond, real *z__);
/*:ref: sasum_ 6 3 4 6 4 */
/*:ref: sgefa_ 14 5 6 4 4 4 4 */
/*:ref: sscal_ 14 4 4 6 6 4 */
/*:ref: sdot_ 6 5 4 6 4 6 4 */
/*:ref: saxpy_ 14 6 4 6 6 4 6 4 */
extern int sgedi_(real *a, integer *lda, integer *n, integer *ipvt, real *det, real *work, integer *job);
/*:ref: sscal_ 14 4 4 6 6 4 */
/*:ref: saxpy_ 14 6 4 6 6 4 6 4 */
/*:ref: sswap_ 14 5 4 6 4 6 4 */
extern int sgefa_(real *a, integer *lda, integer *n, integer *ipvt, integer *info);
/*:ref: isamax_ 4 3 4 6 4 */
/*:ref: sscal_ 14 4 4 6 6 4 */
/*:ref: saxpy_ 14 6 4 6 6 4 6 4 */
extern int sgemm_(char *transa, char *transb, integer *m, integer *n, integer *k, real *alpha, real *a, integer *lda, real *b, integer *ldb, real *beta, real *c__, integer *ldc, ftnlen transa_len, ftnlen transb_len);
/*:ref: lsame_ 12 4 13 13 124 124 */
/*:ref: xerbla_ 14 3 13 4 124 */
extern int sgemv_(char *trans, integer *m, integer *n, real *alpha, real *a, integer *lda, real *x, integer *incx, real *beta, real *y, integer *incy, ftnlen trans_len);
/*:ref: lsame_ 12 4 13 13 124 124 */
/*:ref: xerbla_ 14 3 13 4 124 */
extern E_f snrm2_(integer *n, real *sx, integer *incx);
extern int spoco_(real *a, integer *lda, integer *n, real *rcond, real *z__, integer *info);
/*:ref: sasum_ 6 3 4 6 4 */
/*:ref: spofa_ 14 4 6 4 4 4 */
/*:ref: sscal_ 14 4 4 6 6 4 */
/*:ref: saxpy_ 14 6 4 6 6 4 6 4 */
/*:ref: sdot_ 6 5 4 6 4 6 4 */
extern int spodi_(real *a, integer *lda, integer *n, real *det, integer *job);
/*:ref: sscal_ 14 4 4 6 6 4 */
/*:ref: saxpy_ 14 6 4 6 6 4 6 4 */
extern int spofa_(real *a, integer *lda, integer *n, integer *info);
/*:ref: sdot_ 6 5 4 6 4 6 4 */
extern int srot_(integer *n, real *sx, integer *incx, real *sy, integer *incy, real *sc, real *ss);
extern int srotg_(real *sa, real *sb, real *sc, real *ss);
extern int ssbmv_(char *uplo, integer *n, integer *k, real *alpha, real *a, integer *lda, real *x, integer *incx, real *beta, real *y, integer *incy, ftnlen uplo_len);
/*:ref: lsame_ 12 4 13 13 124 124 */
/*:ref: xerbla_ 14 3 13 4 124 */
extern int sscal_(integer *n, real *sa, real *sx, integer *incx);
extern int ssvdc_(real *x, integer *ldx, integer *n, integer *p, real *s, real *e, real *u, integer *ldu, real *v, integer *ldv, real *work, integer *job, integer *info);
/*:ref: snrm2_ 6 3 4 6 4 */
/*:ref: sscal_ 14 4 4 6 6 4 */
/*:ref: sdot_ 6 5 4 6 4 6 4 */
/*:ref: saxpy_ 14 6 4 6 6 4 6 4 */
/*:ref: srotg_ 14 4 6 6 6 6 */
/*:ref: srot_ 14 7 4 6 4 6 4 6 6 */
/*:ref: sswap_ 14 5 4 6 4 6 4 */
extern int sswap_(integer *n, real *sx, integer *incx, real *sy, integer *incy);
extern int tql2_(integer *nm, integer *n, real *d__, real *e, real *z__, integer *ierr);
/*:ref: pythag_ 6 2 6 6 */
extern int tqlrat_(integer *n, real *d__, real *e2, integer *ierr);
/*:ref: r1mach_ 6 1 4 */
/*:ref: pythag_ 6 2 6 6 */
extern int tred1_(integer *nm, integer *n, real *a, real *d__, real *e, real *e2);
extern int tred2_(integer *nm, integer *n, real *a, real *d__, real *e, real *z__);
extern int xerbla_(char *srname, integer *info, ftnlen srname_len);
/*:ref: xermsg_ 14 8 13 13 13 4 4 124 124 124 */
extern int xercnt_(char *librar, char *subrou, char *messg, integer *nerr, integer *level, integer *kontrl, ftnlen librar_len, ftnlen subrou_len, ftnlen messg_len);
extern int xerhlt_(char *messg, ftnlen messg_len);
extern int xermsg_(char *librar, char *subrou, char *messg, integer *nerr, integer *level, ftnlen librar_len, ftnlen subrou_len, ftnlen messg_len);
/*:ref: j4save_ 4 3 4 4 12 */
/*:ref: xerprn_ 14 6 13 4 13 4 124 124 */
/*:ref: xersve_ 14 10 13 13 13 4 4 4 4 124 124 124 */
/*:ref: xerhlt_ 14 2 13 124 */
/*:ref: xercnt_ 14 9 13 13 13 4 4 4 124 124 124 */
/*:ref: fdump_ 14 0 */
extern int xerprn_(char *prefix, integer *npref, char *messg, integer *nwrap, ftnlen prefix_len, ftnlen messg_len);
/*:ref: xgetua_ 14 2 4 4 */
/*:ref: i1mach_ 4 1 4 */
extern int xersve_(char *librar, char *subrou, char *messg, integer *kflag, integer *nerr, integer *level, integer *icount, ftnlen librar_len, ftnlen subrou_len, ftnlen messg_len);
/*:ref: xgetua_ 14 2 4 4 */
/*:ref: i1mach_ 4 1 4 */
extern int xgetua_(integer *iunita, integer *n);
/*:ref: j4save_ 4 3 4 4 12 */
