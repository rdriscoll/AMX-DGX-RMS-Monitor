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

MODULE_NAME='RmsDgxSwitcherMonitor'(DEV vdvRMS, DEV dvDGXSerialPort)
// 20130906 v0.1 RRD - modified 'RmsDvxSwitcherMonitor'
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

(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)

DEFINE_DEVICE

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

// This defines maximum string length for the purpose of
// dimentioning array sizes
INTEGER MAX_STRING_SIZE												= 50;
INTEGER MAX_ENUM_ENTRY_SIZE										= 50;

// These reflect default maximul values for inputs, ports, etc.
// and as such provide a consistent means to size arrays
INTEGER MAX_AUDIO_INPUT_CNT														= 16;
INTEGER MAX_AUDIO_OUTPUT_CNT													= 16;
INTEGER MAX_VIDEO_INPUT_CNT														= 16;
INTEGER MAX_VIDEO_OUTPUT_CNT													= 16;
INTEGER MAX_FAN_COUNT																	= 2;
INTEGER MAX_MIC_COUNT																	= 0;

CHAR ALL_INPUTS_MSG[]																	= 'All';
CHAR ALL_OUTPUTS_MSG[]																= 'All Outputs';
CHAR FRONT_PANEL_LOCK_TYPE_ENUM[]											= 'All|Unlocked|Configuration Only';	// Front panel locked values
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
LONG DgxMonitoringTimeArray[]													= {30000};		// Frequency of value update requests
SLONG SET_AUDIO_OUTPUT_LEVEL_DEFAULT									= 50;					// Default output volume level
SLONG SET_AUDIO_OUTPUT_LEVEL_MAX											= 100;				// Max volume level

// Device Channels
INTEGER BASE_VIDEO_INPUT_CHANNEL											= 30;				// The video input number is
																																	// added to this base to determine the channel
																																	// i.e. input 1 is channel 31
INTEGER BASE_AUDIO_INPUT_CHANNEL											= 40;				// The audio input number is
																																	// added to this base to determine the channel
																																	// i.e. input 1 is channel 41
INTEGER VIDEO_OUTPUT_ENABLE_CHANNEL										= 70;
INTEGER MIC_ENABLE_CHANNEL														= 71;
INTEGER STANDBY_STATE_CHANNEL													= 100;
INTEGER AUDIO_MUTE_CHANNEL														= 199;
INTEGER VIDEO_MUTE_CHANNEL														= 210;
INTEGER VIDEO_FREEZE_STATE_CHANNEL										= 213;
INTEGER FAN_ALARM_CHANNEL															= 216;
INTEGER TEMP_ALARM_CHANNEL														= 217;

// Device levels
INTEGER OUTPUT_VOLUME_LEVEL														= 1;
INTEGER TEMP_LEVEL																		= 8;

// Device ID's of various Dgx devices
INTEGER ID_Dgx3150HD_SP																= 354;		// 0x0162
INTEGER ID_Dgx3150HD_T																= 387;		// 0x0183
INTEGER ID_Dgx3155HD_SP																= 388;		// 0x0184
INTEGER ID_Dgx3155HD_T																= 389;		// 0x0185
INTEGER ID_Dgx2150HD_SP																= 390;		// 0x0186
INTEGER ID_Dgx2150HD_T																= 391;		// 0x0187
INTEGER ID_Dgx2155HD_SP																= 392;		// 0x0188
INTEGER ID_Dgx2155HD_T																= 393;		// 0x0189


(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

STRUCTURE RmsDgxInfo
{

	// variables for device capabilities
	CHAR hasFan;
	CHAR hasMicInput;
	CHAR hasTemperatureSensor;

	CHAR audioInputName[MAX_AUDIO_INPUT_CNT][MAX_ENUM_ENTRY_SIZE];	// Names assigned to audio inputs
	CHAR audioMicEnabled[MAX_MIC_COUNT];									// An array which contains true or false to
																										// indicate if a microphone is enabled
	CHAR audioOutputMute[MAX_AUDIO_OUTPUT_CNT];				// Each array entry contains the audio output
																										// mute status (TRUE or FALSE) for a specific channel
	CHAR fanAlarm;																		// TRUE to FALSE to indicate a fan alarm
	CHAR frontPanelLockType[MAX_STRING_SIZE]							// Lock type from valid panel lock types
	CHAR frontPanelLocked;														// TRUE or FALSE
	CHAR standbyState;																// Power standby state, TRUE or FALSE (also called low-power)
	CHAR tempAlarm;																		// TRUE to FALSE to indicate a temperature alarm
	CHAR videoInputFormat[MAX_VIDEO_INPUT_CNT][MAX_ENUM_ENTRY_SIZE];	// This contains the video input format. i.e. HDMI, etc.
	CHAR videoInputName[MAX_VIDEO_INPUT_CNT][MAX_ENUM_ENTRY_SIZE];	// Names assigned to video inputs
	CHAR videoOutputEnabled[MAX_VIDEO_OUTPUT_CNT];	 	// An array which indicates the video output
																										// enabled status (TRUE or FALSE) for each channel
	CHAR videoOutputPictureMute[MAX_VIDEO_OUTPUT_CNT];// An array which indicates the video output
																										// mute status (TRUE or FALSE) for each channel
	CHAR videoOutputScaleMode[MAX_VIDEO_OUTPUT_CNT][MAX_STRING_SIZE];	// Video output scale mode
	CHAR videoOutputVideoFreeze[MAX_VIDEO_OUTPUT_CNT];// An array which indicates the video output
																										// freeze status (TRUE or FALSE) for each channel
	INTEGER audioInputCount;
	INTEGER audioOutputCount;													// The total number of audio outputs
	INTEGER audioOutputSelectedSource[MAX_AUDIO_OUTPUT_CNT];	// Each array entry contains the audio input source number for a specific channel
	INTEGER audioOutputVolumeLevel[MAX_AUDIO_OUTPUT_CNT];	// Each array entry contains the audio output volume level for a specific channel
	INTEGER fanCount;
	INTEGER micInputCount;														// Number if microphone input devices
	INTEGER videoInputCount;
	INTEGER multiFormatVideoInputCount;								// This is the number of inputs which support all formats
	INTEGER hdmiFormatVideoInputCount;							// The number of inputs which support only digital formats
	INTEGER videoOutputCount;
	INTEGER videoOutputSelectedSource[MAX_VIDEO_OUTPUT_CNT];	// An array which indicates the input source number for each channel
	SLONG fanSpeed[MAX_FAN_COUNT];												// Each array entry contains the speed of a specific fan
	SLONG internalTemperature;
 }

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

CHAR devInit = FALSE;
CHAR hasValidDeviceId;
CHAR setAudioInputPortPlusNoneEnum[MAX_AUDIO_INPUT_CNT + 1][MAX_ENUM_ENTRY_SIZE]
CHAR setAudioOutputPortPlusAllEnum[MAX_AUDIO_OUTPUT_CNT + 1][MAX_ENUM_ENTRY_SIZE];
CHAR setPowerEnum[2][3];
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
											5002:14:0
										}

// Include RMS MONITOR COMMON AXI
#INCLUDE 'RmsMonitorCommon';

(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)

