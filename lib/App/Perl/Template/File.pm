package App::Perl::Template::File;

use Mouse;
use Method::Signatures::Simple;

use Path::Class;
use Template::Tiny;
use Digest::MD5 qw(md5_hex);

has src_path => ( is => 'ro', isa => 'Path::Class::File', required => 1 );
has dst_path => ( is => 'ro', isa => 'Path::Class::File', required => 1 );
has vars     => ( is => 'rw', isa => 'HashRef' );
has hash_template => ( is => 'ro', default => "# md5sum:%s\n" );

has original_contents => (
    is      => 'ro',
    isa     => 'Str',
    default => method { $self->src_path->slurp },
    lazy    => 1,
);

has template => (
    is      => 'ro',
    isa     => 'Template::Tiny',
    default => sub { Template::Tiny->new } );

method hash {
    ( my $no_empty_lines = $self->contents ) =~ s{^\*$}{};
    return md5_hex($no_empty_lines);
}

method create($vars) {
    $self->vars($vars);

    my $fh = $self->dst_path->openw() or die "Cannot creat file: $!";
    print $fh $self->contents_with_hash;
}

method contents_with_hash {
    return $self->contents . "\n" . sprintf $self->hash_template, $self->hash;
}

method update {
    return;
}

method contents {
    my $output = '';

    my $input = $self->original_contents;
    $self->template->process( \$input, { v => $self->vars }, \$output );
    return $output;
}

1;
