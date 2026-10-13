SuperStrict

Framework Steam.SteamSDK
Import BRL.StandardIO

If Not SteamInit(False) Then
	Print "Steam is not running"
	End
End If

Local utils:TSteamNetworkingUtils = TSteamNetworkingUtils.Create()
If Not utils Then
	Print "Steam Networking Utils is unavailable"
	SteamShutdown()
	End
End If

utils.SetListener(New TRelayListener)
utils.InitRelayNetworkAccess()

Local pingMeasurement:Int
Local networkConfig:ESteamNetworkingAvailability
Local anyRelay:ESteamNetworkingAvailability
Local detail:String
Local availability:ESteamNetworkingAvailability = utils.GetRelayNetworkStatus(pingMeasurement, networkConfig, anyRelay, detail)
Print "Relay availability: " + Int(availability)
Print "Relay diagnostics: " + detail

Local timeout:Int
Local configResult:ESteamNetworkingGetConfigValueResult = utils.GetConfigInt32( ..
	ESteamNetworkingConfigValue.k_ESteamNetworkingConfig_TimeoutConnected, ..
	ESteamNetworkingConfigScope.k_ESteamNetworkingConfig_Global, 0, timeout)
If configResult > 0 Then Print "Connected timeout: " + timeout + " ms"

Local location:String
Local locationAge:Float = utils.GetLocalPingLocation(location)
If locationAge >= 0 Then
	Print "Local ping-location age: " + locationAge + " seconds"
	Print "Local ping location: " + location
End If

For Local iteration:Int = 0 Until 50
	SteamRunCallbacks()
	Delay 100
Next

SteamShutdown()

Type TRelayListener Implements ISteamNetworkingUtilsListener
	Method OnSteamRelayNetworkStatusChanged(availability:ESteamNetworkingAvailability, pingMeasurementInProgress:Int, networkConfig:ESteamNetworkingAvailability, anyRelay:ESteamNetworkingAvailability, debugMessage:String)
		Print "Relay status changed: " + Int(availability) + " - " + debugMessage
	End Method
End Type
