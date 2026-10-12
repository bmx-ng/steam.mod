SuperStrict

Framework steam.steamsdk
Import brl.standardio

If Not SteamInit(False) Then
	Print "Steam is not running"
	End
End If

Local client:TSteamClient = New TSteamClient
Local input:TSteamInput = client.GetISteamInput()
If Not input Then
	Print "Steam Input is unavailable"
	SteamShutdown()
	End
End If

input.SetListener(New TInputListener)

' Pass True because this example explicitly refreshes Steam Input below.
If Not input.Init(True) Then
	Print "Steam Input could not be initialized"
	SteamShutdown()
	End
End If

input.EnableDeviceCallbacks()
input.EnableActionEventCallbacks()
input.RunFrame()

Local handles:ULong[STEAM_INPUT_MAX_COUNT]
Local count:Int = input.GetConnectedControllers(handles, handles.length)
Print "Connected Steam Input controllers: " + count

For Local index:Int = 0 Until count
	Local handle:ULong = handles[index]
	Local major:Int
	Local minor:Int

	Print "Controller " + index + ":"
	Print "  Handle: " + handle
	Print "  Type: " + input.GetInputTypeForHandle(handle)
	Print "  Gamepad index: " + input.GetGamepadIndexForController(handle)
	Print "  Remote Play session: " + input.GetRemotePlaySessionID(handle)
	If input.GetDeviceBindingRevision(handle, major, minor) Then
		Print "  Binding revision: " + major + "." + minor
	End If
Next

Print "Session configuration flags: " + input.GetSessionInputConfigurationSettings()

' A game with an action manifest would now cache handles such as:
' Local gameplay:ULong = input.GetActionSetHandle("gameplay")
' Local moveAction:ULong = input.GetAnalogActionHandle("move")
' Local jumpAction:ULong = input.GetDigitalActionHandle("jump")
' Then activate the set and read those actions once per frame.

input.Shutdown()
SteamShutdown()

Type TInputListener Implements ISteamInputListener, ISteamInputActionListener
	Method OnSteamInputDeviceConnected(inputHandle:ULong)
		Print "Controller connected: " + inputHandle
	End Method

	Method OnSteamInputDeviceDisconnected(inputHandle:ULong)
		Print "Controller disconnected: " + inputHandle
	End Method

	Method OnSteamInputConfigurationLoaded(appID:UInt, inputHandle:ULong, mappingCreator:ULong, majorRevision:UInt, minorRevision:UInt, usesSteamInputAPI:Int, usesGamepadAPI:Int)
		Print "Configuration loaded for controller " + inputHandle + " (revision " + majorRevision + "." + minorRevision + ")"
	End Method

	Method OnSteamInputDigitalAction(inputHandle:ULong, actionHandle:ULong, data:SSteamInputDigitalActionData)
		' A real game can react to low-latency digital action changes here.
	End Method

	Method OnSteamInputAnalogAction(inputHandle:ULong, actionHandle:ULong, data:SSteamInputAnalogActionData)
		' A real game can react to low-latency analog action changes here.
	End Method
End Type
