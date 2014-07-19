#include "stomp.ch"

CLASS TStompFrame

  DATA cCommand INIT "" READONLY
  DATA aHeaders INIT {} READONLY
  DATA cBody INIT "" READONLY

  CLASSDATA aStompFrameTypes INIT { "SEND", "SUBSCRIBE", "UNSUBSCRIBE", "BEGIN", "COMMIT", "ABORT", "ACK", "NACK", "DISCONNECT", "CONNECT", "STOMP" }

  HIDDEN:
  // Validations
  METHOD validateCommand()
  METHOD validateHeader()
  METHOD validateBody()

  #ifdef __PROTHEUS__
    #xtranslate parseExtractCommand( <x> ) => parseEC( <x> )
    #xtranslate parseExtractHeaders( <x> ) => parseEH( <x> )
    #xtranslate parseExtractBody( <x> ) => parseEB( <x> )
  #endif
  METHOD parseExtractCommand( cStompFrame )
  METHOD parseExtractHeaders( cStompFrame )
  METHOD parseExtractBody( cStompFrame )

  EXPORTED:
  METHOD new() CONSTRUCTOR
  METHOD build()
  METHOD parse( cStompFrame )

  // Content
  METHOD setCommand( cCommand )
  METHOD setBody( cBody )
  METHOD addHeader( oStompFrameHeader )
  METHOD removeAllHeaders()
  METHOD getHeaderValue( cHeaderName )

  METHOD isValid()
  METHOD headerExists( cHeaderName )
  METHOD countHeaders()

ENDCLASS

METHOD countHeaders() CLASS TStompFrame
  RETURN ( LEN( ::aHeaders ) )

METHOD new() CLASS TStompFrame
  RETURN SELF

METHOD addHeader ( oStompFrameHeader ) CLASS TStompFrame
  AADD( ::aHeaders, oStompFrameHeader )
  RETURN ( NIL )

METHOD setCommand( cCommand ) CLASS TStompFrame

  ::cCommand := UPPER(cCommand)

  RETURN ( NIL )

METHOD setBody( cBody ) CLASS TStompFrame

  ::cBody := cBody

  RETURN ( NIL )

METHOD removeAllHeaders() CLASS TStompFrame
  ::aHeaders := ARRAY(0)
  RETURN ( nil )

METHOD validateCommand() CLASS TStompFrame
  LOCAL lReturn := .F.

  IIF ( ASCAN( ::aStompFrameTypes, { |c| UPPER(c) == UPPER(::cCommand()) } ) > 0, lReturn := .T., )

  RETURN ( lReturn )

METHOD headerExists( cHeaderName ) CLASS TStompFrame
  LOCAL lReturn := .F.

  IIF ( ASCAN( ::aHeaders, { |h| h:cName == cHeaderName } ) > 0, lReturn := .T., )

  RETURN ( lReturn )

METHOD getHeaderValue( cHeaderName ) CLASS TStompFrame
  LOCAL uReturn := nil

  FOR i := 1 TO ::countHeaders()
    IIF ( (::aHeaders[i]:cName == cHeaderName), uReturn := ::aHeaders[i]:cValue,  )
  NEXT
  RETURN ( uReturn )

METHOD validateHeader() CLASS TStompFrame
  LOCAL lReturn := .F.

  DO CASE

  CASE ::cCommand == "CONNECT" .OR. ::cCommand == "STOMP"
    IIF ( ( ::headerExists(STOMP_ACCEPT_VERSION_HEADER) .AND. ::headerExists(STOMP_HOST_HEADER) ), lReturn := .T., )
  CASE ::cCommand == "SEND"
    IIF ( ::headerExists(STOMP_DESTINATION_HEADER), lReturn := .T., )
  CASE ::cCommand == "SUBSCRIBE"
    IIF ( ( ::headerExists(STOMP_DESTINATION_HEADER) .AND. ::headerExists(STOMP_ID_HEADER) ), lReturn := .T., )
  CASE ::cCommand == "UNSUBSCRIBE" .OR. ::cCommand == "ACK" .OR. ::cCommand == "NACK"
    IIF ( ::headerExists(STOMP_ID_HEADER), lReturn := .T., )
  CASE ::cCommand == "BEGIN" .OR. ::cCommand == "COMMIT" .OR. ::cCommand == "ABORT"
    IIF ( ::headerExists(STOMP_TRANSACTION_HEADER), lReturn := .T., )
  CASE ::cCommand == "DISCONNECT"
    lReturn := .T.
  ENDCASE

  RETURN ( lReturn )

