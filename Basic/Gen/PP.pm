 #####################################################################
#####################################################################
##
## 
## Here starts the actual thing.
##
## This is way too messy and uncommented. Still. :(
#
package PDL::PP;
use PDL::Types;
use FileHandle;
use Exporter;
@ISA = qw(Exporter);

@PDL::PP::EXPORT = qw/pp_addhdr pp_addpm pp_bless pp_def pp_done pp_add_boot pp_add_exported pp_addxs pp_add_isa/;

use Carp;

# use strict qw/vars refs/;

sub import {
	my ($mod,$modname, $packname, $prefix) = @_;
	$::PDLMOD=$modname; $::PDLPACK=$packname; $::PDLPREF=$prefix;
	$::PDLOBJ = "PDL"; # define pp-funcs in this package
	$::PDLXS="";
	$::PDLPMROUT="";
 	for ('Top','Bot','Middle') { $::PDLPM{$_}="" }
	$::PDLPMISA="PDL::Exporter DynaLoader";
	$::DOCUMENTED = 0;
	@_=("PDL::PP");
	goto &Exporter::import;
}


sub pp_addhdr {
	my ($hdr) = @_;
	$::PDLXSC .= $hdr;
}

sub pp_addpm {
 	my $pm = shift;
 	my $pos;
 	if (ref $pm) {
 	  my $opt = $pm;
 	  $pm = shift;
 	  croak "unknown option" unless defined $opt->{At} &&
 	    $opt->{At} =~ /^(Top|Bot|Middle)$/;
 	  $pos = $opt->{At};
 	} else {
 	  $pos = 'Middle';
 	}
 	$::PDLPM{$pos} .= "$pm\n\n";
}

sub pp_add_exported {
	my ($this,$exp) = @_;
	$::PDLPMROUT .= $exp." ";
}


sub pp_add_isa {
        my ($isa) = @_;
	$::PDLPMISA .= $isa." ";
}

sub pp_add_boot {
	my ($boot) = @_;
	$::PDLXSBOOT .= $boot." ";
}

sub pp_bless{
   my($new_package)=@_;
   $::PDLOBJ = $new_package;
}

sub printxs {
	shift;
	$::PDLXS .= join'',@_;
}

sub pp_addxs {
	PDL::PP->printxs(@_);
}

sub printxsc {
	shift;
	$::PDLXSC .= join '',@_;
}

