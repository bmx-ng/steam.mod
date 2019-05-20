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
bbdoc: 
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
bbdoc: 
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
bbdoc: 
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
