PROGRAM_NAME='DGX RMS Monitor'
(***********************************************************

The MIT License (MIT)

Copyright (c) 2013 AMX Australia

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

(***********************************************************)

  20131009 v0.1.1 RRD Changed Connected states to strings rather than booleans.
  20130904 v0.1 RRD
	This Program reads the status of a DGX using a serial port
	connected to the serial port on the DGX, and reports the 
	status to RMSE.
	
	The current revision reports the following:
		- Power supply status
		- Number of input and output boards
		- type of input and output board
		- Link status of DXLink connections on boards
		- fan speed (main fan only)
		
	Maintenance alerts are triggered for the following
		- unplugging an input or output board
		- unplugging a DXLink input or output
		- unplugging a power supply
		- threshold power supply 
		
	Things that aren't currently reported:
		- temperature
		- internal boards
		- internal fans
		- video connections other than DXLink (not reported so can't do anything about it)
	
	The original plan for this program was to be able to plug a
	factory reset DXLink box to a port and have it automatically 
	set up  from the program without the need for a technician.
	
	*** Here is the UN-IMPLEMENTED plan to do this**
	1. A DXLink device fails
		-	This program detects no link on a DXLink port
		- This program detects the device offline
	2. User replaces the faulty unit with a factory reset unit
		- This program detects a link on the port but no device online
		- this program searches for unbound ndp devices
		- this program sets up an unbound device to the IP and device settings
		  of the faulty unit.
	3. User sends faulty unit for repair.
	
	Todo 
	- finish the ndp discover module
	- write code to determine when to set up another device.
	- write a module to telnet into a DXLink device, set it's IP, device and master
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

dvDgxSerial	= 10004:1:LOCAL_SYSTEM
//dvDgxSerial		= 5001:1:REMOTE_SYSTEM_01

vdvDGX				= 33001:1:LOCAL_SYSTEM
vdvRMS 				= 41002:1:LOCAL_SYSTEM //virtual device for RMS Main

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

DEV dvDXLinkTx[] =
{
	dvDXLinkTx_01,
	dvDXLinkTx_02
}

DEV dvDXLinkRx[] =
{
	dvDXLinkRx_01,
	dvDXLinkRx_02
}

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE
(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

cDeviceOnline
(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)
INCLUDE 'RMSMain.axi'
//INCLUDE 'ConfigureDXLink.axi'

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

DATA_EVENT[dvDXLinkTx]
{
	OFFLINE:
	{
		SEND_STRING dvTerminal, "'DXLink Tx-', ITOA(GET_LAST(dvDXLinkTx)), ' offline. ', devToString(DATA.DEVICE)"
	}
	ONLINE:
	{
		SEND_STRING dvTerminal, "'DXLink Tx-', ITOA(GET_LAST(dvDXLinkTx)), ' online. ', devToString(DATA.DEVICE)"
	}
}

DATA_EVENT[dvDXLinkRx]
{
	OFFLINE:
	{
		SEND_STRING dvTerminal, "'DXLink Rx-', ITOA(GET_LAST(dvDXLinkRx)), ' offline. ', devToString(DATA.DEVICE)"
	}
	ONLINE:
	{
		SEND_STRING dvTerminal, "'DXLink Rx-', ITOA(GET_LAST(dvDXLinkRx)), ' online. ', devToString(DATA.DEVICE)"
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
				CASE 30: SEND_COMMAND vdvRMS, 'DEBUG=4';
				CASE 31: SEND_COMMAND vdvRMS, 'DEBUG=0';
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

