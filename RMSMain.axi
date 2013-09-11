PROGRAM_NAME='RMSMain'

INCLUDE 'RmsEventListener' // 'RmsApi.axi' is defined in here
(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

URL_STRUCT uRMS_URL

(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)
DEFINE_FUNCTION	rmsInit()
{
	IF(!LENGTH_STRING(uRMS_URL.URL))
	{
		uRMS_URL.URL = 'developer.amxaustralia.com.au';
		uRMS_URL.Password = 'password';
		uRMS_URL.User = 'DGX Redundancy Demo'; // name. Too lazy to creatre a new variable or structure type
		uRMS_URL.Flags = TRUE; // enabled. Too lazy to creatre a new variable or structure type
	}
}

DEFINE_FUNCTION	rmsConnect()
{
	// announce yourself to RMS server. 
	// This can be done in the NI master web page > system > manage system > device options > device configuration pages if desired
	SEND_COMMAND vdvRMS, "'CONFIG.CLIENT.NAME-', uRMS_URL.User";
	SEND_COMMAND vdvRMS, "'CONFIG.SERVER.URL-http://', uRMS_URL.URL, '/rms'";
	SEND_COMMAND vdvRMS, "'CONFIG.SERVER.PASSWORD-', uRMS_URL.Password";
	SEND_COMMAND vdvRMS, "'CONFIG.CLIENT.ENABLED-', ITOA(uRMS_URL.Flags)";
}

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

rmsInit();

//#WARN 'RMS Commented out'
// RMS general
DEFINE_MODULE 'RmsNetLinxAdapter_dr4_0_0' modRMS1(vdvRMS) // instantiate the Netlinx adaptor module which will start the RMS client
// params
DEFINE_MODULE 'RmsControlSystemMonitor' modRMSsysMon1(vdvRMS, dvSystem) // add the control system as an assett
DEFINE_MODULE 'RmsSystemPowerMonitor' modRMSPwrMon1(vdvRMS, dvSystem) 	// monitor power of the system

DEFINE_MODULE 'RmsDgxSwitcherMonitor' modRMSDgxMon1(vdvRMS, vdvDGX, dvDgxSerial) 	// monitor DGX power, temp, fan and cards
(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

DATA_EVENT[vdvRMS]
{
	ONLINE: 
	{
		rmsConnect();
	}
}