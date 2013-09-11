PROGRAM_NAME='ConfigureDXLink'
(***********************************************************)
(*
  20130904 v0.1 RRD
*)
(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

TL_COMMAND = 1;

TIME_ONLINE		= 36000		// 1 hour (36000 secs)
TIME_OFFLINE	= 1				// 1 sec
TIME_ERROR		= 30			// 30 secs

PORT_TELNET		= 23

INTEGER DONT_REMOVE_DATA															= 0
INTEGER REMOVE_DATA_INC_SEARCH												= 1
INTEGER REMOVE_DATA_BETWEEN_SEARCH										= 2
INTEGER REMOVE_DATA_UP_TO_AND_INC_SEARCH							= 3

CHAR TIMELINE_RESULT[][35] =  // error stringS
{
  'created',															// 0
  'error: already in use',								// 1
  'error: array is not array of longs',		// 2
  'error: length is greater than array',	// 3
  'error: out of memory'									// 4
}

CHAR ONERROR_RESULT[][28] =  // error strings
{
  'Operation successful',					// 1
  'General Failure',							// 2
  'undocumented',									// 3
  'Unknown host',									// 4
  'undocumented',									// 5
  'Connection refused',						// 6
  'Connection timed out',					// 7
  'unknown connection error',			// 8
  'Already closed',								// 9  - returned when closing an already closed port
  'Binding error',								// 10
  'Listening error',							// 11
  'undocumented',									// 12
  'undocumented',									// 13
  'Local port already used',			// 14
  'UDP socket already listening',	// 15
  'Too many open sockets',				// 16
  'Local port open'								// 17 - returned when send string is sent to a closed IP port
}

CHAR IP_OPEN_RESULT[][20] =  // error strings
{
  'Operation successful',	//  0
  'Invalid server port',	// -1
  'undocumented',					// -2
  'Unable to open port'		// -3
}
(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

STRUCTURE _DEV_DETAILS_
{
	CHAR sDescription[100];
	CHAR sIPAddr[50];
	CHAR sMacAddr_[50];
	CHAR sBindingMacAddr[50];
	INTEGER nDeviceNum;
	INTEGER	nIPPort;
}

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

PERSISTENT CHAR cNotFirstBoot;	// is only zero on the very first download to a new master
CHAR cDebug = 1;

URL_STRUCT uURL;
CHAR CLIENT_CONNECT[1];

LONG lConnectDelay;		// Time between connection and commands
CHAR sBuffer[1024];

VOLATILE CHAR cNextCommand;

(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)
DEFINE_FUNCTION NetBug(DEV dvDEV_, CHAR sPrefix[100], CHAR sMsg_[100])
{
  IF (cDebug)
		SEND_STRING dvDEV_, "__FILE__,' ', sPrefix, sMsg_, ' ', $0D, $0A";
}

DEFINE_FUNCTION CHAR[MAX_BUFFER_SIZE] GetSubString(CHAR sSource[], CHAR sStart[], CHAR sEnd[], INTEGER iRemoveFlag)
{
	STACK_VAR CHAR sReturn_[MAX_BUFFER_SIZE] CHAR sTemp_[100];
	STACK_VAR INTEGER iStart_ INTEGER iEnd_;

	iStart_ = FIND_STRING(sSource, sStart, 1);
	iEnd_ = FIND_STRING(sSource, sEnd, iStart_+LENGTH_STRING(sStart))-1;
	sReturn_ = MID_STRING(sSource, iStart_+LENGTH_STRING(sStart), iEnd_-iStart_-LENGTH_STRING(sStart)+1);

	SWITCH (iRemoveFlag)
	{
		CASE REMOVE_DATA_UP_TO_AND_INC_SEARCH :
		{
			sSource = RIGHT_STRING(sSource, LENGTH_STRING(sSource)-iEnd_-LENGTH_STRING(sEnd));
			BREAK;
		}
		CASE REMOVE_DATA_INC_SEARCH :
		{
			sSource = "LEFT_STRING(sSource, iStart_-1),
								RIGHT_STRING(sSource, LENGTH_STRING(sSource)-iEnd_-LENGTH_STRING(sEnd))";
			BREAK;
		}
		CASE REMOVE_DATA_BETWEEN_SEARCH : // get rid of attributes
		{
			sSource = "LEFT_STRING(sSource, iStart_+LENGTH_STRING(sStart)-1),
								RIGHT_STRING(sSource, LENGTH_STRING(sSource)-iEnd_)";
			BREAK;
		}
	}
	//DebugString("'GetSubString(', ITOA(iStart_) ,'..', ITOA(iEnd_),'), iStart_=', ITOA(iStart_), ', iEnd_=', ITOA(iEnd_)",
	//						"': sReturn_=', sReturn_", DEBUG_LEVEL_SUPER_CHATTY);
	RETURN(sReturn_);
}

DEFINE_FUNCTION GetTimelineResult(CHAR sID_[], CHAR cResult_) 
{
	NetBug(0:0:0, "'TIMELINE ', sID_", "' ', TIMELINE_RESULT[cResult_+1]");
}

DEFINE_FUNCTION FirstBoot () //
STACK_VAR CHAR cCount_  CHAR cOutput_; 
{
	NetBug(0:0:0, "'FIRST BOOT '", '');
	cNotFirstBoot 		= 1;						// stop this rotine ever being called again
	lConnectDelay			= 1000;					// Time between connection attempts
	lCommandArray[1]	= lConnectDelay;
	uURL.URL					= '127.0.0.1';	// string: URL or IP address
	uURL.Port					= PORT_TELNET;	// TCP port (normally 1319)
	uURL.Flags 				= IP_TCP;				// Connection Type (normally 1) Lower nibble = TCP/UDP, Upper nibble = connection status
	uURL.User					= '';						// optional account info for ICSPS Added v1.21
	uURL.Password			= '';						// optional account info for ICSPS Added v1.21
}


DEFINE_FUNCTION Connect(DEV dvDEV)
LOCAL_VAR SINTEGER sResult_
{
  IF ((!(uURL.Flags & $F0)) && (LENGTH_STRING(uURL.URL))) // only connect if no connection activity
  {
		NetBug(0, "'IP CONNECT ', ITOA(dvDEV.NUMBER), ':', ITOA(dvDEV.PORT), ':', ITOA(dvDEV.SYSTEM), ' WITH '", 
							"uURL.URL, ':', ITOA(uURL.Port)");
		NetBug(0, 'IP_CLIENT_OPEN: ', IP_OPEN_RESULT[ABS_VALUE(IP_CLIENT_OPEN(dvDEV.PORT, uURL.URL, uURL.Port, uURL.Flags & $0F))+1]);
		uURL.Flags = (uURL.Flags & $0F) | URL_Flg_Stat_Connecting;	// connecting
  }
}

DEFINE_FUNCTION Disconnect ()
{
  CancelIpWaits();
  IF (uURL.Flags & URL_Flg_Stat_Connected)
  {
		NetBug(0, "'IP DISCONNECT ', DEVICE_ID_STRING(dvDEV), ' WITH '", 
							"uURL.User, ':', uURL.Password, '@', uURL.URL, ':', ITOA(uURL.Port)");
		IP_CLIENT_CLOSE (dvDEV.PORT);
  }
}

DEFINE_FUNCTION CreateReconnectTimeline()
{
  NetBug(0, 'creating timeline, delay ', ITOA(lCommandArray[1]))
  GetTimelineResult ('TL_COMMAND', 
										TIMELINE_CREATE(TL_COMMAND,
										lCommandArray, 
										1,		// repetitions
										TIMELINE_RELATIVE,
										TIMELINE_REPEAT)) 
}

DEFINE_FUNCTION SetConnectRetryDelay(LONG lDelayTime_) // reload timeline from time = 0
{
  IF (lCommandArray[1] <> lDelayTime_)
		lCommandArray[1] = lDelayTime_
  IF(!TIMELINE_ACTIVE(TL_COMMAND))
  {
		NetBug(0:0:0, 'SetDelay creating timeline', '');
		CreateReconnectTimeline();
  }
  ELSE
  {
		NetBug(0:0:0, 'SetDelay resetting timeline', '');
		TIMELINE_SET(TL_COMMAND, 0);
  }
}

DEFINE_FUNCTION SearchForDevices() // Called from outside the axi
{
	IF(!(uURL.Flags & URL_Flg_Stat_Connected)); // not connected
		Connect();
}

DEFINE_FUNCTION SendNextCommand()
{
	SWITCH (cNextCommand)
	{
		CASE 1: SEND_STRING dvDGXTelnet, "'show ndp',$0d,$0a";
		CASE 2: SEND_STRING dvDGXTelnet, "'show device',$0d,$0a";
		DEFAULT:
		{
			cNextCommand = 0;
			Disconnect();
		}
	}
	cNextCommand++;
}

DEFINE_FUNCTION ParseShowDevice(CHAR sBuffer[])
{
/*
>show device
Show Device
-----------

Local devices for system #1 (This System)
----------------------------------------------------------------------------
Device (ID)Model                 (ID)Mfg                    FWID  Version
00000  (00351)NI Master          (00001)AMX LLC             00845 v4.2.379
       (PID=0:OID=0) Serial='105808ap31d0003',0             Failed Pings=0
       Physical Address=IP 192.168.2.102:1319 (00:60:9f:99:14:8d)
         (00351)vxWorks Image    (00001)                    00843 v4.2.379
         (PID=0:OID=1) Serial=N/A
         (00351)BootROM          (00001)                    00844 v4.2.379
         (PID=0:OID=2) Serial=N/A
05002  (00352)Enova DGX 8        (09233)AMX AutoPatch       00846 v1.6.1.1
       (PID=0:OID=0) Serial='N/A',0,0,0,0,0,0,0,0,0,        Failed Pings=0
       Physical Address=IP 192.168.2.102
         (00352)Enova DGX 8 Integ(09233)                    00846 v1.0.5.2
         (PID=0:OID=6) Serial='N/A',0,0,0,0,0,0,0,0,0,
         (00352)Enova DGX 8 FW Co(09233)                    00846 v1.6.1.1
         (PID=0:OID=7) Serial='N/A',0,0,0,0,0,0,0,0,0,
10004  (00356)EXB-COM2           (00001)AMX LLC             00866 v1.0.49
       (PID=0:OID=0) Serial='210022P34B0121',0,0            Failed Pings=0
       Physical Address=IP 192.168.2.67
         (00356)MQX              (00001)                    00864 v3.62
         (PID=0:OID=1) Serial=N/A
         (00356)EXBboot          (00001)                    00865 v1.0.49
         (PID=0:OID=2) Serial=N/A
         (00356)EXBapp           (00001)                    00866 v1.0.49
         (PID=0:OID=3) Serial=N/A
41002  (65534)Virtual            (00001)AMX LLC             00845 v4.2.379
       (PID=0:OID=0) Serial='105808ap31d0003',0             Failed Pings=0
       Physical Address=None
         (00000)RMS-NetLinx-Adapt(00000)                    00000 v4.0.0
         (PID=0:OID=2) Serial=0000000000000000
*/
}

DEFINE_FUNCTION ParseNDP(CHAR sBuffer[])
{
/*
>show ndp

Master/Bound Devices
--------------------

Description  : NI Master v4.6.319
             : Main 2.0 "Main 2.0.axs"
Flags        : 8000
System       : 1
Device       : 0
DeviceID     : 0161
DeviceExtAddr: IP 192.168.2.200:1319 (00:60:9f:97:c5:5e)
Timestamp    : 10863199

Description  : NI Master v4.2.379
             : DGX Redundancy "DGX RMS Monitor.axs"
Flags        : 8000
System       : 1
Device       : 0
DeviceID     : 015f
DeviceExtAddr: IP 192.168.2.102:1319 (00:60:9f:99:14:8d)
Timestamp    : 10870114

Description  : NI Master v4.1.373
             : Testing "Testing.axs"
Flags        : 8000
System       : 2
Device       : 0
DeviceID     : 012a
DeviceExtAddr: IP 192.168.2.101:1319 (00:60:9f:96:26:ea)
Timestamp    : 10875183

Description  : NI Master v4.6.319
             : AMX Australia Standard Training Room "AMX Australia Standard Trai
ning Room.axs"
Flags        : 8000
System       : 2
Device       : 0
DeviceID     : 0161
DeviceExtAddr: IP 192.168.2.201:1319 (00:60:9f:97:3f:5c)
Timestamp    : 10865267

Unbound Devices
---------------

Description  : DXLINK-HDMI-RX-v1.5.8
             : DXLINK-HDMI-RX Remote Dev:Video Projector
Flags        : 4002
System       : 0
Device       : 5401
DeviceID     : 017d
DeviceExtAddr: IP 192.168.2.66:1319 (00:60:9f:94:9d:6e)
PeerExtAddr  : MAC:00:60:9f:97:12:32
Timestamp    : 10870070

Current Timestamp: 10879995
>
*/
	STACK_VAR CHAR sTemp_[1000];
	STACK_VAR CHAR cStartPos_ CHAR cEndPos_;
	
	sTemp_ = REMOVE_STRING(sBuffer, 'Unbound Devices', 1);
	IF(LENGTH_STRING(sTemp_))
	{
		cStartPos_ = FIND_STRING(sBuffer, 'Description', 1));
		WHILE(cStartPos_)
		{
			cEndPos_ = FIND_STRING(sBuffer, 'Timestamp', 1));
			cEndPos_ = FIND_STRING(sBuffer, "$0d", cEndPos_));
			sTemp_ = MID_STRING(sBuffer, cStartPos_, cEndPos_-cStartPos_+1); // sTemp_ is all details of a device
			ParseUnboundNDPDevice(sTemp_);
			cStartPos_ = FIND_STRING(sBuffer, 'Description', cEndPos_));
		}
	}
}

