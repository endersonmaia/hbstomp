#include "stomp.ch"

CLASS TStompFrame

  DATA cCommand
  DATA aHeaders
  DATA cBody
  DATA aErrors
  DATA aStompFrameTypes
  DATA nSize

  // Validations
  METHOD validateCommand()
  METHOD validateHeader()
  METHOD validateBody()

  METHOD prsExCmd( cStompFrame )
  METHOD prsExHd( cStompFrame )
  METHOD prsExBd( cStompFrame )

  METHOD new() CONSTRUCTOR
  METHOD build(lCheck)
  METHOD parse( cStompFrame )
  METHOD getSize()

  // Content
  METHOD setCommand( cCommand )
  METHOD setBody( cBody )
  METHOD buildHeader( cName, cValue )
  METHOD addHeader( cName, cValue )
  METHOD removeAllHeaders()
  METHOD getHeaderValue( cHeaderName )

  METHOD isValid()
  METHOD headerExists( cHeaderName )
  METHOD countHeaders()

  METHOD addError()
  METHOD countErrors()

ENDCLASS

METHOD countHeaders() CLASS TStompFrame
  RETURN ( LEN( ::aHeaders ) )

METHOD countErrors() CLASS TStompFrame
  RETURN ( LEN( ::aErrors ) )

METHOD new() CLASS TStompFrame
  ::aHeaders := {}
  ::aErrors := {}
  ::cCommand := ""
  ::cBody := ""
  ::aStompFrameTypes := STOMP_COMMANDS
  RETURN ( SELF )

METHOD buildHeader( cName, cValue ) CLASS TStompFrame
  LOCAL aReturn := {}

  DO CASE
  CASE ( ValType( cName ) == "C" )
  CASE ( ValType( cName ) == "M" )
    BREAK
  OTHERWISE
    //Throw( ErrorNew( "EStompHeaderInvalidType",,, ProcName(), "Invalid type for StompHeader:Name." ) )
  END CASE

  DO CASE
  CASE ( ValType( cValue ) == "C" )
  CASE ( ValType( cValue ) == "M" )
    BREAK
  OTHERWISE
    //Throw( ErrorNew( "EStompHeaderInvalidType",,, ProcName(), "Invalid type for StompHeader:Value." ) )
  END CASE

  aReturn := { cName , cValue }

  RETURN( aReturn )

METHOD addHeader( cName, cValue ) CLASS TStompFrame
  AADD( ::aHeaders, ::buildHeader( cName, cValue ) )
  RETURN ( NIL )

METHOD addError( cError ) CLASS TStompFrame
  AADD( ::aErrors, cError )
  RETURN ( NIL )

METHOD setCommand( cCommand ) CLASS TStompFrame
  ::cCommand := UPPER(cCommand)
  RETURN ( NIL )

METHOD setBody( cBody ) CLASS TStompFrame
  ::cBody := cBody
  RETURN ( NIL )

METHOD removeAllHeaders() CLASS TStompFrame
  ::aHeaders := ARRAY(0)
  RETURN ( NIL )

METHOD validateCommand() CLASS TStompFrame
  LOCAL lReturn := .F.

  IF( ASCAN( ::aStompFrameTypes, { |c| UPPER(c) == UPPER( ::cCommand ) } ) > 0 )
    lReturn := .T.
  ELSE
    ::addError( "Invalid command : " + ::cCommand )
  ENDIF

  RETURN ( lReturn )

METHOD headerExists( cHeaderName ) CLASS TStompFrame
  LOCAL lReturn := .F.

  IIF ( ASCAN( ::aHeaders, { |h| h[1] == cHeaderName } ) > 0, lReturn := .T., )

  RETURN ( lReturn )

METHOD getHeaderValue( cHeaderName ) CLASS TStompFrame
  LOCAL uReturn := nil, i

  FOR i := 1 TO ::countHeaders()
    IIF ( (::aHeaders[i][1] == cHeaderName), uReturn := ::aHeaders[i][2],  )
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
    IIF ( ::headerExists(STOMP_DESTINATION_HEADER) .AND. ::headerExists(STOMP_ID_HEADER), lReturn := .T., )
    IIF ( lReturn == .T. .AND. ::headerExists(STOMP_ACK_HEADER) .AND. ASCAN( STOMP_ACK_MODES, ::getHeaderValue(STOMP_ACK_HEADER) ) = 0, lReturn := .F., )
  CASE ::cCommand == "UNSUBSCRIBE" .OR. ::cCommand == "ACK" .OR. ::cCommand == "NACK"
    IIF ( ::headerExists(STOMP_ID_HEADER), lReturn := .T., )
  CASE ::cCommand == "BEGIN" .OR. ::cCommand == "COMMIT" .OR. ::cCommand == "ABORT"
    IIF ( ::headerExists(STOMP_TRANSACTION_HEADER), lReturn := .T., )
  CASE ::cCOmmand == "MESSAGE"
    IIF ( ( ::headerExists( STOMP_DESTINATION_HEADER ) .AND. ::headerExists( STOMP_MESSAGE_ID_HEADER ) .AND. ::headerExists( STOMP_SUBSCRIPTION_HEADER ) ), lReturn := .T., )
  OTHERWISE
    lReturn := .T.
  ENDCASE

  IIF ( ( lReturn == .F. ), ::addError( "Missing required header for " + ::cCommand + " command." ), )

  RETURN ( lReturn )

