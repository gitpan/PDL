=head1 NAME

PDL::Io::FastRaw -- A simple, fast and convenient io format for PerlDL.

=head1 SYNOPSIS

	use PDL;
	use PDL::Io::FastRaw;

	writefraw($pdl,"fname");

	$pdl2 = readfraw("fname");

	$pdl3 = mapfraw("fname");
	$pdl3 = createmapfraw("fname",@dims);

=head1 DESCRIPTION

This is a very simple and fast io format for PerlDL.
The disk data consists of two files, a header metadata file
in ASCII and a binary file consisting simply of consecutive
bytes, shorts or whatever.

It is hoped that this will not only make for a simple PerlDL module
for saving and retrieving these files but also make it easy
for other programs to use these files.

The format for the header is simply

	<typeid>
	<ndims>
	<dim0> <dim1> ...

These files are NOT interchangeable over network since the binary
file is simply dumped from the memory region of the piddle.
This is also what makes the approach efficient.

=head1 IF YOU HAVE TOO MUCH SPARE TIME

You could implement an interface using mmap for this module.
In the case of huge data sets that you usually only need
parts of, the benefit would be immense. Contact the author
for instructions.

=head1 BUGS

None known.

=head1 AUTHOR

Copyright (C) Tuomas J. Lukka 1997. Redistribution in printed
form forbidden.

=cut

package PDL::Io::FastRaw;

require Exporter;
use PDL;
use FileHandle;
use Carp;
use Data::Dumper;

@PDL::Io::FastRaw::ISA = qw/Exporter/;

@EXPORT = qw/writefraw readfraw mapfraw/;

sub _read_frawhdr {
	my($name) = @_;
	my $hname = "$name.hdr";
	my $h = new FileHandle "$hname"
	 or croak "Couldn't open '$hname' for writing";
	my $tid = <$h>;
	my $ndims = <$h>;
	my $str = <$h>; if(!defined $str) {croak("Format error in '$hname'");}
	my @dims = split ' ',$str;
	if($#dims != $ndims-1) {
		croak("Format error reading fraw header file '$hname'");
	}
	return {
		Type => $tid,
		Dims => \@dims,
		NDims => $ndims
	};
}

sub writefraw {
	my($pdl,$name,$opts) = @_;
	my $hname = "$name.hdr";
	my $h = new FileHandle ">$hname"
	 or croak "Couldn't open '$hname' for writing";
	my $d = new FileHandle ">$name"
	 or croak "Couldn't open '$name' for writing";
	print $h map {"$_\n"} ($pdl->get_datatype,
		$pdl->getndims, (join ' ',$pdl->dims));
	print $d ${$pdl->get_dataref};
}

sub readfraw {
	my($name,$opts) = @_;
	my $d = new FileHandle "$name"
	 or croak "Couldn't open '$name' for writing";
	my $hdr = _read_frawhdr($name);
	my $pdl = PDL->zeroes ((new PDL::Type($hdr->{Type})), @{$hdr->{Dims}});
	my $len = length ${$pdl->get_dataref};
	$d->sysread(${$pdl->get_dataref},$len) == $len
	  or croak "Couldn't read enough data from '$name'";
	return $pdl;
}

sub mapfraw {
	my($name,$opts) = @_;
	my $hdr;
	if($opts->{Dims}) {
		my $datatype = $opts->{Datatype};
		if(!defined $datatype) {$datatype = $PDL_D;}
		$hdr->{Type} = $datatype;
		$hdr->{Dims} = $opts->{Dims};
		$hdr->{NDims} = scalar(@{$opts->{Dims}});
	} else {
		$hdr = _read_frawhdr($name);
	}
	print Dumper($hdr);
	$s = PDL::Core::howbig($hdr->{Type});
	for(@{$hdr->{Dims}}) {
		$s *= $_;
	}
	my $pdl = PDL->zeroes(new PDL::Type($hdr->{Type}));
	$pdl->dump();
	$pdl->setdims($hdr->{Dims});
	$pdl->dump();
	$pdl->set_data_by_mmap($name,$s,1,($opts->{ReadOnly}?0:1),
		($opts->{Creat}?1:0),
		(0644),
		($opts->{Creat} || $opts->{Trunc} ? 1:0));
	$pdl->dump();
	return $pdl;
}
