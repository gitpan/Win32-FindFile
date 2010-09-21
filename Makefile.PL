use Config;
use Data::Dumper;
unless ( $] >= 5.008000 ){
	print STDERR "Perl 5.8.0 required would not build\n";
	exit;
}

unless ( $ENV{FORCE} || $^O=~m/MSWin32/i) {
	print STDERR "Win32 required. Would not build\n";
	exit;
};

# ActivePerl && MinGW Fix
# It seems than with MinGW && AvtivePerl 
# is badly linking we are correcting this
BEGIN{
	if ($Config{ cc } =~m/\bgcc\b/ ){
		$ENV{ACTIVEPERL_CONFIG_libs} = '-lkernel32' ;
	};
};

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'Win32::FindFile',
    VERSION_FROM      => 'lib/Win32/FindFile.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Win32/FindFile.pm', # retrieve abstract from module
       AUTHOR         => 'A.G. Grishayev <gtoly@cpan.org>') : ()),
    LIBS              => [], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
