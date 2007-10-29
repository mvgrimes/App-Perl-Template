use Module::Build;
my $build = Module::Build->new(
	module_name				=> '[% v.namespace %]',
	license					=> 'perl',
	# dist_version_from		=> '[% v.pm_filename %]',
	# dist_name				=> 'name',
	# script_files			=>  [qw( )],
	create_readme			=>  1,
    create_makefile_pl      => 'passthrough',
	requires				=> {
			'perl'				=> '5.008',
			'Carp'				=> 0,
			'Hash::Util'		=> 0.05,
			# 'File::Basename'	=> 2.00,
		},
	recommends				=> {
			'Test::Files'		=> 0,
		},
);

# $build->add_build_element('gif');
$build->create_build_script;