METHOD validateBody() CLASS TStompFrame
  LOCAL lReturn := .F.

  DO CASE  
  CASE  ::cCommand == "SEND"
    lReturn := .T.
  CASE        ::cCommand == "SUBSCRIBE"   ;
        .OR.  ::cCommand == "UNSUBSCRIBE" ;
        .OR.  ::cCommand == "BEGIN"       ;
        .OR.  ::cCommand == "COMMIT"      ;
        .OR.  ::cCommand == "ABORT"       ;
        .OR.  ::cCommand == "ACK"         ;
        .OR.  ::cCommand == "NACK"        ;
        .OR.  ::cCommand == "DISCONNECT"  ;
        .OR.  ::cCommand == "CONNECT"     ;
        .OR.  ::cCommand == "STOMP"
    IIF( ( Empty(::cBody) ), lReturn := .T., )
  ENDCASE

  RETURN ( lReturn )

METHOD isValid() CLASS TStompFrame
  LOCAL lReturn := .F.

  lReturn := ::validateCommand() .AND. ::validateHeader() .AND. ::validateBody()

  RETURN ( lReturn )


METHOD build() CLASS TStompFrame
  LOCAL cStompFrame := "", i

  IF !::isValid()
    RETURN ( .F. )
  ENDIF

  // build COMMAND
  cStompFrame += ::cCommand + CHR_CRLF

  // build HEADERS
  FOR i := 1 TO ::countHeaders()
    cStompFrame += ::aHeaders[i]:cName + ':' + ::aHeaders[i]:cValue
    cStompFrame += CHR_CRLF
  NEXT
  cStompFrame += CHR_CRLF

  // build BODY
  cStompFrame += ::cBody
  cStompFrame += CHR_NULL + CHR_CRLF

  RETURN ( cStompFrame )

METHOD parse( cStompFrame ) CLASS TStompFrame
  LOCAL nLen          := 0,   ;
        nLastPos      := 0,   ; 
        cHeader       := "",  ; 
        cHeaderName   := "",  ; 
        cHeaderValue  := "",  ;
        oHeader

  // Cleaning cStompFrame from CRLF to LF only
  cStompFrame := STRTRAN( cStompFrame, CHR_CRLF, CHR_LF )

  ::cCommand  := ::parseExtractCommand( @cStompFrame )
  IIF ( ( ::cCommand != "ERROR" ), ::aHeaders := ::parseExtractHeaders( @cStompFrame ), )
  ::cBody     := ::parseExtractBody( @cStompFrame )

  RETURN ( SELF )

METHOD parseExtractCommand( cStompFrame ) CLASS TStompFrame
  LOCAL nLen      := 0,   ;
        nLastPos  := 0,   ; 
        cCommand  := ""

  nLen        := Len( cStompFrame )
  nLastPos    := At( CHR_LF, cStompFrame )
  cCommand    := SUBSTR( cStompFrame, 1, nLastPos - 1 )
  cStompFrame := SUBSTR( cStompFrame, nLastPos + 1, nLen )

  RETURN ( cCommand )

METHOD parseExtractHeaders( cStompFrame ) CLASS TStompFrame
  LOCAL nLen          := 0,   ;
        nLastPos      := 0,   ;
        cHeaders      := "",  ;
        cHeaderName   := "",  ;
        cHeaderValue  := "",  ;
        aHeaders      := {},  ;
        i             := 0,   ;
        oHeader

  nLen        := Len ( cStompFrame )
  nLastPos    := Rat( CHR_LF+CHR_LF, cStompFrame )
  cHeaders    := SUBSTR( cStompFrame, 1, nLastPos)

  // extract header's name and value
  DO WHILE ( AT( ":", cHeaders ) > 0 )
    i++

    cHeaderName   := LEFT( cHeaders, AT( ":", cHeaders ) - 1 )
    cHeaderValue  := SUBSTR( cHeaders, AT( ":", cHeaders ) + 1, AT( CHR_LF, cHeaders) - AT( ":", cHeaders ) - 1)

    AADD( aHeaders, TStompFrameHeader():new( cHeaderName, cHeaderValue ) )

    cHeaders      := SUBSTR(  cHeaders, ;
                              Len( CHR_LF ) + Len( cHeaderName ) + Len( ":" ) + Len( cHeaderValue ) + Len( CHR_LF ), ;
                              nLen ;
                            )
  ENDDO

  cStompFrame := SUBSTR( cStompFrame, nLastPos + 2, nLen )

  RETURN ( aHeaders )

METHOD parseExtractBody( cStompFrame ) CLASS TStompFrame
  LOCAL nLen          := 0,   ;
        nLastPos      := 0

  nLen     := Len ( cStompFrame )
  nLastPos := Rat( CHR_NULL+CHR_LF, cStompFrame )
  cBody    := LEFT( cStompFrame, nLastPos - 1)

  RETURN ( cBody )