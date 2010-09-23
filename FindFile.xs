#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <Windows.h>//#include <Winbase.h>
#include <strings.h>

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
    WCHAR *wbuff;
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
    SV *UTF8_SV;
    STRLEN chars;
    STRLEN bytes;
    U8 *str_u8;
    WCHAR *wstr_ptr;
    WCHAR *wbuff;
    STRLEN bufsize;
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
    WCHAR *wbuff;
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
GetCurrentDirectory()
    PROTOTYPE: 
    INIT:
    WCHAR  *wbuff;
    WCHAR  wbuff_stack[ MAX_PATH ];
    U8  *dir_u8;
    SV * WCHAR_SV;
    STRLEN bytes;
    STRLEN chars;
    int path_size;
    PPCODE:
	wbuff = wbuff_stack;
	path_size = GetCurrentDirectoryW( MAX_PATH, wbuff);
	
	if ( MAX_PATH == path_size ){
	    // Too small buffer;
	    SV *tmp;

	    STRLEN tmp_len;
	    tmp_len = MAX_PATH;
	    tmp = sv_newmortal();
	    sv_setpvn( tmp, "", 0);
	    do {
		tmp_len *= 2;
		SvGROW( tmp, tmp_len * sizeof( WCHAR ));
	        path_size = GetCurrentDirectoryW( tmp_len, (WCHAR *) SvPVX( tmp ));
	    }
	    while( path_size == tmp_len && tmp_len <= 16 * MAX_PATH );
	    wbuff = (WCHAR *) SvPVX( tmp );
	    if ( path_size == tmp_len ){
		croak( "Current path too large" );
	    };

	};
	if ( 0 != path_size ){
    	    chars = path_size;
	    PerlIO_stdoutf( "=%d\n", chars );
	    XPUSHs( mortal_utf8( wbuff, chars ));
	}
	else {
	    croak( "GetCurrentDirectoryW failed\n" );
	    XPUSHs( &PL_sv_undef );
	}

PROTOTYPES: DISABLE;

void
Output( SV *sv )
    INIT:
    STRLEN size;
    U8    *ptr;
    PPCODE:	
	ptr = SvPV( sv, size );
	PerlIO_stdoutf( "%.*s", size, ptr);



    