DEFINE_FUNCTION ParseUnboundNDPDevice(CHAR sBuffer[])
{
/*
Description  : DXLINK-HDMI-RX-v1.5.8
             : DXLINK-HDMI-RX Remote Dev:Video Projector
Flags        : 4002
System       : 0
Device       : 5401
DeviceID     : 017d
DeviceExtAddr: IP 192.168.2.66:1319 (00:60:9f:94:9d:6e)
PeerExtAddr  : MAC:00:60:9f:97:12:32
Timestamp    : 10870070
*/
	STACK_VAR CHAR sTemp_[500]; 
	STACK_VAR CHAR cStartPos_ CHAR cEndPos_;
	STACK_VAR _DEV_DETAILS_ Device_;
	
	Device_.nDeviceNum = ATOI(GetSubString(sBuffer, "'Device       : '", "$0d", REMOVE_DATA_INC_SEARCH));
	Device_.sDescription = GetSubString(sBuffer, "'Description  : '", "$0d", REMOVE_DATA_INC_SEARCH);
	Device_.sBindingMacAddr = GetSubString(sBuffer, "'DeviceExtAddr: IP '", "$0d", REMOVE_DATA_INC_SEARCH);

	sTemp_ = GetSubString(sBuffer, "'DeviceExtAddr: IP '", "$0d", REMOVE_DATA_INC_SEARCH);	
	Device_.sIPAddr = GetSubString(sTemp_, "'DeviceExtAddr: IP '", "':'", REMOVE_DATA_INC_SEARCH);
	Device_.sMacAddr = GetSubString(sTemp_, "'('", "')'", REMOVE_DATA_INC_SEARCH);
	Device_.nIPPort = ATOI(sTemp_);

	IF(FIND_STRING(Device_.sDescription, 'DXLINK', 1))
	{
		IF(FIND_STRING(Device_.sDescription, 'DXLINK-HDMI-RX', 1))
		{
		}
		ELSE // TX
		{
		}
	}

}

