package PDL::TriD::OOGL;

$PDL::TriD::create_window_sub = sub {
	return new PDL::TriD::OOGL::Window;
};


package PDL::TriD::Object;
use OpenGL;

sub tooogl {
	my($this) = @_;
	join "\n",map { $_->togl() } (@{$this->{Objects}}) 
}

package PDL::TriD::GL::Window;
use FileHandle;

sub new {my($type) = @_;
	my($this) = bless {},$type;
}

sub update_list {
	my($this) = @_;
	my $fh = new FileHandle("|togeomview");
	my $str = join "\n",map {$_->tooogl()} (@{$this->{Objects}}) ;
	print $str;
	$fh->print($str);
}

sub twiddle {
}
