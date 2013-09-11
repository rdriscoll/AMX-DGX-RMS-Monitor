PROGRAM_NAME='Testing'
(***********************************************************)
(*
  20130904 v0.1 RRD
*)
(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT
LOCAL_SYSTEM			= 1
REMOTE_SYSTEM_01	= 2
(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

dvTerminal		= 0:0:0
dvSystem			= 0:1:0

dvUI					= 10001:1:LOCAL_SYSTEM

dvDXLinkTx_01 = 6001:1:LOCAL_SYSTEM
dvDXLinkTx_02 = 6002:1:LOCAL_SYSTEM

dvDXLinkRx_01 = 6101:1:LOCAL_SYSTEM
dvDXLinkRx_02 = 6102:1:LOCAL_SYSTEM

dvDgxSerial	= 10004:1:LOCAL_SYSTEM

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
//INCLUDE 'RMSMain.axi'
INCLUDE 'testing.axi'

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

BUTTON_EVENT[dvUI, 0]
{
	PUSH:
	{
		IF(BUTTON.INPUT.CHANNEL < 8)
			SEND_STRING dvDgxSerial, "'~scri',ITOA(BUTTON.INPUT.CHANNEL),'v3!',$0d,$0a"; // board info
		ELSE
			SWITCH(BUTTON.INPUT.CHANNEL)
			{			
				CASE 21:// SEND_STRING dvDgxSerial, "'~scri1v3!'";
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
				CASE 22: SEND_STRING dvDgxSerial, "'~scri2v3!'";
				CASE 23: SEND_STRING dvDgxSerial, "'~scri3v3!'";
				CASE 24:// SEND_STRING dvDgxSerial, "'~scri4v3!'";
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
				CASE 25:// SEND_STRING dvDgxSerial, "'~scri5v3!'";
				{
					cBufferDGX = "'~scri5v3!',$0d,$0a,
												'[5:VM Configuration] count = 2',$0d,$0a,
												'[vm 0] "All" 32x32x1',$0d,$0a,
												'[vm 1] "Video" 32x32x1',$0d,$0a,
												'[vm 0 master] 0x11000 master 0 0 1 (self)',$0d,$0a,
												'[vm 1 master] 0x11000 master 0 0 1 (self)',$0d,$0a"
					ParseDGXData();
				}
				CASE 26:// SEND_STRING dvDgxSerial, "'~scri6v3!'";
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
				CASE 27:// SEND_STRING dvDgxSerial, "'~scri7v3!'";
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
				CASE 30:
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