(***********************************************************)
(* Name:  DgxAssetParameterSetValueBoolean                                  *)
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
	if(IsRmsReadyForParameterUpdates() == TRUE)
	{
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
	if(IsRmsReadyForParameterUpdates() == TRUE)
	{
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
	if(IsRmsReadyForParameterUpdates() == TRUE)
	{
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

	// Build enumeration if input port selections
	setAudioInputPortPlusNoneEnum[1] = NO_INPUTS_MSG;
	FOR(index = 1; index <= DgxDeviceInfo.audioInputCount; index++)
	{
		setAudioInputPortPlusNoneEnum[index + 1] = "ITOA(index), ' - ', DgxDeviceInfo.audioInputName[index]";
	}
		
	// Build enumeration of output port selections
	setAudioOutputPortPlusAllEnum[1] = ALL_OUTPUTS_MSG;
	FOR(index = 1; index <= DgxDeviceInfo.audioOutputCount; index++)
	{
		setAudioOutputPortPlusAllEnum[index + 1] = ITOA(index);
	}
	
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
	
		// Standby or low-power state
		// parameter 1 = OFF means turn on standby power state
		// parameter 1 = ON means put the device in normal power state
		// i.e. turn off standby power mode
		ACTIVE(methodKey == 'asset.power'):
		{
			param1 = RmsParseCmdParam(DATA.TEXT);	
			IF(param1 == RmsGetEnumValue(2, SET_POWER_ENUM))				// Put in low/standby power mode
			{
				ON[dvMonitoredDevice, STANDBY_STATE_CHANNEL];
			}
			ELSE IF(param1 == RmsGetEnumValue(1, SET_POWER_ENUM))		// Put in normal power mode
			{
				OFF[dvMonitoredDevice, STANDBY_STATE_CHANNEL];
			}

			// Complain of a valid standby power state was not found
			IF(param1 != RmsGetEnumValue(1, SET_POWER_ENUM) && param1 != RmsGetEnumValue(2, SET_POWER_ENUM) )
			{
				AMX_LOG(AMX_WARNING, "MONITOR_DEBUG_NAME, '-ExecuteAssetControlMethod(): methodKey: ',
										methodKey, ' invalid standby power state: ', param1");
				RETURN;
			}
		}
	
		// Set audio source selection
		ACTIVE(methodKey == 'switcher.output.audio.switch'):
		{
			STACK_VAR CHAR audioInputPort[4];
			STACK_VAR INTEGER loopNdx1;
			
			param1 = RmsParseCmdParam(DATA.TEXT);			// Output port
			param2 = RmsParseCmdParam(DATA.TEXT);			// Input port
			audioInputPort = '';
			
			// If input is NO_INPUTS_MSG, disconnect the output from any inputs
			IF(param2 == NO_INPUTS_MSG)
			{
				audioInputPort = '0'
			}
			// Lookup the input port name and determine the port number
			ELSE
			{
				FOR(loopNdx1 = 1 ; loopNdx1 <= LENGTH_ARRAY(setAudioInputPortPlusNoneEnum); loopNdx1++)
				{
					IF(setAudioInputPortPlusNoneEnum[loopNdx1 + 1] == param2)
					{
						audioInputPort = ITOA(loopNdx1);
						BREAK;
					}
				}
				
				// Note: This should only happen if the port name was changed 
				// after the control methods were registered.
				// Warn if there was no match between selected port name and the list
				// of possible port names
				IF(audioInputPort == '')
				{
					AMX_LOG(AMX_WARNING, "MONITOR_DEBUG_NAME, '-ExecuteAssetControlMethod(): methodKey: ',
										methodKey, ' invalid input port name: ', param2");
					RETURN;
				}
			}
			
			// Set the desired input
			IF(param1 == ALL_OUTPUTS_MSG)
			{
				FOR(loopNdx1 = 1 ; loopNdx1 <= DgxDeviceInfo.videoOutputCount; loopNdx1++)
				{
					SEND_COMMAND dvMonitoredDevice, "'AI', audioInputPort, 'O', ITOA(loopNdx1)";
				}
			}
			ELSE
			{
				SEND_COMMAND dvMonitoredDevice, "'AI', audioInputPort, 'O', param1";
			}
		}

		// Video source selection
		ACTIVE(methodKey == 'switcher.output.video.switch'):
		{
			STACK_VAR CHAR videoInputPort[4];
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

		// Set audio output volume
		ACTIVE(methodKey == 'switcher.output.audio.volume'):
		{
			STACK_VAR INTEGER portNum;

			param1 = RmsParseCmdParam(DATA.TEXT);
			param2 = RmsParseCmdParam(DATA.TEXT);

			IF(param1 == ALL_OUTPUTS_MSG)
			{
				FOR(portNum = 1; portNum <= DgxDeviceInfo.audioOutputCount; portNum++)
				{
					SEND_LEVEL DgxDeviceSet[portNum], OUTPUT_VOLUME_LEVEL, ATOI(param2);
				}
			}
			ELSE
			{
				SEND_LEVEL DgxDeviceSet[ATOI(param1)], OUTPUT_VOLUME_LEVEL, ATOI(param2);
			}
		}

		// Set front panel lockout type
		ACTIVE(methodKey == 'asset.front.panel.lockout'):
		{
			STACK_VAR INTEGER enumNdx;											// Enumeration index for a valid lockout type
			STACK_VAR INTEGER lockoutTypeInt;								// Integer representation of lockout type

			param1 = RmsParseCmdParam(DATA.TEXT);
			lockoutTypeInt = 0;

			FOR(enumNdx = 1; enumNdx <= LENGTH_ARRAY(SET_FRONT_PANEL_LOCKOUT_ENUM); enumNdx++)
			{
				IF(param1 == SET_FRONT_PANEL_LOCKOUT_ENUM[enumNdx])
				{
					lockoutTypeInt = enumNdx;
					BREAK;
				}
			}

			// Complain of a valid lockout type was not found
			IF(lockoutTypeInt == 0)
			{
				AMX_LOG(AMX_WARNING, "MONITOR_DEBUG_NAME, '-ExecuteAssetControlMethod(): methodKey: ',
										methodKey, ' invalid lockout type: ', param1");
				RETURN;
			}

			IF(lockoutTypeInt == 2)
			{
				SEND_COMMAND dvMonitoredDevice, 'FP_LOCKOUT-DISABLE';
			}
			ELSE
			{
				SEND_COMMAND dvMonitoredDevice, "'FP_LOCKTYPE-', ITOA(lockoutTypeInt)";
				SEND_COMMAND dvMonitoredDevice, 'FP_LOCKOUT-ENABLE';
			}
		}

		// Set audio mute
		ACTIVE(methodKey == 'switcher.output.audio.mute'):
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
				FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.audioOutputCount; ndx1++)
				{
					[DgxDeviceSet[ndx1], AUDIO_MUTE_CHANNEL] = muteState;
				}
			}
			ELSE
			{
				[DgxDeviceSet[ATOI(param1)], AUDIO_MUTE_CHANNEL] = muteState;
			}
		}

		// Set audio Mic State
		ACTIVE(methodKey == 'switcher.output.audio.mic.enabled'):
		{
			STACK_VAR CHAR enableState;
			STACK_VAR INTEGER ndx1;

			param1 = RmsParseCmdParam(DATA.TEXT);
			param2 = RmsParseCmdParam(DATA.TEXT);

			IF(param2 == '0')
			{
				enableState = FALSE;
			}

			ELSE IF(param2 == '1')
			{
				enableState = TRUE;
			}
			ELSE
			{
				AMX_LOG(AMX_WARNING, "MONITOR_DEBUG_NAME, '-ExecuteAssetControlMethod(): methodKey: ',
									methodKey, ' port: ', param1, ' unexpected state: ', param2");
				RETURN;
			}

			IF(param1 == ALL_INPUTS_MSG)
			{
				FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.micInputCount; ndx1++)
				{
					[DgxDeviceSet[ndx1], MIC_ENABLE_CHANNEL] = enableState;
				}
			}
			ELSE
			{
				[DgxDeviceSet[ATOI(param1)], MIC_ENABLE_CHANNEL] = enableState;
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
				}
			}
			ELSE
			{
				[DgxDeviceSet[ATOI(param1)], VIDEO_MUTE_CHANNEL] = muteState;
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
	DgxDeviceInfo.hasMicInput									= FALSE;
	DgxDeviceInfo.hasTemperatureSensor				= FALSE;

	DgxDeviceInfo.audioInputCount							= 0;
	DgxDeviceInfo.audioOutputCount						= 0;
	DgxDeviceInfo.fanAlarm										= FALSE;
	DgxDeviceInfo.fanCount										= 0;
	DgxDeviceInfo.micInputCount								= 0;
	DgxDeviceInfo.frontPanelLockType					= SET_FRONT_PANEL_LOCKOUT_ENUM[2];
	DgxDeviceInfo.standbyState								= FALSE;
	DgxDeviceInfo.videoInputCount							= 0;
	DgxDeviceInfo.multiFormatVideoInputCount	= 0;
	DgxDeviceInfo.hdmiFormatVideoInputCount		= 0;
	DgxDeviceInfo.videoOutputCount						= 0;

	SWITCH(devInfo.DEVICE_ID)
	{
		CASE ID_Dgx3150HD_SP:		// Dgx-3150HD-SP
		CASE ID_Dgx3150HD_T:		// Dgx-3150HD-T
		CASE ID_Dgx3155HD_SP:		// Dgx-3155HD-SP
		CASE ID_Dgx3155HD_T:		// Dgx-3155HD-T
		{

			// Make runtime decisions about device capabilites
			DgxDeviceInfo.hasFan											= TRUE;
			DgxDeviceInfo.hasMicInput									= TRUE;
			DgxDeviceInfo.hasTemperatureSensor				= TRUE;

			DgxDeviceInfo.audioInputCount							= 14;
			DgxDeviceInfo.audioOutputCount						= 4;
			DgxDeviceInfo.fanCount										= 2;
			DgxDeviceInfo.micInputCount								= 2;
			DgxDeviceInfo.videoInputCount							= 10;
			DgxDeviceInfo.multiFormatVideoInputCount	= 4;
			DgxDeviceInfo.hdmiFormatVideoInputCount		= 6;
			DgxDeviceInfo.videoOutputCount						= 4;
		}
		
		CASE ID_Dgx2150HD_SP:		// Dgx-2150HD-SP
		CASE ID_Dgx2150HD_T:		// Dgx-2150HD-T
		CASE ID_Dgx2155HD_SP:		// Dgx-2155HD-SP
		CASE ID_Dgx2155HD_T:		// Dgx-2155HD-T
		{

			// Make runtime decisions about device capabilites
			DgxDeviceInfo.hasFan											= TRUE;
			DgxDeviceInfo.hasMicInput									= TRUE;
			DgxDeviceInfo.hasTemperatureSensor				= TRUE;

			DgxDeviceInfo.audioInputCount							= 8;
			DgxDeviceInfo.audioOutputCount						= 2;
			DgxDeviceInfo.micInputCount								= 2;
			DgxDeviceInfo.videoInputCount							= 6;
			DgxDeviceInfo.multiFormatVideoInputCount	= 2;
			DgxDeviceInfo.hdmiFormatVideoInputCount		= 4;
			DgxDeviceInfo.videoOutputCount						= 2;
		}

		DEFAULT:
		{
			AMX_LOG(AMX_WARNING, "MONITOR_DEBUG_NAME, '-InitDefaults: Unexpected DEVICE_ID: ',  ITOA(devInfo.DEVICE_ID)");
			hasValidDeviceId = FALSE;
			RETURN;
		}
	}
	
	// Since these are not explicitly initalized they must be sized
	SET_LENGTH_ARRAY(setAudioInputPortPlusNoneEnum, DgxDeviceInfo.audioInputCount + 1);
	SET_LENGTH_ARRAY(setAudioOutputPortPlusAllEnum, DgxDeviceInfo.audioOutputCount + 1);
	SET_LENGTH_ARRAY(setPowerEnum, 2);
	SET_LENGTH_ARRAY(setVideoInputPortPlusNoneEnum, DgxDeviceInfo.videoInputCount + 1);
	SET_LENGTH_ARRAY(setVideoOutputPortPlusAllEnum, DgxDeviceInfo.videoOutputCount + 1);

	// Dynamically build set power enum to make sure it tracks SET_POWER_ENUM
	setPowerEnum[1] =  RmsGetEnumValue(1, SET_POWER_ENUM);
	setPowerEnum[2] =  RmsGetEnumValue(2, SET_POWER_ENUM);
	
	// Initalize values associated with microphone input
	IF(DgxDeviceInfo.hasMicInput == TRUE)
	{
		FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.micInputCount; ndx1++)
		{
			DgxDeviceInfo.audioMicEnabled[ndx1] = FALSE;
			
			// Request the current mic status
			SEND_COMMAND DgxDeviceSet[ndx1], '?AUDMIC_ON';
		}
	}

	// Initalize audio output values
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.audioOutputCount; ndx1++)
	{
		
		// Initalize to some sane value, then request the current audio mute state
		DgxDeviceInfo.audioOutputMute[ndx1] = FALSE;
		SEND_COMMAND DgxDeviceSet[ndx1], '?AUDOUT_MUTE';
		
		DgxDeviceInfo.audioOutputVolumeLevel[1] = 0;

		// Request the current volume level for each output
		SEND_COMMAND DgxDeviceSet[ndx1], '?AUDOUT_VOLUME';
	}
	
	// Walk through each video output variable and initialize some sane value
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.videoOutputCount; ndx1++)
	{
		DgxDeviceInfo.videoOutputScaleMode[ndx1]		= 'AUTO';
		
		// After assigning some sane value, request the current video freeze value
		DgxDeviceInfo.videoOutputVideoFreeze[ndx1]	= FALSE;
		SEND_COMMAND DgxDeviceSet[ndx1], '?VIDOUT_FREEZE';

		// Request the current video mute state
		DgxDeviceInfo.videoOutputPictureMute[ndx1]	= FALSE;
		SEND_COMMAND DgxDeviceSet[ndx1], '?VIDOUT_MUTE';

		// Ask for the current video output enable state
		DgxDeviceInfo.videoOutputEnabled[ndx1] 			= TRUE;
		SEND_COMMAND DgxDeviceSet[ndx1], '?VIDOUT_ON';
	}

  // Initalize BooleanValues
  DgxDeviceInfo.frontPanelLocked = FALSE;

  // Initalize BooleanValues
  IF(DgxDeviceInfo.hasFan == TRUE)
  {
		FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.fanCount; ndx1++)
		{
			DgxDeviceInfo.fanSpeed[ndx1] = 0;
		}
		DgxDeviceInfo.fanAlarm = FALSE;
	}

  IF(DgxDeviceInfo.hasTemperatureSensor)
  {
		DgxDeviceInfo.internalTemperature			= 0;
		DgxDeviceInfo.tempAlarm								= FALSE;

		// Ask for the current temperature then leave the event handler to
		// keep the value current
		SEND_COMMAND dvMonitoredDevice, "'?TEMP'";
	}

	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.audioInputCount; ndx1++)
	{		
		// Initalize audio input name
		DgxDeviceInfo.audioInputName[ndx1] =  "'Source Name ', ITOA(ndx1)";
		SEND_COMMAND DgxDeviceSet[ndx1], '?AUDIN_NAME';
		
		// Ask for current audio input selected sources
		SEND_COMMAND dvMonitoredDevice, "'?OUTPUT-AUDIO,', ITOA(ndx1)";
	}

	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.videoInputCount;ndx1++)
	{		
		// Initalize video input name
		DgxDeviceInfo.videoInputName[ndx1] =  "'Source Name ', ITOA(ndx1)";
		SEND_COMMAND DgxDeviceSet[ndx1], '?VIDIN_NAME';
	
		// Ask for current video input selected sources
		SEND_COMMAND dvMonitoredDevice, "'?OUTPUT-VIDEO,', ITOA(ndx1)";
		
		// Initalilze video input format for each port
		DgxDeviceInfo.videoInputFormat[ndx1] = "";
		SEND_COMMAND DgxDeviceSet[ndx1], '?VIDIN_FORMAT';
	}
	
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

	// If this device does not have a valid device ID, 
	// simply return without doing anything
	IF(hasValidDeviceId == FALSE)
	{
		RETURN;
	}

	// Query for front panel lock type
	SEND_COMMAND dvMonitoredDevice, "'?FP_LOCKOUT'";		// Request the front panel lockout type
	SEND_COMMAND dvMonitoredDevice, "'?FP_LOCKTYPE'";		// Request the front panel lockout type

	// If the device has fans, get fan information
	IF(DgxDeviceInfo.hasFan == TRUE)
	{
		FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.fanCount; ndx1++)
		{
			SEND_COMMAND dvMonitoredDevice, "'?FAN_SPEED-', ITOA(ndx1)";
		}
	}

	// Get video output information
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.videoOutputCount; ndx1++)
	{
		SEND_COMMAND DgxDeviceSet[ndx1], '?VIDOUT_SCALE';
	}

	// Get video input information
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.videoInputCount; ndx1++)
	{
		SEND_COMMAND DgxDeviceSet[ndx1], '?VIDIN_NAME';
	}

	// Get audio input information
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.audioInputCount; ndx1++)
	{
		SEND_COMMAND DgxDeviceSet[ndx1], '?AUDIN_NAME';
	}
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

	RmsAssetMetadataEnqueueNumber(assetClientKey, 'switcher.input.video.count', 'Video Input Count', DgxDeviceInfo.videoInputCount);
	RmsAssetMetadataEnqueueNumber(assetClientKey, 'switcher.output.video.count', 'Video Output Count', DgxDeviceInfo.videoOutputCount);

	RmsAssetMetadataEnqueueNumber(assetClientKey, 'switcher.input.audio.count', 'Audio Input Count', DgxDeviceInfo.audioInputCount);
	RmsAssetMetadataEnqueueNumber(assetClientKey, 'switcher.output.audio.count', 'Audio Output Count', DgxDeviceInfo.audioOutputCount);

	RmsAssetMetadataEnqueueNumber(assetClientKey, 'switcher.input.mic.count', 'Mic Input Count', DgxDeviceInfo.micInputCount);

	// Audio Input Name
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.audioInputCount; ndx1++)
	{
		keyName						= "'switcher.input.audio.name.', ITOA(ndx1)";
		propertyName			= "'Audio Input ', ITOA(ndx1), ' - Name'";
		RmsAssetMetadataEnqueueString(assetClientKey, keyName, propertyName, setAudioInputPortPlusNoneEnum[ndx1 + 1]);
	}

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
		FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.fanCount; ndx1++)
		{
			paramDesc			= "'Fan ', ITOA(ndx1), ' speed'";
			paramKey			= "'asset.fan.speed.', ITOA(ndx1)";
			paramName			= "'Fan ', ITOA(ndx1), ' Speed'";

			RmsAssetParameterEnqueueNumber(
																			assetClientKey,
																			paramKey,										// Parameter key
																			paramName,									// Parameter name
																			paramDesc,									// Parameter description
																			RMS_ASSET_PARAM_TYPE_NONE,	// RMS Asset Parameter (Reporting) Type
																			DgxDeviceInfo.fanSpeed[ndx1],	// Default value
																			0,													// Minimum value
																			0,													// Maximum value
																			'RPM',											// Units
																			RMS_ALLOW_RESET_NO,					// RMS Asset Parameter Reset
																			0,													// Reset value
																			RMS_TRACK_CHANGES_NO				// RMS Asset Parameter History Tracking
																	);
		}

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

	// Front Panel Locked
	RmsAssetParameterEnqueueBoolean(
																		assetClientKey,
																		'asset.front.panel.lockout',		// Parameter key
																		'Front Panel Locked',						// Parameter name
																		'Front panel locked',						// Parameter description
																		RMS_ASSET_PARAM_TYPE_NONE,			// RMS Asset Parameter (Reporting) Type
																		DgxDeviceInfo.frontPanelLocked,	// Default value
																		RMS_ALLOW_RESET_NO,							// RMS Asset Parameter Reset
																		FALSE,													// Reset value
																		RMS_TRACK_CHANGES_NO						// RMS Asset Parameter History Tracking
																);

	// Front Panel Lockout Type
	RmsAssetParameterEnqueueEnumeration(
																				assetClientKey,
																				'asset.front.panel.lockout.type',			// Parameter key
																				'Front Panel Lockout',						// Parameter name
																				'Front panel lockout',
																				RMS_ASSET_PARAM_TYPE_NONE,				// RMS Asset Parameter (Reporting) Type
																				DgxDeviceInfo.frontPanelLockType,	// Default value
																				FRONT_PANEL_LOCK_TYPE_ENUM,				// Enumeration
																				RMS_ALLOW_RESET_NO,								// RMS Asset Parameter Reset
																				'',																// Reset value
																				RMS_TRACK_CHANGES_NO							// RMS Asset Parameter History Tracking
																		);

	// Audio Output Mute
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.audioOutputCount; ndx1++)
	{
		paramBooleanValue = DgxDeviceInfo.audioOutputMute[ndx1];
		paramDesc					= "'Audio output ', ITOA(ndx1), ' mute'";
		paramKey					= "'switcher.output.audio.mute.', ITOA(ndx1)";
		paramName					= "'Audio Output ', ITOA(ndx1), ' - Mute'";

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

	// Audio Output Volume Level
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.audioOutputCount; ndx1++)
	{
		paramDesc			= "'Audio output ', ITOA(ndx1), ' volume level'";
		paramKey			= "'switcher.output.audio.volume.', ITOA(ndx1)";
		paramName			= "'Audio Output ', ITOA(ndx1), ' Volume Level'";

		RmsAssetParameterEnqueueLevel(
																								assetClientKey,
																								paramKey,										// Parameter key
																								paramName,									// Parameter name
																								paramDesc,									// Parameter description
																								RMS_ASSET_PARAM_TYPE_NONE,	// RMS Asset Parameter (Reporting) Type
																								DgxDeviceInfo.audioOutputVolumeLevel[ndx1],							// Default value
																								0,													// Minimum value
																								SET_AUDIO_OUTPUT_LEVEL_MAX,	// Maximum value
																								'%',												// Units
																								RMS_ALLOW_RESET_NO,					// RMS Asset Parameter Reset
																								0,													// Reset value
																								RMS_TRACK_CHANGES_NO,				// RMS Asset Parameter History Tracking
																								RMS_ASSET_PARAM_BARGRAPH_VOLUME_LEVEL										// Bargraph key
																							);
		};

	// Audio Output Selected Source
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.audioOutputCount; ndx1++)
	{

		paramDesc		= "'Audio output ', ITOA(ndx1), ' selected source'";
		paramKey		= "'switcher.output.audio.switch.input.', ITOA(ndx1)";
		paramName		= "'Audio Output ', ITOA(ndx1), ' - Selected Source'";
		inputNumber	= DgxDeviceInfo.audioOutputSelectedSource[ndx1];
		
		// Get the input source name or say None if not connected
		IF(inputNumber > 0)
		{
			 sourceName = setAudioInputPortPlusNoneEnum[inputNumber + 1];
		}
		ELSE
		{
			sourceName = NO_INPUTS_MSG;
		}
		RmsAssetParameterEnqueueString(
																		assetClientKey,
																		paramKey,					// Parameter key
																		paramName,					// Parameter name
																		paramDesc,					// Parameter description
																		RMS_ASSET_PARAM_TYPE_NONE,	// RMS Asset Parameter (Reporting) Type
																		sourceName,
																		'',							// Units
																		RMS_ALLOW_RESET_NO,			// RMS Asset Parameter Reset
																		'',							// Reset value
																		RMS_TRACK_CHANGES_NO		// RMS Asset Parameter History Tracking
																	);
	}

	IF(DgxDeviceInfo.hasMicInput == TRUE)
	{
		// Audio Mic Enabled
		FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.micInputCount; ndx1++)
		{
			paramBooleanValue	= DgxDeviceInfo.audioMicEnabled[ndx1]
			paramDesc					= "'Audio mic ', ITOA(ndx1), ' enabled'";
			paramKey					= "'switcher.input.mic.enabled.', ITOA(ndx1)";
			paramName					= "'Audio Mic ', ITOA(ndx1), ' - Enabled'";

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

	// Video Output Enabled
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.videoOutputCount; ndx1++)
	{
		paramBooleanValue	= DgxDeviceInfo.videoOutputEnabled[ndx1];
		paramDesc					= "'Video output ', ITOA(ndx1), ' enabled'";
		paramKey					= "'switcher.output.video.enabled.', ITOA(ndx1)";
		paramName					= "'Video Output ', ITOA(ndx1), ' - Enabled'";

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

	// Video Output Video Freeze
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.videoOutputCount; ndx1++)
	{
		paramBooleanValue	= DgxDeviceInfo.videoOutputVideoFreeze[ndx1];
		paramDesc					= "'Video output ', ITOA(ndx1), ' video freeze'";
		paramKey					= "'switcher.output.video.freeze.', ITOA(ndx1)";
		paramName					= "'Video Output ', ITOA(ndx1), ' - Video Freeze'";

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
	
	RmsAssetControlMethodEnqueue(
																assetClientKey,
																'asset.front.panel.lockout',
																'Set Front Panel Lockout',
																'Set front panel lockout.');

	RmsAssetControlMethodArgumentEnumEx(
																			assetClientKey,
																			'asset.front.panel.lockout',
																			0,
																			'Front Panel Lockout',
																			'Select front panel lockout',
																			SET_FRONT_PANEL_LOCKOUT_ENUM[2],
																			SET_FRONT_PANEL_LOCKOUT_ENUM);

	RmsAssetControlMethodEnqueue(
																assetClientKey,
																'switcher.output.audio.switch',
																'Select Audio Source',
																'Select audio source');

	RmsAssetControlMethodArgumentEnumEx(
																			assetClientKey,
																			'switcher.output.audio.switch',
																			0,
																			'Output Port',
																			'Output port select',
																			setAudioOutputPortPlusAllEnum[1],
																			setAudioOutputPortPlusAllEnum);

	RmsAssetControlMethodArgumentEnumEx(
																			assetClientKey,
																			'switcher.output.audio.switch',
																			1,
																			'Input Port',
																			"'Input port [', NO_INPUTS_MSG, ' = No Input]'",
																			setAudioInputPortPlusNoneEnum[1],
																			setAudioInputPortPlusNoneEnum);

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
																'switcher.output.audio.volume',
																'Set Volume',
																'Set Volume');

	RmsAssetControlMethodArgumentEnumEx(
																			assetClientKey,
																			'switcher.output.audio.volume',
																			0,
																			'Output Port',
																			'Output port',
																			setAudioOutputPortPlusAllEnum[1],
																			setAudioOutputPortPlusAllEnum);

	RmsAssetControlMethodArgumentLevel(
																			assetClientKey,
																			'switcher.output.audio.volume',
																			1,
																			'Volume',
																			'Volume level',
																			SET_AUDIO_OUTPUT_LEVEL_DEFAULT,
																			0,
																			SET_AUDIO_OUTPUT_LEVEL_MAX,
																			1);

	RmsAssetControlMethodEnqueue(
																	assetClientKey,
																	'switcher.output.audio.mute',
																	'Set Audio Mute',
																	'Set audio mute');

	RmsAssetControlMethodArgumentEnumEx(
																				assetClientKey,
																				'switcher.output.audio.mute',
																				0,
																				'Output Port',
																				'Output Port',
																				setAudioOutputPortPlusAllEnum[1],
																				setAudioOutputPortPlusAllEnum);

	RmsAssetControlMethodArgumentBoolean(
																				assetClientKey,
																				'switcher.output.audio.mute',
																				1,
																				'Enabled',
																				'Enabled',
																				FALSE);

	IF(DgxDeviceInfo.hasMicInput == TRUE)
	{

		STACK_VAR CHAR setMicInputPlusAllEnum[MAX_MIC_COUNT + 1][3];
		STACK_VAR INTEGER loopNdx;
		
		SET_LENGTH_ARRAY(setMicInputPlusAllEnum, DgxDeviceInfo.micInputCount + 1);
			
		// Build enumeration of output port selections
		FOR(loopNdx = 1; loopNdx <= DgxDeviceInfo.micInputCount; loopNdx++)
		{
			setMicInputPlusAllEnum[loopNdx + 1] = ITOA(loopNdx);
		}
		setMicInputPlusAllEnum[1] = ALL_INPUTS_MSG;
	
		RmsAssetControlMethodEnqueue(
																	assetClientKey,
																	'switcher.output.audio.mic.enabled',
																	'Set Audio Mic State',
																	'Set Audio Mic State');
	
		RmsAssetControlMethodArgumentEnumEx(
																				assetClientKey,
																				'switcher.output.audio.mic.enabled',
																				0,
																				'Output Port',
																				'Output Port',
																				setMicInputPlusAllEnum[1],
																				setMicInputPlusAllEnum);
	
		RmsAssetControlMethodArgumentBoolean(
																					assetClientKey,
																					'switcher.output.audio.mic.enabled',
																					1,
																					'Enabled',
																					'Enabled',
																					FALSE);
	}

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

	RmsAssetMetadataUpdateNumber(assetClientKey, 'switcher.input.video.count', DgxDeviceInfo.videoInputCount);
	RmsAssetMetadataUpdateNumber(assetClientKey, 'switcher.output.video.count', DgxDeviceInfo.videoOutputCount);

	RmsAssetMetadataUpdateNumber(assetClientKey, 'switcher.input.audio.count', DgxDeviceInfo.audioInputCount);
	RmsAssetMetadataUpdateNumber(assetClientKey, 'switcher.output.audio.count', DgxDeviceInfo.audioOutputCount);

	RmsAssetMetadataUpdateNumber(assetClientKey, 'switcher.input.mic.count', DgxDeviceInfo.micInputCount);

	// Audio Input Name
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.audioInputCount; ndx1++)
	{
		keyName = "'switcher.input.audio.name.', ITOA(ndx1)";
		RmsAssetMetadataUpdateString(assetClientKey, keyName, setAudioInputPortPlusNoneEnum[ndx1 + 1]);
	}

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
}

