#!/usr/bin/env perl

use strict;
use warnings;

use Template;
use File::Find;
use File::Path;
use File::Basename;
use File::Copy;
use File::Spec;

$|++;
use Data::Dump;
my $copy_re = qr/\.(png|gif|jpg|ico|pdf)$/;
my $src = File::Spec->catdir( $ENV{HOME}, '.pm-template', 'template' );
print "Template dir is $src\n";

my $namespace = shift || die "usage: $0 namespace\n";
my $new_dir = lc $namespace;
$new_dir =~ s/::/-/g;

die "target dir ($new_dir) already exists\n" if -e $new_dir;
print "creating new distribution directory: $new_dir\n";
mkdir $new_dir or die "couldn't make new module dir ($new_dir): $!\n";
my $pm_filename = "${namespace}.pm";
$pm_filename =~ s!::!/!g;

my @time = localtime(time);

package My::Template::ReadLine;

our $AUTOLOAD;

use Term::ReadLine;

my $term = new Term::ReadLine 'Input> ';

sub new {
    my $that  = shift;
    my $class = ref($that) || $that;    # Enables use to call $instance->new()
    my $self  = shift || {};
    bless $self, $class;
    return $self;
}

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self) or die "$self is not an object";

    my $name = $AUTOLOAD;
    $name =~ s/.*://;                   # Strip fully qualified portion

    # ensure none of these are DESTROY
    return if $name =~ /^DESTROY$/;

    # print "AUTOLOAD ($name)\n";

    # Return the value of the field, setting if an argument supplied
    return $self->{$name} if exists $self->{$name};

    my $v = $term->readline("Enter $name: ");
    $self->{$name} = $v;
    return $v;
}

1;

package main;

my $hash = My::Template::ReadLine->new( {
        name        => 'Mark Grimes',
        email       => 'mgrimes@cpan.org',
        year        => $time[5] + 1900,
        namespace   => $namespace,
        pm_filename => $pm_filename,
} );
my $vars = { v => $hash };

my $tt = Template->new( { INCLUDE_PATH => $src, } );

find( { wanted => \&wanted, no_chdir => 1 }, $src );

print <<CVS_DOC;
cd $new_dir
git init .
git add .
git commit -a
git-2-git add . 
CVS_DOC

sub wanted {
    my $f = $File::Find::name;

    return if $f eq $src;    # don't create the src dir
    my $n = $f;
    $n =~ s!$src/!!;
    my $d = "$new_dir/$n";

    # print "* $f ->\n\tn= $n\n\td= $d\n";

    if ( -d $f ) {
        if (m!/CVS$|/.svn$!) {    # don't create the CVS or svn dirs
            $File::Find::prune = 1;
            return;
        }
        print "creating new dir: $d = $_\n";
        mkpath $d or die "couldn't create directory ($d): $!\n";
        return;
    }

    if ( $f =~ $copy_re ) {
        print "copying file: $d\n";
        copy( $f, $d ) or die "error copying $f to $d: $!\n";
        return;
    }

    if ( $f =~ /NAMESPACE/ ) {
        my $ns = $namespace;
        $ns =~ s!::!/!g;
        $d  =~ s!NAMESPACE!$ns!;
    }

    print "processing $d\n";
    $tt->process( $n, $vars, $d ) || die $tt->error();
}

