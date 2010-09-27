#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <Windows.h>//#include <Winbase.h>

typedef WCHAR * WFile;
typedef DWORD WINAPI (*GetLongPathName_t)(
	   WCHAR* ,
	   WCHAR* ,
	   DWORD 
	);


void convert_towchar( WCHAR * buf,  U8 *utf8,  STRLEN chars){
    UV value;
    STRLEN offset;
    

    do {
	if ( *utf8 < 128 ){
	    *buf++ = *utf8++;
	    chars--;
	}
	else {
	    value = utf8_to_uvchr( utf8, &offset );
	    *buf++= (WCHAR)value;
	    utf8+=offset;
	    chars--;
	}
    } while( chars > 0 && value !=0 );
    *buf = 0;
    
};
void convert_towchar_01( WCHAR * buf,  U8 *utf8,  STRLEN chars){
    UV value;
    STRLEN offset;
    

    do {
        value = utf8_to_uvchr( utf8, &offset );
	*buf++= (WCHAR)value;
	utf8+=offset;
	chars--;
	
    } while( chars > 0 && value !=0 );
    *buf = 0;
    
};
bool convert_toutf8_00 ( U8 *utf8, STRLEN bufsize, WCHAR * wstr ){
    //PerlIO_stdoutf( "==%d\n", (int) bufsize );
    do {
	U8 *old = utf8;
	utf8 = uvchr_to_utf8( utf8, *wstr );
	if (!*wstr ){
	    return 1;
	}
	bufsize-= utf8-old;
	++wstr;
	if (bufsize < UTF8_MAXBYTES + 1 )
	    return 0;
    }
    while( 1 );
};

bool convert_toutf8_02 ( U8 *, STRLEN, WCHAR *);
SV * mortal_utf8( WCHAR * X, int chars ){
    SV *sv;
    U8 *utf;
    STRLEN utf_len;
    STRLEN buffer;
    sv = sv_newmortal();
    sv_setpvn( sv, "", 0);

    SvGROW( sv, buffer = chars * (sizeof(WCHAR)) + 2);

    do {
	utf = (U8*) SvPVX( sv );
	utf_len = SvLEN( sv );
	if (convert_toutf8_02( utf, utf_len, X ) ){
	    SvCUR_set( sv, strlen( utf ));
	    return sv ;
	};
	buffer = utf_len + chars;
	SvGROW( sv , buffer );

    } while (1 );

}

bool convert_toutf8_01 ( U8 *utf8, STRLEN bufsize, WCHAR * wstr ){
    do {
	U8 *old = utf8;
	WCHAR wchr = *wstr;
	STRLEN offset;
	if ( wchr < 128 ){
	    *utf8++ = (U8) wchr;
	    bufsize--;
	    offset = 1;
	}
	else if ( wchr <0x800 ){
	    *utf8++ = (U8 ) ( (wchr >> 6) + 0xC0 );
	    *utf8++ = (U8 ) ( (wchr & 63) + 0x80 );
	    offset = 2;
	    bufsize-=2;
	}
	else {
	    croak( "Can't handle big Unicode Chars" );	    
	};

	if (!*wstr ){
	    return 1;
	}
	++wstr;
	if (bufsize < UTF8_MAXBYTES + 1 )
	    return 0;
    }
    while( 1 );
};

bool convert_toutf8_02 ( U8 *utf8, STRLEN bufsize, WCHAR * wstr ){
    do {
	U8 *old = utf8;
	WCHAR wchr = *wstr;
	STRLEN offset;
	if ( wchr < 128 ){
	    *utf8++ = (U8) wchr;
	    bufsize--;
	    offset = 1;
	}
	else if ( wchr <0x800 ){
	    *utf8++ = (U8 ) ( (wchr >> 6) + 0xC0 );
	    *utf8++ = (U8 ) ( (wchr & 63) + 0x80 );
	    offset = 2;
	    bufsize-=2;
	}
	else {
	    if ( wchr < 0xD800 || wchr > 0xDFFF ){ 
		*utf8++ = (U8 ) ( (wchr >> 12) + 0xE0 );
		*utf8++ = (U8 ) ( ( (wchr >> 6) & 63) + 0x80 );
		*utf8++ = (U8 ) ( (wchr & 63) + 0x80 );
		offset = 3;
		bufsize-=3;
	    }
	    else {
		croak( "No support for unicode surrogates" );
	    }
	}

	if (!*wstr ){
	    return 1;
	}
	++wstr;
	if (bufsize < 3 )
	    return 0;
    }
    while( 1 );
};

