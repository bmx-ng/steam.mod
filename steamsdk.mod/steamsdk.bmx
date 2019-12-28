' Copyright (c) 2019 Bruce A Henderson
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
Module steam.steamsdk

ModuleInfo "Version: 1.00"
ModuleInfo "License: zlib/libpng"
ModuleInfo "Copyright: Steam SDK - Valve Corporation"
ModuleInfo "Copyright: Wrapper - 2019 Bruce A Henderson"

ModuleInfo "CPP_OPTS: -std=c++11"
?win32x64
ModuleInfo "LD_OPTS: -L%PWD%/sdk/redistributable_bin/win64"
?linuxx64
ModuleInfo "LD_OPTS: -L%PWD%/sdk/redistributable_bin/linux64"
?macosx64
ModuleInfo "LD_OPTS: -L%PWD%/sdk/redistributable_bin/osx32"
?

'
' Build notes :
'    steamtypes.h was changed to support building with mingw
'    include/flat.h is steam_api_flat.h with the defs stripped out.
'

Import "common.bmx"

Private

Global _steamPipe:UInt
Global _inited:Int
Global _user:Int
Global _autoRunCallbacks:Int

OnEnd SteamShutdown

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
bbdoc: Shuts down Steam.
End Rem
Function SteamShutdown()
	If _autoRunCallbacks Then
		bmx_SteamAPI_stopBackgroundTimer()
	End If
	bmx_SteamAPI_Shutdown()
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

Type TSteamAPI Abstract

	Field instancePtr:Byte Ptr
	Field callbackPtr:Byte Ptr

End Type

Rem
bbdoc: Provides an interface to a steam instance.
End Rem
Type TSteamClient Extends TSteamAPI

	Const STEAMCLIENT_INTERFACE_VERSION:String = "SteamClient018"

	Method New()
		instancePtr = bmx_SteamInternal_CreateInterface(STEAMCLIENT_INTERFACE_VERSION)

		If Not _user Then
			_user = bmx_SteamAPI_ISteamClient_ConnectToGlobalUser(instancePtr, _steamPipe)
		End If
	End Method

	Rem
	bbdoc: Returns a new instance of #TSteamUtils.
	End Rem
	Method GetISteamUtils:TSteamUtils()
		Return TSteamUtils._create(bmx_SteamAPI_ISteamClient_GetISteamUtils(instancePtr, _steamPipe, TSteamUtils.STEAMUTILS_INTERFACE_VERSION))
	End Method
	
	Rem
	bbdoc: Returns a new instance of #TSteamUserStats.
	End Rem
	Method GetISteamUserStats:TSteamUserStats()
		Return TSteamUserStats._create(bmx_SteamAPI_ISteamClient_GetISteamUserStats(instancePtr, _user, _steamPipe, TSteamUserStats.STEAMUSERSTATS_INTERFACE_VERSION))
	End Method

	Rem
	bbdoc: Returns a new instance of #TSteamUGC.
	End Rem
	Method GetISteamUGC:TSteamUGC()
		Return TSteamUGC._create(bmx_SteamAPI_ISteamClient_GetISteamUGC(instancePtr, _user, _steamPipe, TSteamUGC.STEAMUGC_INTERFACE_VERSION))
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

	Const STEAMUTILS_INTERFACE_VERSION:String = "SteamUtils009"

	Field listener:ISteamUtilsListener

	Function _create:TSteamUtils(instancePtr:Byte Ptr)
		Local this:TSteamUtils = New TSteamUtils
		this.instancePtr = instancePtr

		this.callbackPtr = bmx_steamsdk_register_steamuutils(instancePtr, this)

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
bbdoc: Provides methods for accessing and submitting stats, achievements, and leaderboards.
End Rem
Type TSteamUserStats Extends TSteamAPI

	Const STEAMUSERSTATS_INTERFACE_VERSION:String = "STEAMUSERSTATS_INTERFACE_VERSION011"
	
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
		Return bmx_SteamAPI_ISteamUserStats_GetGlobalStat(instancePtr, statName, data)
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
		Return bmx_SteamAPI_ISteamUserStats_GetGlobalStat0(instancePtr, statName, data)
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
		Return bmx_SteamAPI_ISteamUserStats_GetGlobalStatHistory(instancePtr, statName, data, UInt(data.length))
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
		Return bmx_SteamAPI_ISteamUserStats_GetGlobalStatHistory0(instancePtr, statName, data, UInt(data.length))
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
	bbdoc: Gets the unlock status of the Achievement.
	about: The equivalent function for the local user is #GetAchievement.
	
	This function returns #True upon success if all of the following conditions are met; otherwise, #False.
	* #RequestUserStats has completed and successfully returned its callback.
	* The 'API Name' of the specified achievement exists in App Admin on the Steamworks website, and the changes are published.

	If the call is successful then the unlock status is returned via the @achieved parameter
	End Rem
	Method GetUserAchievement:Int(steamID:ULong, name:String, achieved:Int Var)
		Return bmx_SteamAPI_ISteamGameServerStats_GetUserAchievement(instancePtr, steamID, name, achieved)
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
		Return bmx_SteamAPI_ISteamGameServerStats_GetUserStat(instancePtr, steamID, name, data)
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
		Return bmx_SteamAPI_ISteamGameServerStats_GetUserStat0(instancePtr, steamID, name, data)
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
		Return bmx_SteamAPI_ISteamUserStats_RequestCurrentStats(instancePtr)
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
		bmx_SteamAPI_ISteamGameServerStats_RequestUserStats(callbackPtr, steamID)
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
		Return bmx_SteamAPI_ISteamUserStats_SetStat(instancePtr, name, data)
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
		Return bmx_SteamAPI_ISteamUserStats_SetStat0(instancePtr, name, data)
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

	Const STEAMUGC_INTERFACE_VERSION:String = "STEAMUGC_INTERFACE_VERSION012"

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
	Method CreateQueryAllUGCRequest:ULong(queryType:EUGCQuery, matchingeMatchingUGCTypeFileType:EUGCMatchingUGCType, creatorAppID:UInt, consumerAppID:UInt, page:UInt)
		Return bmx_SteamAPI_ISteamUGC_CreateQueryAllUGCRequest(instancePtr, queryType, matchingeMatchingUGCTypeFileType, creatorAppID, consumerAppID, page)
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
	Method GetNumSubscribedItems:UInt()
		Return bmx_SteamAPI_ISteamUGC_GetNumSubscribedItems(instancePtr)
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
	Method GetSubscribedItems:UInt(publishedFileIDs:ULong Ptr, maxEntries:UInt)
		Return bmx_SteamAPI_ISteamUGC_GetSubscribedItems(instancePtr, publishedFileIDs, maxEntries)
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
	Method SetItemTags:Int(updateHandle:ULong, tags:String[])
		Return bmx_SteamAPI_ISteamUGC_SetItemTags(instancePtr, updateHandle, tags)
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
		inst.OnUserFavoriteItemsListChanged(result:EResult, publishedFileId, wasAddRequest)
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

End Type