sub pp_done {
        $::FUNCSPOD = $::DOCUMENTED ? "\n\n=head1 FUNCTIONS\n\n\n\n=cut\n\n\n"
	  : '';
	print "DONE!\n" if $::PP_VERBOSE;
	(my $fh = new FileHandle(">$::PDLPREF.xs")) or die "Couldn't open xs file\n";

$fh->print(qq%
/*
 * THIS FILE WAS GENERATED BY PDL::PP! Do not modify!
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "pdl.h"
#include "pdlcore.h"
static Core* PDL; /* Structure hold core C functions */
static int __pdl_debugging = 0;
SV* CoreSV;       /* Get's pointer to perl var holding core structure */

$::PDLXSC

MODULE = $::PDLMOD PACKAGE = $::PDLMOD

int
set_debugging(i)
	int i;
	CODE:
	RETVAL = __pdl_debugging;
	__pdl_debugging = i;
	OUTPUT:
	RETVAL
 

MODULE = $::PDLMOD PACKAGE = $::PDLOBJ

$::PDLXS

BOOT:
   /* Get pointer to structure of core shared C routines */
   CoreSV = perl_get_sv("PDL::SHARE",FALSE);  /* SV* value */
   if (CoreSV==NULL)
     Perl_croak("This module requires use of PDL::Core first");
   PDL = (Core*) (void*) SvIV( CoreSV );  /* Core* value */
   $::PDLXSBOOT
%);                                                                

	($fh = new FileHandle(">$::PDLPREF.pm")) or die "Couldn't open pm file\n";

$fh->print(qq%
# 
# GENERATED WITH PDL::PP! Don't modify!
#
package $::PDLPACK;

\@EXPORT_OK  = qw( $::PDLPMROUT);
\%EXPORT_TAGS = (Func=>[\@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;
\@ISA    = qw( $::PDLPMISA );

bootstrap $::PDLMOD;

$::PDLPM{Top}

$::FUNCSPOD

$::PDLPM{Middle};
 
$::PDLPM{Bot}

# Exit with OK status

1;

%);

}

sub pp_def {
	my($name,%hash) = @_;
	$hash{Name} = $name;
	translate(\%hash,$PDL::PP::deftbl);
	my $obj = \%hash;
	if($hash{Dump}) {
		print Dumper(\%hash)if $::PP_VERBOSE ;
	}
	if(!$obj->{FreeFunc}) {
		croak("Cannot free this obj!\n");
	}
	PDL::PP->printxsc(join "\n\n",@$obj{StructDecl,RedoDimsFunc,
		CopyFunc,
		ReadDataFunc,WriteBackDataFunc,
		FreeFunc,
		FooFunc,
		VTableDef,NewXSInPrelude,
		}
		);
	PDL::PP->printxs($$obj{NewXSCode});
	pp_add_boot($$obj{XSBootCode} . $$obj{BootSetNewXS});
	PDL::PP->pp_add_exported($name);
	PDL::PP::pp_addpm("\n".$$obj{PdlDoc}."\n") if $$obj{PdlDoc};
	PDL::PP::pp_addpm($$obj{PMCode});
	if(defined($$obj{PMFunc})) {
		pp_addpm($$obj{PMFunc}."\n");
	}else{
	        pp_addpm('*'.$name.' = \&'.$::PDLOBJ.
	                 '::'.$name.";\n");
	}
}


# Worst memleaks: not freeing things at redodims or
# final free time (thread, dimmed things).

use Carp;
$SIG{__DIE__} = sub {print Carp::longmess(@_); die;};

# Rule table syntax: 
# make  $_->[0] from $_->[1]. 
# use "=" to assign to 1. unless "_" appended to parname, then use ".="

use PDL::PP::Signature;
use PDL::PP::Dims;
use PDL::PP::CType;
use PDL::PP::XS;
use PDL::PP::SymTab;
use PDL::PP::PDLCode;

$|=1;

$PDL::PP::deftbl =
[
 [[CopyName],	[],	sub {"__copy"}],
 [[DefaultFlow], [],	sub {0}],
 [[DefaultFlowCodeNS] ,[DefaultFlow], 
 	sub {$_[0]?'$PRIV(flags) |= PDL_ITRANS_DO_DATAFLOW_F | PDL_ITRANS_DO_DATAFLOW_B;':"/* No flow: $_[0] */"}],

# no docs by default 	
 [[Doc],        [],     sub {"\n=for ref\n\ninfo not available\n"}],

# Default: no otherpars
 [[OtherPars],	[],	sub {""}],
# [[Comp],	[],	sub {""}],
# Naming of the struct and the virtual table.
 [[StructName],		[Name],			"defstructname"],
 [[FHdrInfo],		[Name,StructName],		"mkfhdrinfo"],
 [[VTableName],		[Name],			"defvtablename"],

# Treat exchanges as affines. Affines assumed to be parent->child.
# Exchanges may, if the want, handle threadids as well.
# Same number of dimensions is assumed, though.
 [[AffinePriv],		[XCHGOnly],		"direct"],
 [[Priv],	[AffinePriv],		"affinepriv"],
 [[IsAffineFlag],	[AffinePriv],	sub {"PDL_ITRANS_ISAFFINE"}],

 [[RedoDims],		[EquivPDimExpr,FHdrInfo,_EquivDimCheck],	
 				"pdimexpr2priv"],
 [[RedoDims],		[Identity,FHdrInfo],	"identity2priv"],

 [[EquivCPOffsCode],	[Identity],	sub {'
 	int i;
	for(i=0; i<$CHILD_P(nvals); i++)  {
		$EQUIVCPOFFS(i,i);
	}
 	'}],

 [[Code],	[EquivCPOffsCode],	sub {my($ret) = @_;	
		  $ret =~ s/\$EQUIVCPOFFS\(([^()]+),([^()]+)\)/\$PP(CHILD)[$1] = \$PP(PARENT)[$2]/g;
		  $ret;
		  }],
 [[BackCode],	[EquivCPOffsCode],	sub {my($ret) = @_;	
		  $ret =~ s/\$EQUIVCPOFFS\(([^()]+),([^()]+)\)/\$PP(PARENT)[$2] = \$PP(CHILD)[$1]/g;
		  $ret;
		  }],
 [[Affine_Ok],	[EquivCPOffsCode],	sub {0}],
 [[Affine_Ok],	[],			sub {1}],

 [[ReadDataFuncName],	[AffinePriv],	sub {NULL}],
 [[WriteBackDataFuncName],	[AffinePriv],	sub {NULL}],

 [[BootStruct],	[AffinePriv,VTableName], sub {"$_[1].readdata = PDL->readdata_affine;
 					$_[1].writebackdata = PDL->writebackdata_affine;"}],

 [[ReadDataFuncName],	[Name],	sub {"pdl_$_[0]_readdata"}],
 [[CopyFuncName],	[Name],	sub {"pdl_$_[0]_copy"}],
 [[FreeFuncName],	[Name],	sub {"pdl_$_[0]_free"}],
# [[WriteBackDataFuncName],	[Name],	sub {"pdl_$_[0]_writebackdata"}],
 [[RedoDimsFuncName],	[Name],	sub {"pdl_$_[0]_redodims"}],

 [[XSBootCode],	[BootStruct],	sub {join '',@_}],


# Parameters in the form 'parent and child(this)'.
# The names are PARENT and CHILD.
#
# P2Child implicitly means "no data type changes".
 [[USParNames,USParObjs,FOOFOONoConversion,HaveThreading,NewXSName,PMFunc,
 	PMCode],   [P2Child,Name],
 		"ParentChildPars"],
 [[NewXSName],	[Name],	sub {"_$_[0]_int"}],

 [[EquivPThreadIdExpr],[P2Child],sub {'$CTID-$PARENT(ndims)+$CHILD(ndims)'}],

 [[HaveThreading],	[],	sub {1}],

# the docs
 [[PdlDoc],             [Name,_Pars,OtherPars,Doc],  "GenDocs"],
# Parameters in the 'a(x,y); [o]b(y)' format, with
# fixed nos of real, unthreaded-over dims.
 [[USParNames,USParObjs,DimmedPars], 	[Pars], 		"Pars_nft"],
 [[DimObjs],		[USParNames,USParObjs],	"ParObjs_DimObjs"],

# "Other pars", the parameters which are usually not pdls.
 [[OtherParNames,
   OtherParTypes],	[OtherPars,DimObjs],		"OtherPars_nft"],

 [[ParNames,ParObjs],	[USParNames,USParObjs],	"sort_pnobjs"],

 [[PMCode]	,	[Name,NewXSName,ParNames,ParObjs,OtherParNames,
 			OtherParTypes], "pmcode"],

 [[NewXSArgs],		[USParNames,USParObjs,OtherParNames,OtherParTypes],
 						"NXArgs"],
 [[NewXSHdr],		[NewXSName,NewXSArgs],	"XSHdr"],
 [[NewXSCHdrs],		[NewXSName,NewXSArgs,GlobalNew],	"XSCHdrs"],
 [[DefSyms],		[StructName],			"MkDefSyms"],
 [[NewXSSymTab],	[DefSyms,NewXSArgs],	"AddArgsyms"],
 [[NewXSLocals],	[NewXSSymTab],		"Sym2Loc"],
 [[IsAffineFlag],	[],	sub {return "0"}],
 [[NewXSStructInit0],	[NewXSSymTab,
 			 VTableName,
			 IsAffineFlag,
			 ],		"MkPrivStructInit"],
 [[NewXSMakeNow],	[ParNames,NewXSSymTab],	"MakeNows"],
 [[IgnoreTypesOf],	[FTypes],	sub {return {map {($_,1)} keys %{$_[0]}}}],
 [[IgnoreTypesOf],	[],	sub {{}}],

 [[NewXSCoerceMustNS],	[FTypes],	"make_newcoerce"],
 [[NewXSCoerceMust],	[NewXSCoerceMustNS,NewXSSymTab,Name], "dousualsubsts"],

 [[DefaultFlowCode],	[DefaultFlowCodeNS,NewXSSymTab,Name], "dousualsubsts"],

 [[GenericTypes],	[],	sub {[B,S,U,L,F,D]}], 
#  [[GenericTypes],	[],	sub {[F,D]}],

 [[NewXSFindDatatypeNS],	[ParNames,ParObjs,IgnoreTypesOf,NewXSSymTab,
				GenericTypes],	
 						"find_datatype"],

 [[NewXSFindDatatype],	[NewXSFindDatatypeNS,NewXSSymTab,Name],	
 						"dousualsubsts"],
 [[NewXSTypeCoerce],	[NoConversion],		sub {""}],

 [[NewXSTypeCoerceNS],	[ParNames,ParObjs,IgnoreTypesOf,NewXSSymTab],
 						"coerce_types"],

 [[NewXSTypeCoerce],	[NewXSTypeCoerceNS,NewXSSymTab,Name], "dousualsubsts"],

 [[NewXSStructInit1],	[ParNames,NewXSSymTab],	"CopyPDLPars"],
 [[NewXSSetTrans],	[ParNames,ParObjs,NewXSSymTab],	"makesettrans"],

 [[ExtraGenericLoops],	[FTypes],	sub {return $_[0]}],
 [[ExtraGenericLoops],	[],	sub {return {}}],

 [["ParsedCode"],	[Code,ParNames,ParObjs,DimObjs,GenericTypes,
 			 ExtraGenericLoops,HaveThreading],	
 				sub {new PDL::PP::Code(@_)}],
 [["ParsedBackCode"],	[BackCode,ParNames,ParObjs,DimObjs,GenericTypes,
 			 ExtraGenericLoops,HaveThreading],	
 				sub {new PDL::PP::Code(@_)}],

# Compiled representations i.e. what the xsub function leaves
# in the trans structure. By default, copies of the parameters
# but in many cases (e.g. slice) a benefit can be obtained
# by parsing the string in that function.

# If the user wishes to specify his own code and compiled representation,
# The next two definitions allow this.
# Because of substitutions that will be there, 
# makecompiledrepr et al are array refs, 0th element = string,
# 1th element = hashref of translated names
# This makes the objects: type + ...
 [[CompNames,CompObjs],	[Comp],			"OtherPars_nft"],
 [[CompiledRepr],	[CompNames,CompObjs],	"NT2Decls_p"],
 [[MakeCompiledRepr],	[MakeComp,CompNames,CompObjs],		
 						sub {subst_makecomp(COMP,@_)}],

 [[CompCopyCode],	[CompNames,CompObjs,CopyName], "NT2Copies_p"],
 [[CompFreeCode],	[CompNames,CompObjs], 	"NT2Free_p"],

# This is the default
 [[MakeCompiledRepr],	[OtherParNames,OtherParTypes,
  			 NewXSSymTab],
 						"CopyOtherPars"],
 [[CompiledRepr],	[OtherParNames,OtherParTypes],
 						"NT2Decls"],
 [[CompCopyCode],	[OtherParNames,OtherParTypes,CopyName], "NT2Copies_p"],
 [[CompFreeCode],	[OtherParNames,OtherParTypes], "NT2Free_p"],



# Threads
 [[Priv,PrivIsInc],	[ParNames,ParObjs,DimObjs],	"make_incsizes"],
 [[PrivCopyCode],	[ParNames,ParObjs,DimObjs,CopyName,PrivIsInc],	
 	"make_incsize_copy"],
 [[PrivFreeCode],	[ParNames,ParObjs,DimObjs,PrivIsInc],	
 	"make_incsize_free"], # Frees thread.
 [[RedoDimsCode],       [],      sub {"/* none */"}],

# [[RedoDimsParsedCode], [RedoDimsCode], sub {print "RedoDimsCode = $_[0]\n" if $::PP_VERBOSE;
#				      return "/* no RedoDimsCode */"
#                                        if $_[0] =~ m|^/[*] none [*]/$|;
#				      @_}],

 [[RedoDimsParsedCode], [RedoDimsCode,ParNames,ParObjs,DimObjs,
                         GenericTypes,ExtraGenericLoops,HaveThreading],	
 				sub { # print "RedoDimsCode = $_[0]\n";
				      return "/* no RedoDimsCode */"
                                        if $_[0] =~ m|^/[*] none [*]/$|;
				      new PDL::PP::Code(@_,1)}],
 [[RedoDims],	[ParNames,ParObjs,DimObjs,DimmedPars,RedoDimsParsedCode],	"make_redodims_thread"],

 [[Priv],	[],			"nothing"],

 [[PrivNames,PrivObjs],	[Priv],			"OtherPars_nft"],
 [[PrivateRepr],	[PrivNames,PrivObjs],	"NT2Decls_p"],
 [[PrivCopyCode],	[PrivNames,PrivObjs,CopyName], "NT2Copies_p"],
 [[PrivFreeCode],	[PrivNames,PrivObjs], "NT2Free_p"],

 [[IsReversibleCodeNS],	[Reversible],	"ToIsReversible"],
 [[IsReversibleCode],	[IsReversibleCodeNS,NewXSSymTab,Name], "dousualsubsts"],

 [[NewXSStructInit2],	[MakeCompiledRepr, NewXSSymTab,Name],	sub {"{".dosubst(@_)."}"}],
 
 [[CopyCodeNS],	[PrivCopyCode,CompCopyCode,StructName],	sub {"$_[2] *__copy
 			= malloc(sizeof($_[2])); 
			PDL_TR_CLRMAGIC(__copy);
			__copy->flags = \$PRIV(flags);
			__copy->vtable = \$PRIV(vtable);
			__copy->__datatype = \$PRIV(__datatype);
			__copy->freeproc = NULL;
			__copy->__ddone = \$PRIV(__ddone);
			{int i;
			 for(i=0; i<__copy->vtable->npdls; i++) 
				__copy->pdls[i] = \$PRIV(pdls[i]);
			}
			$_[1]
			if(__copy->__ddone) {
				$_[0]
			}
			return (pdl_trans*)__copy;"}],
 
 [[FreeCodeNS],	[PrivFreeCode,CompFreeCode],	sub {"
			PDL_TR_CLRMAGIC(__privtrans);
			$_[1]
			if(__privtrans->__ddone) {
				$_[0]
			}
			"}],

 [[CopyCode],	[CopyCodeNS,NewXSSymTab,Name], "dousualsubsts"],
 [[FreeCode],	[FreeCodeNS,NewXSSymTab,Name], "dousualsubsts"],
 [[FooCodeSub], [FooCode,NewXSSymTab,Name], "dousualsubsts"],

 [[NewXSCoerceMust],	[],	sub {""}],
 [[NewXSCoerceMustSub1], [NewXSCoerceMust],	sub{subst_makecomp(FOO,@_)}],
 [[NewXSCoerceMustSubs], [NewXSCoerceMustSub1,NewXSSymTab,Name],	"dosubst"],

 [[NewXSCode,BootSetNewXS,NewXSInPrelude
  ],		[_GlobalNew,_NewXSCHdrs,NewXSHdr,NewXSLocals,NewXSStructInit0,
 			 NewXSMakeNow, NewXSFindDatatype,NewXSTypeCoerce,
			 NewXSStructInit1,
			 NewXSStructInit2, 
			 NewXSCoerceMustSubs,_IsReversibleCode,DefaultFlowCode,
			 NewXSSetTrans,
			 ],	"mkxscat"],
 [[StructDecl],		[ParNames,ParObjs, CompiledRepr,
                         PrivateRepr,StructName],		
			 			"mkstruct"],
 [[RedoDimsSub],	[RedoDims,PrivNames,PrivObjs,_DimObjs],
				sub {
				 my $do = $_[3];
				 my $r = subst_makecomp(PRIV,"$_[0] \$PRIV(__ddone) = 1;",@_[1,2]);
				 $r->[1]{SIZE} = sub {
					croak "can't get SIZE of undefined dimension $this->[0]"
					  unless defined($do->{$_[0]});
					return $do->{$_[0]}->get_size();
				  };
				 return $r;
				 }],
 [[RedoDimsSubd],	[RedoDimsSub,NewXSSymTab,Name],	"dosubst"],
 [[RedoDimsFunc], 	[RedoDimsSubd,FHdrInfo,RedoDimsFuncName],	
 				sub {wrap_vfn(@_,"redodims")}],

#  [[ReGenedCode],	[ParsedCode,ParObjs,DimObjs],	sub {$_[0]->gen($_[1,2])}],
 [[ReadDataSub],	[ParsedCode],	
 				sub {subst_makecomp(FOO,@_)}],
 [[ReadDataSubd],	[ReadDataSub,NewXSSymTab,Name],	"dosubst"],
 [[ReadDataFunc], 	[ReadDataSubd,FHdrInfo,ReadDataFuncName],	
 			sub {wrap_vfn(@_,"readdata")}],

 [[WriteBackDataSub],	[ParsedBackCode],	sub {subst_makecomp(FOO,@_)}],
 [[WriteBackDataSubd],	[WriteBackDataSub,NewXSSymTab,Name],	"dosubst"],

 [[WriteBackDataFuncName],	[BackCode,Name],	sub {"pdl_$_[1]_writebackdata"}],
 [[WriteBackDataFuncName],	[Code],	sub {"NULL"}],

 [[WriteBackDataFunc], 	[WriteBackDataSubd,FHdrInfo,WriteBackDataFuncName],	
 	sub {wrap_vfn(@_,"writebackdata")}],
 
 [[CopyFunc],	[CopyCode,FHdrInfo,CopyFuncName],sub {wrap_vfn(@_,"copy")}],
 [[FreeFunc],	[FreeCode,FHdrInfo,FreeFuncName],sub {wrap_vfn(@_,"free")}],

 [[FoofName],	[FooCodeSub],	sub {"foomethod"}],
 [[FooFunc],	[FooCodeSub,FHdrInfo,FoofName], sub {wrap_vfn(@_,"foo")}],

 [[FoofName], [],	sub {"NULL"}],

 [[VTableDef],	[VTableName, StructName, RedoDimsFuncName,ReadDataFuncName,
 		 WriteBackDataFuncName,CopyFuncName,FreeFuncName,
		 ParNames,ParObjs,Affine_Ok,FoofName],	"def_vtable"],
];

sub GenDocs {
  my ($name,$pars,$otherpars,$doc) = @_;
  
  # Allow explcit non-doc using Doc=>undef
  
  return '' if $doc eq '' && (!defined $doc) && $doc==undef; 

  # If the doc string is one line let's have to for the
  # reference card information as well
  
  $doc = "=for ref\n\n".$doc if split("\n", $doc) <= 1;
  
  return '' if $doc =~ /^\s*internal\s*$/i;
  $::DOCUMENTED++;
  $pars = "P(); C()" unless $pars;
  $pars =~ s/^\s*(.+[^;])[;\s]*$/$1/;
  $otherpars =~ s/^\s*(.+[^;])[;\s]*$/$1/ if $otherpars;
  my $sig = "$pars".( $otherpars ? "; $otherpars" : "");
  
  $doc =~ s/\n(=cut\s*\n)+(\s*\n)*$/\n/m; # Strip extra =cut's
   
  return << "EOD";

=head2 $name

=for sig

  Signature: ($sig)

$doc

=cut

EOD
}

sub printtrans {
	my($bar) = @_;
	for (qw/StructDecl RedoDimsFunc ReadDataFunc WriteBackFunc
		VTableDef NewXSCode/) {
		print "\n\n================================================
	$_
=========================================\n",$bar->{$_},"\n" if $::PP_VERBOSE;
	}
}

# use Data::Dumper;

use Carp;
# use Data::Dumper;

sub translate {
	my($pars,$tbl) = @_;
	my $rule;
	RULE: for $rule(@$tbl) {
# Are all prerequisites there;
		my @args;
#		print "Trying rule ",Dumper($rule) if $::PP_VERBOSE;
		for(@{$rule->[0]}) {
			if(exists $pars->{$_}) {
				print "Not applying rule $rule->[2], resexist\n"
				 if $::PP_VERBOSE;
				next RULE
			}
		}
		for(@{$rule->[1]}) {
			my $foo = $_;
			if(/^_/) {
				$foo =~ s/^_//;
			} elsif(!exists $pars->{$_}) {
				print "Component $_ not found for $rule->[2], next rule\n" if $::PP_VERBOSE;
				next RULE
			}
			push @args, $pars->{$foo};
		}
#		print "Applying rule $rule->[2]\n",Dumper($rule);
		print "Applying rule $rule->[2]\n" if $::PP_VERBOSE;
		@res = &{$rule->[2]}(@args);
		print "Setting " if $::PP_VERBOSE;
		for(@{$rule->[0]}) {
			if(exists $pars->{$_}) {
				confess "Cannot have several meanings yet\n";
			}
			print "$_ " if $::PP_VERBOSE;
			$pars->{$_} = shift @res;
		}
		print "\n" if $::PP_VERBOSE;
	}
#	print Dumper($pars);
	print "GOING OUT!\n" if $::PP_VERBOSE;
	return $pars;
}

use Carp;

# ==== FCN ====

sub ToIsReversible {
	my($rev) = @_;
	if($rev eq "1") {
		'$SETREVERSIBLE(1)'
	} else {
		$rev
	}
}

sub make_newcoerce {
	my($ftypes) = @_;
	join '',map {
		"$_->datatype = $ftypes->{$_}; "
	} (keys %$ftypes);
}

sub coerce_types {
	my($parnames,$parobjs,$ignore,$newstab) = @_;
	(join '',map {
		my $dtype = ($parobjs->{$_}->{FlagTyped}) ?
			($parobjs->{$_}->{FlagTplus}) ?
			  "PDLMAX(".$parobjs->{$_}->cenum().
			       ",\$PRIV(__datatype))" :
                             $parobjs->{$_}->cenum()
			: "\$PRIV(__datatype)";
		($ignore->{$_} ? () :
		 $parobjs->{$_}->{FlagCreateAlways} ? 
		  "$_->datatype = $dtype; " :
		   "if((($_->state & PDL_NOMYDIMS) && 
		         $_->trans == NULL) &&
		       0$parobjs->{$_}->{FlagCreat}) {
			  $_->datatype = $dtype;  
		    } else if($dtype != $_->datatype) {
			$_ = PDL->get_convertedpdl($_,$dtype);
		    }")} (@$parnames))
}

# First, finds the greatest datatype, then, if not supported, takes
# the largest type supported by the function.
# Not yet optimal.
sub find_datatype {
	my($parnames,$parobjs,$ignore,$newstab,$gentypes) = @_;
	"\$PRIV(__datatype) = 0;".
	(join '', map {
		$parobjs->{$_}->{FlagTyped}
			? () :
#		print "FD: $_, $ignore->{$_}, $parobjs->{$_}->{FlagCreateAlways}\n";
		($ignore->{$_} ||
		 $parobjs->{$_}->{FlagCreateAlways} ? () :
		 "if(".
		   ($parobjs->{$_}->{FlagCreat}?
		      "!(($_->state & PDL_NOMYDIMS) &&
		       $_->trans == NULL) && " : "")
		       ."
		 	\$PRIV(__datatype) < $_->datatype) {
		 	\$PRIV(__datatype) = $_->datatype;
		  }
		  ")
	}(@$parnames)).
	(join '', map {
		"if(\$PRIV(__datatype) == PDL_$_) {
		 } else "
	}(@$gentypes))."\$PRIV(__datatype) = PDL_$gentypes->[-1];";
}

sub make_incsizes {
	my($parnames,$parobjs,$dimobjs) = @_;
	"pdl_thread __thread; ".
	 (join '',map {$parobjs->{$_}->get_incdecls} @$parnames).
	 (join '',map {$_->get_decldim} values %$dimobjs);
}

sub make_incsize_copy {
	my($parnames,$parobjs,$dimobjs,$copyname) = @_;
	"PDL->thread_copy(&(\$PRIV(__thread)),&($copyname->__thread));".
	 (join '',map {$parobjs->{$_}->get_incdecl_copy(sub{"\$PRIV($_[0])"},
	 						sub{"$copyname->$_[0]"})} @$parnames).
	 (join '',map {$_->get_copydim(sub{"\$PRIV($_[0])"},
						sub{"$copyname->$_[0]"})} values %$dimobjs);
	 
}

sub make_incsize_free {
	my($parnames,$parobjs,$dimobjs) = @_;
	'PDL->freethreadloop(&($PRIV(__thread)));'
}

sub make_parnames {
	my($pnames,$pobjs,$dobjs) = @_;
	my @pdls = map {$pobjs->{$_}} @$pnames;
	my $npdls = $#pdls+1;
	return("static char *__parnames[] = {".
			(join ",",map {qq|"$_"|} @$pnames)."};
		static int __realdims[] = {".
			(join ",",map {$#{$_->{IndObjs}}+1} @pdls). "};
		static char __funcname[] = \"\$MODULE(): \$NAME()\";
		static pdl_errorinfo __einfo = {
			__funcname, __parnames, $npdls
		};
		");
}

sub make_redodims_thread {
	my($pnames,$pobjs,$dobjs,$dpars,$pcode) = @_;
	my $str; my $npdls = @$pnames;
	$str .= "int __creating[$npdls];";
	$str .= join '',map {$_->get_initdim."\n"} values %$dobjs;
	$str .= join '',map {"__creating[$_] = 
			(PDL_CR_SETDIMSCOND(__privtrans,\$PRIV(pdls[$_])))
				&& ".($pobjs->{$pnames->[$_]}{FlagCreat}?1:0)." ;\n"} (0..$#$pnames);
# - null != [0]
#	$str .= join '',map {"if((!__creating[$_]) && \$PRIV(pdls[$_])-> ndims == 1 && \$PRIV(pdls[$_])->dims[0] == 0)
#				   \$CROAK(\"CANNOT CREATE PARAMETER $pobjs->{$pnames->[$_]}{Name}\");
#					"} (0..$#$pnames);
	$str .= join '',map {"if((!__creating[$_]) && (\$PRIV(pdls[$_])->state & PDL_NOMYDIMS) && \$PRIV(pdls[$_])->trans == 0)
				   \$CROAK(\"CANNOT CREATE PARAMETER $pobjs->{$pnames->[$_]}{Name}\");
					"} (0..$#$pnames);
	$str .= " {\n$pcode\n}\n";
	$str .= " {\n " . make_parnames($pnames,$pobjs,$dobjs) . "
		 PDL->initthreadstruct(2,\$PRIV(pdls),
			__realdims,__creating,$npdls,
			&__einfo,&(\$PRIV(__thread)),
                        \$PRIV(vtable->per_pdl_flags));
		}\n";
	$str .= join '',map {$pobjs->{$_}->get_xsnormdimchecks()} @$pnames;
	$str .= join '',map {$pobjs->{$pnames->[$_]}->
				get_incsets("\$PRIV(pdls[$_])")} 0..$#$pnames;
	$str;
}

sub def_vtable {
	my($vname,$sname,$rdname,$rfname,$wfname,$cpfname,$ffname,
		$pnames,$pobjs,$affine_ok,$foofname) = @_;
	my $nparents = 0 + grep {! $pobjs->{$_}->{FlagW}} @$pnames;
	my $aff = ($affine_ok ? "PDL_TPDL_VAFFINE_OK" : 0);
	my $npdls = scalar @$pnames;
	"static char ${vname}_flags[] = 
	 	{ ".
	 	(join",",map {$pobjs->{$pnames->[$_]}->{FlagPaccess} ?
				0 : $aff} 0..$npdls-1).
			"};
	 pdl_transvtable $vname = {
		0,0, $nparents, $npdls, ${vname}_flags, 
		$rdname, $rfname, $wfname,
		$ffname,NULL,NULL,$cpfname,NULL,
		sizeof($sname),\"$vname\",
		$foofname
	 };"
}

sub sort_pnobjs {
	my($pnames,$pobjs) = @_;
	my (@nn);
	for(@$pnames) {
		if(!($pobjs->{$_}{FlagW})) { push @nn,$_; }
	}
	for(@$pnames) {
		if(($pobjs->{$_}{FlagW})) { push @nn,$_; }
	}
	my $no = 0;
	for(@nn) {
		$pobjs->{$_}{Number} = $no++;
	}
	return (\@nn,$pobjs);
}

sub mkfhdrinfo {
	my($name,$sname) = @_;
	return {
		Name => $name,
		StructName => $sname,
	};
}

# XXX __privtrans explicit :(
sub wrap_vfn {
	my($code,$hdrinfo,$rout,$name) = @_;
        my $type = ($name eq "copy" ? "pdl_trans *" : "void");
	my $sname = $hdrinfo->{StructName};
	my $oargs = ($name eq "foo" ? ",int i1,int i2,int i3" : "");
        qq|$type $rout(pdl_trans *__tr $oargs) {
                int __dim;
                $sname *__privtrans = ($sname *) __tr;
                pdl *__it = __tr->pdls[1];
                pdl *__parent = __tr->pdls[0];
                {
			$code
		}
	}
        |;
}

sub makesettrans {
	my($pnames,$pobjs,$symtab) = @_;
	my $trans = $symtab->get_symname(_PDL_ThisTrans);
	my $no=0;
	(join '',map {
		"$trans->pdls[".($no++)."] = $_;\n"
	} @$pnames).
	"PDL->make_trans_mutual((pdl_trans *)$trans);\n"
}

sub identity2priv {
	'
		int i;
		$SETNDIMS($PARENT(ndims));
		for(i=0; i<$CHILD(ndims); i++) {
			$CHILD(dims[i]) = $PARENT(dims[i]);
		}
		$SETDIMS();
		$SETDELTATHREADIDS(0);
	'
}

sub pdimexpr2priv {
	my($pdimexpr,$hdr,$dimcheck) = @_;
	$pdimexpr =~ s/\$CDIM\b/i/g;
	'
		int i,cor;
		'.$dimcheck.'
		$SETNDIMS($PARENT(ndims));
		$DOPRIVDIMS();
		$PRIV(offs) = 0;
		for(i=0; i<$CHILD(ndims); i++) {
			cor = '.$pdimexpr.';
			$CHILD(dims[i]) = $PARENT(dims[cor]);
			$PRIV(incs[i]) = $PARENT(dimincs[cor]);
				
		}
		$SETDIMS();
		$SETDELTATHREADIDS(0);
	'
}

sub affinepriv {
	'PDL_Long incs[$CHILD(ndims)];PDL_Long offs; '
}

sub dousualsubsts {
	my($src,$symtab,$name) = @_;
	return dosubst([$src,
		{@::std_childparent}
	     ],$symtab,$name);
}

sub dosubst {
	my($src,$symtab,$name) = @_;
#	print "DOSUBST on ",Dumper($src),"\n";
	$ret = (ref $src ? $src->[0] : $src);
	my %syms = (
		((ref $src) ? %{$src->[1]} : ()),
		PRIV => sub {return "".$symtab->get_symname(_PDL_ThisTrans).
					"->$_[0]"},
		CROAK => sub {return "barf(\"Error in $name:\" $_[0])"},
		NAME => sub {return $name},
		MODULE => sub {return $::PDLMOD},
	SETREVERSIBLE => sub {"if($_[0]) \$PRIV(flags) |= PDL_ITRANS_REVERSIBLE;
				else \$PRIV(flags) &= ~PDL_ITRANS_REVERSIBLE;"},
	);
	while(
		$ret =~ s/\$(\w+)\(([^()]*)\)/
			(defined $syms{$1} or
				confess("$1 not defined in '$ret'!")) and
			(&{$syms{$1}}($2))/ge
	) {};
	$ret;
}

BEGIN {
@::std_childparent = (
	CHILD => sub {return '$PRIV(pdls[1]->'.(join ',',@_).")"},
	PARENT => sub {return '$PRIV(pdls[0]->'.(join ',',@_).")"},
	CHILD_P => sub {return '$PRIV(pdls[1]->'.(join ',',@_).")"},
	PARENT_P => sub {return '$PRIV(pdls[0]->'.(join ',',@_).")"},
	CHILD_PTR => sub {return '$PRIV(pdls[1])'},
	PARENT_PTR => sub {return '$PRIV(pdls[0])'},
	COMP => sub {return '$PRIV('.(join ',',@_).")"},
);
@::std_redodims = (
	SETNDIMS => sub {return "PDL->reallocdims(__it,$_[0])"},
	SETDIMS => sub {return "PDL->setdims_careful(__it)"},
	SETDELTATHREADIDS => sub {return '
		{int __ind; PDL->reallocthreadids($CHILD_PTR(),
			$PARENT(nthreadids));
		for(__ind=0; __ind<$PARENT(nthreadids)+1; __ind++) {
			$CHILD(threadids[__ind]) =
				$PARENT(threadids[__ind]) + ('.$_[0].');
		}
		}
		'}
				
);
}


sub subst_makecomp {
	my($which,$mc,$cn,$co) = @_;
	return [$mc,{
		@::std_childparent,
		($cn ? 
			((DO.$which.DIMS) => sub {return join '',
				map{$$co{$_}->need_malloc ?
				    $$co{$_}->get_malloc('$PRIV('.$_.')') :
				    ()} @$cn}) :
			()
		),
		($which eq "PRIV" ?
			@::std_redodims : ()),
		},
	];
}

sub ParentChildPars {
	my($p2child,$name) = @_;
	return (Pars_nft("PARENT(); [oca]CHILD();"),0,"${name}_XX",
	"
	*$name = \\&PDL::$name;
	sub PDL::$name {
		my \$foo=PDL->null;
		my \$this = shift;
		PDL::${name}_XX(\$this,\$foo,\@_);
		\$foo
	}
	");
}

sub mkstruct {
	my($pnames,$pobjs,$comp,$priv,$name) = @_;
	my $npdls = $#$pnames+1;
	my $decl = "typedef struct $name {
		PDL_TRANS_START($npdls);
		$priv
		$comp
		char __ddone; /* Dims done */
		} $name;";
	return $decl;
}

sub nothing {return "";}

sub NT2Decls_p {&NT2Decls__({ToPtrs=>1},@_);}

sub NT2Copies_p {&NT2Copies__({ToPtrs=>1},@_);}

sub NT2Free_p {&NT2Free__({ToPtrs=>1},@_);}

sub NT2Decls {&NT2Decls__({},@_);}

sub NT2Decls__ {
	my($opts,$onames,$otypes) = @_; my $decl;
	my $dopts = {};
	if($opts->{ToPtrs}) {
		$dopts->{VarArrays2Ptrs} = 1;
	}
	for(@$onames) {
		$decl .= $otypes->{$_}->get_decl($_,$dopts).";";
	}
	$decl
}

sub NT2Copies__ {
	my($opts,$onames,$otypes,$copyname) = @_; my $decl;
	my $dopts = {};
	if($opts->{ToPtrs}) {
		$dopts->{VarArrays2Ptrs} = 1;
	}
	for(@$onames) {
		$decl .= $otypes->{$_}->get_copy("\$PRIV($_)","$copyname->$_",
			$dopts).";";
	}
	$decl
}

sub NT2Free__ {
	my($opts,$onames,$otypes) = @_; my $decl;
	if($opts->{ToPtrs}) {
		$dopts->{VarArrays2Ptrs} = 1;
	}
	for(@$onames) {
		$decl .= $otypes->{$_}->get_free("\$PRIV($_)",
			$dopts).";";
	}
	$decl
}

sub CopyOtherPars {
	my($onames,$otypes,$symtab) = @_; my $repr; 
	my $sname = $symtab->get_symname(_PDL_ThisTrans);
	for(@$onames) {
		$repr .= $otypes->{$_}->get_copy("$_","$sname->$_");
	}
	return $repr;
}

sub mkxscat {
	my($glb,$chdrs,$hdr,@bits) = @_;
	my($xscode,$boot,$prel,$str);
	if($glb) {
		$prel = $chdrs->[0] . "@bits" . $chdrs->[1];
		$boot = $chdrs->[3];
		$str = "$hdr\n";
	} else {
		$xscode = join '',@bits;
		$str = "$hdr CODE:\n { $xscode XSRETURN(0);\n}\n\n";
	}
	$str =~ s/(\s*\n)+/\n/g;
	($str,$boot,$prel)
}

# Not necessary ?
sub CopyPDLPars {
if(0) {
	my($pnames,$symtab) = @_;
	my $tt = $symtab->get_symname(_PDL_ThisTrans);
	my $str; my $no=0;
	for(@$pnames) {
		$str .= "$tt->pdls[$no] = ".$_.";\n";
		$no++;
	}
	$str
}
	""
}

sub direct {return @_;}

sub MakeNows {
	my($pnames, $symtab) = @_;
	my $str;
	for(@$pnames) {
		$str .= "$_ = PDL->make_now($_);\n";
	}
	$str;
}

sub Sym2Loc {
	return $_[0]->decl_locals();
}

sub defstructname {return "pdl_$_[0]_struct"}
sub defvtablename {return "pdl_$_[0]_vtable"}

sub MkPrivStructInit {
	my($symtab,$vtable,$affflag) = @_;
	my $sname = $symtab->get_symname(_PDL_ThisTrans);
	return "$sname = malloc(sizeof(*$sname));
		PDL_TR_SETMAGIC($sname);
		$sname->flags = $affflag;
		$sname->__ddone = 0;
		$sname->vtable = &$vtable;
		$sname->freeproc = PDL->trans_mallocfreeproc;";
	return $init;
}

sub MkDefSyms {
	return new SymTab(
		_PDL_ThisTrans => ["__privtrans",new C::Type(undef,"$_[0] *foo")],
	);
}

sub AddArgsyms {
	my($symtab,$args) = @_;
	$symtab->add_params(
		map {($_->[0],$_->[0])} @$args
	);
	return $symtab;
}

# Eliminate whitespace entries
sub nospacesplit {map {/^\s*$/?():$_} split $_[0],$_[1]}

# Pars -> ParNames, Parobjs
sub Pars_nft {
	my($str) = @_;
	my $sig = new PDL::PP::Signature($str);
	return ($sig->names,$sig->objs,1);
}

# ParNames,Parobjs -> DimObjs
sub ParObjs_DimObjs {
	my($pnames,$pobjs) = @_;
	my ($dimobjs) = new PDL::PP::PdlDimsObj;
	for(@$pnames) {
		$pobjs->{$_}->add_inds($dimobjs);
	}
	return ($dimobjs);
}

sub OtherPars_nft {
	my($otherpars,$dimobjs) = @_;
	my(@names,%types,$type);
	# support 'int ndim => n;' syntax
	for (nospacesplit ';',$otherpars) {
		if (/^\s*([^=]+)\s*=>\s*(\S+)\s*$/) {
		   my ($ctype,$dim) = ($1,$2);
		   $ctype =~ s/(\S+)\s+$/$1/; # get rid of trailing ws
		   print "OtherPars: setting dim '$dim' from '$ctype'\n" if $::PP_VERBOSE;
		   $type = new C::Type(undef,$ctype);
		   croak "can't set unknown dimension"
			unless defined($dimobjs->{$dim});
		   $dimobjs->{$dim}->set_from($type);
		} elsif(/^\s*pdl\s+\*\s*(\w+)$/) {
			# It is a piddle -> make it a controlling one.
			die("Not supported yet");
		} else {
		   $type = new C::Type(undef,$_);
		}
		my $name = $type->protoname;
		push @names,$name;
		$types{$name} = $type;
	}
	return (\@names,\%types);
}

sub NXArgs {
	my($parnames,$parobjs,$onames,$oobjs) = @_;
	my $pdltype = new C::Type(undef,"pdl *__foo__");
	my $nxargs = [
		( map {[$_,$pdltype]} @$parnames ),
		( map {[$_,$oobjs->{$_}]} @$onames )
	];
	return $nxargs;
}

sub XSHdr {
	my($xsname,$nxargs) = @_;
	return XS::mkproto($xsname,$nxargs);
}

sub XSCHdrs {
	my($name,$pars,$gname) = @_;
	my $shortpars = join ',',map {$_->[0]} @$pars;
	my $longpars = join ",",map {$_->[1]->get_decl($_->[0])} @$pars;
	return ["void $name($longpars) {","}","",
		"PDL->$gname = $name;"];
}


# Make the pm code to massage the arguments if not given enough.
# This function is troublesome because perl5.004_0[0123]
# all contain a bug in 'splice @_,...'.
# However, we can't use just assign because of e.g. otherpars
# and strange argument orderings.
sub pmcode {
	my($name,$newxsname,$parnames,$parobjs,$onames,$oobjs) = @_;
	my ($acnt,$tcnt,$icnt)=(0,0,0) ;
	my ($tspl, $ispl);
	my (@tmap,@imap); # maps: number to get argument n from
	$acnt = 0;
	for(@$parnames) {
		if($parobjs->{$_}->{FlagOut}) {
			push @tmap,$tcnt;
			push @imap,-2;
			$tcnt++;
			$ispl .= "push \@ret,PDL->null; 
			\$_[$acnt] = \$ret[-1];";
		} elsif($parobjs->{$_}->{FlagTemp}) {
			push @tmap,-1;
			push @imap,-1;
			my $spl = "\$_[$acnt] = PDL->null;";
			$tspl .= $spl; $ispl .= $spl
		} else {
			push @tmap,$tcnt;
			push @imap,$icnt;
			$tcnt++;
			$icnt++;
		}
		$acnt ++
	}
	for(@$onames) {
		push @tmap,$tcnt++;
		push @imap,$icnt++;
	}
	my $icode = "";
	my $tcode = "";
	my $ind;
	for $ind (reverse 0..$#imap) {
		if($imap[$ind] == -2) {
			$icode .= "unshift \@ret,(\$_[$ind] = PDL->null);\n";
		} elsif($imap[$ind] == -1) {
			$icode .= "\$_[$ind] = PDL->null;\n";
		} else {
			$icode .= "\$_[$ind] = \$_[$imap[$ind]];\n";
		}
	}
	for $ind (reverse 0..$#tmap) {
		if($tmap[$ind] == -1) {
			$tcode .= "\$_[$ind] = PDL->null;\n";
		} else {
			$tcode .= "\$_[$ind] = \$_[$tmap[$ind]];\n";
		}
	}
#	print "COUNTS0: $acnt $tcnt $icnt\n";
	$acnt += scalar(@$onames);
#	print "COUNTS: $acnt $tcnt $icnt\n";

	return "sub ".$::PDLOBJ."::$name {
		if(\$#_ == ". ($acnt-1) ." || \$#_ == -1 ) { &".$::PDLOBJ."::".$newxsname."; }
		 elsif(\$#_ == ". ($tcnt-1) .") { 
		 	\@_ = \@_;
		 	$tcode
			&".$::PDLOBJ."::".$newxsname.";
		} elsif(\$#_ == ". ($icnt-1) .") {
			\@_ = \@_;
			my \@ret;
			$icode
			&".$::PDLOBJ."::".$newxsname.";
			return wantarray?(\@ret):\$ret[0];
		} else {
			barf \"Invalid number of arguments for $name\";
		}
		}";
# THIS IS BAD: ASSIGNMENTS DON'T WORK.
	return "sub ".$::PDLOBJ."::$name {
		if(\$#_ == ". ($acnt-1) ." || \$#_ == -1 ) { &".$::PDLOBJ."::".$newxsname."; }
		 elsif(\$#_ == ". ($tcnt-1) .") { 
		 	$tspl
			&".$::PDLOBJ."::".$newxsname.";
		} elsif(\$#_ == ". ($icnt-1) .") {
			my \@ret;
			$ispl
			&".$::PDLOBJ."::".$newxsname.";
			return wantarray?(\@ret):\$ret[0];
		}
		}";
}


