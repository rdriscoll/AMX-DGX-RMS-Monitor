This program requires dependencies from the AMX RMS SDK 4.1.5 to compile.
These dependencies cannot be placed on a public repository due to licensing issues.

*****************************************************************************

20131009 v0.1.1 RRD 
 Changed Connected states to strings rather than booleans.

20130911 v0.1 RRD
 Read the data from a serial port on a DGX and pass the information to RMS.

*****************************************************************************
A screen shot of what this looks like in RMS is attached.


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
