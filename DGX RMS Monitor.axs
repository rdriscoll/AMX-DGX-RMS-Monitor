PROGRAM_NAME='DGX Redundancy'
(***********************************************************)
(*
  20130904 v0.1 RRD
*)
(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT
LOCAL_SYSTEM			= 1;
REMOTE_SYSTEM_01	= 2;
(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

dvTerminal		= 0:0:0
dvSystem			= 0:1:0
dvDGXTelnet		= 0:2:0

dvUI					= 10001:1:LOCAL_SYSTEM

dvDXLinkTx_01 = 6001:1:LOCAL_SYSTEM
dvDXLinkTx_02 = 6002:1:LOCAL_SYSTEM

dvDXLinkRx_01 = 6101:1:LOCAL_SYSTEM
dvDXLinkRx_02 = 6102:1:LOCAL_SYSTEM

//dvDgxSerial	= 10004:1:LOCAL_SYSTEM
dvDgxSerial		= 5001:1:REMOTE_SYSTEM_01

vdvDGX				= 33001:1:LOCAL_SYSTEM
vdvRMS 				= 41002:1:LOCAL_SYSTEM //virtual device for RMS Main

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT
(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE
(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE
(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)
INCLUDE 'RMSMain.axi'
//INCLUDE 'testing.axi'

DEFINE_FUNCTION CHAR[20] devToString(DEV dvDev)
{
	RETURN "ITOA(dvDev.NUMBER), ':', ITOA(dvDev.PORT), ':', ITOA(dvDev.SYSTEM)"
}
(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

DATA_EVENT[dvDXLinkTx_01]
{
	OFFLINE:
	{
		SEND_STRING dvTerminal, "'DXLink Tx-01 ', devToString(DATA.DEVICE),' offline'"
		
	}
}

DATA_EVENT[dvDXLinkRx_01]
{
	OFFLINE:
	{
		SEND_STRING dvTerminal, "'DXLink Rx-01 ', devToString(DATA.DEVICE),' offline'"
	}
}

BUTTON_EVENT[dvUI, 0] // debugging only
{
	PUSH:
	{
		SEND_STRING dvTerminal, "'Button pushed:', ITOA(BUTTON.INPUT.CHANNEL)"
		IF(BUTTON.INPUT.CHANNEL < 8)
			SEND_STRING dvDgxSerial, "'~scri',ITOA(BUTTON.INPUT.CHANNEL),'v3!',$0d,$0a"; // board info
		ELSE
			SWITCH(BUTTON.INPUT.CHANNEL)
			{
				CASE 11: SEND_STRING dvDgxSerial, "$03"; // Control+C to go into DGX_SHELL>
				CASE 12: SEND_STRING dvDgxSerial, "'show stats',$0d,$0a";
				CASE 13: SEND_STRING dvDgxSerial, "'bcs',$0d,$0a"; // go back to bcs shell				
				CASE 21: SEND_STRING dvDgxSerial, "'~scri4v3!'"; // board info
				CASE 22: SEND_STRING dvDgxSerial, "'~scri6v3!'"; // board info
				CASE 23: SEND_STRING dvDgxSerial, "'~scri7v3!'"; // board info
			}
	}
}

DATA_EVENT[dvUI]
{
	STRING:
	{
		SEND_STRING dvDgxSerial, DATA.TEXT
	}
}

(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)

