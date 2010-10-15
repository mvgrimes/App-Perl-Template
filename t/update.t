use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;
use App::Perl::Template;
use Path::Class;

$ENV{APP_PERL_TEMPLATE_TESTING} = 1;

use File::Temp qw(tempdir);
my $dir = dir( tempdir( CLEANUP => 1 ) );
chdir $dir;
diag $dir;


my ( $result, $contents );

$result =
  test_app( 'App::Perl::Template' =>
      [ qw(start MyTest::Module --abstract), 'A test module for me' ] );
is( $result->error, undef, 'good start' );
is( $result->stderr, '', '... with no output on stderr' );

# TODO: test when we run update outside of a distribution

# Change to the distdir and run the Build.PL to create a MYMETA.yml file
chdir $dir->subdir('mytest-module');
$result = qx{ perl Build.PL 2>&1 };
ok( -r file('MYMETA.yml'), '... Build.PL created MYMETA.yml' );

# Change the AUTHORs portion of the main module
sub change_module {
    my $contents = file('lib/MyTest/Module.pm')->slurp or die;
    $contents =~ s{\b(AUTHORS*)\b}{$1S};
    my $fh = file('lib/MyTest/Module.pm')->openw() or die;
    print $fh $contents;
    $fh->close;
}

# Change the license in the MYMETA.yml file
do {
    $contents = file('Build.PL')->slurp or die;
    $contents =~ s{\blicense\s*=>\s*'perl'}{license => 'artistic_2'};
    my $fh = file('Build.PL')->openw() or die;
    print $fh $contents;
    $fh->close;
    $result = qx{ perl Build.PL 2>&1 };
    ok( -r file('MYMETA.yml'), '... Build.PL recreated MYMETA.yml' );
};

change_module();
$result = test_app( 'App::Perl::Template' => [qw(update)] );
is( $result->error, undef, 'update w/o errors' );
like( $result->stdout, qr{creating:  ./Changes},  '... update unchanged' );
like( $result->stdout, qr{Module.pm has been mod}, '... skip modified' );
like( $result->stdout, qr{not updating chunk =head1 A}, '... not update chunk' );
like( $result->stdout, qr{updating chunk =head1 C}, '... update lic chunk' );
is( $result->stderr, '',    '... no stderr output' );
is( $result->error,  undef, '... no errors' );
$contents = file('lib/MyTest/Module.pm')->slurp;
like( $contents, qr/Artistic License 2/, '... found updated chunk' );

change_module();
$result = test_app( 'App::Perl::Template' => [qw(update)] );
is( $result->error, undef, 'update again w/o errors' );
like( $result->stdout, qr{creating:  ./Changes},  '... update unchanged' );
like( $result->stdout, qr{Module.pm has been mod}, '... skip modified' );
like( $result->stdout, qr{updating chunk =head1 A}, '... update auth chunk' );
like( $result->stdout, qr{updating chunk =head1 C}, '... update lic chunk' );
is( $result->stderr, '',    '... no stderr output' );
is( $result->error,  undef, '... no errors' );

done_testing;
