//*********************************************************************
//
//             AMX Resource Management Suite  (4.1.5)
//
//*********************************************************************
/*
 *  Legal Notice :
 *
 *     Copyright, AMX LLC, 2012
 *
 *     Private, proprietary information, the sole property of AMX LLC.  The
 *     contents, ideas, and concepts expressed herein are not to be disclosed
 *     except within the confines of a confidential relationship and only
 *     then on a need to know basis.
 *
 *     Any entity in possession of this AMX Software shall not, and shall not
 *     permit any other person to, disclose, display, loan, publish, transfer
 *     (whether by sale, assignment, exchange, gift, operation of law or
 *     otherwise), license, sublicense, copy, or otherwise disseminate this
 *     AMX Software.
 *
 *
 *     This AMX Software is owned by AMX and is protected by United States
 *     copyright laws, patent laws, international treaty provisions, and/or
 *     state of Texas trade secret laws.
 *
 *     Portions of this AMX Software may, from time to time, include
 *     pre-release code and such code may not be at the level of performance,
 *     compatibility and functionality of the final code. The pre-release code
 *     may not operate correctly and may be substantially modified prior to
 *     final release or certain features may not be generally released. AMX is
 *     not obligated to make or support any pre-release code. All pre-release
 *     code is provided "as is" with no warranties.
 *
 *     This AMX Software is provided with restricted rights. Use, duplication,
 *     or disclosure by the Government is subject to restrictions as set forth
 *     in subparagraph (1)(ii) of The Rights in Technical Data and Computer
 *     Software clause at DFARS 252.227-7013 or subparagraphs (1) and (2) of
 *     the Commercial Computer Software Restricted Rights at 48 CFR 52.227-19,
 *     as applicable.
*/

(***********************************************************)
(*                                                         *)
(*  PURPOSE:                                               *)
(*                                                         *)
(*  This NetLinx module contains the source code for       *)
(*  monitoring and controlling a Dgx switchers in RMS.     *)
(*                                                         *)
(*  This module will register a base set of asset          *)
(*  monitoring parameters, metadata properties, and        *)
(*  contorl methods.  It will update the monitored         *)
(*  parameters as changes from the device are              *)
(*  detected.                                              *)
(*                                                         *)
(***********************************************************)
MODULE_NAME='RmsDgxSwitcherMonitor'(DEV vdvRMS, DEV vdvDEV, DEV dvDgxSerial)
// 20130906 v0.1 RRD - modified 'RmsDvxSwitcherMonitor'
// Only made max 16x16

//#DEFINE _VIDEO_SWITCHER_MONITORING_

(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)
DEFINE_DEVICE

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

INTEGER DEBUG_LEVEL																		= 3;

INTEGER DEBUG_LEVEL_QUIET															= 1
INTEGER DEBUG_LEVEL_STANDARD													= 2
INTEGER DEBUG_LEVEL_CHATTY														= 4
INTEGER DEBUG_LEVEL_SUPER_CHATTY											= 8

// This defines maximum string length for the purpose of
// dimentioning array sizes
INTEGER MAX_STRING_SIZE																= 50;
INTEGER MAX_ENUM_ENTRY_SIZE														= 50;

INTEGER MAX_BUFFER_SIZE																= 4000;

INTEGER DONT_REMOVE_DATA															= 0
INTEGER REMOVE_DATA_INC_SEARCH												= 1
INTEGER REMOVE_DATA_BETWEEN_SEARCH										= 2
INTEGER REMOVE_DATA_UP_TO_AND_INC_SEARCH							= 3

// These reflect default maximul values for inputs, ports, etc.
// and as such provide a consistent means to size arrays
INTEGER MAX_VIDEO_INPUT_CNT														= 8;
INTEGER MAX_VIDEO_OUTPUT_CNT													= 8;
INTEGER MAX_FAN_COUNT																	= 2;
INTEGER MAX_PWR_SUPLY_COUNT														= 2;

INTEGER NUM_INPUT_BOARDS = 2; // DGX 8
INTEGER NUM_OUTPUT_BOARDS = 2; // DGX 8
INTEGER NUM_CENTER_BOARDS = 2; // DGX 8
INTEGER NUM_EXPANSION_BOARDS = 2; // DGX 8

CHAR ALL_INPUTS_MSG[]																	= 'All';
CHAR ALL_OUTPUTS_MSG[]																= 'All Outputs';
CHAR MONITOR_ASSET_NAME[]															= '';		// Leave it empty to auto-populate the device name
CHAR MONITOR_ASSET_TYPE[]															= 'Switcher';
CHAR MONITOR_DEBUG_NAME[]															= 'RmsDgxMon';
CHAR MONITOR_NAME[]																		= 'RMS Dgx Switcher Monitor';
CHAR MONITOR_VERSION[]																= '4.1.5';
CHAR NO_INPUTS_MSG[]																	= 'None';
CHAR SET_FRONT_PANEL_LOCKOUT_ENUM[3][MAX_STRING_SIZE]	= { 'All', 'Unlocked', 'Configuration Only' };	// Front panel lockout values
CHAR SET_POWER_ENUM[]																	= { 'ON|OFF' };		// Note the words may change however power on must be first
CHAR SET_VIDEO_OUTOUT_SCALING_MODE_ENUM[]							= 'AUTO|MANUAL|BYPASS';
CHAR degreesC[]																				= {176,'C'};	// Degrees Centigrade
INTEGER FAN_SPEED_DELTA																= 50;					// Don't report speed changes less than this value
INTEGER TEMPERATURE_ALARM_THRESHOLD										= 40;					// Over temperature threshold in degrees C
INTEGER TEMPERATURE_DELTA															= 2;					// Don't report temperatrue changes less than this value
INTEGER TL_MONITOR																		= 1;					// Timeline id
LONG DgxMonitoringTimeArray[]													= {5000};		// Frequency of value update requests

// Device Channels
INTEGER BASE_VIDEO_INPUT_CHANNEL											= 30;				// The video input number is
																																	// added to this base to determine the channel
																																	// i.e. input 1 is channel 31
INTEGER VIDEO_OUTPUT_ENABLE_CHANNEL										= 70;
INTEGER MIC_ENABLE_CHANNEL														= 71;
INTEGER STANDBY_STATE_CHANNEL													= 100;
INTEGER AUDIO_MUTE_CHANNEL														= 199;
INTEGER VIDEO_MUTE_CHANNEL														= 210;
INTEGER VIDEO_FREEZE_STATE_CHANNEL										= 213;
INTEGER FAN_ALARM_CHANNEL															= 216;
INTEGER TEMP_ALARM_CHANNEL														= 217;

// Device levels
INTEGER TEMP_LEVEL																		= 8;

// Device ID's of various Dgx devices
INTEGER ID_Dgx8																				= 351;		// 0x015F
INTEGER ID_Dgx16																			= 352;		// 0x0160
INTEGER ID_Dgx32																			= 353;		// 0x0161
INTEGER ID_Dgx64																			= 354;		// 0x0162

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE
 
STRUCTURE _DXL_CHANNEL
{
	CHAR cLink;
/*
	CHAR cLength;
	CHAR cMSE[4];
	CHAR cBER_Video;
	CHAR cBER_Audio;
	CHAR cBER_Blank;
	CHAR cBER_Ctrl;
	CHAR cDSPResetCount;
*/
}

STRUCTURE _DXL_BOARD
{
	_DXL_CHANNEL uChannel[4];
	INTEGER nStatus; // 0 for missing
}

STRUCTURE RmsDgxInfo
{

	// variables for device capabilities
	CHAR hasTemperatureSensor;
	SLONG internalTemperature;
	CHAR tempAlarm;																		// TRUE to FALSE to indicate a temperature alarm

	CHAR hasFan;
	CHAR fanAlarm;																		// TRUE to FALSE to indicate a fan alarm
	INTEGER fanCount;
	INTEGER fanSpeed;																		// Each array entry contains the speed of a specific fan
	INTEGER nFanSetting[2];

	CHAR videoInputFormat[MAX_VIDEO_INPUT_CNT][MAX_ENUM_ENTRY_SIZE];	// This contains the video input format. i.e. HDMI, etc.
	CHAR videoInputName[MAX_VIDEO_INPUT_CNT][MAX_ENUM_ENTRY_SIZE];	// Names assigned to video inputs
	CHAR videoOutputEnabled[MAX_VIDEO_OUTPUT_CNT];	 	// An array which indicates the video output
																										// enabled status (TRUE or FALSE) for each channel
	CHAR videoOutputPictureMute[MAX_VIDEO_OUTPUT_CNT];// An array which indicates the video output
																										// mute status (0 for not muted, input to return to for muted) for each channel
	CHAR videoOutputScaleMode[MAX_VIDEO_OUTPUT_CNT][MAX_STRING_SIZE];	// Video output scale mode
	CHAR videoOutputVideoFreeze[MAX_VIDEO_OUTPUT_CNT];// An array which indicates the video output
																										// freeze status (TRUE or FALSE) for each channel
	INTEGER videoInputCount;
	INTEGER multiFormatVideoInputCount;								// This is the number of inputs which support all formats
	INTEGER hdmiFormatVideoInputCount;							// The number of inputs which support only digital formats
	INTEGER videoOutputCount;
	INTEGER videoOutputSelectedSource[MAX_VIDEO_OUTPUT_CNT];	// An array which indicates the input source number for each channel

	CHAR PowerSupply[MAX_PWR_SUPLY_COUNT];
	INTEGER PowerAvailable;
	INTEGER PowerRequired;
	
	_DXL_BOARD uInputBoard[4];
	_DXL_BOARD uOutputBoard[4];
	_DXL_BOARD uExpansionBoard[2];
	_DXL_BOARD uCenterBoard[2];
	CHAR cNumInputBoards;
	CHAR cNumOutputBoards;
	CHAR cNumCenterBoards;
	CHAR cNumExpansionBoards;
}

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

VOLATILE CHAR cBufferDGX[MAX_BUFFER_SIZE];
//VOLATILE CHAR strTest[7][MAX_BUFFER_SIZE];
VOLATILE CHAR cDgxValueUpdateIndex;

CHAR devInit = FALSE;
CHAR hasValidDeviceId;
CHAR setVideoInputPortPlusNoneEnum[MAX_VIDEO_INPUT_CNT + 1][MAX_ENUM_ENTRY_SIZE]
CHAR setVideoOutputPortPlusAllEnum[MAX_VIDEO_OUTPUT_CNT + 1][MAX_ENUM_ENTRY_SIZE];
DEV dvMonitoredDevice = 5002:1:0	// Default Dgx DPS
DEV_INFO_STRUCT devInfo;
RmsDgxInfo DgxDeviceInfo;									// RMS device Monitoring Variable

// One DPS entry for each port number
// This array must include all DPS numbers used for Dgx data event processing
DEV DgxDeviceSet[] = {
											5002:1:0,
											5002:2:0,
											5002:3:0,
											5002:4:0,
											5002:5:0,
											5002:6:0,
											5002:7:0,
											5002:8:0,
											5002:9:0,
											5002:10:0,
											5002:11:0,
											5002:12:0,
											5002:13:0,
											5002:14:0,
											5002:15:0,
											5002:16:0
										}      

// Include RMS MONITOR COMMON AXI
#INCLUDE 'RmsMonitorCommon';

(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)

(***********************************************************)
(* Name:  DgxAssetParameterSetValueBoolean                 *)
(* Args:  None                                             *)
(*                                                         *)
(* Desc:  Wrap RmsAssetParameterSetValueBoolean            *)
(*        and make sure RMS is ready for updates,          *)
(*        i.e. online and everything is registered  .      *)
(*                                                         *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR parameterKey[] - monitored parameter key    *)
(*        CHAR parameterValue - monitored parameter value  *)
(*                                                         *)
(*        Note: If RMS is not ready, any update will be    *)
(*        silently skipped. Since the update will not be   *)
(*        performed, all data must be cached so that       *)
(*        updates can be performed once RMS is ready       *)
(*                                                         *)
(***********************************************************)
DEFINE_FUNCTION DgxAssetParameterSetValueBoolean(CHAR assetClientKey[], CHAR parameterKey[], CHAR parameterValue)
{
	DebugVal(parameterKey, parameterValue, DEBUG_LEVEL_CHATTY);		
	if(IsRmsReadyForParameterUpdates() == TRUE)
	{
		DebugVal("'UPDATING ', parameterKey", parameterValue, DEBUG_LEVEL_STANDARD);		
		RmsAssetParameterSetValueBoolean(assetClientKey, parameterKey, parameterValue);
	}
}

(***********************************************************)
(* Name:  DgxAssetParameterSetValue                        *)
(* Args:  None                                             *)
(*                                                         *)
(* Desc:  Wrap RmsAssetParameterSetValue                   *)
(*        and make sure RMS is ready for updates,          *)
(*        i.e. online and everything is registered  .      *)
(*                                                         *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR parameterKey[] - monitored parameter key    *)
(*        CHAR parameterValue[] - monitored parameter value*)
(*                                                         *)
(*        Note: If RMS is not ready, any update will be    *)
(*        silently skipped. Since the update will not be   *)
(*        performed, all data must be cached so that       *)
(*        updates can be performed once RMS is ready       *)
(*                                                         *)
(***********************************************************)
DEFINE_FUNCTION DgxAssetParameterSetValue(CHAR assetClientKey[], CHAR parameterKey[], CHAR parameterValue[])
{
	DebugString(parameterKey, parameterValue, DEBUG_LEVEL_CHATTY);		
	if(IsRmsReadyForParameterUpdates() == TRUE)
	{
		DebugString("'UPDATING ', parameterKey", parameterValue, DEBUG_LEVEL_STANDARD);		
		RmsAssetParameterSetValue(assetClientKey, parameterKey, parameterValue);
	}
}

(***********************************************************)
(* Name:  DgxAssetParameterSetValueNumber                  *)
(* Args:  None                                             *)
(*                                                         *)
(* Desc:  Wrap RmsAssetParameterSetValueNumber             *)
(*        and make sure RMS is ready for updates,          *)
(*        i.e. online and everything is registered  .      *)
(*                                                         *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR parameterKey[] - monitored parameter key    *)
(*        SLONG parameterValue - monitored parameter value *)
(*                                                         *)
(*        Note: If RMS is not ready, any update will be    *)
(*        silently skipped. Since the update will not be   *)
(*        performed, all data must be cached so that       *)
(*        updates can be performed once RMS is ready       *)
(*                                                         *)
(***********************************************************)
DEFINE_FUNCTION DgxAssetParameterSetValueNumber(CHAR assetClientKey[], CHAR parameterKey[], SLONG parameterValue)
{
	DebugVal(parameterKey, TYPE_CAST(parameterValue), DEBUG_LEVEL_CHATTY);		
	if(IsRmsReadyForParameterUpdates() == TRUE)
	{
		DebugVal("'UPDATING ', parameterKey", TYPE_CAST(parameterValue), DEBUG_LEVEL_STANDARD);		
		RmsAssetParameterSetValueNumber(assetClientKey, parameterKey, parameterValue);
	}
}

