=head1 NAME

PDL::DataPresenter - present on-line or off-line data to algorithms

=head1 DESCRIPTION

Usually, the parameters are passed in a hash to another sub
which creates the datapresenter. E.g.

	$pca = new PDL::PCA($data,
		{
			DataDims => 2,
			DataSetDims => 3,
		}
	);

The default size to use is about 1Mb for each intermediate data
slice. It is possible to use e.g. lags in the first dimension.

XXX NOT DONE YET!

=cut

package PDL::DataPresenter;

sub new {
	my($type,$data,$opts,$uopts) = @_;
	my $this = {
		Data => $data,
		Opts => $opts
		UOpts => $uopts
	}
	bless $this,$type;
}

sub run {
	my($this) = @_;
}