SV *mortal_wchar(SV *utf8){

    SV *WCHAR_SV;
    STRLEN chars;
    STRLEN bytes;
    U8 *str_u8;
    WCHAR *wbuff;
    // Get pointer && data length
    str_u8 = SvPV( utf8, bytes );
    chars = utf8_length( str_u8, str_u8 + bytes );
    WCHAR_SV = newSVpvn( "", 0);
    sv_2mortal( WCHAR_SV );
    if (chars >= MAX_PATH ){
	 SvGROW( WCHAR_SV, sizeof( WCHAR ) * ( chars  + 1 + 4));
    }
    else {
	SvGROW(  WCHAR_SV, sizeof( WCHAR ) * ( chars  + 1 ));
    }
    // It's no right ??? this is no support for surrogate so + zero byte at the end
    SvCUR_set( WCHAR_SV,  sizeof( WCHAR ) * ( chars  + 1));
    wbuff = ( WCHAR *) SvPVX( WCHAR_SV );
    convert_towchar_01( wbuff , str_u8, chars);
    return WCHAR_SV;
}

SV *normalize_path(SV *wpath ){
    STRLEN chars;
    STRLEN bytes;
    WCHAR *buffer;
    buffer = ( WCHAR * )SvPV( wpath, bytes );
    chars = (bytes >> 1) -1 ;
    if ( ( bytes & 1 ) || (buffer[ chars ])){
	PerlIO_stdoutf( "Not valid file come" );	
	chars = wcslen( buffer );
    };
    if (chars < MAX_PATH ){
	return wpath;
    }
    else {
	STRLEN k;
	if ( buffer[0] == '\\' && buffer[1] == '\\' && buffer[2] == '?' && buffer[3] == '\\' ){
	    return wpath;
	};
	// We need replace all '/' and make prefix \\?\
	//
	
	if (SvLEN(wpath) < (chars + 5) * sizeof(WCHAR) )
	    SvGROW( wpath, (chars + 5) * sizeof(WCHAR) );
	Move(  buffer, buffer +4 , chars +1, WCHAR);
	buffer[0] = '\\';
	buffer[1] = '\\';
	buffer[2] = '?';
	buffer[3] = '\\';
	for (k = 0; k < chars; ++k ){
	   if ( buffer[ k + 4 ] == '/' )
	       buffer[ k + 4 ] = '\\';

	};
	SvCUR_set(wpath, sizeof(WCHAR) * (chars + 5));
	return wpath;
    };
}

SV * WBool(bool obj){
    return obj ? &PL_sv_yes : &PL_sv_no ;
}

MODULE = Win32::FindFile		PACKAGE = Win32::FindFile		

void 
uchar2( SV * wstr_sv )
    PROTOTYPE: $;
    INIT:
    SV *UTF8_SV;
    STRLEN chars;
    STRLEN bytes;
    U8 *str_u8;
    WCHAR *wstr_ptr;
    STRLEN bufsize;
    PPCODE:
    wstr_ptr = ( WCHAR *) SvPV( wstr_sv, bytes );
    chars = wcslen( wstr_ptr );
    UTF8_SV = newSVpvn( "", 0);
    sv_2mortal( UTF8_SV );

    bufsize = chars * 2 + UTF8_MAXBYTES  + 1;
    //PerlIO_stdoutf( "=*=%d\n", (int) bufsize );
    do {
	SvGROW( UTF8_SV, bufsize );
	str_u8 = ( U8 *) SvPVX( UTF8_SV );
	if ( convert_toutf8_01( str_u8, SvLEN(UTF8_SV), wstr_ptr) )
    	    break;
	
	bufsize += chars *2;
    }
    while( 1) ;

    SvCUR_set( UTF8_SV,  strlen( str_u8 ));
    XPUSHs( UTF8_SV );

void 
uchar( SV * wstr_sv )
    PROTOTYPE: $;
    INIT:
    STRLEN chars;
    STRLEN bytes;
    WCHAR *wstr_ptr;
    PPCODE:
    wstr_ptr = ( WCHAR *) SvPV( wstr_sv, bytes );
    chars = wcslen( wstr_ptr );
    XPUSHs(mortal_utf8( wstr_ptr, chars ));

