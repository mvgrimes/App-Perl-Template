use Module::Build;

my $build = Module::Build->new(
    module_name   => 'App::Perl::Template',
    license       => 'perl',
    create_readme => 1,
    script_files  => [qw( script/perl-template)],
    requires      => {
        'perl'                       => '5.008',
        'Test::Most'                 => 0,
        'Test::Differences'          => 0,
        'App::Cmd::Setup'            => 0,
        'Config::General'            => 0,
        'DateTime'                   => 0,
        'Digest::MD5'                => 0,
        'FindBin'                    => 0,
        'File::Basename'             => 0,
        'File::Copy'                 => 0,
        'File::Find::Rule'           => 0,
        'File::HomeDir'              => 0,
        'File::Path'                 => 0,
        'File::ShareDir'             => 0,
        'File::Spec'                 => 0,
        'Method::Signatures::Simple' => 0,
        'Mouse'                      => 0,
        'Path::Class'                => 0,
        'Template::Tiny'             => 0,
        'YAML'                       => 0,
    },
    config_requires => { 'Module::Build' => '0.36', },
);

$build->create_build_script;