(***********************************************************)
(* Name:  UpdatePortEnums                                  *)
(* Args:  None                                             *)
(*                                                         *)
(* Desc:  Update each of the enumerations used to          *)
(*        to provide input and output port information.    *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION UpdatePortEnums()
{
	STACK_VAR INTEGER index;
#IF_DEFINED _VIDEO_SWITCHER_MONITORING_	
	// Build enumeration of video input port selections
	setVideoInputPortPlusNoneEnum[1] = NO_INPUTS_MSG;
	FOR(index = 1; index <= DgxDeviceInfo.videoInputCount; index++)
	{
		setVideoInputPortPlusNoneEnum[index + 1] = "ITOA(index), ' - ', DgxDeviceInfo.videoInputName[index]";
	}
		
	// Build enumeration of output port selections
	setVideoOutputPortPlusAllEnum[1] = ALL_OUTPUTS_MSG;
	FOR(index = 1; index <= DgxDeviceInfo.videoOutputCount; index++)
	{
		setVideoOutputPortPlusAllEnum[index + 1] = ITOA(index);
	}
#END_IF
}

(***********************************************************)
(* Name:  ExecuteAssetControlMethod                        *)
(* Args:  methodKey - unique method key that was executed  *)
(*        arguments - array of argument values invoked     *)
(*                    with the execution of this method.   *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that it should         *)
(*        fullfill the execution of one of this asset's    *)
(*        control methods.                                 *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION ExecuteAssetControlMethod(CHAR methodKey[], CHAR arguments[])
{
	STACK_VAR CHAR param1[RMS_MAX_PARAM_LEN];
	STACK_VAR CHAR param2[RMS_MAX_PARAM_LEN];
	
	// If this device does not have a valid device ID, 
	// simply return without doing anything
	IF(hasValidDeviceId == FALSE)
	{
		RETURN;
	}
	
	SELECT
	{
		// Video source selection
		ACTIVE(methodKey == 'switcher.output.video.switch'):
		{
			STACK_VAR CHAR videoInputPort[MAX_VIDEO_OUTPUT_CNT];
			STACK_VAR INTEGER loopNdx1;
			
			param1 = RmsParseCmdParam(DATA.TEXT);			// Output port
			param2 = RmsParseCmdParam(DATA.TEXT);			// Input port
			
			// If input is NO_INPUTS_MSG, disconnect the output from any inputs
			IF(param2 == NO_INPUTS_MSG)
			{
				videoInputPort = '0'
			}
			// Lookup the input port name and determine the port number
			ELSE
			{
				FOR(loopNdx1 = 1 ; loopNdx1 <= LENGTH_ARRAY(setVideoInputPortPlusNoneEnum); loopNdx1++)
				{
					IF(setVideoInputPortPlusNoneEnum[loopNdx1 + 1] == param2)
					{
						videoInputPort = ITOA(loopNdx1);
						BREAK;
					}
				}
				
				// Note, this should only happen if the port name was changed after the control
				// methods were registered.
				// Warn if there was no match between selected port name and the list
				// of possible port names
				IF(videoInputPort == '')
				{
					AMX_LOG(AMX_WARNING, "MONITOR_DEBUG_NAME, '-ExecuteAssetControlMethod(): methodKey: ',
										methodKey, ' invalid input port name: ', param2");
					RETURN;
				}
			}

			// Now only set the desired input, but if ALL_OUTPUTS_MSG set them all
			IF(param1 == ALL_OUTPUTS_MSG)
			{
				FOR(loopNdx1 = 1 ; loopNdx1 <= DgxDeviceInfo.videoOutputCount; loopNdx1++)
				{
					SEND_COMMAND dvMonitoredDevice, "'VI', videoInputPort, 'O', ITOA(loopNdx1)";
				}
			}
			ELSE
			{
				SEND_COMMAND dvMonitoredDevice, "'VI', videoInputPort, 'O', param1";
			}
		}

		// Video mute
		ACTIVE(methodKey == 'switcher.output.video.mute'):
		{
			STACK_VAR CHAR muteState;
			STACK_VAR INTEGER ndx1;

			param1 = RmsParseCmdParam(DATA.TEXT);
			param2 = RmsParseCmdParam(DATA.TEXT);

			IF(param2 == '0')
			{
				muteState = FALSE;
			}
			ELSE IF(param2 == '1')
			{
				muteState = TRUE;
			}
			ELSE
			{
				AMX_LOG(AMX_WARNING, "MONITOR_DEBUG_NAME, '-ExecuteAssetControlMethod(): methodKey: ',
									methodKey, ' port: ', param1, ' unexpected state: ', param2");
				RETURN;
			}

			IF(param1 == ALL_OUTPUTS_MSG)
			{
				FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.videoOutputCount; ndx1++)
				{
					[DgxDeviceSet[ndx1], VIDEO_MUTE_CHANNEL] = muteState;
					IF(muteState)
					{
						SEND_COMMAND dvMonitoredDevice, "'DL', ITOA(ndx1)";
						DgxDeviceInfo.videoOutputPictureMute[ndx1] = TYPE_CAST(DgxDeviceInfo.videoOutputSelectedSource[ndx1]);
					}
					ELSE
					{
						SEND_COMMAND dvMonitoredDevice, "'VI', ITOA(DgxDeviceInfo.videoOutputPictureMute[ndx1]), 'O', ITOA(ndx1)";
						DgxDeviceInfo.videoOutputPictureMute[ndx1] = 0;
					}
				}
			}
			ELSE
			{
				[DgxDeviceSet[ATOI(param1)], VIDEO_MUTE_CHANNEL] = muteState;
				IF(muteState)
				{
					SEND_COMMAND dvMonitoredDevice, "'DL', ITOA(ATOI(param1))";
					DgxDeviceInfo.videoOutputPictureMute[ATOI(param1)] = TYPE_CAST(DgxDeviceInfo.videoOutputSelectedSource[ATOI(param1)]);
				}
				ELSE
				{
					SEND_COMMAND dvMonitoredDevice, "'VI', ITOA(DgxDeviceInfo.videoOutputPictureMute[ATOI(param1)]), 'O', ITOA(ATOI(param1))";
					DgxDeviceInfo.videoOutputPictureMute[ATOI(param1)] = 0;
				}
			}
		}
	}
}

(***********************************************************)
(* Name:  InitDefaults                                     *)
(* Args:  NONE                                             *)
(*                                                         *)
(* Desc:  Initalize device capabilities.                   *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION InitDefaults()
{
	STACK_VAR INTEGER ndx1;
	
	hasValidDeviceId = TRUE;
	
	DgxDeviceInfo.hasFan											= FALSE;
	DgxDeviceInfo.hasTemperatureSensor				= FALSE;

	DgxDeviceInfo.fanAlarm										= FALSE;
	DgxDeviceInfo.fanCount										= 0;
#IF_DEFINED _VIDEO_SWITCHER_MONITORING_
	DgxDeviceInfo.videoInputCount							= 0;
	DgxDeviceInfo.multiFormatVideoInputCount	= 0;
	DgxDeviceInfo.hdmiFormatVideoInputCount		= 0;
	DgxDeviceInfo.videoOutputCount						= 0;
#END_IF	
	SWITCH(devInfo.DEVICE_ID)
	{
		CASE ID_Dgx8:		
		{
			DgxDeviceInfo.fanCount										= 2;
#IF_DEFINED _VIDEO_SWITCHER_MONITORING_
			DgxDeviceInfo.videoInputCount							= 8;
			DgxDeviceInfo.videoOutputCount						= 8;
#END_IF	
		}
		CASE ID_Dgx16:		
		{
			DgxDeviceInfo.fanCount										= 2;
#IF_DEFINED _VIDEO_SWITCHER_MONITORING_
			DgxDeviceInfo.videoInputCount							= 16;
			DgxDeviceInfo.videoOutputCount						= 16;
#END_IF	
		}
		CASE ID_Dgx32:
		{
			DgxDeviceInfo.fanCount										= 2;
#IF_DEFINED _VIDEO_SWITCHER_MONITORING_
			DgxDeviceInfo.videoInputCount							= 32;
			DgxDeviceInfo.videoOutputCount						= 32;
#END_IF	
		}
		CASE ID_Dgx64:
		{
			DgxDeviceInfo.fanCount										= 4;
#IF_DEFINED _VIDEO_SWITCHER_MONITORING_
			DgxDeviceInfo.videoInputCount							= 64;
			DgxDeviceInfo.videoOutputCount						= 64;
#END_IF	
		}
	}

	SWITCH(devInfo.DEVICE_ID)
	{
		CASE ID_Dgx8:		
		CASE ID_Dgx16:		
		CASE ID_Dgx32:
		CASE ID_Dgx64:
		{

			// Make runtime decisions about device capabilites
			DgxDeviceInfo.hasFan											= TRUE;
			DgxDeviceInfo.hasTemperatureSensor				= TRUE;
#IF_DEFINED _VIDEO_SWITCHER_MONITORING_
			DgxDeviceInfo.multiFormatVideoInputCount	= 4;
			DgxDeviceInfo.hdmiFormatVideoInputCount		= 6;
#END_IF	
		}
		
		DEFAULT:
		{
			AMX_LOG(AMX_WARNING, "MONITOR_DEBUG_NAME, '-InitDefaults: Unexpected DEVICE_ID: ',  ITOA(devInfo.DEVICE_ID)");
			hasValidDeviceId = FALSE;
			RETURN;
		}
	}
	
#IF_DEFINED _VIDEO_SWITCHER_MONITORING_
	// Since these are not explicitly initalized they must be sized
	SET_LENGTH_ARRAY(setVideoInputPortPlusNoneEnum, DgxDeviceInfo.videoInputCount + 1);
	SET_LENGTH_ARRAY(setVideoOutputPortPlusAllEnum, DgxDeviceInfo.videoOutputCount + 1);

	// Walk through each video output variable and initialize some sane value
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.videoOutputCount; ndx1++)
	{
		DgxDeviceInfo.videoOutputScaleMode[ndx1]		= 'AUTO';
		
		// Request the current video mute state
		DgxDeviceInfo.videoOutputPictureMute[ndx1]	= FALSE;

		// Ask for the current video output enable state
		DgxDeviceInfo.videoOutputEnabled[ndx1] 			= TRUE;

		SEND_STRING dvDgxSerial, "'SL0O', ITOA(ndx1), 'T'";
	}
#END_IF	

  // Initalize BooleanValues
  IF(DgxDeviceInfo.hasFan == TRUE)
  {
		/*
		FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.fanCount; ndx1++)
		{
			DgxDeviceInfo.fanSpeed[ndx1] = 0;
		}
		*/
		DgxDeviceInfo.fanSpeed = 0;
		DgxDeviceInfo.fanAlarm = FALSE;
	}

  IF(DgxDeviceInfo.hasTemperatureSensor)
  {
		DgxDeviceInfo.internalTemperature			= 0;
		DgxDeviceInfo.tempAlarm								= FALSE;

		// Ask for the current temperature then leave the event handler to
		// keep the value current
	}
	
	FOR(ndx1 = 1; ndx1 <= MAX_LENGTH_ARRAY(DgxDeviceInfo.PowerSupply); ndx1++)
	{
		DgxDeviceInfo.PowerSupply[ndx1] = 1;
	}

#IF_DEFINED _VIDEO_SWITCHER_MONITORING_
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.videoInputCount;ndx1++)
	{		
		// Initalize video input name
		DgxDeviceInfo.videoInputName[ndx1] =  "'Source Name ', ITOA(ndx1)";
	
		// Initalilze video input format for each port
		DgxDeviceInfo.videoInputFormat[ndx1] = "";
	}
#END_IF	
	// Update the various input/output port mapping enumerations
	UpdatePortEnums();

	devInit = TRUE;
}

(***********************************************************)
(* Name:  RequestDgxValuesUpdates                          *)
(* Args:  NONE                                             *)
(*                                                         *)
(* Desc:  For device information not managed by channel    *)
(* or level events, this method will query for the current *)
(* value.                                                  *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RequestDgxValuesUpdates()
{
	STACK_VAR INTEGER ndx1;

	//DebugVal('RequestDgxValuesUpdates', cDgxValueUpdateIndex, DEBUG_LEVEL_SUPER_CHATTY);

	// If this device does not have a valid device ID, 
	// simply return without doing anything
	IF(hasValidDeviceId == FALSE)
	{
		RETURN;
	}
	
	CLEAR_BUFFER cBufferDGX; // hackarama
	
	SWITCH (cDgxValueUpdateIndex)
	{
		CASE 1: SEND_STRING dvDgxSerial, "$03"; // Control+C to go into DGX_SHELL>
		CASE 2: SEND_STRING dvDgxSerial, "'show stats', $0d,$0a";
		CASE 3: SEND_STRING dvDgxSerial, "'bcs ~scri6v3!', $0d,$0a"; // power info
		CASE 4: SEND_STRING dvDgxSerial, "'bcs ~scri4v3!', $0d,$0a"; // board info
		DEFAULT: cDgxValueUpdateIndex = 0;
	}     
	cDgxValueUpdateIndex++

}

(***********************************************************)
(* Name: RegisterAsset                                     *)
(* Args:  RmsAsset asset data object to be registered .    *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that it is time to     *)
(*        register this asset.                             *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RegisterAsset(RmsAsset asset)
{
	
	// If this device does not have a valid device ID, 
	// simply return without doing anything
	IF(hasValidDeviceId == FALSE)
	{
		asset.assetType = 'Unknown';
		asset.description = "'Unsupported device ID: ', ITOA(devInfo.DEVICE_ID)";
	}
	ELSE
	{
		asset.assetType = MONITOR_ASSET_TYPE;
	}

	// perform registration of this
	// AMX Device as a RMS Asset
	//
	// (registering this asset as an 'AMX' asset
	// will pre-populate all available asset
	// data fields with information obtained
	// from a NetLinx DeviceInfo query.)
	RmsAssetRegisterAmxDevice(dvMonitoredDevice, asset);
}

(***********************************************************)
(* Name:  RegisterAssetMetadata                            *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that it is time to     *)
(*        register this asset's metadata properties with   *)
(*        RMS.                                             *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RegisterAssetMetadata()
{

	STACK_VAR CHAR keyName[MAX_STRING_SIZE];
	STACK_VAR CHAR propertyName[MAX_STRING_SIZE];
	STACK_VAR INTEGER ndx1;
	
	// If this device does not have a valid device ID, 
	// simply return without doing anything
	IF(hasValidDeviceId == FALSE)
	{
		RETURN;
	}
		//DgxAssetParameterSetValueBoolean(assetClientKey, "'asset.power-supply-',ITOA(cCount)", 0);

	//RmsAssetMetadataEnqueueBoolean(assetClientKey, 'asset.power.supply.1', 'Power supply 1', DgxDeviceInfo.PowerSupply[1]);
	//RmsAssetMetadataEnqueueBoolean(assetClientKey, 'asset.power.supply.2', 'Power supply 2', DgxDeviceInfo.PowerSupply[2]);

#IF_DEFINED _VIDEO_SWITCHER_MONITORING_
	RmsAssetMetadataEnqueueNumber(assetClientKey, 'switcher.input.video.count', 'Video Input Count', DgxDeviceInfo.videoInputCount);
	RmsAssetMetadataEnqueueNumber(assetClientKey, 'switcher.output.video.count', 'Video Output Count', DgxDeviceInfo.videoOutputCount);
	// Video Input Signal Format
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.videoInputCount; ndx1++)
	{
		keyName				= "'switcher.input.video.format.', ITOA(ndx1)";
		propertyName	= "'Video Input ', ITOA(ndx1), ' - Signal Format'";
		RmsAssetMetadataEnqueueString(assetClientKey, keyName, propertyName, DgxDeviceInfo.videoInputFormat[ndx1]);
	}
	// Video Input Name
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.videoInputCount; ndx1++)
	{
		keyName						= "'switcher.input.video.name.', ITOA(ndx1)";
		propertyName			= "'Video Input ', ITOA(ndx1), ' - Name'";
		RmsAssetMetadataEnqueueString(assetClientKey, keyName, propertyName, setVideoInputPortPlusNoneEnum[ndx1 + 1]);
	}
#END_IF
	// submit metadata for registration now
	RmsAssetMetadataSubmit(assetClientKey);

}

(***********************************************************)
(* Name:  RegisterAssetParameters                          *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that it is time to     *)
(*        register this asset's parameters to be monitored *)
(*        by RMS.                                          *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RegisterAssetParameters()
{
	STACK_VAR CHAR paramBooleanValue;
	STACK_VAR CHAR paramDesc[MAX_STRING_SIZE];
	STACK_VAR CHAR paramKey[MAX_STRING_SIZE];
	STACK_VAR CHAR paramName[MAX_STRING_SIZE];
	STACK_VAR CHAR sourceName[MAX_STRING_SIZE];
	STACK_VAR INTEGER ndx1;
	STACK_VAR INTEGER inputNumber;
	STACK_VAR RmsAssetParameterThreshold fanAlarmThreshold;
	STACK_VAR RmsAssetParameterThreshold temperatureAlarmThreshold;
	STACK_VAR RmsAssetParameterThreshold temperatureThreshold;

	// If this device does not have a valid device ID, 
	// simply return without doing anything
	IF(hasValidDeviceId == FALSE)
	{
		RETURN;
	}

	// register all asset monitoring parameters now.

	// register the default "Device Online" parameter
	RmsAssetOnlineParameterEnqueue (assetClientKey, DEVICE_ID(dvMonitoredDevice));

	// register asset power
	RmsAssetPowerParameterEnqueue(assetClientKey,DEVICE_ID(dvMonitoredDevice));

	IF(DgxDeviceInfo.hasTemperatureSensor)
	{
		RmsAssetParameterEnqueueNumberWithBargraph(
																								assetClientKey,
																								'asset.temperature',							// Parameter key
																								'Internal Temperature',						// Parameter name
																								'Internal temperature',						// Parameter description
																								RMS_ASSET_PARAM_TYPE_TEMPERATURE,	// RMS Asset Parameter (Reporting) Type
																								DgxDeviceInfo.internalTemperature,// Default value
																								0,																// Minimum value
																								0,																// Maximum value
																								degreesC,													// Units
																								RMS_ALLOW_RESET_NO,								// RMS Asset Parameter Reset
																								0,																// Reset value
																								RMS_TRACK_CHANGES_YES,						// RMS Asset Parameter History Tracking
																								RMS_ASSET_PARAM_BARGRAPH_TEMPERATURE											// Bargraph key
																							);

		temperatureThreshold.comparisonOperator	= RMS_ASSET_PARAM_THRESHOLD_COMPARISON_GREATER_THAN;
		temperatureThreshold.enabled						= TRUE;
		temperatureThreshold.name								= "'Operating Temperature > ', ITOA(TEMPERATURE_ALARM_THRESHOLD), 'C'";
		temperatureThreshold.notifyOnRestore		= TRUE;
		temperatureThreshold.notifyOnTrip				= TRUE;
		temperatureThreshold.statusType					= RMS_STATUS_TYPE_MAINTENANCE;
		temperatureThreshold.value							= ITOA(TEMPERATURE_ALARM_THRESHOLD);

		// Add a default threshold for the device asset temperature parameter
		RmsAssetParameterThresholdEnqueueEx(assetClientKey,'asset.temperature', temperatureThreshold);

		// Internal Temperature Alarm
		RmsAssetParameterEnqueueBoolean(
																		assetClientKey,
																		'asset.temperature.alarm',			// Parameter key
																		'Internal Temperature Alarm',		// Parameter name
																		'Internal temperature alarm',		// Parameter description
																		RMS_ASSET_PARAM_TYPE_NONE,			// RMS Asset Parameter (Reporting) Type
																		DgxDeviceInfo.tempAlarm,				// Default value
																		RMS_ALLOW_RESET_NO,							// RMS Asset Parameter Reset
																		FALSE,													// Reset value
																		RMS_TRACK_CHANGES_YES						// RMS Asset Parameter History Tracking
																	);

		temperatureAlarmThreshold.comparisonOperator	= RMS_ASSET_PARAM_THRESHOLD_COMPARISON_EQUAL;
		temperatureAlarmThreshold.delayInterval				= 0;
		temperatureAlarmThreshold.enabled							= TRUE;
		temperatureAlarmThreshold.name								= 'Temperature Alarm';
		temperatureAlarmThreshold.notifyOnRestore			= TRUE;
		temperatureAlarmThreshold.notifyOnTrip				= TRUE;
		temperatureAlarmThreshold.statusType					= RMS_STATUS_TYPE_MAINTENANCE;
		temperatureAlarmThreshold.value								= 'TRUE';

		RmsAssetParameterThresholdEnqueueEx(assetClientKey, 'asset.temperature.alarm', temperatureAlarmThreshold)
	}

	IF(DgxDeviceInfo.hasFan == TRUE)
	{
		// Fan speed
		//FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.fanCount; ndx1++)
		//{
			paramDesc			= "'Fan ', ITOA(ndx1), ' speed'";
			//paramKey			= "'asset.fan.speed.', ITOA(ndx1)";
			//paramName			= "'Fan ', ITOA(ndx1), ' Speed'";
			paramKey			= "'asset.fan.speed'";
			paramName			= "'Fan Speed'";

			RmsAssetParameterEnqueueNumber(
																			assetClientKey,
																			paramKey,										// Parameter key
																			paramName,									// Parameter name
																			paramDesc,									// Parameter description
																			RMS_ASSET_PARAM_TYPE_NONE,	// RMS Asset Parameter (Reporting) Type
																			//DgxDeviceInfo.fanSpeed[ndx1],	// Default value
																			DgxDeviceInfo.fanSpeed,	// Default value
																			0,													// Minimum value
																			0,													// Maximum value
																			'RPM',											// Units
																			RMS_ALLOW_RESET_NO,					// RMS Asset Parameter Reset
																			0,													// Reset value
																			RMS_TRACK_CHANGES_NO				// RMS Asset Parameter History Tracking
																	);
		//}

		// Fan Alarm
		RmsAssetParameterEnqueueBoolean(
																			assetClientKey,
																			'asset.fan.alarm',						// Parameter key
																			'Fan Alarm',									// Parameter name
																			'Fan alarm',									// Parameter description
																			RMS_ASSET_PARAM_TYPE_NONE,		// RMS Asset Parameter (Reporting) Type
																			DgxDeviceInfo.fanAlarm,				// Default value
																			RMS_ALLOW_RESET_YES,					// RMS Asset Parameter Reset
																			FALSE,												// Reset value
																			RMS_TRACK_CHANGES_YES					// RMS Asset Parameter History Tracking
																	);

		fanAlarmThreshold.comparisonOperator	= RMS_ASSET_PARAM_THRESHOLD_COMPARISON_EQUAL;
		fanAlarmThreshold.delayInterval				= 0;
		fanAlarmThreshold.enabled							= TRUE;
		fanAlarmThreshold.name								= 'Alarm is TRUE';
		fanAlarmThreshold.notifyOnRestore			= TRUE;
		fanAlarmThreshold.notifyOnTrip				= TRUE;
		fanAlarmThreshold.statusType					= RMS_STATUS_TYPE_MAINTENANCE;
		fanAlarmThreshold.value								= 'TRUE';

		// add a default threshold for the device fan alarm parameter
		RmsAssetParameterThresholdEnqueueEx(assetClientKey, 'asset.fan.alarm', fanAlarmThreshold)

	}
#IF_DEFINED _VIDEO_SWITCHER_MONITORING_
	// Video Output Picture Mute
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.videoOutputCount; ndx1++)
	{
		paramBooleanValue	= DgxDeviceInfo.videoOutputPictureMute[ndx1];
		paramDesc					= "'Video output ', ITOA(ndx1), ' picture mute'";
		paramKey					= "'switcher.output.video.mute.', ITOA(ndx1)";
		paramName					= "'Video Output ', ITOA(ndx1), ' - Picture Mute'";

		RmsAssetParameterEnqueueBoolean(
																			assetClientKey,
																			paramKey,										// Parameter key
																			paramName,									// Parameter name
																			paramDesc,									// Parameter description
																			RMS_ASSET_PARAM_TYPE_NONE,	// RMS Asset Parameter (Reporting) Type
																			paramBooleanValue,					// Default value
																			RMS_ALLOW_RESET_NO,					// RMS Asset Parameter Reset
																			FALSE,											// Reset value
																			RMS_TRACK_CHANGES_NO				// RMS Asset Parameter History Tracking
																		);
	}

	// Video Output Scaling Mode
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.videoOutputCount; ndx1++)
	{
		paramDesc						= "'Video output ', ITOA(ndx1), ' scaling mode'";
		paramKey						= "'switcher.output.video.scale.mode.', ITOA(ndx1)";
		paramName						= "'Video Output ', ITOA(ndx1), ' - Scaling Mode'";
		RmsAssetParameterEnqueueEnumeration(
																				assetClientKey,
																				paramKey,										// Parameter key
																				paramName,									// Parameter name
																				paramDesc,									// Parameter description
																				RMS_ASSET_PARAM_TYPE_NONE,	// RMS Asset Parameter (Reporting) Type
																				DgxDeviceInfo.videoOutputScaleMode[ndx1],				// Default value
																				SET_VIDEO_OUTOUT_SCALING_MODE_ENUM,	// Enumeration
																				RMS_ALLOW_RESET_NO,					// RMS Asset Parameter Reset
																				'',													// Reset value
																				RMS_TRACK_CHANGES_NO				// RMS Asset Parameter History Tracking
																			);
	}

	// Video Output Selected Source
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.videoOutputCount; ndx1++)
	{
		paramDesc		= "'Video output ', ITOA(ndx1), ' selected source'"
		paramKey		= "'switcher.output.video.switch.input.', ITOA(ndx1)";
		paramName		= "'Video Output ', ITOA(ndx1), ' - Selected Source'";
		inputNumber	= DgxDeviceInfo.videoOutputSelectedSource[ndx1];
		
		// Get the input source name or say None if not connected
		IF(inputNumber > 0)
		{
			 sourceName = setVideoInputPortPlusNoneEnum[inputNumber + 1];
		}
		ELSE
		{
			sourceName = NO_INPUTS_MSG;
		}

		RmsAssetParameterEnqueueString(
																		assetClientKey,
																		paramKey,										// Parameter key
																		paramName,									// Parameter name
																		paramDesc,									// Parameter description
																		RMS_ASSET_PARAM_TYPE_NONE,	// RMS Asset Parameter (Reporting) Type
																		sourceName,									// Default value
																		'',													// Units
																		RMS_ALLOW_RESET_NO,					// RMS Asset Parameter Reset
																		'',													// Reset value
																		RMS_TRACK_CHANGES_NO				// RMS Asset Parameter History Tracking
																	);
	}
#END_IF

	// Power supply
	FOR(ndx1 = 1; ndx1 <= MAX_LENGTH_ARRAY(DgxDeviceInfo.PowerSupply); ndx1++)
	{
		paramBooleanValue	= DgxDeviceInfo.PowerSupply[ndx1];
		paramDesc					= "'Power supply ', ITOA(ndx1)";
		paramKey					= "'asset.power.supply.', ITOA(ndx1)";
		paramName					= "'Power supply ', ITOA(ndx1)";

		RmsAssetParameterEnqueueBoolean(
																			assetClientKey,
																			paramKey,										// Parameter key
																			paramName,									// Parameter name
																			paramDesc,									// Parameter description
																			RMS_ASSET_PARAM_TYPE_NONE,	// RMS Asset Parameter (Reporting) Type
																			paramBooleanValue,					// Default value
																			RMS_ALLOW_RESET_NO,					// RMS Asset Parameter Reset
																			FALSE,											// Reset value
																			RMS_TRACK_CHANGES_YES				// RMS Asset Parameter History Tracking
																		);
	}
	
	// number of input boards
	paramDesc			= "'Number of Input boards'";
	paramKey			= "'switcher.input.video.board.count'";
	paramName			= "'Input boards'";

	RmsAssetParameterEnqueueNumber(
																	assetClientKey,
																	paramKey,										// Parameter key
																	paramName,									// Parameter name
																	paramDesc,									// Parameter description
																	RMS_ASSET_PARAM_TYPE_NONE,	// RMS Asset Parameter (Reporting) Type
																	//DgxDeviceInfo.fanSpeed[ndx1],	// Default value
																	DgxDeviceInfo.cNumInputBoards,	// Default value
																	0,													// Minimum value
																	0,													// Maximum value
																	'',													// Units
																	RMS_ALLOW_RESET_NO,					// RMS Asset Parameter Reset
																	0,													// Reset value
																	RMS_TRACK_CHANGES_NO				// RMS Asset Parameter History Tracking
															);

	// Input boards
	FOR(ndx1 = 1; ndx1 <= MAX_LENGTH_ARRAY(DgxDeviceInfo.uInputBoard); ndx1++)
	{
		paramDesc					= "'Input board ', ITOA(ndx1)";
		paramKey					= "'switcher.input.video.board.', ITOA(ndx1)";
		paramName					= "'Input board ', ITOA(ndx1)";
		RmsAssetParameterEnqueueNumber(
																		assetClientKey,
																		paramKey,										// Parameter key
																		paramName,									// Parameter name
																		paramDesc,									// Parameter description
																		RMS_ASSET_PARAM_TYPE_NONE,	// RMS Asset Parameter (Reporting) Type
																		DgxDeviceInfo.uInputBoard[ndx1].nStatus,	// Default value
																		0,													// Minimum value
																		0,													// Maximum value
																		'',													// Units
																		RMS_ALLOW_RESET_NO,					// RMS Asset Parameter Reset
																		0,													// Reset value
																		RMS_TRACK_CHANGES_YES				// RMS Asset Parameter History Tracking
																		);
	}

	// Input boards - inputs
	FOR(ndx1 = 1; ndx1 <= MAX_LENGTH_ARRAY(DgxDeviceInfo.uInputBoard); ndx1++)
	{
		FOR(inputNumber = 1; inputNumber <= MAX_LENGTH_ARRAY(DgxDeviceInfo.uInputBoard[1].uChannel); inputNumber++)
		{
			paramBooleanValue	= DgxDeviceInfo.uInputBoard[ndx1].uChannel[inputNumber].cLink;
			paramDesc					= "'Input board ', ITOA(ndx1), ' input ', ITOA(inputNumber)";
			paramKey					= "'switcher.input.video.board.', ITOA(ndx1), '.input.', ITOA(inputNumber)";
			paramName					= "'Input board ', ITOA(ndx1), ' input ', ITOA(inputNumber)";
	
		RmsAssetParameterEnqueueBoolean(
																			assetClientKey,
																			paramKey,										// Parameter key
																			paramName,									// Parameter name
																			paramDesc,									// Parameter description
																			RMS_ASSET_PARAM_TYPE_NONE,	// RMS Asset Parameter (Reporting) Type
																			paramBooleanValue,					// Default value
																			RMS_ALLOW_RESET_NO,					// RMS Asset Parameter Reset
																			FALSE,											// Reset value
																			RMS_TRACK_CHANGES_NO				// RMS Asset Parameter History Tracking
																		);
		}
	}

	
	// number of output boards
	paramDesc			= "'Number of Output boards'";
	paramKey			= "'switcher.output.video.board.count'";
	paramName			= "'Output boards'";

	RmsAssetParameterEnqueueNumber(
																	assetClientKey,
																	paramKey,										// Parameter key
																	paramName,									// Parameter name
																	paramDesc,									// Parameter description
																	RMS_ASSET_PARAM_TYPE_NONE,	// RMS Asset Parameter (Reporting) Type
																	//DgxDeviceInfo.fanSpeed[ndx1],	// Default value
																	DgxDeviceInfo.cNumInputBoards,	// Default value
																	0,													// Minimum value
																	0,													// Maximum value
																	'',													// Units
																	RMS_ALLOW_RESET_NO,					// RMS Asset Parameter Reset
																	0,													// Reset value
																	RMS_TRACK_CHANGES_NO				// RMS Asset Parameter History Tracking
															);

	// Output boards
	FOR(ndx1 = 1; ndx1 <= MAX_LENGTH_ARRAY(DgxDeviceInfo.uOutputBoard); ndx1++)
	{
		paramDesc					= "'Output board ', ITOA(ndx1)";
		paramKey					= "'switcher.output.video.board.', ITOA(ndx1)";
		paramName					= "'Output board ', ITOA(ndx1)";

		RmsAssetParameterEnqueueNumber(
																		assetClientKey,
																		paramKey,										// Parameter key
																		paramName,									// Parameter name
																		paramDesc,									// Parameter description
																		RMS_ASSET_PARAM_TYPE_NONE,	// RMS Asset Parameter (Reporting) Type
																		DgxDeviceInfo.uOutputBoard[ndx1].nStatus,	// Default value
																		0,													// Minimum value
																		0,													// Maximum value
																		'',													// Units
																		RMS_ALLOW_RESET_NO,					// RMS Asset Parameter Reset
																		0,													// Reset value
																		RMS_TRACK_CHANGES_YES				// RMS Asset Parameter History Tracking
																		);
	}

	// Output boards - outputs
	FOR(ndx1 = 1; ndx1 <= MAX_LENGTH_ARRAY(DgxDeviceInfo.uOutputBoard); ndx1++)
	{
		FOR(inputNumber = 1; inputNumber <= MAX_LENGTH_ARRAY(DgxDeviceInfo.uOutputBoard[1].uChannel); inputNumber++)
		{
			paramBooleanValue	= DgxDeviceInfo.uOutputBoard[ndx1].uChannel[inputNumber].cLink;
			paramDesc					= "'Output board ', ITOA(ndx1), ' output ', ITOA(inputNumber)";
			paramKey					= "'switcher.output.video.board.', ITOA(ndx1), '.output.', ITOA(inputNumber)";
			paramName					= "'Output board ', ITOA(ndx1), ' output ', ITOA(inputNumber)";
	
		RmsAssetParameterEnqueueBoolean(
																			assetClientKey,
																			paramKey,										// Parameter key
																			paramName,									// Parameter name
																			paramDesc,									// Parameter description
																			RMS_ASSET_PARAM_TYPE_NONE,	// RMS Asset Parameter (Reporting) Type
																			paramBooleanValue,					// Default value
																			RMS_ALLOW_RESET_NO,					// RMS Asset Parameter Reset
																			FALSE,											// Reset value
																			RMS_TRACK_CHANGES_NO				// RMS Asset Parameter History Tracking
																		);
		}
	}
	// submit all parameter registrations
	RmsAssetParameterSubmit(assetClientKey);
}

(***********************************************************)
(* Name:  RegisterAssetControlMethods                      *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that it is time to     *)
(*        register this asset's control methods with RMS.  *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RegisterAssetControlMethods()
{
		
	// If this device does not have a valid device ID, 
	// simply return without doing anything
	IF(hasValidDeviceId == FALSE)
	{
		RETURN;
	}
	
	// Make sure the port selection enumerations are up to date
/*	
	UpdatePortEnums();
	RmsAssetControlMethodEnqueue(
																	assetClientKey,
																	'asset.power',
																	'Set Power',
																	'Set Power (ON|OFF=STANDBY)');

	RmsAssetControlMethodArgumentEnumEx(
																			assetClientKey,
																			'asset.power',
																			0,
																			'Set Power',
																			'Set power mode',
																			setPowerEnum[2],
																			setPowerEnum);
*/
#IF_DEFINED _VIDEO_SWITCHER_MONITORING_
	RmsAssetControlMethodEnqueue(
																assetClientKey,
																'switcher.output.video.switch',
																'Select Video Source',
																'Select video source');

	RmsAssetControlMethodArgumentEnumEx(
																			assetClientKey,
																			'switcher.output.video.switch',
																			0,
																			'Output Port',
																			'Output port select',
																			setVideoOutputPortPlusAllEnum[1],
																			setVideoOutputPortPlusAllEnum);

	RmsAssetControlMethodArgumentEnumEx(
																			assetClientKey,
																			'switcher.output.video.switch',
																			1,
																			'Input Port',
																			"'Input port [', NO_INPUTS_MSG, ' = No Input]'",
																			setVideoInputPortPlusNoneEnum[1],
																			setVideoInputPortPlusNoneEnum);

	RmsAssetControlMethodEnqueue(
																assetClientKey,
																'switcher.output.video.mute',
																'Set Video Mute',
																'Set video mute');

	RmsAssetControlMethodArgumentEnumEx(
																			assetClientKey,
																			'switcher.output.video.mute',
																			0,
																			'Output Port',
																			'Output Port',
																			setVideoOutputPortPlusAllEnum[1],
																			setVideoOutputPortPlusAllEnum);

	RmsAssetControlMethodArgumentBoolean(
																				assetClientKey,
																				'switcher.output.video.mute',
																				1,
																				'Enabled',
																				'Enabled',
																				FALSE);
#END_IF

	// when finished enqueuing all asset control methods and
	// arguments for this asset, we just need to submit
	// them to finalize and register them with the RMS server
	RmsAssetControlMethodsSubmit(assetClientKey);
}

(***********************************************************)
(* Name:  SynchronizeAssetMetadata                         *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that it is time to     *)
(*        update/synchronize this asset metadata properties *)
(*        with RMS if needed.                              *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION SynchronizeAssetMetadata()
{

	STACK_VAR CHAR keyName[MAX_STRING_SIZE];
	STACK_VAR INTEGER ndx1;
	
	// If this device does not have a valid device ID, 
	// simply return without doing anything
	IF(hasValidDeviceId == FALSE)
	{
		RETURN;
	}
#IF_DEFINED _VIDEO_SWITCHER_MONITORING_
	RmsAssetMetadataUpdateNumber(assetClientKey, 'switcher.input.video.count', DgxDeviceInfo.videoInputCount);
	RmsAssetMetadataUpdateNumber(assetClientKey, 'switcher.output.video.count', DgxDeviceInfo.videoOutputCount);

	// Video Input Signal Format for source which support only HDMI formats
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.videoInputCount; ndx1++)
	{
		keyName = "'switcher.input.video.format.', ITOA(ndx1)";
		RmsAssetMetadataUpdateString(assetClientKey, keyName, DgxDeviceInfo.videoInputFormat[ndx1]);
	}

	// Video Input Name
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.videoInputCount; ndx1++)
	{
		keyName						= "'switcher.input.video.name.', ITOA(ndx1)";
		RmsAssetMetadataUpdateString(assetClientKey, keyName, setVideoInputPortPlusNoneEnum[ndx1 + 1]);
	}
#END_IF
}

(***********************************************************)
(* Name:  SyncVideoOutputSource                            *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  Called to synchronize video output selected      *)
(* source                                                  *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION SyncVideoOutputSource()
{
#IF_DEFINED _VIDEO_SWITCHER_MONITORING_
	STACK_VAR CHAR sourceName[MAX_STRING_SIZE];
	STACK_VAR INTEGER indx1;
	STACK_VAR INTEGER inputNumber;

	UpdatePortEnums();

	// Video Output Selected Source
	FOR(indx1 = 1; indx1 <= DgxDeviceInfo.videoOutputCount; indx1++)
	{
		inputNumber = DgxDeviceInfo.videoOutputSelectedSource[indx1];
		// The the video input source name or say NO_INPUTS_MSG if not connected
		IF(inputNumber > 0)
		{
			sourceName = setVideoInputPortPlusNoneEnum[inputNumber + 1];
		}
		ELSE
		{
			sourceName = NO_INPUTS_MSG;
		}
		DgxAssetParameterSetValue(assetClientKey, "'switcher.output.video.switch.input.', ITOA(indx1)", sourceName);
	}
#END_IF
}

(***********************************************************)
(* Name:  SynchronizeAssetParameters                       *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that it is time to     *)
(*        update/synchronize this asset parameter values   *)
(*        with RMS.                                        *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION SynchronizeAssetParameters()
{
	STACK_VAR CHAR paramKey[MAX_STRING_SIZE];
	STACK_VAR INTEGER ndx1 INTEGER ndx2;
	
	// If this device does not have a valid device ID, 
	// simply return without doing anything
	IF(hasValidDeviceId == FALSE)
	{
		RETURN;
	}

	// update device online parameter value
	RmsAssetOnlineParameterUpdate(assetClientKey, DEVICE_ID(dvMonitoredDevice));

	// update asset power parameter value
	//RmsAssetPowerParameterUpdate(assetClientKey,DEVICE_ID(dvMonitoredDevice));

	IF(DgxDeviceInfo.hasTemperatureSensor)
	{
		paramKey = 'asset.temperature';
		RmsAssetParameterEnqueueSetValueNumber(assetClientKey, paramKey, DgxDeviceInfo.internalTemperature);

		paramKey = 'asset.temperature.alarm';
		RmsAssetParameterEnqueueSetValueBoolean(assetClientKey, paramKey, DgxDeviceInfo.tempAlarm);
	}

  // If fans exist, update information which has changed
  IF(DgxDeviceInfo.hasFan == TRUE)
  {
	/*
		FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.fanCount; ndx1++)
		{
			paramKey = "'asset.fan.speed.', ITOA(ndx1)";
			RmsAssetParameterEnqueueSetValueNumber(assetClientKey, paramKey, DgxDeviceInfo.fanSpeed[ndx1]);
		}
	*/
		paramKey = "'asset.fan.speed'";
		RmsAssetParameterEnqueueSetValueNumber(assetClientKey, paramKey, DgxDeviceInfo.fanSpeed);

		RmsAssetParameterEnqueueSetValueBoolean(assetClientKey, 'asset.fan.alarm', DgxDeviceInfo.fanAlarm);
  }

#IF_DEFINED _VIDEO_SWITCHER_MONITORING_
	// Sync video output parameters
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.videoOutputCount; ndx1++)
	{
		paramKey = "'switcher.output.video.mute.', ITOA(ndx1)";
		RmsAssetParameterEnqueueSetValueBoolean(assetClientKey, paramKey, DgxDeviceInfo.videoOutputPictureMute[ndx1]);

		paramKey = "'switcher.output.video.scale.mode.', ITOA(ndx1)";;
		RmsAssetParameterEnqueueSetValue(assetClientKey, paramKey, DgxDeviceInfo.videoOutputScaleMode[ndx1]);
  }
#END_IF

	// power supplies
	FOR(ndx1 = 1; ndx1 <= MAX_LENGTH_ARRAY(DgxDeviceInfo.PowerSupply); ndx1++)
	{
		paramKey = "'power.supply.', ITOA(ndx1)";
		RmsAssetParameterEnqueueSetValueBoolean(assetClientKey, paramKey, DgxDeviceInfo.PowerSupply[ndx1]);
  }
	
	paramKey = "'switcher.input.video.board.count'";
	RmsAssetParameterEnqueueSetValueNumber(assetClientKey, paramKey, DgxDeviceInfo.cNumInputBoards);

	// input boards
	FOR(ndx1 = 1; ndx1 <= MAX_LENGTH_ARRAY(DgxDeviceInfo.uInputBoard); ndx1++)
	{
		paramKey = "'switcher.input.video.board.', ITOA(ndx1)";
		RmsAssetParameterEnqueueSetValueNumber(assetClientKey, paramKey, DgxDeviceInfo.uInputBoard[ndx1].nStatus);
  }
	
	// input board inputs
	FOR(ndx1 = 1; ndx1 <= MAX_LENGTH_ARRAY(DgxDeviceInfo.uInputBoard); ndx1++)
	{
		FOR(ndx2 = 1; ndx2 <= MAX_LENGTH_ARRAY(DgxDeviceInfo.uInputBoard[1].uChannel); ndx2++)
		{
			paramKey = "'switcher.input.video.board.', ITOA(ndx1), '.input.', ITOA(ndx2)";
			RmsAssetParameterEnqueueSetValue(assetClientKey, paramKey, DgxDeviceInfo.uInputBoard[ndx1].uChannel[ndx2].cLink);
		}
  }
	
	
	paramKey = "'switcher.output.video.board.count'";
	RmsAssetParameterEnqueueSetValueNumber(assetClientKey, paramKey, DgxDeviceInfo.cNumOutputBoards);

	// output boards
	FOR(ndx1 = 1; ndx1 <= MAX_LENGTH_ARRAY(DgxDeviceInfo.uOutputBoard); ndx1++)
	{
		paramKey = "'switcher.output.video.board.', ITOA(ndx1)";
		RmsAssetParameterEnqueueSetValueNumber(assetClientKey, paramKey, DgxDeviceInfo.uOutputBoard[ndx1].nStatus);
  }
	
	// output board inputs
	FOR(ndx1 = 1; ndx1 <= MAX_LENGTH_ARRAY(DgxDeviceInfo.uOutputBoard); ndx1++)
	{
		FOR(ndx2 = 1; ndx2 <= MAX_LENGTH_ARRAY(DgxDeviceInfo.uOutputBoard[1].uChannel); ndx2++)
		{
			paramKey = "'switcher.output.video.board.', ITOA(ndx1), '.output.', ITOA(ndx2)";
			RmsAssetParameterEnqueueSetValue(assetClientKey, paramKey, DgxDeviceInfo.uOutputBoard[ndx1].uChannel[ndx2].cLink);
		}
  }
  // submit all the pending parameter updates now
  RmsAssetParameterUpdatesSubmit(assetClientKey);

	// These methods do not queue changes but simply perform an update
	SyncVideoOutputSource();
}

(***********************************************************)
(* Name:  SystemModeChanged                                *)
(* Args:  modeName - string value representing mode change *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that the SYSTEM MODE   *)
(*        state has changed states.                        *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION SystemModeChanged(CHAR modeName[])
{
}

(***********************************************************)
(* Name:  SystemPowerChanged                               *)
(* Args:  powerOn - boolean value representing ON/OFF      *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that the SYSTEM POWER  *)
(*        state has changed states.                        *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION SystemPowerChanged(CHAR powerOn)
{
}

(***********************************************************)
(* Name:  ResetAssetParameterValue                         *)
(* Args:  parameterKey   - unique parameter key identifier *)
(*        parameterValue - new parameter value after reset *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that an asset          *)
(*        parameter value has been reset by the RMS server *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION ResetAssetParameterValue(CHAR parameterKey[],CHAR parameterValue[])
{
}

(***********************************************************)

(***********************************************************)
DEFINE_FUNCTION NotifyDGXMissingBoard(CHAR strNotice[], CHAR cCount)
{
	SEND_STRING 0, "strNotice, ITOA(cCount)";
}
DEFINE_FUNCTION NotifyDGXPowerFail(CHAR strNotice[], CHAR cCount)
{
	SEND_STRING 0, "strNotice, ITOA(cCount)";
}
DEFINE_FUNCTION NotifyDGXUnlinked(INTEGER nBoard, INTEGER nChan)
{
	SEND_STRING 0, "'No link on board ', ITOA(nBoard), ', Channel ', ITOA(nChan)";
}

DEFINE_FUNCTION RemoveFromDGXBuffer(INTEGER nStartPos, INTEGER nEndPos)
{
	cBufferDGX = "LEFT_STRING(cBufferDGX,nStartPos-1), RIGHT_STRING(cBufferDGX, LENGTH_STRING(cBufferDGX)-nEndPos-1)";
}

DEFINE_FUNCTION DiscardFromDGXBuffer(CHAR strTemp[])
{
	IF(FIND_STRING(cBufferDGX, strTemp, 1))
		cBufferDGX = RIGHT_STRING(cBufferDGX, LENGTH_STRING(cBufferDGX)-LENGTH_STRING(strTemp));
}

DEFINE_FUNCTION	CHAR[MAX_BUFFER_SIZE] ParseDGXSplashScreen(INTEGER nCount, INTEGER nStartPos) // Response from '~scrv?i?!' (verbosity ?, component ?)
// "~scrv3i<n>![<n>:' .. '[<n+1>' (or to end of string)
{
	LOCAL_VAR INTEGER nStartPos_ INTEGER nMidPos_;
	LOCAL_VAR CHAR sTemp_[MAX_BUFFER_SIZE];
	// Remove '~scrv*i*!'
	sTemp_ = "'~scr'"; 
	nStartPos_ = FIND_STRING(cBufferDGX, sTemp_, nStartPos);
	IF(nStartPos_) // Found '~scr'
	{
		nMidPos_ = nStartPos_+LENGTH_STRING(sTemp_);
		sTemp_ = "'['"; 
		nMidPos_ = FIND_STRING(cBufferDGX, sTemp_, nMidPos_);
		IF(!nMidPos_)
		{
			sTemp_ = "'!'"; 
			nMidPos_ = FIND_STRING(cBufferDGX, sTemp_, nStartPos_);
		}
		IF(nMidPos_ >= nStartPos_ + 9);//LENGTH_STRING('~scrv*i*!'))
		{
			IF((nMidPos_ - nStartPos_) < 20) // just make sure we don't delete an entire section
				RemoveFromDGXBuffer(nStartPos_, nMidPos_-2); // don't remove the '['
		}
	}
	// Remove section from '[n:'...'['
	sTemp_ = "'[', ITOA(nCount)	,':'"; 
	IF(!nStartPos_)
		nStartPos_ = 1;
	nStartPos_ = FIND_STRING(cBufferDGX, sTemp_, nStartPos_);
	IF(nStartPos_) // Found strTemp_
	{
		nMidPos_ = nStartPos_+LENGTH_STRING(sTemp_);
		sTemp_ = "'[', ITOA(nCount+1)	,':'"; 
		nMidPos_ = FIND_STRING(cBufferDGX, sTemp_, nMidPos_);
		IF(!nMidPos_)
			nMidPos_ = LENGTH_STRING(cBufferDGX)+1;
		sTemp_ = MID_STRING(cBufferDGX, nStartPos_, nMidPos_-nStartPos_-1);
		RemoveFromDGXBuffer(nStartPos_, nMidPos_-2); // don't remove the '['
		RETURN sTemp_;
	}
	ELSE RETURN '';
}

DEFINE_FUNCTION ParseDGXSplashScreen1(CHAR sTemp[]) // ~scrv3i1! [1:Enclosure]
{
	DebugString('ParseDGXSplashScreen1', sTemp, DEBUG_LEVEL_SUPER_CHATTY);
}

DEFINE_FUNCTION ParseDGXSplashScreen2(CHAR sTemp[]) // ~scrv3i2!
{
	DebugString('ParseDGXSplashScreen2', sTemp, DEBUG_LEVEL_SUPER_CHATTY);
}
DEFINE_FUNCTION ParseDGXSplashScreen3(CHAR sTemp[]) // ~scrv3i3!
{
	DebugString('ParseDGXSplashScreen3', sTemp, DEBUG_LEVEL_SUPER_CHATTY);
}

DEFINE_FUNCTION ParseDGXSplashScreen4(CHAR sTemp[]) // ~scrv3i4! [4:Hardware Boards]
{
	STACK_VAR CHAR sTemp_[MAX_BUFFER_SIZE] CHAR sTemp2_[100] CHAR sJunk_[20];
	STACK_VAR CHAR cCount_ INTEGER nVal_;
	//'[input boards]' .. '[output boards]'
	DebugString('ParseDGXSplashScreen4', sTemp, DEBUG_LEVEL_SUPER_CHATTY);
	sTemp_ = GetSubString(sTemp, '[input boards] count', '[output boards]', DONT_REMOVE_DATA);
	sTemp2_ = GetSubString(sTemp_, '[board ', "$0d", REMOVE_DATA_UP_TO_AND_INC_SEARCH);
	WHILE(LENGTH_STRING(sTemp2_))
	{
		cCount_ = ATOI(sTemp2_); // board number
		sJunk_ = REMOVE_STRING(sTemp2_, ']', 1);
		DebugString("'Input Board number ', ITOA(cCount_)", sTemp2_, DEBUG_LEVEL_SUPER_CHATTY);		
		nVal_		= AHTOI(sTemp2_); // board version - 0000 = no board
		IF(DgxDeviceInfo.uInputBoard[cCount_].nStatus <> nVal_)
		{
			DgxDeviceInfo.uInputBoard[cCount_].nStatus = nVal_;
			DgxAssetParameterSetValueNumber(assetClientKey, "'switcher.input.video.board.', ITOA(DgxDeviceInfo.uInputBoard[cCount_].nStatus)", DgxDeviceInfo.uInputBoard[cCount_].nStatus);
		}
		sTemp2_ = GetSubString(sTemp_, '[board ', "$0d", REMOVE_DATA_UP_TO_AND_INC_SEARCH);
	}
	
	//'[input boards] count'
	sTemp_ = GetSubString(sTemp, '[input boards] count', "$0d", REMOVE_DATA_INC_SEARCH);
	IF(LENGTH_STRING(sTemp_))
	{
		IF(DgxDeviceInfo.cNumInputBoards <> ATOI(sTemp_))
		{
			DgxDeviceInfo.cNumInputBoards = ATOI(sTemp_);
			DgxAssetParameterSetValueNumber(assetClientKey, 'switcher.input.video.board.count', DgxDeviceInfo.cNumInputBoards);
		}
		DebugVal('NumInputBoards', DgxDeviceInfo.cNumInputBoards, DEBUG_LEVEL_STANDARD);
	}
	
	//'[output boards]' .. '[output boards]'
	sTemp_ = GetSubString(sTemp, '[output boards] count', '[expansion boards]', DONT_REMOVE_DATA);
	sTemp2_ = GetSubString(sTemp_, '[board ', "$0d", REMOVE_DATA_UP_TO_AND_INC_SEARCH);
	WHILE(LENGTH_STRING(sTemp2_))
	{
		cCount_ = ATOI(sTemp2_)-MAX_VIDEO_INPUT_CNT/4; // board 4 on an 8x8 is output board 2. 4-8/4=2
		sJunk_ = REMOVE_STRING(sTemp2_, ']', 1);
		DebugString("'output board number ', ITOA(cCount_)", sTemp2_, DEBUG_LEVEL_SUPER_CHATTY);		
		nVal_		= AHTOI(sTemp2_); // board version - 0000 = no board
		IF(DgxDeviceInfo.uOutputBoard[cCount_].nStatus <> nVal_)
		{
			DgxDeviceInfo.uOutputBoard[cCount_].nStatus = nVal_;
			DgxAssetParameterSetValueNumber(assetClientKey, "'switcher.output.video.board.', ITOA(DgxDeviceInfo.uOutputBoard[cCount_].nStatus)", DgxDeviceInfo.uOutputBoard[cCount_].nStatus);
		}
		sTemp2_ = GetSubString(sTemp_, '[board ', "$0d", REMOVE_DATA_UP_TO_AND_INC_SEARCH);
	}
	
	//'[output boards] count'
	sTemp_ = GetSubString(sTemp, '[output boards] count', "$0d", REMOVE_DATA_INC_SEARCH);
	IF(LENGTH_STRING(sTemp_))
	{
		IF(DgxDeviceInfo.cNumOutputBoards <> ATOI(sTemp_))
		{
			DgxDeviceInfo.cNumOutputBoards = ATOI(sTemp_);
			DgxAssetParameterSetValueNumber(assetClientKey, 'switcher.output.video.board.count', DgxDeviceInfo.cNumOutputBoards);
		}
		DebugVal('NumOutputBoards', DgxDeviceInfo.cNumOutputBoards, DEBUG_LEVEL_STANDARD);
	}
}

DEFINE_FUNCTION ParseDGXSplashScreen5(CHAR sTemp[]) // ~scrv3i5! [5:VM Configuration]
{
	DebugString('ParseDGXSplashScreen5', sTemp, DEBUG_LEVEL_SUPER_CHATTY);
}

DEFINE_FUNCTION ParseDGXSplashScreen6(CHAR sTemp[]) // ~scrv3i6! [6:Power System]
{
	STACK_VAR CHAR sTemp_[MAX_BUFFER_SIZE] CHAR sTemp2_[100];
	STACK_VAR CHAR cCount_ INTEGER nVal_;
	DebugString('ParseDGXSplashScreen6', sTemp, DEBUG_LEVEL_SUPER_CHATTY);
// If power removed 
//	'[ac power slot 2] good' doesn't exist
//[6:Power System] warning
//    [status flags] 0x0001
	sTemp_ = GetSubString(sTemp, '[fan speed]', "$0d", REMOVE_DATA_INC_SEARCH);
	//DebugString('fan speed', sTemp_, DEBUG_LEVEL_SUPER_CHATTY);
	IF(LENGTH_STRING(sTemp_))
	{
		nVal_ = ATOI(sTemp_);
		IF(DgxDeviceInfo.fanSpeed <> nVal_)
		{
			DgxDeviceInfo.fanSpeed = nVal_;
			DgxAssetParameterSetValueNumber(assetClientKey, "'switcher.fan.speed'", DgxDeviceInfo.fanSpeed);
			DebugVal("'fanSpeed update'", DgxDeviceInfo.fanSpeed, DEBUG_LEVEL_STANDARD);
		}
		DebugVal("'fanSpeed'", DgxDeviceInfo.fanSpeed, DEBUG_LEVEL_CHATTY);
	}

	sTemp_ = GetSubString(sTemp, '[available system power]', "$0d", REMOVE_DATA_INC_SEARCH);
	//DebugString('available system power', sTemp_, DEBUG_LEVEL_SUPER_CHATTY);
	IF(LENGTH_STRING(sTemp_))
	{
		nVal_ = ATOI(sTemp_);
		IF(DgxDeviceInfo.PowerAvailable <> nVal_)
		{
			DgxDeviceInfo.PowerAvailable = nVal_;
			DgxAssetParameterSetValueNumber(assetClientKey, "'switcher.power.available'", DgxDeviceInfo.PowerAvailable);
			DebugVal("'PowerAvailable update'", DgxDeviceInfo.PowerAvailable, DEBUG_LEVEL_STANDARD);
		}
		DebugVal("'PowerAvailable'", DgxDeviceInfo.PowerAvailable, DEBUG_LEVEL_CHATTY);
	}

	sTemp_ = GetSubString(sTemp, '[required system power]', "$0d", REMOVE_DATA_INC_SEARCH);
	//DebugString('required system power', sTemp_, DEBUG_LEVEL_SUPER_CHATTY);
	IF(LENGTH_STRING(sTemp_))
	{
		nVal_ = ATOI(sTemp_);
		IF(DgxDeviceInfo.PowerRequired <> nVal_)
		{
			DgxDeviceInfo.PowerRequired = nVal_;
			DgxAssetParameterSetValueNumber(assetClientKey, "'switcher.power.required'", DgxDeviceInfo.PowerRequired);
			DebugVal("'PowerRequired update'", DgxDeviceInfo.PowerRequired, DEBUG_LEVEL_STANDARD);
		}
		DebugVal("'PowerRequired'", DgxDeviceInfo.PowerRequired, DEBUG_LEVEL_CHATTY);
	}

// can't just pick a sub string out because there is no guarantee of the next 
	sTemp_ = '[ac power slot 1] good'
	nVal_ = (FIND_STRING(sTemp_,sTemp_,1) != 0);
	DebugVal("'PowerSupply[1] in'", nVal_, DEBUG_LEVEL_CHATTY);
	DebugVal("'PowerSupply[1] cur'", DgxDeviceInfo.PowerSupply[1], DEBUG_LEVEL_CHATTY);
	IF(DgxDeviceInfo.PowerSupply[1] != nVal_)
	{
		DebugVal('ParseDGXData: PowerSupply[1]', DgxDeviceInfo.PowerSupply[1], DEBUG_LEVEL_STANDARD);
		DgxDeviceInfo.PowerSupply[1] = TYPE_CAST(nVal_);
		DgxAssetParameterSetValueBoolean(assetClientKey, 'asset.power.supply.1', DgxDeviceInfo.PowerSupply[1]);
	}

	sTemp_ = '[ac power slot 2] good'
	nVal_ = (FIND_STRING(sTemp,sTemp_,1) != 0);
	DebugVal("'PowerSupplyX[2] in'", nVal_, DEBUG_LEVEL_STANDARD);
	DebugVal("'PowerSupply[2] cur'", DgxDeviceInfo.PowerSupply[2], DEBUG_LEVEL_STANDARD);
	IF(DgxDeviceInfo.PowerSupply[2] != nVal_)
	{
		DebugVal('ParseDGXData: PowerSupply[2]', DgxDeviceInfo.PowerSupply[2], DEBUG_LEVEL_CHATTY);
		DgxDeviceInfo.PowerSupply[2] = TYPE_CAST(nVal_);
		DgxAssetParameterSetValueBoolean(assetClientKey, 'asset.power.supply.2', DgxDeviceInfo.PowerSupply[2]);
	}
}

DEFINE_FUNCTION ParseDGXSplashScreen7(CHAR sTemp[]) // ~scrv3i7! [7:System Sensors]
{
	STACK_VAR CHAR sTemp_[MAX_BUFFER_SIZE] CHAR sTemp2_[100];
	STACK_VAR CHAR cCount_ INTEGER nVal_ INTEGER nStartPos_ INTEGER nMidPos_;
	DebugString('ParseDGXSplashScreen7', sTemp, DEBUG_LEVEL_SUPER_CHATTY);
/*
*/
// if input card 1 removed '[io board 1 sensors] detected  [temp 1] -66.-4c'
// if input card 2 removed '[io board 2 sensors] detected  [temp 1] -66.-4c'
// if all boards removed '[io board <all> sensors] detected  [temp 1] -66.-4c', '[expansion board <both> sensors] detected [temp 1] -66.-4c'
	sTemp_ = '[center board 1 sensors]';
	nStartPos_ = FIND_STRING(sTemp, sTemp_, 1);
	nStartPos_ = nStartPos_ + LENGTH_STRING(sTemp_);
	sTemp_ = '[temp 1]';
	nStartPos_ = FIND_STRING(sTemp, sTemp_, 1);
	IF(nStartPos_)
	{
		nStartPos_ = nStartPos_ + LENGTH_STRING(sTemp_);
		nMidPos_ = FIND_STRING(sTemp, "$0d", nStartPos_);
		sTemp2_ = MID_STRING(sTemp, nStartPos_, LENGTH_STRING(sTemp)-nMidPos_+1);
		DebugString('internalTemperature', sTemp2_, DEBUG_LEVEL_CHATTY); // TODO: fix: this turns from '37.0' to 0
		// if the temperature change exceeds threshold send update
		IF(ATOI(sTemp2_) - DgxDeviceInfo.internalTemperature >= TEMPERATURE_DELTA || DgxDeviceInfo.internalTemperature - ATOI(sTemp2_)  >= TEMPERATURE_DELTA)
		{
			DebugVal('internalTemperature-update', TYPE_CAST(DgxDeviceInfo.internalTemperature), DEBUG_LEVEL_STANDARD);
			DgxDeviceInfo.internalTemperature = ATOI(sTemp2_);
			DgxAssetParameterSetValueNumber(assetClientKey, 'asset.temperature', DgxDeviceInfo.internalTemperature);
		}
	}
	sTemp_ = '[fan controller 1]';
	nStartPos_ = FIND_STRING(sTemp, sTemp_, 1);
	nStartPos_ = nStartPos_ + LENGTH_STRING(sTemp_);
	sTemp_ = '[fan ';
	nStartPos_ = FIND_STRING(sTemp, sTemp_, 1);
	WHILE(nStartPos_)
	{
		nStartPos_ = nStartPos_ + LENGTH_STRING(sTemp_);
		nMidPos_ = FIND_STRING(sTemp, "$0d", nStartPos_);
		sTemp2_ = MID_STRING(sTemp, nStartPos_, LENGTH_STRING(sTemp)-nMidPos_+1);
		DebugString('-[fan ', sTemp2_, DEBUG_LEVEL_CHATTY);
		cCount_ = ATOI(sTemp2_);
		nMidPos_ = FIND_STRING(sTemp2_, 'setting] ', 1);
		IF(nMidPos_)
		{
			nMidPos_ = nMidPos_ + LENGTH_STRING('setting] ');
			sTemp2_ = MID_STRING(sTemp2_, nMidPos_, LENGTH_STRING(sTemp)-nMidPos_+1);
			DebugString('-setting] ', sTemp2_, DEBUG_LEVEL_CHATTY);
			DgxDeviceInfo.nFanSetting[cCount_] = ATOI(sTemp2_);
		}
		nMidPos_ = FIND_STRING(sTemp2_, 'speed] ', 1);
		IF(nMidPos_)
		{
			nMidPos_ = nMidPos_ + LENGTH_STRING('speed] ');
			sTemp2_ = MID_STRING(sTemp2_, nMidPos_, LENGTH_STRING(sTemp)-nMidPos_+1);
			DebugVal("'fanSpeed ', ITOA(cCount_)", ATOI(sTemp2_), DEBUG_LEVEL_CHATTY);
			// if the speed change exceeds threshold send update
/* // using fan in centre board for diag
			IF(ATOI(sTemp2_) - DgxDeviceInfo.fanSpeed[cCount_] >= FAN_SPEED_DELTA || DgxDeviceInfo.fanSpeed[cCount_] - ATOI(sTemp2_)  >= FAN_SPEED_DELTA)
			{
				DebugVal("'fanSpeed ', ITOA(cCount_), ' update'", TYPE_CAST(DgxDeviceInfo.fanSpeed[cCount_]), DEBUG_LEVEL_STANDARD);
				DgxDeviceInfo.fanSpeed[cCount_] = ATOI(sTemp2_);
				DgxAssetParameterSetValueNumber(assetClientKey, "'asset.fan.speed.', ITOA(cCount_)", DgxDeviceInfo.fanSpeed[cCount_]);
			}
*/
		}
		nStartPos_ = FIND_STRING(sTemp, sTemp_, nStartPos_);
	}
}


DEFINE_FUNCTION ParseDGXBCPU()
{
	STACK_VAR CHAR cCount_ INTEGER nMidPos_ INTEGER nStartPos_ INTEGER nTemp_;
	STACK_VAR CHAR sTemp_[100] CHAR sTemp2_[MAX_BUFFER_SIZE] CHAR sTemp3_[50];
	// Remove section from 'BCPU<n>:'...'BCPU<n+1>'
	nStartPos_ = 1;
	sTemp_ = "'BCPU'";
	nStartPos_ = FIND_STRING(cBufferDGX, sTemp_, nStartPos_);
	WHILE(nStartPos_) // Found strTemp_
	{
		nMidPos_ = nStartPos_+LENGTH_STRING(sTemp_);
		sTemp2_ = RIGHT_STRING(cBufferDGX, LENGTH_STRING(cBufferDGX)-nMidPos_+1);
		cCount_ = ATOI(sTemp2_);
		DebugVal('ParseDGXBCPU cCount_', cCount_, DEBUG_LEVEL_SUPER_CHATTY);
		sTemp3_ = "'BCPU', ITOA(cCount_+1)	,':'"; 
		nMidPos_ = FIND_STRING(cBufferDGX, sTemp3_, nMidPos_);
		IF(!nMidPos_)
			nMidPos_ = LENGTH_STRING(cBufferDGX)+1;
		//nTemp_ = LENGTH_STRING("'BCPU', ITOA(cCount_)	,':'");
		nTemp_ = 6; // LENGTH_STRING("'BCPU', ITOA(cCount_)	,':'");
		sTemp2_ = MID_STRING(cBufferDGX, nStartPos_+nTemp_, nMidPos_-nStartPos_-nTemp_-1);
		//DebugString("'ParseDGXBCPU'", sTemp2_, DEBUG_LEVEL_SUPER_CHATTY);
		ParseDGXBCPUNumber(sTemp2_, cCount_);
		RemoveFromDGXBuffer(nStartPos_, nMidPos_-2); // don't remove the 'B'
		nStartPos_ = FIND_STRING(cBufferDGX, sTemp_, 1);
	}
}

DEFINE_FUNCTION ParseDGXBCPUNumber(CHAR sTemp[], CHAR cBoard)
{
	STACK_VAR CHAR sTemp_[MAX_BUFFER_SIZE] CHAR sTemp2_[100];
	STACK_VAR CHAR cCount_ CHAR cLinked_ CHAR cOutputBoardNum_ CHAR cIsInputBoard_;
	DebugVal('ParseDGXBCPUNumber', cBoard, DEBUG_LEVEL_SUPER_CHATTY);
	//DebugString("'ParseDGXBCPUNumber', ITOA(cBoard)", sTemp, DEBUG_LEVEL_SUPER_CHATTY);
/*
BCPU1:
        Ch1-[DxLink In] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl:10^(-10)
        Ch1-[TX] Cable Length: 0 (Meters), 0 (Feet)
        Ch1-[DxLink In] MSE Chan A:-21db, Chan B:-22db, Chan C:-22db, Chan D:-22db
        Ch1-[DxLink In] DSP Reset Count: 2
        Ch2-[DxLink In] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl:10^(-10)
        Ch2-[TX] Cable Length: 0 (Meters), 0 (Feet)
        Ch2-[DxLink In] MSE Chan A:-22db, Chan B:-21db, Chan C:-22db, Chan D:-22db
        Ch2-[DxLink In] DSP Reset Count: 3
        Ch3-Unlinked.
        Ch3-Unlinked.
        Ch3-Unlinked.
        Ch3-Unlinked.
        Ch4-Unlinked.
        Ch4-Unlinked.
        Ch4-Unlinked.
        Ch4-Unlinked.
*/
	FOR(cCount_=1; cCount_< 5; cCount_++) // 4 channels per board
	{
		//DebugVal("'Channel'", TYPE_CAST(cCount_), DEBUG_LEVEL_STANDARD);
		sTemp_ = GetSubString(sTemp, "'Ch',ITOA(cCount_),'-Unlinked.'", "$0d", REMOVE_DATA_INC_SEARCH); //Ch1-[DxLink In] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl:10^(-10)
		DebugString("'sTemp_'", sTemp_, DEBUG_LEVEL_CHATTY);
		cLinked_ = (LENGTH_STRING(sTemp_) != 0); // *** should be a ! ***
		IF(cLinked_) // linked
		{
			//DebugVal("'linked'", TYPE_CAST(cLinked_), DEBUG_LEVEL_CHATTY);
			sTemp_ = GetSubString(sTemp, "'Ch',ITOA(cCount_),'-[DxLink In]'", "$0d", DONT_REMOVE_DATA); //Ch1-[DxLink In] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl:10^(-10)
			cIsInputBoard_ = (LENGTH_STRING(sTemp_)); // [DxLink In]
		}
		ELSE // unlinked - have to determine input board by the number
		{
			cIsInputBoard_ = (cBoard <= MAX_VIDEO_INPUT_CNT/4);
			//DebugVal("'Unlinked'", TYPE_CAST(cLinked_), DEBUG_LEVEL_CHATTY);
			//DebugString("'sTemp_'", sTemp_, DEBUG_LEVEL_SUPER_CHATTY);
		}
		IF(cIsInputBoard_)
		{
			sTemp_ = GetSubString(sTemp, "'Ch',ITOA(cCount_),'-[DxLink In]'", "$0d", REMOVE_DATA_INC_SEARCH); //Ch1-[DxLink In] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl:10^(-10)
			//DebugVal("'cBoard Input'", TYPE_CAST(cBoard), DEBUG_LEVEL_STANDARD);
			sTemp2_ = "'Input board ', ITOA(cBoard), ' channel ', ITOA(cCount_)";
			DebugVal(sTemp2_, cLinked_, DEBUG_LEVEL_CHATTY);
			IF(DgxDeviceInfo.uInputBoard[cBoard].uChannel[cCount_].cLink <> cLinked_)
			{
				DgxDeviceInfo.uInputBoard[cBoard].uChannel[cCount_].cLink = cLinked_;
				DebugVal("sTemp2_,'-update'", TYPE_CAST(cLinked_), DEBUG_LEVEL_STANDARD);
				DgxAssetParameterSetValueNumber(assetClientKey, 
																				"'switcher.input.video.board.', ITOA(cBoard), '.input.', ITOA(cCount_)",
																				DgxDeviceInfo.uInputBoard[cBoard].uChannel[cCount_].cLink);
			}
		}
		ELSE
		{
			sTemp_ = GetSubString(sTemp, "'Ch',ITOA(cCount_),'-[RX] BER'", "$0d", REMOVE_DATA_INC_SEARCH); //'Ch1-[RX] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl:10^(-10)'
			//'Ch1-[RX] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl:10^(-10)'
			//DebugVal("'cBoard Output'", TYPE_CAST(cBoard), DEBUG_LEVEL_STANDARD);
			cOutputBoardNum_ = cBoard-MAX_VIDEO_INPUT_CNT/4;
			sTemp2_ = "'Output board ', ITOA(cOutputBoardNum_), ' channel ', ITOA(cCount_)";
			DebugVal(sTemp2_, cLinked_, DEBUG_LEVEL_CHATTY);
			IF(cOutputBoardNum_ > MAX_LENGTH_ARRAY(DgxDeviceInfo.uOutputBoard))
				DebugVal("'cBoard Output ERROR'", TYPE_CAST(cOutputBoardNum_), DEBUG_LEVEL_STANDARD);
			ELSE
			{
				IF(DgxDeviceInfo.uOutputBoard[cOutputBoardNum_].uChannel[cCount_].cLink <> cLinked_)
				{
					DgxDeviceInfo.uOutputBoard[cOutputBoardNum_].uChannel[cCount_].cLink = cLinked_;
					DebugVal("sTemp2_,'-update'", TYPE_CAST(cLinked_), DEBUG_LEVEL_STANDARD);
					DgxAssetParameterSetValueNumber(assetClientKey, 
																					"'switcher.output.video.board.', ITOA(cOutputBoardNum_), '.output.', ITOA(cCount_)",
																					DgxDeviceInfo.uOutputBoard[cOutputBoardNum_].uChannel[cCount_].cLink);
				}
			}
		}
		//DebugVal(sTemp2_, cVal_, DEBUG_LEVEL_CHATTY);
		//NotifyDGXUnlinked(cNumber, cCount_);
		sTemp_ = GetSubString(sTemp, "'Ch',ITOA(cCount_),'-[TX]'", "$0d", REMOVE_DATA_INC_SEARCH);
    // Ch1-[TX] Cable Length: 0 (Meters), 0 (Feet)
		sTemp_ = GetSubString(sTemp, "'Ch',ITOA(cCount_),'-[DxLink In] MSE'", "$0d", REMOVE_DATA_INC_SEARCH);
     //Ch1-[DxLink In] MSE Chan A:-21db, Chan B:-22db, Chan C:-22db, Chan D:-22db
		sTemp_ = GetSubString(sTemp, "'Ch',ITOA(cCount_),'-[DxLink In] DSP'", "$0d", REMOVE_DATA_INC_SEARCH);
    // Ch1-[DxLink In] DSP Reset Count: 2
	}
}

DEFINE_FUNCTION ParseDGXData()
{
	STACK_VAR INTEGER nStartPos_ INTEGER nMidPos_  INTEGER nEndPos_;
	STACK_VAR CHAR strTemp_[MAX_BUFFER_SIZE] CHAR strTemp2_[100] CHAR strTemp3_[50] CHAR cCount_;
	LOCAL_VAR INTEGER nBufferSize;
	DebugString('ParseDGXData', cBufferDGX, DEBUG_LEVEL_SUPER_CHATTY);
	WHILE(LENGTH_STRING(cBufferDGX))
	{
		FOR(cCount_= 1; cCount_ < 8; cCount_++)
		{
			strTemp_ = ParseDGXSplashScreen(cCount_, 1); // ~scrv3i?!
			IF(LENGTH_STRING(strTemp_))
			{
				SWITCH(cCount_)
				{
					CASE 1: ParseDGXSplashScreen1(strTemp_);
					CASE 2: ParseDGXSplashScreen2(strTemp_);
					CASE 3: ParseDGXSplashScreen3(strTemp_);
					CASE 4: ParseDGXSplashScreen4(strTemp_);
					CASE 5: ParseDGXSplashScreen5(strTemp_);
					CASE 6: ParseDGXSplashScreen6(strTemp_);
					CASE 7: ParseDGXSplashScreen7(strTemp_);
				}                           
			}
		}
		
		ParseDGXBCPU();
	
	/***********************************************************************************
	 DGX_SHELL>
	***********************************************************************************
	*/
		strTemp_ = 'MCPU:';
		nStartPos_ = FIND_STRING(cBufferDGX, strTemp_, 1);
		IF(nStartPos_) // Found strTemp_
		{
			nMidPos_ = nStartPos_+LENGTH_STRING(strTemp_);
			nEndPos_ = nMidPos_;
			strTemp_ = 'BCPU';
			nEndPos_ = FIND_STRING(cBufferDGX, strTemp_, nEndPos_);
			IF(!nEndPos_)
				nEndPos_ = LENGTH_STRING(cBufferDGX);
			RemoveFromDGXBuffer(nStartPos_,nEndPos_-1);
		}
			
		strTemp_ = "'DGX_SHELL>'";
		DiscardFromDGXBuffer(strTemp_);
		strTemp_ = "'Shell input timeout.  Resume BCS.',$0D,$0A";
		DiscardFromDGXBuffer(strTemp_);
		strTemp_ = "'Command not found.',$0D,$0A";
		DiscardFromDGXBuffer(strTemp_);
		strTemp_ = "'bcs'";	
		DiscardFromDGXBuffer(strTemp_);
	
		//IF(LENGTH_STRING(cBufferDGX))
		//	DebugString('Unparsed data', cBufferDGX, DEBUG_LEVEL_SUPER_CHATTY);
	
		strTemp_ = "'~scr'"; 
		nStartPos_ = FIND_STRING(cBufferDGX, strTemp_, 1);
		IF(nStartPos_)
		{
			strTemp_ = "'!'"; 
			nMidPos_ = FIND_STRING(cBufferDGX, strTemp_, nStartPos_)
			IF(nMidPos_)
				RemoveFromDGXBuffer(nStartPos_, nMidPos_);
		}
	
		RemoveLeadingNonPrintable(cBufferDGX);
	
/*	
		// this could remove useful data but we need to empty the buffer of unparsed data.
		strTemp_ = "$0a"; 		// the last byte of any message should be $0a
		IF(FIND_STRING(cBufferDGX, strTemp_, 1))
			strTemp_ = REMOVE_STRING(cBufferDGX, strTemp_, 1);
*/

	// If the buffer hasn't changed size since the last pass then the remaining data in the buffer must be unhandled data so ditch it to terminate the loop
		nEndPos_ = LENGTH_STRING(cBufferDGX);
		IF(nBufferSize == nEndPos_)
			CLEAR_BUFFER cBufferDGX;
		ELSE
			nBufferSize = nEndPos_;
		
	}
	DebugString('Finished parsing data', cBufferDGX, DEBUG_LEVEL_SUPER_CHATTY);
}

DEFINE_FUNCTION RemoveLeadingNonPrintable(CHAR sString[])
{
	STACK_VAR INTEGER nIdx_;
	nIdx_ = 0;
	WHILE(nIdx_ < LENGTH_STRING(sString))
	{
		IF (sString[nIdx_+1] > $1F && sString[nIdx_+1] < $7F) // printable
			BREAK;
		nIdx_++;
	}
	IF(nIdx_)
		sString = RIGHT_STRING(sString, LENGTH_STRING(sString)-nIdx_);
}

DEFINE_FUNCTION BreakStringIntoChunks(CHAR sSource[], INTEGER iChunkSize)
{
	STACK_VAR CHAR sTemp_[MAX_BUFFER_SIZE] CHAR sReturn_[MAX_BUFFER_SIZE] CHAR sTemp2_[10];
	STACK_VAR INTEGER iStart_ INTEGER iEnd_;

	iStart_ = 1;
	iEnd_ = iStart_ + iChunkSize;
	sTemp_ = sSource;
	sTemp2_ = '**';
	WHILE (LENGTH_STRING(sTemp_) > iEnd_)
	{
		sReturn_ = MID_STRING(sTemp_, iStart_, iChunkSize);
		DebugString(sTemp2_, sReturn_, DEBUG_LEVEL_CHATTY);
		sTemp2_ = '->';

		iStart_ = iStart_ + iChunkSize;
		iEnd_ = iStart_ + iChunkSize;
	}
	sReturn_ = RIGHT_STRING(sTemp_, LENGTH_STRING(sTemp_) - iStart_ + 1);
	DebugString(sTemp2_, sReturn_, DEBUG_LEVEL_CHATTY);
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

DEFINE_FUNCTION DebugVal(CHAR strHead[], INTEGER nVal, INTEGER iDebugLevel)	
{
	IF (DEBUG_LEVEL & iDebugLevel)
		SEND_STRING 0, "strHead,': ',ITOA(nVal)"
}

DEFINE_FUNCTION DebugString(CHAR strHead[], CHAR strBody[], INTEGER iDebugLevel)
{
	STACK_VAR CHAR strTemp_[120];
	IF (DEBUG_LEVEL & iDebugLevel)
	{
		strTemp_ = "strHead,':LEN=',ITOA(LENGTH_STRING(strBody)),':'";
		IF(LENGTH_STRING(strBody) > MAX_LENGTH_STRING(strTemp_))
			//BreakStringIntoChunks("strTemp_, strBody", MAX_LENGTH_STRING(strTemp_))
			SEND_STRING 0, "strTemp_, LEFT_STRING(strBody,30), ' ... ', RIGHT_STRING(strBody, 30)";
		ELSE
			SEND_STRING 0, "strTemp_,strBody";
	}
}

DEFINE_FUNCTION INTEGER AHTOI(CHAR sVal[])	 // Ascii hex to integer. eg 'xyzC000'
STACK_VAR  CHAR sValidChars_[16] CHAR sTemp_[MAX_BUFFER_SIZE];
STACK_VAR CHAR cCount_ CHAR cTemp_ CHAR cFirstCharIdx_;
STACK_VAR INTEGER nReturn_;
{
	sValidChars_ = '0123456789ABCDEF';
	cFirstCharIdx_= 0;
	nReturn_ = 0;
	sTemp_ = UPPER_STRING(sVal);
	FOR(cCount_= 1; cCount_ <= LENGTH_STRING(sTemp_); cCount_++)
	{
		IF(!cFirstCharIdx_)
		{
			cTemp_ = FIND_STRING("sValidChars_", "sTemp_[cCount_]", 1);
			IF(cTemp_)
			{
				cFirstCharIdx_ = cCount_;
				nReturn_ = cTemp_-1;
			}
		}
		ELSE
		{
			cTemp_ = FIND_STRING("sValidChars_", "sTemp_[cCount_]", 1);
			IF(cTemp_)
				nReturn_ = $10*nReturn_+cTemp_-1;
			ELSE
				cCount_ = $FE; // force loop to exit
		}
	}
	RETURN nReturn_;
}

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START
CREATE_BUFFER dvDgxSerial, cBufferDGX;

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

DATA_EVENT[dvMonitoredDevice]
{
	ONLINE:
	{
		DEVICE_INFO(dvMonitoredDevice, devInfo);		// Populate version, etc. information

		// Since all the devices are processed by this handler,
		// only perform these tasks if they have not already been run
		IF(devInit == FALSE)
		{
			InitDefaults();
		}

		// For device values not managed by channel or level events, ask the
		// device for those values not
		RequestDgxValuesUpdates();

		IF(!TIMELINE_ACTIVE(TL_MONITOR))
		{
			TIMELINE_CREATE(TL_MONITOR,DgxMonitoringTimeArray,2,TIMELINE_RELATIVE,TIMELINE_REPEAT);
		}
  }

	OFFLINE:
	{
		devInit = FALSE;

		// if a panel monitoring timeline was created and is running, then permanently
		// destroy the panel monitoring timeline while the panel is offline.
		IF(TIMELINE_ACTIVE(TL_MONITOR))
		{
			TIMELINE_KILL(TL_MONITOR);
		}
	}
}


DATA_EVENT[dvDgxSerial]
{
	ONLINE:	SEND_COMMAND DATA.DEVICE, 'SET BAUD 9600,n,8,1 485 DISABLE';
	STRING:
	{
		CANCEL_WAIT 'DATA IN';
		WAIT 5 'DATA IN'
			ParseDGXData();
		IF(LENGTH_STRING(cBufferDGX) > MAX_LENGTH_STRING(cBufferDGX)-10)
		{
			DebugVal('Clearing full cBufferDGX', LENGTH_STRING(cBufferDGX), DEBUG_LEVEL_STANDARD);
			CLEAR_BUFFER cBufferDGX;
		}
	}
}

BUTTON_EVENT[vdvDEV, 0] // testing
{
	PUSH:
	{
		IF(BUTTON.INPUT.CHANNEL < 8)
			SEND_STRING dvDgxSerial, "'~scri',ITOA(BUTTON.INPUT.CHANNEL),'v3!',$0d,$0a"; // board info
		ELSE
			SWITCH(BUTTON.INPUT.CHANNEL)
			{
				//CASE 1-7: // send "'~scri1v3!'";
				//CASE 10: // Get BCPU data (channels linked)
				//CASE 11-17: // emulate "'~scri1v3!'";
				//CASE 20: // leave bcs shell-	so you can send BCPU commands			
				//CASE 30: // go back to bcs shell - so you can cend ~scr commands		
				//CASE 40: // emulate BCPU command
				
				CASE 10: // Get BCPU data (channels linked)
				{
					SEND_STRING dvDgxSerial, "$03"; // Control+C to go into DGX_SHELL>
					WAIT 1
						SEND_STRING dvDgxSerial, "'show stats',$0d,$0a";
				}
				CASE 11:// SEND_STRING dvDgxSerial, "'~scri1v3!'";
				{ // LEN=120
					cBufferDGX = "'~scrv3i1!',$0d,$0a,
												'[1:Enclosure] AMX Enova DGX 16',$0d,$0a,
												'[host software] v3.6.0',$0d,$0a,
												'[hardware driver] v1.0.1 R',$0d,$0a,
												'[build date] July 22 2011 11:29:26',$0d,$0a,
												'[pld version] A1',$0d,$0a,
												'[xnet address] 0x11029',$0d,$0a,
												'[ap system id] 0x0',$0d,$0a,
												'[nvram status] valid.. user preference restored',$0d,$0a,
												'[nvram magic] 0xdedafaba',$0d,$0a,
												'[sysrev id] 1',$0d,$0a"
					ParseDGXData();
				}
				CASE 12: {}
				CASE 13: {}
				CASE 14:// SEND_STRING dvDgxSerial, "'~scri4v3!'";
				{
					cBufferDGX = "'~scrv3i4!',$0d,$0a,
												'[4:Hardware Boards] detected',$0d,$0a,
												'[switching drivers] count = 1',$0d,$0a,
												'[mtx driver 1.1] 16x16 switching driver',$0d,$0a,
												'[revision] 0x05',$0d,$0a,
												'[mtx driver 1.2] 16x16 switching driver',$0d,$0a,
												'[revision] 0x05',$0d,$0a,
												'[input boards] count = 2',$0d,$0a,
												'[board 1] c0e0',$0d,$0a,
												'[board 2] c0e0',$0d,$0a,
												'[board 3] 0000',$0d,$0a,
												'[board 4] 0000',$0d,$0a,
												'[output boards] count = 2',$0d,$0a,
												'[board 5] 80b0',$0d,$0a"
					ParseDGXData();
				}
				CASE 15:// SEND_STRING dvDgxSerial, "'~scri5v3!'";
				{
					cBufferDGX = "'~scri5v3!',$0d,$0a,
												'[5:VM Configuration] count = 2',$0d,$0a,
												'[vm 0] "All" 32x32x1',$0d,$0a,
												'[vm 1] "Video" 32x32x1',$0d,$0a,
												'[vm 0 master] 0x11000 master 0 0 1 (self)',$0d,$0a,
												'[vm 1 master] 0x11000 master 0 0 1 (self)',$0d,$0a"
					ParseDGXData();
				}
				CASE 16:// SEND_STRING dvDgxSerial, "'~scri6v3!'";
				{
					cBufferDGX = "'~scrv3i6!',$0d,$0a,
												'[6:Power System] good',$0d,$0a,
														$09,'[status flags] 0x0000',$0d,$0a,
														$09,'[available system power] 1872w',$0d,$0a,
														$09,'[required system power] 268w',$0d,$0a,
														$09,'[ac power slot 1] good',$0d,$0a,
																$09,$09,'[status flags] 0x00',$0d,$0a,
																$09,$09,'[available power] 936w',$0d,$0a,
																$09,$09,'[output power] 66.06w',$0d,$0a,
																$09,$09,'[voltage] 12.01v',$0d,$0a,
																$09,$09,'[current] 5.50a',$0d,$0a,
																$09,$09,'[fan speed] 9400 rpm',$0d,$0a,
																$09,$09,'[service hours] 100000',$0d,$0a,
																$09,$09,'[model #] CAR0812FPBXZ01A',$0d,$0a,
																$09,$09,'[serial #] ZB90545',$0d,$0a,
																$09,$09,'[revision] A',$0d,$0a,
														$09,'[ac power slot 2] good',$0d,$0a,
																$09,$09,'[status flags] 0x00',$0d,$0a,
																$09,$09,'[available power] 936w',$0d,$0a,
																$09,$09,'[output power] 33.01w',$0d,$0a,
																$09,$09,'[voltage] 12.00v',$0d,$0a,
																$09,$09,'[current] 2.75a',$0d,$0a,
																$09,$09,'[fan speed] 9600 rpm',$0d,$0a,
																$09,$09,'[service hours] 100000',$0d,$0a,
																$09,$09,'[model #] CAR0812FPBXZ01A',$0d,$0a,
																$09,$09,'[serial #] ZB90653',$0d,$0a,
																$09,$09,'[revision] A',$0d,$0a,
														$09,'[dc controller 1] good',$0d,$0a,
																$09,$09,'[status flags] 0x0000',$0d,$0a,
																$09,$09,'[io board 1 pol 1] good',$0d,$0a,
																		$09,$09,$09,'[status flags] 0x00',$0d,$0a,
																		$09,$09,$09,'[voltage] 4.94v',$0d,$0a,
																		$09,$09,$09,'[current] 1.40a',$0d,$0a,
																		$09,$09,$09,'[temp] 43.8c',$0d,$0a,
																$09,$09,'[io board 2 pol 1] good',$0d,$0a,
																		$09,$09,$09,'[status flags] 0x00',$0d,$0a,
																		$09,$09,$09,'[voltage] 4.94v',$0d,$0a,
																		$09,$09,$09,'[current] 1.40a',$0d,$0a,
																		$09,$09,$09,'[temp] 43.8c',$0d,$0a,
																$09,$09,'[io board 3 pol 1] good',$0d,$0a,
																		$09,$09,$09,'[status flags] 0x00',$0d,$0a,
																		$09,$09,$09,'[voltage] 4.94v',$0d,$0a,
																		$09,$09,$09,'[current] 1.40a',$0d,$0a,
																		$09,$09,$09,'[temp] 43.8c',$0d,$0a,
																$09,$09,'[io board 4 pol 1] good',$0d,$0a,
																		$09,$09,$09,'[status flags] 0x00',$0d,$0a,
																		$09,$09,$09,'[voltage] 2.42v',$0d,$0a,
																		$09,$09,$09,'[current] 1.53a',$0d,$0a,
																		$09,$09,$09,'[temp] 34.0c',$0d,$0a,
																$09,$09,'[io board 4 pol 2] good',$0d,$0a,
																		$09,$09,$09,'[status flags] 0x00',$0d,$0a,
																		$09,$09,$09,'[voltage] 3.85v',$0d,$0a,
																		$09,$09,$09,'[current] 1.53a',$0d,$0a,
																		$09,$09,$09,'[temp] 34.0c',$0d,$0a,
																$09,$09,'[center board 1 pol 1] good',$0d,$0a,
																		$09,$09,$09,'[status flags] 0x00',$0d,$0a,
																		$09,$09,$09,'[voltage] 2.47v',$0d,$0a,
																		$09,$09,$09,'[current] 2.42a',$0d,$0a,
																		$09,$09,$09,'[temp] 40.3c',$0d,$0a,
																$09,$09,'[cpu board pol 1] good',$0d,$0a,
																		$09,$09,$09,'[status flags] 0x00',$0d,$0a,
																		$09,$09,$09,'[voltage] 3.24v',$0d,$0a,
																		$09,$09,$09,'[current] 3.92a',$0d,$0a,
																		$09,$09,$09,'[temp] 69.5c',$0d,$0a,
																$09,$09,'[cpu board pol 2] good',$0d,$0a,
																		$09,$09,$09,'[status flags] 0x00',$0d,$0a,
																		$09,$09,$09,'[voltage] 3.26v',$0d,$0a,
																		$09,$09,$09,'[current] 1.05a',$0d,$0a,
																		$09,$09,$09,'[temp] 43.0c',$0d,$0a"
					ParseDGXData();
				}            
				CASE 17:// SEND_STRING dvDgxSerial, "'~scri7v3!'";
				{
					cBufferDGX = "'~scrv2i7!',$0d,$0a,
												'[7:System Sensors] detected',$0d,$0a,
														$09,'[io board 1 sensors] detected',$0d,$0a,
																$09,$09,'[temp 1] 37.0c',$0d,$0a,
														$09,'[io board 2 sensors] detected',$0d,$0a,
																$09,$09,'[temp 1] 36.0c',$0d,$0a,
														$09,'[io board 3 sensors] detected',$0d,$0a,
																$09,$09,'[temp 1] 36.5c',$0d,$0a,
																$09,$09,'[temp 2] 47.0c',$0d,$0a,
																$09,$09,'[temp 3] 39.0c',$0d,$0a,
																$09,$09,'[temp 4] 40.0c',$0d,$0a,
																$09,$09,'[temp 5] 36.0c',$0d,$0a,
														$09,'[io board 4 sensors] detected',$0d,$0a,
																$09,$09,'[temp 1] 34.0c',$0d,$0a,
														$09,'[expansion board 1 sensors] detected',$0d,$0a,
																$09,$09,'[temp 1] 34.0c',$0d,$0a,
														$09,'[expansion board 2 sensors] detected',$0d,$0a,
																$09,$09,'[temp 1] 34.0c',$0d,$0a,
														$09,'[center board 1 sensors] detected',$0d,$0a,
																$09,'[temp 1] 32.0c',$0d,$0a,
														$09,'[signal sense]',$0d,$0a,
																$09,$09,'[board 1] 0',$0d,$0a,
																$09,$09,'[board 2] 0',$0d,$0a,
																$09,$09,'[board 3] 0',$0d,$0a,
																$09,$09,'[board 4] 0',$0d,$0a,
														$09,'[fan controller 1] detected',$0d,$0a,
																$09,$09,'[fan 1 setting] 1440 rpm',$0d,$0a,
																$09,$09,'[fan 1 speed] 1446 rpm',$0d,$0a,
																$09,$09,'[fan 2 setting] 1440 rpm',$0d,$0a,
																$09,$09,'[fan 2 speed] 1477 rpm',$0d,$0a";
					ParseDGXData();
				}
				CASE 30: SEND_STRING dvDgxSerial, "'bcs',$0d,$0a"; // go back to bcs shell				
				CASE 40: // emulate BCPU command
				{
					cBufferDGX = "'show stats',$0d,$0a,
												'MCPU:',$0d,$0a,
																$09,$09,$09,$09,'i2c failure count: 0',$0d,$0a,
																$09,$09,$09,$09,'reboot count: 16',$0d,$0a,
																$09,$09,$09,$09,'recover count: 2',$0d,$0a,
												$0d,$0a,        
												'BCPU1:',$0d,$0a,
																$09,$09,$09,$09,'Ch1-[DxLink In] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl:10^(-10)',$0d,$0a,
																$09,$09,$09,$09,'Ch1-[TX] Cable Length: 0 (Meters), 0 (Feet)',$0d,$0a,
																$09,$09,$09,$09,'Ch1-[DxLink In] MSE Chan A:-22db, Chan B:-22db, Chan C:-22db, Chan D:-22db',$0d,$0a,
																$09,$09,$09,$09,'Ch1-[DxLink In] DSP Reset Count: 1',$0d,$0a,
																$09,$09,$09,$09,'Ch2-[DxLink In] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl:10^(-10)',$0d,$0a,
																$09,$09,$09,$09,'Ch2-[TX] Cable Length: 0 (Meters), 0 (Feet)',$0d,$0a,
																$09,$09,$09,$09,'Ch2-[DxLink In] MSE Chan A:-22db, Chan B:-22db, Chan C:-22db, Chan D:-21db',$0d,$0a,
																$09,$09,$09,$09,'Ch2-[DxLink In] DSP Reset Count: 1',$0d,$0a,
																$09,$09,$09,$09,'Ch3-[DxLink In] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl:10^(-10)',$0d,$0a,
																$09,$09,$09,$09,'Ch3-[TX] Cable Length: 0 (Meters), 0 (Feet)',$0d,$0a,
																$09,$09,$09,$09,'Ch3-[DxLink In] MSE Chan A:-21db, Chan B:-21db, Chan C:-21db, Chan D:-22db',$0d,$0a,
																$09,$09,$09,$09,'Ch3-[DxLink In] DSP Reset Count: 1',$0d,$0a,
																$09,$09,$09,$09,'Ch4-[DxLink In] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl:10^(-10)',$0d,$0a,
																$09,$09,$09,$09,'Ch4-[TX] Cable Length: 62 (Meters), 203 (Feet)',$0d,$0a,
																$09,$09,$09,$09,'Ch4-[DxLink In] MSE Chan A:-19db, Chan B:-17db, Chan C:-19db, Chan D:-19db',$0d,$0a,
																$09,$09,$09,$09,'Ch4-[DxLink In] DSP Reset Count: 1',$0d,$0a,
												$0d,$0a,
												'BCPU2:',$0d,$0a,
																$09,$09,$09,$09,'Ch1-[DxLink In] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl:10^(-10)',$0d,$0a,
																$09,$09,$09,$09,'Ch1-[TX] Cable Length: 0 (Meters), 0 (Feet)',$0d,$0a,
																$09,$09,$09,$09,'Ch1-[DxLink In] MSE Chan A:-21db, Chan B:-22db, Chan C:-22db, Chan D:-22db',$0d,$0a,
																$09,$09,$09,$09,'Ch1-[DxLink In] DSP Reset Count: 2',$0d,$0a,
																$09,$09,$09,$09,'Ch2-[DxLink In] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl:10^(-10)',$0d,$0a,
																$09,$09,$09,$09,'Ch2-[TX] Cable Length: 0 (Meters), 0 (Feet)',$0d,$0a,
																$09,$09,$09,$09,'Ch2-[DxLink In] MSE Chan A:-22db, Chan B:-21db, Chan C:-22db, Chan D:-22db',$0d,$0a,
																$09,$09,$09,$09,'Ch2-[DxLink In] DSP Reset Count: 3',$0d,$0a,
																$09,$09,$09,$09,'Ch3-Unlinked.',$0d,$0a,
																$09,$09,$09,$09,'Ch3-Unlinked.',$0d,$0a,
																$09,$09,$09,$09,'Ch3-Unlinked.',$0d,$0a,
																$09,$09,$09,$09,'Ch3-Unlinked.',$0d,$0a,
																$09,$09,$09,$09,'Ch4-Unlinked.',$0d,$0a,
																$09,$09,$09,$09,'Ch4-Unlinked.',$0d,$0a,
																$09,$09,$09,$09,'Ch4-Unlinked.',$0d,$0a,
																$09,$09,$09,$09,'Ch4-Unlinked.',$0d,$0a,
												$0d,$0a,
												'BCPU3:',$0d,$0a,
																$09,$09,$09,$09,'Ch1-[DxLink In] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl:10^(-10)',$0d,$0a,
																$09,$09,$09,$09,'Ch1-[TX] Cable Length: 30 (Meters), 98 (Feet)',$0d,$0a,
																$09,$09,$09,$09,'Ch1-[DxLink In] MSE Chan A:-21db, Chan B:-22db, Chan C:-21db, Chan D:-21db',$0d,$0a,
																$09,$09,$09,$09,'Ch1-[DxLink In] DSP Reset Count: 1',$0d,$0a,
																$09,$09,$09,$09,'Ch2-[DxLink In] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl:10^(-10)',$0d,$0a,
																$09,$09,$09,$09,'Ch2-[TX] Cable Length: 28 (Meters), 91 (Feet)',$0d,$0a,
																$09,$09,$09,$09,'Ch2-[DxLink In] MSE Chan A:-21db, Chan B:-21db, Chan C:-21db, Chan D:-21db',$0d,$0a,
																$09,$09,$09,$09,'Ch2-[DxLink In] DSP Reset Count: 1',$0d,$0a,
																$09,$09,$09,$09,'Ch3-[DxLink In] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl',$0d,$0a,
																$09,$09,$09,$09,'Ch3-[TX] Cable Length: 56 (Meters), 183 (Feet)',$0d,$0a,
																$09,$09,$09,$09,'Ch3-[DxLink In] MSE Chan A:-20db, Chan B:-18db, Chan C:-20db, Chan D:-20',$0d,$0a,
																$09,$09,$09,$09,'Ch3-[DxLink In] DSP Reset Count: 1',$0d,$0a,
																$09,$09,$09,$09,'Ch4-[DxLink In] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl',$0d,$0a,
																$09,$09,$09,$09,'Ch4-[TX] Cable Length: 46 (Meters), 150 (Feet)',$0d,$0a,
																$09,$09,$09,$09,'Ch4-[DxLink In] MSE Chan A:-20db, Chan B:-20db, Chan C:-21db, Chan D:-20',$0d,$0a,
																$09,$09,$09,$09,'Ch4-[DxLink In] DSP Reset Count: 1',$0d,$0a,
												$0d,$0a,
												'BCPU4:',$0d,$0a,
																$09,$09,$09,$09,'Ch1-[DxLink In] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl',$0d,$0a,
																$09,$09,$09,$09,'Ch1-[TX] Cable Length: 40 (Meters), 131 (Feet)',$0d,$0a,
																$09,$09,$09,$09,'Ch1-[DxLink In] MSE Chan A:-19db, Chan B:-21db, Chan C:-21db, Chan D:-21',$0d,$0a,
																$09,$09,$09,$09,'Ch1-[DxLink In] DSP Reset Count: 1',$0d,$0a,
																$09,$09,$09,$09,'Ch2-[DxLink In] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl',$0d,$0a,
																$09,$09,$09,$09,'Ch2-[TX] Cable Length: 36 (Meters), 118 (Feet)',$0d,$0a,
																$09,$09,$09,$09,'Ch2-[DxLink In] MSE Chan A:-20db, Chan B:-21db, Chan C:-20db, Chan D:-21',$0d,$0a,
																$09,$09,$09,$09,'Ch2-[DxLink In] DSP Reset Count: 1',$0d,$0a,
																$09,$09,$09,$09,'Ch3-[DxLink In] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl',$0d,$0a,
																$09,$09,$09,$09,'Ch3-[TX] Cable Length: 30 (Meters), 98 (Feet)',$0d,$0a,
																$09,$09,$09,$09,'Ch3-[DxLink In] MSE Chan A:-21db, Chan B:-21db, Chan C:-21db, Chan D:-21',$0d,$0a,
																$09,$09,$09,$09,'Ch3-[DxLink In] DSP Reset Count: 1',$0d,$0a,
																$09,$09,$09,$09,'Ch4-[DxLink In] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl:10^(-10)',$0d,$0a,
																$09,$09,$09,$09,'Ch4-[TX] Cable Length: 70 (Meters), 229 (Feet)',$0d,$0a,
																$09,$09,$09,$09,'Ch4-[DxLink In] MSE Chan A:-19db, Chan B:-17db, Chan C:-19db, Chan D:-19db',$0d,$0a,
																$09,$09,$09,$09,'Ch4-[DxLink In] DSP Reset Count: 1',$0d,$0a,
												$0d,$0a,'DGX_SHELL>'"
					ParseDGXData();
				} 
			}
	}
}

DATA_EVENT[DgxDeviceSet]
{
	COMMAND:
	{
		STACK_VAR CHAR header[RMS_MAX_HDR_LEN];
		STACK_VAR CHAR param1[RMS_MAX_PARAM_LEN];
		STACK_VAR CHAR param2[RMS_MAX_PARAM_LEN];
		STACK_VAR INTEGER eventDevicePort;

		// parse RMS command header
		header	= UPPER_STRING(RmsParseCmdHeader(DATA.TEXT));

		// Determine what device created the data event and get it's port number
		eventDevicePort = DgxDeviceSet[GET_LAST(DgxDeviceSet)].PORT;

/*
		SELECT
		{

			// Audio and video input name
			// Note: With current versions of the firmware changes in the video name
			// are reflected in the audio name as well
			ACTIVE(header == 'VIDIN_NAME' || header == 'AUDIN_NAME'):
			{
				STACK_VAR CHAR cachedName[MAX_STRING_SIZE];
				STACK_VAR CHAR newName[MAX_STRING_SIZE];

				newName	= RmsParseCmdParam(DATA.TEXT);
				IF(header == 'VIDIN_NAME')
				{
					cachedName = DgxDeviceInfo.videoInputName[eventDevicePort];
				}
				ELSE
				{
					cachedName = DgxDeviceInfo.audioInputName[eventDevicePort];
				}

				// if there is a change, update device information structure
				IF(cachedName != newName)
				{
					IF(header == 'VIDIN_NAME')
					{
						DgxDeviceInfo.videoInputName[eventDevicePort] = newName;
						SyncVideoOutputSource();
					}
					ELSE
					{
						DgxDeviceInfo.audioInputName[eventDevicePort] = newName;
						SyncAudioOutputSource();
					}				
				}
			}

			// Video output scale
			ACTIVE(header == 'VIDOUT_SCALE'):
			{
				STACK_VAR CHAR newScale[MAX_STRING_SIZE];

				newScale	= RmsParseCmdParam(DATA.TEXT);

				// if there is a change update struct and RMS
				IF(UPPER_STRING(DgxDeviceInfo.videoOutputScaleMode[eventDevicePort]) != UPPER_STRING(newScale))
				{
					DgxDeviceInfo.videoOutputScaleMode[eventDevicePort] = newScale;
					DgxAssetParameterSetValue(assetClientKey,  "'switcher.output.video.scale.mode.', ITOA(eventDevicePort)", newScale);
				}
			}

			// Video input format
			ACTIVE(header == 'VIDIN_FORMAT'):
			{
				STACK_VAR CHAR newFormat[MAX_STRING_SIZE];

				newFormat	= RmsParseCmdParam(DATA.TEXT);

				// if there is a change update struct and RMS
				IF(UPPER_STRING(DgxDeviceInfo.videoInputFormat[eventDevicePort]) != UPPER_STRING(newFormat))
				{
					DgxDeviceInfo.videoInputFormat[eventDevicePort] = newFormat;
					DgxAssetParameterSetValue(assetClientKey,  "'switcher.input.video.format.', ITOA(eventDevicePort)", newFormat);
				}
			}
*/
/*
			// Events for queries for connections between inputs and outputs go here
			// This applies to both audio and video
			ACTIVE(LEFT_STRING(header,8) == 'SWITCH'):
			{
				STACK_VAR CHAR input[2];
				STACK_VAR CHAR mediaRouteInfo[RMS_MAX_PARAM_LEN];
				STACK_VAR CHAR media[5];
				STACK_VAR CHAR output[2];
				STACK_VAR CHAR videoSourceChanged;
				STACK_VAR INTEGER cachedValue;
				STACK_VAR INTEGER inputNumber;
				STACK_VAR INTEGER ndx;
				STACK_VAR INTEGER outputNumber;

				videoSourceChanged = FALSE;
				param1	= RmsParseCmdParam(DATA.TEXT);
				mediaRouteInfo = param1;
				REMOVE_STRING(mediaRouteInfo, 'L', 1);
				media = LEFT_STRING(mediaRouteInfo, 5);				// A(AUDIO) or V(VIDEO)
				REMOVE_STRING(mediaRouteInfo, media, 1);
				
				// Characters between the 'I' and 'O' represent the input port number
				REMOVE_STRING(mediaRouteInfo, 'I', 1);
				input = MID_STRING(mediaRouteInfo, 1, FIND_STRING(mediaRouteInfo, 'O', 1) - 1);
				
				// Any characters after the 'O' represent the output port number
				REMOVE_STRING(mediaRouteInfo, "input,'O'", 1);
				output = mediaRouteInfo;
				
				inputNumber = ATOI(input);
				outputNumber = ATOI(output);

				// Parse video connection routing information
				IF(media == 'VIDEO')
				{
					// If input number is 0, disconnect outputs
					IF(inputNumber == 0 && outputNumber != 0 )
					{
						cachedValue = DgxDeviceInfo.videoOutputSelectedSource[outputNumber];
						IF(cachedValue != 0)
						{
							videoSourceChanged = TRUE;
							DgxDeviceInfo.videoOutputSelectedSource[outputNumber] = 0;
						}
					}
					// If output number is 0, disconnect inputs
					ELSE IF(outputNumber == 0 && inputNumber != 0 )
					{
						FOR(ndx = 1; ndx <= DgxDeviceInfo.videoOutputCount; ndx++)
						{
							cachedValue = DgxDeviceInfo.videoOutputSelectedSource[ndx];
							IF(cachedValue == inputNumber)
							{
								videoSourceChanged = TRUE;
								DgxDeviceInfo.videoOutputSelectedSource[ndx] = 0;
							}
						}
					}
					ELSE IF(outputNumber != 0 && inputNumber != 0 )
					{
						cachedValue = DgxDeviceInfo.videoOutputSelectedSource[outputNumber];
						IF(cachedValue != inputNumber)
						{
							videoSourceChanged = TRUE;
							DgxDeviceInfo.videoOutputSelectedSource[outputNumber] = inputNumber;
						}
					}
					ELSE
					{
						AMX_LOG(AMX_WARNING, "MONITOR_DEBUG_NAME, '-DATA_EVENT.COMMAND: header: SWITCH , media: ',
											media, ' , unexpected output and input ports are zero'");
					}
				}
				ELSE
				{
					AMX_LOG(AMX_WARNING, "MONITOR_DEBUG_NAME, '-DATA_EVENT.COMMAND: header: SWITCH ,
										unexpected media type: ', media");
				}

				IF(videoSourceChanged == TRUE)
				{
					SyncVideoOutputSource();
				}
			}
		}
*/
	}
}

(***********************************************************)
(* When a device comes online, determine the device        *)
(* capabilities                                            *)
(***********************************************************)
DATA_EVENT[vdvRMS]
{
	ONLINE:
	{
	}
	OFFLINE:
	{
	}
}

#IF_DEFINED _VIDEO_SWITCHER_MONITORING_
(***********************************************************)
(* Channel event for video output enable                   *)
(***********************************************************)
CHANNEL_EVENT[DgxDeviceSet, VIDEO_OUTPUT_ENABLE_CHANNEL]
{
	ON:
	{
		DgxDeviceInfo.videoOutputEnabled[DgxDeviceSet[GET_LAST(DgxDeviceSet)].PORT] = TRUE;
		DgxAssetParameterSetValueBoolean(
																			assetClientKey,
																			"'switcher.output.video.enabled.', ITOA(DgxDeviceSet[GET_LAST(DgxDeviceSet)].PORT)",
																			TRUE);
	}
	OFF:
	{
		DgxDeviceInfo.videoOutputEnabled[DgxDeviceSet[GET_LAST(DgxDeviceSet)].PORT] = FALSE;
		DgxAssetParameterSetValueBoolean(
																			assetClientKey,
																			"'switcher.output.video.enabled.', ITOA(DgxDeviceSet[GET_LAST(DgxDeviceSet)].PORT)",
																			FALSE);
	}
}

(***********************************************************)
(* Channel event for video output mute                     *)
(***********************************************************)
CHANNEL_EVENT[DgxDeviceSet, VIDEO_MUTE_CHANNEL]
{
	ON:
	{
		DgxDeviceInfo.videoOutputPictureMute[GET_LAST(DgxDeviceSet)] = TRUE;
		DgxAssetParameterSetValueBoolean(
																			assetClientKey,
																			"'switcher.output.video.mute.', ITOA(DgxDeviceSet[GET_LAST(DgxDeviceSet)].PORT)",
																			TRUE);
	}
	OFF:
	{
		DgxDeviceInfo.videoOutputPictureMute[GET_LAST(DgxDeviceSet)] = FALSE;
		DgxAssetParameterSetValueBoolean(
																			assetClientKey,
																			"'switcher.output.video.mute.', ITOA(DgxDeviceSet[GET_LAST(DgxDeviceSet)].PORT)",
																			FALSE);
	}
}
#END_IF
(***********************************************************)
(* Channel event for fan alarm                             *)
(***********************************************************)
CHANNEL_EVENT[dvMonitoredDevice, FAN_ALARM_CHANNEL]
{
	// If the runtime decision is that this device does not have
	// a fan, any incorrect channel events will be simply
	// be ignored at this point
	ON:
	{
		IF(DgxDeviceInfo.hasFan)
		{
			DgxDeviceInfo.fanAlarm = TRUE;
			DgxAssetParameterSetValueBoolean(assetClientKey, 'asset.fan.alarm', TRUE);
		}
	}

	OFF:
	{
		IF(DgxDeviceInfo.hasFan)
		{
			DgxDeviceInfo.fanAlarm = FALSE;
			DgxAssetParameterSetValueBoolean(assetClientKey, 'asset.fan.alarm', FALSE);
		}
	}
}

(***********************************************************)
(* Channel event for over temperature alarm                *)
(***********************************************************)
CHANNEL_EVENT[dvMonitoredDevice, TEMP_ALARM_CHANNEL]
{
	// If the runtime decision is that this device does not have
	// a temperature sensor, any incorrect channel events will
	// be simply be ignored at this point
	ON:
	{
		IF(DgxDeviceInfo.hasTemperatureSensor)
		{
			DgxDeviceInfo.tempAlarm = TRUE;
			DgxAssetParameterSetValueBoolean(assetClientKey, 'asset.temperature.alarm', TRUE);
		}
	}
	OFF:
	{
		IF(DgxDeviceInfo.hasTemperatureSensor)
		{
			DgxDeviceInfo.tempAlarm = FALSE;
			DgxAssetParameterSetValueBoolean(assetClientKey, 'asset.temperature.alarm', FALSE);
		}
	}
}

(***********************************************************)
(* Level event for over internal temperature               *)
(***********************************************************)
LEVEL_EVENT[dvMonitoredDevice, TEMP_LEVEL]
{
	// If the runtime decision is that this device does not have
	// a temperature sensor, any incorrect channel events will
	// be simply be ignored at this point


	IF(DgxDeviceInfo.hasTemperatureSensor)
	{
		IF(LEVEL.VALUE - DgxDeviceInfo.internalTemperature >= TEMPERATURE_DELTA || DgxDeviceInfo.internalTemperature - LEVEL.VALUE  >= TEMPERATURE_DELTA)
		{
			DgxDeviceInfo.internalTemperature = LEVEL.VALUE;
			DgxAssetParameterSetValueNumber(assetClientKey, 'asset.temperature', LEVEL.VALUE);
		}
  }
}

(***********************************************************)
(* Timeline for data structure update/refresh              *)
(***********************************************************)
TIMELINE_EVENT[TL_MONITOR]
{
	SWITCH(TIMELINE.SEQUENCE)
	{
		CASE 1: // This timeline sequence will ask for current parameter values
		{
			RequestDgxValuesUpdates();
		}
	}
}

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