void
fromWCHAR( SV * wstr_sv )
    PROTOTYPE: $;
    INIT:
    SV *UTF8_SV;
    STRLEN chars;
    STRLEN bytes;
    U8 *str_u8;
    WCHAR *wstr_ptr;
    STRLEN bufsize;
    PPCODE:
    wstr_ptr = ( WCHAR *) SvPV( wstr_sv, bytes );
    chars = wcslen( wstr_ptr );
    UTF8_SV = newSVpvn( "", 0);
    sv_2mortal( UTF8_SV );

    bufsize = chars * 2 + UTF8_MAXBYTES  + 1;
    //PerlIO_stdoutf( "=*=%d\n", (int) bufsize );
    do {
	SvGROW( UTF8_SV, bufsize );
	str_u8 = ( U8 *) SvPVX( UTF8_SV );
	if ( convert_toutf8_02( str_u8, SvLEN(UTF8_SV), wstr_ptr) )
    	    break;
	
	bufsize += chars *2;
    }
    while( 1) ;

    SvCUR_set( UTF8_SV,  strlen( str_u8 ));
    XPUSHs( UTF8_SV );


void
wchar( SV * str )
    PPCODE:
    XPUSHs( mortal_wchar( str) );

void
toWCHAR( SV * str )
    PROTOTYPE: $;
    INIT:
    SV *WCHAR_SV;
    STRLEN chars;
    STRLEN bytes;
    U8 *str_u8;
    WCHAR *wbuff;
    PPCODE:
    str_u8 = SvPV( str, bytes );
    chars = utf8_length( str_u8, str_u8 + bytes );
    WCHAR_SV = newSVpvn( "", 0);
    sv_2mortal( WCHAR_SV );
    SvGROW( WCHAR_SV, sizeof( WCHAR ) * ( chars  + 1));
    SvCUR_set( WCHAR_SV,  sizeof( WCHAR ) * ( chars  + 1));
    wbuff = ( WCHAR *) SvPVX( WCHAR_SV );
    convert_towchar_01( wbuff , str_u8, chars);
    XPUSHs( WCHAR_SV );




void 
wfchar( SV * str)
    PPCODE:
    XPUSHs( normalize_path( mortal_wchar( str )));


# /* File functions */

void 
FindFile(SV* dir)
    PROTOTYPE: $
    INIT:
    WIN32_FIND_DATAW data;
    HANDLE hFile;
    WCHAR * wbuff;
    U8  BIG_UTF8[ MAX_PATH * 3 ];
    U8  *dir_u8;
    SV * WCHAR_SV;
    STRLEN bytes;
    STRLEN chars;
    PPCODE:
	dir_u8 = SvPV( dir, bytes);
	chars = utf8_length( dir_u8, dir_u8 + bytes );


	WCHAR_SV = newSVpvn( "", 0);
	sv_2mortal( WCHAR_SV );
	SvGROW( WCHAR_SV, sizeof( WCHAR ) * ( chars  + 1 ));
	wbuff = ( WCHAR * ) SvPV_nolen( WCHAR_SV );
	
	convert_towchar_01( wbuff , dir_u8, chars);
	
	hFile = FindFirstFileW( wbuff, &data);
	if ( hFile == INVALID_HANDLE_VALUE ){
	    croak( "FindFile: No Files found");
	    NULL;	        
	}
	else {
	    (void)convert_toutf8_02( BIG_UTF8, sizeof( BIG_UTF8 ),data.cFileName); 
	    mXPUSHp( BIG_UTF8, strlen( BIG_UTF8 ));
	    while( FindNextFileW( hFile, &data) ){
		convert_toutf8_02( BIG_UTF8, sizeof( BIG_UTF8 ), data.cFileName); 
		mXPUSHp( BIG_UTF8, strlen( BIG_UTF8 ));
	    };
	    FindClose( hFile );
	}
	

void 
AreFileApisANSI()
    PPCODE:
	XPUSHs( WBool( AreFileApisANSI() ));



void 
DeleteFile(WFile file)
    PPCODE:
	XPUSHs( WBool(DeleteFileW( file )));


void 
GetBinaryType(WFile file)
    PREINIT:
    DWORD BinaryType;
    PPCODE:
    if ( GetBinaryTypeW( file, & BinaryType ) ){
	mXPUSHi( BinaryType );	
    }
    else {
	XPUSHs( &PL_sv_undef );
    }

void 
GetCompressedFileSize(WFile file)
    PREINIT:
    DWORD FileSize1;
    //DWORD FileSize2;
    PPCODE:
    if ( ( FileSize1 = GetCompressedFileSizeW( file, NULL )) != INVALID_FILE_SIZE ){
        mXPUSHi( FileSize1 );
    }
    else {
        XPUSHs( &PL_sv_undef );
    }

