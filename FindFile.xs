#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <Windows.h>
#include <Winbase.h>

void convert_towchar( WCHAR * buf,  U8 *utf8,  STRLEN chars){
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
void convert_toutf8 ( U8 *utf8, WCHAR * wstr ){
    do {
	utf8 = uvchr_to_utf8( utf8, *wstr );
    }
    while( *wstr++ );
};


/*
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
    WCHAR XXX[ MAX_PATH * 4];
    PPCODE:
	dir_u8 = SvPV( dir, bytes);
	PerlIO_stdoutf( "Start=%d\n", 0);
	chars = utf8_length( dir_u8, dir_u8 + bytes );

	PerlIO_stdoutf( "len=%d\n", chars);
	WCHAR_SV = newSVpvn( 0,0);
	if (chars < MAX_PATH ){
    	    SvGROW( WCHAR_SV, MAX_PATH *sizeof(WCHAR));

	}
	else {
    	    SvGROW( WCHAR_SV, sizeof( WCHAR ) * ( chars  + 1 ));
	}
	sv_2mortal( WCHAR_SV );
	fprintf( stderr,  "len=%d\n", SvLEN( WCHAR_SV ));
	wbuff = ( WCHAR * ) SvPV_nolen( WCHAR_SV );
	
	convert_towchar( XXX , dir_u8, chars);
	
	hFile = FindFirstFileW( XXX, &data);
	
	exit(0);
	if ( hFile == INVALID_HANDLE_VALUE ){
	    croak( "No FindFirstFile found");
	    NULL;	        
	}
	else {
	    convert_toutf8( BIG_UTF8, data.cFileName); 
	    mXPUSHp( BIG_UTF8, strlen( BIG_UTF8 ));
	    while( FindNextFileW( hFile, &data) ){
		convert_toutf8( BIG_UTF8, data.cFileName); 
		mXPUSHp( BIG_UTF8, strlen( BIG_UTF8 ));
	    };
	    FindClose( hFile );
	}
	
*/
/*HMODULE WINAPI LoadLibrary(
	    LPCTSTR lpFileName
	);

void 
FindFile(SV* dir)
    PROTOTYPE: $
    INIT:
    WIN32_FIND_DATA data;
    HANDLE hFile;
    WCHAR * wbuff;
    U8  BIG_UTF8[ MAX_PATH * 3 ];
    U8  *dir_u8;
    SV * WCHAR_SV;
    STRLEN bytes;
    STRLEN chars;
    WCHAR XXX[ MAX_PATH * 4];

    PPCODE:
	

	hFile = FindFirstFile( "*", &data);
	
	if ( hFile == INVALID_HANDLE_VALUE ){
	    croak( "No FindFirstFile found");
	    NULL;	        
	}
	else {
	    fprintf( stderr, "%s\n", data.cFileName );
	    while( FindNextFile( hFile, &data) ){
		fprintf(stderr,  "%s\n", data.cFileName );
	    };
	    FindClose( hFile ); 
	}
*/

MODULE = Win32::FindFile		PACKAGE = Win32::FindFile		

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
    WCHAR XXX[ MAX_PATH * 4];
    PPCODE:
	dir_u8 = SvPV( dir, bytes);
	chars = utf8_length( dir_u8, dir_u8 + bytes );


	WCHAR_SV = newSVpvn( "", 0);
	if (chars < MAX_PATH ){
    	    SvGROW( WCHAR_SV, MAX_PATH *sizeof(WCHAR));
	}
	else {
    	    SvGROW( WCHAR_SV, sizeof( WCHAR ) * ( chars  + 1 ));
	}
	sv_2mortal( WCHAR_SV );
	wbuff = ( WCHAR * ) SvPV_nolen( WCHAR_SV );
	
	convert_towchar( XXX , dir_u8, chars);
	
	hFile = FindFirstFileW( XXX, &data);
	if ( hFile == INVALID_HANDLE_VALUE ){
	    croak( "FindFile: No Files found");
	    NULL;	        
	}
	else {
	    convert_toutf8( BIG_UTF8, data.cFileName); 
	    mXPUSHp( BIG_UTF8, strlen( BIG_UTF8 ));
	    while( FindNextFileW( hFile, &data) ){
		convert_toutf8( BIG_UTF8, data.cFileName); 
		mXPUSHp( BIG_UTF8, strlen( BIG_UTF8 ));
	    };
	    FindClose( hFile );
	}
	