METHOD validateBody() CLASS TStompFrame
  LOCAL lReturn := .F.

  DO CASE
  CASE  ::cCommand == "SEND" .OR. ::cCommand == "MESSAGE"
    IIF( ( !Empty(::cBody) ), lReturn := .T., )
  CASE        ::cCommand == "SUBSCRIBE"   ;
        .OR.  ::cCommand == "UNSUBSCRIBE" ;
        .OR.  ::cCommand == "BEGIN"       ;
        .OR.  ::cCommand == "COMMIT"      ;
        .OR.  ::cCommand == "ABORT"       ;
        .OR.  ::cCommand == "ACK"         ;
        .OR.  ::cCommand == "NACK"        ;
        .OR.  ::cCommand == "DISCONNECT"  ;
        .OR.  ::cCommand == "CONNECT"     ;
        .OR.  ::cCommand == "STOMP"       ;
        .OR.  ::cCommand == "ERROR"
    lReturn := .T.
  ENDCASE

  IIF ( ( lReturn == .F. ), ::addError( "Missing required body for this " + ::cCommand + " frame." ), )

  RETURN ( lReturn )

METHOD isValid() CLASS TStompFrame
  RETURN ( ::validateCommand() .AND. ::validateHeader() .AND. ::validateBody() )

METHOD build(lCheck) CLASS TStompFrame
  LOCAL cStompFrame := "", i

  IF !::isValid() .AND. lCheck == .T.
    RETURN ( .F. )
  ENDIF

  // build COMMAND
  cStompFrame += ::cCommand + CHR_CRLF

  // build HEADERS
  IF (::countHeaders() > 0)
    FOR i := 1 TO ::countHeaders()
      cStompFrame += ::aHeaders[i][1] + ":" + ::aHeaders[i][2]
      cStompFrame += CHR_CRLF
    NEXT
  ENDIF
  cStompFrame += CHR_CRLF

  // build BODY
  cStompFrame += ::cBody
  cStompFrame += CHR_NULL + CHR_CRLF

  ::nSize := LEN( cStompFrame )

  RETURN ( cStompFrame )

METHOD parse( cStompFrame ) CLASS TStompFrame
  LOCAL nLen          := 0 ,  ;
        nLastPos      := 0 ,  ;
        oStompFrame

  // Cleaning cStompFrame from CRLF to LF only
  cStompFrame := STRTRAN( cStompFrame, CHR_CRLF, CHR_LF )

  oStompFrame := TStompFrame():new()

  oStompFrame:cCommand  := ::prsExCmd( @cStompFrame )
  oStompFrame:aHeaders := ::prsExHd( @cStompFrame )
  oStompFrame:cBody     := ::prsExBd( @cStompFrame )

  RETURN ( oStompFrame )

METHOD prsExCmd( cStompFrame ) CLASS TStompFrame
  LOCAL nLen      := 0,   ;
        nLastPos  := 0,   ;
        cCommand  := ""

  nLen        := Len( cStompFrame )
  nLastPos    := At( CHR_LF, cStompFrame )
  cCommand    := SUBSTR( cStompFrame, 1, nLastPos - 1 )
  cStompFrame := SUBSTR( cStompFrame, nLastPos + 1, nLen )

  RETURN ( cCommand )

METHOD prsExHd( cStompFrame ) CLASS TStompFrame
  LOCAL nLen          := 0,   ;
        nLastPos      := 0,   ;
        cHeaders      := "",  ;
        cHeaderName   := "",  ;
        cHeaderValue  := "",  ;
        aHeaders      := {},  ;
        i             := 0

  nLen        := Len ( cStompFrame )
  nLastPos    := AT( CHR_LF+CHR_LF, cStompFrame )
  cHeaders    := SUBSTR( cStompFrame, 1, nLastPos)

  // extract header's name and value
  DO WHILE ( AT( ":", cHeaders ) > 0 )
    i++

    cHeaderName   := LEFT( cHeaders, AT( ":", cHeaders ) - 1 )
    cHeaderValue  := SUBSTR( cHeaders, AT( ":", cHeaders ) + 1, AT( CHR_LF, cHeaders) - AT( ":", cHeaders ) - 1)

    AADD( aHeaders, ::buildHeader( cHeaderName, cHeaderValue ) )

    cHeaders      := SUBSTR(  cHeaders, ;
                              Len( CHR_LF ) + Len( cHeaderName ) + Len( ":" ) + Len( cHeaderValue ) + Len( CHR_LF ), ;
                              nLen ;
                            )
  ENDDO

  cStompFrame := SUBSTR( cStompFrame, nLastPos + 2, nLen )

  RETURN ( aHeaders )

METHOD prsExBd( cStompFrame ) CLASS TStompFrame
  LOCAL nLen          := 0,   ;
        nLastPos      := 0

  nLen     := Len ( cStompFrame )
  nLastPos := AT( CHR_NULL+CHR_LF, cStompFrame )
  cBody    := LEFT( cStompFrame, nLastPos - 1)

  cStompFrame := SUBSTR( cStompFrame, nLastPos + 2 , nLen )

  RETURN ( cBody )

METHOD getSize() CLASS TStompFrame
  RETURN ( ::nSize )