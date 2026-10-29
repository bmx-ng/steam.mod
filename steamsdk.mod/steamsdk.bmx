' Copyright (c) 2019-2026 Bruce A Henderson
' 
' This software is provided 'as-is', without any express or implied
' warranty. In no event will the authors be held liable for any damages
' arising from the use of this software.
' 
' Permission is granted to anyone to use this software for any purpose,
' including commercial applications, and to alter it and redistribute it
' freely, subject to the following restrictions:
' 
' 1. The origin of this software must not be misrepresented; you must not
'    claim that you wrote the original software. If you use this software
'    in a product, an acknowledgment in the product documentation would be
'    appreciated but is not required.
' 2. Altered source versions must be plainly marked as such, and must not be
'    misrepresented as being the original software.
' 3. This notice may not be removed or altered from any source distribution.
' 
SuperStrict

Rem
bbdoc: Steam SDK
End Rem
Module Steam.SteamSDK

ModuleInfo "Version: 1.12"
ModuleInfo "License: zlib/libpng"
ModuleInfo "Copyright: Steam SDK - Valve Corporation"
ModuleInfo "Copyright: Wrapper - 2019-2026 Bruce A Henderson"

ModuleInfo "History: 1.12"
ModuleInfo "History: Added Steam Networking Utils relay, ping, POP, timestamp, and configuration APIs."
ModuleInfo "History: 1.11"
ModuleInfo "History: Added Steam Networking Sockets and dedicated game-server support."
ModuleInfo "History: 1.10"
ModuleInfo "History: Updated to Steamworks SDK 1.65."
ModuleInfo "History: Added Timeline, DualSense trigger effects, web API tickets, profile items, and new Apps, Utils, and UGC APIs."
ModuleInfo "History: 1.09"
ModuleInfo "History: Added Steam Input actions, devices, glyphs, motion, feedback, and callbacks."
ModuleInfo "History: 1.08"
ModuleInfo "History: Added Steam Remote Storage and Steam Cloud file support."
ModuleInfo "History: 1.07"
ModuleInfo "History: Completed Apps, User, Friends, matchmaking, Networking Messages, UserStats, Utils, and UGC feature coverage."
ModuleInfo "History: 1.06"
ModuleInfo "History: Added TSteamUGC SetListener()"
ModuleInfo "History: 1.05"
ModuleInfo "History: Update to steamworks sdk 1.53a."
ModuleInfo "History: Build fixes."
ModuleInfo "History: 1.04"
ModuleInfo "History: Added ISteamUserStats GetStats()."
ModuleInfo "History: Fixed linking for macOS and Linux."
ModuleInfo "History: 1.03"
ModuleInfo "History: Fixed thread registration."
ModuleInfo "History: 1.02"
ModuleInfo "History: Added ISteamFriends API."
ModuleInfo "History: 1.01"
ModuleInfo "History: Added ISteamUGC API."
ModuleInfo "History: 1.00"
ModuleInfo "History: Initial Release."

ModuleInfo "CPP_OPTS: -std=c++11"
?win32x86
ModuleInfo "CC_OPTS: -DSTEAM_API_EXPORTS"
ModuleInfo "LD_OPTS: -L%PWD%/sdk/redistributable_bin"
?win32x64
ModuleInfo "LD_OPTS: -L%PWD%/sdk/redistributable_bin/win64"
?linuxx86
ModuleInfo "LD_OPTS: -L%PWD%/sdk/redistributable_bin/linux32"
ModuleInfo "LD_OPTS: -Wl,-rpath,'$ORIGIN'"
?linuxx64
ModuleInfo "LD_OPTS: -L%PWD%/sdk/redistributable_bin/linux64"
ModuleInfo "LD_OPTS: -Wl,-rpath,'$ORIGIN'"
?linuxarm64
ModuleInfo "LD_OPTS: -L%PWD%/sdk/redistributable_bin/linuxarm64"
ModuleInfo "LD_OPTS: -Wl,-rpath,'$ORIGIN'"
?macosx64
ModuleInfo "LD_OPTS: -L%PWD%/sdk/redistributable_bin/osx"
?macosarm64
ModuleInfo "LD_OPTS: -L%PWD%/sdk/redistributable_bin/osx"
?

'
' Build notes :
'    steamtypes.h was changed to support building with mingw
'

Import "common.bmx"

Private

Global _steamPipe:UInt
Global _inited:Int
Global _user:Int
Global _autoRunCallbacks:Int
Global _shutdown:Int

Public

Rem
bbdoc: Initialises Steam.
about: By default callback processing is run once every 100ms. If you'd rather control this yourself, you can 
set @autoRunCallbacks to #False, and call #SteamRunCallbacks yourself.
End Rem
Function SteamInit:Int(autoRunCallbacks:Int = True)
	If Not _inited Then
		Local res:Int = bmx_SteamAPI_Init()
		If Not res Then
			Return res
		End If
	
		_inited = True
		
		_steamPipe = bmx_SteamAPI_GetHSteamPipe()
		
		If autoRunCallbacks Then
			_autoRunCallbacks = True
			bmx_SteamAPI_startBackgroundTimer()
		End If
		
	End If
	
	Return True
End Function

Rem
bbdoc: Checks if your executable was launched through Steam and relaunches it through Steam if it wasn't.
about: 
If this returns #True then it starts the Steam client if required and launches your game again through it, and you should quit your process as soon as possible.
This effectively runs `steam://run/<AppId>` so it may not relaunch the exact executable that called it, as it will always relaunch from the version installed
in your Steam library folder.

If it returns #False, then your game was launched by the Steam client and no action needs to be taken. One exception is if a `steam_appid.txt` file is present
then this will return #False regardless. This allows you to develop and test without launching your game through the Steam client.
Make sure to remove the `steam_appid.txt` file when uploading the game to your Steam depot!
End Rem
Function SteamRestartAppIfNecessary:Int(ownAppID:UInt)
	Return bmx_SteamAPI_RestartAppIfNecessary(ownAppID)
End Function

Rem
bbdoc: Shuts down Steam.
about: This should be called before your application closes.
End Rem
Function SteamShutdown()
	If Not _shutdown Then
		_shutdown = True
		If _autoRunCallbacks Then
			bmx_SteamAPI_stopBackgroundTimer()
		End If
		bmx_SteamAPI_Shutdown()
	End If
End Function

Rem
bbdoc: Dispatches callbacks and call results.
about: It's best to call this at >10Hz, the more time between calls, the more potential latency between receiving events or results
from the Steamworks API. Most games call this once per render-frame. All registered listener functions will be invoked during this call,
in the callers thread context.
End Rem
Function SteamRunCallbacks()
	bmx_SteamAPI_RunCallbacks()
End Function

Rem
bbdoc: Returns True after Steam has been successfully initialized.
End Rem
Function SteamIsInitialized:Int()
	Return _inited And Not _shutdown
End Function

Rem
bbdoc: Enables or disables the wrapper's automatic background callback timer.
about: Disable automatic callbacks when the application calls
#SteamRunCallbacks from its main loop. Changing mode does not initialize Steam.
End Rem
Function SteamSetAutoRunCallbacks:Int(enabled:Int)
	If Not _inited Or _shutdown Then Return False
	enabled = enabled <> 0
	If enabled = _autoRunCallbacks Then Return True
	If enabled Then
		bmx_SteamAPI_startBackgroundTimer()
	Else
		bmx_SteamAPI_stopBackgroundTimer()
	End If
	_autoRunCallbacks = enabled
	Return True
End Function

Type TSteamAPI Abstract

	Field instancePtr:Byte Ptr
	Field callbackPtr:Byte Ptr

End Type

Rem
bbdoc: Local Steam user identity and connection state.
End Rem
Interface ISteamUserListener
	Method OnValidateAuthTicket(steamID:ULong, response:EAuthSessionResponse, ownerSteamID:ULong)
	Method OnGetAuthSessionTicket(authTicket:UInt, result:EResult)
	Method OnGetTicketForWebApi(authTicket:UInt, result:EResult, ticket:Byte Ptr, ticketSize:Int)
	Method OnEncryptedAppTicket(result:EResult, ioFailure:Int)
	Method OnStoreAuthURL(url:String, ioFailure:Int)
	Method OnMarketEligibility(allowed:Int, reason:EMarketNotAllowedReasonFlags, allowedAtTime:UInt, steamGuardRequiredDays:Int, newDeviceCooldown:Int, ioFailure:Int)
	Method OnDurationControl(result:EResult, appID:UInt, applicable:Int, secondsLast5h:Int, progress:EDurationControlProgress, notification:EDurationControlNotification, secondsToday:Int, secondsRemaining:Int, ioFailure:Int)
End Interface

Type TSteamUser Extends TSteamAPI
	Const STEAMUSER_INTERFACE_VERSION:String = "SteamUser023"
	Field listener:ISteamUserListener

	Function _create:TSteamUser(instancePtr:Byte Ptr)
		If Not instancePtr Then Return Null
		Local this:TSteamUser = New TSteamUser
		this.instancePtr = instancePtr
		this.callbackPtr = bmx_steamsdk_register_steamuser(instancePtr, this)
		Return this
	End Function

	Method Delete()
		If callbackPtr Then bmx_steamsdk_unregister_steamuser(callbackPtr)
		callbackPtr = Null
	End Method

	Rem
	bbdoc: Sets the listener that receives asynchronous results and Steam callbacks for this interface.
	End Rem
	Method SetListener(listener:ISteamUserListener)
		Self.listener = listener
	End Method
	Rem
	bbdoc: Returns the Steam user handle associated with the current API context.
	End Rem
	Method GetHSteamUser:Int()
		Return bmx_SteamAPI_ISteamUser_GetHSteamUser(instancePtr)
	End Method

	Rem
	bbdoc: Returns #True when the Steam client currently has an active connection to the Steam servers.
	End Rem
	Method BLoggedOn:Int()
		Return bmx_SteamAPI_ISteamUser_BLoggedOn(instancePtr)
	End Method

	Rem
	bbdoc: Returns the 64-bit Steam ID of the local user.
	End Rem
	Method GetSteamID:ULong()
		Return bmx_SteamAPI_ISteamUser_GetSteamID(instancePtr)
	End Method

	Rem
	bbdoc: Returns the current user's application data folder in @folder.
	End Rem
	Method GetUserDataFolder:Int(folder:String Var)
		Return bmx_SteamAPI_ISteamUser_GetUserDataFolder(instancePtr, folder)
	End Method
	Rem
	bbdoc: Starts capturing voice data for the local user.
	End Rem
	Method StartVoiceRecording()
		bmx_SteamAPI_ISteamUser_StartVoiceRecording(instancePtr)
	End Method
	Rem
	bbdoc: Stops voice capture after any remaining recorded data has been read.
	End Rem
	Method StopVoiceRecording()
		bmx_SteamAPI_ISteamUser_StopVoiceRecording(instancePtr)
	End Method
	Rem
	bbdoc: Reports how many bytes of compressed voice data are ready to read.
	End Rem
	Method GetAvailableVoice:EVoiceResult(compressedBytes:UInt Var)
		Return bmx_SteamAPI_ISteamUser_GetAvailableVoice(instancePtr, compressedBytes)
	End Method
	Rem
	bbdoc: Copies available compressed voice data into @destination and reports the number of bytes written.
	End Rem
	Method GetVoice:EVoiceResult(destination:Byte Ptr, capacity:UInt, bytesWritten:UInt Var)
		Return bmx_SteamAPI_ISteamUser_GetVoice(instancePtr, destination, capacity, bytesWritten)
	End Method
	Rem
	bbdoc: Decompresses Steam voice data into signed 16-bit mono PCM at @sampleRate.
	End Rem
	Method DecompressVoice:EVoiceResult(compressed:Byte Ptr, compressedSize:UInt, destination:Byte Ptr, capacity:UInt, bytesWritten:UInt Var, sampleRate:UInt)
		Return bmx_SteamAPI_ISteamUser_DecompressVoice(instancePtr, compressed, compressedSize, destination, capacity, bytesWritten, sampleRate)
	End Method
	Rem
	bbdoc: Returns Steam's recommended sample rate for decompressed voice playback.
	End Rem
	Method GetVoiceOptimalSampleRate:UInt()
		Return bmx_SteamAPI_ISteamUser_GetVoiceOptimalSampleRate(instancePtr)
	End Method
	Rem
	bbdoc: Creates an authentication ticket and copies it into @ticket.
	End Rem
	Method GetAuthSessionTicket:UInt(ticket:Byte Ptr, capacity:Int, ticketSize:UInt Var)
		Return bmx_SteamAPI_ISteamUser_GetAuthSessionTicket(instancePtr, ticket, capacity, ticketSize)
	End Method

	Rem
	bbdoc: Requests an authentication ticket for the AuthenticateUserTicket Web API.
	about: The ticket bytes delivered to #ISteamUserListener are valid only during the callback and should be copied before returning.
	End Rem
	Method GetAuthTicketForWebApi:UInt(identity:String = "")
		Return bmx_SteamAPI_ISteamUser_GetAuthTicketForWebApi(instancePtr, identity)
	End Method
	Rem
	bbdoc: Begins validating a remote user's authentication ticket.
	End Rem
	Method BeginAuthSession:EBeginAuthSessionResult(ticket:Byte Ptr, ticketSize:Int, steamID:ULong)
		Return bmx_SteamAPI_ISteamUser_BeginAuthSession(instancePtr, ticket, ticketSize, steamID)
	End Method
	Rem
	bbdoc: Ends authentication for @steamID when the connection or session finishes.
	End Rem
	Method EndAuthSession(steamID:ULong)
		bmx_SteamAPI_ISteamUser_EndAuthSession(instancePtr, steamID)
	End Method
	Rem
	bbdoc: Cancels a ticket previously returned by #GetAuthSessionTicket.
	End Rem
	Method CancelAuthTicket(authTicket:UInt)
		bmx_SteamAPI_ISteamUser_CancelAuthTicket(instancePtr, authTicket)
	End Method
	Rem
	bbdoc: Checks whether @steamID owns or otherwise has a license for @appID.
	End Rem
	Method UserHasLicenseForApp:EUserHasLicenseForAppResult(steamID:ULong, appID:UInt)
		Return bmx_SteamAPI_ISteamUser_UserHasLicenseForApp(instancePtr, steamID, appID)
	End Method
	Rem
	bbdoc: Returns #True when Steam believes the local user is behind NAT.
	End Rem
	Method BIsBehindNAT:Int()
		Return bmx_SteamAPI_ISteamUser_BIsBehindNAT(instancePtr)
	End Method
	Rem
	bbdoc: Advertises the game server the local user is currently connected to.
	End Rem
	Method AdvertiseGame(steamIDGameServer:ULong, ip:UInt, port:Short)
		bmx_SteamAPI_ISteamUser_AdvertiseGame(instancePtr, steamIDGameServer, ip, port)
	End Method
	Rem
	bbdoc: Records a Steam application usage event for the supplied game ID.
	End Rem
	Method TrackAppUsageEvent(gameID:ULong, appUsageEvent:Int, extraInfo:String = "")
		bmx_SteamAPI_ISteamUser_TrackAppUsageEvent(instancePtr, gameID, appUsageEvent, extraInfo)
	End Method
	Rem
	bbdoc: Requests an encrypted application ticket and reports completion through #ISteamUserListener.
	End Rem
	Method RequestEncryptedAppTicket(data:Byte Ptr = Null, size:Int = 0)
		bmx_SteamAPI_ISteamUser_RequestEncryptedAppTicket(callbackPtr, data, size)
	End Method
	Rem
	bbdoc: Copies the most recently requested encrypted application ticket into @ticket.
	End Rem
	Method GetEncryptedAppTicket:Int(ticket:Byte Ptr, capacity:Int, ticketSize:UInt Var)
		Return bmx_SteamAPI_ISteamUser_GetEncryptedAppTicket(instancePtr, ticket, capacity, ticketSize)
	End Method
	Rem
	bbdoc: Returns the user's badge level for this game and card series.
	End Rem
	Method GetGameBadgeLevel:Int(series:Int, foil:Int = False)
		Return bmx_SteamAPI_ISteamUser_GetGameBadgeLevel(instancePtr, series, foil)
	End Method
	Rem
	bbdoc: Returns the local user's Steam community level.
	End Rem
	Method GetPlayerSteamLevel:Int()
		Return bmx_SteamAPI_ISteamUser_GetPlayerSteamLevel(instancePtr)
	End Method
	Rem
	bbdoc: Requests a store authentication URL and reports it through #ISteamUserListener.
	End Rem
	Method RequestStoreAuthURL(redirectURL:String)
		bmx_SteamAPI_ISteamUser_RequestStoreAuthURL(callbackPtr, redirectURL)
	End Method
	Rem
	bbdoc: Returns #True when the local account has a verified phone number.
	End Rem
	Method BIsPhoneVerified:Int()
		Return bmx_SteamAPI_ISteamUser_BIsPhoneVerified(instancePtr)
	End Method
	Rem
	bbdoc: Returns #True when the local account has two-factor authentication enabled.
	End Rem
	Method BIsTwoFactorEnabled:Int()
		Return bmx_SteamAPI_ISteamUser_BIsTwoFactorEnabled(instancePtr)
	End Method
	Rem
	bbdoc: Returns #True when the local account's phone identifies the user.
	End Rem
	Method BIsPhoneIdentifying:Int()
		Return bmx_SteamAPI_ISteamUser_BIsPhoneIdentifying(instancePtr)
	End Method
	Rem
	bbdoc: Returns #True when the local account's phone still requires verification.
	End Rem
	Method BIsPhoneRequiringVerification:Int()
		Return bmx_SteamAPI_ISteamUser_BIsPhoneRequiringVerification(instancePtr)
	End Method
	Rem
	bbdoc: Requests the local user's Community Market eligibility and reports it through #ISteamUserListener.
	End Rem
	Method GetMarketEligibility()
		bmx_SteamAPI_ISteamUser_GetMarketEligibility(callbackPtr)
	End Method
	Rem
	bbdoc: Requests play-time duration-control information and reports it through #ISteamUserListener.
	End Rem
	Method GetDurationControl()
		bmx_SteamAPI_ISteamUser_GetDurationControl(callbackPtr)
	End Method
	Rem
	bbdoc: Updates the application's online state for Steam duration-control tracking.
	End Rem
	Method BSetDurationControlOnlineState:Int(state:EDurationControlOnlineState)
		Return bmx_SteamAPI_ISteamUser_BSetDurationControlOnlineState(instancePtr, state)
	End Method

	Method OnValidateAuthTicket(steamID:ULong, response:EAuthSessionResponse, ownerSteamID:ULong)
		If listener Then listener.OnValidateAuthTicket(steamID, response, ownerSteamID)
	End Method
	Function _OnValidateAuthTicket(inst:TSteamUser, steamID:ULong, response:EAuthSessionResponse, ownerSteamID:ULong) { nomangle }
		inst.OnValidateAuthTicket(steamID, response, ownerSteamID)
	End Function
	Method OnGetAuthSessionTicket(authTicket:UInt, result:EResult)
		If listener Then listener.OnGetAuthSessionTicket(authTicket, result)
	End Method
	Function _OnGetAuthSessionTicket(inst:TSteamUser, authTicket:UInt, result:EResult) { nomangle }
		inst.OnGetAuthSessionTicket(authTicket, result)
	End Function
	Method OnGetTicketForWebApi(authTicket:UInt, result:EResult, ticket:Byte Ptr, ticketSize:Int)
		If listener Then listener.OnGetTicketForWebApi(authTicket, result, ticket, ticketSize)
	End Method
	Function _OnGetTicketForWebApi(inst:TSteamUser, authTicket:UInt, result:EResult, ticket:Byte Ptr, ticketSize:Int) { nomangle }
		inst.OnGetTicketForWebApi(authTicket, result, ticket, ticketSize)
	End Function
	Method OnEncryptedAppTicket(result:EResult, ioFailure:Int)
		If listener Then listener.OnEncryptedAppTicket(result, ioFailure)
	End Method
	Function _OnEncryptedAppTicket(inst:TSteamUser, result:EResult, ioFailure:Int) { nomangle }
		inst.OnEncryptedAppTicket(result, ioFailure)
	End Function
	Method OnStoreAuthURL(url:String, ioFailure:Int)
		If listener Then listener.OnStoreAuthURL(url, ioFailure)
	End Method
	Function _OnStoreAuthURL(inst:TSteamUser, url:String, ioFailure:Int) { nomangle }
		inst.OnStoreAuthURL(url, ioFailure)
	End Function
	Method OnMarketEligibility(allowed:Int, reason:EMarketNotAllowedReasonFlags, allowedAtTime:UInt, steamGuardRequiredDays:Int, newDeviceCooldown:Int, ioFailure:Int)
		If listener Then listener.OnMarketEligibility(allowed, reason, allowedAtTime, steamGuardRequiredDays, newDeviceCooldown, ioFailure)
	End Method
	Function _OnMarketEligibility(inst:TSteamUser, allowed:Int, reason:EMarketNotAllowedReasonFlags, allowedAtTime:UInt, steamGuardRequiredDays:Int, newDeviceCooldown:Int, ioFailure:Int) { nomangle }
		inst.OnMarketEligibility(allowed, reason, allowedAtTime, steamGuardRequiredDays, newDeviceCooldown, ioFailure)
	End Function
	Method OnDurationControl(result:EResult, appID:UInt, applicable:Int, secondsLast5h:Int, progress:EDurationControlProgress, notification:EDurationControlNotification, secondsToday:Int, secondsRemaining:Int, ioFailure:Int)
		If listener Then listener.OnDurationControl(result, appID, applicable, secondsLast5h, progress, notification, secondsToday, secondsRemaining, ioFailure)
	End Method
	Function _OnDurationControl(inst:TSteamUser, result:EResult, appID:UInt, applicable:Int, secondsLast5h:Int, progress:EDurationControlProgress, notification:EDurationControlNotification, secondsToday:Int, secondsRemaining:Int, ioFailure:Int) { nomangle }
		inst.OnDurationControl(result, appID, applicable, secondsLast5h, progress, notification, secondsToday, secondsRemaining, ioFailure)
	End Function
End Type

Rem
bbdoc: Application information supplied by Steam.
End Rem
Interface ISteamAppsListener
	Method OnDlcInstalled(appID:UInt)
	Method OnNewUrlLaunchParameters()
	Method OnAppProofOfPurchaseKey(result:EResult, appID:UInt, key:String)
	Method OnTimedTrialStatus(appID:UInt, offline:Int, secondsAllowed:UInt, secondsPlayed:UInt)
	Method OnFileDetails(result:EResult, fileSize:ULong, sha1:String, flags:UInt, ioFailure:Int)
End Interface

Type TSteamApps Extends TSteamAPI
	Const STEAMAPPS_INTERFACE_VERSION:String = "STEAMAPPS_INTERFACE_VERSION009"
	Field listener:ISteamAppsListener

	Function _create:TSteamApps(instancePtr:Byte Ptr)
		If Not instancePtr Then Return Null
		Local this:TSteamApps = New TSteamApps
		this.instancePtr = instancePtr
		this.callbackPtr = bmx_steamsdk_register_steamapps(instancePtr, this)
		Return this
	End Function

	Method Delete()
		If callbackPtr Then bmx_steamsdk_unregister_steamapps(callbackPtr)
		callbackPtr = Null
	End Method

	Rem
	bbdoc: Sets the listener that receives asynchronous results and Steam callbacks for this interface.
	End Rem
	Method SetListener(listener:ISteamAppsListener)
		Self.listener = listener
	End Method
	Rem
	bbdoc: Returns #True when the active user is subscribed to the current application.
	End Rem
	Method BIsSubscribed:Int()
		Return bmx_SteamAPI_ISteamApps_BIsSubscribed(instancePtr)
	End Method
	Rem
	bbdoc: Returns #True when Steam is running a low-violence build for this user.
	End Rem
	Method BIsLowViolence:Int()
		Return bmx_SteamAPI_ISteamApps_BIsLowViolence(instancePtr)
	End Method
	Rem
	bbdoc: Returns #True when the application is running under a cybercafe license.
	End Rem
	Method BIsCybercafe:Int()
		Return bmx_SteamAPI_ISteamApps_BIsCybercafe(instancePtr)
	End Method
	Rem
	bbdoc: Returns #True when the user has a VAC ban for this application.
	End Rem
	Method BIsVACBanned:Int()
		Return bmx_SteamAPI_ISteamApps_BIsVACBanned(instancePtr)
	End Method
	Rem
	bbdoc: Returns the language Steam has selected for the current game.
	End Rem
	Method GetCurrentGameLanguage:String()
		Return bmx_SteamAPI_ISteamApps_GetCurrentGameLanguage(instancePtr)
	End Method
	Rem
	bbdoc: Returns the comma-separated languages supported by the current game.
	End Rem
	Method GetAvailableGameLanguages:String()
		Return bmx_SteamAPI_ISteamApps_GetAvailableGameLanguages(instancePtr)
	End Method
	Rem
	bbdoc: Returns #True when the active user is subscribed to @appID.
	End Rem
	Method BIsSubscribedApp:Int(appID:UInt)
		Return bmx_SteamAPI_ISteamApps_BIsSubscribedApp(instancePtr, appID)
	End Method
	Rem
	bbdoc: Returns #True when the specified DLC is installed.
	End Rem
	Method BIsDlcInstalled:Int(appID:UInt)
		Return bmx_SteamAPI_ISteamApps_BIsDlcInstalled(instancePtr, appID)
	End Method
	Rem
	bbdoc: Returns the earliest purchase time for @appID as a Unix timestamp.
	End Rem
	Method GetEarliestPurchaseUnixTime:UInt(appID:UInt)
		Return bmx_SteamAPI_ISteamApps_GetEarliestPurchaseUnixTime(instancePtr, appID)
	End Method
	Rem
	bbdoc: Returns #True when access comes from a free-weekend license.
	End Rem
	Method BIsSubscribedFromFreeWeekend:Int()
		Return bmx_SteamAPI_ISteamApps_BIsSubscribedFromFreeWeekend(instancePtr)
	End Method
	Rem
	bbdoc: Returns the number of DLC entries known for the current application.
	End Rem
	Method GetDLCCount:Int()
		Return bmx_SteamAPI_ISteamApps_GetDLCCount(instancePtr)
	End Method
	Rem
	bbdoc: Returns the application ID, availability, and display name of a DLC entry.
	End Rem
	Method BGetDLCDataByIndex:Int(index:Int, appID:UInt Var, available:Int Var, name:String Var)
		Return bmx_SteamAPI_ISteamApps_BGetDLCDataByIndex(instancePtr, index, appID, available, name)
	End Method
	Rem
	bbdoc: Requests installation of the specified DLC.
	End Rem
	Method InstallDLC(appID:UInt)
		bmx_SteamAPI_ISteamApps_InstallDLC(instancePtr, appID)
	End Method
	Rem
	bbdoc: Requests removal of the specified DLC.
	End Rem
	Method UninstallDLC(appID:UInt)
		bmx_SteamAPI_ISteamApps_UninstallDLC(instancePtr, appID)
	End Method
	Rem
	bbdoc: Requests the proof-of-purchase key for @appID through #ISteamAppsListener.
	End Rem
	Method RequestAppProofOfPurchaseKey(appID:UInt)
		bmx_SteamAPI_ISteamApps_RequestAppProofOfPurchaseKey(instancePtr, appID)
	End Method
	Rem
	bbdoc: Returns the name of the beta branch selected by the user.
	End Rem
	Method GetCurrentBetaName:Int(name:String Var)
		Return bmx_SteamAPI_ISteamApps_GetCurrentBetaName(instancePtr, name)
	End Method
	Rem
	bbdoc: Asks Steam to verify the application's installed content.
	End Rem
	Method MarkContentCorrupt:Int(missingFilesOnly:Int)
		Return bmx_SteamAPI_ISteamApps_MarkContentCorrupt(instancePtr, missingFilesOnly)
	End Method
	Rem
	bbdoc: Copies up to @maxDepots installed depot IDs into @depots and returns the count.
	End Rem
	Method GetInstalledDepots:UInt(appID:UInt, depots:UInt Ptr, maxDepots:UInt)
		Return bmx_SteamAPI_ISteamApps_GetInstalledDepots(instancePtr, appID, depots, maxDepots)
	End Method
	Rem
	bbdoc: Returns the installation directory for @appID in @folder.
	End Rem
	Method GetAppInstallDir:UInt(appID:UInt, folder:String Var)
		Return bmx_SteamAPI_ISteamApps_GetAppInstallDir(instancePtr, appID, folder)
	End Method
	Rem
	bbdoc: Returns #True when @appID is installed on this computer.
	End Rem
	Method BIsAppInstalled:Int(appID:UInt)
		Return bmx_SteamAPI_ISteamApps_BIsAppInstalled(instancePtr, appID)
	End Method
	Rem
	bbdoc: Returns the Steam ID of the account that owns the current application license.
	End Rem
	Method GetAppOwner:ULong()
		Return bmx_SteamAPI_ISteamApps_GetAppOwner(instancePtr)
	End Method
	Rem
	bbdoc: Returns a query parameter supplied in a Steam URL launch.
	End Rem
	Method GetLaunchQueryParam:String(key:String)
		Return bmx_SteamAPI_ISteamApps_GetLaunchQueryParam(instancePtr, key)
	End Method
	Rem
	bbdoc: Returns the downloaded and total byte counts for a DLC installation.
	End Rem
	Method GetDlcDownloadProgress:Int(appID:UInt, downloaded:ULong Var, total:ULong Var)
		Return bmx_SteamAPI_ISteamApps_GetDlcDownloadProgress(instancePtr, appID, downloaded, total)
	End Method
	Rem
	bbdoc: Returns the build ID of the currently installed application.
	End Rem
	Method GetAppBuildId:Int()
		Return bmx_SteamAPI_ISteamApps_GetAppBuildId(instancePtr)
	End Method
	Rem
	bbdoc: Requests proof-of-purchase keys for all owned DLC.
	End Rem
	Method RequestAllProofOfPurchaseKeys()
		bmx_SteamAPI_ISteamApps_RequestAllProofOfPurchaseKeys(instancePtr)
	End Method
	Rem
	bbdoc: Requests file size, SHA-1, and flag information through #ISteamAppsListener.
	End Rem
	Method GetFileDetails(fileName:String)
		bmx_SteamAPI_ISteamApps_GetFileDetails(callbackPtr, fileName)
	End Method
	Rem
	bbdoc: Returns #True when access comes from Steam Family Sharing.
	End Rem
	Method BIsSubscribedFromFamilySharing:Int()
		Return bmx_SteamAPI_ISteamApps_BIsSubscribedFromFamilySharing(instancePtr)
	End Method
	Rem
	bbdoc: Reports whether this is a timed trial and returns its allowed and played durations.
	End Rem
	Method BIsTimedTrial:Int(secondsAllowed:UInt Var, secondsPlayed:UInt Var)
		Return bmx_SteamAPI_ISteamApps_BIsTimedTrial(instancePtr, secondsAllowed, secondsPlayed)
	End Method

	Rem
	bbdoc: Returns the command line supplied by Steam when the application was launched.
	about: This includes special launch parameters such as +connect_lobby after
	a user accepts a lobby invitation while the application is not running.
	End Rem
	Method GetLaunchCommandLine:String()
		Return bmx_SteamAPI_ISteamApps_GetLaunchCommandLine(instancePtr)
	End Method

	Rem
	bbdoc: Selects the DLC context currently being played, or zero to clear it.
	End Rem
	Method SetDlcContext:Int(appID:UInt)
		Return bmx_SteamAPI_ISteamApps_SetDlcContext(instancePtr, appID)
	End Method

	Rem
	bbdoc: Returns the number of known beta branches and writes availability counts.
	End Rem
	Method GetNumBetas:Int(available:Int Var, privateBetas:Int Var)
		Return bmx_SteamAPI_ISteamApps_GetNumBetas(instancePtr, available, privateBetas)
	End Method

	Rem
	bbdoc: Retrieves details for a beta branch by index.
	End Rem
	Method GetBetaInfo:Int(index:Int, flags:UInt Var, buildID:UInt Var, name:String Var, description:String Var, lastUpdated:UInt Var)
		Return bmx_SteamAPI_ISteamApps_GetBetaInfo(instancePtr, index, flags, buildID, name, description, lastUpdated)
	End Method

	Rem
	bbdoc: Selects the active beta branch. Pass an empty name for the public branch.
	End Rem
	Method SetActiveBeta:Int(name:String)
		Return bmx_SteamAPI_ISteamApps_SetActiveBeta(instancePtr, name)
	End Method

	Rem
	bbdoc: Reports the performance preset selected by the game.
	End Rem
	Method SetGamePerformanceSetting(setting:EGamePerformanceSetting)
		bmx_SteamAPI_ISteamApps_SetGamePerformanceSetting(instancePtr, setting)
	End Method

	Rem
	bbdoc: Reports the current game render resolution to Steam.
	End Rem
	Method SetGameRenderResolution(width:UInt, height:UInt)
		bmx_SteamAPI_ISteamApps_SetGameRenderResolution(instancePtr, width, height)
	End Method

	Method OnDlcInstalled(appID:UInt)
		If listener Then listener.OnDlcInstalled(appID)
	End Method
	Function _OnDlcInstalled(inst:TSteamApps, appID:UInt) { nomangle }
		inst.OnDlcInstalled(appID)
	End Function
	Method OnNewUrlLaunchParameters()
		If listener Then listener.OnNewUrlLaunchParameters()
	End Method
	Function _OnNewUrlLaunchParameters(inst:TSteamApps) { nomangle }
		inst.OnNewUrlLaunchParameters()
	End Function
	Method OnAppProofOfPurchaseKey(result:EResult, appID:UInt, key:String)
		If listener Then listener.OnAppProofOfPurchaseKey(result, appID, key)
	End Method
	Function _OnAppProofOfPurchaseKey(inst:TSteamApps, result:EResult, appID:UInt, key:String) { nomangle }
		inst.OnAppProofOfPurchaseKey(result, appID, key)
	End Function
	Method OnTimedTrialStatus(appID:UInt, offline:Int, secondsAllowed:UInt, secondsPlayed:UInt)
		If listener Then listener.OnTimedTrialStatus(appID, offline, secondsAllowed, secondsPlayed)
	End Method
	Function _OnTimedTrialStatus(inst:TSteamApps, appID:UInt, offline:Int, secondsAllowed:UInt, secondsPlayed:UInt) { nomangle }
		inst.OnTimedTrialStatus(appID, offline, secondsAllowed, secondsPlayed)
	End Function
	Method OnFileDetails(result:EResult, fileSize:ULong, sha1:String, flags:UInt, ioFailure:Int)
		If listener Then listener.OnFileDetails(result, fileSize, sha1, flags, ioFailure)
	End Method
	Function _OnFileDetails(inst:TSteamApps, result:EResult, fileSize:ULong, sha1:String, flags:UInt, ioFailure:Int) { nomangle }
		inst.OnFileDetails(result, fileSize, sha1, flags, ioFailure)
	End Function
End Type

Rem
bbdoc: Listener for Steam lobby matchmaking results and changes.
End Rem
Interface ISteamMatchmakingListener
	Method OnLobbyCreated(result:EResult, steamIDLobby:ULong, ioFailure:Int)
	Method OnLobbyMatchList(lobbyCount:UInt, ioFailure:Int)
	Method OnLobbyEnter(steamIDLobby:ULong, locked:Int, response:EChatRoomEnterResponse)
	Method OnLobbyDataUpdate(steamIDLobby:ULong, steamIDMember:ULong, success:Int)
	Method OnLobbyChatUpdate(steamIDLobby:ULong, steamIDUserChanged:ULong, steamIDMakingChange:ULong, stateChange:EChatMemberStateChange)
	Method OnLobbyChatMessage(steamIDLobby:ULong, steamIDUser:ULong, chatEntryType:EChatEntryType, chatID:UInt)
	Method OnLobbyGameCreated(steamIDLobby:ULong, steamIDGameServer:ULong, ip:UInt, port:Short)
	Method OnLobbyInvite(steamIDUser:ULong, steamIDLobby:ULong, gameID:ULong)
	Method OnLobbyJoinRequested(steamIDLobby:ULong, steamIDFriend:ULong)
End Interface

Rem
bbdoc: Steam lobby creation, discovery, membership, and metadata.
End Rem
Type TSteamMatchmaking Extends TSteamAPI
	Const STEAMMATCHMAKING_INTERFACE_VERSION:String = "SteamMatchMaking009"
	Field listener:ISteamMatchmakingListener

	Function _create:TSteamMatchmaking(instancePtr:Byte Ptr)
		If Not instancePtr Then Return Null
		Local this:TSteamMatchmaking = New TSteamMatchmaking
		this.instancePtr = instancePtr
		this.callbackPtr = bmx_steamsdk_register_steammatchmaking(instancePtr, this)
		Return this
	End Function

	Method Delete()
		If callbackPtr Then bmx_steamsdk_unregister_steammatchmaking(callbackPtr)
		callbackPtr = Null
	End Method

	Rem
	bbdoc: Sets the listener that receives asynchronous results and Steam callbacks for this interface.
	End Rem
	Method SetListener(listener:ISteamMatchmakingListener)
		Self.listener = listener
	End Method

	Rem
	bbdoc: Returns the number of entries in the user's favorite and history server list.
	End Rem
	Method GetFavoriteGameCount:Int()
		Return bmx_SteamAPI_ISteamMatchmaking_GetFavoriteGameCount(instancePtr)
	End Method
	Rem
	bbdoc: Returns one favorite or history server entry by index.
	End Rem
	Method GetFavoriteGame:Int(index:Int, appID:UInt Var, ip:UInt Var, connectionPort:Short Var, queryPort:Short Var, flags:UInt Var, lastPlayed:UInt Var)
		Return bmx_SteamAPI_ISteamMatchmaking_GetFavoriteGame(instancePtr, index, appID, ip, connectionPort, queryPort, flags, lastPlayed)
	End Method
	Rem
	bbdoc: Adds a server to the user's favorite or history list.
	End Rem
	Method AddFavoriteGame:Int(appID:UInt, ip:UInt, connectionPort:Short, queryPort:Short, flags:UInt, lastPlayed:UInt)
		Return bmx_SteamAPI_ISteamMatchmaking_AddFavoriteGame(instancePtr, appID, ip, connectionPort, queryPort, flags, lastPlayed)
	End Method
	Rem
	bbdoc: Removes a server from the user's favorite or history list.
	End Rem
	Method RemoveFavoriteGame:Int(appID:UInt, ip:UInt, connectionPort:Short, queryPort:Short, flags:UInt)
		Return bmx_SteamAPI_ISteamMatchmaking_RemoveFavoriteGame(instancePtr, appID, ip, connectionPort, queryPort, flags)
	End Method

	Rem
	bbdoc: Adds a string metadata comparison to the next lobby-list request.
	End Rem
	Method AddRequestLobbyListStringFilter(key:String, value:String, comparison:ELobbyComparison = ELobbyComparison.k_ELobbyComparisonEqual)
		bmx_SteamAPI_ISteamMatchmaking_AddRequestLobbyListStringFilter(instancePtr, key, value, comparison)
	End Method

	Rem
	bbdoc: Adds a numeric metadata comparison to the next lobby-list request.
	End Rem
	Method AddRequestLobbyListNumericalFilter(key:String, value:Int, comparison:ELobbyComparison = ELobbyComparison.k_ELobbyComparisonEqual)
		bmx_SteamAPI_ISteamMatchmaking_AddRequestLobbyListNumericalFilter(instancePtr, key, value, comparison)
	End Method

	Rem
	bbdoc: Orders the next lobby-list result by distance from a numeric metadata value.
	End Rem
	Method AddRequestLobbyListNearValueFilter(key:String, value:Int)
		bmx_SteamAPI_ISteamMatchmaking_AddRequestLobbyListNearValueFilter(instancePtr, key, value)
	End Method

	Rem
	bbdoc: Limits the number of lobbies returned by the next lobby-list request.
	End Rem
	Method AddRequestLobbyListResultCountFilter(maxResults:Int)
		bmx_SteamAPI_ISteamMatchmaking_AddRequestLobbyListResultCountFilter(instancePtr, maxResults)
	End Method

	Rem
	bbdoc: Requires a minimum number of open slots in the next lobby-list request.
	End Rem
	Method AddRequestLobbyListFilterSlotsAvailable(slotsAvailable:Int)
		bmx_SteamAPI_ISteamMatchmaking_AddRequestLobbyListFilterSlotsAvailable(instancePtr, slotsAvailable)
	End Method

	Rem
	bbdoc: Sets the geographic distance used by the next lobby-list request.
	End Rem
	Method AddRequestLobbyListDistanceFilter(distance:ELobbyDistanceFilter)
		bmx_SteamAPI_ISteamMatchmaking_AddRequestLobbyListDistanceFilter(instancePtr, distance)
	End Method

	Rem
	bbdoc: Restricts the next lobby-list request to lobbies compatible with members of another lobby.
	End Rem
	Method AddRequestLobbyListCompatibleMembersFilter(steamIDLobby:ULong)
		bmx_SteamAPI_ISteamMatchmaking_AddRequestLobbyListCompatibleMembersFilter(instancePtr, steamIDLobby)
	End Method

	Rem
	bbdoc: Starts an asynchronous lobby search using the filters added since the previous request.
	End Rem
	Method RequestLobbyList()
		bmx_SteamAPI_ISteamMatchmaking_RequestLobbyList(callbackPtr)
	End Method

	Rem
	bbdoc: Creates a lobby asynchronously and reports the result through #ISteamMatchmakingListener.
	End Rem
	Method CreateLobby(lobbyType:ELobbyType, maxMembers:Int)
		bmx_SteamAPI_ISteamMatchmaking_CreateLobby(callbackPtr, lobbyType, maxMembers)
	End Method

	Rem
	bbdoc: Joins a lobby asynchronously and reports entry through #ISteamMatchmakingListener.
	End Rem
	Method JoinLobby(steamIDLobby:ULong)
		bmx_SteamAPI_ISteamMatchmaking_JoinLobby(instancePtr, steamIDLobby)
	End Method

	Rem
	bbdoc: Leaves a lobby immediately.
	End Rem
	Method LeaveLobby(steamIDLobby:ULong)
		bmx_SteamAPI_ISteamMatchmaking_LeaveLobby(instancePtr, steamIDLobby)
	End Method

	Rem
	bbdoc: Returns a lobby ID from the most recent successful lobby-list result.
	End Rem
	Method GetLobbyByIndex:ULong(index:Int)
		Return bmx_SteamAPI_ISteamMatchmaking_GetLobbyByIndex(instancePtr, index)
	End Method
	Rem
	bbdoc: Returns the current number of members in a joined lobby.
	End Rem
	Method GetNumLobbyMembers:Int(steamIDLobby:ULong)
		Return bmx_SteamAPI_ISteamMatchmaking_GetNumLobbyMembers(instancePtr, steamIDLobby)
	End Method
	Rem
	bbdoc: Returns a member's Steam ID from a joined lobby.
	End Rem
	Method GetLobbyMemberByIndex:ULong(steamIDLobby:ULong, member:Int)
		Return bmx_SteamAPI_ISteamMatchmaking_GetLobbyMemberByIndex(instancePtr, steamIDLobby, member)
	End Method
	Rem
	bbdoc: Returns a lobby metadata value for @key.
	End Rem
	Method GetLobbyData:String(steamIDLobby:ULong, key:String)
		Return bmx_SteamAPI_ISteamMatchmaking_GetLobbyData(instancePtr, steamIDLobby, key)
	End Method
	Rem
	bbdoc: Sets lobby metadata; only the lobby owner may change it.
	End Rem
	Method SetLobbyData:Int(steamIDLobby:ULong, key:String, value:String)
		Return bmx_SteamAPI_ISteamMatchmaking_SetLobbyData(instancePtr, steamIDLobby, key, value)
	End Method
	Rem
	bbdoc: Returns the number of metadata entries associated with a lobby.
	End Rem
	Method GetLobbyDataCount:Int(steamIDLobby:ULong)
		Return bmx_SteamAPI_ISteamMatchmaking_GetLobbyDataCount(instancePtr, steamIDLobby)
	End Method
	Rem
	bbdoc: Returns one lobby metadata key/value pair by index.
	End Rem
	Method GetLobbyDataByIndex:Int(steamIDLobby:ULong, index:Int, key:String Var, value:String Var)
		Return bmx_SteamAPI_ISteamMatchmaking_GetLobbyDataByIndex(instancePtr, steamIDLobby, index, key, value)
	End Method
	Rem
	bbdoc: Deletes lobby metadata; only the lobby owner may change it.
	End Rem
	Method DeleteLobbyData:Int(steamIDLobby:ULong, key:String)
		Return bmx_SteamAPI_ISteamMatchmaking_DeleteLobbyData(instancePtr, steamIDLobby, key)
	End Method
	Rem
	bbdoc: Returns member-specific metadata from a joined lobby.
	End Rem
	Method GetLobbyMemberData:String(steamIDLobby:ULong, steamIDUser:ULong, key:String)
		Return bmx_SteamAPI_ISteamMatchmaking_GetLobbyMemberData(instancePtr, steamIDLobby, steamIDUser, key)
	End Method
	Rem
	bbdoc: Sets metadata for the local member of a joined lobby.
	End Rem
	Method SetLobbyMemberData(steamIDLobby:ULong, key:String, value:String)
		bmx_SteamAPI_ISteamMatchmaking_SetLobbyMemberData(instancePtr, steamIDLobby, key, value)
	End Method
	Rem
	bbdoc: Sends a binary chat message to every member of a joined lobby.
	End Rem
	Method SendLobbyChatMsg:Int(steamIDLobby:ULong, data:Byte Ptr, size:Int)
		Return bmx_SteamAPI_ISteamMatchmaking_SendLobbyChatMsg(instancePtr, steamIDLobby, data, size)
	End Method
	Rem
	bbdoc: Copies a lobby chat entry into @data and returns its byte count.
	End Rem
	Method GetLobbyChatEntry:Int(steamIDLobby:ULong, chatID:Int, steamIDUser:ULong Var, data:Byte Ptr, capacity:Int, chatEntryType:EChatEntryType Var)
		Return bmx_SteamAPI_ISteamMatchmaking_GetLobbyChatEntry(instancePtr, steamIDLobby, chatID, steamIDUser, data, capacity, chatEntryType)
	End Method
	Rem
	bbdoc: Refreshes lobby metadata and reports completion through #ISteamMatchmakingListener.
	End Rem
	Method RequestLobbyData:Int(steamIDLobby:ULong)
		Return bmx_SteamAPI_ISteamMatchmaking_RequestLobbyData(instancePtr, steamIDLobby)
	End Method
	Rem
	bbdoc: Associates a game server endpoint or Steam ID with a lobby.
	End Rem
	Method SetLobbyGameServer(steamIDLobby:ULong, ip:UInt, port:Short, steamIDGameServer:ULong)
		bmx_SteamAPI_ISteamMatchmaking_SetLobbyGameServer(instancePtr, steamIDLobby, ip, port, steamIDGameServer)
	End Method
	Rem
	bbdoc: Returns the game server associated with a lobby.
	End Rem
	Method GetLobbyGameServer:Int(steamIDLobby:ULong, ip:UInt Var, port:Short Var, steamIDGameServer:ULong Var)
		Return bmx_SteamAPI_ISteamMatchmaking_GetLobbyGameServer(instancePtr, steamIDLobby, ip, port, steamIDGameServer)
	End Method
	Rem
	bbdoc: Sets the maximum membership of a lobby.
	End Rem
	Method SetLobbyMemberLimit:Int(steamIDLobby:ULong, maxMembers:Int)
		Return bmx_SteamAPI_ISteamMatchmaking_SetLobbyMemberLimit(instancePtr, steamIDLobby, maxMembers)
	End Method
	Rem
	bbdoc: Returns the maximum membership of a lobby.
	End Rem
	Method GetLobbyMemberLimit:Int(steamIDLobby:ULong)
		Return bmx_SteamAPI_ISteamMatchmaking_GetLobbyMemberLimit(instancePtr, steamIDLobby)
	End Method
	Rem
	bbdoc: Changes a lobby's visibility and join policy.
	End Rem
	Method SetLobbyType:Int(steamIDLobby:ULong, lobbyType:ELobbyType)
		Return bmx_SteamAPI_ISteamMatchmaking_SetLobbyType(instancePtr, steamIDLobby, lobbyType)
	End Method
	Rem
	bbdoc: Controls whether new users may join a lobby.
	End Rem
	Method SetLobbyJoinable:Int(steamIDLobby:ULong, joinable:Int)
		Return bmx_SteamAPI_ISteamMatchmaking_SetLobbyJoinable(instancePtr, steamIDLobby, joinable)
	End Method
	Rem
	bbdoc: Returns the Steam ID of the lobby owner.
	End Rem
	Method GetLobbyOwner:ULong(steamIDLobby:ULong)
		Return bmx_SteamAPI_ISteamMatchmaking_GetLobbyOwner(instancePtr, steamIDLobby)
	End Method
	Rem
	bbdoc: Transfers lobby ownership to another current member.
	End Rem
	Method SetLobbyOwner:Int(steamIDLobby:ULong, steamIDNewOwner:ULong)
		Return bmx_SteamAPI_ISteamMatchmaking_SetLobbyOwner(instancePtr, steamIDLobby, steamIDNewOwner)
	End Method
	Rem
	bbdoc: Links a dependent lobby to a primary lobby.
	End Rem
	Method SetLinkedLobby:Int(steamIDLobby:ULong, steamIDLobbyDependent:ULong)
		Return bmx_SteamAPI_ISteamMatchmaking_SetLinkedLobby(instancePtr, steamIDLobby, steamIDLobbyDependent)
	End Method
	Rem
	bbdoc: Invites a Steam user to a lobby.
	End Rem
	Method InviteUserToLobby:Int(steamIDLobby:ULong, steamIDInvitee:ULong)
		Return bmx_SteamAPI_ISteamMatchmaking_InviteUserToLobby(instancePtr, steamIDLobby, steamIDInvitee)
	End Method

	Method OnLobbyCreated(result:EResult, steamIDLobby:ULong, ioFailure:Int)
		If listener Then listener.OnLobbyCreated(result, steamIDLobby, ioFailure)
	End Method
	Function _OnLobbyCreated(inst:TSteamMatchmaking, result:EResult, steamIDLobby:ULong, ioFailure:Int) { nomangle }
		inst.OnLobbyCreated(result, steamIDLobby, ioFailure)
	End Function
	Method OnLobbyMatchList(lobbyCount:UInt, ioFailure:Int)
		If listener Then listener.OnLobbyMatchList(lobbyCount, ioFailure)
	End Method
	Function _OnLobbyMatchList(inst:TSteamMatchmaking, lobbyCount:UInt, ioFailure:Int) { nomangle }
		inst.OnLobbyMatchList(lobbyCount, ioFailure)
	End Function
	Method OnLobbyEnter(steamIDLobby:ULong, locked:Int, response:EChatRoomEnterResponse)
		If listener Then listener.OnLobbyEnter(steamIDLobby, locked, response)
	End Method
	Function _OnLobbyEnter(inst:TSteamMatchmaking, steamIDLobby:ULong, locked:Int, response:EChatRoomEnterResponse) { nomangle }
		inst.OnLobbyEnter(steamIDLobby, locked, response)
	End Function
	Method OnLobbyDataUpdate(steamIDLobby:ULong, steamIDMember:ULong, success:Int)
		If listener Then listener.OnLobbyDataUpdate(steamIDLobby, steamIDMember, success)
	End Method
	Function _OnLobbyDataUpdate(inst:TSteamMatchmaking, steamIDLobby:ULong, steamIDMember:ULong, success:Int) { nomangle }
		inst.OnLobbyDataUpdate(steamIDLobby, steamIDMember, success)
	End Function
	Method OnLobbyChatUpdate(steamIDLobby:ULong, steamIDUserChanged:ULong, steamIDMakingChange:ULong, stateChange:EChatMemberStateChange)
		If listener Then listener.OnLobbyChatUpdate(steamIDLobby, steamIDUserChanged, steamIDMakingChange, stateChange)
	End Method
	Function _OnLobbyChatUpdate(inst:TSteamMatchmaking, steamIDLobby:ULong, steamIDUserChanged:ULong, steamIDMakingChange:ULong, stateChange:EChatMemberStateChange) { nomangle }
		inst.OnLobbyChatUpdate(steamIDLobby, steamIDUserChanged, steamIDMakingChange, stateChange)
	End Function
	Method OnLobbyChatMessage(steamIDLobby:ULong, steamIDUser:ULong, chatEntryType:EChatEntryType, chatID:UInt)
		If listener Then listener.OnLobbyChatMessage(steamIDLobby, steamIDUser, chatEntryType, chatID)
	End Method
	Function _OnLobbyChatMessage(inst:TSteamMatchmaking, steamIDLobby:ULong, steamIDUser:ULong, chatEntryType:EChatEntryType, chatID:UInt) { nomangle }
		inst.OnLobbyChatMessage(steamIDLobby, steamIDUser, chatEntryType, chatID)
	End Function
	Method OnLobbyGameCreated(steamIDLobby:ULong, steamIDGameServer:ULong, ip:UInt, port:Short)
		If listener Then listener.OnLobbyGameCreated(steamIDLobby, steamIDGameServer, ip, port)
	End Method
	Function _OnLobbyGameCreated(inst:TSteamMatchmaking, steamIDLobby:ULong, steamIDGameServer:ULong, ip:UInt, port:Short) { nomangle }
		inst.OnLobbyGameCreated(steamIDLobby, steamIDGameServer, ip, port)
	End Function
	Method OnLobbyInvite(steamIDUser:ULong, steamIDLobby:ULong, gameID:ULong)
		If listener Then listener.OnLobbyInvite(steamIDUser, steamIDLobby, gameID)
	End Method
	Function _OnLobbyInvite(inst:TSteamMatchmaking, steamIDUser:ULong, steamIDLobby:ULong, gameID:ULong) { nomangle }
		inst.OnLobbyInvite(steamIDUser, steamIDLobby, gameID)
	End Function
	Method OnLobbyJoinRequested(steamIDLobby:ULong, steamIDFriend:ULong)
		If listener Then listener.OnLobbyJoinRequested(steamIDLobby, steamIDFriend)
	End Method
	Function _OnLobbyJoinRequested(inst:TSteamMatchmaking, steamIDLobby:ULong, steamIDFriend:ULong) { nomangle }
		inst.OnLobbyJoinRequested(steamIDLobby, steamIDFriend)
	End Function
End Type

Const STEAM_NETWORKING_SEND_UNRELIABLE:Int = 0
Const STEAM_NETWORKING_SEND_NO_NAGLE:Int = 1
Const STEAM_NETWORKING_SEND_NO_DELAY:Int = 4
Const STEAM_NETWORKING_SEND_RELIABLE:Int = 8
Const STEAM_NETWORKING_SEND_AUTO_RESTART:Int = 32

Interface ISteamNetworkingMessagesListener
	Method OnSteamNetworkingMessagesSessionRequest(steamIDRemote:ULong)
	Method OnSteamNetworkingMessagesSessionFailed(steamIDRemote:ULong, state:ESteamNetworkingConnectionState, endReason:Int, debugMessage:String)
End Interface

Rem
bbdoc: UDP-like reliable and unreliable messages addressed by Steam identity.
End Rem
Type TSteamNetworkingMessages Extends TSteamAPI
	Field listener:ISteamNetworkingMessagesListener

	Function Create:TSteamNetworkingMessages()
		Local instancePtr:Byte Ptr = bmx_SteamAPI_SteamNetworkingMessages()
		If Not instancePtr Then Return Null
		Local this:TSteamNetworkingMessages = New TSteamNetworkingMessages
		this.instancePtr = instancePtr
		this.callbackPtr = bmx_steamsdk_register_steamnetworkingmessages(instancePtr, this)
		Return this
	End Function

	Method Delete()
		If callbackPtr Then bmx_steamsdk_unregister_steamnetworkingmessages(callbackPtr)
		callbackPtr = Null
	End Method

	Rem
	bbdoc: Sets the listener that receives asynchronous results and Steam callbacks for this interface.
	End Rem
	Method SetListener(listener:ISteamNetworkingMessagesListener)
		Self.listener = listener
	End Method
	Rem
	bbdoc: Sends one binary networking message to a Steam user on the selected channel.
	End Rem
	Method SendMessageToUser:EResult(steamIDRemote:ULong, data:Byte Ptr, size:UInt, sendFlags:Int = STEAM_NETWORKING_SEND_UNRELIABLE, remoteChannel:Int = 0)
		Return bmx_SteamAPI_ISteamNetworkingMessages_SendMessageToUser(instancePtr, steamIDRemote, data, size, sendFlags, remoteChannel)
	End Method
	Rem
	bbdoc: Receives and consumes one message. Returns 1, 0 when empty, or -1 when capacity was too small.
	about: Size always receives the original message size when a message was consumed.
	End Rem
	Method ReceiveMessage:Int(localChannel:Int, data:Byte Ptr, capacity:UInt, size:UInt Var, steamIDRemote:ULong Var, reliable:Int Var)
		Return bmx_SteamAPI_ISteamNetworkingMessages_ReceiveMessage(instancePtr, localChannel, data, capacity, size, steamIDRemote, reliable)
	End Method
	Rem
	bbdoc: Accepts an incoming networking-messages session request.
	End Rem
	Method AcceptSessionWithUser:Int(steamIDRemote:ULong)
		Return bmx_SteamAPI_ISteamNetworkingMessages_AcceptSessionWithUser(instancePtr, steamIDRemote)
	End Method
	Rem
	bbdoc: Closes all networking-messages channels to a remote user.
	End Rem
	Method CloseSessionWithUser:Int(steamIDRemote:ULong)
		Return bmx_SteamAPI_ISteamNetworkingMessages_CloseSessionWithUser(instancePtr, steamIDRemote)
	End Method
	Rem
	bbdoc: Closes one local networking-messages channel to a remote user.
	End Rem
	Method CloseChannelWithUser:Int(steamIDRemote:ULong, localChannel:Int)
		Return bmx_SteamAPI_ISteamNetworkingMessages_CloseChannelWithUser(instancePtr, steamIDRemote, localChannel)
	End Method
	Rem
	bbdoc: Returns current connection state and commonly useful real-time diagnostics for a remote user.
	End Rem
	Method GetSessionConnectionInfo:ESteamNetworkingConnectionState(steamIDRemote:ULong, endReason:Int Var, endDebug:String Var, ping:Int Var, qualityLocal:Float Var, qualityRemote:Float Var, pendingUnreliable:Int Var, pendingReliable:Int Var, sentUnackedReliable:Int Var, queueTimeMicroseconds:Long Var)
		Return bmx_SteamAPI_ISteamNetworkingMessages_GetSessionConnectionInfo(instancePtr, steamIDRemote, endReason, endDebug, ping, qualityLocal, qualityRemote, pendingUnreliable, pendingReliable, sentUnackedReliable, queueTimeMicroseconds)
	End Method
	Method OnSessionRequest(steamIDRemote:ULong)
		If listener Then listener.OnSteamNetworkingMessagesSessionRequest(steamIDRemote)
	End Method
	Function _OnSessionRequest(inst:TSteamNetworkingMessages, steamIDRemote:ULong) { nomangle }
		inst.OnSessionRequest(steamIDRemote)
	End Function
	Method OnSessionFailed(steamIDRemote:ULong, state:ESteamNetworkingConnectionState, endReason:Int, debugMessage:String)
		If listener Then listener.OnSteamNetworkingMessagesSessionFailed(steamIDRemote, state, endReason, debugMessage)
	End Method
	Function _OnSessionFailed(inst:TSteamNetworkingMessages, steamIDRemote:ULong, state:ESteamNetworkingConnectionState, endReason:Int, debugMessage:String) { nomangle }
		inst.OnSessionFailed(steamIDRemote, state, endReason, debugMessage)
	End Function
End Type

Rem
bbdoc: Receives connection lifecycle changes from Steam Networking Sockets.
End Rem
Interface ISteamNetworkingSocketsListener
	Method OnSteamNetworkingSocketsConnectionStatusChanged(connection:UInt, listenSocket:UInt, remoteSteamID:ULong, oldState:ESteamNetworkingConnectionState, state:ESteamNetworkingConnectionState, endReason:Int, debugMessage:String)
End Interface

Rem
bbdoc: Connection-oriented reliable and unreliable networking over Steam identities or IP addresses.
about: Create the client interface for a normal game process, or the game-server interface after Steam game-server initialization. Incoming connections must be explicitly accepted from the listener callback.
End Rem
Type TSteamNetworkingSockets Extends TSteamAPI
	Const STEAMNETWORKINGSOCKETS_INTERFACE_VERSION:String = "SteamNetworkingSockets013"

	Field listener:ISteamNetworkingSocketsListener
	Field gameServer:Int

	Function Create:TSteamNetworkingSockets(gameServer:Int = False)
		Local native:Byte Ptr = bmx_SteamAPI_SteamNetworkingSockets(gameServer)
		If Not native Then Return Null
		Local sockets:TSteamNetworkingSockets = New TSteamNetworkingSockets
		sockets.instancePtr = native
		sockets.gameServer = gameServer
		sockets.callbackPtr = bmx_steamsdk_register_networkingsockets(native, sockets, gameServer)
		Return sockets
	End Function

	Method Delete()
		If callbackPtr Then bmx_steamsdk_unregister_networkingsockets(callbackPtr)
		callbackPtr = Null
	End Method

	Method SetListener(listener:ISteamNetworkingSocketsListener)
		Self.listener = listener
	End Method

	Rem
	bbdoc: Dispatches the callback queue appropriate to this client or game-server interface.
	End Rem
	Method RunCallbacks()
		If gameServer Then
			SteamGameServerRunCallbacks()
		Else
			SteamRunCallbacks()
		End If
	End Method

	Rem
	bbdoc: Creates a direct IP listen socket. An empty address binds all local interfaces.
	End Rem
	Method CreateListenSocketIP:UInt(address:String, port:Int)
		Return bmx_SteamAPI_ISteamNetworkingSockets_CreateListenSocketIP(instancePtr, address, port)
	End Method

	Rem
	bbdoc: Begins connecting to a numeric IPv4 or IPv6 address.
	End Rem
	Method ConnectByIPAddress:UInt(address:String, port:Int)
		Return bmx_SteamAPI_ISteamNetworkingSockets_ConnectByIPAddress(instancePtr, address, port)
	End Method

	Rem
	bbdoc: Creates a P2P listen socket on a virtual port.
	End Rem
	Method CreateListenSocketP2P:UInt(virtualPort:Int = 0)
		Return bmx_SteamAPI_ISteamNetworkingSockets_CreateListenSocketP2P(instancePtr, virtualPort)
	End Method

	Rem
	bbdoc: Begins a P2P connection to a Steam identity and virtual port.
	End Rem
	Method ConnectP2P:UInt(steamID:ULong, virtualPort:Int = 0)
		Return bmx_SteamAPI_ISteamNetworkingSockets_ConnectP2P(instancePtr, steamID, virtualPort)
	End Method

	Method AcceptConnection:EResult(connection:UInt)
		Return bmx_SteamAPI_ISteamNetworkingSockets_AcceptConnection(instancePtr, connection)
	End Method

	Method CloseConnection:Int(connection:UInt, reason:Int = 0, debugMessage:String = "", linger:Int = False)
		Return bmx_SteamAPI_ISteamNetworkingSockets_CloseConnection(instancePtr, connection, reason, debugMessage, linger)
	End Method

	Method CloseListenSocket:Int(socket:UInt)
		Return bmx_SteamAPI_ISteamNetworkingSockets_CloseListenSocket(instancePtr, socket)
	End Method

	Method SendMessageToConnection:EResult(connection:UInt, data:Byte Ptr, size:UInt, sendFlags:Int, messageNumber:Long Var)
		Return bmx_SteamAPI_ISteamNetworkingSockets_SendMessageToConnection(instancePtr, connection, data, size, sendFlags, messageNumber)
	End Method

	Rem
	bbdoc: Receives and consumes one message. Returns 1, 0 when empty, or -1 when capacity was too small.
	End Rem
	Method ReceiveMessageOnConnection:Int(connection:UInt, data:Byte Ptr, capacity:UInt, size:UInt Var, flags:Int Var)
		Return bmx_SteamAPI_ISteamNetworkingSockets_ReceiveMessageOnConnection(instancePtr, connection, data, capacity, size, flags)
	End Method

	Method CreatePollGroup:UInt()
		Return bmx_SteamAPI_ISteamNetworkingSockets_CreatePollGroup(instancePtr)
	End Method

	Method DestroyPollGroup:Int(pollGroup:UInt)
		Return bmx_SteamAPI_ISteamNetworkingSockets_DestroyPollGroup(instancePtr, pollGroup)
	End Method

	Method SetConnectionPollGroup:Int(connection:UInt, pollGroup:UInt)
		Return bmx_SteamAPI_ISteamNetworkingSockets_SetConnectionPollGroup(instancePtr, connection, pollGroup)
	End Method

	Rem
	bbdoc: Receives and consumes one message from any connection in a poll group.
	End Rem
	Method ReceiveMessageOnPollGroup:Int(pollGroup:UInt, data:Byte Ptr, capacity:UInt, connection:UInt Var, size:UInt Var, flags:Int Var)
		Return bmx_SteamAPI_ISteamNetworkingSockets_ReceiveMessageOnPollGroup(instancePtr, pollGroup, data, capacity, connection, size, flags)
	End Method

	Rem
	bbdoc: Returns state and commonly useful real-time diagnostics for a connection.
	End Rem
	Method GetConnectionStatus:EResult(connection:UInt, state:ESteamNetworkingConnectionState Var, endReason:Int Var, endDebug:String Var, ping:Int Var, qualityLocal:Float Var, qualityRemote:Float Var, pendingUnreliable:Int Var, pendingReliable:Int Var, sentUnackedReliable:Int Var, queueTimeMicroseconds:Long Var)
		Return bmx_SteamAPI_ISteamNetworkingSockets_GetConnectionStatus(instancePtr, connection, state, endReason, endDebug, ping, qualityLocal, qualityRemote, pendingUnreliable, pendingReliable, sentUnackedReliable, queueTimeMicroseconds)
	End Method

	Private
	Method OnConnectionStatusChanged(connection:UInt, listenSocket:UInt, remoteSteamID:ULong, oldState:ESteamNetworkingConnectionState, state:ESteamNetworkingConnectionState, endReason:Int, debugMessage:String)
		If listener Then listener.OnSteamNetworkingSocketsConnectionStatusChanged(connection, listenSocket, remoteSteamID, oldState, state, endReason, debugMessage)
	End Method

	Function _OnConnectionStatusChanged(inst:TSteamNetworkingSockets, connection:UInt, listenSocket:UInt, remoteSteamID:ULong, oldState:ESteamNetworkingConnectionState, state:ESteamNetworkingConnectionState, endReason:Int, debugMessage:String) { nomangle }
		inst.OnConnectionStatusChanged(connection, listenSocket, remoteSteamID, oldState, state, endReason, debugMessage)
	End Function
End Type

Const STEAM_NETWORKING_PING_FAILED:Int = -1
Const STEAM_NETWORKING_PING_UNKNOWN:Int = -2

Rem
bbdoc: Receives changes in Steam Datagram Relay availability and ping measurement.
End Rem
Interface ISteamNetworkingUtilsListener
	Method OnSteamRelayNetworkStatusChanged(availability:ESteamNetworkingAvailability, pingMeasurementInProgress:Int, networkConfig:ESteamNetworkingAvailability, anyRelay:ESteamNetworkingAvailability, debugMessage:String)
End Interface

Rem
bbdoc: Relay readiness, network-location estimates, data-center pings, and Networking Sockets configuration.
about: Ping locations are represented as opaque strings because Steam's native
location structure is process-local and must not be persisted or sent over the
wire directly. Configuration scope objects are native connection, listen
socket, or interface handles as required by the selected configuration value.
End Rem
Type TSteamNetworkingUtils Extends TSteamAPI
	Const STEAMNETWORKINGUTILS_INTERFACE_VERSION:String = "SteamNetworkingUtils004"

	Field listener:ISteamNetworkingUtilsListener
	Field gameServer:Int

	Function Create:TSteamNetworkingUtils(gameServer:Int = False)
		Local native:Byte Ptr = bmx_SteamAPI_SteamNetworkingUtils()
		If Not native Then Return Null
		Local utils:TSteamNetworkingUtils = New TSteamNetworkingUtils
		utils.instancePtr = native
		utils.gameServer = gameServer
		utils.callbackPtr = bmx_steamsdk_register_networkingutils(native, utils, gameServer)
		Return utils
	End Function

	Method Delete()
		If callbackPtr Then bmx_steamsdk_unregister_networkingutils(callbackPtr)
		callbackPtr = Null
	End Method

	Method SetListener(listener:ISteamNetworkingUtilsListener)
		Self.listener = listener
	End Method

	Rem
	bbdoc: Dispatches the callback queue appropriate to this client or game-server interface.
	End Rem
	Method RunCallbacks()
		If gameServer Then
			SteamGameServerRunCallbacks()
		Else
			SteamRunCallbacks()
		End If
	End Method

	Rem
	bbdoc: Begins fetching relay configuration and measuring relay latency early.
	End Rem
	Method InitRelayNetworkAccess()
		bmx_SteamAPI_ISteamNetworkingUtils_InitRelayNetworkAccess(instancePtr)
	End Method

	Rem
	bbdoc: Returns current relay availability and fills its diagnostic details.
	End Rem
	Method GetRelayNetworkStatus:ESteamNetworkingAvailability(pingMeasurementInProgress:Int Var, networkConfig:ESteamNetworkingAvailability Var, anyRelay:ESteamNetworkingAvailability Var, debugMessage:String Var)
		Return bmx_SteamAPI_ISteamNetworkingUtils_GetRelayNetworkStatus(instancePtr, pingMeasurementInProgress, networkConfig, anyRelay, debugMessage)
	End Method

	Rem
	bbdoc: Returns the age in seconds of the local ping location, or a negative value when unavailable.
	End Rem
	Method GetLocalPingLocation:Float(location:String Var)
		Return bmx_SteamAPI_ISteamNetworkingUtils_GetLocalPingLocation(instancePtr, location)
	End Method

	Method EstimatePingTimeBetweenLocations:Int(first:String, second:String)
		Return bmx_SteamAPI_ISteamNetworkingUtils_EstimatePingTimeBetweenLocations(instancePtr, first, second)
	End Method

	Method EstimatePingTimeFromLocalHost:Int(remote:String)
		Return bmx_SteamAPI_ISteamNetworkingUtils_EstimatePingTimeFromLocalHost(instancePtr, remote)
	End Method

	Method CheckPingDataUpToDate:Int(maxAgeSeconds:Float)
		Return bmx_SteamAPI_ISteamNetworkingUtils_CheckPingDataUpToDate(instancePtr, maxAgeSeconds)
	End Method

	Method GetPingToDataCenter:Int(popID:UInt, viaRelayPOP:UInt Var)
		Return bmx_SteamAPI_ISteamNetworkingUtils_GetPingToDataCenter(instancePtr, popID, viaRelayPOP)
	End Method

	Method GetDirectPingToPOP:Int(popID:UInt)
		Return bmx_SteamAPI_ISteamNetworkingUtils_GetDirectPingToPOP(instancePtr, popID)
	End Method

	Method GetPOPCount:Int()
		Return bmx_SteamAPI_ISteamNetworkingUtils_GetPOPCount(instancePtr)
	End Method

	Method GetPOPList:Int(popIDs:UInt Ptr, capacity:Int)
		Return bmx_SteamAPI_ISteamNetworkingUtils_GetPOPList(instancePtr, popIDs, capacity)
	End Method

	Method GetLocalTimestamp:Long()
		Return bmx_SteamAPI_ISteamNetworkingUtils_GetLocalTimestamp(instancePtr)
	End Method

	Method SetConfigInt32:Int(value:ESteamNetworkingConfigValue, scope:ESteamNetworkingConfigScope, scopeObject:Long, data:Int)
		Return bmx_SteamAPI_ISteamNetworkingUtils_SetConfigInt32(instancePtr, value, scope, scopeObject, data)
	End Method

	Method SetConfigInt64:Int(value:ESteamNetworkingConfigValue, scope:ESteamNetworkingConfigScope, scopeObject:Long, data:Long)
		Return bmx_SteamAPI_ISteamNetworkingUtils_SetConfigInt64(instancePtr, value, scope, scopeObject, data)
	End Method

	Method SetConfigFloat:Int(value:ESteamNetworkingConfigValue, scope:ESteamNetworkingConfigScope, scopeObject:Long, data:Float)
		Return bmx_SteamAPI_ISteamNetworkingUtils_SetConfigFloat(instancePtr, value, scope, scopeObject, data)
	End Method

	Method SetConfigString:Int(value:ESteamNetworkingConfigValue, scope:ESteamNetworkingConfigScope, scopeObject:Long, data:String)
		Return bmx_SteamAPI_ISteamNetworkingUtils_SetConfigString(instancePtr, value, scope, scopeObject, data)
	End Method

	Method ResetConfig:Int(value:ESteamNetworkingConfigValue, scope:ESteamNetworkingConfigScope, scopeObject:Long = 0)
		Return bmx_SteamAPI_ISteamNetworkingUtils_ResetConfig(instancePtr, value, scope, scopeObject)
	End Method

	Method GetConfigInt32:ESteamNetworkingGetConfigValueResult(value:ESteamNetworkingConfigValue, scope:ESteamNetworkingConfigScope, scopeObject:Long, data:Int Var)
		Return bmx_SteamAPI_ISteamNetworkingUtils_GetConfigInt32(instancePtr, value, scope, scopeObject, data)
	End Method

	Method GetConfigInt64:ESteamNetworkingGetConfigValueResult(value:ESteamNetworkingConfigValue, scope:ESteamNetworkingConfigScope, scopeObject:Long, data:Long Var)
		Return bmx_SteamAPI_ISteamNetworkingUtils_GetConfigInt64(instancePtr, value, scope, scopeObject, data)
	End Method

	Method GetConfigFloat:ESteamNetworkingGetConfigValueResult(value:ESteamNetworkingConfigValue, scope:ESteamNetworkingConfigScope, scopeObject:Long, data:Float Var)
		Return bmx_SteamAPI_ISteamNetworkingUtils_GetConfigFloat(instancePtr, value, scope, scopeObject, data)
	End Method

	Method GetConfigString:ESteamNetworkingGetConfigValueResult(value:ESteamNetworkingConfigValue, scope:ESteamNetworkingConfigScope, scopeObject:Long, data:String Var)
		Return bmx_SteamAPI_ISteamNetworkingUtils_GetConfigString(instancePtr, value, scope, scopeObject, data)
	End Method

	Method GetConfigValueInfo:Int(value:ESteamNetworkingConfigValue, name:String Var, dataType:ESteamNetworkingConfigDataType Var, scope:ESteamNetworkingConfigScope Var)
		Return bmx_SteamAPI_ISteamNetworkingUtils_GetConfigValueInfo(instancePtr, value, name, dataType, scope)
	End Method

	Method IterateGenericEditableConfigValues:ESteamNetworkingConfigValue(current:ESteamNetworkingConfigValue = ESteamNetworkingConfigValue.k_ESteamNetworkingConfig_Invalid, enumerateDevVars:Int = False)
		Return bmx_SteamAPI_ISteamNetworkingUtils_IterateGenericEditableConfigValues(instancePtr, current, enumerateDevVars)
	End Method

	Private
	Method OnRelayNetworkStatusChanged(availability:ESteamNetworkingAvailability, pingMeasurementInProgress:Int, networkConfig:ESteamNetworkingAvailability, anyRelay:ESteamNetworkingAvailability, debugMessage:String)
		If listener Then listener.OnSteamRelayNetworkStatusChanged(availability, pingMeasurementInProgress, networkConfig, anyRelay, debugMessage)
	End Method

	Function _OnRelayNetworkStatusChanged(inst:TSteamNetworkingUtils, availability:ESteamNetworkingAvailability, pingMeasurementInProgress:Int, networkConfig:ESteamNetworkingAvailability, anyRelay:ESteamNetworkingAvailability, debugMessage:String) { nomangle }
		inst.OnRelayNetworkStatusChanged(availability, pingMeasurementInProgress, networkConfig, anyRelay, debugMessage)
	End Function
End Type

Rem
bbdoc: Initializes the Steam game-server interfaces.
about: After success create #TSteamGameServer, set its advertised properties, and call #TSteamGameServer.LogOnAnonymous or #TSteamGameServer.LogOn. @ip is normally zero and the ports are host-order UDP ports.
End Rem
Function SteamGameServerInit:ESteamAPIInitResult(ip:UInt, gamePort:Int, queryPort:Int, serverMode:EServerMode, version:String, errorMessage:String Var)
	Return bmx_SteamGameServer_Init(ip, gamePort, queryPort, serverMode, version, errorMessage)
End Function

Rem
bbdoc: Dispatches pending Steam game-server callbacks.
End Rem
Function SteamGameServerRunCallbacks()
	bmx_SteamGameServer_RunCallbacks()
End Function

Rem
bbdoc: Shuts down the process-wide Steam game-server interfaces.
End Rem
Function SteamGameServerShutdown()
	bmx_SteamGameServer_Shutdown()
End Function

Rem
bbdoc: Receives Steam game-server service and player-authentication events.
End Rem
Interface ISteamGameServerListener
	Method OnSteamGameServerConnected()
	Method OnSteamGameServerConnectFailure(result:EResult, retrying:Int)
	Method OnSteamGameServerDisconnected(result:EResult)
	Method OnSteamGameServerValidateAuthTicket(steamID:ULong, response:EAuthSessionResponse, ownerSteamID:ULong)
End Interface

Rem
bbdoc: Advertises and authenticates a dedicated or listen server through Steam.
about: This interface does not run or allocate a machine. The application owns the server process and normally combines this type with a game-server #TSteamNetworkingSockets interface and a GameNet listening transport.
End Rem
Type TSteamGameServer Extends TSteamAPI
	Const STEAMGAMESERVER_INTERFACE_VERSION:String = "SteamGameServer015"

	Field listener:ISteamGameServerListener

	Function Create:TSteamGameServer()
		Local native:Byte Ptr = bmx_SteamAPI_SteamGameServer()
		If Not native Then Return Null
		Local server:TSteamGameServer = New TSteamGameServer
		server.instancePtr = native
		server.callbackPtr = bmx_steamsdk_register_gameserver(native, server)
		Return server
	End Function

	Method Delete()
		If callbackPtr Then bmx_steamsdk_unregister_gameserver(callbackPtr)
		callbackPtr = Null
	End Method

	Method SetListener(listener:ISteamGameServerListener)
		Self.listener = listener
	End Method

	Method SetProduct(product:String)
		bmx_SteamAPI_ISteamGameServer_SetProduct(instancePtr, product)
	End Method

	Method SetGameDescription(description:String)
		bmx_SteamAPI_ISteamGameServer_SetGameDescription(instancePtr, description)
	End Method

	Method SetModDir(modDir:String)
		bmx_SteamAPI_ISteamGameServer_SetModDir(instancePtr, modDir)
	End Method

	Method SetDedicatedServer(dedicated:Int = True)
		bmx_SteamAPI_ISteamGameServer_SetDedicatedServer(instancePtr, dedicated)
	End Method

	Rem
	bbdoc: Logs on using a game-server account token.
	End Rem
	Method LogOn(token:String)
		bmx_SteamAPI_ISteamGameServer_LogOn(instancePtr, token)
	End Method

	Rem
	bbdoc: Logs on anonymously when the application's Steam configuration permits it.
	End Rem
	Method LogOnAnonymous()
		bmx_SteamAPI_ISteamGameServer_LogOnAnonymous(instancePtr)
	End Method

	Method LogOff()
		bmx_SteamAPI_ISteamGameServer_LogOff(instancePtr)
	End Method

	Method IsLoggedOn:Int()
		Return bmx_SteamAPI_ISteamGameServer_BLoggedOn(instancePtr)
	End Method

	Method IsSecure:Int()
		Return bmx_SteamAPI_ISteamGameServer_BSecure(instancePtr)
	End Method

	Method SteamID:ULong()
		Return bmx_SteamAPI_ISteamGameServer_GetSteamID(instancePtr)
	End Method

	Method WasRestartRequested:Int()
		Return bmx_SteamAPI_ISteamGameServer_WasRestartRequested(instancePtr)
	End Method

	Method SetMaxPlayerCount(count:Int)
		bmx_SteamAPI_ISteamGameServer_SetMaxPlayerCount(instancePtr, count)
	End Method

	Method SetBotPlayerCount(count:Int)
		bmx_SteamAPI_ISteamGameServer_SetBotPlayerCount(instancePtr, count)
	End Method

	Method SetServerName(name:String)
		bmx_SteamAPI_ISteamGameServer_SetServerName(instancePtr, name)
	End Method

	Method SetMapName(name:String)
		bmx_SteamAPI_ISteamGameServer_SetMapName(instancePtr, name)
	End Method

	Method SetPasswordProtected(isProtected:Int)
		bmx_SteamAPI_ISteamGameServer_SetPasswordProtected(instancePtr, isProtected)
	End Method

	Method ClearAllKeyValues()
		bmx_SteamAPI_ISteamGameServer_ClearAllKeyValues(instancePtr)
	End Method

	Method SetKeyValue(key:String, value:String)
		bmx_SteamAPI_ISteamGameServer_SetKeyValue(instancePtr, key, value)
	End Method

	Method SetGameTags(tags:String)
		bmx_SteamAPI_ISteamGameServer_SetGameTags(instancePtr, tags)
	End Method

	Method SetGameData(data:String)
		bmx_SteamAPI_ISteamGameServer_SetGameData(instancePtr, data)
	End Method

	Method SetRegion(region:String)
		bmx_SteamAPI_ISteamGameServer_SetRegion(instancePtr, region)
	End Method

	Method SetAdvertiseServerActive(active:Int)
		bmx_SteamAPI_ISteamGameServer_SetAdvertiseServerActive(instancePtr, active)
	End Method

	Rem
	bbdoc: Begins validating a player's Steam authentication ticket.
	End Rem
	Method BeginAuthSession:EBeginAuthSessionResult(ticket:Byte Ptr, ticketSize:Int, steamID:ULong)
		Return bmx_SteamAPI_ISteamGameServer_BeginAuthSession(instancePtr, ticket, ticketSize, steamID)
	End Method

	Method EndAuthSession(steamID:ULong)
		bmx_SteamAPI_ISteamGameServer_EndAuthSession(instancePtr, steamID)
	End Method

	Method UserHasLicenseForApp:EUserHasLicenseForAppResult(steamID:ULong, appID:UInt)
		Return bmx_SteamAPI_ISteamGameServer_UserHasLicenseForApp(instancePtr, steamID, appID)
	End Method

	Private
	Method OnSteamServersConnected()
		If listener Then listener.OnSteamGameServerConnected()
	End Method

	Method OnSteamServerConnectFailure(result:EResult, retrying:Int)
		If listener Then listener.OnSteamGameServerConnectFailure(result, retrying)
	End Method

	Method OnSteamServersDisconnected(result:EResult)
		If listener Then listener.OnSteamGameServerDisconnected(result)
	End Method

	Method OnValidateAuthTicket(steamID:ULong, response:EAuthSessionResponse, ownerSteamID:ULong)
		If listener Then listener.OnSteamGameServerValidateAuthTicket(steamID, response, ownerSteamID)
	End Method

	Function _OnSteamServersConnected(inst:TSteamGameServer) { nomangle }
		inst.OnSteamServersConnected()
	End Function

	Function _OnSteamServerConnectFailure(inst:TSteamGameServer, result:EResult, retrying:Int) { nomangle }
		inst.OnSteamServerConnectFailure(result, retrying)
	End Function

	Function _OnSteamServersDisconnected(inst:TSteamGameServer, result:EResult) { nomangle }
		inst.OnSteamServersDisconnected(result)
	End Function

	Function _OnValidateAuthTicket(inst:TSteamGameServer, steamID:ULong, response:EAuthSessionResponse, ownerSteamID:ULong) { nomangle }
		inst.OnValidateAuthTicket(steamID, response, ownerSteamID)
	End Function
End Type

Const STEAM_INPUT_MAX_COUNT:Int = 16
Const STEAM_INPUT_MAX_ORIGINS:Int = 8
Const STEAM_INPUT_MAX_ACTIVE_LAYERS:Int = 16
Const STEAM_INPUT_HANDLE_ALL_CONTROLLERS:ULong = $ffffffffffffffff:ULong
Const STEAM_INPUT_MIN_ANALOG_ACTION_DATA:Float = -1.0
Const STEAM_INPUT_MAX_ANALOG_ACTION_DATA:Float = 1.0

Rem
bbdoc: Current state of a Steam Input digital action.
End Rem
Struct SSteamInputDigitalActionData
	Field state:Int
	Field active:Int
End Struct

Rem
bbdoc: Current state of a Steam Input analog action.
End Rem
Struct SSteamInputAnalogActionData
	Field mode:EInputSourceMode
	Field x:Float
	Field y:Float
	Field active:Int
End Struct

Rem
bbdoc: Sensor-fused rotation, acceleration, and angular velocity reported by a Steam Input device.
End Rem
Struct SSteamInputMotionData
	Field rotQuatX:Float
	Field rotQuatY:Float
	Field rotQuatZ:Float
	Field rotQuatW:Float
	Field posAccelX:Float
	Field posAccelY:Float
	Field posAccelZ:Float
	Field rotVelX:Float
	Field rotVelY:Float
	Field rotVelZ:Float
End Struct

Rem
bbdoc: Receives Steam Input device and configuration notifications.
End Rem
Interface ISteamInputListener
	Method OnSteamInputDeviceConnected(inputHandle:ULong)
	Method OnSteamInputDeviceDisconnected(inputHandle:ULong)
	Method OnSteamInputConfigurationLoaded(appID:UInt, inputHandle:ULong, mappingCreator:ULong, majorRevision:UInt, minorRevision:UInt, usesSteamInputAPI:Int, usesGamepadAPI:Int)
End Interface

Rem
bbdoc: Optional listener extension for low-latency Steam Input action events.
about: Implement this in addition to #ISteamInputListener and call #TSteamInput.EnableActionEventCallbacks.
End Rem
Interface ISteamInputActionListener
	Method OnSteamInputDigitalAction(inputHandle:ULong, actionHandle:ULong, data:SSteamInputDigitalActionData)
	Method OnSteamInputAnalogAction(inputHandle:ULong, actionHandle:ULong, data:SSteamInputAnalogActionData)
End Interface

Rem
bbdoc: Provides action-based controller input through Steam Input.
about: Call #Init before reading devices and #Shutdown when finished. Games normally define action sets and actions in a Steam Input action manifest, cache their handles at startup, then read action data each frame. The data structures are unmanaged values and can be reused without per-frame allocation.
End Rem
Type TSteamInput Extends TSteamAPI
	Const STEAMINPUT_INTERFACE_VERSION:String = "SteamInput007"

	Field listener:ISteamInputListener

	Function _create:TSteamInput(instancePtr:Byte Ptr)
		If Not instancePtr Then Return Null
		Local this:TSteamInput = New TSteamInput
		this.instancePtr = instancePtr
		this.callbackPtr = bmx_steamsdk_register_steaminput(instancePtr, this)
		Return this
	End Function

	Method Delete()
		If callbackPtr Then bmx_steamsdk_unregister_steaminput(callbackPtr)
		callbackPtr = Null
	End Method

	Rem
	bbdoc: Sets the listener that receives device, configuration, and optional action notifications.
	End Rem
	Method SetListener(listener:ISteamInputListener)
		Self.listener = listener
	End Method

	Rem
	bbdoc: Initializes Steam Input.
	about: Set @explicitlyCallRunFrame when the game will call #RunFrame itself. Otherwise Steam updates input while callbacks are processed.
	End Rem
	Method Init:Int(explicitlyCallRunFrame:Int = False)
		Return bmx_SteamAPI_ISteamInput_Init(instancePtr, explicitlyCallRunFrame)
	End Method

	Rem
	bbdoc: Shuts down Steam Input after the game has finished using it.
	End Rem
	Method Shutdown:Int()
		Return bmx_SteamAPI_ISteamInput_Shutdown(instancePtr)
	End Method

	Rem
	bbdoc: Selects an absolute path to the game's Steam Input action manifest.
	about: Call this before #Init when shipping the manifest inside the game depot.
	End Rem
	Method SetInputActionManifestFilePath:Int(path:String)
		Return bmx_SteamAPI_ISteamInput_SetInputActionManifestFilePath(instancePtr, path)
	End Method

	Rem
	bbdoc: Refreshes Steam Input state immediately before the game reads action data.
	End Rem
	Method RunFrame()
		bmx_SteamAPI_ISteamInput_RunFrame(instancePtr)
	End Method

	Rem
	bbdoc: Waits for new controller data, optionally until data arrives.
	about: This is intended for a dedicated input thread. @timeout is measured in milliseconds.
	End Rem
	Method WaitForData:Int(waitForever:Int, timeout:UInt = 0)
		Return bmx_SteamAPI_ISteamInput_BWaitForData(instancePtr, waitForever, timeout)
	End Method

	Rem
	bbdoc: Returns #True when new data has arrived since action data was last read.
	End Rem
	Method NewDataAvailable:Int()
		Return bmx_SteamAPI_ISteamInput_BNewDataAvailable(instancePtr)
	End Method

	Rem
	bbdoc: Copies connected device handles into @handles and returns the number copied.
	about: Steam supports at most #STEAM_INPUT_MAX_COUNT connected handles. Call #RunFrame or process Steam callbacks before enumeration.
	End Rem
	Method GetConnectedControllers:Int(handles:ULong Ptr, capacity:Int)
		If Not handles Or capacity <= 0 Then Return 0
		Return bmx_SteamAPI_ISteamInput_GetConnectedControllers(instancePtr, handles, Min(capacity, STEAM_INPUT_MAX_COUNT))
	End Method

	Rem
	bbdoc: Enables connected and disconnected device notifications for this process.
	End Rem
	Method EnableDeviceCallbacks()
		bmx_SteamAPI_ISteamInput_EnableDeviceCallbacks(instancePtr)
	End Method

	Rem
	bbdoc: Enables low-latency action notifications for the current listener.
	about: Steam supports one action-event callback for the process. Polling with #GetDigitalActionData and #GetAnalogActionData remains available.
	End Rem
	Method EnableActionEventCallbacks()
		bmx_SteamAPI_ISteamInput_EnableActionEventCallbacks(callbackPtr)
	End Method

	Rem
	bbdoc: Returns the cached handle for a named action set, or 0 when not found.
	End Rem
	Method GetActionSetHandle:ULong(name:String)
		Return bmx_SteamAPI_ISteamInput_GetActionSetHandle(instancePtr, name)
	End Method

	Rem
	bbdoc: Activates an action set for one controller or #STEAM_INPUT_HANDLE_ALL_CONTROLLERS.
	End Rem
	Method ActivateActionSet(inputHandle:ULong, actionSetHandle:ULong)
		bmx_SteamAPI_ISteamInput_ActivateActionSet(instancePtr, inputHandle, actionSetHandle)
	End Method

	Rem
	bbdoc: Returns the controller's currently active action set.
	End Rem
	Method GetCurrentActionSet:ULong(inputHandle:ULong)
		Return bmx_SteamAPI_ISteamInput_GetCurrentActionSet(instancePtr, inputHandle)
	End Method

	Rem
	bbdoc: Activates an action-set layer for a controller.
	End Rem
	Method ActivateActionSetLayer(inputHandle:ULong, actionSetLayerHandle:ULong)
		bmx_SteamAPI_ISteamInput_ActivateActionSetLayer(instancePtr, inputHandle, actionSetLayerHandle)
	End Method

	Rem
	bbdoc: Deactivates one action-set layer for a controller.
	End Rem
	Method DeactivateActionSetLayer(inputHandle:ULong, actionSetLayerHandle:ULong)
		bmx_SteamAPI_ISteamInput_DeactivateActionSetLayer(instancePtr, inputHandle, actionSetLayerHandle)
	End Method

	Rem
	bbdoc: Deactivates all action-set layers for a controller.
	End Rem
	Method DeactivateAllActionSetLayers(inputHandle:ULong)
		bmx_SteamAPI_ISteamInput_DeactivateAllActionSetLayers(instancePtr, inputHandle)
	End Method

	Rem
	bbdoc: Copies active action-set layer handles into @handles and returns the number copied.
	End Rem
	Method GetActiveActionSetLayers:Int(inputHandle:ULong, handles:ULong Ptr, capacity:Int)
		If Not handles Or capacity <= 0 Then Return 0
		Return bmx_SteamAPI_ISteamInput_GetActiveActionSetLayers(instancePtr, inputHandle, handles, Min(capacity, STEAM_INPUT_MAX_ACTIVE_LAYERS))
	End Method

	Rem
	bbdoc: Returns the cached handle for a named digital action, or 0 when not found.
	End Rem
	Method GetDigitalActionHandle:ULong(name:String)
		Return bmx_SteamAPI_ISteamInput_GetDigitalActionHandle(instancePtr, name)
	End Method

	Rem
	bbdoc: Writes the current state of a digital action into @data.
	End Rem
	Method GetDigitalActionData(inputHandle:ULong, actionHandle:ULong, data:SSteamInputDigitalActionData Var)
		bmx_SteamAPI_ISteamInput_GetDigitalActionData(instancePtr, inputHandle, actionHandle, data.state, data.active)
	End Method

	Rem
	bbdoc: Copies the physical origins currently bound to a digital action and returns the number copied.
	End Rem
	Method GetDigitalActionOrigins:Int(inputHandle:ULong, actionSetHandle:ULong, actionHandle:ULong, origins:Int Ptr, capacity:Int)
		If Not origins Or capacity <= 0 Then Return 0
		Return bmx_SteamAPI_ISteamInput_GetDigitalActionOrigins(instancePtr, inputHandle, actionSetHandle, actionHandle, origins, Min(capacity, STEAM_INPUT_MAX_ORIGINS))
	End Method

	Rem
	bbdoc: Returns the localized display name of a digital action.
	End Rem
	Method GetStringForDigitalActionName:String(actionHandle:ULong)
		Return bmx_SteamAPI_ISteamInput_GetStringForDigitalActionName(instancePtr, actionHandle)
	End Method

	Rem
	bbdoc: Returns the cached handle for a named analog action, or 0 when not found.
	End Rem
	Method GetAnalogActionHandle:ULong(name:String)
		Return bmx_SteamAPI_ISteamInput_GetAnalogActionHandle(instancePtr, name)
	End Method

	Rem
	bbdoc: Writes the current state of an analog action into @data.
	End Rem
	Method GetAnalogActionData(inputHandle:ULong, actionHandle:ULong, data:SSteamInputAnalogActionData Var)
		bmx_SteamAPI_ISteamInput_GetAnalogActionData(instancePtr, inputHandle, actionHandle, data.mode, data.x, data.y, data.active)
	End Method

	Rem
	bbdoc: Copies the physical origins currently bound to an analog action and returns the number copied.
	End Rem
	Method GetAnalogActionOrigins:Int(inputHandle:ULong, actionSetHandle:ULong, actionHandle:ULong, origins:Int Ptr, capacity:Int)
		If Not origins Or capacity <= 0 Then Return 0
		Return bmx_SteamAPI_ISteamInput_GetAnalogActionOrigins(instancePtr, inputHandle, actionSetHandle, actionHandle, origins, Min(capacity, STEAM_INPUT_MAX_ORIGINS))
	End Method

	Rem
	bbdoc: Returns a local PNG glyph path for an action origin.
	End Rem
	Method GetGlyphPNGForActionOrigin:String(origin:EInputActionOrigin, size:ESteamInputGlyphSize = ESteamInputGlyphSize.k_ESteamInputGlyphSize_Medium, flags:ESteamInputGlyphStyle = ESteamInputGlyphStyle.ESteamInputGlyphStyle_Knockout)
		Return bmx_SteamAPI_ISteamInput_GetGlyphPNGForActionOrigin(instancePtr, origin, size, flags)
	End Method

	Rem
	bbdoc: Returns a local SVG glyph path for an action origin.
	End Rem
	Method GetGlyphSVGForActionOrigin:String(origin:EInputActionOrigin, flags:ESteamInputGlyphStyle = ESteamInputGlyphStyle.ESteamInputGlyphStyle_Knockout)
		Return bmx_SteamAPI_ISteamInput_GetGlyphSVGForActionOrigin(instancePtr, origin, flags)
	End Method

	Rem
	bbdoc: Returns the localized display name for an action origin.
	End Rem
	Method GetStringForActionOrigin:String(origin:EInputActionOrigin)
		Return bmx_SteamAPI_ISteamInput_GetStringForActionOrigin(instancePtr, origin)
	End Method

	Rem
	bbdoc: Returns the localized display name of an analog action.
	End Rem
	Method GetStringForAnalogActionName:String(actionHandle:ULong)
		Return bmx_SteamAPI_ISteamInput_GetStringForAnalogActionName(instancePtr, actionHandle)
	End Method

	Rem
	bbdoc: Stops trackball-style momentum for an analog action.
	End Rem
	Method StopAnalogActionMomentum(inputHandle:ULong, actionHandle:ULong)
		bmx_SteamAPI_ISteamInput_StopAnalogActionMomentum(instancePtr, inputHandle, actionHandle)
	End Method

	Rem
	bbdoc: Writes the controller's current motion sensor data into @data.
	End Rem
	Method GetMotionData(inputHandle:ULong, data:SSteamInputMotionData Var)
		bmx_SteamAPI_ISteamInput_GetMotionData(instancePtr, inputHandle, data.rotQuatX, data.rotQuatY, data.rotQuatZ, data.rotQuatW, data.posAccelX, data.posAccelY, data.posAccelZ, data.rotVelX, data.rotVelY, data.rotVelZ)
	End Method

	Rem
	bbdoc: Sets left and right vibration motor speeds in the range 0 through 65535.
	End Rem
	Method TriggerVibration(inputHandle:ULong, leftSpeed:Int, rightSpeed:Int)
		bmx_SteamAPI_ISteamInput_TriggerVibration(instancePtr, inputHandle, Max(0, Min(65535, leftSpeed)), Max(0, Min(65535, rightSpeed)))
	End Method

	Rem
	bbdoc: Sets main and trigger vibration motor speeds in the range 0 through 65535.
	End Rem
	Method TriggerVibrationExtended(inputHandle:ULong, leftSpeed:Int, rightSpeed:Int, leftTriggerSpeed:Int, rightTriggerSpeed:Int)
		bmx_SteamAPI_ISteamInput_TriggerVibrationExtended(instancePtr, inputHandle, Max(0, Min(65535, leftSpeed)), Max(0, Min(65535, rightSpeed)), Max(0, Min(65535, leftTriggerSpeed)), Max(0, Min(65535, rightTriggerSpeed)))
	End Method

	Rem
	bbdoc: Sends a simple haptic event to Steam Deck or Steam Controller hardware.
	End Rem
	Method TriggerSimpleHapticEvent(inputHandle:ULong, location:EControllerHapticLocation, intensity:Int, gainDB:Int, otherIntensity:Int = 0, otherGainDB:Int = 0)
		bmx_SteamAPI_ISteamInput_TriggerSimpleHapticEvent(instancePtr, inputHandle, location, Max(0, Min(255, intensity)), Max(-128, Min(127, gainDB)), Max(0, Min(255, otherIntensity)), Max(-128, Min(127, otherGainDB)))
	End Method

	Rem
	bbdoc: Sets or restores the LED colour on supported controllers.
	End Rem
	Method SetLEDColor(inputHandle:ULong, red:Int, green:Int, blue:Int, flags:ESteamInputLEDFlag = ESteamInputLEDFlag.k_ESteamInputLEDFlag_SetColor)
		bmx_SteamAPI_ISteamInput_SetLEDColor(instancePtr, inputHandle, Max(0, Min(255, red)), Max(0, Min(255, green)), Max(0, Min(255, blue)), flags)
	End Method

	Rem
	bbdoc: Opens Steam's binding panel for the controller.
	End Rem
	Method ShowBindingPanel:Int(inputHandle:ULong)
		Return bmx_SteamAPI_ISteamInput_ShowBindingPanel(instancePtr, inputHandle)
	End Method

	Rem
	bbdoc: Returns the stable device category for a controller handle.
	End Rem
	Method GetInputTypeForHandle:ESteamInputType(inputHandle:ULong)
		Return bmx_SteamAPI_ISteamInput_GetInputTypeForHandle(instancePtr, inputHandle)
	End Method

	Rem
	bbdoc: Returns the Steam Input handle associated with an emulated gamepad index, or 0.
	End Rem
	Method GetControllerForGamepadIndex:ULong(index:Int)
		Return bmx_SteamAPI_ISteamInput_GetControllerForGamepadIndex(instancePtr, index)
	End Method

	Rem
	bbdoc: Returns the emulated gamepad index associated with a controller, or -1.
	End Rem
	Method GetGamepadIndexForController:Int(inputHandle:ULong)
		Return bmx_SteamAPI_ISteamInput_GetGamepadIndexForController(instancePtr, inputHandle)
	End Method

	Rem
	bbdoc: Returns Steam's localized name for a conventional Xbox origin.
	End Rem
	Method GetStringForXboxOrigin:String(origin:EXboxOrigin)
		Return bmx_SteamAPI_ISteamInput_GetStringForXboxOrigin(instancePtr, origin)
	End Method

	Rem
	bbdoc: Returns a local glyph path for a conventional Xbox origin.
	End Rem
	Method GetGlyphForXboxOrigin:String(origin:EXboxOrigin)
		Return bmx_SteamAPI_ISteamInput_GetGlyphForXboxOrigin(instancePtr, origin)
	End Method

	Rem
	bbdoc: Maps a conventional Xbox origin to the equivalent origin for a controller.
	End Rem
	Method GetActionOriginFromXboxOrigin:EInputActionOrigin(inputHandle:ULong, origin:EXboxOrigin)
		Return bmx_SteamAPI_ISteamInput_GetActionOriginFromXboxOrigin(instancePtr, inputHandle, origin)
	End Method

	Rem
	bbdoc: Translates an action origin to its equivalent on another controller type.
	End Rem
	Method TranslateActionOrigin:EInputActionOrigin(destinationType:ESteamInputType, sourceOrigin:EInputActionOrigin)
		Return bmx_SteamAPI_ISteamInput_TranslateActionOrigin(instancePtr, destinationType, sourceOrigin)
	End Method

	Rem
	bbdoc: Returns the major and minor binding revisions loaded for a controller.
	End Rem
	Method GetDeviceBindingRevision:Int(inputHandle:ULong, major:Int Var, minor:Int Var)
		Return bmx_SteamAPI_ISteamInput_GetDeviceBindingRevision(instancePtr, inputHandle, major, minor)
	End Method

	Rem
	bbdoc: Returns the Remote Play session that supplies a controller, or 0 for a local controller.
	End Rem
	Method GetRemotePlaySessionID:UInt(inputHandle:ULong)
		Return bmx_SteamAPI_ISteamInput_GetRemotePlaySessionID(instancePtr, inputHandle)
	End Method

	Rem
	bbdoc: Returns a bitmask of #ESteamInputConfigurationEnableType values enabled for this session.
	End Rem
	Method GetSessionInputConfigurationSettings:ESteamInputConfigurationEnableType()
		Return bmx_SteamAPI_ISteamInput_GetSessionInputConfigurationSettings(instancePtr)
	End Method

	Rem
	bbdoc: Stops the adaptive-trigger effect on one or both DualSense triggers.
	End Rem
	Method SetDualSenseTriggerOff:Int(inputHandle:ULong, trigger:EDualSenseTrigger)
		Return bmx_SteamAPI_ISteamInput_SetDualSenseTriggerEffect(instancePtr, inputHandle, trigger, EDualSenseTriggerEffectMode.k_EDualSenseTriggerEffectMode_Off, 0, 0, 0, 0, Null, 0)
	End Method

	Rem
	bbdoc: Applies constant resistance to one or both DualSense triggers.
	about: @position is 0 through 9 and @strength is 0 through 8.
	End Rem
	Method SetDualSenseTriggerFeedback:Int(inputHandle:ULong, trigger:EDualSenseTrigger, position:Int, strength:Int)
		Return bmx_SteamAPI_ISteamInput_SetDualSenseTriggerEffect(instancePtr, inputHandle, trigger, EDualSenseTriggerEffectMode.k_EDualSenseTriggerEffectMode_Feedback, position, strength, 0, 0, Null, 0)
	End Method

	Rem
	bbdoc: Configures one or both DualSense triggers to emulate a weapon trigger.
	about: @startPosition is 2 through 7, @endPosition is greater than @startPosition and at most 8, and @strength is 0 through 8.
	End Rem
	Method SetDualSenseTriggerWeapon:Int(inputHandle:ULong, trigger:EDualSenseTrigger, startPosition:Int, endPosition:Int, strength:Int)
		Return bmx_SteamAPI_ISteamInput_SetDualSenseTriggerEffect(instancePtr, inputHandle, trigger, EDualSenseTriggerEffectMode.k_EDualSenseTriggerEffectMode_Weapon, startPosition, endPosition, strength, 0, Null, 0)
	End Method

	Rem
	bbdoc: Vibrates one or both DualSense triggers from a control position.
	about: @position is 0 through 9, @amplitude is 0 through 8, and @frequency is 0 through 255 Hz.
	End Rem
	Method SetDualSenseTriggerVibration:Int(inputHandle:ULong, trigger:EDualSenseTrigger, position:Int, amplitude:Int, frequency:Int)
		Return bmx_SteamAPI_ISteamInput_SetDualSenseTriggerEffect(instancePtr, inputHandle, trigger, EDualSenseTriggerEffectMode.k_EDualSenseTriggerEffectMode_Vibration, position, amplitude, frequency, 0, Null, 0)
	End Method

	Rem
	bbdoc: Sets resistance independently at the ten DualSense trigger control positions.
	about: @strengths must point to at least ten bytes, each containing a strength from 0 through 8.
	End Rem
	Method SetDualSenseTriggerMultiplePositionFeedback:Int(inputHandle:ULong, trigger:EDualSenseTrigger, strengths:Byte Ptr, count:Int = 10)
		Return bmx_SteamAPI_ISteamInput_SetDualSenseTriggerEffect(instancePtr, inputHandle, trigger, EDualSenseTriggerEffectMode.k_EDualSenseTriggerEffectMode_MultiplePositionFeedback, 0, 0, 0, 0, strengths, count)
	End Method

	Rem
	bbdoc: Applies a changing resistance between two DualSense trigger positions.
	about: Positions are 0 through 9 and strengths are 1 through 8.
	End Rem
	Method SetDualSenseTriggerSlopeFeedback:Int(inputHandle:ULong, trigger:EDualSenseTrigger, startPosition:Int, endPosition:Int, startStrength:Int, endStrength:Int)
		Return bmx_SteamAPI_ISteamInput_SetDualSenseTriggerEffect(instancePtr, inputHandle, trigger, EDualSenseTriggerEffectMode.k_EDualSenseTriggerEffectMode_SlopeFeedback, startPosition, endPosition, startStrength, endStrength, Null, 0)
	End Method

	Rem
	bbdoc: Sets vibration amplitude independently at the ten DualSense trigger control positions.
	about: @amplitudes must point to at least ten bytes containing values from 0 through 8. @frequency is 0 through 255 Hz.
	End Rem
	Method SetDualSenseTriggerMultiplePositionVibration:Int(inputHandle:ULong, trigger:EDualSenseTrigger, frequency:Int, amplitudes:Byte Ptr, count:Int = 10)
		Return bmx_SteamAPI_ISteamInput_SetDualSenseTriggerEffect(instancePtr, inputHandle, trigger, EDualSenseTriggerEffectMode.k_EDualSenseTriggerEffectMode_MultiplePositionVibration, frequency, 0, 0, 0, amplitudes, count)
	End Method

	Private
	Method OnDeviceConnected(inputHandle:ULong)
		If listener Then listener.OnSteamInputDeviceConnected(inputHandle)
	End Method

	Method OnDeviceDisconnected(inputHandle:ULong)
		If listener Then listener.OnSteamInputDeviceDisconnected(inputHandle)
	End Method

	Method OnConfigurationLoaded(appID:UInt, inputHandle:ULong, mappingCreator:ULong, majorRevision:UInt, minorRevision:UInt, usesSteamInputAPI:Int, usesGamepadAPI:Int)
		If listener Then listener.OnSteamInputConfigurationLoaded(appID, inputHandle, mappingCreator, majorRevision, minorRevision, usesSteamInputAPI, usesGamepadAPI)
	End Method

	Method OnDigitalAction(inputHandle:ULong, actionHandle:ULong, state:Int, active:Int)
		Local actionListener:ISteamInputActionListener = ISteamInputActionListener(listener)
		If actionListener Then
			Local data:SSteamInputDigitalActionData
			data.state = state
			data.active = active
			actionListener.OnSteamInputDigitalAction(inputHandle, actionHandle, data)
		End If
	End Method

	Method OnAnalogAction(inputHandle:ULong, actionHandle:ULong, mode:EInputSourceMode, x:Float, y:Float, active:Int)
		Local actionListener:ISteamInputActionListener = ISteamInputActionListener(listener)
		If actionListener Then
			Local data:SSteamInputAnalogActionData
			data.mode = mode
			data.x = x
			data.y = y
			data.active = active
			actionListener.OnSteamInputAnalogAction(inputHandle, actionHandle, data)
		End If
	End Method

	Function _OnDeviceConnected(inst:TSteamInput, inputHandle:ULong) { nomangle }
		inst.OnDeviceConnected(inputHandle)
	End Function

	Function _OnDeviceDisconnected(inst:TSteamInput, inputHandle:ULong) { nomangle }
		inst.OnDeviceDisconnected(inputHandle)
	End Function

	Function _OnConfigurationLoaded(inst:TSteamInput, appID:UInt, inputHandle:ULong, mappingCreator:ULong, majorRevision:UInt, minorRevision:UInt, usesSteamInputAPI:Int, usesGamepadAPI:Int) { nomangle }
		inst.OnConfigurationLoaded(appID, inputHandle, mappingCreator, majorRevision, minorRevision, usesSteamInputAPI, usesGamepadAPI)
	End Function

	Function _OnDigitalAction(inst:TSteamInput, inputHandle:ULong, actionHandle:ULong, state:Int, active:Int) { nomangle }
		inst.OnDigitalAction(inputHandle, actionHandle, state, active)
	End Function

	Function _OnAnalogAction(inst:TSteamInput, inputHandle:ULong, actionHandle:ULong, mode:EInputSourceMode, x:Float, y:Float, active:Int) { nomangle }
		inst.OnAnalogAction(inputHandle, actionHandle, mode, x, y, active)
	End Function
End Type

Const STEAM_TIMELINE_MAX_PRIORITY:UInt = 1000
Const STEAM_TIMELINE_KEEP_CURRENT_PRIORITY:UInt = 1000000
Const STEAM_TIMELINE_MAX_EVENT_DURATION:Float = 600.0

Rem
bbdoc: Receives asynchronous Steam Timeline recording queries.
End Rem
Interface ISteamTimelineListener
	Rem
	bbdoc: Reports whether a recording exists for a timeline event.
	End Rem
	Method OnTimelineEventRecordingExists(eventHandle:ULong, recordingExists:Int, ioFailure:Int)
	Rem
	bbdoc: Reports recording and clip information for a game phase.
	End Rem
	Method OnTimelineGamePhaseRecordingExists(phaseID:String, recordingMS:ULong, longestClipMS:ULong, clipCount:UInt, screenshotCount:UInt, ioFailure:Int)
End Interface

Rem
bbdoc: Adds game state, events, phases, and navigation to Steam Timeline.
about: Titles, descriptions, tags, and attributes should already be localized for the language returned by Steam. Timeline event handles are valid only for the current game process.
End Rem
Type TSteamTimeline Extends TSteamAPI
	Const STEAMTIMELINE_INTERFACE_VERSION:String = "STEAMTIMELINE_INTERFACE_V004"

	Field listener:ISteamTimelineListener

	Function _create:TSteamTimeline(instancePtr:Byte Ptr)
		If Not instancePtr Then Return Null
		Local this:TSteamTimeline = New TSteamTimeline
		this.instancePtr = instancePtr
		this.callbackPtr = bmx_steamsdk_register_steamtimeline(instancePtr, this)
		Return this
	End Function

	Method Delete()
		If callbackPtr Then bmx_steamsdk_unregister_steamtimeline(callbackPtr)
		callbackPtr = Null
	End Method

	Rem
	bbdoc: Sets the listener that receives recording-query results.
	End Rem
	Method SetListener(listener:ISteamTimelineListener)
		Self.listener = listener
	End Method

	Rem
	bbdoc: Describes the current game state at the supplied time offset.
	End Rem
	Method SetTimelineTooltip(description:String, timeDelta:Float = 0.0)
		bmx_SteamAPI_ISteamTimeline_SetTimelineTooltip(instancePtr, description, timeDelta)
	End Method

	Rem
	bbdoc: Clears the timeline tooltip at the supplied time offset.
	End Rem
	Method ClearTimelineTooltip(timeDelta:Float = 0.0)
		bmx_SteamAPI_ISteamTimeline_ClearTimelineTooltip(instancePtr, timeDelta)
	End Method

	Rem
	bbdoc: Selects the current game mode used to colour the timeline bar.
	End Rem
	Method SetTimelineGameMode(mode:ETimelineGameMode)
		bmx_SteamAPI_ISteamTimeline_SetTimelineGameMode(instancePtr, mode)
	End Method

	Rem
	bbdoc: Adds a point event and returns its process-local handle.
	End Rem
	Method AddInstantaneousTimelineEvent:ULong(title:String, description:String, icon:String, iconPriority:UInt, startOffsetSeconds:Float = 0.0, clipPriority:ETimelineEventClipPriority = ETimelineEventClipPriority.k_ETimelineEventClipPriority_None)
		Return bmx_SteamAPI_ISteamTimeline_AddInstantaneousTimelineEvent(instancePtr, title, description, icon, iconPriority, startOffsetSeconds, clipPriority)
	End Method

	Rem
	bbdoc: Adds a completed range event and returns its process-local handle.
	End Rem
	Method AddRangeTimelineEvent:ULong(title:String, description:String, icon:String, iconPriority:UInt, startOffsetSeconds:Float = 0.0, duration:Float = 0.0, clipPriority:ETimelineEventClipPriority = ETimelineEventClipPriority.k_ETimelineEventClipPriority_None)
		Return bmx_SteamAPI_ISteamTimeline_AddRangeTimelineEvent(instancePtr, title, description, icon, iconPriority, startOffsetSeconds, duration, clipPriority)
	End Method

	Rem
	bbdoc: Starts an open range event that must later be ended with #EndRangeTimelineEvent.
	End Rem
	Method StartRangeTimelineEvent:ULong(title:String, description:String, icon:String, priority:UInt, startOffsetSeconds:Float = 0.0, clipPriority:ETimelineEventClipPriority = ETimelineEventClipPriority.k_ETimelineEventClipPriority_None)
		Return bmx_SteamAPI_ISteamTimeline_StartRangeTimelineEvent(instancePtr, title, description, icon, priority, startOffsetSeconds, clipPriority)
	End Method

	Rem
	bbdoc: Updates an open range event.
	about: Use #STEAM_TIMELINE_KEEP_CURRENT_PRIORITY to retain its current priority.
	End Rem
	Method UpdateRangeTimelineEvent(eventHandle:ULong, title:String, description:String, icon:String, priority:UInt = STEAM_TIMELINE_KEEP_CURRENT_PRIORITY, clipPriority:ETimelineEventClipPriority = ETimelineEventClipPriority.k_ETimelineEventClipPriority_None)
		bmx_SteamAPI_ISteamTimeline_UpdateRangeTimelineEvent(instancePtr, eventHandle, title, description, icon, priority, clipPriority)
	End Method

	Rem
	bbdoc: Ends an open range event and makes it visible in Steam Timeline.
	End Rem
	Method EndRangeTimelineEvent(eventHandle:ULong, endOffsetSeconds:Float = 0.0)
		bmx_SteamAPI_ISteamTimeline_EndRangeTimelineEvent(instancePtr, eventHandle, endOffsetSeconds)
	End Method

	Rem
	bbdoc: Removes a timeline event created by this game process.
	End Rem
	Method RemoveTimelineEvent(eventHandle:ULong)
		bmx_SteamAPI_ISteamTimeline_RemoveTimelineEvent(instancePtr, eventHandle)
	End Method

	Rem
	bbdoc: Asynchronously asks whether a background recording contains this event.
	End Rem
	Method DoesEventRecordingExist:ULong(eventHandle:ULong)
		Return bmx_SteamAPI_ISteamTimeline_DoesEventRecordingExist(callbackPtr, eventHandle)
	End Method

	Rem
	bbdoc: Starts a new game phase, ending any current phase.
	End Rem
	Method StartGamePhase()
		bmx_SteamAPI_ISteamTimeline_StartGamePhase(instancePtr)
	End Method

	Rem
	bbdoc: Ends the current game phase.
	End Rem
	Method EndGamePhase()
		bmx_SteamAPI_ISteamTimeline_EndGamePhase(instancePtr)
	End Method

	Rem
	bbdoc: Assigns a persistent identifier to the current game phase.
	End Rem
	Method SetGamePhaseID(phaseID:String)
		bmx_SteamAPI_ISteamTimeline_SetGamePhaseID(instancePtr, phaseID)
	End Method

	Rem
	bbdoc: Asynchronously asks whether a background recording contains a phase.
	End Rem
	Method DoesGamePhaseRecordingExist:ULong(phaseID:String)
		Return bmx_SteamAPI_ISteamTimeline_DoesGamePhaseRecordingExist(callbackPtr, phaseID)
	End Method

	Rem
	bbdoc: Adds a localized tag to the current game phase.
	End Rem
	Method AddGamePhaseTag(tagName:String, tagIcon:String, tagGroup:String, priority:UInt)
		bmx_SteamAPI_ISteamTimeline_AddGamePhaseTag(instancePtr, tagName, tagIcon, tagGroup, priority)
	End Method

	Rem
	bbdoc: Sets or replaces a localized text attribute on the current game phase.
	End Rem
	Method SetGamePhaseAttribute(attributeGroup:String, attributeValue:String, priority:UInt)
		bmx_SteamAPI_ISteamTimeline_SetGamePhaseAttribute(instancePtr, attributeGroup, attributeValue, priority)
	End Method

	Rem
	bbdoc: Opens the Steam overlay at a previously identified game phase.
	End Rem
	Method OpenOverlayToGamePhase(phaseID:String)
		bmx_SteamAPI_ISteamTimeline_OpenOverlayToGamePhase(instancePtr, phaseID)
	End Method

	Rem
	bbdoc: Opens the Steam overlay at a timeline event.
	End Rem
	Method OpenOverlayToTimelineEvent(eventHandle:ULong)
		bmx_SteamAPI_ISteamTimeline_OpenOverlayToTimelineEvent(instancePtr, eventHandle)
	End Method

	Private
	Method OnEventRecordingExists(eventHandle:ULong, recordingExists:Int, ioFailure:Int)
		If listener Then listener.OnTimelineEventRecordingExists(eventHandle, recordingExists, ioFailure)
	End Method

	Method OnGamePhaseRecordingExists(phaseID:String, recordingMS:ULong, longestClipMS:ULong, clipCount:UInt, screenshotCount:UInt, ioFailure:Int)
		If listener Then listener.OnTimelineGamePhaseRecordingExists(phaseID, recordingMS, longestClipMS, clipCount, screenshotCount, ioFailure)
	End Method

	Function _OnEventRecordingExists(inst:TSteamTimeline, eventHandle:ULong, recordingExists:Int, ioFailure:Int) { nomangle }
		inst.OnEventRecordingExists(eventHandle, recordingExists, ioFailure)
	End Function

	Function _OnGamePhaseRecordingExists(inst:TSteamTimeline, phaseID:String, recordingMS:ULong, longestClipMS:ULong, clipCount:UInt, screenshotCount:UInt, ioFailure:Int) { nomangle }
		inst.OnGamePhaseRecordingExists(phaseID, recordingMS, longestClipMS, clipCount, screenshotCount, ioFailure)
	End Function
End Type

Const STEAM_REMOTE_STORAGE_MAX_CLOUD_FILE_CHUNK_SIZE:Int = 100 * 1024 * 1024

Rem
bbdoc: Receives notifications when Steam Cloud changes files during the current application session.
End Rem
Interface ISteamRemoteStorageListener
	Rem
	bbdoc: Called when an asynchronous file write completes.
	End Rem
	Method OnFileWriteAsyncComplete(callHandle:ULong, result:EResult, ioFailure:Int)
	Rem
	bbdoc: Called when an asynchronous file read is ready to be copied.
	about: When @result is k_EResultOK, call #TSteamRemoteStorage.FileReadAsyncComplete from this callback using @callHandle and @bytesRead.
	End Rem
	Method OnFileReadAsyncComplete(callHandle:ULong, result:EResult, offset:UInt, bytesRead:UInt, ioFailure:Int)
	Rem
	bbdoc: Called when one or more local files changed after Steam synchronized changes from another session.
	about: Use #TSteamRemoteStorage.GetLocalFileChangeCount and #TSteamRemoteStorage.GetLocalFileChange to inspect the changes.
	End Rem
	Method OnLocalFileChange()
End Interface

Rem
bbdoc: Provides direct access to files managed by Steam Cloud.
about: Filenames are case-insensitive and Steam normalizes them to lowercase.
Use #BeginFileWriteBatch and #EndFileWriteBatch when one logical save operation
updates more than one file. Workshop publishing is provided by #TSteamUGC rather
than the legacy Workshop methods on ISteamRemoteStorage.
End Rem
Type TSteamRemoteStorage Extends TSteamAPI
	Const STEAMREMOTESTORAGE_INTERFACE_VERSION:String = "STEAMREMOTESTORAGE_INTERFACE_VERSION016"

	Field listener:ISteamRemoteStorageListener

	Function _create:TSteamRemoteStorage(instancePtr:Byte Ptr)
		If Not instancePtr Then Return Null
		Local this:TSteamRemoteStorage = New TSteamRemoteStorage
		this.instancePtr = instancePtr
		this.callbackPtr = bmx_steamsdk_register_steamremotestorage(instancePtr, this)
		Return this
	End Function

	Method Delete()
		If callbackPtr Then bmx_steamsdk_unregister_steamremotestorage(callbackPtr)
		callbackPtr = Null
	End Method

	Rem
	bbdoc: Sets the listener that receives Steam Cloud file-change notifications.
	End Rem
	Method SetListener(listener:ISteamRemoteStorageListener)
		Self.listener = listener
	End Method

	Rem
	bbdoc: Writes @size bytes to a Steam Cloud file.
	returns: #True when the data was accepted, otherwise #False.
	about: A single write may not exceed #STEAM_REMOTE_STORAGE_MAX_CLOUD_FILE_CHUNK_SIZE. Use the stream methods for larger files.
	End Rem
	Method FileWrite:Int(file:String, data:Byte Ptr, size:Int)
		If size < 0 Or size > STEAM_REMOTE_STORAGE_MAX_CLOUD_FILE_CHUNK_SIZE Or (size > 0 And Not data) Then Return False
		Return bmx_SteamAPI_ISteamRemoteStorage_FileWrite(instancePtr, file, data, size)
	End Method

	Rem
	bbdoc: Reads up to @capacity bytes from a Steam Cloud file into @data.
	returns: The number of bytes read, or -1 when the operation failed.
	End Rem
	Method FileRead:Int(file:String, data:Byte Ptr, capacity:Int)
		If capacity < 0 Or (capacity > 0 And Not data) Then Return -1
		Return bmx_SteamAPI_ISteamRemoteStorage_FileRead(instancePtr, file, data, capacity)
	End Method

	Rem
	bbdoc: Starts an asynchronous write of @size bytes to a Steam Cloud file.
	returns: A call handle delivered to #ISteamRemoteStorageListener.OnFileWriteAsyncComplete, or 0 when the request could not start.
	about: The wrapper retains its own copy of the supplied data until Steam completes the operation, so the caller may reuse or release its buffer immediately.
	End Rem
	Method FileWriteAsync:ULong(file:String, data:Byte Ptr, size:UInt)
		If Not data Or size > UInt(STEAM_REMOTE_STORAGE_MAX_CLOUD_FILE_CHUNK_SIZE) Then Return 0
		Return bmx_SteamAPI_ISteamRemoteStorage_FileWriteAsync(callbackPtr, file, data, size)
	End Method

	Rem
	bbdoc: Starts an asynchronous read from @file.
	returns: A call handle delivered to #ISteamRemoteStorageListener.OnFileReadAsyncComplete, or 0 when the request could not start.
	about: Only one asynchronous read may be active for the same file. Use #FileReadAsyncComplete from the completion callback to copy the data.
	End Rem
	Method FileReadAsync:ULong(file:String, offset:UInt, bytesToRead:UInt)
		If bytesToRead = 0 Then Return 0
		Return bmx_SteamAPI_ISteamRemoteStorage_FileReadAsync(callbackPtr, file, offset, bytesToRead)
	End Method

	Rem
	bbdoc: Copies data produced by a completed asynchronous read into @data.
	about: Call this only from #ISteamRemoteStorageListener.OnFileReadAsyncComplete, using that callback's @callHandle and normally its @bytesRead value.
	End Rem
	Method FileReadAsyncComplete:Int(readCall:ULong, data:Byte Ptr, bytesToRead:UInt)
		If Not data Or bytesToRead = 0 Then Return False
		Return bmx_SteamAPI_ISteamRemoteStorage_FileReadAsyncComplete(instancePtr, readCall, data, bytesToRead)
	End Method

	Rem
	bbdoc: Stops synchronizing @file while retaining its local copy.
	End Rem
	Method FileForget:Int(file:String)
		Return bmx_SteamAPI_ISteamRemoteStorage_FileForget(instancePtr, file)
	End Method

	Rem
	bbdoc: Deletes @file from both the local cache and Steam Cloud.
	End Rem
	Method FileDelete:Int(file:String)
		Return bmx_SteamAPI_ISteamRemoteStorage_FileDelete(instancePtr, file)
	End Method

	Rem
	bbdoc: Selects the platforms on which @file should synchronize.
	End Rem
	Method SetSyncPlatforms:Int(file:String, platforms:ERemoteStoragePlatform)
		Return bmx_SteamAPI_ISteamRemoteStorage_SetSyncPlatforms(instancePtr, file, platforms)
	End Method

	Rem
	bbdoc: Opens a streamed write to @file.
	returns: A stream handle, or ULong(-1) when the stream could not be opened.
	End Rem
	Method FileWriteStreamOpen:ULong(file:String)
		Return bmx_SteamAPI_ISteamRemoteStorage_FileWriteStreamOpen(instancePtr, file)
	End Method

	Rem
	bbdoc: Appends one chunk to an open file-write stream.
	about: Each chunk must be no larger than #STEAM_REMOTE_STORAGE_MAX_CLOUD_FILE_CHUNK_SIZE.
	End Rem
	Method FileWriteStreamWriteChunk:Int(streamHandle:ULong, data:Byte Ptr, size:Int)
		If size < 0 Or size > STEAM_REMOTE_STORAGE_MAX_CLOUD_FILE_CHUNK_SIZE Or (size > 0 And Not data) Then Return False
		Return bmx_SteamAPI_ISteamRemoteStorage_FileWriteStreamWriteChunk(instancePtr, streamHandle, data, size)
	End Method

	Rem
	bbdoc: Commits and closes an open file-write stream.
	End Rem
	Method FileWriteStreamClose:Int(streamHandle:ULong)
		Return bmx_SteamAPI_ISteamRemoteStorage_FileWriteStreamClose(instancePtr, streamHandle)
	End Method

	Rem
	bbdoc: Cancels an open file-write stream without committing it.
	End Rem
	Method FileWriteStreamCancel:Int(streamHandle:ULong)
		Return bmx_SteamAPI_ISteamRemoteStorage_FileWriteStreamCancel(instancePtr, streamHandle)
	End Method

	Rem
	bbdoc: Returns #True when @file exists in the local Steam Cloud cache.
	End Rem
	Method FileExists:Int(file:String)
		Return bmx_SteamAPI_ISteamRemoteStorage_FileExists(instancePtr, file)
	End Method

	Rem
	bbdoc: Returns #True when @file is currently persisted in Steam Cloud.
	End Rem
	Method FilePersisted:Int(file:String)
		Return bmx_SteamAPI_ISteamRemoteStorage_FilePersisted(instancePtr, file)
	End Method

	Rem
	bbdoc: Returns the size of @file in bytes, or 0 when it does not exist.
	End Rem
	Method GetFileSize:Int(file:String)
		Return bmx_SteamAPI_ISteamRemoteStorage_GetFileSize(instancePtr, file)
	End Method

	Rem
	bbdoc: Returns the last modification time of @file as a Unix timestamp.
	End Rem
	Method GetFileTimestamp:Long(file:String)
		Return bmx_SteamAPI_ISteamRemoteStorage_GetFileTimestamp(instancePtr, file)
	End Method

	Rem
	bbdoc: Returns the platforms on which @file is configured to synchronize.
	End Rem
	Method GetSyncPlatforms:ERemoteStoragePlatform(file:String)
		Return bmx_SteamAPI_ISteamRemoteStorage_GetSyncPlatforms(instancePtr, file)
	End Method

	Rem
	bbdoc: Returns the number of files in the application's Steam Cloud cache.
	End Rem
	Method GetFileCount:Int()
		Return bmx_SteamAPI_ISteamRemoteStorage_GetFileCount(instancePtr)
	End Method

	Rem
	bbdoc: Returns a cached file's normalized name and writes its byte size to @size.
	End Rem
	Method GetFileNameAndSize:String(index:Int, size:Int Var)
		Return bmx_SteamAPI_ISteamRemoteStorage_GetFileNameAndSize(instancePtr, index, size)
	End Method

	Rem
	bbdoc: Returns the application's total and currently available Steam Cloud quota in bytes.
	End Rem
	Method GetQuota:Int(totalBytes:ULong Var, availableBytes:ULong Var)
		Return bmx_SteamAPI_ISteamRemoteStorage_GetQuota(instancePtr, totalBytes, availableBytes)
	End Method

	Rem
	bbdoc: Returns #True when Steam Cloud is enabled for the current account.
	End Rem
	Method IsCloudEnabledForAccount:Int()
		Return bmx_SteamAPI_ISteamRemoteStorage_IsCloudEnabledForAccount(instancePtr)
	End Method

	Rem
	bbdoc: Returns #True when the user has enabled Steam Cloud for this application.
	End Rem
	Method IsCloudEnabledForApp:Int()
		Return bmx_SteamAPI_ISteamRemoteStorage_IsCloudEnabledForApp(instancePtr)
	End Method

	Rem
	bbdoc: Enables or disables Steam Cloud for this application for the current user.
	End Rem
	Method SetCloudEnabledForApp(enabled:Int)
		bmx_SteamAPI_ISteamRemoteStorage_SetCloudEnabledForApp(instancePtr, enabled)
	End Method

	Rem
	bbdoc: Returns the number of pending local file-change records produced by cloud synchronization.
	End Rem
	Method GetLocalFileChangeCount:Int()
		Return bmx_SteamAPI_ISteamRemoteStorage_GetLocalFileChangeCount(instancePtr)
	End Method

	Rem
	bbdoc: Returns one changed path and its change and path types.
	about: Call this after #ISteamRemoteStorageListener.OnLocalFileChange. The path may be an API filename or an absolute Auto-Cloud path according to @pathType.
	End Rem
	Method GetLocalFileChange:String(index:Int, changeType:ERemoteStorageLocalFileChange Var, pathType:ERemoteStorageFilePathType Var)
		Return bmx_SteamAPI_ISteamRemoteStorage_GetLocalFileChange(instancePtr, index, changeType, pathType)
	End Method

	Rem
	bbdoc: Begins a logical batch of related file writes and deletions.
	about: Always balance a successful call with #EndFileWriteBatch.
	End Rem
	Method BeginFileWriteBatch:Int()
		Return bmx_SteamAPI_ISteamRemoteStorage_BeginFileWriteBatch(instancePtr)
	End Method

	Rem
	bbdoc: Ends a logical batch begun by #BeginFileWriteBatch.
	End Rem
	Method EndFileWriteBatch:Int()
		Return bmx_SteamAPI_ISteamRemoteStorage_EndFileWriteBatch(instancePtr)
	End Method

	Method OnLocalFileChange()
		If listener Then listener.OnLocalFileChange()
	End Method

	Method OnFileWriteAsyncComplete(callHandle:ULong, result:EResult, ioFailure:Int)
		If listener Then listener.OnFileWriteAsyncComplete(callHandle, result, ioFailure)
	End Method

	Method OnFileReadAsyncComplete(callHandle:ULong, result:EResult, offset:UInt, bytesRead:UInt, ioFailure:Int)
		If listener Then listener.OnFileReadAsyncComplete(callHandle, result, offset, bytesRead, ioFailure)
	End Method

	Function _OnLocalFileChange(inst:TSteamRemoteStorage) { nomangle }
		inst.OnLocalFileChange()
	End Function

	Function _OnFileWriteAsyncComplete(inst:TSteamRemoteStorage, callHandle:ULong, result:EResult, ioFailure:Int) { nomangle }
		inst.OnFileWriteAsyncComplete(callHandle, result, ioFailure)
	End Function

	Function _OnFileReadAsyncComplete(inst:TSteamRemoteStorage, callHandle:ULong, result:EResult, offset:UInt, bytesRead:UInt, ioFailure:Int) { nomangle }
		inst.OnFileReadAsyncComplete(callHandle, result, offset, bytesRead, ioFailure)
	End Function
End Type

Rem
bbdoc: Provides an interface to a steam instance.
End Rem
Type TSteamClient Extends TSteamAPI

	Const STEAMCLIENT_INTERFACE_VERSION:String = "SteamClient023"

	Method New()
		instancePtr = bmx_SteamAPI_SteamClient()

		If Not _user Then
			_user = bmx_SteamAPI_ISteamClient_ConnectToGlobalUser(instancePtr, _steamPipe)
		End If
	End Method

	Rem
	bbdoc: Returns a new instance of #TSteamUtils.
	End Rem
	Method GetISteamUtils:TSteamUtils()
		Return TSteamUtils._create(bmx_SteamAPI_ISteamClient_GetISteamUtils(instancePtr, _steamPipe))
	End Method
	
	Rem
	bbdoc: Returns a new instance of #TSteamUserStats.
	End Rem
	Method GetISteamUserStats:TSteamUserStats()
		Return TSteamUserStats._create(bmx_SteamAPI_ISteamClient_GetISteamUserStats(instancePtr, _user, _steamPipe))
	End Method

	Rem
	bbdoc: Returns a new instance of #TSteamUGC.
	End Rem
	Method GetISteamUGC:TSteamUGC()
		Return TSteamUGC._create(bmx_SteamAPI_ISteamClient_GetISteamUGC(instancePtr, _user, _steamPipe))
	End Method

	Rem
	bbdoc: Returns a new instance of #TSteamFriends.
	End Rem
	Method GetISteamFriends:TSteamFriends()
		Return TSteamFriends._create(bmx_SteamAPI_ISteamClient_GetISteamFriends(instancePtr, _user, _steamPipe))
	End Method

	Rem
	bbdoc: Returns the local Steam user interface.
	End Rem
	Method GetISteamUser:TSteamUser()
		Return TSteamUser._create(bmx_SteamAPI_ISteamClient_GetISteamUser(instancePtr, _user, _steamPipe))
	End Method

	Rem
	bbdoc: Returns the Steam lobby matchmaking interface.
	End Rem
	Method GetISteamMatchmaking:TSteamMatchmaking()
		Return TSteamMatchmaking._create(bmx_SteamAPI_ISteamClient_GetISteamMatchmaking(instancePtr, _user, _steamPipe))
	End Method

	Rem
	bbdoc: Returns the Steam application information interface.
	End Rem
	Method GetISteamApps:TSteamApps()
		Return TSteamApps._create(bmx_SteamAPI_ISteamClient_GetISteamApps(instancePtr, _user, _steamPipe))
	End Method

	Rem
	bbdoc: Returns the Steam Remote Storage and Steam Cloud file interface.
	End Rem
	Method GetISteamRemoteStorage:TSteamRemoteStorage()
		Return TSteamRemoteStorage._create(bmx_SteamAPI_ISteamClient_GetISteamRemoteStorage(instancePtr, _user, _steamPipe))
	End Method

	Rem
	bbdoc: Returns the Steam Input action-based controller interface.
	End Rem
	Method GetISteamInput:TSteamInput()
		Return TSteamInput._create(bmx_SteamAPI_ISteamClient_GetISteamInput(instancePtr, _user, _steamPipe))
	End Method

	Rem
	bbdoc: Returns the Steam Timeline interface for gameplay events, phases, and recordings.
	End Rem
	Method GetISteamTimeline:TSteamTimeline()
		Return TSteamTimeline._create(bmx_SteamAPI_SteamTimeline())
	End Method
	
End Type

Rem
bbdoc: Utils listener interface
about: Implement this and add as a listener to an instance of #TSteamUtils to receive appropriate event callbacks.
End Rem
Interface ISteamUtilsListener

	Rem
	bbdoc: CallResult for #CheckFileSignature.
	End Rem
	Method OnCheckFileSignature(checkFileSignature:ECheckFileSignature)
	Rem
	bbdoc: Called when the big picture gamepad text input has been closed.
	End Rem
	Method OnGamepadTextInputDismissed(submitted:Int, submittedTextLength:UInt)
	Rem
	bbdoc: Called when running on a laptop and less than 10 minutes of battery is left, and then fires then every minute afterwards.
	End Rem
	Method OnLowBatteryPower(minutesBatteryLeft:UInt)
	Rem
	bbdoc: Called when Steam wants to shutdown.
	End Rem
	Method OnSteamShutdown()
	
End Interface

Rem
bbdoc: Provides access to a range of miscellaneous utility functions.
End Rem
Type TSteamUtils Extends TSteamAPI

	Const STEAMUTILS_INTERFACE_VERSION:String = "SteamUtils011"

	Field listener:ISteamUtilsListener

	Function _create:TSteamUtils(instancePtr:Byte Ptr)
		Local this:TSteamUtils = New TSteamUtils
		this.instancePtr = instancePtr

		this.callbackPtr = bmx_steamsdk_register_steamutils(instancePtr, this)

		Return this
	End Function

	Method Delete()
		bmx_steamsdk_unregister_steamutils(callbackPtr)
	End Method

	Rem
	bbdoc: Sets the steam utils callback listener.
	about: Once installed, the listener will receive utils events via the callback methods.
	End Rem
	Method SetListener(listener:ISteamUtilsListener)
		Self.listener = listener
	End Method
	
	Rem
	bbdoc: Removes the current steam utils callback listener.
	End Rem
	Method RemoveListener()
		listener = Null
	End Method

	Rem
	bbdoc: Checks if the Overlay needs a present.
	returns: #True if the overlay needs you to refresh the screen, otherwise #False.
	about: Only required if using event driven render updates.
	End Rem
	Method OverlayNeedsPresent:Int()
		Return bmx_SteamAPI_ISteamUtils_BOverlayNeedsPresent(instancePtr)
	End Method
	
	Rem
	bbdoc: Gets the current amount of battery power on the computer.
	returns: The current battery power ranging between [0..100]%. Returns 255 when the user is on AC power.
	End Rem
	Method GetCurrentBatteryPower:Int()
		Return bmx_SteamAPI_ISteamUtils_GetCurrentBatteryPower(instancePtr)
	End Method
	
	Rem
	bbdoc: Gets the gamepad text input from the Big Picture overlay.
	returns: #True if there was text to receive and @txt is the same size as @submittedTextLength; otherwise, #False.
	about: This must be called within the #OnGamepadTextInputDismissed callback, and only if @submitted is #True.
	
	See Also: #ShowGamepadTextInput, #GetEnteredGamepadTextLength
	End Rem
	Method GetEnteredGamepadTextInput:Int(txt:String Var)
		Return bmx_SteamAPI_ISteamUtils_GetEnteredGamepadTextInput(instancePtr, txt)
	End Method
	
	Rem
	bbdoc: Gets the length of the gamepad text input from the Big Picture overlay.
	about: This must be called within the #OnGamepadTextInputDismissed callback, and only if @submitted is #True.
	
	See Also: #ShowGamepadTextInput, #GetEnteredGamepadTextInput
	End Rem
	Method GetEnteredGamepadTextLength:UInt()
		Return bmx_SteamAPI_ISteamUtils_GetEnteredGamepadTextLength(instancePtr)
	End Method
	
	Rem
	bbdoc: Gets the image bytes from an image handle.
	returns: #True upon success if the image handle is valid and the buffer was filled out, otherwise #False.
	about: Prior to calling this you must get the size of the image by calling #GetImageSize so that you can
	create your buffer with an appropriate size. You can then allocate your buffer with the width and
	height as: width * height * 4. The image is provided in RGBA format. This call can be somewhat expensive
	as it converts from the compressed type (JPG, PNG, TGA) and provides no internal caching of returned buffer,
	thus it is highly recommended to only call this once per image handle and cache the result.
	This method is only used for Steam Avatars and Achievement images and those are not expected to change mid game.
	End Rem
	Method GetImageRGBA:Int(image:Int, dest:Byte Ptr, destBufferSize:Int)
		Return bmx_SteamAPI_ISteamUtils_GetImageRGBA(instancePtr, image, dest, destBufferSize)
	End Method

	Rem
	bbdoc: Gets the size of a Steam image handle.
	returns: #True upon success if the image handle is valid and the sizes were filled out, otherwise #False.
	about: This must be called before calling #GetImageRGBA to create an appropriately sized buffer that will
	be filled with the raw image data.
	End Rem
	Method GetImageSize:Int(image:Int, width:UInt Var, height:UInt Var)
		Return bmx_SteamAPI_ISteamUtils_GetImageSize(instancePtr, image, width, height)
	End Method
	
	Rem
	bbdoc: Returns the number of seconds since the application was active.
	End Rem
	Method GetSecondsSinceAppActive:UInt()
		Return bmx_SteamAPI_ISteamUtils_GetSecondsSinceAppActive(instancePtr)
	End Method
	
	Rem
	bbdoc: Returns the number of seconds since the user last moved the mouse.
	End Rem
	Method GetSecondsSinceComputerActive:UInt()
		Return bmx_SteamAPI_ISteamUtils_GetSecondsSinceComputerActive(instancePtr)
	End Method
	
	Rem
	bbdoc: Returns the Steam server time in Unix epoch format.
	about: Number of seconds since Jan 1, 1970 UTC.
	End Rem
	Method GetServerRealTime:UInt()
		Return bmx_SteamAPI_ISteamUtils_GetServerRealTime(instancePtr)
	End Method
	
	Rem
	bbdoc: Returns the 2 digit ISO 3166-1-alpha-2 format country code which client is running in.
	about: This is looked up via an IP-to-location database.
	End Rem
	Method GetIPCountry:String()
		Return bmx_SteamAPI_ISteamUtils_GetIPCountry(instancePtr)
	End Method
	
	Rem
	bbdoc: Returns the language the steam client is running in.
	about: You probably want #TSteamApps.GetCurrentGameLanguage instead, this should only be used in very special cases.
	End Rem
	Method GetSteamUILanguage:String()
		Return bmx_SteamAPI_ISteamUtils_GetSteamUILanguage(instancePtr)
	End Method
	
	Rem
	bbdoc: Gets the App ID of the current process.
	returns: The AppId.
	End Rem
	Method GetAppID:UInt()
		Return bmx_SteamAPI_ISteamUtils_GetAppID(instancePtr)
	End Method
	
	Rem
	bbdoc: Checks if the Steam Overlay is running and the user can access it.
	about: The overlay process could take a few seconds to start and hook the game process, so this method will
	initially return #False while the overlay is loading.
	End Rem
	Method IsOverlayEnabled:Int()
		Return bmx_SteamAPI_ISteamUtils_IsOverlayEnabled(instancePtr)
	End Method
	
	Rem
	bbdoc: Checks if Steam and the Steam Overlay are running in Big Picture mode.
	returns: #True if the Big Picture overlay is available; otherwise, #False. This will always return #False if your app is not the 'game' application type.
	about: Games must be launched through the Steam client to enable the Big Picture overlay.
	During development, a game can be added as a non-steam game to the developers library to test this feature.
	End Rem
	Method IsSteamInBigPictureMode:Int()
		Return bmx_SteamAPI_ISteamUtils_IsSteamInBigPictureMode(instancePtr)
	End Method
	
	Rem
	bbdoc: Checks if Steam is running in VR mode.
	returns: #True if Steam itself is running in VR mode; otherwise, #False.
	End Rem
	Method IsSteamRunningInVR:Int()
		Return bmx_SteamAPI_ISteamUtils_IsSteamRunningInVR(instancePtr)
	End Method
	
	Rem
	bbdoc: Checks if the HMD view will be streamed via Steam In-Home Streaming.
	returns: #True if VR is enabled and the HMD view is currently being streamed; otherwise, #False.
	End Rem
	Method IsVRHeadsetStreamingEnabled:Int()
		Return bmx_SteamAPI_ISteamUtils_IsVRHeadsetStreamingEnabled(instancePtr)
	End Method
	
	Rem
	bbdoc: Sets the inset of the overlay notification from the corner specified by #SetOverlayNotificationPosition.
	about: A value of (0, 0) resets the position into the corner.
	This position is per-game and is reset each launch.
	End Rem
	Method SetOverlayNotificationInset(horizontalInset:Int, verticalInset:Int)
		bmx_SteamAPI_ISteamUtils_SetOverlayNotificationInset(instancePtr, horizontalInset, verticalInset)
	End Method
	
	Rem
	bbdoc: Sets which corner the Steam overlay notification popup should display itself in.
	about: You can also set the distance from the specified corner by using #SetOverlayNotificationInset.
	This position is per-game and is reset each launch.

	End Rem
	Method SetOverlayNotificationPosition(position:ENotificationPosition)
		bmx_SteamAPI_ISteamUtils_SetOverlayNotificationPosition(instancePtr, position)
	End Method
	
	Rem
	bbdoc: Sets whether the HMD content will be streamed via Steam In-Home Streaming.
	about: If this is enabled, then the scene in the HMD headset will be streamed, and remote input will
	not be allowed. Otherwise if this is disabled, then the application window will be streamed instead,
	and remote input will be allowed. VR games default to enabled unless "VRHeadsetStreaming" "0" is in the
	extended appinfo for a game.

	This is useful for games that have asymmetric multiplayer gameplay.
	End Rem
	Method SetVRHeadsetStreamingEnabled(enabled:Int)
		bmx_SteamAPI_ISteamUtils_SetVRHeadsetStreamingEnabled(instancePtr, enabled)
	End Method
	
	Rem
	bbdoc: Asks Steam to create and render the OpenVR dashboard.
	End Rem
	Method StartVRDashboard()
		bmx_SteamAPI_ISteamUtils_StartVRDashboard(instancePtr)
	End Method
	
	Rem
	bbdoc: Activates the Big Picture text input dialog which only supports gamepad input.
	returns: #True if the big picture overlay is running; otherwise, #False.
	about: See Also: #GetEnteredGamepadTextLength, #GetEnteredGamepadTextInput
	End Rem
	Method ShowGamepadTextInput:Int(inputMode:EGamepadTextInputMode, lineInputMode:EGamepadTextInputLineMode, description:String, charMax:UInt, existingText:String)
		Return bmx_SteamAPI_ISteamUtils_ShowGamepadTextInput(instancePtr, inputMode, lineInputMode, description, charMax, existingText)
	End Method

	Rem
	bbdoc: Checks a file's digital signature and reports the result through #ISteamUtilsListener.
	End Rem
	Method CheckFileSignature(fileName:String)
		bmx_SteamAPI_ISteamUtils_CheckFileSignature(instancePtr, fileName)
	End Method
	Rem
	bbdoc: Returns #True when running through the Steam China launcher.
	End Rem
	Method IsSteamChinaLauncher:Int()
		Return bmx_SteamAPI_ISteamUtils_IsSteamChinaLauncher(instancePtr)
	End Method
	Rem
	bbdoc: Initializes Steam's text-filtering dictionaries.
	End Rem
	Method InitFilterText:Int(filterOptions:UInt = 0)
		Return bmx_SteamAPI_ISteamUtils_InitFilterText(instancePtr, filterOptions)
	End Method
	Rem
	bbdoc: Filters user-generated text and returns the number of filtered characters.
	End Rem
	Method FilterText:Int(context:ETextFilteringContext, sourceSteamID:ULong, input:String, output:String Var)
		Return bmx_SteamAPI_ISteamUtils_FilterText(instancePtr, context, sourceSteamID, input, output)
	End Method
	Rem
	bbdoc: Returns Steam's current IPv6 connectivity assessment for @protocol.
	End Rem
	Method GetIPv6ConnectivityState:ESteamIPv6ConnectivityState(protocol:ESteamIPv6ConnectivityProtocol)
		Return bmx_SteamAPI_ISteamUtils_GetIPv6ConnectivityState(instancePtr, protocol)
	End Method
	Rem
	bbdoc: Returns #True when the application is running on a Steam Deck.
	End Rem
	Method IsSteamRunningOnSteamDeck:Int()
		Return IsRunningOnSteamHardware() = ESteamHardwareType.k_ESteamHardwareTypeSteamDeck
	End Method

	Rem
	bbdoc: Returns the Steam hardware family on which the process is running.
	End Rem
	Method IsRunningOnSteamHardware:ESteamHardwareType()
		Return bmx_SteamAPI_ISteamUtils_IsRunningOnSteamHardware(instancePtr)
	End Method

	Rem
	bbdoc: Returns the default performance configuration recommended by Steam for the current hardware.
	End Rem
	Method GetSteamHardwareDefaultConfig:ESteamHardwareDefaultConfig()
		Return bmx_SteamAPI_ISteamUtils_GetSteamHardwareDefaultConfig(instancePtr)
	End Method

	Rem
	bbdoc: Returns True when the process is running through Proton on Linux.
	End Rem
	Method IsRunningUnderProton:Int()
		Return bmx_SteamAPI_ISteamUtils_IsRunningUnderProton(instancePtr)
	End Method
	Rem
	bbdoc: Shows the floating gamepad keyboard over the supplied screen rectangle.
	End Rem
	Method ShowFloatingGamepadTextInput:Int(keyboardMode:EFloatingGamepadTextInputMode, x:Int, y:Int, width:Int, height:Int)
		Return bmx_SteamAPI_ISteamUtils_ShowFloatingGamepadTextInput(instancePtr, keyboardMode, x, y, width, height)
	End Method
	Rem
	bbdoc: Dismisses the floating gamepad keyboard if it is visible.
	End Rem
	Method DismissFloatingGamepadTextInput:Int()
		Return bmx_SteamAPI_ISteamUtils_DismissFloatingGamepadTextInput(instancePtr)
	End Method

	Rem
	bbdoc: Dismisses the full-screen Steam gamepad text-input dialog.
	End Rem
	Method DismissGamepadTextInput:Int()
		Return bmx_SteamAPI_ISteamUtils_DismissGamepadTextInput(instancePtr)
	End Method
	Rem
	bbdoc: Tells Steam whether this application is acting as a launcher for other games.
	End Rem
	Method SetGameLauncherMode(launcherMode:Int)
		bmx_SteamAPI_ISteamUtils_SetGameLauncherMode(instancePtr, launcherMode)
	End Method
	Rem
	bbdoc: Returns the Steam universe to which the client is connected.
	End Rem
	Method GetConnectedUniverse:EUniverse()
		Return bmx_SteamAPI_ISteamUtils_GetConnectedUniverse(instancePtr)
	End Method
	Rem
	bbdoc: Returns the number of Steam IPC calls made since the last query.
	End Rem
	Method GetIPCCallCount:UInt()
		Return bmx_SteamAPI_ISteamUtils_GetIPCCallCount(instancePtr)
	End Method

	' callbacks
	Private
	
	Method OnCheckFileSignature(checkFileSignature:ECheckFileSignature)
		If listener Then
			listener.OnCheckFileSignature(checkFileSignature)
		End If
	End Method

	Function _OnCheckFileSignature(inst:TSteamUtils, checkFileSignature:ECheckFileSignature) { nomangle }
		inst.OnCheckFileSignature(checkFileSignature)
	End Function
	
	Method OnGamepadTextInputDismissed(submitted:Int, submittedTextLength:UInt)
		If listener Then
			listener.OnGamepadTextInputDismissed(submitted, submittedTextLength)
		End If
	End Method

	Function _OnGamepadTextInputDismissed(inst:TSteamUtils, submitted:Int, submittedTextLength:UInt) { nomangle }
		inst.OnGamepadTextInputDismissed(submitted, submittedTextLength)
	End Function
	
	Method OnLowBatteryPower(minutesBatteryLeft:UInt)
		If listener Then
			listener.OnLowBatteryPower(minutesBatteryLeft)
		End If
	End Method

	Function _OnLowBatteryPower(inst:TSteamUtils, minutesBatteryLeft:UInt) { nomangle }
		inst.OnLowBatteryPower(minutesBatteryLeft)
	End Function
	
	Method OnSteamShutdown()
		If listener Then
			listener.OnSteamShutdown()
		End If
	End Method

	Function _OnSteamShutdown(inst:TSteamUtils) { nomangle }
		inst.OnSteamShutdown()
	End Function
	
End Type

Rem
bbdoc: Steam User Stats listener interface
about: Implement this and add as a listener to an instance of #TSteamUserStats to receive appropriate event callbacks.
End Rem
Interface ISteamUserStatsListener

	Rem
	bbdoc: Called when the global achievement percentages have been received from the server.
	End Rem
	Method OnGlobalAchievementPercentagesReady(gameID:ULong, result:EResult)
	Rem
	bbdoc: Called when the global stats have been received from the server.
	End Rem
	Method OnGlobalStatsReceived(gameID:ULong, result:EResult)
	Rem
	bbdoc: Result when finding a leaderboard.
	End Rem
	Method OnLeaderboardFindResult(leaderboardHandle:ULong, leaderboardFound:Int)
	Rem
	bbdoc: Called when scores for a leaderboard have been downloaded and are ready to be retrieved.
	about: After calling you must use #GetDownloadedLeaderboardEntry to retrieve the info for each downloaded entry.
	End Rem
	Method OnLeaderboardScoresDownloaded(leaderboardHandle:ULong, leaderboardEntriesHandle:ULong, entryCount:Int)
	Rem
	bbdoc: Result indicating that a leaderboard score has been uploaded.
	End Rem
	Method OnLeaderboardScoreUploaded(success:Int, leaderboardHandle:ULong, score:UInt, scoreChanged:Int, globalRankNew:Int, globalRankPrevious:Int)
	Rem
	bbdoc: Gets the current number of players for the current AppId.
	End Rem
	Method OnGetNumberOfCurrentPlayers(success:Int, players:Int)
	Rem
	bbdoc: Result of an achievement icon that has been fetched.
	End Rem
	Method OnUserAchievementIconFetched(gameID:ULong, achievementName:String, achieved:Int, iconHandle:Int)
	Rem
	bbdoc: Result of a request to store the achievements on the server, or an "indicate progress" call.
	about: If both @curProgress and @maxProgress are zero, that means the achievement has been fully unlocked.
	End Rem
	Method OnUserAchievementStored(gameID:ULong, groupAchievement:Int, achievementName:String, curProgress:UInt, maxProgress:UInt)
	Rem
	bbdoc: Called when the latest stats and achievements for a specific user (including the local user) have been received from the server.
	End Rem
	Method OnUserStatsReceived(gameID:ULong, result:EResult, steamID:ULong)
	Rem
	bbdoc: Result of a request to store the user stats.
	End Rem
	Method OnUserStatsStored(gameID:ULong, result:EResult)
	Rem
	bbdoc: Callback indicating that a user's stats have been unloaded.
	about: Call #RequestUserStats again before accessing stats for this user.
	End Rem
	Method OnUserStatsUnloaded(userID:ULong)

End Interface

Rem
bbdoc: Optional extended listener for leaderboard UGC attachment results.
End Rem
Interface ISteamUserStatsUGCListener
	Method OnLeaderboardUGCSet(result:EResult, leaderboardHandle:ULong, ioFailure:Int)
End Interface

Rem
bbdoc: Provides methods for accessing and submitting stats, achievements, and leaderboards.
End Rem
Type TSteamUserStats Extends TSteamAPI

	Const STEAMUSERSTATS_INTERFACE_VERSION:String = "STEAMUSERSTATS_INTERFACE_VERSION013"
	
	Field listener:ISteamUserStatsListener
	
	Function _create:TSteamUserStats(instancePtr:Byte Ptr)
		Local this:TSteamUserStats = New TSteamUserStats
		this.instancePtr = instancePtr
		
		this.callbackPtr = bmx_steamsdk_register_steamuserstats(instancePtr, this)
		
		Return this
	End Function
	
	Method Delete()
		bmx_steamsdk_unregister_steamuserstats(callbackPtr)
	End Method

	Rem
	bbdoc: Sets the user stats callback listener.
	about: Once installed, the listener will receive stats events via the callback methods.
	End Rem
	Method SetListener(listener:ISteamUserStatsListener)
		Self.listener = listener
	End Method
	
	Rem
	bbdoc: Removes the current user stats callback listener.
	End Rem
	Method RemoveListener()
		listener = Null
	End Method

	Rem
	bbdoc: Resets the unlock status of an achievement.
	returns: #True upon success if all of the following conditions are met; otherwise, #False.
	about: This is primarily only ever used for testing.
	
	You must have called #RequestCurrentStats and it needs to return successfully via its callback prior to calling this!

	This call only modifies Steam's in-memory state so it is quite cheap. To send the unlock status to the server and to
	trigger the Steam overlay notification you must call #StoreStats.
	
	See Also: #ResetAllStats, #GetAchievementAndUnlockTime, #GetAchievement, #SetAchievement
	End Rem
	Method ClearAchievement:Int(name:String)
		Return bmx_SteamAPI_ISteamUserStats_ClearAchievement(instancePtr, name)
	End Method
	
	Rem
	bbdoc: Fetches a series of leaderboard entries for a specified leaderboard.
	about: You can ask for more entries than exist, then this will return as many as do exist.
	
	If you want to download entries for an arbitrary set of users, such as all of the users on a server then you can
	use #DownloadLeaderboardEntriesForUsers which takes an array of Steam IDs.

	You must call #FindLeaderboard or #FindOrCreateLeaderboard to get a @leaderboardHandle prior to calling this method.
	End Rem
	Method DownloadLeaderboardEntries(leaderboardHandle:ULong, leaderboardDataRequest:ELeaderboardDataRequest, rangeStart:Int, rangeEnd:Int)
		bmx_SteamAPI_ISteamUserStats_DownloadLeaderboardEntries(callbackPtr, leaderboardHandle, leaderboardDataRequest, rangeStart, rangeEnd)
	End Method
	
	Rem
	bbdoc: Fetches leaderboard entries for an arbitrary set of users on a specified leaderboard.
	about: A maximum of 100 users can be downloaded at a time, with only one outstanding call at a time. If a user doesn't
	have an entry on the specified leaderboard, they won't be included in the result.

	If you want to download entries based on their ranking or friends of the current user then you should use #DownloadLeaderboardEntries.

	You must call #FindLeaderboard or #FindOrCreateLeaderboard to get a @leaderboardHandle prior to calling this method.
	End Rem
	Method DownloadLeaderboardEntriesForUsers(leaderboardHandle:ULong, users:ULong[])
		bmx_SteamAPI_ISteamUserStats_DownloadLeaderboardEntriesForUsers(callbackPtr, leaderboardHandle, users, users.length)
	End Method
	
	Rem
	bbdoc: Gets a leaderboard by name.
	about: You must call either this or #FindOrCreateLeaderboard to obtain the leaderboard handle which is valid
	for the game session for each leaderboard you wish to access prior to calling any other Leaderboard methods.
	
	See Also: #GetLeaderboardEntryCount, #DownloadLeaderboardEntries, #UploadLeaderboardScore
	End Rem
	Method FindLeaderboard(leaderboardName:String)
		bmx_SteamAPI_ISteamUserStats_FindLeaderboard(callbackPtr, leaderboardName)
	End Method
	
	Rem
	bbdoc: Gets a leaderboard by name, it will create it if it's not yet created.
	about: You must call either this or #FindLeaderboard to obtain the leaderboard handle which is valid for the
	game session for each leaderboard you wish to access prior to calling any other Leaderboard methods.

	Leaderboards created with this method will not automatically show up in the Steam Community. You must manually
	set the Community Name field in the App Admin panel of the Steamworks website. As such it's generally
	recommended to prefer creating the leaderboards in the App Admin panel on the Steamworks website and using
	#FindLeaderboard unless you're expected to have a large amount of dynamically created leaderboards.
	
	> You should never pass k_ELeaderboardSortMethodNone for @sortMethod or k_ELeaderboardDisplayTypeNone for @displayType as this is undefined behavior.
	
	See Also: #GetLeaderboardEntryCount, #DownloadLeaderboardEntries, #UploadLeaderboardScore
	End Rem
	Method FindOrCreateLeaderboard(leaderboardName:String, sortMethod:ELeaderboardSortMethod , displayType:ELeaderboardDisplayType)
		bmx_SteamAPI_ISteamUserStats_FindOrCreateLeaderboard(callbackPtr, leaderboardName, sortMethod, displayType)
	End Method
	
	Rem
	bbdoc: Gets the unlock status of the Achievement.
	about: The equivalent method for other users is #GetUserAchievement.
	
	This method returns #True upon success if all of the following conditions are met; otherwise, #False.
	* #RequestCurrentStats has completed and successfully returned its callback.
	* The 'API Name' of the specified achievement exists in App Admin on the Steamworks website, and the changes are published.

	If the call is successful then the unlock status is returned via the @achieved parameter.
	
	See Also: #GetAchievementDisplayAttribute, #GetAchievementName, #GetAchievementIcon, #GetAchievementAndUnlockTime, #GetAchievementAchievedPercent
	End Rem
	Method GetAchievement:Int(name:String, achieved:Int Var)
		Return bmx_SteamAPI_ISteamUserStats_GetAchievement(instancePtr, name, achieved)
	End Method
	
	Rem
	bbdoc: Returns the percentage of users who have unlocked the specified achievement.
	returns: #True upon success; otherwise #False if #RequestGlobalAchievementPercentages has not been called or if the specified 'API Name' does not exist in the global achievement percentages.
	about: You must have called #RequestGlobalAchievementPercentages and it needs to return successfully via its callback prior to calling this.
	
	See Also: #GetMostAchievedAchievementInfo, #GetNextMostAchievedAchievementInfo
	End Rem
	Method GetAchievementAchievedPercent:Int(name:String, percent:Float Var)
		Return bmx_SteamAPI_ISteamUserStats_GetAchievementAchievedPercent(instancePtr, name, percent)
	End Method
	
	Rem
	bbdoc: Gets the achievement status, and the time it was unlocked if unlocked.
	about: If the return value is #True, but the unlock time is zero, that means it was unlocked before Steam began
	tracking achievement unlock times (December 2009). The time is provided in Unix epoch format, seconds since January 1, 1970 UTC.

	The equivalent function for other users is GetUserAchievementAndUnlockTime.

	See Also: #GetAchievement, #GetAchievementDisplayAttribute, #GetAchievementName, #GetAchievementIcon
	End Rem
	Method GetAchievementAndUnlockTime:Int(name:String, achieved:Int Var, unlockTime:UInt Var)
		Return bmx_SteamAPI_ISteamUserStats_GetAchievementAndUnlockTime(instancePtr, name, achieved, unlockTime)
	End Method
	
	Rem
	bbdoc: Get general attributes for an achievement. Currently provides: Name, Description, and Hidden status.
	about: This receives the value from a dictionary/map keyvalue store, so you must provide one of the following keys.
	* "name" to retrive the localized achievement name in UTF8
	* "desc" to retrive the localized achievement description in UTF8
	* "hidden" for retrieving if an achievement is hidden. Returns "0" when not hidden, "1" when hidden

	This localization is provided based on the games language if it's set, otherwise it checks if a localization
	is avilable for the users Steam UI Language. If that fails too, then it falls back to english.

	See Also: #GetAchievement, #GetAchievementName, #GetAchievementIcon, #GetAchievementAndUnlockTime
	End Rem
	Method GetAchievementDisplayAttribute:String(name:String, key:String)
		Return bmx_SteamAPI_ISteamUserStats_GetAchievementDisplayAttribute(instancePtr, name, key)
	End Method
	
	Rem
	bbdoc: Gets the icon for an achievement.
	about: Triggers an OnUserAchievementIconFetched callback.
	The image is returned as a handle to be used with #TSteamUtils.GetImageRGBA to get the actual image data.

	An invalid handle of 0 will be returned under the following conditions:
	* #RequestCurrentStats has not completed and successfully returned its callback.
	* The specified achievement does not exist in App Admin on the Steamworks website, or the changes are not published.
	* Steam is still fetching the image data from the server. This will trigger an OnUserAchievementIconFetched callback which will notify you when the image data is ready and provide you with a new handle. If the @iconHandle in the callback is still 0, then there is no image set for the specified achievement.

	See Also: #GetAchievement, #GetAchievementName, #GetAchievementAndUnlockTime, #GetAchievementAchievedPercent, #GetAchievementDisplayAttribute
	End Rem
	Method GetAchievementIcon:Int(name:String)
		Return bmx_SteamAPI_ISteamUserStats_GetAchievementIcon(instancePtr, name)
	End Method
	
	Rem
	bbdoc: Gets the 'API name' for an achievement index between 0 and #GetNumAchievements.
	about: This method must be used in cojunction with #GetNumAchievements to loop over the list of achievements.
	In general games should not need these methods as they should have the list of achievements compiled into them.
	
	#RequestCurrentStats must have been called and successfully returned its callback, and the current App ID must have achievements.
	End Rem
	Method GetAchievementName:String(achievement:UInt)
		Return bmx_SteamAPI_ISteamUserStats_GetAchievementName(instancePtr, achievement)
	End Method
	
	Rem
	bbdoc: Gets the lifetime totals for an aggregated stat.
	about: You must have called #RequestGlobalStats and it needs to return successfully via its callback prior to calling this.
	
	This method returns #True upon success if all of the following conditions are met; otherwise, #False.
	* The specified stat exists in App Admin on the Steamworks website, and the changes are published.
	* #RequestGlobalStats has completed and successfully returned its callback.
	* The type does not match the type listed in the App Admin panel of the Steamworks website.

	See Also: #GetGlobalStatHistory
	End Rem
	Method GetGlobalStat:Int(statName:String, data:Long Var)
		Return bmx_SteamAPI_ISteamUserStats_GetGlobalStatInt64(instancePtr, statName, data)
	End Method
	
	Rem
	bbdoc: Gets the lifetime totals for an aggregated stat.
	about: You must have called #RequestGlobalStats and it needs to return successfully via its callback prior to calling this.
	
	This method returns #True upon success if all of the following conditions are met; otherwise, #False.
	* The specified stat exists in App Admin on the Steamworks website, and the changes are published.
	* #RequestGlobalStats has completed and successfully returned its callback.
	* The type does not match the type listed in the App Admin panel of the Steamworks website.

	See Also: #GetGlobalStatHistory
	End Rem
	Method GetGlobalStat:Int(statName:String, data:Double Var)
		Return bmx_SteamAPI_ISteamUserStats_GetGlobalStatDouble(instancePtr, statName, data)
	End Method
	
	Rem
	bbdoc: Gets the daily history for an aggregated stat.
	returns: The number of elements returned in the @data array.
	about: @data will be filled with daily values, starting with today.
	So when called, @data[0] will be today, @data[1] will be yesterday, and @data[2] will be two days ago, etc.

	You must have called #RequestGlobalStats and it needs to return successfully via its callback prior to calling this.

	A return value of `0` indicates failure for one of the following reasons:
	* The specified stat does not exist in App Admin on the Steamworks website, or the changes aren't published.
	* #RequestGlobalStats has not been called or returned its callback, with at least 1 day of history.
	* The type does not match the type listed in the App Admin panel of the Steamworks website.
	* There is no history available.
	End Rem
	Method GetGlobalStatHistory:Int(statName:String, data:Long[])
		Return bmx_SteamAPI_ISteamUserStats_GetGlobalStatHistoryInt64(instancePtr, statName, data, UInt(data.length))
	End Method
	
	Rem
	bbdoc: Gets the daily history for an aggregated stat.
	returns: The number of elements returned in the @data array.
	about: @data will be filled with daily values, starting with today.
	So when called, @data[0] will be today, @data[1] will be yesterday, and @data[2] will be two days ago, etc.

	You must have called #RequestGlobalStats and it needs to return successfully via its callback prior to calling this.

	A return value of `0` indicates failure for one of the following reasons:
	* The specified stat does not exist in App Admin on the Steamworks website, or the changes aren't published.
	* #RequestGlobalStats has not been called or returned its callback, with at least 1 day of history.
	* The type does not match the type listed in the App Admin panel of the Steamworks website.
	* There is no history available.
	End Rem
	Method GetGlobalStatHistory:Int(statName:String, data:Double[])
		Return bmx_SteamAPI_ISteamUserStats_GetGlobalStatHistoryDouble(instancePtr, statName, data, UInt(data.length))
	End Method
	
	Rem
	bbdoc: Returns the display type of a leaderboard handle.
	returns: The display type of the leaderboard. Returns ELeaderboardDisplayType.k_ELeaderboardDisplayTypeNone if the leaderboard handle is invalid.
	about: 
	See Also: #GetLeaderboardName, #GetLeaderboardSortMethod, #GetLeaderboardEntryCount
	End Rem
	Method GetLeaderboardDisplayType:ELeaderboardDisplayType(leaderboardHandle:ULong)
		Return bmx_SteamAPI_ISteamUserStats_GetLeaderboardDisplayType(instancePtr, leaderboardHandle)
	End Method
	
	Rem
	bbdoc: Returns the total number of entries in a leaderboard.
	returns: The number of entries in the leaderboard. Returns 0 if the leaderboard handle is invalid.
	about: This is cached on a per leaderboard basis upon the first call to #FindLeaderboard or #FindOrCreateLeaderboard and
	is refreshed on each successful call to #DownloadLeaderboardEntries, #DownloadLeaderboardEntriesForUsers, and #UploadLeaderboardScore.

	See Also: #GetLeaderboardName, #GetLeaderboardSortMethod, #GetLeaderboardDisplayType
	End Rem
	Method GetLeaderboardEntryCount:Int(leaderboardHandle:ULong)
		Return bmx_SteamAPI_ISteamUserStats_GetLeaderboardEntryCount(instancePtr, leaderboardHandle)
	End Method
	
	Rem
	bbdoc: Returns the name of a leaderboard handle.
	returns: The name of the leaderboard. Returns #Null if the leaderboard handle is invalid.
	about:
	See Also: #GetLeaderboardEntryCount, #GetLeaderboardSortMethod, #GetLeaderboardDisplayType
	End Rem
	Method GetLeaderboardName:String(leadboarHandle:ULong)
		Return bmx_SteamAPI_ISteamUserStats_GetLeaderboardName(instancePtr, leadboarHandle)
	End Method
	
	Rem
	bbdoc: Returns the sort order of a leaderboard handle.
	returns: The sort method of the leaderboard. Returns ELeaderboardSortMethod.k_ELeaderboardSortMethodNone if the leaderboard handle is invalid.
	about: 
	See Also: #GetLeaderboardName, #GetLeaderboardDisplayType, #GetLeaderboardEntryCount
	End Rem
	Method GetLeaderboardSortMethod:ELeaderboardSortMethod(leaderboardHandle:ULong)
		Return bmx_SteamAPI_ISteamUserStats_GetLeaderboardSortMethod(instancePtr, leaderboardHandle)
	End Method
	
	Rem
	bbdoc: Gets the info on the most achieved achievement for the game.
	returns: -1 if #RequestGlobalAchievementPercentages has not been called or if there are no global achievement percentages for this app Id.
	about: You must have called #RequestGlobalAchievementPercentages and it needs to return successfully via its callback prior to calling this.
	If the call is successful it returns an iterator which should be used with #GetNextMostAchievedAchievementInfo.
	
	See Also: #RequestCurrentStats, #RequestGlobalAchievementPercentages, #GetNextMostAchievedAchievementInfo, #GetAchievementAchievedPercent
	End Rem
	Method GetMostAchievedAchievementInfo:Int(name:String Var, percent:Float Var, achieved:Int Var)
		Return bmx_SteamAPI_ISteamUserStats_GetMostAchievedAchievementInfo(instancePtr, name, percent, achieved)
	End Method
	
	Rem
	bbdoc: Gets the info on the next most achieved achievement for the game.
	returns: -1 if #RequestGlobalAchievementPercentages has not been called or if there are no global achievement percentages for this app Id.
	about: You must have called #RequestGlobalAchievementPercentages and it needs to return successfully via its callback prior to calling this.
	If the call is successful it returns an iterator which should be used with subsequent calls to this method.
	End Rem
	Method GetNextMostAchievedAchievementInfo:Int(previous:Int, name:String Var, percent:Float Var, achieved:Int Var)
		Return bmx_SteamAPI_ISteamUserStats_GetNextMostAchievedAchievementInfo(instancePtr, previous, name, percent, achieved)
	End Method
	
	Rem
	bbdoc: Gets the number of achievements defined in the App Admin panel of the Steamworks website.
	returns: The number of achievements. Returns 0 if #RequestCurrentStats has not been called and successfully returned its callback, or the current App ID has no achievements.
	about: This is used for iterating through all of the achievements with #GetAchievementName.
	In general games should not need these methods because they should have a list of existing achievements compiled into them.
	
	See Also: #RequestCurrentStats, #GetAchievementName
	End Rem
	Method GetNumAchievements:UInt()
		Return bmx_SteamAPI_ISteamUserStats_GetNumAchievements(instancePtr)
	End Method
	
	Rem
	bbdoc: Asynchronously retrieves the total number of players currently playing the current game.
	about: Both online and in offline mode.
	End Rem
	Method GetNumberOfCurrentPlayers()
		bmx_SteamAPI_ISteamUserStats_GetNumberOfCurrentPlayers(callbackPtr)
	End Method

	Rem
	bbdoc: Gets the current value of the a stat for the current user.
	about: You must have called #RequestCurrentStats and it needs to return successfully via its callback prior to calling this.

	To receive stats for other users use #GetUserStat.

	This method returns #True upon success if all of the following conditions are met; otherwise, #False.
	* The specified stat exists in App Admin on the Steamworks website, and the changes are published.
	* #RequestCurrentStats has completed and successfully returned its callback.
	* The type passed to this function must match the type listed in the App Admin panel of the Steamworks website.

	See Also: #RequestCurrentStats, #SetStat, #UpdateAvgRateStat, #StoreStats, #ResetAllStats
	End Rem
	Method GetStat:Int(name:String, data:Int Var)
		Return bmx_SteamAPI_ISteamUserStats_GetStatInt32(instancePtr, name, data)
	End Method

	Rem
	bbdoc: Gets the current value of the a stat for the current user.
	about: You must have called #RequestCurrentStats and it needs to return successfully via its callback prior to calling this.

	To receive stats for other users use #GetUserStat.

	This method returns #True upon success if all of the following conditions are met; otherwise, #False.
	* The specified stat exists in App Admin on the Steamworks website, and the changes are published.
	* #RequestCurrentStats has completed and successfully returned its callback.
	* The type passed to this function must match the type listed in the App Admin panel of the Steamworks website.

	See Also: #RequestCurrentStats, #SetStat, #UpdateAvgRateStat, #StoreStats, #ResetAllStats
	End Rem
	Method GetStat:Int(name:String, data:Float Var)
		Return bmx_SteamAPI_ISteamUserStats_GetStatFloat(instancePtr, name, data)
	End Method

	Rem
	bbdoc: Gets the unlock status of the Achievement.
	about: The equivalent function for the local user is #GetAchievement.
	
	This function returns #True upon success if all of the following conditions are met; otherwise, #False.
	* #RequestUserStats has completed and successfully returned its callback.
	* The 'API Name' of the specified achievement exists in App Admin on the Steamworks website, and the changes are published.

	If the call is successful then the unlock status is returned via the @achieved parameter
	End Rem
	Method GetUserAchievement:Int(steamID:ULong, name:String, achieved:Int Var)
		Return bmx_SteamAPI_ISteamUserStats_GetUserAchievement(instancePtr, steamID, name, achieved)
	End Method
	
	Rem
	bbdoc: Gets the achievement status, and the time it was unlocked if unlocked.
	about: If the return value is true, but the unlock time is zero, that means it was unlocked before Steam
	began tracking achievement unlock times (December 2009). The time is provided in Unix epoch format, seconds since January 1, 1970 UTC.
	The equivalent method for the local user is #GetAchievementAndUnlockTime.

	This method returns #True upon success if all of the following conditions are met; otherwise, #False.
	* #RequestUserStats has completed and successfully returned its callback.
	* The 'API Name' of the specified achievement exists in App Admin on the Steamworks website, and the changes are published.

	If the call is successful then the achieved status and unlock time are provided via the arguments pbAchieved and punUnlockTime.
	End Rem
	Method GetUserAchievementAndUnlockTime:Int(steamID:ULong, name:String, achieved:Int Var, unlockTime:UInt Var)
		Return bmx_SteamAPI_ISteamUserStats_GetUserAchievementAndUnlockTime(instancePtr, steamID, name, achieved, unlockTime)
	End Method
	
	Rem
	bbdoc: Gets the current value of the a stat for the specified user.
	about: You must have called #RequestUserStats and it needs to return successfully via its callback prior to calling this.
	The equivalent method for the local user is #GetStat.

	This method returns #True upon success if all of the following conditions are met; otherwise, #False.
	* The specified stat exists in App Admin on the Steamworks website, and the changes are published.
	* #RequestUserStats has completed and successfully returned its callback.
	* The type does not match the type listed in the App Admin panel of the Steamworks website.
	End Rem
	Method GetUserStat:Int(steamID:ULong, name:String, data:Int Var)
		Return bmx_SteamAPI_ISteamUserStats_GetUserStatInt32(instancePtr, steamID, name, data)
	End Method
	
	Rem
	bbdoc: Gets the current value of the a stat for the specified user.
	about: You must have called #RequestUserStats and it needs to return successfully via its callback prior to calling this.
	The equivalent method for the local user is #GetStat.

	This method returns #True upon success if all of the following conditions are met; otherwise, #False.
	* The specified stat exists in App Admin on the Steamworks website, and the changes are published.
	* #RequestUserStats has completed and successfully returned its callback.
	* The type does not match the type listed in the App Admin panel of the Steamworks website.
	End Rem
	Method GetUserStat:Int(steamID:ULong, name:String, data:Float Var)
		Return bmx_SteamAPI_ISteamUserStats_GetUserStatFloat(instancePtr, steamID, name, data)
	End Method
	
	Rem
	bbdoc: Shows the user a pop-up notification with the current progress of an achievement.
	about: Calling this method will **NOT** set the progress or unlock the achievement, the game must do that manually by calling #SetStat!
	
	Triggers an #OnUserStatsStored callback.
	Triggers an #OnUserAchievementStored callback.

	This method returns true upon success if all of the following conditions are met; otherwise, false.
	* #RequestCurrentStats has completed and successfully returned its callback.
	* The specified achievement exists in App Admin on the Steamworks website, and the changes are published.
	* The specified achievement is not already unlocked.
	* @curProgress is less than @maxProgress.
	End Rem
	Method IndicateAchievementProgress:Int(name:String, curProgress:UInt, maxProgress:UInt)
		Return bmx_SteamAPI_ISteamUserStats_IndicateAchievementProgress(instancePtr, name, curProgress, maxProgress)
	End Method	

	Rem
	bbdoc: Asynchronously request the user's current stats and achievements from the server.
	about: You must always call this first to get the initial status of stats and achievements.
	Only after the resulting callback comes back can you start calling the rest of the stats and achievement functions for the current user.

	The equivalent function for other users is #RequestUserStats.
	
	See Also: #GetStat, #SetStat, #SetAchievement, #StoreStats
	End Rem
	Method RequestCurrentStats:Int()
		' Steamworks 1.61 synchronizes current stats before the game launches.
		' Retained as a successful compatibility no-op for existing applications.
		Return True
	End Method
	
	Rem
	bbdoc: Asynchronously fetch the data for the percentage of players who have received each achievement for the current game globally.
	about: You must have called #RequestCurrentStats and it needs to return successfully via its callback prior to calling this.
	
	Triggers an #OnGlobalAchievementPercentagesReady callback.
	
	See Also: #GetMostAchievedAchievementInfo, #GetNextMostAchievedAchievementInfo, #GetAchievementAchievedPercent
	End Rem
	Method RequestGlobalAchievementPercentages()
		bmx_SteamAPI_ISteamUserStats_RequestGlobalAchievementPercentages(callbackPtr)
	End Method
	
	Rem
	bbdoc: Asynchronously fetches global stats data, which is available for stats marked as "aggregated" in the App Admin panel of the Steamworks website.
	about: You must have called #RequestCurrentStats and it needs to return successfully via its callback prior to calling this.

	Triggers an #OnGlobalStatsReceived callback.

	See Also: #GetGlobalStat, #GetGlobalStatHistory
	End Rem
	Method RequestGlobalStats(historyDays:Int)
		bmx_SteamAPI_ISteamUserStats_RequestGlobalStats(callbackPtr, historyDays)
	End Method
	
	Rem
	bbdoc: Asynchronously downloads stats and achievements for the specified user from the server.
	about: These stats are not automatically updated; you'll need to call this method again to refresh any data that may have changed.
	To keep from using too much memory, a least recently used cache (LRU) is maintained and other user's stats will occasionally be
	unloaded. When this happens an #OnUserStatsUnloaded callback is sent. After receiving this callback the user's stats will be
	unavailable until this method is called again.

	The equivalent method for the local user is #RequestCurrentStats.
	
	Triggers an #OnUserStatsReceived callback.
	
	See Also: #GetUserAchievement, #GetUserAchievementAndUnlockTime, #GetUserStat
	End Rem
	Method RequestUserStats(steamID:ULong)
		bmx_SteamAPI_ISteamUserStats_RequestUserStats(callbackPtr, steamID)
	End Method

	Rem
	bbdoc: Returns the configured minimum and maximum progress values for an achievement.
	End Rem
	Method GetAchievementProgressLimits:Int(name:String, minimum:Int Var, maximum:Int Var)
		Return bmx_SteamAPI_ISteamUserStats_GetAchievementProgressLimitsInt32(instancePtr, name, minimum, maximum)
	End Method

	Rem
	bbdoc: Returns the configured minimum and maximum progress values for an achievement.
	End Rem
	Method GetAchievementProgressLimits:Int(name:String, minimum:Float Var, maximum:Float Var)
		Return bmx_SteamAPI_ISteamUserStats_GetAchievementProgressLimitsFloat(instancePtr, name, minimum, maximum)
	End Method

	Rem
	bbdoc: Reads one entry from a downloaded leaderboard result and optionally copies its detail values.
	End Rem
	Method GetDownloadedLeaderboardEntry:Int(entriesHandle:ULong, index:Int, steamID:ULong Var, globalRank:Int Var, score:Int Var, details:Int[], detailsCount:Int Var, ugcHandle:ULong Var)
		If Not details Then details = New Int[0]
		Return bmx_SteamAPI_ISteamUserStats_GetDownloadedLeaderboardEntry(instancePtr, entriesHandle, index, steamID, globalRank, score, details, details.Length, detailsCount, ugcHandle)
	End Method

	Rem
	bbdoc: Attaches a published UGC item to the current user's leaderboard entry asynchronously.
	End Rem
	Method AttachLeaderboardUGC(leaderboardHandle:ULong, ugcHandle:ULong)
		bmx_SteamAPI_ISteamUserStats_AttachLeaderboardUGC(callbackPtr, leaderboardHandle, ugcHandle)
	End Method
	
	Rem
	bbdoc: Resets the current users stats and, optionally achievements.
	returns: #True indicating success if #RequestCurrentStats has been called and successfully returned its callback; otherwise #False.
	about: This automatically calls #StoreStats to persist the changes to the server. This should typically only
	be used for testing purposes during development. Ensure that you sync up your stats with the new default
	values provided by Steam after calling this by calling #RequestCurrentStats.
	End Rem
	Method ResetAllStats:Int(achievementsToo:Int)
		Return bmx_SteamAPI_ISteamUserStats_ResetAllStats(instancePtr, achievementsToo)
	End Method
	
	Rem
	bbdoc: Unlocks an achievement.
	about: You must have called #RequestCurrentStats and it needs to return successfully via its callback prior to calling this!
	You can unlock an achievement multiple times so you don't need to worry about only setting achievements that
	aren't already set. This call only modifies Steam's in-memory state so it is quite cheap. To send the unlock
	status to the server and to trigger the Steam overlay notification you must call #StoreStats.

	This method returns #True upon success if all of the following conditions are met; otherwise, #False.
	* The specified achievement "API Name" exists in App Admin on the Steamworks website, and the changes are published.
	* #RequestCurrentStats has completed and successfully returned its callback.

	See Also: #RequestCurrentStats, #StoreStats, #ResetAllStats, #GetAchievementAndUnlockTime, #GetAchievement
	End Rem
	Method SetAchievement:Int(name:String)
		Return bmx_SteamAPI_ISteamUserStats_SetAchievement(instancePtr, name)
	End Method
	
	Rem
	bbdoc: Sets / updates the value of a given stat for the current user.
	about: You must have called #RequestCurrentStats and it needs to return successfully via its callback prior to calling this!

	This call only modifies Steam's in-memory state and is very cheap. Doing so allows Steam to persist the
	changes even in the event of a game crash or unexpected shutdown. To submit the stats to the server you must call #StoreStats.

	If this is returning #False and everything appears correct, then check to ensure that your changes in the App Admin
	panel of the Steamworks website are published.

	This method returns #True upon success if all of the following conditions are met; otherwise, #False.
	* The specified stat exists in App Admin on the Steamworks website, and the changes are published.
	* #RequestCurrentStats has completed and successfully returned its callback.
	* The type passed to this function must match the type listed in the App Admin panel of the Steamworks website.
	
	See Also: #GetStat, #UpdateAvgRateStat, #ResetAllStats
	End Rem
	Method SetStat:Int(name:String, data:Int)
		Return bmx_SteamAPI_ISteamUserStats_SetStatInt32(instancePtr, name, data)
	End Method
	
	Rem
	bbdoc: Sets / updates the value of a given stat for the current user.
	about: You must have called #RequestCurrentStats and it needs to return successfully via its callback prior to calling this!

	This call only modifies Steam's in-memory state and is very cheap. Doing so allows Steam to persist the
	changes even in the event of a game crash or unexpected shutdown. To submit the stats to the server you must call #StoreStats.

	If this is returning #False and everything appears correct, then check to ensure that your changes in the App Admin
	panel of the Steamworks website are published.

	This method returns #True upon success if all of the following conditions are met; otherwise, #False.
	* The specified stat exists in App Admin on the Steamworks website, and the changes are published.
	* #RequestCurrentStats has completed and successfully returned its callback.
	* The type passed to this function must match the type listed in the App Admin panel of the Steamworks website.
	
	See Also: #GetStat, #UpdateAvgRateStat, #ResetAllStats
	End Rem
	Method SetStat:Int(name:String, data:Float)
		Return bmx_SteamAPI_ISteamUserStats_SetStatFloat(instancePtr, name, data)
	End Method
	
	Rem
	bbdoc: Sends the changed stats and achievements data to the server for permanent storage.
	about: If this fails then nothing is sent to the server. It's advisable to keep trying until the call is successful.

	This call can be rate limited. Call frequency should be on the order of minutes, rather than seconds. You should only 
	be calling this during major state changes such as the end of a round, the map changing, or the user leaving a server.
	This call is required to display the achievement unlock notification dialog though, so if you have called #SetAchievement
	then it's advisable to call this soon after that.

	If you have stats or achievements that you have saved locally but haven't uploaded with this method when your
	application process ends then this function will automatically be called.

	You can find additional debug information written to the %steam_install%\logs\stats_log.txt file.
	
	Triggers an #OnUserStatsStored callback.
	Triggers an #OnUserAchievementStored callback.

	This method returns #True upon success if all of the following conditions are met; otherwise, #False.
	* #RequestCurrentStats has completed and successfully returned its callback.
	* The current game has stats associated with it in the Steamworks Partner backend, and those stats are published.

	If the call is successful you will receive an #OnUserStatsStored callback.

	If @esult has a result of k_EResultInvalidParam, then one or more stats uploaded has been rejected, either because
	they broke constraints or were out of date. In this case the server sends back updated values and the stats
	should be updated locally to keep in sync.

	If one or more achievements has been unlocked then this will also trigger an #OnUserAchievementStored callback.

	See Also: #SetStat, #SetAchievement
	End Rem
	Method StoreStats:Int()
		Return bmx_SteamAPI_ISteamUserStats_StoreStats(instancePtr)
	End Method
	
	Rem
	bbdoc: Updates an AVGRATE stat with new values.
	about: You must have called #RequestCurrentStats and it needs to return successfully via its callback prior to calling this!

	This call only modifies Steam's in-memory state and is very cheap. Doing so allows Steam to
	persist the changes even in the event of a game crash or unexpected shutdown.
	To submit the stats to the server you must call #StoreStats.

	If this is returning false and everything appears correct, then check to ensure that your changes in
	the App Admin panel of the Steamworks website are published.

	This method returns #True upon success if all of the following conditions are met; otherwise, #False.
	* The specified stat exists in App Admin on the Steamworks website, and the changes are published.
	* #RequestCurrentStats has completed and successfully returned its callback.
	* The type must be AVGRATE in the Steamworks Partner backend.
	End Rem
	Method UpdateAvgRateStat:Int(name:String, countThisSession:Float, sessionLength:Double)
		Return bmx_SteamAPI_ISteamUserStats_UpdateAvgRateStat(instancePtr, name, countThisSession, sessionLength)
	End Method
	
	Rem
	bbdoc: Uploads a user score to a specified leaderboard.
	about: Details are optional game-defined information which outlines how the user got that score.
	For example if it's a racing style time based leaderboard you could store the timestamps when the
	player hits each checkpoint. If you have collectibles along the way you could use bit fields as
	booleans to store the items the player picked up in the playthrough.

	Uploading scores to Steam is rate limited to 10 uploads per 10 minutes and you may only
	have one outstanding call to this function at a time.

	Triggers an #OnLeaderboardScoreUploaded callback.
	
	See Also: #DownloadLeaderboardEntries, #AttachLeaderboardUGC
	End Rem
	Method UploadLeaderboardScore(leaderboardHandle:ULong, uploadScoreMethod:ELeaderboardUploadScoreMethod, score:Int, scoreDetails:Int[])
		bmx_SteamAPI_ISteamUserStats_UploadLeaderboardScore(callbackPtr, leaderboardHandle, uploadScoreMethod, score, scoreDetails, scoreDetails.length)
	End Method
	
	' callbacks
	Private

	Method OnGlobalAchievementPercentagesReady(gameID:ULong, result:EResult)
		If listener Then
			listener.OnGlobalAchievementPercentagesReady(gameID, result)
		End If
	End Method

	Function _OnGlobalAchievementPercentagesReady(inst:TSteamUserStats, gameID:ULong, result:EResult) { nomangle }
		inst.OnGlobalAchievementPercentagesReady(gameID, result)
	End Function
	
	Method OnGlobalStatsReceived(gameID:ULong, result:EResult)
		If listener Then
			listener.OnGlobalStatsReceived(gameID, result)
		End If
	End Method

	Function _OnGlobalStatsReceived(inst:TSteamUserStats, gameID:ULong, result:EResult) { nomangle }
		inst.OnGlobalStatsReceived(gameID, result)
	End Function

	Method OnLeaderboardFindResult(leaderboardHandle:ULong, leaderboardFound:Int)
		If listener Then
			listener.OnLeaderboardFindResult(leaderboardHandle, leaderboardFound)
		End If
	End Method

	Function _OnLeaderboardFindResult(inst:TSteamUserStats, leaderboardHandle:ULong, leaderboardFound:Int) { nomangle }
		inst.OnLeaderboardFindResult(leaderboardHandle, leaderboardFound)
	End Function
	
	Method OnLeaderboardScoresDownloaded(leaderboardHandle:ULong, leaderboardEntriesHandle:ULong, entryCount:Int)
		If listener Then
			listener.OnLeaderboardScoresDownloaded(leaderboardHandle, leaderboardEntriesHandle, entryCount)
		End If
	End Method

	Function _OnLeaderboardScoresDownloaded(inst:TSteamUserStats, leaderboardHandle:ULong, leaderboardEntriesHandle:ULong, entryCount:Int) { nomangle }
		inst.OnLeaderboardScoresDownloaded(leaderboardHandle, leaderboardEntriesHandle, entryCount)
	End Function

	Method OnLeaderboardScoreUploaded(success:Int, leaderboardHandle:ULong, score:UInt, scoreChanged:Int, globalRankNew:Int, globalRankPrevious:Int)
		If listener Then
			listener.OnLeaderboardScoreUploaded(success, leaderboardHandle, score, scoreChanged, globalRankNew, globalRankPrevious)
		End If
	End Method

	Function _OnLeaderboardScoreUploaded(inst:TSteamUserStats, success:Int, leaderboardHandle:ULong, score:UInt, scoreChanged:Int, globalRankNew:Int, globalRankPrevious:Int) { nomangle }
		inst.OnLeaderboardScoreUploaded(success, leaderboardHandle, score, scoreChanged, globalRankNew, globalRankPrevious)
	End Function

	Method OnLeaderboardUGCSet(result:EResult, leaderboardHandle:ULong, ioFailure:Int)
		Local extended:ISteamUserStatsUGCListener = ISteamUserStatsUGCListener(listener)
		If extended Then extended.OnLeaderboardUGCSet(result, leaderboardHandle, ioFailure)
	End Method

	Function _OnLeaderboardUGCSet(inst:TSteamUserStats, result:EResult, leaderboardHandle:ULong, ioFailure:Int) { nomangle }
		inst.OnLeaderboardUGCSet(result, leaderboardHandle, ioFailure)
	End Function

	Method OnGetNumberOfCurrentPlayers(success:Int, players:Int)
		If listener Then
			listener.OnGetNumberOfCurrentPlayers(success, players)
		End If
	End Method

	Function _OnGetNumberOfCurrentPlayers(inst:TSteamUserStats, success:Int, players:Int) { nomangle }
		inst.OnGetNumberOfCurrentPlayers(success, players)
	End Function

	Method OnUserAchievementIconFetched(gameID:ULong, achievementName:String, achieved:Int, iconHandle:Int)
		If listener Then
			listener.OnUserAchievementIconFetched(gameID, achievementName, achieved, iconHandle)
		End If
	End Method

	Function _OnUserAchievementIconFetched(inst:TSteamUserStats, gameID:ULong, achievementName:String, achieved:Int, iconHandle:Int) { nomangle }
		inst.OnUserAchievementIconFetched(gameID, achievementName, achieved, iconHandle)
	End Function
	
	Method OnUserAchievementStored(gameID:ULong, groupAchievement:Int, achievementName:String, curProgress:UInt, maxProgress:UInt)
		If listener Then
			listener.OnUserAchievementStored(gameID, groupAchievement, achievementName, curProgress, maxProgress)
		End If
	End Method

	Function _OnUserAchievementStored(inst:TSteamUserStats, gameID:ULong, groupAchievement:Int, achievementName:String, curProgress:UInt, maxProgress:UInt) { nomangle }
		inst.OnUserAchievementStored(gameID, groupAchievement, achievementName, curProgress, maxProgress)
	End Function
	
	Method OnUserStatsReceived(gameID:ULong, result:EResult, steamID:ULong)
		If listener Then
			listener.OnUserStatsReceived(gameID, result, steamID)
		End If
	End Method
	
	Function _OnUserStatsReceived(inst:TSteamUserStats, gameID:ULong, result:EResult, steamID:ULong) { nomangle }
		inst.OnUserStatsReceived(gameID, result, steamID)
	End Function 

	Method OnUserStatsStored(gameID:ULong, result:EResult)
		If listener Then
			listener.OnUserStatsStored(gameID, result)
		End If
	End Method
	
	Function _OnUserStatsStored(inst:TSteamUserStats, gameID:ULong, result:EResult) { nomangle }
		inst.OnUserStatsStored(gameID, result)
	End Function 

	Method OnUserStatsUnloaded(userID:ULong)
		If listener Then
			listener.OnUserStatsUnloaded(userID)
		End If
	End Method

	Function _OnUserStatsUnloaded(inst:TSteamUserStats, userID:ULong) { nomangle }
		inst.OnUserStatsUnloaded(userID)
	End Function 
	
End Type

Rem
bbdoc: Steam UGC listener interface
about: Implement this and add as a listener to an instance of #TSteamUGC to receive appropriate event callbacks.
End Rem
Type TSteamUGCDetails
	Field publishedFileId:ULong
	Field result:EResult
	Field fileType:EWorkshopFileType
	Field creatorAppID:UInt
	Field consumerAppID:UInt
	Field title:String
	Field description:String
	Field steamIDOwner:ULong
	Field timeCreated:UInt
	Field timeUpdated:UInt
	Field timeAddedToUserList:UInt
	Field visibility:ERemoteStoragePublishedFileVisibility
	Field banned:Int
	Field acceptedForUse:Int
	Field tagsTruncated:Int
	Field tags:String
	Field fileHandle:ULong
	Field previewFileHandle:ULong
	Field fileName:String
	Field fileSize:Int
	Field previewFileSize:Int
	Field url:String
	Field votesUp:UInt
	Field votesDown:UInt
	Field score:Float
	Field numChildren:UInt

	Function _Create:TSteamUGCDetails(publishedFileId:ULong, result:EResult, fileType:EWorkshopFileType, creatorAppID:UInt, consumerAppID:UInt, title:String, description:String, steamIDOwner:ULong, timeCreated:UInt, timeUpdated:UInt, timeAddedToUserList:UInt, visibility:ERemoteStoragePublishedFileVisibility, banned:Int, acceptedForUse:Int, tagsTruncated:Int, tags:String, fileHandle:ULong, previewFileHandle:ULong, fileName:String, fileSize:Int, previewFileSize:Int, url:String, votesUp:UInt, votesDown:UInt, score:Float, numChildren:UInt) { nomangle }
		Local details:TSteamUGCDetails = New TSteamUGCDetails
		details.publishedFileId = publishedFileId; details.result = result; details.fileType = fileType; details.creatorAppID = creatorAppID; details.consumerAppID = consumerAppID
		details.title = title; details.description = description; details.steamIDOwner = steamIDOwner; details.timeCreated = timeCreated; details.timeUpdated = timeUpdated; details.timeAddedToUserList = timeAddedToUserList
		details.visibility = visibility; details.banned = banned; details.acceptedForUse = acceptedForUse; details.tagsTruncated = tagsTruncated; details.tags = tags
		details.fileHandle = fileHandle; details.previewFileHandle = previewFileHandle; details.fileName = fileName; details.fileSize = fileSize; details.previewFileSize = previewFileSize; details.url = url
		details.votesUp = votesUp; details.votesDown = votesDown; details.score = score; details.numChildren = numChildren
		Return details
	End Function
End Type

Interface ISteamUGCListener

	Rem
	bbdoc: The result of a call to #AddAppDependency
	End Rem
	Method OnAddAppDependency(result:EResult, publishedFileId:ULong, appID:UInt)
	Rem
	bbdoc: The result of a call to #AddDependency.
	End Rem
	Method OnAddDependency(result:EResult, publishedFileId:ULong, childPublishedFileId:ULong)
	Rem
	bbdoc: Called when the user has added or removed an item to/from their favorites.
	End Rem
	Method OnUserFavoriteItemsListChanged(result:EResult, publishedFileId:ULong, wasAddRequest:Int)
	Rem
	bbdoc: Called when a new workshop item has been created.
	End Rem
	Method OnCreateItem(result:EResult, publishedFileId:ULong, userNeedsToAcceptWorkshopLegalAgreement:Int)
	Rem
	bbdoc: Called when an attempt at deleting an item completes.
	End Rem
	Method OnDeleteItem(result:EResult, publishedFileId:ULong)
	Rem
	bbdoc: Called when a workshop item has been downloaded.
	about: NOTE: This callback goes out to all running applications, ensure that the app ID associated with the item matches what you expect.
	End Rem
	Method OnDownloadItem(result:EResult, appID:UInt, publishedFileId:ULong)
	Rem
	bbdoc: Called when getting the users vote status on an item.
	End Rem
	Method OnGetUserItemVote(result:EResult, publishedFileId:ULong, votedUp:Int, votedDown:Int, voteSkipped:Int)
	Rem
	bbdoc: Called when a workshop item has been installed or updated.
	about: 
	> NOTE: This callback goes out to all running applications, ensure that the app ID associated with the item matches what you expect.
	End Rem
	Method OnItemInstalled(appID:UInt, publishedFileId:ULong)
	Rem
	bbdoc: The result of a call to #RemoveAppDependency.
	End Rem
	Method OnRemoveAppDependency(result:EResult, publishedFileId:ULong, appID:UInt)
	Rem
	bbdoc: The result of a call to #RemoveDependency.
	End Rem
	Method OnRemoveUGCDependency(result:EResult, publishedFileId:ULong, childPublishedFileId:ULong)
	Rem
	bbdoc: Called when a UGC query request completes.
	End Rem
	Method OnSteamUGCQueryCompleted(result:EResult, queryHandle:ULong, numResultsReturned:UInt, totalMatchingResults:UInt)
	Rem
	bbdoc: Called when the user has voted on an item.
	End Rem
	Method OnSetUserItemVote(result:EResult, publishedFileId:ULong, voteUp:Int)
	Rem
	bbdoc: Called when workshop item playtime tracking has started.
	End Rem
	Method OnStartPlaytimeTracking(result:EResult)
	Rem
	bbdoc: Called when workshop item playtime tracking has stopped.
	End Rem
	Method OnStopPlaytimeTracking(result:EResult)
	Rem
	bbdoc: Called when getting the app dependencies for an item.
	End Rem
	Method OnGetAppDependencies(result:EResult, publishedFileId:ULong, appID:UInt Ptr, numAppDependencies:Int, totalNumAppDependencies:Int)
	Rem
	bbdoc: Called when an item update has completed.
	End Rem
	Method OnSubmitItemUpdate(result:EResult, userNeedsToAcceptWorkshopLegalAgreement:Int)
	Rem
	bbdoc: Called when the user has subscribed to a piece of UGC.
	End Rem
	Method OnRemoteStorageSubscribePublishedFile(result:EResult, publishedFileId:ULong)
	Rem
	bbdoc: Called when the user has unsubscribed from a piece of UGC.
	End Rem
	Method OnRemoteStorageUnsubscribePublishedFile(result:EResult, publishedFileId:ULong)
	
End Interface

Rem
bbdoc: Optional extended listener for Workshop EULA status results.
End Rem
Interface ISteamUGCEULAListener
	Method OnWorkshopEULAStatus(result:EResult, appID:UInt, version:UInt, actionTime:UInt, accepted:Int, needsAction:Int, ioFailure:Int)
End Interface

Rem
bbdoc: Steam UGC API
about: Steam Workshop is a system of back-end storage and front-end web pages that make it easy to store, organize, sort, rate, and download content for your game or application.

In a typical set-up, customers of your game would use tools provided by you with purchase of your game to create modifications or entirely new content.
Those customers would then submit that content through a form built into your tool to the Steam Workshop.
Other customers would then be able to browse, sort, rate, and subscribe to items they wish to add to their game by going to the Steam Workshop
in the Steam Community. Those items would then download through Steam. By using the #OnItemInstalled callback within your game, you can then
call #GetItemInstallInfo to get the installed location and read the data directly from that folder. That new content would then be recognized
by the game in whatever capacity makes sense for your game and the content created.

### Steam Workshop Types, Monetization, & Best Practices
For more information and definitions of the various types of Workshop integration you can utilize and how to make the best out of the
tools provided by Steam, please see the [Steam Workshop](https://partner.steamgames.com/doc/features/workshop) documentation.

### Enabling ISteamUGC for a Game or Application
Before workshop items can be uploaded to the Steamworks backend there are two configuration settings that must be made,
Configuring Steam Cloud Quotas and Enabling the ISteamUGC API.

The Steam Cloud feature is used to store the preview images associated to workshop items. The Steam Cloud Quota can be configured with the following steps:
1. Navigate to the Steam Cloud Settings page in the App Admin panel.
2. Set the Byte quota per user and Number of files allowed per user to appropriate values for preview image storage
3. Click Save Cloud Changes
4. From the Publish tab, click Prepare for Publishing
5. Click Publish to Steam and complete the process to publish the change.

Enabling the ISteamUGC API can be accomplished with the following steps:
1. Navigate to the Steam Workshop Configuration page in the App Admin panel.
2. Find the Additional Configuration Options section
3. Check on Use ISteamUGC for file transfer
4. Click Save Additional Configuration Options
5. From the Publish tab, click Prepare for Publishing
6. Click Publish to Steam and complete the process to publish the change.

Once these settings are in place workshop content can be uploaded via the API.

### Creating and Uploading Content
The process of creating and uploading workshop content is a simple and repeatable process.

#### Creating a Workshop Item
1. All workshop items begin their existence with a call to #CreateItem
 * The @consumerAppId variable should contain the App ID for the game or application. Do not pass the App ID of the workshop item creation tool if that is a separate App ID.
 * #EWorkshopFileType is an enumeration type that defines how the shared file will be shared with the community. The valid values are:
   * k_EWorkshopFileTypeCommunity - This file type is used to describe files that will be uploaded by users and made available to download by anyone in the community. Common usage of this would be to share user created mods.
   * k_EWorkshopFileTypeMicrotransaction - This file type is used to describe files that are uploaded by users, but intended only for the game to consider adding as official content. These files will not be downloaded by users through the Workshop, but will be viewable by the community to rate. This is the implementation that Team Fortress 2 uses.
2. Register a call result handler for #OnCreateItem.
3. First check the @result to ensure that the item was created successfully.
4. When the call result handler is executed, read the @publishedFileId value and store for future updates to the workshop item (e.g. in a project file associated with the creation tool).
5. The @userNeedsToAcceptWorkshopLegalAgreement variable should also be checked and if it's true, the user should be redirected to accept the legal agreement. See the [Workshop Legal Agreement](https://partner.steamgames.com/doc/features/workshop/implementation#Legal) section for more details.

#### Uploading a Workshop Item
1. Once a workshop item has been created and a published file id value has been returned, the content of the workshop item can be populated and uploaded to the Steam Workshop.
2. An item update begins with a call to #StartItemUpdate
3. Using the update handle that is returned from #StartItemUpdate, calls can be made to update the Title, Description, Visibility, Tags, Item Content and Item Preview Image through the various `SetItem[...]` methods.
  * #SetItemTitle - Sets a new title for an item.
  * #SetItemDescription - Sets a new description for an item.
  * #SetItemUpdateLanguage - Sets the language of the title and description that will be set in this item update.
  * #SetItemMetadata - Sets arbitrary metadata for an item. This metadata can be returned from queries without having to download and install the actual content.
  * #SetItemVisibility - Sets the visibility of an item.
  * #SetItemTags - Sets arbitrary developer specified tags on an item.
  * #AddItemKeyValueTag - Adds a key-value tag pair to an item. Keys can map to multiple different values (1-to-many relationship).
  * #RemoveItemKeyValueTags - Removes an existing key value tag from an item.
  * #SetItemContent - Sets the folder that will be stored as the content for an item.
  * #SetItemPreview -Sets the primary preview image for the item.
4. Once the update calls have been completed, calling #SubmitItemUpdate will initiate the upload process to the Steam Workshop.
  * Register a call result handler for #OnSubmitItemUpdate
  * When the call result handler is executed, check the @result to confirm the upload completed successfully.
  * Note: There is no method to cancel the item update and upload once it's been called.
5. If desired, the progress of the upload can be tracked using #GetItemUpdateProgress
  * #EItemUpdateStatus defines the upload and update progress.
  * @bytesProcessed and @bytesTotal can be used to provide input for a user interface control such as a progress bar to indicate progress of the upload.
  * @bytesTotal may update during the upload process based upon the stage of the item update.
6. In the same way as Creating a Workshop Item, confirm the user has accepted the legal agreement. This is necessary in case where the user didn't initially create the item but is editing an existing item.

##### Additional Notes
 * Workshop items were previously designated as single files. With ISteamUGC, a workshop item is a representation of a folder of files.
 * If a workshop item requires additional metadata for use by the consuming application, you can attach metadata to your item using the #SetItemMetadata call. This metadata can be returned in queries without having to download and install the item content.  Previously we suggested that you save this metadata to a file inside the workshop item folder, which of course you can still do.

### Consuming Content
Consuming workshop content falls into two categories, Item Subscription and Item Installation.

#### Item Subscription
The majority of subscriptions to a workshop item will happen through the Steam Workshop portal. It is a known location, common to all games and applications, and as such, users are likely to find and subscribe to items regularly on the workshop site.

However, ISteamUGC provides two methods for programmatically subscribing and unsubscribing to workshop items to support in-game item subscription management.
 * #SubscribeItem - Subscribe to a workshop item. It will be downloaded and installed as soon as possible.
 * #UnsubscribeItem - Unsubscribe from a workshop item. This will result in the item being removed after the game quits.

Two additional methods exist for enumerating through a user's subscribed items.
 * #GetNumSubscribedItems - Gets the total number of items the current user is subscribed to for the game or application.
 * #GetSubscribedItems - Gets a list of all of the items the current user is subscribed to for the current game.

##### Receiving Notifications for External Subscription Actions
In-game notifications can be received when a user has subscribed or unsubscribed from a file through any mechanism (e.g. ISteamUGC, Steam Workshop Website):
 * Register a callback handler for #OnRemoteStoragePublishedFileSubscribed and #OnRemoteStoragePublishedFileUnsubscribed
 * The @publishedFileId will be returned which can then be used to access the information about the workshop item.
 * The application ID (@appID) associated with the workshop item will also be returned. It should be compared against the running application ID as the handler will be called for all item subscriptions regardless of the running application.

#### Item Installation
Once Item Subscription information is known, the remaining consumption methods can be utilized. These methods provide information back to the game about the state of the item download and installation. Workshop item downloads are executed via the Steam Client and happen automatically, based on the following rules:

1. When the Steam Client indicates a game or application is to launch, all app depots that have been updated will be downloaded and installed.
2. Any existing installed workshop items are updated if needed
3. Game or application then launches
4. Newly subscribed workshop items that are not downloaded will then download and be installed in the background.
 * Subscribed files will be downloaded to the client in the order they were subscribed in.
 * The Steam download page will show workshop item downloads with a specific banner to indicate a workshop item download is occurring.

> Note: Using the "Verify Integrity of Game Files" feature in the Steam Client will also cause workshop items to be downloaded.

As the game will start before newly subscribed content is downloaded and installed, the remaining consumption methods exist to aid in monitoring and managing the install progress. They can also be used when items are subscribed in-game to provide status of installation in real time.

##### Status of a Workshop Item
 * #GetItemState - Gets the current state of a workshop item on this client.

##### Download Progress of a Workshop Item
 * #GetItemDownloadInfo - Get info about a pending download of a workshop item that has k_EItemStateNeedsUpdate set.

##### Initiate or Increase the Priority of Downloading a Workshop Item
1. #DownloadItem
 * Set @highPriority to #True to pause any existing in-progress downloads and immediately begin downloading this workshop item.
 * If the return value is #True then register and wait for the callback #OnDownloadItem before calling #GetItemInstallInfo or accessing the workshop item on disk.
 * If the user is not subscribed to the item (e.g. a Game Server using anonymous login), the workshop item will be downloaded and cached temporarily.
 * If the workshop item has an #EItemState of k_EItemStateNeedsUpdate, #DownloadItem can be called to initiate the update. Do not access the workshop item on disk until the callback ISteamUGC::DownloadItemResult_t is called.
 * This method only works with ISteamUGC created workshop items. It will not work with legacy ISteamRemoteStorage workshop items.
 * The #OnDownloadItem callback struct contains the application ID (m_unAppID) associated with the workshop item. It should be compared against the running application ID as the handler will be called for all item downloads regardless of the running application.

##### Retrieving information about the local copy of the Workshop Item
 * #GetItemInstallInfo - Gets info about currently installed content on the disc for workshop items that have k_EItemStateInstalled set.

##### Notification when a Workshop Item is Installed or Updated
 * Register a callback handler for #OnItemInstalled.

### Querying Content
The #TSteamUGC interface provides a flexible way to enumerate the various kinds of UGC in Steam (e.g. Workshop items, screenshots, videos, etc.).

1. Register a call result handler for #OnSteamUGCQueryCompleted.
2. There are a few methods available for creating the query depending upon the required scenario, Querying by Content Associated to a User or Querying All Content or getting the details of content you have ids for.
  * #CreateQueryUserUGCRequest - Query UGC associated with a user. You can use this to list the UGC the user is subscribed to amongst other things.
  * CreateQueryAllUGCRequest - Query for all matching UGC. You can use this to list all of the available UGC for your app.
  * CreateQueryUGCDetailsRequest - Query for the details of specific workshop items.
3. Customize the query as appropriate by calling the option setting methods:
  
  When querying for User UGC
  * #SetCloudFileNameFilter - Sets to only return items that have a specific filename on a pending UGC Query.

  When querying for All UGC
  * #SetMatchAnyTag - Sets whether workshop items will be returned if they have one or more matching tag, or if all tags need to match on a pending UGC Query.
  * #SetSearchText - Sets a string to that items need to match in either the title or the description on a pending UGC Query.
  * #SetRankedByTrendDays - Sets whether the order of the results will be updated based on the rank of items over a number of days on a pending UGC Query.

When querying for either type of UGC

  * #AddRequiredTag - Adds a required tag to a pending UGC Query. This will only return UGC with the specified tag.
  * #AddExcludedTag - Adds a excluded tag to a pending UGC Query. This will only return UGC without the specified tag.
  * #AddRequiredKeyValueTag - Adds a required key-value tag to a pending UGC Query. This will only return workshop items that have a key = `key` and a value = `value`.
  * #SetReturnOnlyIDs - Sets whether to only return IDs instead of all the details on a pending UGC Query. This is useful for when you don't need all the information (e.g. you just want to get the IDs of the items a user has in their favorites list.)
  * #SetReturnKeyValueTags - Sets whether to return any key-value tags for the items on a pending UGC Query.
  * #SetReturnLongDescription - Sets whether to return the full description for the items on a pending UGC Query.
  * #SetReturnMetadata - Sets whether to return the developer specified metadata for the items on a pending UGC Query.
  * #SetReturnChildren - Sets whether to return the IDs of the child items of the items on a pending UGC Query.
  * #SetReturnAdditionalPreviews - Sets whether to return any additional images/videos attached to the items on a pending UGC Query.
  * #SetReturnTotalOnly - Sets whether to only return the total number of matching items on a pending UGC Query. -- The actual items will not be returned when ISteamUGC::SteamUGCQueryCompleted_t is called.
  * #SetLanguage - Sets the language to return the title and description in for the items on a pending UGC Query.
  * #SetAllowCachedResponse - Sets whether results to be will be returned from the cache for the specific period of time on a pending UGC Query.

4. Send the query to Steam using #SendQueryUGCRequest which will invoke the #OnSteamUGCQueryCompleted call result handler registered in step 1.
5. In the call result handler for #OnSteamUGCQueryCompleted, call #GetQueryUGCResult to retrieve the details for each item returned.
6. You can also call these functions to retrieve additional information for each item (some of this data is not returned by default, so you need to configure your query appropriately):
  * #GetQueryUGCPreviewURL - Retrieve the URL to the preview image of an individual workshop item after receiving a querying UGC call result.
  * #GetQueryUGCMetadata - Retrieve the developer set metadata of an individual workshop item after receiving a querying UGC call result.
  * #GetQueryUGCChildren - Retrieve the ids of any child items of an individual workshop item after receiving a querying UGC call result.
  * #GetQueryUGCStatistic - Retrieve various statistics of an individual workshop item after receiving a querying UGC call result.
  * #GetQueryUGCNumAdditionalPreviews and #GetQueryUGCAdditionalPreview - Retrieve the details of an additional preview associated with an individual workshop item after receiving a querying UGC call result.
  * #GetQueryUGCNumKeyValueTags and #GetQueryUGCKeyValueTag - Retrieve the details of a key-value tag associated with an individual workshop item after receiving a querying UGC call result.

7. Call #ReleaseQueryUGCRequest to free up any memory allocated while querying or retrieving the results.

##### Paging Results
Up to 50 results will be returned from each query. Paging through more results can be achieved by creating a query that increments the unPage parameter (which should start at 1).

### Playtime Tracking
To track the playtime of Workshop items simply call #StartPlaytimeTracking with the ids of the items you want to track. Then when the items are removed from play call #StopPlaytimeTracking with the ids you want to stop tracking or call #StopPlaytimeTrackingForAllItems to stop tracking playtime for all items at once.
When your app shuts down, playtime tracking will automatically stop.

You will also be able to sort items by various playtime metrics in #CreateQueryAllUGCRequest queries. Here are the playtime based query types you can use:
 * k_EUGCQuery_RankedByPlaytimeTrend - Sort by total playtime in the "trend" period descending (set with #SetRankedByTrendDays)
 * k_EUGCQuery_RankedByTotalPlaytime - Sort by total lifetime playtime descending.
 * k_EUGCQuery_RankedByAveragePlaytimeTrend - Sort by average playtime in the "trend" period descending (set with #SetRankedByTrendDays)
 * k_EUGCQuery_RankedByLifetimeAveragePlaytime - Soft by lifetime average playtime descending
 * k_EUGCQuery_RankedByPlaytimeSessionsTrend - Sort by number of play sessions in the "trend" period descending (set in #SetRankedByTrendDays)
 * k_EUGCQuery_RankedByLifetimePlaytimeSessions - Sort by number of lifetime play sessions descending

### Deleting Workshop Item Content
To delete a Workshop item, you can call #DeleteItem. Please note that this does not prompt the user and cannot be undone.

### Workshop Legal Agreement
Workshop items will be hidden by default until the contributor agrees to the Steam Workshop Legal Agreement. In order to make it easy for the contributor to make the item publicly visible, please do the following.
1. Include text next to the button that submits an item to the workshop, something to the effect of: "By submitting this item, you agree to the [workshop terms of service](http://steamcommunity.com/sharedfiles/workshoplegalagreement)" (including the link)
2. After a user submits an item, open a browser window to the Steam Workshop page for that item by calling ISteamFriends::ActivateGameOverlayToWebPage with pchURL set to steam://url/CommunityFilePage/&lt;PublishedFileId_t&gt; replacing &lt;PublishedFileId_t&gt; with the workshop item id.

This has the benefit of directing the author to the workshop page so that they can see the item and configure it further if necessary and will make it easy for the user to read and accept the Steam Workshop Legal Agreement.

### Errors and Logging
The majority of #TSteamUGC methods return boolean values. For additional information on specific errors, there are a number of places to review:
 * `Steam\logs\Workshop_log.txt` is a log for all transfers that occur during workshop item downloading and installation.
 * `Steam\workshopbuilds\depot_build_<appid>.log` is a log for all actions during the upload and update of a workshop item.
 * #OnSteamUGCQueryCompleted, #OnCreateItem and #OnSubmitItemUpdate contain #EResult variables that can be checked.

End Rem
Type TSteamUGC Extends TSteamAPI

	Const STEAMUGC_INTERFACE_VERSION:String = "STEAMUGC_INTERFACE_VERSION021"

	Field listener:ISteamUGCListener

	Function _create:TSteamUGC(instancePtr:Byte Ptr)
		Local this:TSteamUGC = New TSteamUGC
		this.instancePtr = instancePtr
		
		this.callbackPtr = bmx_steamsdk_register_steamugc(instancePtr, this)
		
		Return this
	End Function
	
	Method Delete()
		bmx_steamsdk_unregister_steamugc(callbackPtr)
	End Method

	Rem
	bbdoc: Sets the UGC callback listener.
	about: Once installed, the listener will receive events via the callback methods.
	End Rem
	Method SetListener(listener:ISteamUGCListener)
		Self.listener = listener
	End Method
	
	Rem
	bbdoc: Removes the current UGC callback listener.
	End Rem
	Method RemoveListener()
		listener = Null
	End Method

	Rem
	bbdoc: Adds a dependency between the given item and the appid.
	about: This list of dependencies can be retrieved by calling #GetAppDependencies.
	This is a soft-dependency that is displayed on the web. It is up to the application to determine whether the item can actually be used or not.

	See Also: #RemoveAppDependency
	End Rem
	Method AddAppDependency(publishedFileID:ULong, appID:UInt)
		bmx_SteamAPI_ISteamUGC_AddAppDependency(callbackPtr, publishedFileID, appID)
	End Method
	
	Rem
	bbdoc: Adds a workshop item as a dependency to the specified item.
	about: If the @parentPublishedFileID item is of type #k_EWorkshopFileTypeCollection, then the childPublishedFileID is simply added to that collection.
	Otherwise, the dependency is a soft one that is displayed on the web and can be retrieved via the #TSteamUGC API using a combination of the @numChildren member variable of the SteamUGCDetails_t struct and #GetQueryUGCChildren.

	See Also: #RemoveDependency
	End Rem
	Method AddDependency(publishedFileId:ULong, childPublishedFileId:ULong)
		bmx_SteamAPI_ISteamUGC_AddDependency(callbackPtr, publishedFileId, childPublishedFileId)
	End Method
	
	Rem
	bbdoc: Adds a excluded tag to a pending UGC Query.
	returns: #True upon success or #False if the UGC query handle is invalid, if the UGC query handle is from #CreateQueryUGCDetailsRequest, or @tagName was #Null.
	about: This will only return UGC without the specified tag.
	
	NOTE: This must be set before you send a UGC Query handle using #SendQueryUGCRequest.
	
	See Also: #AddRequiredTag, #SetMatchAnyTag, #SetItemTags
	End Rem
	Method AddExcludedTag:Int(queryHandle:ULong, tagName:String)
		Return bmx_SteamAPI_ISteamUGC_AddExcludedTag(instancePtr, queryHandle, tagName)
	End Method
	
	Rem
	bbdoc: Adds a key-value tag pair to an item.
	about: Keys can map to multiple different values (1-to-many relationship).

	Key names are restricted to alpha-numeric characters and the '_' character.
	Both keys and values cannot exceed 255 characters in length.
	Key-value tags are searchable by exact match only.
	
	> NOTE: This must be set before you submit the UGC update handle using #SubmitItemUpdate.

	See Also: #RemoveItemKeyValueTags, #SetReturnKeyValueTags, #GetQueryUGCNumKeyValueTags, #GetQueryUGCKeyValueTag
	End Rem
	Method AddItemKeyValueTag:Int(queryHandle:ULong, key:String, value:String)
		Return bmx_SteamAPI_ISteamUGC_AddItemKeyValueTag(instancePtr, queryHandle, key, value)
	End Method
	
	Rem
	bbdoc: Adds an additional preview file for the item.
	about: Then the format of the image should be one that both the web and the application (if necessary) can render, and must be under 1MB.
	Suggested formats include JPG, PNG and GIF.

	> NOTE: Using k_EItemPreviewType_YouTubeVideo or k_EItemPreviewType_Sketchfab are not currently supported with this API.
	> For YouTube videos you should use #AddItemPreviewVideo.

	> NOTE: This must be set before you submit the UGC update handle using #SubmitItemUpdate.

	See Also: #GetQueryUGCNumAdditionalPreviews, #GetQueryUGCAdditionalPreview, #SetReturnAdditionalPreviews, #UpdateItemPreviewFile, #AddItemPreviewVideo, #RemoveItemPreview
	End Rem
	Method AddItemPreviewFile:Int(queryHandle:ULong, previewFile:String, previewType:EItemPreviewType)
		Return bmx_SteamAPI_ISteamUGC_AddItemPreviewFile(instancePtr, queryHandle, previewFile, previewType)
	End Method
	
	Rem
	bbdoc: Adds an additional video preview from YouTube for the item.
	about:
	> NOTE: This must be set before you submit the UGC update handle using #SubmitItemUpdate.
	
	See Also: #GetQueryUGCNumAdditionalPreviews, #GetQueryUGCAdditionalPreview, #SetReturnAdditionalPreviews, #UpdateItemPreviewVideo, #AddItemPreviewFile, #RemoveItemPreview
	End Rem
	Method AddItemPreviewVideo:Int(queryHandle:ULong, videoID:String)
		Return bmx_SteamAPI_ISteamUGC_AddItemPreviewVideo(instancePtr, queryHandle, videoID)
	End Method
	
	Rem
	bbdoc: Adds a workshop item to the users favorites list.
	about: See Also: #RemoveItemFromFavorites
	End Rem
	Method AddItemToFavorites(appId:UInt, publishedFileID:ULong)
		bmx_SteamAPI_ISteamUGC_AddItemToFavorites(callbackPtr, appId, publishedFileID)
	End Method
	
	Rem
	bbdoc: Adds a required key-value tag to a pending UGC Query.
	about: This will only return workshop items that have a key = pKey and a value = pValue.

	> NOTE: This must be set before you send a UGC Query handle using #SendQueryUGCRequest.

	See Also: #AddExcludedTag, #SetMatchAnyTag, #SetItemTags
	End Rem
	Method AddRequiredKeyValueTag:Int(queryHandle:ULong, key:String, value:String)
		Return bmx_SteamAPI_ISteamUGC_AddRequiredKeyValueTag(instancePtr, queryHandle, key, value)
	End Method
	
	Rem
	bbdoc: Adds a required tag to a pending UGC Query.
	about: This will only return UGC with the specified tag.

	> NOTE: This must be set before you send a UGC Query handle using #SendQueryUGCRequest.
	
	See Also: #AddExcludedTag, #SetMatchAnyTag, #SetItemTags
	End Rem
	Method AddRequiredTag:Int(queryHandle:ULong, tagName:String)
		Return bmx_SteamAPI_ISteamUGC_AddRequiredTag(instancePtr, queryHandle, tagName)
	End Method
	
	Rem
	bbdoc: Lets game servers set a specific workshop folder before issuing any UGC commands.
	returns: #True upon success, otherwise, #False if the calling user is not a game server or if the workshop is currently updating it's content.
	about: This is helpful if you want to support multiple game servers running out of the same install folder.
	End Rem
	Method InitWorkshopForGameServer:Int(workshopDepotID:ULong, folder:String)
		Return bmx_SteamAPI_ISteamUGC_InitWorkshopForGameServer(instancePtr, workshopDepotID, folder)
	End Method
	
	Rem
	bbdoc: Creates a new workshop item with no content attached yet.
	End Rem
	Method CreateItem(consumerAppId:UInt, FileType:EWorkshopFileType)
		bmx_SteamAPI_ISteamUGC_CreateItem(callbackPtr, consumerAppId, FileType)
	End Method
	
	Rem
	bbdoc: Query for all matching UGC.
	about: You can use this to list all of the available UGC for your app.

	This will return up to 50 results per page. You can make subsequent calls to this method, increasing @page each time to get the next set of results.
	
	> NOTE: Either @consumerAppID or @creatorAppID must have a valid AppID!

	> NOTE: You must release the handle returned by this function by calling #ReleaseQueryUGCRequest when you are done with it!

	To query for the UGC associated with a single user you can use #CreateQueryUserUGCRequest instead.
	End Rem
	Method CreateQueryAllUGCRequestPage:ULong(queryType:EUGCQuery, matchingeMatchingUGCTypeFileType:EUGCMatchingUGCType, creatorAppID:UInt, consumerAppID:UInt, page:UInt)
		Return bmx_SteamAPI_ISteamUGC_CreateQueryAllUGCRequestPage(instancePtr, queryType, matchingeMatchingUGCTypeFileType, creatorAppID, consumerAppID, page)
	End Method

	Rem
	bbdoc: Creates a cursor-based UGC query; release the returned handle after the query completes.
	End Rem
	Method CreateQueryAllUGCRequestCursor:ULong(queryType:EUGCQuery, matchingUGCType:EUGCMatchingUGCType, creatorAppID:UInt, consumerAppID:UInt, cursor:String = "*")
		Return bmx_SteamAPI_ISteamUGC_CreateQueryAllUGCRequestCursor(instancePtr, queryType, matchingUGCType, creatorAppID, consumerAppID, cursor)
	End Method

	Rem
	bbdoc: Returns the primary details for one item in a completed UGC query.
	End Rem
	Method GetQueryUGCResult:TSteamUGCDetails(queryHandle:ULong, index:UInt)
		Return TSteamUGCDetails(bmx_SteamAPI_ISteamUGC_GetQueryUGCResult(instancePtr, queryHandle, index))
	End Method

	Rem
	bbdoc: Returns the number of tags attached to one item in a completed UGC query.
	End Rem
	Method GetQueryUGCNumTags:UInt(queryHandle:ULong, index:UInt)
		Return bmx_SteamAPI_ISteamUGC_GetQueryUGCNumTags(instancePtr, queryHandle, index)
	End Method
	Rem
	bbdoc: Returns one tag from an item in a completed UGC query.
	End Rem
	Method GetQueryUGCTag:Int(queryHandle:ULong, index:UInt, tagIndex:UInt, value:String Var)
		Return bmx_SteamAPI_ISteamUGC_GetQueryUGCTag(instancePtr, queryHandle, index, tagIndex, value)
	End Method
	Rem
	bbdoc: Returns the localized display name of one UGC tag.
	End Rem
	Method GetQueryUGCTagDisplayName:Int(queryHandle:ULong, index:UInt, tagIndex:UInt, value:String Var)
		Return bmx_SteamAPI_ISteamUGC_GetQueryUGCTagDisplayName(instancePtr, queryHandle, index, tagIndex, value)
	End Method
	Rem
	bbdoc: Returns a value for a named key/value tag on a queried UGC item.
	End Rem
	Method GetQueryUGCKeyValueTag:Int(queryHandle:ULong, index:UInt, key:String, value:String Var)
		Return bmx_SteamAPI_ISteamUGC_GetQueryUGCKeyValueTagByKey(instancePtr, queryHandle, index, key, value)
	End Method
	Rem
	bbdoc: Adds a group of tags from which a UGC query result must match at least one.
	End Rem
	Method AddRequiredTagGroup:Int(queryHandle:ULong, tags:String[])
		Return bmx_SteamAPI_ISteamUGC_AddRequiredTagGroup(instancePtr, queryHandle, tags)
	End Method
	Rem
	bbdoc: Restricts a UGC query to items created within a Unix-time range.
	End Rem
	Method SetTimeCreatedDateRange:Int(queryHandle:ULong, startTime:UInt, endTime:UInt)
		Return bmx_SteamAPI_ISteamUGC_SetTimeCreatedDateRange(instancePtr, queryHandle, startTime, endTime)
	End Method
	Rem
	bbdoc: Restricts a UGC query to items updated within a Unix-time range.
	End Rem
	Method SetTimeUpdatedDateRange:Int(queryHandle:ULong, startTime:UInt, endTime:UInt)
		Return bmx_SteamAPI_ISteamUGC_SetTimeUpdatedDateRange(instancePtr, queryHandle, startTime, endTime)
	End Method
	Rem
	bbdoc: Controls whether a UGC update may use the legacy upload path.
	End Rem
	Method SetAllowLegacyUpload:Int(updateHandle:ULong, allowLegacyUpload:Int)
		Return bmx_SteamAPI_ISteamUGC_SetAllowLegacyUpload(instancePtr, updateHandle, allowLegacyUpload)
	End Method
	Rem
	bbdoc: Removes every key/value tag from a pending UGC item update.
	End Rem
	Method RemoveAllItemKeyValueTags:Int(updateHandle:ULong)
		Return bmx_SteamAPI_ISteamUGC_RemoveAllItemKeyValueTags(instancePtr, updateHandle)
	End Method
	Rem
	bbdoc: Opens the Steam Workshop legal agreement in the overlay.
	End Rem
	Method ShowWorkshopEULA:Int()
		Return bmx_SteamAPI_ISteamUGC_ShowWorkshopEULA(instancePtr)
	End Method
	Rem
	bbdoc: Requests Workshop agreement status through #ISteamUGCEULAListener.
	End Rem
	Method GetWorkshopEULAStatus()
		bmx_SteamAPI_ISteamUGC_GetWorkshopEULAStatus(callbackPtr)
	End Method
	
	Rem
	bbdoc: Query for the details of specific workshop items.
	about: This will return up to 50 results per page.

	> NOTE: Either @consumerAppID or @creatorAppID must have a valid AppID!

	> NOTE: You must release the handle returned by this function by calling #ReleaseQueryUGCRequest when you are done with it!

	To query all the UGC for your app you can use #CreateQueryAllUGCRequest instead.
	End Rem
	Method CreateQueryUGCDetailsRequest:ULong(publishedFileIDs:ULong[])
		Return CreateQueryUGCDetailsRequest(publishedFileIDs, publishedFileIDs.length)
	End Method

	Rem
	bbdoc: Query for the details of specific workshop items.
	about: This will return up to 50 results per page.

	> NOTE: Either @consumerAppID or @creatorAppID must have a valid AppID!

	> NOTE: You must release the handle returned by this function by calling #ReleaseQueryUGCRequest when you are done with it!

	To query all the UGC for your app you can use #CreateQueryAllUGCRequest instead.
	End Rem
	Method CreateQueryUGCDetailsRequest:ULong(publishedFileIDs:ULong Ptr, numPublishedFileIDs:Int)
		Return bmx_SteamAPI_ISteamUGC_CreateQueryUGCDetailsRequest(instancePtr, publishedFileIDs, numPublishedFileIDs)
	End Method
	
	Rem
	bbdoc: Query UGC associated with a user.
	about: You can use this to list the UGC the user is subscribed to amongst other things.
	This will return up to 50 results per page. You can make subsequent calls to this method, increasing @page each time to get the next set of results.

	> NOTE: Either @consumerAppID or @creatorAppID must have a valid AppID!

	> NOTE: You must release the handle returned by this function by calling #ReleaseQueryUGCRequest when you are done with it!

	To query all the UGC for your app you can use #CreateQueryAllUGCRequest instead.
	End Rem
	Method CreateQueryUserUGCRequest:ULong(accountID:UInt, listType:EUserUGCList, matchingUGCType:EUGCMatchingUGCType, sortOrder:EUserUGCListSortOrder, creatorAppID:UInt, consumerAppID:UInt, page:UInt)
		Return bmx_SteamAPI_ISteamUGC_CreateQueryUserUGCRequest(instancePtr, accountID, listType, matchingUGCType, sortOrder, creatorAppID, consumerAppID, page)
	End Method
	
	Rem
	bbdoc: Deletes the item without prompting the user.
	about: Results in a cal to #OnDeleteItem.
	End Rem
	Method DeleteItem(publishedFileID:ULong)
		bmx_SteamAPI_ISteamUGC_DeleteItem(callbackPtr, publishedFileID)
	End Method
	
	Rem
	bbdoc: Downloads or updates a workshop item.
	returns: #True if the download was successfully started, otherwise, #False if @publishedFileID is invalid or the user is not logged on.
	about: If the return value is #True then wait for the callback to #OnDownloadItem before calling #GetItemInstallInfo or accessing the workshop item on disk.

	If the user is not subscribed to the item (e.g. a Game Server using anonymous login), the workshop item will be downloaded and cached temporarily.

	If the workshop item has an item state of k_EItemStateNeedsUpdate, then this method can be called to initiate the update.
	Do not access the workshop item on disk until the callback #OnDownloadItem is called.

	The #OnDownloadItem callback contains the app ID associated with the workshop item. It should be compared against the running app ID as
	the handler will be called for all item downloads regardless of the running application.
	End Rem
	Method DownloadItem:Int(publishedFileID:ULong, highPriority:Int)
		Return bmx_SteamAPI_ISteamUGC_DownloadItem(instancePtr, publishedFileID, highPriority)
	End Method

	Rem
	bbdoc: Gets the app dependencies associated with the given @publishedFileID.
	about: These are "soft" dependencies that are shown on the web. It is up to the application to determine whether an item can be used or not.
	
	Results in a call to #OnGetAppDependencies.
	
	See Also: #AddAppDependency, #RemoveAppDependency
	End Rem
	Method GetAppDependencies(publishedFileID:ULong)
		bmx_SteamAPI_ISteamUGC_GetAppDependencies(callbackPtr, publishedFileID)
	End Method
	
	Rem
	bbdoc: Gets info about a pending download of a workshop item that has k_EItemStateNeedsUpdate set.
	returns: #True if the download information was available, otherwise, #False.
	End Rem
	Method GetItemDownloadInfo:Int(publishedFileID:ULong, bytesDownloaded:ULong Var, bytesTotal:ULong Var)
		Return bmx_SteamAPI_ISteamUGC_GetItemDownloadInfo(instancePtr, publishedFileID, bytesDownloaded, bytesTotal)
	End Method
	
	Rem
	bbdoc: Gets info about currently installed content on the disc for workshop items that have k_EItemStateInstalled set.
	about: Calling this sets the "used" flag on the workshop item for the current player and adds it to their k_EUserUGCList_UsedOrPlayed list.

	If k_EItemStateLegacyItem is set then @folder contains the path to the legacy file itself, not a folder.
	End Rem
	Method GetItemInstallInfo:Int(publishedFileID:ULong, sizeOnDisk:ULong Var, folder:String Var, timestamp:UInt Var)
		Return bmx_SteamAPI_ISteamUGC_GetItemInstallInfo(instancePtr, publishedFileID, sizeOnDisk, folder, timestamp)
	End Method
	
	Rem
	bbdoc: Gets the current state of a workshop item on this client.
	End Rem
	Method GetItemState:EItemState(publishedFileID:ULong)
		Return bmx_SteamAPI_ISteamUGC_GetItemState(instancePtr, publishedFileID)
	End Method
	
	Rem
	bbdoc: Gets the progress of an item update.
	returns: The current status.
	about: See Also: #SubmitItemUpdate
	End Rem
	Method GetItemUpdateProgress:EItemUpdateStatus(queryHandle:ULong, bytesProcessed:ULong Var, bytesTotal:ULong Var)
		Return bmx_SteamAPI_ISteamUGC_GetItemUpdateProgress(instancePtr, queryHandle, bytesProcessed, bytesTotal)
	End Method
	
	Rem
	bbdoc: Gets the total number of items the current user is subscribed to for the game or application.
	returns: 0 if called from a game server.
	End Rem
	Method GetNumSubscribedItems:UInt(includeLocallyDisabled:Int = False)
		Return bmx_SteamAPI_ISteamUGC_GetNumSubscribedItems(instancePtr, includeLocallyDisabled)
	End Method
	
	Rem
	bbdoc: Retrieves the details of an additional preview associated with an individual workshop item after receiving a querying UGC call result.
	returns: #True upon success, indicates that @URLOrVideoID and @previewType have been filled out. Otherwise, #False if the UGC query handle is invalid, the @index is out of bounds, or @previewIndex is out of bounds.
	about: You should call this in a loop to get the details of all the workshop items returned.

	> NOTE: This must only be called with the handle obtained from a successful #OnSteamUGCQueryCompleted call result.

	Before calling this you should call #GetQueryUGCNumAdditionalPreviews to get number of additional previews.
	End Rem
	Method GetQueryUGCAdditionalPreview:Int(queryHandle:ULong, index:UInt, previewIndex:UInt, URLOrVideoID:String Var, originalFileName:String Var, previewType:EItemPreviewType Var)
		Return bmx_SteamAPI_ISteamUGC_GetQueryUGCAdditionalPreview(instancePtr, queryHandle, index, previewIndex, URLOrVideoID, originalFileName, previewType)
	End Method
	
	Rem
	bbdoc: Retrieves the ids of any child items of an individual workshop item after receiving a querying UGC call result.
	returns: #True upon success, indicates that @publishedFileIDs has been filled out. Otherwise, #False if the UGC query handle is invalid or the @index is out of bounds.
	about: These items can either be a part of a collection or some other dependency (see #AddDependency).

	You should call this in a loop to get the details of all the workshop items returned.

	> NOTE: This must only be called with the handle obtained from a successful #OnSteamUGCQueryCompleted call result.

	You should create @publishedFileIDs with @numChildren provided in #OnSteamUGCDetails after getting the UGC details with #GetQueryUGCResult.
	End Rem
	Method GetQueryUGCChildren:Int(queryHandle:ULong, index:UInt, publishedFileIDs:ULong Ptr, maxEntries:UInt)
		Return bmx_SteamAPI_ISteamUGC_GetQueryUGCChildren(instancePtr, queryHandle, index, publishedFileIDs, maxEntries)
	End Method
	
	Rem
	bbdoc: Retrieves the details of a key-value tag associated with an individual workshop item after receiving a querying UGC call result.
	returns: #True upon success, indicates that @key and @value have been filled out. Otherwise, #False if the UGC query handle is invalid, the @index is out of bounds, or @keyValueTagIndex is out of bounds.
	about: You should call this in a loop to get the details of all the workshop items returned.

	> NOTE: This must only be called with the handle obtained from a successful #OnSteamUGCQueryCompleted call result.

	Before calling this you should call #GetQueryUGCNumKeyValueTags to get number of tags.
	End Rem
	Method GetQueryUGCKeyValueTag:Int(queryHandle:ULong, index:UInt, keyValueTagIndex:UInt, key:String Var, value:String Var)
		Return bmx_SteamAPI_ISteamUGC_GetQueryUGCKeyValueTag(instancePtr, queryHandle, index, keyValueTagIndex, key, value)
	End Method
	
	Rem
	bbdoc: Retrieves the developer set metadata of an individual workshop item after receiving a querying UGC call result.
	returns: #True upon success, indicates that @metadata has been filled out. Otherwise, false if the UGC query handle is invalid or the @index is out of bounds.
	about: You should call this in a loop to get the details of all the workshop items returned.

	> NOTE: This must only be called with the handle obtained from a successful #OnSteamUGCQueryCompleted call result.
	
	See Also: #SetItemMetadata
	End Rem
	Method GetQueryUGCMetadata:Int(queryHandle:ULong, index:UInt, metadata:String Var)
		Return bmx_SteamAPI_ISteamUGC_GetQueryUGCMetadata(instancePtr, queryHandle, index, metadata)
	End Method
	
	Rem
	bbdoc: Retrieve the number of additional previews of an individual workshop item after receiving a querying UGC call result.
	returns: The number of additional previews associated with the specified workshop item. Returns 0 if the UGC query handle is invalid or the @index is out of bounds.
	about: You should call this in a loop to get the details of all the workshop items returned.

	> NOTE: This must only be called with the handle obtained from a successful #OnSteamUGCQueryCompleted call result.

	You can then call #GetQueryUGCAdditionalPreview to get the details of each additional preview.
	End Rem
	Method GetQueryUGCNumAdditionalPreviews:UInt(queryHandle:ULong, index:UInt)
		Return bmx_SteamAPI_ISteamUGC_GetQueryUGCNumAdditionalPreviews(instancePtr, queryHandle, index)
	End Method
	
	Rem
	bbdoc: Retrieves the number of key-value tags of an individual workshop item after receiving a querying UGC call result.
	returns: The number of key-value tags associated with the specified workshop item. Returns 0 if the UGC query handle is invalid or the @index is out of bounds.
	about: You should call this in a loop to get the details of all the workshop items returned.

	> NOTE: This must only be called with the handle obtained from a successful #OnSteamUGCQueryCompleted call result.

	You can then call #GetQueryUGCKeyValueTag to get the details of each tag.
	End Rem
	Method GetQueryUGCNumKeyValueTags:UInt(queryHandle:ULong, index:UInt)
		Return bmx_SteamAPI_ISteamUGC_GetQueryUGCNumKeyValueTags(instancePtr, queryHandle, index)
	End Method
	
	Rem
	bbdoc: Retrieves the URL to the preview image of an individual workshop item after receiving a querying UGC call result.
	returns: #True upon success, indicates that pchURL has been filled out. Otherwise, false if the UGC query handle is invalid or the @index is out of bounds.
	about: You should call this in a loop to get the details of all the workshop items returned.

	> NOTE: This must only be called with the handle obtained from a successful #OnSteamUGCQueryCompleted call result.
	
	You can use this URL to download and display the preview image instead of having to download it using the @previewFile from the SteamUGCDetails.
	End Rem
	Method GetQueryUGCPreviewURL:Int(queryHandle:ULong, index:UInt, URL:String Var)
		Return bmx_SteamAPI_ISteamUGC_GetQueryUGCPreviewURL(instancePtr, queryHandle, index, URL)
	End Method
	
	Rem
	bbdoc: Retrieves various statistics of an individual workshop item after receiving a querying UGC call result.
	returns: #True upon success, indicates that pStatValue has been filled out. Otherwise, #False if the UGC query handle is invalid, the @index is out of bounds, or @statType was invalid.

	about: You should call this in a loop to get the details of all the workshop items returned.

	> NOTE: This must only be called with the handle obtained from a successful #OnSteamUGCQueryCompleted call result.
	End Rem
	Method GetQueryUGCStatistic:Int(queryHandle:ULong, index:UInt, statType:EItemStatistic, statValue:ULong Var)
		Return bmx_SteamAPI_ISteamUGC_GetQueryUGCStatistic(instancePtr, queryHandle, index, statType, statValue)
	End Method
	
	Rem
	bbdoc: Gets a list of all of the items the current user is subscribed to for the current game.
	returns: The number of subscribed workshop items that were populated into @publishedFileIDs. Returns 0 if called from a game server.
	about: You create an array with the size provided by #GetNumSubscribedItems before calling this.
	End Rem
	Method GetSubscribedItems:UInt(publishedFileIDs:ULong Ptr, maxEntries:UInt, includeLocallyDisabled:Int = False)
		Return bmx_SteamAPI_ISteamUGC_GetSubscribedItems(instancePtr, publishedFileIDs, maxEntries, includeLocallyDisabled)
	End Method

	Method GetNumSupportedGameVersions:UInt(queryHandle:ULong, index:UInt)
		Return bmx_SteamAPI_ISteamUGC_GetNumSupportedGameVersions(instancePtr, queryHandle, index)
	End Method

	Method GetSupportedGameVersionData:Int(queryHandle:ULong, index:UInt, versionIndex:UInt, minimum:String Var, maximum:String Var)
		Return bmx_SteamAPI_ISteamUGC_GetSupportedGameVersionData(instancePtr, queryHandle, index, versionIndex, minimum, maximum)
	End Method

	Method GetQueryUGCContentDescriptors:UInt(queryHandle:ULong, index:UInt, descriptors:EUGCContentDescriptorID Ptr, maxEntries:UInt)
		Return bmx_SteamAPI_ISteamUGC_GetQueryUGCContentDescriptors(instancePtr, queryHandle, index, descriptors, maxEntries)
	End Method

	Method SetAdminQuery:Int(queryHandle:ULong, adminQuery:Int)
		Return bmx_SteamAPI_ISteamUGC_SetAdminQuery(instancePtr, queryHandle, adminQuery)
	End Method

	Method AddContentDescriptor:Int(updateHandle:ULong, descriptor:EUGCContentDescriptorID)
		Return bmx_SteamAPI_ISteamUGC_AddContentDescriptor(instancePtr, updateHandle, descriptor)
	End Method

	Method RemoveContentDescriptor:Int(updateHandle:ULong, descriptor:EUGCContentDescriptorID)
		Return bmx_SteamAPI_ISteamUGC_RemoveContentDescriptor(instancePtr, updateHandle, descriptor)
	End Method

	Method SetRequiredGameVersions:Int(updateHandle:ULong, minimum:String, maximum:String)
		Return bmx_SteamAPI_ISteamUGC_SetRequiredGameVersions(instancePtr, updateHandle, minimum, maximum)
	End Method

	Method GetUserContentDescriptorPreferences:UInt(descriptors:EUGCContentDescriptorID Ptr, maxEntries:UInt)
		Return bmx_SteamAPI_ISteamUGC_GetUserContentDescriptorPreferences(instancePtr, descriptors, maxEntries)
	End Method

	Method SetItemsDisabledLocally:Int(publishedFileIDs:ULong Ptr, count:UInt, disabled:Int)
		Return bmx_SteamAPI_ISteamUGC_SetItemsDisabledLocally(instancePtr, publishedFileIDs, count, disabled)
	End Method

	Method SetSubscriptionsLoadOrder:Int(publishedFileIDs:ULong Ptr, count:UInt)
		Return bmx_SteamAPI_ISteamUGC_SetSubscriptionsLoadOrder(instancePtr, publishedFileIDs, count)
	End Method

	Method MarkDownloadedItemAsUnused:Int(publishedFileID:ULong)
		Return bmx_SteamAPI_ISteamUGC_MarkDownloadedItemAsUnused(instancePtr, publishedFileID)
	End Method

	Method GetNumDownloadedItems:UInt()
		Return bmx_SteamAPI_ISteamUGC_GetNumDownloadedItems(instancePtr)
	End Method

	Method GetDownloadedItems:UInt(publishedFileIDs:ULong Ptr, maxEntries:UInt)
		Return bmx_SteamAPI_ISteamUGC_GetDownloadedItems(instancePtr, publishedFileIDs, maxEntries)
	End Method
	
	Rem
	bbdoc: Gets the users vote status on a workshop item.
	about: Results in a call to #OnGetUserItemVote.
	
	See Also: #SetUserItemVote
	End Rem
	Method GetUserItemVote(publishedFileID:ULong)
		bmx_SteamAPI_ISteamUGC_GetUserItemVote(callbackPtr, publishedFileID)
	End Method
	
	Rem
	bbdoc: Releases a UGC query handle when you are done with it to free up memory.
	returns: Always returns #True.
	End Rem
	Method ReleaseQueryUGCRequest:Int(queryHandle:ULong)
		Return bmx_SteamAPI_ISteamUGC_ReleaseQueryUGCRequest(instancePtr, queryHandle)
	End Method
	
	Rem
	bbdoc: Removes the dependency between the given item and the appid.
	about: This list of dependencies can be retrieved by calling #GetAppDependencies.
	
	Results in a call to #OnRemoveAppDependency.
	
	See Also: #AddAppDependency
	End Rem
	Method RemoveAppDependency(publishedFileID:ULong, appID:UInt)
		bmx_SteamAPI_ISteamUGC_RemoveAppDependency(callbackPtr, publishedFileID, appID)
	End Method
	
	Rem
	bbdoc: Removes a workshop item as a dependency from the specified item.
	about: Results in a call to #OnRemoveUGCDependency.
	
	See Also: #AddDependency
	End Rem
	Method RemoveDependency(parentPublishedFileID:ULong, childPublishedFileID:ULong)
		bmx_SteamAPI_ISteamUGC_RemoveDependency(callbackPtr, parentPublishedFileID, childPublishedFileID)
	End Method
	
	Rem
	bbdoc: Removes a workshop item from the users favorites list.
	about: Results in a call to #OnUserFavoriteItemsListChanged.
	
	See Also: #AddItemToFavorites
	End Rem
	Method RemoveItemFromFavorites(appId:UInt, publishedFileID:ULong)
		bmx_SteamAPI_ISteamUGC_RemoveItemFromFavorites(callbackPtr, appId, publishedFileID)
	End Method
	
	Rem
	bbdoc: Removes an existing key value tag from an item.
	returns: #True upon success, otherwise #False if the UGC update handle is invalid or if you are trying to remove more than 100 key-value tags in a single update.
	about: You can only call this up to 100 times per item update. If you need remove more tags than that you'll need to make subsequent item updates.

	> NOTE: This must be set before you submit the UGC update handle using #SubmitItemUpdate.

	See Also: #AddItemKeyValueTag
	End Rem
	Method RemoveItemKeyValueTags:Int(queryHandle:ULong, key:String)
		Return bmx_SteamAPI_ISteamUGC_RemoveItemKeyValueTags(instancePtr, queryHandle, key)
	End Method
	
	Rem
	bbdoc: Removes an item preview.
	End Rem
	Method RemoveItemPreview:Int(queryHandle:ULong, index:UInt)
		Return bmx_SteamAPI_ISteamUGC_RemoveItemPreview(instancePtr, queryHandle, index)
	End Method
	
	Rem
	bbdoc: Sends a UGC query to Steam.
	about: This must be called with a handle obtained from #CreateQueryUserUGCRequest, #CreateQueryAllUGCRequest, or #CreateQueryUGCDetailsRequest to actually send the request to Steam.
	Before calling this you should use one or more of the following APIs to customize your query:
	#AddRequiredTag, #AddExcludedTag, #SetReturnOnlyIDs, #SetReturnKeyValueTags, #SetReturnLongDescription, #SetReturnMetadata, #SetReturnChildren, #SetReturnAdditionalPreviews,
	#SetReturnTotalOnly, #SetLanguage, #SetAllowCachedResponse, #SetCloudFileNameFilter, #SetMatchAnyTag, #SetSearchText, #SetRankedByTrendDays, 
	#AddRequiredKeyValueTag

	Results in a call to #OnSteamUGCQueryCompleted.
	End Rem
	Method SendQueryUGCRequest(queryHandle:ULong)
		bmx_SteamAPI_ISteamUGC_SendQueryUGCRequest(callbackPtr, queryHandle)
	End Method

	Rem
	bbdoc: Sets whether results will be returned from the cache for the specific period of time on a pending UGC Query.
	returns: #True upon success, #False if the UGC query handle is invalid.
	about: 

	> NOTE: This must be set before you send a UGC Query handle using #SendQueryUGCRequest.

	End Rem
	Method SetAllowCachedResponse:Int(queryHandle:ULong, maxAgeSeconds:UInt)
		Return bmx_SteamAPI_ISteamUGC_SetAllowCachedResponse(instancePtr, queryHandle, maxAgeSeconds)
	End Method
	
	Rem
	bbdoc: Sets to only return items that have a specific filename on a pending UGC Query.
	returns: #True upon success, otherwise #False if the UGC query handle is invalid, if the UGC query handle is not from #CreateQueryUserUGCRequest or if @matchCloudFileName is not set.
	about:
	> NOTE: This can only be used with #CreateQueryUserUGCRequest!

	> NOTE: This must be set before you send a UGC Query handle using #SendQueryUGCRequest.
	End Rem
	Method SetCloudFileNameFilter:Int(queryHandle:ULong, matchCloudFileName:String)
		Return bmx_SteamAPI_ISteamUGC_SetCloudFileNameFilter(instancePtr, queryHandle, matchCloudFileName)
	End Method
	
	Rem
	bbdoc: Sets the folder that will be stored as the content for an item.
	returns: #True upon success, #False if the UGC update handle is invalid.
	about: For efficient upload and download, files should not be merged or compressed into single files (e.g. zip files).

	> NOTE: This must be set before you submit the UGC update handle using SubmitItemUpdate.
	End Rem
	Method SetItemContent:Int(updateHandle:ULong, contentFolder:String)
		Return bmx_SteamAPI_ISteamUGC_SetItemContent(instancePtr, updateHandle, contentFolder)
	End Method
	
	Rem
	bbdoc: Sets a new description for an item.
	returns: #True upon success, otherwise #False if the UGC update handle is invalid.
	about: The description must be limited to the length defined by #k_cchPublishedDocumentDescriptionMax.

	You can set what language this is for by using #SetItemUpdateLanguage, if no language is set then "english" is assumed.

	> NOTE: This must be set before you submit the UGC update handle using SubmitItemUpdate.
	
	See Also: #SetReturnLongDescription
	End Rem
	Method SetItemDescription:Int(updateHandle:ULong, description:String)
		Return bmx_SteamAPI_ISteamUGC_SetItemDescription(instancePtr, updateHandle, description)
	End Method
	
	Rem
	bbdoc: Sets arbitrary metadata for an item.
	returns: #True upon success, otherwise #False if the UGC update handle is invalid, or if @metadata is longer than #k_cchDeveloperMetadataMax.
	about: This metadata can be returned from queries without having to download and install the actual content.

	The metadata must be limited to the size defined by #k_cchDeveloperMetadataMax.

	> NOTE: This must be set before you submit the UGC update handle using #SubmitItemUpdate.

	See Also: #SetReturnMetadata
	End Rem
	Method SetItemMetadata:Int(updateHandle:ULong, metaData:String)
		Return bmx_SteamAPI_ISteamUGC_SetItemMetadata(instancePtr, updateHandle, metaData)
	End Method
	
	Rem
	bbdoc: Sets the primary preview image for the item.
	returns: #True upon success, otherwise #False if the UGC update handle is invalid.
	about: The format should be one that both the web and the application (if necessary) can render. Suggested formats include JPG, PNG and GIF.

	> NOTE: This must be set before you submit the UGC update handle using #SubmitItemUpdate.
	End Rem
	Method SetItemPreview:Int(updateHandle:ULong, previewFile:String)
		Return bmx_SteamAPI_ISteamUGC_SetItemPreview(instancePtr, updateHandle, previewFile)
	End Method
	
	Rem
	bbdoc: Sets arbitrary developer specified tags on an item.
	returns: #True upon success, otherwise #False if the UGC update handle is invalid, or if one of the tags is invalid either due to exceeding the maximum length or because it is empty.
	about: Each tag must be limited to 255 characters. Tag names can only include printable characters, excluding ','. For reference on what characters are allowed, refer to http://en.cppreference.com/w/c/string/byte/isprint

	> NOTE: This must be set before you submit the UGC update handle using #SubmitItemUpdate.
	End Rem
	Method SetItemTags:Int(updateHandle:ULong, tags:String[], allowAdminTags:Int = False)
		Return bmx_SteamAPI_ISteamUGC_SetItemTags(instancePtr, updateHandle, tags, allowAdminTags)
	End Method
	
	Rem
	bbdoc: Sets a new title for an item.
	returns: #True upon success, otherwise #False if the UGC update handle is invalid.
	about: The title must be limited to the size defined by #k_cchPublishedDocumentTitleMax.

	You can set what language this is for by using #SetItemUpdateLanguage, if no language is set then "english" is assumed.

	> NOTE: This must be set before you submit the UGC update handle using #SubmitItemUpdate.
	End Rem
	Method SetItemTitle:Int(updateHandle:ULong, title:String)
		Return bmx_SteamAPI_ISteamUGC_SetItemTitle(instancePtr, updateHandle, title)
	End Method
	
	Rem
	bbdoc: Sets the language of the title and description that will be set in this item update.
	returns: #True upon success, otherwise #False if the UGC update handle is invalid.
	about: This must be in the format of the API language code.

	If this is not set then "english" is assumed.

	> NOTE: This must be set before you submit the UGC update handle using #SubmitItemUpdate.
	
	See Also: #SetItemTitle, #SetItemDescription, #SetLanguage
	End Rem
	Method SetItemUpdateLanguage:Int(updateHandle:ULong, language:String)
		Return bmx_SteamAPI_ISteamUGC_SetItemUpdateLanguage(instancePtr, updateHandle, language)
	End Method
	
	Rem
	bbdoc: Sets the visibility of an item.
	returns: #True upon success, otherwise #False if the UGC update handle is invalid.

	about: 
	> NOTE: This must be set before you submit the UGC update handle using #SubmitItemUpdate.
	End Rem
	Method SetItemVisibility:Int(updateHandle:ULong, visibility:ERemoteStoragePublishedFileVisibility)
		Return bmx_SteamAPI_ISteamUGC_SetItemVisibility(instancePtr, updateHandle, visibility)
	End Method
	
	Rem
	bbdoc: Sets the language to return the title and description in for the items on a pending UGC Query.
	returns: #True upon success, otherwise #False if the UGC query handle is invalid.
	about: This must be in the format of the API Language code.

	If this is not set then "english" is assumed.

	> NOTE: This must be set before you send a UGC Query handle using #SendQueryUGCRequest.
	
	See Also: #SetItemUpdateLanguage
	End Rem
	Method SetLanguage:Int(queryHandle:ULong, language:String)
		Return bmx_SteamAPI_ISteamUGC_SetLanguage(instancePtr, queryHandle, language)
	End Method
	
	Rem
	bbdoc: Sets whether workshop items will be returned if they have one or more matching tag, or if all tags need to match on a pending UGC Query.
	returns: #True upon success, otherwise #False if the UGC query handle is invalid or if the UGC query handle is not from #CreateQueryAllUGCRequest.
	about: 
	> NOTE: This can only be used with #CreateQueryAllUGCRequest!

	> NOTE: This must be set before you send a UGC Query handle using #SendQueryUGCRequest.
	
	See Also: #AddRequiredTag, #AddExcludedTag, #SetItemTags
	End Rem
	Method SetMatchAnyTag:Int(queryHandle:ULong, matchAnyTag:Int)
		Return bmx_SteamAPI_ISteamUGC_SetMatchAnyTag(instancePtr, queryHandle, matchAnyTag)
	End Method
	
	Rem
	bbdoc: Sets whether the order of the results will be updated based on the rank of items over a number of days on a pending UGC Query.
	returns: #True upon success, otherwise #False if the UGC query handle is invalid, if the UGC query handle is not from #CreateQueryAllUGCRequest or if the #EUGCQuery of the query is not one of k_PublishedFileQueryType_RankedByTrend, k_PublishedFileQueryType_RankedByPlaytimeTrend, k_PublishedFileQueryType_RankedByAveragePlaytimeTrend, k_PublishedFileQueryType_RankedByVotesUp, or k_PublishedFileQueryType_RankedByPlaytimeSessionsTrend.
	about:
	> NOTE: This can only be used with #CreateQueryAllUGCRequest!

	> NOTE: This must be set before you send a UGC Query handle using #SendQueryUGCRequest.
	End Rem
	Method SetRankedByTrendDays:Int(queryHandle:ULong, days:UInt)
		Return bmx_SteamAPI_ISteamUGC_SetRankedByTrendDays(instancePtr, queryHandle, days)
	End Method
	
	Rem
	bbdoc: Sets whether to return any additional images/videos attached to the items on a pending UGC Query.
	returns: #True upon success, otherwise #False if the UGC query handle is invalid.
	about: 
	> NOTE: This must be set before you send a UGC Query handle using #SendQueryUGCRequest.
	End Rem
	Method SetReturnAdditionalPreviews:Int(queryHandle:ULong, returnAdditionalPreviews:Int)
		Return bmx_SteamAPI_ISteamUGC_SetReturnAdditionalPreviews(instancePtr, queryHandle, returnAdditionalPreviews)
	End Method
	
	Rem
	bbdoc: Sets whether to return the IDs of the child items of the items on a pending UGC Query.
	returns: #True upon success, otherwise #False if the UGC query handle is invalid.
	about: 
	> NOTE: This must be set before you send a UGC Query handle using #SendQueryUGCRequest.
	End Rem
	Method SetReturnChildren:Int(queryHandle:ULong, returnChildren:Int)
		Return bmx_SteamAPI_ISteamUGC_SetReturnChildren(instancePtr, queryHandle, returnChildren)
	End Method
	
	Rem
	bbdoc: Sets whether to return any key-value tags for the items on a pending UGC Query.
	returns: #True upon success, #False if the UGC query handle is invalid.
	about: 
	> NOTE: This must be set before you send a UGC Query handle using #SendQueryUGCRequest.
	End Rem
	Method SetReturnKeyValueTags:Int(queryHandle:ULong, returnKeyValueTags:Int)
		Return bmx_SteamAPI_ISteamUGC_SetReturnKeyValueTags(instancePtr, queryHandle, returnKeyValueTags)
	End Method

	Rem
	bbdoc: Sets whether to return the full description for the items on a pending UGC Query.
	returns: #True upon success, otherwise #False if the UGC query handle is invalid.
	about: If you don't set this then you only receive the summary which is the description truncated at 255 bytes.

	> NOTE: This must be set before you send a UGC Query handle using #SendQueryUGCRequest.
	
	See Also: #SetItemDescription
	End Rem
	Method SetReturnLongDescription:Int(queryHandle:ULong, returnLongDescription:Int)
		Return bmx_SteamAPI_ISteamUGC_SetReturnLongDescription(instancePtr, queryHandle, returnLongDescription)
	End Method
	
	Rem
	bbdoc: Sets whether to return the developer specified metadata for the items on a pending UGC Query.
	returns: #True upon success, #False if the UGC query handle is invalid.
	about: 
	> NOTE: This must be set before you send a UGC Query handle using #SendQueryUGCRequest.
	
	See Also: #SetItemMetadata
	End Rem
	Method SetReturnMetadata:Int(queryHandle:ULong, returnMetadata:Int)
		Return bmx_SteamAPI_ISteamUGC_SetReturnMetadata(instancePtr, queryHandle, returnMetadata)
	End Method
	
	Rem
	bbdoc: Sets whether to only return IDs instead of all the details on a pending UGC Query.
	returns: #True upon success, otherwise #False if the UGC query handle is invalid or if the UGC query handle is from #CreateQueryUGCDetailsRequest.

	about: 
	This is useful for when you don't need all the information (e.g. you just want to get the IDs of the items a user has in their favorites list.)

	> NOTE: This must be set before you send a UGC Query handle using #SendQueryUGCRequest.
	End Rem
	Method SetReturnOnlyIDs:Int(queryHandle:ULong, returnOnlyIDs:Int)
		Return bmx_SteamAPI_ISteamUGC_SetReturnOnlyIDs(instancePtr, queryHandle, returnOnlyIDs)
	End Method
	
	Rem
	bbdoc: Sets whether to return the the playtime stats on a pending UGC Query.
	returns: #True upon success, otherwise #False if the UGC query handle is invalid.
	about: 
	> NOTE: This must be set before you send a UGC Query handle using #SendQueryUGCRequest.
	End Rem
	Method SetReturnPlaytimeStats:Int(queryHandle:ULong, days:UInt)
		Return bmx_SteamAPI_ISteamUGC_SetReturnPlaytimeStats(instancePtr, queryHandle, days)
	End Method
	
	Rem
	bbdoc: Sets whether to only return the the total number of matching items on a pending UGC Query.
	returns: #True upon success, #False if the UGC query handle is invalid or if the UGC query handle is from #CreateQueryUGCDetailsRequest.
	about: The actual items will not be returned when #OnSteamUGCQueryCompleted is called.

	> NOTE: This must be set before you send a UGC Query handle using #SendQueryUGCRequest.
	End Rem
	Method SetReturnTotalOnly:Int(queryHandle:ULong, returnTotalOnly:Int)
		Return bmx_SteamAPI_ISteamUGC_SetReturnTotalOnly(instancePtr, queryHandle, returnTotalOnly)
	End Method
	
	Rem
	bbdoc: Sets a string to that items need to match in either the title or the description on a pending UGC Query.
	returns: #True upon success, #False if the UGC query handle is invalid, if the UGC query handle is not from #CreateQueryAllUGCRequest or if @searchText is empty.
	about: 
	> NOTE: This can only be used with #CreateQueryAllUGCRequest!

	> NOTE: This must be set before you send a UGC Query handle using #SendQueryUGCRequest.
	End Rem
	Method SetSearchText:Int(queryHandle:ULong, searchText:String)
		Return bmx_SteamAPI_ISteamUGC_SetSearchText(instancePtr, queryHandle, searchText)
	End Method
	
	Rem
	bbdoc: Allows the user to rate a workshop item up or down.
	about: Results in a call to #OnSetUserItemVote.
	
	See Also: #GetUserItemVote
	End Rem
	Method SetUserItemVote(publishedFileID:ULong, voteUp:Int)
		bmx_SteamAPI_ISteamUGC_SetUserItemVote(callbackPtr, publishedFileID, voteUp)
	End Method
	
	Rem
	bbdoc: Starts the item update process.
	returns: A handle that you can use with future calls to modify the item before finally sending the update.
	about: This gets you a handle that you can use to modify the item before finally sending off the update to the server with #SubmitItemUpdate.
	
	See Also: Uploading a Workshop Item, #SetItemTitle, #SetItemDescription, #SetItemUpdateLanguage, #SetItemMetadata, #SetItemVisibility, #SetItemTags, #SetItemContent, #SetItemPreview, #RemoveItemKeyValueTags, #AddItemKeyValueTag, #AddItemPreviewFile, #AddItemPreviewVideo, #UpdateItemPreviewFile, #UpdateItemPreviewVideo, #RemoveItemPreview
	End Rem
	Method StartItemUpdate:ULong(consumerAppId:UInt, publishedFileID:ULong)
		Return bmx_SteamAPI_ISteamUGC_StartItemUpdate(instancePtr, consumerAppId, publishedFileID)
	End Method
	
	Rem
	bbdoc: Starts tracking playtime on a set of workshop items.
	about: When your app shuts down, playtime tracking will automatically stop.

	Results in a call to #OnStartPlaytimeTracking
	
	See Also: #StopPlaytimeTracking, #StopPlaytimeTrackingForAllItems
	End Rem
	Method StartPlaytimeTracking(publishedFileIDs:ULong Ptr, numPublishedFileIDs:UInt)
		bmx_SteamAPI_ISteamUGC_StartPlaytimeTracking(callbackPtr, publishedFileIDs, numPublishedFileIDs)
	End Method
	
	Rem
	bbdoc: Stops tracking playtime on a set of workshop items.
	about: When your app shuts down, playtime tracking will automatically stop.
	
	Results in a call to #OnStopPlaytimeTracking
	End Rem
	Method StopPlaytimeTracking(publishedFileIDs:ULong Ptr, numPublishedFileIDs:UInt)
		bmx_SteamAPI_ISteamUGC_StopPlaytimeTracking(callbackPtr, publishedFileIDs, numPublishedFileIDs)
	End Method
	
	Rem
	bbdoc: Stops tracking playtime of all workshop items.
	about: When your app shuts down, playtime tracking will automatically stop.

	Results in a call to #OnStopPlaytimeTracking
	End Rem
	Method StopPlaytimeTrackingForAllItems()
		bmx_SteamAPI_ISteamUGC_StopPlaytimeTrackingForAllItems(callbackPtr)
	End Method
	
	Rem
	bbdoc: Uploads the changes made to an item to the Steam Workshop.
	about: You can track the progress of an item update with #GetItemUpdateProgress.

	Results in a call to #OnSubmitItemUpdate
	End Rem
	Method SubmitItemUpdate(updateHandle:ULong, changeNote:String)
		bmx_SteamAPI_ISteamUGC_SubmitItemUpdate(callbackPtr, updateHandle, changeNote)
	End Method
	
	Rem
	bbdoc: Subscribe to a workshop item. It will be downloaded and installed as soon as possible.
	about: Results in a call to #OnRemoteStorageSubscribePublishedFile
	
	See Also: #SubscribeItem
	End Rem
	Method SubscribeItem(publishedFileID:ULong)
		bmx_SteamAPI_ISteamUGC_SubscribeItem(callbackPtr, publishedFileID)
	End Method
	
	Rem
	bbdoc: Suspends and resumes all workshop downloads.
	about: If you call this with @suspend set to #True then downloads will be suspended until you resume them by setting @suspend to #False or when the game ends.
	End Rem
	Method SuspendDownloads(suspend:Int)
		bmx_SteamAPI_ISteamUGC_SuspendDownloads(instancePtr, suspend)
	End Method
	
	Rem
	bbdoc: Unsubscribes from a workshop item.
	about: This will result in the item being removed after the game quits.

	Results in a call to #OnRemoteStorageUnsubscribePublishedFile
	
	See Also: #UnsubscribeItem
	End Rem
	Method UnsubscribeItem(publishedFileID:ULong)
		bmx_SteamAPI_ISteamUGC_UnsubscribeItem(callbackPtr, publishedFileID)
	End Method
	
	Rem
	bbdoc: Updates an existing additional preview file for the item.
	returns: #True upon success, otherwise #False if the UGC update handle is invalid.
	about: If the preview type is an image then the format should be one that both the web and the application (if necessary) can render, and must be under 1MB.
	Suggested formats include JPG, PNG and GIF.

	> NOTE: This must be set before you submit the UGC update handle using #SubmitItemUpdate.

	See Also: #AddItemPreviewFile
	End Rem
	Method UpdateItemPreviewFile:Int(updateHandle:ULong, index:UInt, previewFile:String)
		Return bmx_SteamAPI_ISteamUGC_UpdateItemPreviewFile(instancePtr, updateHandle, index, previewFile)
	End Method
	
	Rem
	bbdoc: Updates an additional video preview from YouTube for the item.
	returns: #True upon success, otherwise #False if the UGC update handle is invalid.
	about: 
	> NOTE: This must be set before you submit the UGC update handle using #SubmitItemUpdate.

	See Also: #AddItemPreviewVideo
	End Rem
	Method UpdateItemPreviewVideo:Int(updateHandle:ULong, index:UInt, videoID:String)
		Return bmx_SteamAPI_ISteamUGC_UpdateItemPreviewVideo(instancePtr, updateHandle, index, videoID)
	End Method
	
	' callbacks
	Private

	Method OnAddAppDependency(result:EResult, publishedFileId:ULong, appID:UInt)
		If listener Then
			listener.OnAddAppDependency(result, publishedFileId, appID)
		End If
	End Method

	Function _OnAddAppDependency(inst:TSteamUGC, result:EResult, publishedFileId:ULong, appID:UInt) { nomangle }
		inst.OnAddAppDependency(result, publishedFileId, appID)
	End Function 

	Method OnAddDependency(result:EResult, publishedFileId:ULong, childPublishedFileId:ULong)
		If listener Then
			listener.OnAddDependency(result, publishedFileId, childPublishedFileId)
		End If
	End Method

	Function _OnAddDependency(inst:TSteamUGC, result:EResult, publishedFileId:ULong, childPublishedFileId:ULong) { nomangle }
		inst.OnAddDependency(result, publishedFileId, childPublishedFileId)
	End Function

	Method OnUserFavoriteItemsListChanged(result:EResult, publishedFileId:ULong, wasAddRequest:Int)
		If listener Then
			listener.OnUserFavoriteItemsListChanged(result, publishedFileId, wasAddRequest)
		End If
	End Method
	
	Function _OnUserFavoriteItemsListChanged(inst:TSteamUGC, publishedFileId:ULong, result:EResult, wasAddRequest:Int) { nomangle }
		inst.OnUserFavoriteItemsListChanged(result, publishedFileId, wasAddRequest)
	End Function

	Method OnCreateItem(result:EResult, publishedFileId:ULong, userNeedsToAcceptWorkshopLegalAgreement:Int)
		If listener Then
			listener.OnCreateItem(result, publishedFileId, userNeedsToAcceptWorkshopLegalAgreement)
		End If
	End Method

	Function _OnCreateItem(inst:TSteamUGC, result:EResult, publishedFileId:ULong, userNeedsToAcceptWorkshopLegalAgreement:Int) { nomangle }
		inst.OnCreateItem(result, publishedFileId, userNeedsToAcceptWorkshopLegalAgreement)
	End Function

	Method OnDeleteItem(result:EResult, publishedFileId:ULong)
		If listener Then
			listener.OnDeleteItem(result, publishedFileId)
		End If
	End Method

	Function _OnDeleteItem(inst:TSteamUGC, result:EResult, publishedFileId:ULong) { nomangle }
		inst.OnDeleteItem(result, publishedFileId)
	End Function

	Method OnDownloadItem(result:EResult, appID:UInt, publishedFileId:ULong)
		If listener Then
			listener.OnDownloadItem(result, appID, publishedFileId)
		End If
	End Method
	
	Function _OnDownloadItem(inst:TSteamUGC, result:EResult, appID:UInt, publishedFileId:ULong) { nomangle }
		inst.OnDownloadItem(result, appID, publishedFileId)
	End Function 

	Method OnGetUserItemVote(result:EResult, publishedFileId:ULong, votedUp:Int, votedDown:Int, voteSkipped:Int)
		If listener Then
			listener.OnGetUserItemVote(result, publishedFileId, votedUp, votedDown, voteSkipped)
		End If
	End Method

	Function _OnGetUserItemVote(inst:TSteamUGC, publishedFileId:ULong, result:EResult, votedUp:Int, votedDown:Int, voteSkipped:Int) { nomangle }
		inst.OnGetUserItemVote(result, publishedFileId, votedUp, votedDown, voteSkipped)
	End Function
	
	Method OnItemInstalled(appID:UInt, publishedFileId:ULong)
		If listener Then
			listener.OnItemInstalled(appID, publishedFileId)
		End If
	End Method
	
	Function _OnItemInstalled(inst:TSteamUGC, appID:UInt, publishedFileId:ULong) { nomangle }
		inst.OnItemInstalled(appID, publishedFileId)
	End Function

	Method OnRemoveAppDependency(result:EResult, publishedFileId:ULong, appID:UInt)
		If listener Then
			listener.OnRemoveAppDependency(result, publishedFileId, appID)
		End If
	End Method

	Function _OnRemoveAppDependency(inst:TSteamUGC, result:EResult, publishedFileId:ULong, appID:UInt) { nomangle }
		inst.OnRemoveAppDependency(result, publishedFileId, appID)
	End Function

	Method OnRemoveUGCDependency(result:EResult, publishedFileId:ULong, childPublishedFileId:ULong)
		If listener Then
			listener.OnRemoveUGCDependency(result, publishedFileId, childPublishedFileId)
		End If
	End Method

	Function _OnRemoveUGCDependency(inst:TSteamUGC, result:EResult, publishedFileId:ULong, childPublishedFileId:ULong) { nomangle }
		inst.OnRemoveUGCDependency(result, publishedFileId, childPublishedFileId)
	End Function

	Method OnSteamUGCQueryCompleted(result:EResult, queryHandle:ULong, numResultsReturned:UInt, totalMatchingResults:UInt)
		If listener Then
			listener.OnSteamUGCQueryCompleted(result, queryHandle, numResultsReturned, totalMatchingResults)
		End If
	End Method

	Function _OnSteamUGCQueryCompleted(inst:TSteamUGC, queryHandle:ULong, result:EResult, numResultsReturned:UInt, totalMatchingResults:UInt) { nomangle }
		inst.OnSteamUGCQueryCompleted(result, queryHandle, numResultsReturned, totalMatchingResults)
	End Function

	Method OnSetUserItemVote(result:EResult, publishedFileId:ULong, voteUp:Int)
		If listener Then
			listener.OnSetUserItemVote(result, publishedFileId, voteUp)
		End If
	End Method

	Function _OnSetUserItemVote(inst:TSteamUGC, publishedFileId:ULong, result:EResult, voteUp:Int) { nomangle }
		inst.OnSetUserItemVote(result, publishedFileId, voteUp)
	End Function

	Method OnStartPlaytimeTracking(result:EResult)
		If listener Then
			listener.OnStartPlaytimeTracking(result)
		End If
	End Method

	Function _OnStartPlaytimeTracking(inst:TSteamUGC, result:EResult) { nomangle }
		inst.OnStartPlaytimeTracking(result)
	End Function

	Method OnStopPlaytimeTracking(result:EResult)
		If listener Then
			listener.OnStopPlaytimeTracking(result)
		End If
	End Method

	Function _OnStopPlaytimeTracking(inst:TSteamUGC, result:EResult) { nomangle }
		inst.OnStopPlaytimeTracking(result)
	End Function

	Method OnGetAppDependencies(result:EResult, publishedFileId:ULong, appID:UInt Ptr, numAppDependencies:Int, totalNumAppDependencies:Int)
		If listener Then
			listener.OnGetAppDependencies(result, publishedFileId, appID, numAppDependencies, totalNumAppDependencies)
		End If
	End Method

	Function _OnGetAppDependencies(inst:TSteamUGC, result:EResult, publishedFileId:ULong, appID:UInt Ptr, numAppDependencies:Int, totalNumAppDependencies:Int) { nomangle }
		inst.OnGetAppDependencies(result, publishedFileId, appID, numAppDependencies, totalNumAppDependencies)
	End Function

	Method OnSubmitItemUpdate(result:EResult, userNeedsToAcceptWorkshopLegalAgreement:Int)
		If listener Then
			listener.OnSubmitItemUpdate(result, userNeedsToAcceptWorkshopLegalAgreement)
		End If
	End Method

	Function _OnSubmitItemUpdate(inst:TSteamUGC, result:EResult, userNeedsToAcceptWorkshopLegalAgreement:Int) { nomangle }
		inst.OnSubmitItemUpdate(result, userNeedsToAcceptWorkshopLegalAgreement)
	End Function

	Method OnRemoteStorageSubscribePublishedFile(result:EResult, publishedFileId:ULong)
		If listener Then
			listener.OnRemoteStorageSubscribePublishedFile(result, publishedFileId)
		End If
	End Method

	Function _OnRemoteStorageSubscribePublishedFile(inst:TSteamUGC, result:EResult, publishedFileId:ULong) { nomangle }
		inst.OnRemoteStorageSubscribePublishedFile(result, publishedFileId)
	End Function

	Method OnRemoteStorageUnsubscribePublishedFile(result:EResult, publishedFileId:ULong)
		If listener Then
			listener.OnRemoteStorageUnsubscribePublishedFile(result, publishedFileId)
		End If
	End Method

	Function _OnRemoteStorageUnsubscribePublishedFile(inst:TSteamUGC, result:EResult, publishedFileId:ULong) { nomangle }
		inst.OnRemoteStorageUnsubscribePublishedFile(result, publishedFileId)
	End Function

	Method OnWorkshopEULAStatus(result:EResult, appID:UInt, version:UInt, actionTime:UInt, accepted:Int, needsAction:Int, ioFailure:Int)
		Local extended:ISteamUGCEULAListener = ISteamUGCEULAListener(listener)
		If extended Then extended.OnWorkshopEULAStatus(result, appID, version, actionTime, accepted, needsAction, ioFailure)
	End Method

	Function _OnWorkshopEULAStatus(inst:TSteamUGC, result:EResult, appID:UInt, version:UInt, actionTime:UInt, accepted:Int, needsAction:Int, ioFailure:Int) { nomangle }
		inst.OnWorkshopEULAStatus(result, appID, version, actionTime, accepted, needsAction, ioFailure)
	End Function

End Type

Rem
bbdoc: Steam Friends listener interface
about: Implement this and add as a listener to an instance of #TSteamFriends to receive appropriate event callbacks.
End Rem
Interface ISteamFriendsListener

	Rem
	bbdoc: Called when a large avatar is loaded if you have tried requesting it when it was unavailable.
	End Rem
	Method OnAvatarImageLoaded(steamID:ULong, image:Int, width:Int, height:Int)
	Rem
	bbdoc: Called when Rich Presence data has been updated for a user.
	about: This can happen automatically when friends in the same game update their rich presence, or after a call to #RequestFriendRichPresence.
	End Rem
	Method OnFriendRichPresenceUpdated(steamIDFriend:ULong, appID:UInt)
	Rem
	bbdoc: Called when a user has left a Steam group chat that the we are in.
	End Rem
	Method OnGameConnectedChatLeave(steamIDClanChat:ULong, steamIDUser:ULong, kicked:Int, dropped:Int)
	Rem
	bbdoc: Called when chat message has been received from a friend.
	about: 
	Associated Functions: #SetListenForFriendsMessages
	End Rem
	Method OnGameConnectedFriendChatMsg(steamIDUser:ULong, messageID:Int)
	Rem
	bbdoc: Called when the user tries to join a lobby from their friends list or from an invite.
	about: The game client should attempt to connect to specified lobby when this is received.
	If the game isn't running yet then the game will be automatically launched with the command line parameter +connect_lobby &lt;64-bit lobby Steam ID&gt; instead.

	> NOTE: This callback is made when joining a lobby. If the user is attempting to join a game but not a lobby, then the callback #OnGameRichPresenceJoinRequested will be made.
	End Rem
	Method OnGameLobbyJoinRequested(steamIDLobby:ULong, steamIDFriend:ULong)
	Rem
	bbdoc: Posted when the Steam Overlay activates or deactivates.
	about: The game can use this to be pause or resume single player games.
	End Rem
	Method OnGameOverlayActivated(active:Int)
	Rem
	bbdoc: Called when the user tries to join a game from their friends list or after a user accepts an invite by a friend with #InviteUserToGame.
	about:
	> NOTE : This callback is made when joining a game. If the user is attempting to join a lobby, then the callback #OnGameLobbyJoinRequested will be made.
	End Rem
	Method OnGameRichPresenceJoinRequested(steamIDFriend:ULong, connect:String)
	Rem
	bbdoc: Called when the user tries to join a different game server from their friends list.
	about: The game client should attempt to connect to specified server when this is received.
	End Rem
	Method OnGameServerChangeRequested(server:String, password:String)
	Rem
	bbdoc: Called whenever a friends' status changes.
	End Rem
	Method OnPersonaStateChanged(steamID:ULong, changeFlags:Int)
	Rem
	bbdoc: Marks the return of a request officer list call.
	End Rem
	Method OnClanOfficerList(steamIDClan:ULong, officers:Int, success:Int)
	Rem
	bbdoc: Called when a Steam group activity has received.
	End Rem
	Method OnDownloadClanActivityCounts(success:Int)
	Rem
	bbdoc: Returns the result of #EnumerateFollowingList.
	End Rem
	Method OnFriendsEnumerateFollowingList(result:EResult, steamIDS:ULong Ptr, resultsReturned:Int, totalResultCount:Int)
	Rem
	bbdoc: Returns the result of #GetFollowerCount.
	End Rem
	Method OnFriendsGetFollowerCount(result:EResult, steamID:ULong, count:Int)
	Rem
	bbdoc: Returns the result of #IsFollowing.
	End Rem
	Method OnFriendsIsFollowing(result:EResult, steamID:ULong, isFollowing:Int)
	Rem
	bbdoc: Called when a user has joined a Steam group chat that the we are in.
	End Rem
	Method OnGameConnectedChatJoined(steamIDClanChat:ULong, steamIDUser:ULong)
	Rem
	bbdoc: Called when a chat message has been received in a Steam group chat that we are in.
	End Rem
	Method OnGameConnectedClanChatMsg(steamIDClanChat:ULong, steamIDUser:ULong, messageID:Int)
	Rem
	bbdoc: Posted when the user has attempted to join a Steam group chat via #JoinClanChatRoom.
	End Rem
	Method OnJoinClanChatRoomCompletion(steamIDClanChat:ULong, chatRoomEnterResponse:EChatRoomEnterResponse)
	Method OnEquippedProfileItemsChanged(steamID:ULong)
	Method OnEquippedProfileItems(result:EResult, steamID:ULong, animatedAvatar:Int, avatarFrame:Int, profileModifier:Int, profileBackground:Int, miniProfileBackground:Int, fromCache:Int)
End Interface

Rem
bbdoc: Interface to access information about individual users and interact with the Steam Overlay.
End Rem
Type TSteamFriends Extends TSteamAPI

	Const STEAMFRIENDS_INTERFACE_VERSION:String = "SteamFriends018"

	Field listener:ISteamFriendsListener

	Function _create:TSteamFriends(instancePtr:Byte Ptr)
		Local this:TSteamFriends = New TSteamFriends
		this.instancePtr = instancePtr

		this.callbackPtr = bmx_steamsdk_register_steamfriends(instancePtr, this)

		Return this
	End Function

	Method Delete()
		bmx_steamsdk_unregister_steamfriends(callbackPtr)
	End Method

	Rem
	bbdoc: Sets the steam utils callback listener.
	about: Once installed, the listener will receive utils events via the callback methods.
	End Rem
	Method SetListener(listener:ISteamFriendsListener)
		Self.listener = listener
	End Method

	Rem
	bbdoc: Activates the Steam Overlay to a specific dialog.
	about: This is equivalent to calling #ActivateGameOverlayToUser with steamID set to ISteamUser::GetSteamID.
	Valid options are: "friends", "community", "players", "settings", "officialgamegroup", "stats", "achievements".
	End Rem
	Method ActivateGameOverlay(dialog:String)
		bmx_SteamAPI_ISteamFriends_ActivateGameOverlay(instancePtr, dialog)
	End Method
	
	Rem
	bbdoc: Activates the [Steam Overlay](https://partner.steamgames.com/doc/features/overlay) to open the invite dialog.
	about: Invitations sent from this dialog will be for the provided lobby.
	End Rem
	Method ActivateGameOverlayInviteDialog(steamIDLobby:ULong)
		bmx_SteamAPI_ISteamFriends_ActivateGameOverlayInviteDialog(instancePtr, steamIDLobby)
	End Method

	Rem
	bbdoc: Opens the friend invite overlay using a rich-presence connection string.
	End Rem
	Method ActivateGameOverlayInviteDialogConnectString(connectString:String)
		bmx_SteamAPI_ISteamFriends_ActivateGameOverlayInviteDialogConnectString(instancePtr, connectString)
	End Method

	Rem
	bbdoc: Opens the Remote Play Together invite overlay for a lobby.
	End Rem
	Method ActivateGameOverlayRemotePlayTogetherInviteDialog(steamIDLobby:ULong)
		bmx_SteamAPI_ISteamFriends_ActivateGameOverlayRemotePlayTogetherInviteDialog(instancePtr, steamIDLobby)
	End Method

	Rem
	bbdoc: Returns the number of chats containing unread priority messages.
	End Rem
	Method GetNumChatsWithUnreadPriorityMessages:Int()
		Return bmx_SteamAPI_ISteamFriends_GetNumChatsWithUnreadPriorityMessages(instancePtr)
	End Method

	Rem
	bbdoc: Registers a custom URL protocol for navigation from Steam's overlay browser.
	End Rem
	Method RegisterProtocolInOverlayBrowser:Int(protocol:String)
		Return bmx_SteamAPI_ISteamFriends_RegisterProtocolInOverlayBrowser(instancePtr, protocol)
	End Method
	
	Rem
	bbdoc: Activates the [Steam Overlay](https://partner.steamgames.com/doc/features/overlay) to the Steam store page for the provided app.
	about: Using k_uAppIdInvalid brings the user to the front page of the Steam store.
	End Rem
	Method ActivateGameOverlayToStore(appID:UInt, flag:EOverlayToStoreFlag )
		bmx_SteamAPI_ISteamFriends_ActivateGameOverlayToStore(instancePtr, appID, flag)
	End Method
	
	Rem
	bbdoc: Activates [Steam Overlay](https://partner.steamgames.com/doc/features/overlay) to a specific dialog.
	about: Valid @dialog options are:
	* "steamid" - Opens the overlay web browser to the specified user or groups profile.
	* "chat" - Opens a chat window to the specified user, or joins the group chat.
	* "jointrade" - Opens a window to a Steam Trading session that was started with the ISteamEconomy/StartTrade Web API.
	* "stats" - Opens the overlay web browser to the specified user's stats.
	* "achievements" - Opens the overlay web browser to the specified user's achievements.
	* "friendadd" - Opens the overlay in minimal mode prompting the user to add the target user as a friend.
	* "friendremove" - Opens the overlay in minimal mode prompting the user to remove the target friend.
	* "friendrequestaccept" - Opens the overlay in minimal mode prompting the user to accept an incoming friend invite.
	* "friendrequestignore" - Opens the overlay in minimal mode prompting the user to ignore an incoming friend invite.
	End Rem
	Method ActivateGameOverlayToUser(dialog:String, steamID:ULong)
		bmx_SteamAPI_ISteamFriends_ActivateGameOverlayToUser(instancePtr, dialog, steamID)
	End Method
	
	Rem
	bbdoc: Activates [Steam Overlay](https://partner.steamgames.com/doc/features/overlay) web browser directly to the specified URL.
	about: A fully qualified address with the protocol is required, e.g. "http://www.steampowered.com"
	End Rem
	Method ActivateGameOverlayToWebPage(url:String)
		bmx_SteamAPI_ISteamFriends_ActivateGameOverlayToWebPage(instancePtr, url)
	End Method
	
	Rem
	bbdoc: Clears all of the current user's Rich Presence key/values.
	End Rem
	Method ClearRichPresence()
		bmx_SteamAPI_ISteamFriends_ClearRichPresence(instancePtr)
	End Method
	
	Rem
	bbdoc: Closes the specified Steam group chat room in the Steam UI.
	returns: #True if the user successfully left the Steam group chat room, otherwise #False if the user is not in the provided Steam group chat room.
	about: 
	See Also: #IsClanChatWindowOpenInSteam, #OpenClanChatWindowInSteam
	End Rem
	Method CloseClanChatWindowInSteam:Int(steamIDClanChat:ULong)
		Return bmx_SteamAPI_ISteamFriends_CloseClanChatWindowInSteam(instancePtr, steamIDClanChat)
	End Method
	
	Rem
	bbdoc: Refreshes the Steam Group activity data or get the data from groups other than one that the current user is a member.
	about: After receiving the callback you can then use #GetClanActivityCounts to get the up to date user counts.
	End Rem
	Method DownloadClanActivityCounts(steamIDClans:ULong Ptr, clansToRequest:Int)
		bmx_SteamAPI_ISteamFriends_DownloadClanActivityCounts(callbackPtr, steamIDClans, clansToRequest)
	End Method
	
	Rem
	bbdoc: Gets the list of users that the current user is following.
	about: You can be following people that are not your friends. Following allows you to receive updates when the person does things like post a new piece of content to the Steam Workshop.

	> NOTE: This returns up to k_cEnumerateFollowersMax users at once. If the current user is following more than that, you will need to call this repeatedly, with unStartIndex set to the total number of followers that you have received so far.
	> i.e. If you have received 50 followers, and the user is following 105, you will need to call this again with unStartIndex = 50 to get the next 50, and then again with unStartIndex = 100 to get the remaining 5 users.
	End Rem
	Method EnumerateFollowingList(startIndex:UInt)
		bmx_SteamAPI_ISteamFriends_EnumerateFollowingList(callbackPtr, startIndex)
	End Method
	
	Rem
	bbdoc: Gets the Steam ID at the given index in a Steam group chat.
	about: 
	> NOTE: You must call #GetClanChatMemberCount before calling this.
	End Rem
	Method GetChatMemberByIndex:ULong(steamIDClan:ULong, user:Int)
		Return bmx_SteamAPI_ISteamFriends_GetChatMemberByIndex(instancePtr, steamIDClan, user)
	End Method
	
	Rem
	bbdoc: Gets the most recent information we have about what the users in a Steam Group are doing.
	returns: #True if the data was successfully returned, otherwise #False if the provided Steam ID is invalid or the local client does not have info about the Steam group and sets all the other parameters to 0.
	about: This can only retrieve data that the local client knows about.
	To refresh the data or get data from a group other than one that the current user is a member of you must call #DownloadClanActivityCounts.
	End Rem
	Method GetClanActivityCounts:Int(steamIDClan:ULong, online:Int Var, inGame:Int Var, chatting:Int Var)
		Return bmx_SteamAPI_ISteamFriends_GetClanActivityCounts(instancePtr, steamIDClan, online, inGame, chatting)
	End Method
	
	Rem
	bbdoc: Gets the Steam group's Steam ID at the given index.
	about: 
	> NOTE: You must call #GetClanCount before calling this.
	End Rem
	Method GetClanByIndex:ULong(clan:Int)
		Return bmx_SteamAPI_ISteamFriends_GetClanByIndex(instancePtr, clan)
	End Method
	
	Rem
	bbdoc: Gets the number of users in a Steam group chat.
	returns: 0 if the Steam ID provided is invalid or if the local user doesn't have the data available.
	about: 
	> NOTE: Large steam groups cannot be iterated by the local user.

	> NOTE: The current user must be in a lobby to retrieve the Steam IDs of other users in that lobby.

	This is used for iteration, after calling this then #GetChatMemberByIndex can be used to get the Steam ID of each person in the chat.
	End Rem
	Method GetClanChatMemberCount:Int(steamIDClan:ULong)
		Return bmx_SteamAPI_ISteamFriends_GetClanChatMemberCount(instancePtr, steamIDClan)
	End Method
	
	Rem
	bbdoc: Gets the data from a Steam group chat room message.
	returns: The number of bytes copied into @txt. Returns 0 and sets @chatEntryType to k_EChatEntryTypeInvalid if the current user is not in the specified Steam group chat room or if the index provided in iMessage is invalid.
	about: This should only ever be called in response to an #OnGameConnectedClanChatMsg callback.
	End Rem
	Method GetClanChatMessage:Int(steamIDClanChat:ULong, message:Int, txt:String Var, chatEntryType:EChatEntryType Var, steamidChatter:ULong Var)
		Return bmx_SteamAPI_ISteamFriends_GetClanChatMessage(instancePtr, steamIDClanChat, message, txt, chatEntryType, steamidChatter)
	End Method
	
	Rem
	bbdoc: Gets the number of Steam groups that the current user is a member of.
	returns: The number of Steam groups that the user is a member of.
	about: This is used for iteration, after calling this then #GetClanByIndex can be used to get the Steam ID of each Steam group.
	End Rem
	Method GetClanCount:Int()
		Return bmx_SteamAPI_ISteamFriends_GetClanCount(instancePtr)
	End Method
	
	Rem
	bbdoc: Gets the display name for the specified Steam group; if the local client knows about it.
	returns: The Steam groups name. Returns an empty string ("") if the provided Steam ID is invalid or the user does not know about the group.
	about: 
	See Also: #DownloadClanActivityCounts
	End Rem
	Method GetClanName:String(steamIDClan:ULong)
		Return bmx_SteamAPI_ISteamFriends_GetClanName(instancePtr, steamIDClan)
	End Method
	
	Rem
	bbdoc: Gets the Steam ID of the officer at the given index in a Steam group.
	about: 
	> NOTE: You must call GetClanOfficerCount before calling this.
	End Rem
	Method GetClanOfficerByIndex:ULong(steamIDClan:ULong, officer:Int)
		Return bmx_SteamAPI_ISteamFriends_GetClanOfficerByIndex(instancePtr, steamIDClan, officer)
	End Method
	
	Rem
	bbdoc: Gets the number of officers (administrators and moderators) in a specified Steam group.
	returns: The number of officers in the Steam group. Returns 0 if @steamIDClan is invalid or if #RequestClanOfficerList has not been called for it.
	about: This also includes the owner of the Steam group.

	This is used for iteration, after calling this then #GetClanOfficerByIndex can be used to get the Steam ID of each officer.

	> NOTE: You must call #RequestClanOfficerList before this to get the required data!
	End Rem
	Method GetClanOfficerCount:Int(steamIDClan:ULong)
		Return bmx_SteamAPI_ISteamFriends_GetClanOfficerCount(instancePtr, steamIDClan)
	End Method
	
	Rem
	bbdoc: Gets the owner of a Steam Group.
	returns: Returns k_steamIDNil if steamIDClan is invalid or if #RequestClanOfficerList has not been called for it.

	about: 
	> NOTE: You must call #RequestClanOfficerList before this to get the required data!
	End Rem
	Method GetClanOwner:ULong(steamIDClan:ULong)
		Return bmx_SteamAPI_ISteamFriends_GetClanOwner(instancePtr, steamIDClan)
	End Method
	
	Rem
	bbdoc: Gets the unique tag (abbreviation) for the specified Steam group; If the local client knows about it.
	returns: The Steam groups tag, or an empty string ("") if the provided Steam ID is invalid or the user does not know about the group.
	about: The Steam group abbreviation is a unique way for people to identify the group and is limited to 12 characters.
	In some games this will appear next to the name of group members.
	End Rem
	Method GetClanTag:String(steamIDClan:ULong)
		Return bmx_SteamAPI_ISteamFriends_GetClanTag(instancePtr, steamIDClan)
	End Method
	
	Rem
	bbdoc: Gets the Steam ID of the recently played with user at the given index.
	about: 
	> NOTE: You must call #GetCoplayFriendCount before calling this.
	End Rem
	Method GetCoplayFriend:ULong(coplayFriend:Int)
		Return bmx_SteamAPI_ISteamFriends_GetCoplayFriend(instancePtr, coplayFriend)
	End Method
	
	Rem
	bbdoc: Gets the number of players that the current users has recently played with, across all games.
	returns: The number of users that the current user has recently played with.

	about: This is used for iteration, after calling this then #GetCoplayFriend can be used to get the Steam ID of each player.

	These players are have been set with previous calls to #SetPlayedWith.
	End Rem
	Method GetCoplayFriendCount:Int()
		Return bmx_SteamAPI_ISteamFriends_GetCoplayFriendCount(instancePtr)
	End Method
	
	Rem
	bbdoc: Gets the number of users following the specified user.
	about: Triggers an OnFriendsGetFollowerCount callback.
	End Rem
	Method GetFollowerCount(steamID:ULong)
		bmx_SteamAPI_ISteamFriends_GetFollowerCount(callbackPTr, steamID)
	End Method
	
	Rem
	bbdoc: Gets the Steam ID of the user at the given index.
	about: 
	> NOTE: You must call #GetFriendCount before calling this.
	End Rem
	Method GetFriendByIndex:ULong(friend:Int, friendFlags:Int)
		Return bmx_SteamAPI_ISteamFriends_GetFriendByIndex(instancePtr, friend, friendFlags)
	End Method
	
	Rem
	bbdoc: Gets the app ID of the game that user played with someone on their recently-played-with list.
	End Rem
	Method GetFriendCoplayGame:UInt(steamIDFriend:ULong)
		Return bmx_SteamAPI_ISteamFriends_GetFriendCoplayGame(instancePtr, steamIDFriend)
	End Method
	
	Rem
	bbdoc: Gets the timestamp of when the user played with someone on their recently-played-with list.
	returns: The time is provided in Unix epoch format (seconds since Jan 1st 1970). Steam IDs not in the recently-played-with list return 0.
	End Rem
	Method GetFriendCoplayTime:Int(steamIDFriend:ULong)
		Return bmx_SteamAPI_ISteamFriends_GetFriendCoplayTime(instancePtr, steamIDFriend)
	End Method
	
	Rem
	bbdoc: Gets the number of users the client knows about who meet a specified criteria. (Friends, blocked, users on the same server, etc)
	returns: The number of users that meet the specified criteria.
	about: This can be used to iterate over all of the users by calling #GetFriendByIndex to get the Steam IDs of each user.

	> NOTE: Returns -1 if the current user is not logged on.
	End Rem
	Method GetFriendCount:Int(friendFlags:Int)
		Return bmx_SteamAPI_ISteamFriends_GetFriendCount(instancePtr, friendFlags)
	End Method
	
	Rem
	bbdoc: Get the number of users in a source (Steam group, chat room, lobby, or game server).
	returns: 0 if the Steam ID provided is invalid or if the local user doesn't have the data available.
	about: 
	> NOTE: Large Steam groups cannot be iterated by the local user.

	> NOTE: If you're getting the number of lobby members then you should use ISteamMatchmaking::GetNumLobbyMembers instead.

	This is used for iteration, after calling this then #GetFriendFromSourceByIndex can be used to get the Steam ID of each person in the source.
	End Rem
	Method GetFriendCountFromSource:Int(steamIDSource:ULong)
		Return bmx_SteamAPI_ISteamFriends_GetFriendCountFromSource(instancePtr, steamIDSource)
	End Method
	
	Rem
	bbdoc: Gets the Steam ID at the given index from a source (Steam group, chat room, lobby, or game server).
	about: 
	> NOTE: You must call #GetFriendCountFromSource before calling this.
	End Rem
	Method GetFriendFromSourceByIndex:ULong(steamIDSource:ULong, friend:Int)
		Return bmx_SteamAPI_ISteamFriends_GetFriendFromSourceByIndex(instancePtr, steamIDSource, friend)
	End Method
	
	Rem
	bbdoc: Checks if the specified friend is in a game, and gets info about the game if they are.
	returns: #True if the user is a friend and is in a game, otherwise #False.
	End Rem
	Method GetFriendGamePlayed:Int(steamIDFriend:ULong, gameID:ULong Var, gameIP:UInt Var, gamePort:Short Var, queryPort:Short Var, steamIDLobby:ULong Var)
		Return bmx_SteamAPI_ISteamFriends_GetFriendGamePlayed(instancePtr, steamIDFriend, gameID, gameIP, gamePort, queryPort, steamIDLobby)
	End Method
	
	Rem
	bbdoc: Gets the data from a Steam friends message.
	returns: The number of bytes copied into @txt. Returns 0 and sets @chatEntryType to k_EChatEntryTypeInvalid if the current user is chat restricted, if the provided Steam ID is not a friend, or if the index provided in @messageID is invalid.
	about: This should only ever be called in response to an OGameConnectedFriendChatMsg callback.
	End Rem
	Method GetFriendMessage:Int(steamIDFriend:ULong, messageID:Int, txt:String Var, chatEntryType:EChatEntryType Var)
		Return bmx_SteamAPI_ISteamFriends_GetFriendMessage(instancePtr, steamIDFriend, messageID, txt, chatEntryType)
	End Method
	
	Rem
	bbdoc: Gets the specified user's persona (display) name.
	returns: The current users persona name, or an empty string (""), or "[unknown]" if the Steam ID is invalid or not known to the caller.
	about: This will only be known to the current user if the other user is in their friends list, on the same game server, in a chat room or
	lobby, or in a small Steam group with the local user.

	> NOTE: Upon on first joining a lobby, chat room, or game server the current user will not known the name of the other users automatically; that information will arrive asynchronously via #OnPersonaStateChanged callbacks.

	To get the persona name of the current user use #GetPersonaName.
	End Rem
	Method GetFriendPersonaName:String(steamIDFriend:ULong)
		Return bmx_SteamAPI_ISteamFriends_GetFriendPersonaName(instancePtr, steamIDFriend)
	End Method
	
	Rem
	bbdoc: Gets one of the previous display names for the specified user.
	returns: The players old persona name at the given index. Returns an empty string when there are no further items in the history.
	about: This only works for display names that the current user has seen on the local computer.
	End Rem
	Method GetFriendPersonaNameHistory:String(steamIDFriend:ULong, personaName:Int)
		Return bmx_SteamAPI_ISteamFriends_GetFriendPersonaNameHistory(instancePtr, steamIDFriend, personaName)
	End Method
	
	Rem
	bbdoc: Gets the current status of the specified user.
	returns: The friend state of the specified user. (Online, Offline, In-Game, etc)
	about: This will only be known to the current user if the other user is in their friends list, on the same game server,
	in a chat room or lobby, or in a small Steam group with the local user.

	> To get the state of the current user use #GetPersonaState.
	End Rem
	Method GetFriendPersonaState:EPersonaState(steamIDFriend:ULong)
		Return bmx_SteamAPI_ISteamFriends_GetFriendPersonaState(instancePtr, steamIDFriend)
	End Method
	
	Rem
	bbdoc: Gets a relationship to a specified user.
	returns: How the users know each other.
	End Rem
	Method GetFriendRelationship:EFriendRelationship(steamIDFriend:ULong)
		Return bmx_SteamAPI_ISteamFriends_GetFriendRelationship(instancePtr, steamIDFriend)
	End Method
	
	Rem
	bbdoc: Gets a Rich Presence value from a specified friend.
	returns: An empty string ("") if the specified key is not set.
	about: 
	See Also: #RequestFriendRichPresence, #SetRichPresence
	End Rem
	Method GetFriendRichPresence:String(steamIDFriend:ULong, key:String)
		Return bmx_SteamAPI_ISteamFriends_GetFriendRichPresence(instancePtr, steamIDFriend, key)
	End Method
	
	Rem
	bbdoc: Gets a Rich Presence value from a specified friend for the given key index.
	returns: An empty string ("") if the index is invalid or the specified user has no Rich Presence data available.
	about: 
	See Also: #RequestFriendRichPresence, #SetRichPresence
	End Rem
	Method GetFriendRichPresenceKeyByIndex:String(steamIDFriend:ULong, key:Int)
		Return bmx_SteamAPI_ISteamFriends_GetFriendRichPresenceKeyByIndex(instancePtr, steamIDFriend, key)
	End Method
	
	Rem
	bbdoc: Gets the number of Rich Presence keys that are set on the specified user.
	returns: 0 if there is no Rich Presence information for the specified user.
	about: This is used for iteration, after calling this then #GetFriendRichPresenceKeyByIndex to get the rich presence keys.

	This is typically only ever used for debugging purposes.
	End Rem
	Method GetFriendRichPresenceKeyCount:Int(steamIDFriend:ULong)
		Return bmx_SteamAPI_ISteamFriends_GetFriendRichPresenceKeyCount(instancePtr, steamIDFriend)
	End Method
	
	Rem
	bbdoc: Gets the number of friends groups (tags) the user has created.
	returns: The number of friends groups the current user has.
	about: This is used for iteration, after calling this then #GetFriendsGroupIDByIndex can be used to get the ID of each friend group.

	This is not to be confused with Steam groups. Those can be obtained with #GetClanCount.
	End Rem
	Method GetFriendsGroupCount:Int()
		Return bmx_SteamAPI_ISteamFriends_GetFriendsGroupCount(instancePtr)
	End Method
	
	Rem
	bbdoc: Gets the friends group ID for the given index.
	about: 
	> NOTE: You must call #GetFriendsGroupCount before calling this.


	End Rem
	Method GetFriendsGroupIDByIndex:Short(fg:Int)
		Return bmx_SteamAPI_ISteamFriends_GetFriendsGroupIDByIndex(instancePtr, fg)
	End Method
	
	Rem
	bbdoc: Gets the number of friends in a given friends group.
	returns: The number of friends in the specified friends group.
	about: This should be called before getting the list of friends with #GetFriendsGroupMembersList.
	
	See Also: #GetFriendsGroupCount
	End Rem
	Method GetFriendsGroupMembersCount:Int(friendsGroupID:Short)
		Return bmx_SteamAPI_ISteamFriends_GetFriendsGroupMembersCount(instancePtr, friendsGroupID)
	End Method
	
	Rem
	bbdoc: Gets the number of friends in the given friends group.
	about: If fewer friends exist than requested those positions' Steam IDs will be invalid.

	You must call #GetFriendsGroupMembersCount before calling this to set up the @outSteamIDMembers array with an appropriate size!
	
	See Also: #GetFriendsGroupCount
	End Rem
	Method GetFriendsGroupMembersList(friendsGroupID:Short, outSteamIDMembers:ULong Ptr, membersCount:Int)
		bmx_SteamAPI_ISteamFriends_GetFriendsGroupMembersList(instancePtr, friendsGroupID, outSteamIDMembers, membersCount)
	End Method
	
	Rem
	bbdoc: Gets the name for the given friends group.
	returns: The friend groups name or #Null if the group ID is invalid.
	about: 
	See Also: #GetFriendsGroupCount
	End Rem
	Method GetFriendsGroupName:String(friendsGroupID:Short)
		Return bmx_SteamAPI_ISteamFriends_GetFriendsGroupName(instancePtr, friendsGroupID)
	End Method
	
	Rem
	bbdoc: Gets the Steam level of the specified user.
	returns: The Steam level if it's available.
	about: You can use the local users Steam ID (ISteamUser::GetSteamID) to get their level.
	
	
	If the Steam level is not immediately available for the specified user then this returns 0 and queues it to be downloaded from the Steam servers.
	When it gets downloaded an #OnPersonaStateChanged callback will be posted with @changeFlags including k_EPersonaChangeSteamLevel.
	End Rem
	Method GetFriendSteamLevel:Int(steamIDFriend:ULong)
		Return bmx_SteamAPI_ISteamFriends_GetFriendSteamLevel(instancePtr, steamIDFriend)
	End Method
	
	Rem
	bbdoc: Gets a handle to the large (128*128px) avatar for the specified user.
	returns: A Steam image handle which is used with ISteamUtils::GetImageSize and ISteamUtils::GetImageRGBA. Returns 0 if no avatar is set for the user. Returns -1 if the avatar image data has not been loaded yet and requests that it gets download. In this case wait for an #OnAvatarImageLoaded callback and then call this again.
	about: You can pass in ISteamUser::GetSteamID to get the current users avatar.

	Triggers an #OnAvatarImageLoaded callback.

	> NOTE: This only works for users that the local user knows about. They will automatically know about their friends, people on leaderboards they've requested, or people in the same source as them (Steam group, chat room, lobby, or game server). If they don't know about them then you must call #RequestUserInformation to cache the avatar locally.

	See Also: #GetMediumFriendAvatar, #GetSmallFriendAvatar
	End Rem
	Method GetLargeFriendAvatar:Int(steamIDFriend:ULong)
		Return bmx_SteamAPI_ISteamFriends_GetLargeFriendAvatar(instancePtr, steamIDFriend)
	End Method
	
	Rem
	bbdoc: Gets a handle to the medium (64*64px) avatar for the specified user.
	returns: A Steam image handle which is used with ISteamUtils::GetImageSize and ISteamUtils::GetImageRGBA, or 0 if no avatar is set for the user.
	about: You can pass in ISteamUser::GetSteamID to get the current users avatar.

	> NOTE: This only works for users that the local user knows about. They will automatically know about their friends, people on leaderboards they've requested, or people in the same source as them (Steam group, chat room, lobby, or game server). If they don't know about them then you must call #RequestUserInformation to cache the avatar locally.

	See Also: #GetLargeFriendAvatar, #GetSmallFriendAvatar
	End Rem
	Method GetMediumFriendAvatar:Int(steamIDFriend:ULong)
		Return bmx_SteamAPI_ISteamFriends_GetMediumFriendAvatar(instancePtr, steamIDFriend)
	End Method
	
	Rem
	bbdoc: Gets the current users persona (display) name.
	returns: The current users persona name.
	about: This is the same name that is displayed the users community profile page.

	To get the persona name of other users use #GetFriendPersonaName.
	End Rem
	Method GetPersonaName:String()
		Return bmx_SteamAPI_ISteamFriends_GetPersonaName(instancePtr)
	End Method
	
	Rem
	bbdoc: Gets the friend status of the current user.
	returns: The friend state of the current user. (Online, Offline, In-Game, etc)
	about: To get the state of other users use #GetFriendPersonaState.
	End Rem
	Method GetPersonaState:EPersonaState()
		Return bmx_SteamAPI_ISteamFriends_GetPersonaState(instancePtr)
	End Method
	
	Rem
	bbdoc: Gets the nickname that the current user has set for the specified user.
	returns: #Null if the no nickname has been set for that user.
	End Rem
	Method GetPlayerNickname:String(steamIDPlayer:ULong)
		Return bmx_SteamAPI_ISteamFriends_GetPlayerNickname(instancePtr, steamIDPlayer)
	End Method
	
	Rem
	bbdoc: Gets a handle to the small (32*32px) avatar for the specified user.
	returns: A Steam image handle which is used with ISteamUtils::GetImageSize and ISteamUtils::GetImageRGBA, or 0 if no avatar is set for the user.
	about: You can pass in ISteamUser::GetSteamID to get the current users avatar.

	> NOTE: This only works for users that the local user knows about. They will automatically know about their friends, people on leaderboards they've requested, or people in the same source as them (Steam group, chat room, lobby, or game server). If they don't know about them then you must call #RequestUserInformation to cache the avatar locally.

	See Also: #GetLargeFriendAvatar, #GetMediumFriendAvatar
	End Rem
	Method GetSmallFriendAvatar:Int(steamIDFriend:ULong)
		Return bmx_SteamAPI_ISteamFriends_GetSmallFriendAvatar(instancePtr, steamIDFriend)
	End Method
	
	Rem
	bbdoc: Checks if the user meets the specified criteria. (Friends, blocked, users on the same server, etc)
	returns: #True if the specified user meets any of the criteria specified in @friendFlags; otherwise, #False.
	End Rem
	Method HasFriend:Int(steamIDFriend:ULong, friendFlags:Int)
		Return bmx_SteamAPI_ISteamFriends_HasFriend(instancePtr, steamIDFriend, friendFlags)
	End Method
	
	Rem
	bbdoc: Invites a friend or clan member to the current game using a special invite string.
	about: If the target user accepts the invite then the @connectString gets added to the command-line when launching the game.
	
	If the game is already running for that user, then they will receive an #OnGameRichPresenceJoinRequested callback with the connect string.

	See Also: ISteamMatchmaking::InviteUserToLobby
	End Rem
	Method InviteUserToGame:Int(steamIDFriend:ULong, connectString:String)
		Return bmx_SteamAPI_ISteamFriends_InviteUserToGame(instancePtr, steamIDFriend, connectString)
	End Method
	
	Rem
	bbdoc: Checks if a user in the Steam group chat room is an admin.
	returns: #True if the specified user is an admin, otherwise #False if the user is not an admin, if the current user is not in the chat room specified, or the specified user is not in the chat room.
	End Rem
	Method IsClanChatAdmin:Int(steamIDClanChat:ULong, steamIDUser:ULong)
		Return bmx_SteamAPI_ISteamFriends_IsClanChatAdmin(instancePtr, steamIDClanChat, steamIDUser)
	End Method
	
	Rem
	bbdoc: Checks if the Steam group is public.
	returns: #True if the specified group is public, otherwise #False if the specified group is not public.
	End Rem
	Method IsClanPublic:Int(steamIDClan:ULong)
		Return bmx_SteamAPI_ISteamFriends_IsClanPublic(instancePtr, steamIDClan)
	End Method
	
	Rem
	bbdoc: Checks if the Steam group is an official game group/community hub.
	returns: #True if the specified group is an official game group/community hub, #False if the specified group is not an official game group/community hub.
	End Rem
	Method IsClanOfficialGameGroup:Int(steamIDClan:ULong)
		Return bmx_SteamAPI_ISteamFriends_IsClanOfficialGameGroup(instancePtr, steamIDClan)
	End Method
	
	Rem
	bbdoc: Checks if the Steam Group chat room is open in the Steam UI.
	returns: #True if the specified Steam group chat room is opened, otherwise, #False. This also returns #False if the specified Steam group chat room is unknown.
	about: 
	See Also: #OpenClanChatWindowInSteam, #CloseClanChatWindowInSteam
	End Rem
	Method IsClanChatWindowOpenInSteam:Int(steamIDClanChat:ULong)
		Return bmx_SteamAPI_ISteamFriends_IsClanChatWindowOpenInSteam(instancePtr, steamIDClanChat)
	End Method
	
	Rem
	bbdoc: Checks if the current user is following the specified user.
	about: Triggers the #OnFriendsIsFollowing callback.
	End Rem
	Method IsFollowing(steamID:ULong)
		bmx_SteamAPI_ISteamFriends_IsFollowing(callbackPtr, steamID)
	End Method
	
	Rem
	bbdoc: Checks if a specified user is in a source (Steam group, chat room, lobby, or game server).
	returns: #True if the local user can see that @steamIDUser is a member or in @steamIDSource, otherwise, #False.
	End Rem
	Method IsUserInSource:Int(steamIDUser:ULong, steamIDSource:ULong)
		Return bmx_SteamAPI_ISteamFriends_IsUserInSource(instancePtr, steamIDUser, steamIDSource)
	End Method
	
	Rem
	bbdoc: Allows the user to join Steam group (clan) chats right within the game.
	about: The behavior is somewhat complicated, because the user may or may not be already in the group chat from outside the game or in the overlay.

	You can use #ActivateGameOverlayToUser to open the in-game overlay version of the chat.

	If you have joined a Steam group chat then you should be watching for the following callbacks:
	* #OnGameConnectedClanChatMsg
	* #OnGameConnectedChatJoin
	* #OnGameConnectedChatLeave

	See Also: #LeaveClanChatRoom, #GetClanChatMemberCount, #GetChatMemberByIndex, #SendClanChatMessage, #GetClanChatMessage, #IsClanChatAdmin, #IsClanChatWindowOpenInSteam
	End Rem
	Method JoinClanChatRoom(steamIDClan:ULong)
		bmx_SteamAPI_ISteamFriends_JoinClanChatRoom(callbackPtr, steamIDClan)
	End Method
	
	Rem
	bbdoc: Leaves a Steam group chat that the user has previously entered with #JoinClanChatRoom.
	returns: #True if user is in the specified chat room, otherwise #False.
	about: Triggers an #OnGameConnectedChatLeave callback.
	End Rem
	Method LeaveClanChatRoom:Int(steamIDClan:ULong)
		Return bmx_SteamAPI_ISteamFriends_LeaveClanChatRoom(instancePtr, steamIDClan)
	End Method
	
	Rem
	bbdoc: Opens the specified Steam group chat room in the Steam UI.
	returns: #True if the user successfully entered the Steam group chat room.
	about: 
	Returns #False in one of the following situations:
	* The provided Steam group chat room does not exist or the user does not have access to join it.
	* The current user is currently rate limited.
	* The current user is chat restricted.

	See Also: #IsClanChatWindowOpenInSteam, #CloseClanChatWindowInSteam
	End Rem
	Method OpenClanChatWindowInSteam:Int(steamIDClanChat:ULong)
		Return bmx_SteamAPI_ISteamFriends_OpenClanChatWindowInSteam(instancePtr, steamIDClanChat)
	End Method
	
	Rem
	bbdoc: Sends a message to a Steam friend.
	returns: #True if the message was successfully sent, otherwise #False if the current user is rate limited or chat restricted.
	End Rem
	Method ReplyToFriendMessage:Int(steamIDFriend:ULong, msgToSend:String)
		Return bmx_SteamAPI_ISteamFriends_ReplyToFriendMessage(instancePtr, steamIDFriend, msgToSend)
	End Method
	
	Rem
	bbdoc: Requests information about a Steam group officers (administrators and moderators).
	about: 
	Triggers an #OnClanOfficerListResponse callback.
	
	> NOTE: You can only ask about Steam groups that a user is a member of.

	> NOTE: This won't download avatars for the officers automatically. If no avatar image is available for an officer, then call #RequestUserInformation to download the avatar.

	See Also: #GetClanOwner, #GetClanOfficerCount, #GetClanOfficerByIndex
	End Rem
	Method RequestClanOfficerList(steamIDClan:ULong)
		bmx_SteamAPI_ISteamFriends_RequestClanOfficerList(callbackPtr, steamIDClan)
	End Method
	
	Rem
	bbdoc: Requests Rich Presence data from a specific user.
	about: This is used to get the Rich Presence information from a user that is not a friend of the current user, like someone in the same lobby or game server.

	This method is rate limited, if you call this too frequently for a particular user then it will just immediately post a callback without requesting new data from the server.
	
	Triggers an #OnFriendRichPresenceUpdated callback.
	
	See Also: #GetFriendRichPresence, #SetRichPresence
	End Rem
	Method RequestFriendRichPresence(steamIDFriend:ULong)
		bmx_SteamAPI_ISteamFriends_RequestFriendRichPresence(instancePtr, steamIDFriend)
	End Method
	
	Rem
	bbdoc: Requests the persona name and optionally the avatar of a specified user.
	returns: #True means that the data has being requested, and an #OnPersonaStateChanged callback will be posted when it's retrieved. #False means that we already have all the details about that user, and functions that require this information can be used immediately.
	about: 
	Triggers an #OnPersonaStateChanged callback.
	
	> NOTE: It's a lot slower to download avatars and churns the local cache, so if you don't need avatars, don't request them.
	End Rem
	Method RequestUserInformation:Int(steamIDUser:ULong, requireNameOnly:Int)
		Return bmx_SteamAPI_ISteamFriends_RequestUserInformation(instancePtr, steamIDUser, requireNameOnly)
	End Method
	
	Rem
	bbdoc: Sends a message to a Steam group chat room.
	returns: #True if the message was successfully sent.
	about: 
	Returns #False under one of the following circumstances:
	* The current user is not in the specified group chat.
	* The current user is not connected to Steam.
	* The current user is rate limited.
	* The current user is chat restricted.
	* The message in @txt exceeds 2048 characters.
	End Rem
	Method SendClanChatMessage:Int(steamIDClanChat:ULong, txt:String)
		Return bmx_SteamAPI_ISteamFriends_SendClanChatMessage(instancePtr, steamIDClanChat, txt)
	End Method
	
	Rem
	bbdoc: Lets Steam know that the user is currently using voice chat in game.
	about: This will suppress the microphone for all voice communication in the Steam UI.
	End Rem
	Method SetInGameVoiceSpeaking(steamIDUser:ULong, speaking:Int)
		bmx_SteamAPI_ISteamFriends_SetInGameVoiceSpeaking(instancePtr, steamIDUser, speaking)
	End Method
	
	Rem
	bbdoc: Listens for Steam friends chat messages.
	returns: Always returns #True.
	about: You can then show these chats inline in the game. For example with a Blizzard style chat message system or the chat system in Dota 2.
	After enabling this you will receive #OnGameConnectedFriendChatMsg callbacks when ever the user receives a chat message.
	You can get the actual message data from this callback with #GetFriendMessage. You can send messages with #ReplyToFriendMessage.
	
	Triggers an #OnGameConnectedFriendChatMsg callback.
	End Rem
	Method SetListenForFriendsMessages:Int(interceptEnabled:Int)
		Return bmx_SteamAPI_ISteamFriends_SetListenForFriendsMessages(instancePtr, interceptEnabled)
	End Method
	
	Rem
	bbdoc: Marks a target user as 'played with'.
	about: 
	> NOTE: The current user must be in game with the other player for the association to work.

	You can view the players you have recently played with here on the Steam community and in the Steam Overlay.
	End Rem
	Method SetPlayedWith(steamIDUserPlayedWith:ULong)
		bmx_SteamAPI_ISteamFriends_SetPlayedWith(instancePtr, steamIDUserPlayedWith)
	End Method
	
	Rem
	bbdoc: Sets a Rich Presence key/value for the current user that is automatically shared to all friends playing the same game.
	returns: #True if the rich presence was set successfully.
	about: Each user can have up to 20 keys set as defined by #k_cchMaxRichPresenceKeys.

	There are two special keys used for viewing/joining games:
	* "status" - A #String that will show up in the 'view game info' dialog in the Steam friends list.
	* "connect" - A #String that contains the command-line for how a friend can connect to a game. This enables the 'join game' button in the 'view game info' dialog, in the steam friends list right click menu, and on the players Steam community profile.

	There are three additional special keys used by the new Steam Chat:
	* "steam_display" - Names a rich presence localization token that will be displayed in the viewing user's selected language in the Steam client UI. See [Rich Presence Localization](https://partner.steamgames.com/doc/api/ISteamFriends#richpresencelocalization) for more info, including a link to a page for testing this rich presence data. If steam_display is not set to a valid localization tag, then rich presence will not be displayed in the Steam client.
	* "steam_player_group" - When set, indicates to the Steam client that the player is a member of a particular group. Players in the same group may be organized together in various places in the Steam UI. This string could identify a party, a server, or whatever grouping is relevant for your game. The string itself is not displayed to users.
	* "steam_player_group_size" - When set, indicates the total number of players in the steam_player_group. The Steam client may use this number to display additional information about a group when all of the members are not part of a user's friends list. (For example, "Bob, Pete, and 4 more".)

	You can clear all of the keys for the current user with #ClearRichPresence.

	To get rich presence keys for friends see: #GetFriendRichPresence.

	Returns #False under the following conditions:
	* @key was longer than #k_cchMaxRichPresenceKeyLength or had a length of 0.
	* @value was longer than #k_cchMaxRichPresenceValueLength.
	* The user has reached the maximum amount of rich presence keys as defined by #k_cchMaxRichPresenceKeys.
	End Rem
	Method SetRichPresence:Int(key:String, value:String)
		Return bmx_SteamAPI_ISteamFriends_SetRichPresence(instancePtr, key, value)
	End Method

	Rem
	bbdoc: Requests the Steam Community profile items equipped by a user.
	End Rem
	Method RequestEquippedProfileItems(steamID:ULong)
		bmx_SteamAPI_ISteamFriends_RequestEquippedProfileItems(callbackPtr, steamID)
	End Method

	Method BHasEquippedProfileItem:Int(steamID:ULong, itemType:ECommunityProfileItemType)
		Return bmx_SteamAPI_ISteamFriends_BHasEquippedProfileItem(instancePtr, steamID, itemType)
	End Method

	Method GetProfileItemPropertyString:String(steamID:ULong, itemType:ECommunityProfileItemType, property:ECommunityProfileItemProperty)
		Return bmx_SteamAPI_ISteamFriends_GetProfileItemPropertyString(instancePtr, steamID, itemType, property)
	End Method

	Method GetProfileItemPropertyUint:UInt(steamID:ULong, itemType:ECommunityProfileItemType, property:ECommunityProfileItemProperty)
		Return bmx_SteamAPI_ISteamFriends_GetProfileItemPropertyUint(instancePtr, steamID, itemType, property)
	End Method

	' callbacks
	Private

	Method OnAvatarImageLoaded(steamID:ULong, image:Int, width:Int, height:Int)
		If listener Then
			listener.OnAvatarImageLoaded(steamID, image, width, height)
		End If
	End Method

	Function _OnAvatarImageLoaded(inst:TSteamFriends, steamID:ULong, image:Int, width:Int, height:Int) { nomangle }
		inst.OnAvatarImageLoaded(steamID, image, width, height)
	End Function
	
	Method OnFriendRichPresenceUpdated(steamIDFriend:ULong, appID:UInt)
		If listener Then
			listener.OnFriendRichPresenceUpdated(steamIDFriend, appID)
		End If
	End Method

	Function _OnFriendRichPresenceUpdated(inst:TSteamFriends, steamIDFriend:ULong, appID:UInt) { nomangle }
		inst.OnFriendRichPresenceUpdated(steamIDFriend, appID)
	End Function

	Method OnGameConnectedChatLeave(steamIDClanChat:ULong, steamIDUser:ULong, kicked:Int, dropped:Int)
		If listener Then
			listener.OnGameConnectedChatLeave(steamIDClanChat, steamIDUser, kicked, dropped)
		End If
	End Method

	Function _OnGameConnectedChatLeave(inst:TSteamFriends, steamIDClanChat:ULong, steamIDUser:ULong, kicked:Int, dropped:Int) { nomangle }
		inst.OnGameConnectedChatLeave(steamIDClanChat, steamIDUser, kicked, dropped)
	End Function

	Method OnGameConnectedFriendChatMsg(steamIDUser:ULong, messageID:Int)
		If listener Then
			listener.OnGameConnectedFriendChatMsg(steamIDUser, messageID)
		End If
	End Method

	Function _OnGameConnectedFriendChatMsg(inst:TSteamFriends, steamIDUser:ULong, messageID:Int) { nomangle }
		inst.OnGameConnectedFriendChatMsg(steamIDUser, messageID)
	End Function

	Method OnGameLobbyJoinRequested(steamIDLobby:ULong, steamIDFriend:ULong)
		If listener Then
			listener.OnGameLobbyJoinRequested(steamIDLobby, steamIDFriend)
		End If
	End Method

	Function _OnGameLobbyJoinRequested(inst:TSteamFriends, steamIDLobby:ULong, steamIDFriend:ULong) { nomangle }
		inst.OnGameLobbyJoinRequested(steamIDLobby, steamIDFriend)
	End Function

	Method OnGameOverlayActivated(active:Int)
		If listener Then
			listener.OnGameOverlayActivated(active)
		End If
	End Method

	Function _OnGameOverlayActivated(inst:TSteamFriends, active:Int) { nomangle }
		inst.OnGameOverlayActivated(active)
	End Function

	Method OnGameRichPresenceJoinRequested(steamIDFriend:ULong, connect:String)
		If listener Then
			listener.OnGameRichPresenceJoinRequested(steamIDFriend, connect)
		End If
	End Method

	Function _OnGameRichPresenceJoinRequested(inst:TSteamFriends, steamIDFriend:ULong, connect:String) { nomangle }
		inst.OnGameRichPresenceJoinRequested(steamIDFriend, connect)
	End Function

	Method OnGameServerChangeRequested(server:String, password:String)
		If listener Then
			listener.OnGameServerChangeRequested(server, password)
		End If
	End Method

	Function _OnGameServerChangeRequested(inst:TSteamFriends, server:String, password:String) { nomangle }
		inst.OnGameServerChangeRequested(server, password)
	End Function

	Method OnPersonaStateChanged(steamID:ULong, changeFlags:Int)
		If listener Then
			listener.OnPersonaStateChanged(steamID, changeFlags)
		End If
	End Method

	Function _OnPersonaStateChanged(inst:TSteamFriends, steamID:ULong, changeFlags:Int) { nomangle }
		inst.OnPersonaStateChanged(steamID, changeFlags)
	End Function

	Method OnClanOfficerList(steamIDClan:ULong, officers:Int, success:Int)
		If listener Then
			listener.OnClanOfficerList(steamIDClan, officers, success)
		End If
	End Method

	Function _OnClanOfficerList(inst:TSteamFriends, steamIDClan:ULong, officers:Int, success:Int) { nomangle }
		inst.OnClanOfficerList(steamIDClan, officers, success)
	End Function

	Method OnDownloadClanActivityCounts(success:Int)
		If listener Then
			listener.OnDownloadClanActivityCounts(success)
		End If
	End Method

	Function _OnDownloadClanActivityCounts(inst:TSteamFriends, success:Int) { nomangle }
		inst.OnDownloadClanActivityCounts(success)
	End Function

	Method OnFriendsEnumerateFollowingList(result:EResult, steamIDS:ULong Ptr, resultsReturned:Int, totalResultCount:Int)
		If listener Then
			listener.OnFriendsEnumerateFollowingList(result, steamIDS, resultsReturned, totalResultCount)
		End If
	End Method

	Function _OnFriendsEnumerateFollowingList(inst:TSteamFriends, result:EResult, steamIDS:ULong Ptr, resultsReturned:Int, totalResultCount:Int) { nomangle }
		inst.OnFriendsEnumerateFollowingList(result, steamIDS, resultsReturned, totalResultCount)
	End Function

	Method OnFriendsGetFollowerCount(result:EResult, steamID:ULong, count:Int)
		If listener Then
			listener.OnFriendsGetFollowerCount(result, steamID, count)
		End If
	End Method

	Function _OnFriendsGetFollowerCount(inst:TSteamFriends, result:EResult, steamID:ULong, count:Int) { nomangle }
		inst.OnFriendsGetFollowerCount(result, steamID, count)
	End Function

	Method OnFriendsIsFollowing(result:EResult, steamID:ULong, isFollowing:Int)
		If listener Then
			listener.OnFriendsIsFollowing(result, steamID, isFollowing)
		End If
	End Method

	Function _OnFriendsIsFollowing(inst:TSteamFriends, result:EResult, steamID:ULong, isFollowing:Int) { nomangle }
		inst.OnFriendsIsFollowing(result, steamID, isFollowing)
	End Function

	Method OnGameConnectedChatJoined(steamIDClanChat:ULong, steamIDUser:ULong)
		If listener Then
			listener.OnGameConnectedChatJoined(steamIDClanChat, steamIDUser)
		End If
	End Method

	Function _OnGameConnectedChatJoined(inst:TSteamFriends, steamIDClanChat:ULong, steamIDUser:ULong) { nomangle }
		inst.OnGameConnectedChatJoined(steamIDClanChat, steamIDUser)
	End Function

	Method OnGameConnectedClanChatMsg(steamIDClanChat:ULong, steamIDUser:ULong, messageID:Int)
		If listener Then
			listener.OnGameConnectedClanChatMsg(steamIDClanChat, steamIDUser, messageID)
		End If
	End Method

	Function _OnGameConnectedClanChatMsg(inst:TSteamFriends, steamIDClanChat:ULong, steamIDUser:ULong, messageID:Int) { nomangle }
		inst.OnGameConnectedClanChatMsg(steamIDClanChat, steamIDUser, messageID)
	End Function

	Method OnJoinClanChatRoomCompletion(steamIDClanChat:ULong, chatRoomEnterResponse:EChatRoomEnterResponse)
		If listener Then
			listener.OnJoinClanChatRoomCompletion(steamIDClanChat, chatRoomEnterResponse)
		End If
	End Method

	Function _OnJoinClanChatRoomCompletion(inst:TSteamFriends, steamIDClanChat:ULong, chatRoomEnterResponse:EChatRoomEnterResponse) { nomangle }
		inst.OnJoinClanChatRoomCompletion(steamIDClanChat, chatRoomEnterResponse)
	End Function

	Method OnEquippedProfileItemsChanged(steamID:ULong)
		If listener Then listener.OnEquippedProfileItemsChanged(steamID)
	End Method

	Function _OnEquippedProfileItemsChanged(inst:TSteamFriends, steamID:ULong) { nomangle }
		inst.OnEquippedProfileItemsChanged(steamID)
	End Function

	Method OnEquippedProfileItems(result:EResult, steamID:ULong, animatedAvatar:Int, avatarFrame:Int, profileModifier:Int, profileBackground:Int, miniProfileBackground:Int, fromCache:Int)
		If listener Then listener.OnEquippedProfileItems(result, steamID, animatedAvatar, avatarFrame, profileModifier, profileBackground, miniProfileBackground, fromCache)
	End Method

	Function _OnEquippedProfileItems(inst:TSteamFriends, result:EResult, steamID:ULong, animatedAvatar:Int, avatarFrame:Int, profileModifier:Int, profileBackground:Int, miniProfileBackground:Int, fromCache:Int) { nomangle }
		inst.OnEquippedProfileItems(result, steamID, animatedAvatar, avatarFrame, profileModifier, profileBackground, miniProfileBackground, fromCache)
	End Function

End Type
