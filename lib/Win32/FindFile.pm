package Win32::FindFile;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32::FindFile ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(FindFile GetCurrentDirectory Output wchar uchar) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	FindFile 	
);

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Win32::FindFile', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Win32::FindFile - Perl extension for calling win32 FindFirstFileW/FindNextFileW  ( or FindFirstFile FindNextFile )

=head1 SYNOPSIS

  use Win32::FindFile;
  
  my @txt_files = FindFile( "*.txt" );
  my @dir_content = FindFile( "*" );

  # and finally
  # print entire directory content in unicode 
  #
  binmode( STDOUT, ":utf8" );
  for ( @dir_content ){
	  utf8::decode( $_ );
	  print $_, "\n";
  };
  print "Current directory is ", GetCurrentDirectory(), "\n";

# Using with Win32API::File

  use Win32::FindFile qw(wchar GetCurrentDirectory);
  use Win32API::File qw(MoveFileW);
  use Win32::API ;

  my %rename ( ... )
  for (FindFile( '*' )){
	next unless $rename{$_}:
	MoveFileW( wchar( $_ ), wchar( $rename{$_} ) or die "$^E";

  }



=head1 DESCRIPTION

	Win32::FindFile are simple wrapper around win32 functions FindFileFirst/FindFileNext

=head2 EXPORT

@content = FindFile( $Pattern )

$directory = GetCurrentDirectory();

=head1 SEE ALSO

L<Win32>, L<Win32API>(CopyFile, DeleteFile, MoveFile)

=head1 AUTHOR

A. G. Grishaev, E<lt>grian@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by A. G. Grishaev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
