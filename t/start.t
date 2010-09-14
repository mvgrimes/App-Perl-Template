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

$result = test_app( 'App::Perl::Template' => [qw(start)] );
like( $result->error, qr/Error: Module::Name required/, 'need module name' );

$result = test_app( 'App::Perl::Template' => [qw(start MyTest::Module)] );
like( $result->error, qr/Error: Abstract required/, '... need abstract' );

$result =
  test_app( 'App::Perl::Template' =>
      [ qw(start MyTest::Module --abstract), 'A test module for me' ] );
is( $result->error, undef, 'good start' );

$contents = $dir->subdir('mytest-module')->file('Build.PL')->slurp;
like( $contents, qr/license\s*=>\s'perl'/, '... good Build.PL license' );

$contents = $dir->file('mytest-module/lib/MyTest/Module.pm')->slurp;
like( $contents, qr/terms as the Perl 5 prog/, '... good module license' );
like( $contents, qr/# md5sum:\w+/,             '... inserted file md5sum' );
like( $contents, qr/=for perl-template md5sum:\w+/, '... inserted md5sums' );

done_testing;