void
GetFileAttributes( WFile file)
    PREINIT:reFileApisANSI
    DWORD FileAttributes;
    PPCODE:
    if ( ( FileAttributes = GetFileAttributesW( file )) != INVALID_FILE_ATTRIBUTES ){
	mXPUSHi( FileAttributes );
    }
    else {
	XPUSHs( &PL_sv_undef );
    }

void 
RemoveDirectory( WFile file )
    PPCODE:
    XPUSHs(WBool( RemoveDirectoryW( file )));

void 
CreateDirectory( WFile file )
    PPCODE:
    XPUSHs(WBool( CreateDirectoryW( file, NULL )));

void 
SetCurrentDirectory( WFile file )
    PPCODE:
    XPUSHs(WBool( SetCurrentDirectoryW( file )));

void
SetFileAttributes( WFile file, int FileAttributes)
    PPCODE:
    XPUSHs( WBool( SetFileAttributesW( file, FileAttributes )));

void MoveFile( WFile file1, WFile file2 )
    PPCODE:
    mXPUSHs( WBool( MoveFileW( file1, file2 )));


void CopyFile( WFile file1, WFile file2, int FailIfExists )
    PPCODE:
    mXPUSHs( WBool( CopyFileW( file1, file2, FailIfExists )));



void GetCurrentDirectory( WFile file )
    PREINIT:
    long length;
    SV *buffer;
    PPCODE:
	length = GetCurrentDirectoryW( 0 , NULL);
	if ( length != 0){
	    buffer= sv_newmortal();
	    sv_setpvn( buffer, "", 0);
	    SvGROW( buffer, (sizeof( WCHAR) * length ));
	    
	    length = GetCurrentDirectoryW( SvLEN(buffer)/2, (WCHAR *)SvPV_nolen( buffer ));	    
	    if ( length != 0){
		XPUSHs( mortal_utf8( (WCHAR *)SvPVX(buffer), length ));
	    }
	    else {
		XPUSHs( &PL_sv_undef );
	    };
	} else {
	    XPUSHs( &PL_sv_undef );
	}

void
GetFullPathName( WFile file )
    PREINIT:
    long length;
    SV *buffer;
    PPCODE:
	length = GetFullPathNameW( file, 0 , NULL, NULL);
	if ( length != 0){
	    buffer= sv_newmortal();
	    sv_setpvn( buffer, "", 0);
	    SvGROW( buffer, (sizeof( WCHAR) * length ));
	    
	    length = GetFullPathNameW( file, SvLEN(buffer)/2, (WCHAR *)SvPV_nolen( buffer ), NULL);	    
	    if ( length != 0){
		XPUSHs( mortal_utf8( (WCHAR *)SvPVX(buffer), length ));
	    }
	    else {
		XPUSHs( &PL_sv_undef );
	    };
	} else {
	    XPUSHs( &PL_sv_undef );
	}


void GetLongPathName( WFile file )
    PREINIT:
    long length;
    SV *buffer;
    HMODULE Kernel;
    GetLongPathName_t Func;
    PPCODE:
	Kernel= LoadLibrary( "Kernel32.dll" );
	if ( Kernel == NULL )
	    croak( "Unable load Kernel32.dll" );
	Func = ( GetLongPathName_t )GetProcAddress( Kernel, "GetLongPathNameW" );
	if ( Func == NULL ){
	    FreeLibrary( Kernel );
	    croak( "Unable get function GetLongPathNameW" );
	};

	length = Func( file, NULL, 0);
	if ( length != 0){
	    buffer= sv_newmortal();
	    sv_setpvn( buffer, "", 0);
	    SvGROW( buffer, (sizeof( WCHAR) * length ));
	    
	    length = Func( file, (WCHAR *)SvPV_nolen( buffer ), SvLEN(buffer)/2);	    
	    if ( length != 0){
		XPUSHs( mortal_utf8( (WCHAR *)SvPVX(buffer), length ));
	    }
	    else {
		XPUSHs( &PL_sv_undef );
	    };
	} else {
	    XPUSHs( &PL_sv_undef );
	}
	FreeLibrary( Kernel );


PROTOTYPES: DISABLE;

void
Output( SV *sv )
    INIT:
    STRLEN size;
    U8    *ptr;
    PPCODE:	
	ptr = SvPV( sv, size );
	PerlIO_stdoutf( "%.*s", size, ptr);



    
