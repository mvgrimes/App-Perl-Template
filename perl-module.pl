#!/usr/bin/perl

use strict;
use warnings;
$|++;

use Template;
use File::Find;
use File::Path;
use File::Basename;
use File::Copy;
use FindBin;

my $copy_re = qr/\.(png|gif|jpg|ico|pdf)$/;
my $src  	= $FindBin::Bin,

my $namespace = shift || usage();
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
	my $self = shift || {};
	bless $self, $class;
	return $self;
}

sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) or die "$self is not an object";

	my $name = $AUTOLOAD;
	$name =~ s/.*://;           # Strip fully qualified portion

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
		name	=> 'Mark V. Grimes',
		email	=> 'mgrimes@cpan.org',
		year	=> $time[5] + 1900,
		namespace => $namespace,
		pm_filename => $pm_filename,
	} );
my $vars = { v => $hash };

my $tt = Template->new( {
		INCLUDE_PATH	=> $src,
	});

find( { wanted => \&wanted, no_chdir => 1 }, $src );

print <<CVS_DOC;
Now you should enter into cvs:

cd $new_dir
cvs import -m "Initial import" Perl/$new_dir mgrimes $new_dir-0-1
cd ..

cvs checkout CVSROOT/modules
cd CVSROOT
echo "$new_dir -d $new_dir Perl/$new_dir" >> modules
cvs commit -m "Added the $new_dir perl module"
cd ..
cvs release -d CVSROOT

mv $new_dir $new_dir.org
cvs checkout $new_dir

OR INTO SUBVERSION:

cd $new_dir
svn import svn+ssh://grimes.homeip.net/var/svn/mgrimes/dev/trunk/$new_dir
cd .. && mv $new_dir $new_dir.org
svn co svn+ssh://grimes.homeip.net/var/svn/mgrimes/dev/trunk/$new_dir

** All done.
CVS_DOC

sub wanted { 
	my $f = $File::Find::name;

	return if $f eq $src;		# don't create the src dir
	my $n = $f; $n =~ s!$src/!!;
	my $d = "$new_dir/$n";
	
	# print "* $f ->\n\tn= $n\n\td= $d\n";

	if( -d $f ){
		if( m!/CVS$|/.svn$! ){	# don't create the CVS or svn dirs
			$File::Find::prune = 1;
			return;
		}
		print "creating new dir: $d = $_\n";
		mkpath $d or die "couldn't create directory ($d): $!\n";
		return;
	}

	if( $f =~ $copy_re ){
		print "copying file: $d\n";
		copy($f,$d) or die "error copying $f to $d: $!\n";
		return;
	}

	if( $f =~ /NAMESPACE/ ){
		my $ns = $namespace;
		$ns =~ s!::!/!g;
		$d  =~ s!NAMESPACE!$ns!;
	}

	print "processing $d\n";
	$tt->process($n, $vars, $d) || die $tt->error();
}

sub usage {

print <<END;
usage: $0 namespace
END

exit;
}
