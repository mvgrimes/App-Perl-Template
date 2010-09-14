use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;
use App::Perl::Template;
use Path::Class;

use File::Temp qw(tempdir);
my $dir = dir( tempdir( CLEANUP => 0 ) );
chdir $dir;
diag $dir;

my ( $result, $contents );

$result =
  test_app( 'App::Perl::Template' =>
      [ qw(start MyTest::Module --abstract), 'A test module for me' ] );
is( $result->error, undef, 'good start' );

# TODO: test when we run update outside of a distribution

chdir $dir->subdir('mytest-module');
$result = qx{ perl Build.PL 2>&1 };
ok( -r file('MYMETA.yml'), '... Build.PL created MYMETA.yml' );

my $fh = file('lib/MyTest/Module.pm')->open('a');
print $fh "# an added comment\n";
$fh->close;

$result = test_app( 'App::Perl::Template' => [qw(update)] );
is( $result->error, undef, '... update w/o errors' );
like( $result->stdout, qr{processing: ./Build.PL}, '... update unchanged' );
like( $result->stdout, qr{Module.pm has been mod}, '... skip modified' );
is( $result->stderr, '',    '... no stderr output' );
is( $result->error,  undef, '... no errors' );

# $contents = $dir->file('mytest-module/lib/MyTest/Module.pm')->slurp;
# like( $contents, qr/terms as the Perl 5 prog/, '... good module license' );
# like( $contents, qr/# md5sum:\w+/,             '... inserted file md5sum' );
# like( $contents, qr/=for perl-template md5sum:\w+/, '... inserted md5sums' );

done_testing;
