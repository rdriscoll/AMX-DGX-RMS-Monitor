PROGRAM_NAME='Testing'

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

INTEGER DEBUG_LEVEL = $FFFF;

INTEGER DEBUG_LEVEL_QUIET															= 1
INTEGER DEBUG_LEVEL_STANDARD													= 2
INTEGER DEBUG_LEVEL_CHATTY														= 4
INTEGER DEBUG_LEVEL_SUPER_CHATTY											= 8

// This defines maximum string length for the purpose of
// dimentioning array sizes
INTEGER MAX_STRING_SIZE																= 50;
INTEGER MAX_ENUM_ENTRY_SIZE														= 50;

INTEGER MAX_BUFFER_SIZE																= 12000;

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
CHAR assetClientKey[100];

// Include RMS MONITOR COMMON AXI
//#INCLUDE 'RmsMonitorCommon';
DEFINE_FUNCTION DgxAssetParameterSetValueNumber(CHAR a[], CHAR b[], SLONG c) {}
DEFINE_FUNCTION DgxAssetParameterSetValueBoolean(CHAR a[], CHAR b[], CHAR c) {}

(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)

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
	DebugVal('[temp 1] nStartPos_', nStartPos_, DEBUG_LEVEL_CHATTY);
	IF(nStartPos_)
	{
		nStartPos_ = nStartPos_ + LENGTH_STRING(sTemp_);
		nMidPos_ = FIND_STRING(sTemp, "$0d", nStartPos_);
		sTemp2_ = MID_STRING(sTemp, nStartPos_, LENGTH_STRING(sTemp)-nMidPos_+1);
		DebugString('internalTemperature', sTemp2_, DEBUG_LEVEL_CHATTY);
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
		//DebugVal('ParseDGXBCPU cCount_', cCount_, DEBUG_LEVEL_SUPER_CHATTY);
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
		DebugString("'sTemp_'", sTemp_, DEBUG_LEVEL_STANDARD);
		cLinked_ = (LENGTH_STRING(sTemp_) != 0); // *** should be a ! ***
		IF(cLinked_) // linked
		{
			DebugVal("'linked'", TYPE_CAST(cLinked_), DEBUG_LEVEL_STANDARD);
			sTemp_ = GetSubString(sTemp, "'Ch',ITOA(cCount_),'-[DxLink In]'", "$0d", DONT_REMOVE_DATA); //Ch1-[DxLink In] BER Video:10^(-10), Audio:10^(-10), Blank:10^(-10), Ctrl:10^(-10)
			cIsInputBoard_ = (LENGTH_STRING(sTemp_)); // [DxLink In]
		}
		ELSE // unlinked - have to determine input board by the number
		{
			cIsInputBoard_ = (cBoard <= MAX_VIDEO_INPUT_CNT/4);
			DebugVal("'Unlinked'", TYPE_CAST(cLinked_), DEBUG_LEVEL_STANDARD);
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
	WHILE(LENGTH_STRING(cBufferDGX))
	{
		//DebugString('ParseDGXData', cBufferDGX, DEBUG_LEVEL_SUPER_CHATTY);
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

		IF(LENGTH_STRING(cBufferDGX) > MAX_LENGTH_STRING(cBufferDGX)-10)
			CLEAR_BUFFER cBufferDGX;

	// If the buffer hasn't changed size since the last pass then the remaining data in the buffer must be unhandled data so ditch it to terminate the loop
		nEndPos_ = LENGTH_STRING(cBufferDGX);
		IF(nBufferSize == nEndPos_)
			CLEAR_BUFFER cBufferDGX;
		ELSE
			nBufferSize = nEndPos_;
	}
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
			BreakStringIntoChunks("strTemp_, strBody", MAX_LENGTH_STRING(strTemp_))
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
//CREATE_BUFFER dvDgxSerial, cBufferDGX;

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

DATA_EVENT[dvDgxSerial]
{
	ONLINE:	SEND_COMMAND DATA.DEVICE, 'SET BAUD 9600,n,8,1 485 DISABLE';
	STRING:	WAIT 1 ParseDGXData();
}

