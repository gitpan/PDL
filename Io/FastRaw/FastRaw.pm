=head1 NAME

PDL::Io::FastRaw -- A simple, fast and convenient io format for PerlDL.

=head1 SYNOPSIS

	use PDL;
	use PDL::Io::FastRaw;

	writefraw($pdl,"fname");

	$pdl2 = readfraw("fname");

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

@PDL::Io::FastRaw::ISA = qw/Exporter/;

@EXPORT = qw/writefraw readfraw/;

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
	my $hname = "$name.hdr";
	my $h = new FileHandle "$hname"
	 or croak "Couldn't open '$hname' for writing";
	my $d = new FileHandle "$name"
	 or croak "Couldn't open '$name' for writing";
	my $tid = <$h>;
	my $ndims = <$h>;
	my $str = <$h>; if(!defined $str) {croak("Format error in '$hname'");}
	my @dims = split ' ',$str;
	if($#dims != $ndims-1) {
		croak("Format error reading fraw header file '$hname'");
	}
	my $pdl = PDL->zeroes ((new PDL::Type($tid)), @dims);
	my $len = length ${$pdl->get_dataref};
	$d->sysread(${$pdl->get_dataref},$len) == $len
	  or croak "Couldn't read enough data from '$name'";
	return $pdl;
}
