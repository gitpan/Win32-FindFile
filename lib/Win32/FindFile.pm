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
our %EXPORT_TAGS = ( 'all' => [ qw(
	FindFile 
	FileTime
	FileData
	wchar 
	uchar
	wfchar

	DeleteFile
	MoveFile
	CopyFile
	RemoveDirectory
	CreateDirectory

	GetFullPathName
	GetCurrentDirectory 
	SetCurrentDirectory 

	GetBinaryType
	GetCompressedFileSize
	GetFileAttributes
	SetFileAttributes
	GetLongPathName

	AreFileApisANSI
        SetFileApisToOEM
        SetFileApisToANSI
	) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	FindFile FileData FileTime	
);
use constant { 
    FileData => __PACKAGE__ . '::' .'_WFD',
    FileTime => __PACKAGE__ . '::' .'_WFT',};

our $VERSION = '0.13';

require XSLoader;
XSLoader::load('Win32::FindFile', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Win32::FindFile - simple unicode directory reader under Win32

=head1 SYNOPSIS

  use Win32::FindFile;
  use bytes;
  
  my @txt_files = FindFile( "*.txt" );
  my @dir_content = FindFile( "*" );

  # and finally
  # print entire directory content in unicode 
  #
  for ( @dir_content ){
	next unless $file->is_entry # skip over '.', '..'
	next if $file->is_hidden; # skip over hidden files
	next if $file->is_system; # etc

	next if $file->ftCreationTime   > time -10; # skip over files created recently
	next if $file->ftLastWriteTime  > time -10;
	next if $file->ftLastAccessTime > time -10; 

	next if $file->FileSize == 0; # 

	print $file, "\n"; # $file->cFileName
	print $file->dosName, "\n";

	my $s = $file->dwFileAttributes; # Get all attribytes
  };

  print "Current directory is ", GetCurrentDirectory(), "\n";



=head1 DESCRIPTION

	Win32::FindFile are simple tool for reading unicode dir content. It call kernel32.dll unicode functions
	FindFirstFileW, FindNextFileW, and covert UTF-16 to utf8 and back there is needed.

	Main Function is FindFile that take pattern of form '*' or '$directory\*' or more complex "$directory\*.txt"
	and return records from FileFileNextW as Class.

	Other function are utility functions as Copy, Move, GetCurrentDirectory, SetCurrentDirectory, ... etc.

=head2 EXPORT

=over 4

=item @content = FindFile( $Pattern )
    Find files matching pattern and returns them as list
    each record is blessed in FileFind::FindData class.

=item  utf8 =  GetCurrentDirectory()

    return CurrentDirectory as getcwd? but return value in utf8

=item SetCurrentDirectory( folder ) or die "Can't chdir to folder";

    Set current directory

=item GetFullPathName(file)
    Expand file name to absolute path

=item  $bool = AreFileApisANSI()
=item SetFileApisToOEM()
=item SetFileApisToANSI()
    If you know that is it you may do it
=item  DeleteFile( $file )
    Delete file. On success return true. Error description are at $^E
=item  CopyFile($from, $to, $fail_if_overwrite)
=item  MoveFile($from, $to)
=item  RemoveDirectory( $dir )
=item  CreateDirectory( $dir )

    copy, move, rmdir, mkdir. On success return 1. Errors at $^E

=item  GetBinaryType($file)
    See MSDN
=item  GetCompressedFileSize($file)
=item  GetFileAttributes($file)
=item  GetFileAttributes)$file, $attr)
=item  GetLongPathName(file)

=back

=cut
=head1 SEE ALSO

L<Win32>, L<Win32API>, L<Win32::UNICODE>

=head1 AUTHOR

A. G. Grishaev, E<lt>grian@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by A. G. Grishaev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
