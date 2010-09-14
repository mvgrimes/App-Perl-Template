use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;
use App::Perl::Template;
use Path::Class;

use File::Temp qw(tempdir);
my $dir = dir( tempdir( CLEANUP => 1 ) );
chdir $dir;
diag $dir;

my ( $result, $contents );

$result =
  test_app( 'App::Perl::Template' =>
      [ qw(start MyTest::Module --abstract), 'A test module for me' ] );
is( $result->error, undef, 'good start' );

# TODO: test when we run update outside of a distribution

# Change to the distdir and run the Build.PL to create a MYMETA.yml file
chdir $dir->subdir('mytest-module');
$result = qx{ perl Build.PL 2>&1 };
ok( -r file('MYMETA.yml'), '... Build.PL created MYMETA.yml' );

# Change the AUTHORs portion of the main module
$contents = file('lib/MyTest/Module.pm')->slurp or die;
my $fh = file('lib/MyTest/Module.pm')->openw() or die;
$contents =~ s{\bAUTHOR\b}{AUTHORS};
print $fh $contents;
$fh->close;

$result = test_app( 'App::Perl::Template' => [qw(update)] );
is( $result->error, undef, '... update w/o errors' );
like( $result->stdout, qr{processing: ./Build.PL}, '... update unchanged' );
like( $result->stdout, qr{Module.pm has been mod}, '... skip modified' );
like( $result->stdout, qr{not updating chunk aut}, '... not update chunk' );
like( $result->stdout, qr{updating chunk auth},    '... update chunk' );
is( $result->stderr, '',    '... no stderr output' );
is( $result->error,  undef, '... no errors' );

$contents = file('lib/MyTest/Module.pm')->slurp;
like( $contents, qr/updated asdf/, '... found updated chunk' );

# like( $contents, qr/# md5sum:\w+/, '... inserted file md5sum' );
# like( $contents, qr/=for perl-template md5sum:\w+/, '... inserted md5sums' );

done_testing;
