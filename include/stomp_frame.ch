#ifndef _STOMP_FRAME_CH
#define _STOMP_FRAME_CH

// ASCII CHARACTERS

#DEFINE CHR_NULL  chr(0)
#DEFINE CHR_CR    chr(13)
#DEFINE CHR_LF    chr(10)
#DEFINE CHR_CRLF  CHR_CR+CHR_LF

// STOMP FRAME CLIENT COMMANDS

#DEFINE STOMP_CLIENT_COMMAND_SEND          "SEND"
#define STOMP_CLIENT_COMMAND_SUBSCRIBE     "SUBSCRIBE"
#define STOMP_CLIENT_COMMAND_UNSUBSCRIBE   "UNSUBSCRIBE"
#define STOMP_CLIENT_COMMAND_BEGIN         "BEGIN"
#define STOMP_CLIENT_COMMAND_COMMIT        "COMMIT"
#define STOMP_CLIENT_COMMAND_ABORT         "ABORT"
#define STOMP_CLIENT_COMMAND_ACK           "ACK"
#define STOMP_CLIENT_COMMAND_NACK          "NACK"
#define STOMP_CLIENT_COMMAND_DISCONNECT    "DISCONNECT"
#define STOMP_CLIENT_COMMAND_CONNECT       "CONNECT"
#define STOMP_CLIENT_COMMAND_STOMP         "STOMP"

//STOMP FRAME SERVER COMMANDS

#define STOMP_SERVER_COMMAND_CONNECTED     "CONNECTED"
#define STOMP_SERVER_COMMAND_MESSAGE       "MESSAGE"
#define STOMP_SERVER_COMMAND_RECEIPT       "RECEIPT"
#define STOMP_SERVER_COMMAND_ERROR         "ERROR"

#endif