(***********************************************************)
(* Name:  SyncAudioOutputSource                            *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  Called to synchronize audio output selected      *)
(* source                                                  *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION SyncAudioOutputSource()
{
	STACK_VAR CHAR sourceName[MAX_STRING_SIZE];
	STACK_VAR INTEGER index1;
	STACK_VAR INTEGER inputNumber;

	UpdatePortEnums();
	
	// Audio Output Selected Source
	FOR(index1 = 1; index1 <= DgxDeviceInfo.audioOutputCount; index1++)
	{
		inputNumber = DgxDeviceInfo.audioOutputSelectedSource[index1];
		
		// The the audio input source name or NO_INPUTS_MSG if not connected
		IF(inputNumber > 0)
		{
			sourceName = setAudioInputPortPlusNoneEnum[inputNumber + 1];
		}
		ELSE
		{
			sourceName = NO_INPUTS_MSG;
		}
		
		DgxAssetParameterSetValue(assetClientKey, "'switcher.output.audio.switch.input.', ITOA(index1)", sourceName);
	}
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
	STACK_VAR INTEGER ndx1;
	
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
		FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.fanCount; ndx1++)
		{
			paramKey = "'asset.fan.speed.', ITOA(ndx1)";
			RmsAssetParameterEnqueueSetValueNumber(assetClientKey, paramKey, DgxDeviceInfo.fanSpeed[ndx1]);
		}

		RmsAssetParameterEnqueueSetValueBoolean(assetClientKey, 'asset.fan.alarm', DgxDeviceInfo.fanAlarm);
  }

	paramKey = 'asset.front.panel.lockout';
	RmsAssetParameterEnqueueSetValueBoolean(assetClientKey, paramKey, DgxDeviceInfo.frontPanelLocked);

	paramKey = 'asset.front.panel.lockout.type';
	RmsAssetParameterEnqueueSetValue(assetClientKey, paramKey, DgxDeviceInfo.frontPanelLockType);

	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.audioOutputCount; ndx1++)
	{

		paramKey = "'switcher.output.audio.mute.', ITOA(ndx1)";
		RmsAssetParameterEnqueueSetValueBoolean(assetClientKey, paramKey, DgxDeviceInfo.audioOutputMute[ndx1]);

		paramKey = "'switcher.output.audio.volume.', ITOA(ndx1)";
		RmsAssetParameterEnqueueSetValueNumber(assetClientKey, paramKey, DgxDeviceInfo.audioOutputVolumeLevel[1]);
  }

	IF(DgxDeviceInfo.hasMicInput == TRUE)
	{
		FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.micInputCount; ndx1++)
		{
			RmsAssetParameterEnqueueSetValueBoolean(
																							assetClientKey,
																							"'switcher.input.mic.enabled.', ITOA(ndx1)",
																							DgxDeviceInfo.audioMicEnabled[ndx1]);
		}
	}

	// Sync video output parameters
	FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.videoOutputCount; ndx1++)
	{
		paramKey = "'switcher.output.video.enabled.', ITOA(ndx1)";
		RmsAssetParameterEnqueueSetValueBoolean(assetClientKey, paramKey, DgxDeviceInfo.videoOutputEnabled[ndx1]);

		paramKey = "'switcher.output.video.mute.', ITOA(ndx1)";
		RmsAssetParameterEnqueueSetValueBoolean(assetClientKey, paramKey, DgxDeviceInfo.videoOutputPictureMute[ndx1]);

		paramKey = "'switcher.output.video.freeze.', ITOA(ndx1)";;
		RmsAssetParameterEnqueueSetValueBoolean(assetClientKey, paramKey, DgxDeviceInfo.videoOutputVideoFreeze[ndx1]);

		paramKey = "'switcher.output.video.scale.mode.', ITOA(ndx1)";;
		RmsAssetParameterEnqueueSetValue(assetClientKey, paramKey, DgxDeviceInfo.videoOutputScaleMode[ndx1]);
  }

	// Sync audio output information
  FOR(ndx1 = 1; ndx1 <= DgxDeviceInfo.audioOutputCount; ndx1++)
  {
		paramKey = "'switcher.output.audio.mute.', ITOA(ndx1)";
		RmsAssetParameterEnqueueSetValueBoolean(assetClientKey, paramKey, DgxDeviceInfo.audioOutputMute[1]);

		paramKey = "'switcher.output.audio.volume.', ITOA(ndx1)";
		RmsAssetParameterEnqueueSetValueNumber(assetClientKey, paramKey, DgxDeviceInfo.audioOutputVolumeLevel[1]);
  }

  // submit all the pending parameter updates now
  RmsAssetParameterUpdatesSubmit(assetClientKey);

	// These methods do not queue changes but simply perform an update
	SyncAudioOutputSource();
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
DEFINE_FUNCTION ResetAssetParameterValue(CHAR parameterKey[],CHAR parameterValue[])
{
}

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

		SELECT
		{

			// Update fan speed if it exceeds a specific threshold
			ACTIVE(header == 'FAN_SPEED'):
			{
				IF(DgxDeviceInfo.hasFan = TRUE)
				{
					STACK_VAR INTEGER fanNumber;
					STACK_VAR SLONG newSpeed;

					param1 = RmsParseCmdParam(DATA.TEXT);
					param2 = RmsParseCmdParam(DATA.TEXT);

					fanNumber = ATOI(param1);
					newSpeed = ATOL(param2);

					// if the speed change exceeds threshold send update
					IF(newSpeed - DgxDeviceInfo.fanSpeed[fanNumber] >= FAN_SPEED_DELTA || DgxDeviceInfo.fanSpeed[fanNumber] - newSpeed  >= FAN_SPEED_DELTA)
					{
						DgxDeviceInfo.fanSpeed[fanNumber] = newSpeed;
						DgxAssetParameterSetValueNumber(assetClientKey, "'asset.fan.speed.', fanNumber", newSpeed);
					}
				}
			}

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

			// This data event handler is only used to provide initial volume
			// information when the device comes online
			ACTIVE(header == 'AUDOUT_VOLUME'):
			{
				STACK_VAR INTEGER newVolumeValue;

				param1 = RmsParseCmdParam(DATA.TEXT);
				newVolumeValue = ATOI(param1);
				IF(newVolumeValue != DgxDeviceInfo.audioOutputVolumeLevel[eventDevicePort])
				{
					DgxDeviceInfo.audioOutputVolumeLevel[eventDevicePort] = newVolumeValue;
					DgxAssetParameterSetValueNumber(
																					assetClientKey,
																					"'switcher.output.audio.volume.', eventDevicePort",
																					newVolumeValue);
				}
			}

			// Internal temperature is managed from a level event handler; however
			// this data event handler provides a means to query for the initial
			// value when the device comes online
			ACTIVE(header == 'TEMP'):
			{
				IF(DgxDeviceInfo.hasTemperatureSensor = TRUE)
				{
					STACK_VAR SLONG newTemp;

					param1 = RmsParseCmdParam(DATA.TEXT);
					newTemp = ATOI(param1);
					// if the temperature change exceeds threshold send update
					IF(newTemp - DgxDeviceInfo.internalTemperature >= TEMPERATURE_DELTA || DgxDeviceInfo.internalTemperature - newTemp  >= TEMPERATURE_DELTA)
					{
						DgxDeviceInfo.internalTemperature = newTemp;
						DgxAssetParameterSetValueNumber(assetClientKey, 'asset.temperature', newTemp);
					}
				}
			}

			// Note: Audio and video output mute is handled by a channel event; however, this 
			// is provided to make sure the initial value is correct when the device
			// comes online
			ACTIVE(header == 'AUDOUT_MUTE' || header == 'VIDOUT_MUTE'):
			{
				STACK_VAR CHAR cachesState;
				STACK_VAR CHAR newState;
				
				param1	= UPPER_STRING(RmsParseCmdParam(DATA.TEXT));			
				IF(param1 == 'ENABLE')
				{
					newState = TRUE;
				}
				ELSE
				{
					newState = FALSE;
				}

				IF(header == 'AUDOUT_MUTE')
				{
					cachesState = DgxDeviceInfo.audioOutputMute[eventDevicePort];
				}
				ELSE
				{
					cachesState = DgxDeviceInfo.videoOutputPictureMute[eventDevicePort];
				}
				IF(cachesState != newState)
				{
					IF(header == 'AUDOUT_MUTE')
					{
						DgxDeviceInfo.audioOutputMute[eventDevicePort] = newState;
						DgxAssetParameterSetValueBoolean(assetClientKey, "'switcher.output.audio.mute.', ITOA(eventDevicePort)", newState);
					}
					ELSE
					{
						DgxDeviceInfo.videoOutputPictureMute[eventDevicePort] = newState;
						DgxAssetParameterSetValueBoolean(assetClientKey, "'switcher.output.video.mute.', ITOA(eventDevicePort)", newState);
					}
				}
			}

			// Note: Video output freeze is handled by a channel event; however, this 
			// is provided to make sure the initial value is correct when the device
			// comes online
			ACTIVE(header == 'VIDOUT_FREEZE'):
			{
				STACK_VAR CHAR newState;
				
				param1	= UPPER_STRING(RmsParseCmdParam(DATA.TEXT));			
				IF(param1 == 'ENABLE')
				{
					newState = TRUE;
				}
				ELSE
				{
					newState = FALSE;
				}

				IF(DgxDeviceInfo.videoOutputVideoFreeze[eventDevicePort] != newState)
				{
					DgxDeviceInfo.videoOutputVideoFreeze[eventDevicePort] = newState;
					DgxAssetParameterSetValueBoolean(assetClientKey, "'switcher.output.video.freeze.', ITOA(eventDevicePort)", newState);
				}
			}

			// Video output status is managed by a channel event; however this is simply used to 
			// ensure the initial value is correct when the device comes onlinie
			ACTIVE(header == 'VIDOUT_ON'):
			{
				STACK_VAR CHAR newState;
				
				param1	= UPPER_STRING(RmsParseCmdParam(DATA.TEXT));				
				IF(param1 == 'ON')
				{
					newState = TRUE;
				}
				ELSE
				{
					newState = FALSE;
				}

				IF(DgxDeviceInfo.videoOutputEnabled[eventDevicePort] != newState)
				{
					DgxDeviceInfo.videoOutputEnabled[eventDevicePort] = newState;
					DgxAssetParameterSetValueBoolean(assetClientKey, "'switcher.output.video.enabled.', ITOA(eventDevicePort)", newState);
				}
			}
			
			// Input mic status is handled by a channel event; however, this is used just when the
			// device comes online to get the current state
			ACTIVE(header == 'AUDMIC_ON'):
			{
				STACK_VAR CHAR newState;
				
				param1	= UPPER_STRING(RmsParseCmdParam(DATA.TEXT));				
				IF(param1 == 'ON')
				{
					newState = TRUE;
				}
				ELSE
				{
					newState = FALSE;
				}

				IF(DgxDeviceInfo.audioMicEnabled[eventDevicePort] != newState)
				{
					DgxDeviceInfo.audioMicEnabled[eventDevicePort] = newState;
					DgxAssetParameterSetValueBoolean(assetClientKey, "'switcher.input.mic.enabled.', ITOA(eventDevicePort)", newState);
				}
			}

			// Front panel lockout
			ACTIVE(header == 'FP_LOCKOUT'):
			{
				STACK_VAR CHAR newState;

				param1	= UPPER_STRING(RmsParseCmdParam(DATA.TEXT));
				IF(param1 == 'ENABLE')
				{
					newState = TRUE;
				}
				ELSE
				{
					newState = FALSE;
				}

				IF(DgxDeviceInfo.frontPanelLocked != newState)
				{
					DgxDeviceInfo.frontPanelLocked = newState;
					DgxAssetParameterSetValueBoolean(assetClientKey, 'asset.front.panel.lockout', newState);
				}
			}

			// Front panel lock type
			ACTIVE(header == 'FP_LOCKTYPE'):
			{
				STACK_VAR CHAR newLockType[MAX_STRING_SIZE];

				param1	= RmsParseCmdParam(DATA.TEXT);
				newLockType = RmsGetEnumValue( ATOI(param1), FRONT_PANEL_LOCK_TYPE_ENUM);

				// If there is a change, update struct and RMS
				IF(DgxDeviceInfo.frontPanelLockType != newLockType)
				{
					DgxDeviceInfo.frontPanelLockType = newLockType;
					DgxAssetParameterSetValue(assetClientKey, 'asset.front.panel.lockout.type', newLockType);
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

			// Events for queries for connections between inputs and outputs go here
			// This applies to both audio and video
			ACTIVE(LEFT_STRING(header,8) == 'SWITCH'):
			{
				STACK_VAR CHAR audioSourceChanged;
				STACK_VAR CHAR input[2];
				STACK_VAR CHAR mediaRouteInfo[RMS_MAX_PARAM_LEN];
				STACK_VAR CHAR media[5];
				STACK_VAR CHAR output[2];
				STACK_VAR CHAR videoSourceChanged;
				STACK_VAR INTEGER cachedValue;
				STACK_VAR INTEGER inputNumber;
				STACK_VAR INTEGER ndx;
				STACK_VAR INTEGER outputNumber;

				audioSourceChanged = FALSE;
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

				// Process audio connection routing
				ELSE IF(media == 'AUDIO')
				{
					// If input number is 0, disconnect outputs
					IF(inputNumber == 0 && outputNumber != 0 )
					{
						cachedValue = DgxDeviceInfo.audioOutputSelectedSource[outputNumber];
						IF(cachedValue != 0)
						{
							audioSourceChanged = TRUE;
							DgxDeviceInfo.audioOutputSelectedSource[outputNumber] = 0;
						}

					}
					// If output number is 0, disconnect inputs
					ELSE IF(outputNumber == 0 && inputNumber != 0 )
					{
						FOR(ndx = 1; ndx <= DgxDeviceInfo.audioOutputCount; ndx++)
						{
							cachedValue = DgxDeviceInfo.audioOutputSelectedSource[ndx];
							IF(cachedValue == inputNumber)
							{
								audioSourceChanged = TRUE;
								DgxDeviceInfo.audioOutputSelectedSource[ndx]= 0;
							}
						}
					}
					ELSE IF(outputNumber != 0 && inputNumber != 0 )
					{
						cachedValue = DgxDeviceInfo.audioOutputSelectedSource[outputNumber];
						IF(cachedValue != inputNumber)
						{
							audioSourceChanged = TRUE;
							DgxDeviceInfo.audioOutputSelectedSource[outputNumber] = inputNumber;
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

				IF(audioSourceChanged == TRUE)
				{
					SyncAudioOutputSource();
				}

				IF(videoSourceChanged == TRUE)
				{
					SyncVideoOutputSource();
				}
			}
		}
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

(***********************************************************)
(* Channel event for standby/low power                     *)
(***********************************************************)
CHANNEL_EVENT[dvMonitoredDevice, STANDBY_STATE_CHANNEL]
{
	ON:	// Enable low/standby power mode
	{
		DgxDeviceInfo.standbyState = TRUE;
		RmsAssetPowerParameterUpdate(assetClientKey, FALSE);
	}
	OFF:	// Turn OFF standby power mode, i.e. enable normal power mode
	{
		DgxDeviceInfo.standbyState = FALSE;
		RmsAssetPowerParameterUpdate(assetClientKey, TRUE);
	}
}

(***********************************************************)
(* Channel event for audio output mute                     *)
(***********************************************************)
CHANNEL_EVENT[DgxDeviceSet, AUDIO_MUTE_CHANNEL]
{
	ON:
	{
		DgxDeviceInfo.audioOutputMute[GET_LAST(DgxDeviceSet)] = TRUE;
		DgxAssetParameterSetValueBoolean(
																			assetClientKey,
																			"'switcher.output.audio.mute.', ITOA(DgxDeviceSet[GET_LAST(DgxDeviceSet)].PORT)",
																			TRUE);

	}
	OFF:
	{
		DgxDeviceInfo.audioOutputMute[GET_LAST(DgxDeviceSet)] = FALSE;
		DgxAssetParameterSetValueBoolean(
																			assetClientKey,
																			"'switcher.output.audio.mute.', ITOA(DgxDeviceSet[GET_LAST(DgxDeviceSet)].PORT)",
																			FALSE);
	}
}


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
(* Channel event for mic enable                     *)
(***********************************************************)
CHANNEL_EVENT[DgxDeviceSet, MIC_ENABLE_CHANNEL]
{
	ON:
	{
		IF(DgxDeviceInfo.hasMicInput == TRUE)
		{
			DgxDeviceInfo.audioMicEnabled[DgxDeviceSet[GET_LAST(DgxDeviceSet)].PORT] = TRUE;
			DgxAssetParameterSetValueBoolean(
																				assetClientKey,
																				"'switcher.input.mic.enabled.', ITOA(DgxDeviceSet[GET_LAST(DgxDeviceSet)].PORT)",
																				TRUE);
		}
	}
	OFF:
	{
		IF(DgxDeviceInfo.hasMicInput == TRUE)
		{
			DgxDeviceInfo.audioMicEnabled[DgxDeviceSet[GET_LAST(DgxDeviceSet)].PORT] = FALSE;
			DgxAssetParameterSetValueBoolean(
																				assetClientKey,
																				"'switcher.input.mic.enabled.', ITOA(DgxDeviceSet[GET_LAST(DgxDeviceSet)].PORT)",
																				FALSE);
		}
	}
}

(***********************************************************)
(* Video freeze channel state                              *)
(***********************************************************)
CHANNEL_EVENT[DgxDeviceSet, VIDEO_FREEZE_STATE_CHANNEL]
{

	ON:
	{
		DgxDeviceInfo.videoOutputVideoFreeze[DgxDeviceSet[GET_LAST(DgxDeviceSet)].PORT] = TRUE;
		DgxAssetParameterSetValueBoolean(
																			assetClientKey,
																			"'switcher.output.video.freeze.', ITOA(DgxDeviceSet[GET_LAST(DgxDeviceSet)].PORT)",
																			TRUE);

	}
	OFF:
	{
		DgxDeviceInfo.videoOutputVideoFreeze[DgxDeviceSet[GET_LAST(DgxDeviceSet)].PORT] = FALSE;
		DgxAssetParameterSetValueBoolean(
																			assetClientKey,
																			"'switcher.output.video.freeze.', ITOA(DgxDeviceSet[GET_LAST(DgxDeviceSet)].PORT)",
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
(* Level event for output volume                           *)
(***********************************************************)
LEVEL_EVENT[DgxDeviceSet[1], OUTPUT_VOLUME_LEVEL]
LEVEL_EVENT[DgxDeviceSet[2], OUTPUT_VOLUME_LEVEL]
LEVEL_EVENT[DgxDeviceSet[3], OUTPUT_VOLUME_LEVEL]
LEVEL_EVENT[DgxDeviceSet[4], OUTPUT_VOLUME_LEVEL]
{
	DgxDeviceInfo.audioOutputVolumeLevel[Level.Input.Device.Port] = LEVEL.VALUE;
	DgxAssetParameterSetValueNumber(
																	assetClientKey,
																	"'switcher.output.audio.volume.', ITOA(Level.Input.Device.Port)",
																	LEVEL.VALUE);
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