DEFINE_FUNCTION ReadBuffer (CHAR sBuffer_[])
LOCAL_VAR CHAR sMsg_[255] INTEGER iJoin_ INTEGER iValue_ INTEGER iiPID_
{
  NetBug(0:0:0, 'BUFFER in - ', sBuffer);
  sBuffer = "";
  sBuffer = sBuffer_;
	IF(FIND_STRING(sBuffer, 'Welcome to NetLinx', 1)) // just connected
	{
	//Welcome to NetLinx v4.2.379 Copyright AMX LLC 2009
		cNextCommand = 1;
		SendNextCommand();
	}
	ELSE IF(FIND_STRING(sBuffer, 'Show Device', 1))
	{
		ParseShowDevice(sBuffer);
	}
	ELSE IF(FIND_STRING(sBuffer, 'Master/Bound Devices', 1))
	{
		ParseShowDevice(sBuffer);
	}
	//CLEAR_BUFFER sBuffer;
}

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT
TIMELINE_EVENT[TL_COMMAND] 
{
  Connect();
}

DATA_EVENT[dvDGXTelnet]
{
  ONLINE : 
  {
		uURL.Flags = (uURL.Flags & $0F) | URL_Flg_Stat_Connected;	// connected
		IF (TIMELINE_ACTIVE(TL_COMMAND))
			TIMELINE_KILL(TL_COMMAND);
		//SendNextCommand();
		NetBug(0, 'IP ONLINE', "'. URL.Flags ', ITOA(uURL.Flags)");
	}
	OFFLINE:
	{
		uURL.Flags = uURL.Flags & $0F;	// disconnected
		Connect(); // want this port to stay online to catch incoming calls
		NetBug(0, 'IP OFFLINE', "'. URL.Flags ', ITOA(uURL.Flags)");
	}
	ONERROR : 
	{
		CancelIpWaits();
		SWITCH (DATA.NUMBER)
		{
			CASE 14 : // 14 Local port already used
			CASE 17 : // 17 Local port open
				uURL.Flags = (uURL.Flags & $0F) | URL_Flg_Stat_Waiting;	// waiting
			CASE  7 : // 7 Connection timed out
			CASE  9 : // 9 Already closed
			DEFAULT :
				uURL.Flags = uURL.Flags & $0F;	// disconnected
		}
		IF (DATA.NUMBER)
		{
			NetBug(0, "'IP ERROR ', ITOA(DATA.NUMBER), ' : ', ONERROR_RESULT[DATA.NUMBER]", 
						"'. URL.Flags ', ITOA(uURL.Flags)");
		}
  }
  STRING :
  {
		NetBug(0, "ITOA(dvDEV.NUMBER), ':', ITOA(dvDEV.PORT), ':', ITOA(dvDEV.SYSTEM), ' STRING ~ DATA.TEXT: ', DATA.TEXT", '');
		ReadBuffer(DATA.TEXT);
  }
}