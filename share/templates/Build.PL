use Module::Build;

my $build = Module::Build->new(
    module_name        => '[% v.namespace %]',
    license            => 'perl',
    create_readme      => 0,
    create_makefile_pl => 'passthrough',
    ## script_files	   =>  [qw( )],
    requires => {
        'perl'       => '5.008',
        'Carp'       => 0,
        'Test::Most' => 0,
        ## 'File::Basename'	=> 2.00,
    },
    recommends => { 'Test::Files' => 0, },
);

# $build->add_build_element('gif');
$build->create_build_script;

