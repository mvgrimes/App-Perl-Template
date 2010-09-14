use Module::Build;

my $build = Module::Build->new(
    module_name   => '[% namespace %]',
    license       => 'perl',
    create_readme => 0,
    ## script_files	   =>  [qw( )],
    requires => {
        'perl'       => '5.008',
        'Carp'       => 0,
        'Test::Most' => 0,
        ## 'File::Basename'	=> 2.00,
    },
    config_requires => { 'Module::Build' => '0.36', },
    recommends      => { 'Test::Files'   => 0, },
);

# $build->add_build_element('gif');
$build->create_build_script;

