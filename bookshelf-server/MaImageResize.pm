package MaImageResize;
#
# $Id: Resize.pm,v 1.5 2005/11/04 23:44:59 sherzodr Exp $
#
use strict;
use Carp ('croak');
use GD;

$MaImageResize::VERSION = '0.5';

# Thanks to Paul Allen <paul.l.allen AT comcast.net> for this tip
GD::Image->trueColor( 1 );

sub new {
    #my ($class, $image) = @_;
    unless ( $class && defined($image) ) { croak "MaImageResize->new(): usage error"; }
    my $gd;

    # Thanks to Nicholas Venturella <nick2588 AT gmail.com> for this tip
    if (ref($image) eq "GD::Image") {
        $gd = $image;

    } else {
        unless ( -e $image ) { croak "MaImageResize->new(): file '$image' does not exist"; }
        $gd = GD::Image->new($image) or die $@;
    }

    return bless {
        gd => $gd
    }, $class;
}

sub width   { return ($_[0]->gd->getBounds)[0]; }
sub height  { return ($_[0]->gd->getBounds)[1]; }
sub gd      { return $_[0]->{gd}; }

sub resize {
    my $self = shift;
    my ($width, $height, $constraint) = @_;
    unless ( defined $constraint ) { $constraint = 1; }
    unless ( $width && $height ) { croak "MaImageResize->resize(): usage error"; }

    if ( $constraint ) {
        my $k_h = $height / $self->height;
        my $k_w = $width / $self->width;
        my $k = ($k_h < $k_w ? $k_h : $k_w);
        $height = int($self->height * $k);
        $width  = int($self->width * $k);
    }

    my $image = GD::Image->new($width, $height);
    $image->copyResampled($self->gd,
        0, 0,               # (destX, destY)
        0, 0,               # (srcX,  srxY )
        $width, $height,    # (destX, destY)
        $self->width, $self->height
    );
    return $image;
}


1;
__END__
