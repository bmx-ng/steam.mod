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

?win32x64
Import "-l:steam_api64.dll"
?linuxx64
Import "-lsteam_api"
?

Import "glue/glue.cpp"


Extern

	Function bmx_SteamAPI_Init:Int()
	Function bmx_SteamAPI_Shutdown()
	Function bmx_SteamAPI_GetHSteamPipe:UInt()
	Function bmx_SteamAPI_startBackgroundTimer()
	Function bmx_SteamAPI_stopBackgroundTimer()
	Function bmx_SteamAPI_RunCallbacks()
	
	Function bmx_SteamInternal_CreateInterface:Byte Ptr(version:String)

	Function bmx_steamsdk_register_steamuserstats:Byte Ptr(inst:Byte Ptr, obj:Object)
	Function bmx_steamsdk_unregister_steamuserstats(callbackPtr:Byte Ptr)
	Function bmx_SteamAPI_ISteamClient_GetISteamUtils:Byte Ptr(inst:Byte Ptr, pipe:UInt, version:String)
	Function bmx_SteamAPI_ISteamClient_ConnectToGlobalUser:Int(inst:Byte Ptr, pipe:UInt)
	Function bmx_SteamAPI_ISteamClient_GetISteamUserStats:Byte Ptr(inst:Byte Ptr, user:Int, pipe:UInt, version:String)
	Function bmx_SteamAPI_ISteamClient_GetISteamUGC:Byte Ptr(inst:Byte Ptr, user:Int, pipe:UInt, version:String)
	Function bmx_SteamAPI_ISteamClient_GetISteamFriends:Byte Ptr(inst:Byte Ptr, user:Int, pipe:UInt, version:String)

	Function bmx_steamsdk_register_steamutils:Byte Ptr(inst:Byte Ptr, obj:Object)
	Function bmx_steamsdk_unregister_steamutils(callbackPtr:Byte Ptr)

	Function bmx_SteamAPI_ISteamUtils_GetSecondsSinceAppActive:UInt(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamUtils_GetSecondsSinceComputerActive:UInt(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamUtils_GetServerRealTime:UInt(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamUtils_GetIPCountry:String(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamUtils_GetAppID:UInt(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamUtils_IsOverlayEnabled:Int(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamUtils_IsSteamInBigPictureMode:Int(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamUtils_IsSteamRunningInVR:Int(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamUtils_IsVRHeadsetStreamingEnabled:Int(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamUtils_SetOverlayNotificationInset(inst:Byte Ptr, horizontalInset:Int, verticalInset:Int)
	Function bmx_SteamAPI_ISteamUtils_SetOverlayNotificationPosition(inst:Byte Ptr, position:ENotificationPosition)
	Function bmx_SteamAPI_ISteamUtils_SetVRHeadsetStreamingEnabled(inst:Byte Ptr, enabled:Int)
	Function bmx_SteamAPI_ISteamUtils_StartVRDashboard(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamUtils_BOverlayNeedsPresent:Int(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamUtils_GetCurrentBatteryPower:Int(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamUtils_GetEnteredGamepadTextInput:Int(inst:Byte Ptr, txt:String Var)
	Function bmx_SteamAPI_ISteamUtils_GetEnteredGamepadTextLength:UInt(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamUtils_GetImageRGBA:Int(inst:Byte Ptr, image:Int, dest:Byte Ptr, destBufferSize:Int)
	Function bmx_SteamAPI_ISteamUtils_GetImageSize:Int(inst:Byte Ptr, image:Int, width:UInt Var, height:UInt Var)
	Function bmx_SteamAPI_ISteamUtils_GetSteamUILanguage:String(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamUtils_ShowGamepadTextInput:Int(inst:Byte Ptr, inputMode:EGamepadTextInputMode, lineInputMode:EGamepadTextInputLineMode, description:String, charMax:UInt, existingText:String)

	Function bmx_SteamAPI_ISteamUserStats_RequestCurrentStats:Int(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamUserStats_GetNumberOfCurrentPlayers(callback:Byte Ptr)
	Function bmx_SteamAPI_ISteamUserStats_GetMostAchievedAchievementInfo:Int(inst:Byte Ptr, name:String Var, percent:Float Var, achieved:Int Var)
	Function bmx_SteamAPI_ISteamUserStats_GetNextMostAchievedAchievementInfo:Int(inst:Byte Ptr, previous:Int, name:String Var, percent:Float Var, achieved:Int Var)
	Function bmx_SteamAPI_ISteamUserStats_GetNumAchievements:UInt(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamUserStats_ClearAchievement:Int(inst:Byte Ptr, name:String)
	Function bmx_SteamAPI_ISteamUserStats_DownloadLeaderboardEntries(callback:Byte Ptr, leaderboardHandle:ULong, leaderboardDataRequest:ELeaderboardDataRequest, rangeStart:Int, rangeEnd:Int)
	Function bmx_SteamAPI_ISteamUserStats_DownloadLeaderboardEntriesForUsers(callback:Byte Ptr, leaderboardHandle:ULong, users:ULong Ptr, count:Int)
	Function bmx_SteamAPI_ISteamUserStats_FindLeaderboard(callback:Byte Ptr, leaderboardName:String)
	Function bmx_SteamAPI_ISteamUserStats_FindOrCreateLeaderboard(callback:Byte Ptr, leaderboardName:String, sortMethod:ELeaderboardSortMethod , displayType:ELeaderboardDisplayType)
	Function bmx_SteamAPI_ISteamUserStats_GetAchievement:Int(inst:Byte Ptr, name:String, achieved:Int Var)
	Function bmx_SteamAPI_ISteamUserStats_GetAchievementAchievedPercent:Int(inst:Byte Ptr, name:String, percent:Float Var)
	Function bmx_SteamAPI_ISteamUserStats_GetAchievementAndUnlockTime:Int(inst:Byte Ptr, name:String, achieved:Int Var, unlockTime:UInt Var)
	Function bmx_SteamAPI_ISteamUserStats_GetAchievementDisplayAttribute:String(inst:Byte Ptr, name:String, key:String)
	Function bmx_SteamAPI_ISteamUserStats_GetAchievementIcon:Int(inst:Byte Ptr, name:String)
	Function bmx_SteamAPI_ISteamUserStats_GetAchievementName:String(inst:Byte Ptr, achievement:UInt)
	Function bmx_SteamAPI_ISteamUserStats_GetGlobalStat:Int(inst:Byte Ptr, statName:String, data:Long Var)
	Function bmx_SteamAPI_ISteamUserStats_GetGlobalStat0:Int(inst:Byte Ptr, statName:String, data:Double Var)
	Function bmx_SteamAPI_ISteamUserStats_GetGlobalStatHistory:Int(inst:Byte Ptr, statName:String, data:Long Ptr, count:UInt)
	Function bmx_SteamAPI_ISteamUserStats_GetGlobalStatHistory0:Int(inst:Byte Ptr, statName:String, data:Double Ptr, count:UInt)
	Function bmx_SteamAPI_ISteamUserStats_GetLeaderboardDisplayType:ELeaderboardDisplayType(inst:Byte Ptr, leaderboardHandle:ULong)
	Function bmx_SteamAPI_ISteamUserStats_GetLeaderboardEntryCount:Int(inst:Byte Ptr, leaderboardHandle:ULong)
	Function bmx_SteamAPI_ISteamUserStats_GetLeaderboardName:String(inst:Byte Ptr, leadboarHandle:ULong)
	Function bmx_SteamAPI_ISteamUserStats_GetLeaderboardSortMethod:ELeaderboardSortMethod(inst:Byte Ptr, leaderboardHandle:ULong)
	Function bmx_SteamAPI_ISteamGameServerStats_GetUserAchievement:Int(inst:Byte Ptr, steamID:ULong, name:String, achieved:Int Var)
	Function bmx_SteamAPI_ISteamUserStats_GetUserAchievementAndUnlockTime:Int(inst:Byte Ptr, steamID:ULong, name:String, achieved:Int Var, unlockTime:UInt Var)
	Function bmx_SteamAPI_ISteamGameServerStats_GetUserStat:Int(inst:Byte Ptr, steamID:ULong, name:String, data:Int Var)
	Function bmx_SteamAPI_ISteamGameServerStats_GetUserStat0:Int(inst:Byte Ptr, steamID:ULong, name:String, data:Float Var)
	Function bmx_SteamAPI_ISteamUserStats_IndicateAchievementProgress:Int(inst:Byte Ptr, name:String, curProgress:UInt, maxProgress:UInt)
	Function bmx_SteamAPI_ISteamUserStats_RequestGlobalAchievementPercentages(callback:Byte Ptr)
	Function bmx_SteamAPI_ISteamUserStats_RequestGlobalStats(callback:Byte Ptr, historyDays:Int)
	Function bmx_SteamAPI_ISteamGameServerStats_RequestUserStats(callback:Byte Ptr, steamID:ULong)
	Function bmx_SteamAPI_ISteamUserStats_ResetAllStats:Int(inst:Byte Ptr, achievementsToo:Int)
	Function bmx_SteamAPI_ISteamUserStats_SetAchievement:Int(inst:Byte Ptr, name:String)
	Function bmx_SteamAPI_ISteamUserStats_SetStat:Int(inst:Byte Ptr, name:String, data:Int)
	Function bmx_SteamAPI_ISteamUserStats_SetStat0:Int(inst:Byte Ptr, name:String, data:Float)
	Function bmx_SteamAPI_ISteamUserStats_StoreStats:Int(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamUserStats_UpdateAvgRateStat:Int(inst:Byte Ptr, name:String, countThisSession:Float, sessionLength:Double)
	Function bmx_SteamAPI_ISteamUserStats_UploadLeaderboardScore(callback:Byte Ptr, leaderboardHandle:ULong, uploadScoreMethod:ELeaderboardUploadScoreMethod, score:Int, scoreDetails:Int Ptr, count:Int)

	Function bmx_steamsdk_register_steamugc:Byte Ptr(inst:Byte Ptr, obj:Object)
	Function bmx_steamsdk_unregister_steamugc(callbackPtr:Byte Ptr)
	
	Function bmx_SteamAPI_ISteamUGC_AddAppDependency(callback:Byte Ptr, publishedFileID:ULong, appID:UInt)
	Function bmx_SteamAPI_ISteamUGC_AddDependency(callback:Byte Ptr, publishedFileId:ULong, childPublishedFileId:ULong)
	Function bmx_SteamAPI_ISteamUGC_AddExcludedTag:Int(inst:Byte Ptr, queryHandle:ULong, tagName:String)
	Function bmx_SteamAPI_ISteamUGC_AddItemKeyValueTag:Int(inst:Byte Ptr, queryHandle:ULong, key:String, value:String)
	Function bmx_SteamAPI_ISteamUGC_AddItemPreviewFile:Int(inst:Byte Ptr, queryHandle:ULong, previewFile:String, previewType:EItemPreviewType)
	Function bmx_SteamAPI_ISteamUGC_AddItemPreviewVideo:Int(inst:Byte Ptr, queryHandle:ULong, videoID:String)
	Function bmx_SteamAPI_ISteamUGC_AddItemToFavorites(callback:Byte Ptr, appId:UInt, publishedFileID:ULong)
	Function bmx_SteamAPI_ISteamUGC_AddRequiredKeyValueTag:Int(inst:Byte Ptr, queryHandle:ULong, key:String, value:String)
	Function bmx_SteamAPI_ISteamUGC_AddRequiredTag:Int(inst:Byte Ptr, queryHandle:ULong, tagName:String)
	Function bmx_SteamAPI_ISteamUGC_InitWorkshopForGameServer:Int(inst:Byte Ptr, workshopDepotID:ULong, folder:String)
	Function bmx_SteamAPI_ISteamUGC_CreateItem(callback:Byte Ptr, consumerAppId:UInt, FileType:EWorkshopFileType)
	Function bmx_SteamAPI_ISteamUGC_CreateQueryAllUGCRequest:ULong(inst:Byte Ptr, queryType:EUGCQuery, matchingeMatchingUGCTypeFileType:EUGCMatchingUGCType, creatorAppID:UInt, consumerAppID:UInt, page:UInt)
	Function bmx_SteamAPI_ISteamUGC_CreateQueryUGCDetailsRequest:ULong(inst:Byte Ptr, publishedFileIDs:ULong Ptr, numPublishedFileIDs:Int)
	Function bmx_SteamAPI_ISteamUGC_CreateQueryUserUGCRequest:ULong(inst:Byte Ptr, accountID:UInt, listType:EUserUGCList, matchingUGCType:EUGCMatchingUGCType, sortOrder:EUserUGCListSortOrder, creatorAppID:UInt, consumerAppID:UInt, page:UInt)
	Function bmx_SteamAPI_ISteamUGC_DeleteItem(callback:Byte Ptr, publishedFileID:ULong)
	Function bmx_SteamAPI_ISteamUGC_DownloadItem:Int(inst:Byte Ptr, publishedFileID:ULong, highPriority:Int)
	Function bmx_SteamAPI_ISteamUGC_GetAppDependencies(callback:Byte Ptr, publishedFileID:ULong)
	Function bmx_SteamAPI_ISteamUGC_GetItemDownloadInfo:Int(inst:Byte Ptr, publishedFileID:ULong, bytesDownloaded:ULong Var, bytesTotal:ULong Var)
	Function bmx_SteamAPI_ISteamUGC_GetItemInstallInfo:Int(inst:Byte Ptr, publishedFileID:ULong, sizeOnDisk:ULong Var, folder:String Var, timestamp:UInt Var)
	Function bmx_SteamAPI_ISteamUGC_GetItemState:EItemState(inst:Byte Ptr, publishedFileID:ULong)
	Function bmx_SteamAPI_ISteamUGC_GetItemUpdateProgress:EItemUpdateStatus(inst:Byte Ptr, queryHandle:ULong, bytesProcessed:ULong Var, bytesTotal:ULong Var)
	Function bmx_SteamAPI_ISteamUGC_GetNumSubscribedItems:UInt(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamUGC_GetQueryUGCAdditionalPreview:Int(inst:Byte Ptr, queryHandle:ULong, index:UInt, previewIndex:UInt, URLOrVideoID:String Var, originalFileName:String Var, previewType:EItemPreviewType Var)
	Function bmx_SteamAPI_ISteamUGC_GetQueryUGCChildren:Int(inst:Byte Ptr, queryHandle:ULong, index:UInt, publishedFileIDs:ULong Ptr, maxEntries:UInt)
	Function bmx_SteamAPI_ISteamUGC_GetQueryUGCKeyValueTag:Int(inst:Byte Ptr, queryHandle:ULong, index:UInt, keyValueTagIndex:UInt, key:String Var, value:String Var)
	Function bmx_SteamAPI_ISteamUGC_GetQueryUGCMetadata:Int(inst:Byte Ptr, queryHandle:ULong, index:UInt, metadata:String Var)
	Function bmx_SteamAPI_ISteamUGC_GetQueryUGCNumAdditionalPreviews:UInt(inst:Byte Ptr, queryHandle:ULong, index:UInt)
	Function bmx_SteamAPI_ISteamUGC_GetQueryUGCNumKeyValueTags:UInt(inst:Byte Ptr, queryHandle:ULong, index:UInt)
	Function bmx_SteamAPI_ISteamUGC_GetQueryUGCPreviewURL:Int(inst:Byte Ptr, queryHandle:ULong, index:UInt, URL:String Var)
	Function bmx_SteamAPI_ISteamUGC_GetQueryUGCStatistic:Int(inst:Byte Ptr, queryHandle:ULong, index:UInt, statType:EItemStatistic, statValue:ULong Var)
	Function bmx_SteamAPI_ISteamUGC_GetSubscribedItems:UInt(inst:Byte Ptr, publishedFileIDs:ULong Ptr, maxEntries:UInt)
	Function bmx_SteamAPI_ISteamUGC_GetUserItemVote(callback:Byte Ptr, publishedFileID:ULong)
	Function bmx_SteamAPI_ISteamUGC_ReleaseQueryUGCRequest:Int(inst:Byte Ptr, queryHandle:ULong)
	Function bmx_SteamAPI_ISteamUGC_RemoveAppDependency(callback:Byte Ptr, publishedFileID:ULong, appID:UInt)
	Function bmx_SteamAPI_ISteamUGC_RemoveDependency(callback:Byte Ptr, parentPublishedFileID:ULong, childPublishedFileID:ULong)
	Function bmx_SteamAPI_ISteamUGC_RemoveItemFromFavorites(callback:Byte Ptr, appId:UInt, publishedFileID:ULong)
	Function bmx_SteamAPI_ISteamUGC_RemoveItemKeyValueTags:Int(inst:Byte Ptr, queryHandle:ULong, key:String)
	Function bmx_SteamAPI_ISteamUGC_RemoveItemPreview:Int(inst:Byte Ptr, queryHandle:ULong, index:UInt)
	Function bmx_SteamAPI_ISteamUGC_SendQueryUGCRequest(callback:Byte Ptr, queryHandle:ULong)
	Function bmx_SteamAPI_ISteamUGC_SetAllowCachedResponse:Int(inst:Byte Ptr, queryHandle:ULong, maxAgeSeconds:UInt)
	Function bmx_SteamAPI_ISteamUGC_SetCloudFileNameFilter:Int(inst:Byte Ptr, queryHandle:ULong, matchCloudFileName:String)
	Function bmx_SteamAPI_ISteamUGC_SetItemContent:Int(inst:Byte Ptr, updateHandle:ULong, contentFolder:String)
	Function bmx_SteamAPI_ISteamUGC_SetItemDescription:Int(inst:Byte Ptr, updateHandle:ULong, description:String)
	Function bmx_SteamAPI_ISteamUGC_SetItemMetadata:Int(inst:Byte Ptr, updateHandle:ULong, metaData:String)
	Function bmx_SteamAPI_ISteamUGC_SetItemPreview:Int(inst:Byte Ptr, updateHandle:ULong, previewFile:String)
	Function bmx_SteamAPI_ISteamUGC_SetItemTags:Int(inst:Byte Ptr, updateHandle:ULong, tags:String[])
	Function bmx_SteamAPI_ISteamUGC_SetItemTitle:Int(inst:Byte Ptr, updateHandle:ULong, title:String)
	Function bmx_SteamAPI_ISteamUGC_SetItemUpdateLanguage:Int(inst:Byte Ptr, updateHandle:ULong, language:String)
	Function bmx_SteamAPI_ISteamUGC_SetItemVisibility:Int(inst:Byte Ptr, updateHandle:ULong, visibility:ERemoteStoragePublishedFileVisibility)
	Function bmx_SteamAPI_ISteamUGC_SetLanguage:Int(inst:Byte Ptr, queryHandle:ULong, language:String)
	Function bmx_SteamAPI_ISteamUGC_SetMatchAnyTag:Int(inst:Byte Ptr, queryHandle:ULong, matchAnyTag:Int)
	Function bmx_SteamAPI_ISteamUGC_SetRankedByTrendDays:Int(inst:Byte Ptr, queryHandle:ULong, days:UInt)
	Function bmx_SteamAPI_ISteamUGC_SetReturnAdditionalPreviews:Int(inst:Byte Ptr, queryHandle:ULong, returnAdditionalPreviews:Int)
	Function bmx_SteamAPI_ISteamUGC_SetReturnChildren:Int(inst:Byte Ptr, queryHandle:ULong, returnChildren:Int)
	Function bmx_SteamAPI_ISteamUGC_SetReturnKeyValueTags:Int(inst:Byte Ptr, queryHandle:ULong, returnKeyValueTags:Int)
	Function bmx_SteamAPI_ISteamUGC_SetReturnLongDescription:Int(inst:Byte Ptr, queryHandle:ULong, returnLongDescription:Int)
	Function bmx_SteamAPI_ISteamUGC_SetReturnMetadata:Int(inst:Byte Ptr, queryHandle:ULong, returnMetadata:Int)
	Function bmx_SteamAPI_ISteamUGC_SetReturnOnlyIDs:Int(inst:Byte Ptr, queryHandle:ULong, returnOnlyIDs:Int)
	Function bmx_SteamAPI_ISteamUGC_SetReturnPlaytimeStats:Int(inst:Byte Ptr, queryHandle:ULong, days:UInt)
	Function bmx_SteamAPI_ISteamUGC_SetReturnTotalOnly:Int(inst:Byte Ptr, queryHandle:ULong, returnTotalOnly:Int)
	Function bmx_SteamAPI_ISteamUGC_SetSearchText:Int(inst:Byte Ptr, queryHandle:ULong, searchText:String)
	Function bmx_SteamAPI_ISteamUGC_SetUserItemVote(callback:Byte Ptr, publishedFileID:ULong, voteUp:Int)
	Function bmx_SteamAPI_ISteamUGC_StartItemUpdate:ULong(inst:Byte Ptr, consumerAppId:UInt, publishedFileID:ULong)
	Function bmx_SteamAPI_ISteamUGC_StartPlaytimeTracking(callback:Byte Ptr, publishedFileIDs:ULong Ptr, numPublishedFileIDs:UInt)
	Function bmx_SteamAPI_ISteamUGC_StopPlaytimeTracking(callback:Byte Ptr, publishedFileIDs:ULong Ptr, numPublishedFileIDs:UInt)
	Function bmx_SteamAPI_ISteamUGC_StopPlaytimeTrackingForAllItems(callback:Byte Ptr)
	Function bmx_SteamAPI_ISteamUGC_SubmitItemUpdate(callback:Byte Ptr, updateHandle:ULong, changeNote:String)
	Function bmx_SteamAPI_ISteamUGC_SubscribeItem(callback:Byte Ptr, publishedFileID:ULong)
	Function bmx_SteamAPI_ISteamUGC_SuspendDownloads(inst:Byte Ptr, suspend:Int)
	Function bmx_SteamAPI_ISteamUGC_UnsubscribeItem(callback:Byte Ptr, publishedFileID:ULong)
	Function bmx_SteamAPI_ISteamUGC_UpdateItemPreviewFile:Int(inst:Byte Ptr, updateHandle:ULong, index:UInt, previewFile:String)
	Function bmx_SteamAPI_ISteamUGC_UpdateItemPreviewVideo:Int(inst:Byte Ptr, updateHandle:ULong, index:UInt, videoID:String)

	Function bmx_steamsdk_register_steamfriends:Byte Ptr(inst:Byte Ptr, obj:Object)
	Function bmx_steamsdk_unregister_steamfriends(callbackPtr:Byte Ptr)

	Function bmx_SteamAPI_ISteamFriends_ActivateGameOverlay(inst:Byte Ptr, dialog:String)
	Function bmx_SteamAPI_ISteamFriends_ActivateGameOverlayInviteDialog(inst:Byte Ptr, steamIDLobby:ULong)
	Function bmx_SteamAPI_ISteamFriends_ActivateGameOverlayToStore(inst:Byte Ptr, appID:UInt, flag:EOverlayToStoreFlag)
	Function bmx_SteamAPI_ISteamFriends_ActivateGameOverlayToUser(inst:Byte Ptr, dialog:String, steamID:ULong)
	Function bmx_SteamAPI_ISteamFriends_ActivateGameOverlayToWebPage(inst:Byte Ptr, url:String)
	Function bmx_SteamAPI_ISteamFriends_ClearRichPresence(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamFriends_CloseClanChatWindowInSteam:Int(inst:Byte Ptr, steamIDClanChat:ULong)
	Function bmx_SteamAPI_ISteamFriends_DownloadClanActivityCounts(callback:Byte Ptr, steamIDClans:ULong Ptr, clansToRequest:Int)
	Function bmx_SteamAPI_ISteamFriends_EnumerateFollowingList(callback:Byte Ptr, startIndex:UInt)
	Function bmx_SteamAPI_ISteamFriends_GetChatMemberByIndex:ULong(inst:Byte Ptr, steamIDClan:ULong, user:Int)
	Function bmx_SteamAPI_ISteamFriends_GetClanActivityCounts:Int(inst:Byte Ptr, steamIDClan:ULong, online:Int Var, inGame:Int Var, chatting:Int Var)
	Function bmx_SteamAPI_ISteamFriends_GetClanByIndex:ULong(inst:Byte Ptr, clan:Int)
	Function bmx_SteamAPI_ISteamFriends_GetClanChatMemberCount:Int(inst:Byte Ptr, steamIDClan:ULong)
	Function bmx_SteamAPI_ISteamFriends_GetClanChatMessage:Int(inst:Byte Ptr, steamIDClanChat:ULong, message:Int, txt:String Var, chatEntryType:EChatEntryType Var, steamidChatter:ULong Var)
	Function bmx_SteamAPI_ISteamFriends_GetClanCount:Int(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamFriends_GetClanName:String(inst:Byte Ptr, steamIDClan:ULong)
	Function bmx_SteamAPI_ISteamFriends_GetClanOfficerByIndex:ULong(inst:Byte Ptr, steamIDClan:ULong, officer:Int)
	Function bmx_SteamAPI_ISteamFriends_GetClanOfficerCount:Int(inst:Byte Ptr, steamIDClan:ULong)
	Function bmx_SteamAPI_ISteamFriends_GetClanOwner:ULong(inst:Byte Ptr, steamIDClan:ULong)
	Function bmx_SteamAPI_ISteamFriends_GetClanTag:String(inst:Byte Ptr, steamIDClan:ULong)
	Function bmx_SteamAPI_ISteamFriends_GetCoplayFriend:ULong(inst:Byte Ptr, coplayFriend:Int)
	Function bmx_SteamAPI_ISteamFriends_GetCoplayFriendCount:Int(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamFriends_GetFollowerCount(callback:Byte Ptr, steamID:ULong)
	Function bmx_SteamAPI_ISteamFriends_GetFriendByIndex:ULong(inst:Byte Ptr, friend:Int, friendFlags:Int)
	Function bmx_SteamAPI_ISteamFriends_GetFriendCoplayGame:UInt(inst:Byte Ptr, steamIDFriend:ULong)
	Function bmx_SteamAPI_ISteamFriends_GetFriendCoplayTime:Int(inst:Byte Ptr, steamIDFriend:ULong)
	Function bmx_SteamAPI_ISteamFriends_GetFriendCount:Int(inst:Byte Ptr, friendFlags:Int)
	Function bmx_SteamAPI_ISteamFriends_GetFriendCountFromSource:Int(inst:Byte Ptr, steamIDSource:ULong)
	Function bmx_SteamAPI_ISteamFriends_GetFriendFromSourceByIndex:ULong(inst:Byte Ptr, steamIDSource:ULong, friend:Int)
	Function bmx_SteamAPI_ISteamFriends_GetFriendGamePlayed:Int(inst:Byte Ptr, steamIDFriend:ULong, gameID:ULong Var, gameIP:UInt Var, gamePort:Short Var, queryPort:Short Var, steamIDLobby:ULong Var)
	Function bmx_SteamAPI_ISteamFriends_GetFriendMessage:Int(inst:Byte Ptr, steamIDFriend:ULong, messageID:Int, txt:String Var, chatEntryType:EChatEntryType Var)
	Function bmx_SteamAPI_ISteamFriends_GetFriendPersonaName:String(inst:Byte Ptr, steamIDFriend:ULong)
	Function bmx_SteamAPI_ISteamFriends_GetFriendPersonaNameHistory:String(inst:Byte Ptr, steamIDFriend:ULong, personaName:Int)
	Function bmx_SteamAPI_ISteamFriends_GetFriendPersonaState:EPersonaState(inst:Byte Ptr, steamIDFriend:ULong)
	Function bmx_SteamAPI_ISteamFriends_GetFriendRelationship:EFriendRelationship(inst:Byte Ptr, steamIDFriend:ULong)
	Function bmx_SteamAPI_ISteamFriends_GetFriendRichPresence:String(inst:Byte Ptr, steamIDFriend:ULong, key:String)
	Function bmx_SteamAPI_ISteamFriends_GetFriendRichPresenceKeyByIndex:String(inst:Byte Ptr, steamIDFriend:ULong, key:Int)
	Function bmx_SteamAPI_ISteamFriends_GetFriendRichPresenceKeyCount:Int(inst:Byte Ptr, steamIDFriend:ULong)
	Function bmx_SteamAPI_ISteamFriends_GetFriendsGroupCount:Int(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamFriends_GetFriendsGroupIDByIndex:Short(inst:Byte Ptr, fg:Int)
	Function bmx_SteamAPI_ISteamFriends_GetFriendsGroupMembersCount:Int(inst:Byte Ptr, friendsGroupID:Short)
	Function bmx_SteamAPI_ISteamFriends_GetFriendsGroupMembersList(inst:Byte Ptr, friendsGroupID:Short, outSteamIDMembers:ULong Ptr, membersCount:Int)
	Function bmx_SteamAPI_ISteamFriends_GetFriendsGroupName:String(inst:Byte Ptr, friendsGroupID:Short)
	Function bmx_SteamAPI_ISteamFriends_GetFriendSteamLevel:Int(inst:Byte Ptr, steamIDFriend:ULong)
	Function bmx_SteamAPI_ISteamFriends_GetLargeFriendAvatar:Int(inst:Byte Ptr, steamIDFriend:ULong)
	Function bmx_SteamAPI_ISteamFriends_GetMediumFriendAvatar:Int(inst:Byte Ptr, steamIDFriend:ULong)
	Function bmx_SteamAPI_ISteamFriends_GetPersonaName:String(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamFriends_GetPersonaState:EPersonaState(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamFriends_GetPlayerNickname:String(inst:Byte Ptr, steamIDPlayer:ULong)
	Function bmx_SteamAPI_ISteamFriends_GetSmallFriendAvatar:Int(inst:Byte Ptr, steamIDFriend:ULong)
	Function bmx_SteamAPI_ISteamFriends_GetUserRestrictions:UInt(inst:Byte Ptr)
	Function bmx_SteamAPI_ISteamFriends_HasFriend:Int(inst:Byte Ptr, steamIDFriend:ULong, friendFlags:Int)
	Function bmx_SteamAPI_ISteamFriends_InviteUserToGame:Int(inst:Byte Ptr, steamIDFriend:ULong, connectString:String)
	Function bmx_SteamAPI_ISteamFriends_IsClanChatAdmin:Int(inst:Byte Ptr, steamIDClanChat:ULong, steamIDUser:ULong)
	Function bmx_SteamAPI_ISteamFriends_IsClanPublic:Int(inst:Byte Ptr, steamIDClan:ULong)
	Function bmx_SteamAPI_ISteamFriends_IsClanOfficialGameGroup:Int(inst:Byte Ptr, steamIDClan:ULong)
	Function bmx_SteamAPI_ISteamFriends_IsClanChatWindowOpenInSteam:Int(inst:Byte Ptr, steamIDClanChat:ULong)
	Function bmx_SteamAPI_ISteamFriends_IsFollowing(callback:Byte Ptr, steamID:ULong)
	Function bmx_SteamAPI_ISteamFriends_IsUserInSource:Int(inst:Byte Ptr, steamIDUser:ULong, steamIDSource:ULong)
	Function bmx_SteamAPI_ISteamFriends_JoinClanChatRoom(callback:Byte Ptr, steamIDClan:ULong)
	Function bmx_SteamAPI_ISteamFriends_LeaveClanChatRoom:Int(inst:Byte Ptr, steamIDClan:ULong)
	Function bmx_SteamAPI_ISteamFriends_OpenClanChatWindowInSteam:Int(inst:Byte Ptr, steamIDClanChat:ULong)
	Function bmx_SteamAPI_ISteamFriends_ReplyToFriendMessage:Int(inst:Byte Ptr, steamIDFriend:ULong, msgToSend:String)
	Function bmx_SteamAPI_ISteamFriends_RequestClanOfficerList(callback:Byte Ptr, steamIDClan:ULong)
	Function bmx_SteamAPI_ISteamFriends_RequestFriendRichPresence(inst:Byte Ptr, steamIDFriend:ULong)
	Function bmx_SteamAPI_ISteamFriends_RequestUserInformation:Int(inst:Byte Ptr, steamIDUser:ULong, requireNameOnly:Int)
	Function bmx_SteamAPI_ISteamFriends_SendClanChatMessage:Int(inst:Byte Ptr, steamIDClanChat:ULong, txt:String)
	Function bmx_SteamAPI_ISteamFriends_SetInGameVoiceSpeaking(inst:Byte Ptr, steamIDUser:ULong, speaking:Int)
	Function bmx_SteamAPI_ISteamFriends_SetListenForFriendsMessages:Int(inst:Byte Ptr, interceptEnabled:Int)
	Function bmx_SteamAPI_ISteamFriends_SetPersonaName(callback:Byte Ptr, personaName:String)
	Function bmx_SteamAPI_ISteamFriends_SetPlayedWith(inst:Byte Ptr, steamIDUserPlayedWith:ULong)
	Function bmx_SteamAPI_ISteamFriends_SetRichPresence:Int(inst:Byte Ptr, key:String, value:String)
	
End Extern

Rem
bbdoc: Used to specify an invalid query handle.
about: This is frequently returned if a call fails.
End Rem
Const k_UGCQueryHandleInvalid:ULong = $ffffffffffffffff:ULong
Rem
bbdoc: Used to specify an invalid item update handle.
about: This is frequently returned if a call fails.
End Rem
Const k_UGCUpdateHandleInvalid:ULong = $ffffffffffffffff:ULong
Rem
bbdoc: The maximum size in bytes that a Workshop item description can be.
End Rem
Const k_cchPublishedDocumentDescriptionMax:UInt = 8000
Rem
bbdoc: The maximum amount of bytes you can set with #SetItemMetadata.
End Rem
Const k_cchDeveloperMetadataMax:UInt = 5000
Rem
bbdoc: The maximum size in bytes that a Workshop item title can be.
End Rem
Const k_cchPublishedDocumentTitleMax:UInt = 128 + 1
Rem
bbdoc: The maximum amount of rich presence keys that can be set.
End Rem
Const k_cchMaxRichPresenceKeys:Int = 20
Rem
bbdoc: The maximum length that a rich presence value can be.
End Rem
Const k_cchMaxRichPresenceValueLength:Int = 256
Rem
bbdoc: The maximum length that a rich presence key can be.
End Rem
Const k_cchMaxRichPresenceKeyLength:Int = 64

' // GENERATED

Enum EUniverse
	k_EUniverseInvalid = 0
	k_EUniversePublic = 1
	k_EUniverseBeta = 2
	k_EUniverseInternal = 3
	k_EUniverseDev = 4
	k_EUniverseMax = 5
End Enum

Enum EResult
	k_EResultOK = 1
	k_EResultFail = 2
	k_EResultNoConnection = 3
	k_EResultInvalidPassword = 5
	k_EResultLoggedInElsewhere = 6
	k_EResultInvalidProtocolVer = 7
	k_EResultInvalidParam = 8
	k_EResultFileNotFound = 9
	k_EResultBusy = 10
	k_EResultInvalidState = 11
	k_EResultInvalidName = 12
	k_EResultInvalidEmail = 13
	k_EResultDuplicateName = 14
	k_EResultAccessDenied = 15
	k_EResultTimeout = 16
	k_EResultBanned = 17
	k_EResultAccountNotFound = 18
	k_EResultInvalidSteamID = 19
	k_EResultServiceUnavailable = 20
	k_EResultNotLoggedOn = 21
	k_EResultPending = 22
	k_EResultEncryptionFailure = 23
	k_EResultInsufficientPrivilege = 24
	k_EResultLimitExceeded = 25
	k_EResultRevoked = 26
	k_EResultExpired = 27
	k_EResultAlreadyRedeemed = 28
	k_EResultDuplicateRequest = 29
	k_EResultAlreadyOwned = 30
	k_EResultIPNotFound = 31
	k_EResultPersistFailed = 32
	k_EResultLockingFailed = 33
	k_EResultLogonSessionReplaced = 34
	k_EResultConnectFailed = 35
	k_EResultHandshakeFailed = 36
	k_EResultIOFailure = 37
	k_EResultRemoteDisconnect = 38
	k_EResultShoppingCartNotFound = 39
	k_EResultBlocked = 40
	k_EResultIgnored = 41
	k_EResultNoMatch = 42
	k_EResultAccountDisabled = 43
	k_EResultServiceReadOnly = 44
	k_EResultAccountNotFeatured = 45
	k_EResultAdministratorOK = 46
	k_EResultContentVersion = 47
	k_EResultTryAnotherCM = 48
	k_EResultPasswordRequiredToKickSession = 49
	k_EResultAlreadyLoggedInElsewhere = 50
	k_EResultSuspended = 51
	k_EResultCancelled = 52
	k_EResultDataCorruption = 53
	k_EResultDiskFull = 54
	k_EResultRemoteCallFailed = 55
	k_EResultPasswordUnset = 56
	k_EResultExternalAccountUnlinked = 57
	k_EResultPSNTicketInvalid = 58
	k_EResultExternalAccountAlreadyLinked = 59
	k_EResultRemoteFileConflict = 60
	k_EResultIllegalPassword = 61
	k_EResultSameAsPreviousValue = 62
	k_EResultAccountLogonDenied = 63
	k_EResultCannotUseOldPassword = 64
	k_EResultInvalidLoginAuthCode = 65
	k_EResultAccountLogonDeniedNoMail = 66
	k_EResultHardwareNotCapableOfIPT = 67
	k_EResultIPTInitError = 68
	k_EResultParentalControlRestricted = 69
	k_EResultFacebookQueryError = 70
	k_EResultExpiredLoginAuthCode = 71
	k_EResultIPLoginRestrictionFailed = 72
	k_EResultAccountLockedDown = 73
	k_EResultAccountLogonDeniedVerifiedEmailRequired = 74
	k_EResultNoMatchingURL = 75
	k_EResultBadResponse = 76
	k_EResultRequirePasswordReEntry = 77
	k_EResultValueOutOfRange = 78
	k_EResultUnexpectedError = 79
	k_EResultDisabled = 80
	k_EResultInvalidCEGSubmission = 81
	k_EResultRestrictedDevice = 82
	k_EResultRegionLocked = 83
	k_EResultRateLimitExceeded = 84
	k_EResultAccountLoginDeniedNeedTwoFactor = 85
	k_EResultItemDeleted = 86
	k_EResultAccountLoginDeniedThrottle = 87
	k_EResultTwoFactorCodeMismatch = 88
	k_EResultTwoFactorActivationCodeMismatch = 89
	k_EResultAccountAssociatedToMultiplePartners = 90
	k_EResultNotModified = 91
	k_EResultNoMobileDevice = 92
	k_EResultTimeNotSynced = 93
	k_EResultSmsCodeFailed = 94
	k_EResultAccountLimitExceeded = 95
	k_EResultAccountActivityLimitExceeded = 96
	k_EResultPhoneActivityLimitExceeded = 97
	k_EResultRefundToWallet = 98
	k_EResultEmailSendFailure = 99
	k_EResultNotSettled = 100
	k_EResultNeedCaptcha = 101
	k_EResultGSLTDenied = 102
	k_EResultGSOwnerDenied = 103
	k_EResultInvalidItemType = 104
	k_EResultIPBanned = 105
	k_EResultGSLTExpired = 106
	k_EResultInsufficientFunds = 107
	k_EResultTooManyPending = 108
	k_EResultNoSiteLicensesFound = 109
	k_EResultWGNetworkSendExceeded = 110
	k_EResultAccountNotFriends = 111
	k_EResultLimitedUserAccount = 112
	k_EResultCantRemoveItem = 113
End Enum

Enum EVoiceResult
	k_EVoiceResultOK = 0
	k_EVoiceResultNotInitialized = 1
	k_EVoiceResultNotRecording = 2
	k_EVoiceResultNoData = 3
	k_EVoiceResultBufferTooSmall = 4
	k_EVoiceResultDataCorrupted = 5
	k_EVoiceResultRestricted = 6
	k_EVoiceResultUnsupportedCodec = 7
	k_EVoiceResultReceiverOutOfDate = 8
	k_EVoiceResultReceiverDidNotAnswer = 9
End Enum

Enum EDenyReason
	k_EDenyInvalid = 0
	k_EDenyInvalidVersion = 1
	k_EDenyGeneric = 2
	k_EDenyNotLoggedOn = 3
	k_EDenyNoLicense = 4
	k_EDenyCheater = 5
	k_EDenyLoggedInElseWhere = 6
	k_EDenyUnknownText = 7
	k_EDenyIncompatibleAnticheat = 8
	k_EDenyMemoryCorruption = 9
	k_EDenyIncompatibleSoftware = 10
	k_EDenySteamConnectionLost = 11
	k_EDenySteamConnectionError = 12
	k_EDenySteamResponseTimedOut = 13
	k_EDenySteamValidationStalled = 14
	k_EDenySteamOwnerLeftGuestUser = 15
End Enum

Enum EBeginAuthSessionResult
	k_EBeginAuthSessionResultOK = 0
	k_EBeginAuthSessionResultInvalidTicket = 1
	k_EBeginAuthSessionResultDuplicateRequest = 2
	k_EBeginAuthSessionResultInvalidVersion = 3
	k_EBeginAuthSessionResultGameMismatch = 4
	k_EBeginAuthSessionResultExpiredTicket = 5
End Enum

Enum EAuthSessionResponse
	k_EAuthSessionResponseOK = 0
	k_EAuthSessionResponseUserNotConnectedToSteam = 1
	k_EAuthSessionResponseNoLicenseOrExpired = 2
	k_EAuthSessionResponseVACBanned = 3
	k_EAuthSessionResponseLoggedInElseWhere = 4
	k_EAuthSessionResponseVACCheckTimedOut = 5
	k_EAuthSessionResponseAuthTicketCanceled = 6
	k_EAuthSessionResponseAuthTicketInvalidAlreadyUsed = 7
	k_EAuthSessionResponseAuthTicketInvalid = 8
	k_EAuthSessionResponsePublisherIssuedBan = 9
End Enum

Enum EUserHasLicenseForAppResult
	k_EUserHasLicenseResultHasLicense = 0
	k_EUserHasLicenseResultDoesNotHaveLicense = 1
	k_EUserHasLicenseResultNoAuth = 2
End Enum

Enum EAccountType
	k_EAccountTypeInvalid = 0
	k_EAccountTypeIndividual = 1
	k_EAccountTypeMultiseat = 2
	k_EAccountTypeGameServer = 3
	k_EAccountTypeAnonGameServer = 4
	k_EAccountTypePending = 5
	k_EAccountTypeContentServer = 6
	k_EAccountTypeClan = 7
	k_EAccountTypeChat = 8
	k_EAccountTypeConsoleUser = 9
	k_EAccountTypeAnonUser = 10
	k_EAccountTypeMax = 11
End Enum

Enum EAppReleaseState
	k_EAppReleaseState_Unknown = 0
	k_EAppReleaseState_Unavailable = 1
	k_EAppReleaseState_Prerelease = 2
	k_EAppReleaseState_PreloadOnly = 3
	k_EAppReleaseState_Released = 4
End Enum

Enum EAppOwnershipFlags Flags
	k_EAppOwnershipFlags_None = 0
	k_EAppOwnershipFlags_OwnsLicense = 1
	k_EAppOwnershipFlags_FreeLicense = 2
	k_EAppOwnershipFlags_RegionRestricted = 4
	k_EAppOwnershipFlags_LowViolence = 8
	k_EAppOwnershipFlags_InvalidPlatform = 16
	k_EAppOwnershipFlags_SharedLicense = 32
	k_EAppOwnershipFlags_FreeWeekend = 64
	k_EAppOwnershipFlags_RetailLicense = 128
	k_EAppOwnershipFlags_LicenseLocked = 256
	k_EAppOwnershipFlags_LicensePending = 512
	k_EAppOwnershipFlags_LicenseExpired = 1024
	k_EAppOwnershipFlags_LicensePermanent = 2048
	k_EAppOwnershipFlags_LicenseRecurring = 4096
	k_EAppOwnershipFlags_LicenseCanceled = 8192
	k_EAppOwnershipFlags_AutoGrant = 16384
	k_EAppOwnershipFlags_PendingGift = 32768
	k_EAppOwnershipFlags_RentalNotActivated = 65536
	k_EAppOwnershipFlags_Rental = 131072
	k_EAppOwnershipFlags_SiteLicense = 262144
End Enum

Enum EAppType:UInt Flags
	k_EAppType_Invalid = 0
	k_EAppType_Game = 1
	k_EAppType_Application = 2
	k_EAppType_Tool = 4
	k_EAppType_Demo = 8
	k_EAppType_Media_DEPRECATED = 16
	k_EAppType_DLC = 32
	k_EAppType_Guide = 64
	k_EAppType_Driver = 128
	k_EAppType_Config = 256
	k_EAppType_Hardware = 512
	k_EAppType_Franchise = 1024
	k_EAppType_Video = 2048
	k_EAppType_Plugin = 4096
	k_EAppType_Music = 8192
	k_EAppType_Series = 16384
	k_EAppType_Comic = 32768
	k_EAppType_Shortcut = 1073741824
	k_EAppType_DepotOnly = -2147483648
End Enum

Enum ESteamUserStatType
	k_ESteamUserStatTypeINVALID = 0
	k_ESteamUserStatTypeINT = 1
	k_ESteamUserStatTypeFLOAT = 2
	k_ESteamUserStatTypeAVGRATE = 3
	k_ESteamUserStatTypeACHIEVEMENTS = 4
	k_ESteamUserStatTypeGROUPACHIEVEMENTS = 5
	k_ESteamUserStatTypeMAX = 6
End Enum

Enum EChatEntryType
	k_EChatEntryTypeInvalid = 0
	k_EChatEntryTypeChatMsg = 1
	k_EChatEntryTypeTyping = 2
	k_EChatEntryTypeInviteGame = 3
	k_EChatEntryTypeEmote = 4
	k_EChatEntryTypeLeftConversation = 6
	k_EChatEntryTypeEntered = 7
	k_EChatEntryTypeWasKicked = 8
	k_EChatEntryTypeWasBanned = 9
	k_EChatEntryTypeDisconnected = 10
	k_EChatEntryTypeHistoricalChat = 11
	k_EChatEntryTypeLinkBlocked = 14
End Enum

Enum EChatRoomEnterResponse
	k_EChatRoomEnterResponseSuccess = 1
	k_EChatRoomEnterResponseDoesntExist = 2
	k_EChatRoomEnterResponseNotAllowed = 3
	k_EChatRoomEnterResponseFull = 4
	k_EChatRoomEnterResponseError = 5
	k_EChatRoomEnterResponseBanned = 6
	k_EChatRoomEnterResponseLimited = 7
	k_EChatRoomEnterResponseClanDisabled = 8
	k_EChatRoomEnterResponseCommunityBan = 9
	k_EChatRoomEnterResponseMemberBlockedYou = 10
	k_EChatRoomEnterResponseYouBlockedMember = 11
	k_EChatRoomEnterResponseRatelimitExceeded = 15
End Enum

Enum EChatSteamIDInstanceFlags
	k_EChatAccountInstanceMask = 4095
	k_EChatInstanceFlagClan = 524288
	k_EChatInstanceFlagLobby = 262144
	k_EChatInstanceFlagMMSLobby = 131072
End Enum

Enum EMarketingMessageFlags
	k_EMarketingMessageFlagsNone = 0
	k_EMarketingMessageFlagsHighPriority = 1
	k_EMarketingMessageFlagsPlatformWindows = 2
	k_EMarketingMessageFlagsPlatformMac = 4
	k_EMarketingMessageFlagsPlatformLinux = 8
	k_EMarketingMessageFlagsPlatformRestrictions = 14
End Enum

Enum ENotificationPosition
	k_EPositionTopLeft = 0
	k_EPositionTopRight = 1
	k_EPositionBottomLeft = 2
	k_EPositionBottomRight = 3
End Enum

Enum EBroadcastUploadResult
	k_EBroadcastUploadResultNone = 0
	k_EBroadcastUploadResultOK = 1
	k_EBroadcastUploadResultInitFailed = 2
	k_EBroadcastUploadResultFrameFailed = 3
	k_EBroadcastUploadResultTimeout = 4
	k_EBroadcastUploadResultBandwidthExceeded = 5
	k_EBroadcastUploadResultLowFPS = 6
	k_EBroadcastUploadResultMissingKeyFrames = 7
	k_EBroadcastUploadResultNoConnection = 8
	k_EBroadcastUploadResultRelayFailed = 9
	k_EBroadcastUploadResultSettingsChanged = 10
	k_EBroadcastUploadResultMissingAudio = 11
	k_EBroadcastUploadResultTooFarBehind = 12
	k_EBroadcastUploadResultTranscodeBehind = 13
	k_EBroadcastUploadResultNotAllowedToPlay = 14
	k_EBroadcastUploadResultBusy = 15
	k_EBroadcastUploadResultBanned = 16
	k_EBroadcastUploadResultAlreadyActive = 17
	k_EBroadcastUploadResultForcedOff = 18
	k_EBroadcastUploadResultAudioBehind = 19
	k_EBroadcastUploadResultShutdown = 20
	k_EBroadcastUploadResultDisconnect = 21
	k_EBroadcastUploadResultVideoInitFailed = 22
	k_EBroadcastUploadResultAudioInitFailed = 23
End Enum

Enum ELaunchOptionType
	k_ELaunchOptionType_None = 0
	k_ELaunchOptionType_Default = 1
	k_ELaunchOptionType_SafeMode = 2
	k_ELaunchOptionType_Multiplayer = 3
	k_ELaunchOptionType_Config = 4
	k_ELaunchOptionType_OpenVR = 5
	k_ELaunchOptionType_Server = 6
	k_ELaunchOptionType_Editor = 7
	k_ELaunchOptionType_Manual = 8
	k_ELaunchOptionType_Benchmark = 9
	k_ELaunchOptionType_Option1 = 10
	k_ELaunchOptionType_Option2 = 11
	k_ELaunchOptionType_Option3 = 12
	k_ELaunchOptionType_OculusVR = 13
	k_ELaunchOptionType_OpenVROverlay = 14
	k_ELaunchOptionType_OSVR = 15
	k_ELaunchOptionType_Dialog = 1000
End Enum

Enum EVRHMDType
	k_eEVRHMDType_None = -1
	k_eEVRHMDType_Unknown = 0
	k_eEVRHMDType_HTC_Dev = 1
	k_eEVRHMDType_HTC_VivePre = 2
	k_eEVRHMDType_HTC_Vive = 3
	k_eEVRHMDType_HTC_VivePro = 4
	k_eEVRHMDType_HTC_Unknown = 20
	k_eEVRHMDType_Oculus_DK1 = 21
	k_eEVRHMDType_Oculus_DK2 = 22
	k_eEVRHMDType_Oculus_Rift = 23
	k_eEVRHMDType_Oculus_Unknown = 40
	k_eEVRHMDType_Acer_Unknown = 50
	k_eEVRHMDType_Acer_WindowsMR = 51
	k_eEVRHMDType_Dell_Unknown = 60
	k_eEVRHMDType_Dell_Visor = 61
	k_eEVRHMDType_Lenovo_Unknown = 70
	k_eEVRHMDType_Lenovo_Explorer = 71
	k_eEVRHMDType_HP_Unknown = 80
	k_eEVRHMDType_HP_WindowsMR = 81
	k_eEVRHMDType_Samsung_Unknown = 90
	k_eEVRHMDType_Samsung_Odyssey = 91
	k_eEVRHMDType_Unannounced_Unknown = 100
	k_eEVRHMDType_Unannounced_WindowsMR = 101
	k_eEVRHMDType_vridge = 110
	k_eEVRHMDType_Huawei_Unknown = 120
	k_eEVRHMDType_Huawei_VR2 = 121
	k_eEVRHMDType_Huawei_Unannounced = 129
End Enum

Enum EMarketNotAllowedReasonFlags Flags
	k_EMarketNotAllowedReason_None = 0
	k_EMarketNotAllowedReason_TemporaryFailure = 1
	k_EMarketNotAllowedReason_AccountDisabled = 2
	k_EMarketNotAllowedReason_AccountLockedDown = 4
	k_EMarketNotAllowedReason_AccountLimited = 8
	k_EMarketNotAllowedReason_TradeBanned = 16
	k_EMarketNotAllowedReason_AccountNotTrusted = 32
	k_EMarketNotAllowedReason_SteamGuardNotEnabled = 64
	k_EMarketNotAllowedReason_SteamGuardOnlyRecentlyEnabled = 128
	k_EMarketNotAllowedReason_RecentPasswordReset = 256
	k_EMarketNotAllowedReason_NewPaymentMethod = 512
	k_EMarketNotAllowedReason_InvalidCookie = 1024
	k_EMarketNotAllowedReason_UsingNewDevice = 2048
	k_EMarketNotAllowedReason_RecentSelfRefund = 4096
	k_EMarketNotAllowedReason_NewPaymentMethodCannotBeVerified = 8192
	k_EMarketNotAllowedReason_NoRecentPurchases = 16384
	k_EMarketNotAllowedReason_AcceptedWalletGift = 32768
End Enum

Enum EGameIDType
	k_EGameIDTypeApp = 0
	k_EGameIDTypeGameMod = 1
	k_EGameIDTypeShortcut = 2
	k_EGameIDTypeP2P = 3
End Enum

Enum EGameSearchErrorCode_t
	k_EGameSearchErrorCode_OK = 1
	k_EGameSearchErrorCode_Failed_Search_Already_In_Progress = 2
	k_EGameSearchErrorCode_Failed_No_Search_In_Progress = 3
	k_EGameSearchErrorCode_Failed_Not_Lobby_Leader = 4
	k_EGameSearchErrorCode_Failed_No_Host_Available = 5
	k_EGameSearchErrorCode_Failed_Search_Params_Invalid = 6
	k_EGameSearchErrorCode_Failed_Offline = 7
	k_EGameSearchErrorCode_Failed_NotAuthorized = 8
	k_EGameSearchErrorCode_Failed_Unknown_Error = 9
End Enum

Enum EPlayerResult_t
	k_EPlayerResultFailedToConnect = 1
	k_EPlayerResultAbandoned = 2
	k_EPlayerResultKicked = 3
	k_EPlayerResultIncomplete = 4
	k_EPlayerResultCompleted = 5
End Enum

Enum EFailureType
	k_EFailureFlushedCallbackQueue = 0
	k_EFailurePipeFail = 1
End Enum

Enum EFriendRelationship
	k_EFriendRelationshipNone = 0
	k_EFriendRelationshipBlocked = 1
	k_EFriendRelationshipRequestRecipient = 2
	k_EFriendRelationshipFriend = 3
	k_EFriendRelationshipRequestInitiator = 4
	k_EFriendRelationshipIgnored = 5
	k_EFriendRelationshipIgnoredFriend = 6
	k_EFriendRelationshipSuggested_DEPRECATED = 7
	k_EFriendRelationshipMax = 8
End Enum

Rem
bbdoc: List of states a Steam friend can be in.
End Rem
Enum EPersonaState
	k_EPersonaStateOffline = 0
	k_EPersonaStateOnline = 1
	k_EPersonaStateBusy = 2
	k_EPersonaStateAway = 3
	k_EPersonaStateSnooze = 4
	k_EPersonaStateLookingToTrade = 5
	k_EPersonaStateLookingToPlay = 6
	k_EPersonaStateInvisible = 7
	k_EPersonaStateMax = 8
End Enum

Enum EFriendFlags Flags
	k_EFriendFlagNone = 0
	k_EFriendFlagBlocked = 1
	k_EFriendFlagFriendshipRequested = 2
	k_EFriendFlagImmediate = 4
	k_EFriendFlagClanMember = 8
	k_EFriendFlagOnGameServer = 16
	k_EFriendFlagRequestingFriendship = 128
	k_EFriendFlagRequestingInfo = 256
	k_EFriendFlagIgnored = 512
	k_EFriendFlagIgnoredFriend = 1024
	k_EFriendFlagChatMember = 4096
	k_EFriendFlagAll = 65535
End Enum

Rem
bbdoc: User restriction flags.
about: These are returned by #GetUserRestrictions.
End Rem
Enum EUserRestriction Flags
	k_nUserRestrictionNone = 0
	k_nUserRestrictionUnknown = 1
	k_nUserRestrictionAnyChat = 2
	k_nUserRestrictionVoiceChat = 4
	k_nUserRestrictionGroupChat = 8
	k_nUserRestrictionRating = 16
	k_nUserRestrictionGameInvites = 32
	k_nUserRestrictionTrading = 64
End Enum

Enum EOverlayToStoreFlag
	k_EOverlayToStoreFlag_None = 0
	k_EOverlayToStoreFlag_AddToCart = 1
	k_EOverlayToStoreFlag_AddToCartAndShow = 2
End Enum

Enum EActivateGameOverlayToWebPageMode
	k_EActivateGameOverlayToWebPageMode_Default = 0
	k_EActivateGameOverlayToWebPageMode_Modal = 1
End Enum

Rem
bbdoc: Used in #OnPersonaStateChange, @changeFlags to describe what's changed about a user.
These flags describe what the client has learned has changed recently, so on startup you'll see a name, avatar and relationship change for every friend
End Rem
Enum EPersonaChange Flags
	k_EPersonaChangeName = 1
	k_EPersonaChangeStatus = 2
	k_EPersonaChangeComeOnline = 4
	k_EPersonaChangeGoneOffline = 8
	k_EPersonaChangeGamePlayed = 16
	k_EPersonaChangeGameServer = 32
	k_EPersonaChangeAvatar = 64
	k_EPersonaChangeJoinedSource = 128
	k_EPersonaChangeLeftSource = 256
	k_EPersonaChangeRelationshipChanged = 512
	k_EPersonaChangeNameFirstSet = 1024
	k_EPersonaChangeBroadcast = 2048
	k_EPersonaChangeNickname = 4096
	k_EPersonaChangeSteamLevel = 8192
	k_EPersonaChangeRichPresence = 16384
End Enum

Enum ESteamAPICallFailure
	k_ESteamAPICallFailureNone = -1
	k_ESteamAPICallFailureSteamGone = 0
	k_ESteamAPICallFailureNetworkFailure = 1
	k_ESteamAPICallFailureInvalidHandle = 2
	k_ESteamAPICallFailureMismatchedCallback = 3
End Enum

Enum EGamepadTextInputMode
	k_EGamepadTextInputModeNormal = 0
	k_EGamepadTextInputModePassword = 1
End Enum

Enum EGamepadTextInputLineMode
	k_EGamepadTextInputLineModeSingleLine = 0
	k_EGamepadTextInputLineModeMultipleLines = 1
End Enum

Enum ECheckFileSignature
	k_ECheckFileSignatureInvalidSignature = 0
	k_ECheckFileSignatureValidSignature = 1
	k_ECheckFileSignatureFileNotFound = 2
	k_ECheckFileSignatureNoSignaturesFoundForThisApp = 3
	k_ECheckFileSignatureNoSignaturesFoundForThisFile = 4
End Enum

Enum EMatchMakingServerResponse
	eServerResponded = 0
	eServerFailedToRespond = 1
	eNoServersListedOnMasterServer = 2
End Enum

Enum ELobbyType
	k_ELobbyTypePrivate = 0
	k_ELobbyTypeFriendsOnly = 1
	k_ELobbyTypePublic = 2
	k_ELobbyTypeInvisible = 3
End Enum

Enum ELobbyComparison
	k_ELobbyComparisonEqualToOrLessThan = -2
	k_ELobbyComparisonLessThan = -1
	k_ELobbyComparisonEqual = 0
	k_ELobbyComparisonGreaterThan = 1
	k_ELobbyComparisonEqualToOrGreaterThan = 2
	k_ELobbyComparisonNotEqual = 3
End Enum

Enum ELobbyDistanceFilter
	k_ELobbyDistanceFilterClose = 0
	k_ELobbyDistanceFilterDefault = 1
	k_ELobbyDistanceFilterFar = 2
	k_ELobbyDistanceFilterWorldwide = 3
End Enum

Enum EChatMemberStateChange Flags
	k_EChatMemberStateChangeEntered = 1
	k_EChatMemberStateChangeLeft = 2
	k_EChatMemberStateChangeDisconnected = 4
	k_EChatMemberStateChangeKicked = 8
	k_EChatMemberStateChangeBanned = 16
End Enum

Enum ESteamPartyBeaconLocationType
	k_ESteamPartyBeaconLocationType_Invalid = 0
	k_ESteamPartyBeaconLocationType_ChatGroup = 1
	k_ESteamPartyBeaconLocationType_Max = 2
End Enum

Enum ESteamPartyBeaconLocationData
	k_ESteamPartyBeaconLocationDataInvalid = 0
	k_ESteamPartyBeaconLocationDataName = 1
	k_ESteamPartyBeaconLocationDataIconURLSmall = 2
	k_ESteamPartyBeaconLocationDataIconURLMedium = 3
	k_ESteamPartyBeaconLocationDataIconURLLarge = 4
End Enum

Enum PlayerAcceptState_t
	k_EStateUnknown = 0
	k_EStatePlayerAccepted = 1
	k_EStatePlayerDeclined = 2
End Enum

Enum ERemoteStoragePlatform Flags
	k_ERemoteStoragePlatformNone = 0
	k_ERemoteStoragePlatformWindows = 1
	k_ERemoteStoragePlatformOSX = 2
	k_ERemoteStoragePlatformPS3 = 4
	k_ERemoteStoragePlatformLinux = 8
	k_ERemoteStoragePlatformReserved2 = 16
	k_ERemoteStoragePlatformAndroid = 32
	k_ERemoteStoragePlatformAll = -1
End Enum

Rem
bbdoc: Possible visibility states that a Workshop item can be in.
End Rem
Enum ERemoteStoragePublishedFileVisibility
	k_ERemoteStoragePublishedFileVisibilityPublic = 0
	k_ERemoteStoragePublishedFileVisibilityFriendsOnly = 1
	k_ERemoteStoragePublishedFileVisibilityPrivate = 2
End Enum

Rem
bbdoc: The way that a shared file will be shared with the community.
End Rem
Enum EWorkshopFileType
	k_EWorkshopFileTypeFirst = 0
	k_EWorkshopFileTypeCommunity = 0
	k_EWorkshopFileTypeMicrotransaction = 1
	k_EWorkshopFileTypeCollection = 2
	k_EWorkshopFileTypeArt = 3
	k_EWorkshopFileTypeVideo = 4
	k_EWorkshopFileTypeScreenshot = 5
	k_EWorkshopFileTypeGame = 6
	k_EWorkshopFileTypeSoftware = 7
	k_EWorkshopFileTypeConcept = 8
	k_EWorkshopFileTypeWebGuide = 9
	k_EWorkshopFileTypeIntegratedGuide = 10
	k_EWorkshopFileTypeMerch = 11
	k_EWorkshopFileTypeControllerBinding = 12
	k_EWorkshopFileTypeSteamworksAccessInvite = 13
	k_EWorkshopFileTypeSteamVideo = 14
	k_EWorkshopFileTypeGameManagedItem = 15
	k_EWorkshopFileTypeMax = 16
End Enum

Enum EWorkshopVote
	k_EWorkshopVoteUnvoted = 0
	k_EWorkshopVoteFor = 1
	k_EWorkshopVoteAgainst = 2
	k_EWorkshopVoteLater = 3
End Enum

Enum EWorkshopFileAction
	k_EWorkshopFileActionPlayed = 0
	k_EWorkshopFileActionCompleted = 1
End Enum

Enum EWorkshopEnumerationType
	k_EWorkshopEnumerationTypeRankedByVote = 0
	k_EWorkshopEnumerationTypeRecent = 1
	k_EWorkshopEnumerationTypeTrending = 2
	k_EWorkshopEnumerationTypeFavoritesOfFriends = 3
	k_EWorkshopEnumerationTypeVotedByFriends = 4
	k_EWorkshopEnumerationTypeContentByFriends = 5
	k_EWorkshopEnumerationTypeRecentFromFollowedUsers = 6
End Enum

Enum EWorkshopVideoProvider
	k_EWorkshopVideoProviderNone = 0
	k_EWorkshopVideoProviderYoutube = 1
End Enum

Enum EUGCReadAction
	k_EUGCRead_ContinueReadingUntilFinished = 0
	k_EUGCRead_ContinueReading = 1
	k_EUGCRead_Close = 2
End Enum

Enum ELeaderboardDataRequest
	k_ELeaderboardDataRequestGlobal = 0
	k_ELeaderboardDataRequestGlobalAroundUser = 1
	k_ELeaderboardDataRequestFriends = 2
	k_ELeaderboardDataRequestUsers = 3
End Enum

Enum ELeaderboardSortMethod
	k_ELeaderboardSortMethodNone = 0
	k_ELeaderboardSortMethodAscending = 1
	k_ELeaderboardSortMethodDescending = 2
End Enum

Enum ELeaderboardDisplayType
	k_ELeaderboardDisplayTypeNone = 0
	k_ELeaderboardDisplayTypeNumeric = 1
	k_ELeaderboardDisplayTypeTimeSeconds = 2
	k_ELeaderboardDisplayTypeTimeMilliSeconds = 3
End Enum

Enum ELeaderboardUploadScoreMethod
	k_ELeaderboardUploadScoreMethodNone = 0
	k_ELeaderboardUploadScoreMethodKeepBest = 1
	k_ELeaderboardUploadScoreMethodForceUpdate = 2
End Enum

Enum ERegisterActivationCodeResult
	k_ERegisterActivationCodeResultOK = 0
	k_ERegisterActivationCodeResultFail = 1
	k_ERegisterActivationCodeResultAlreadyRegistered = 2
	k_ERegisterActivationCodeResultTimeout = 3
	k_ERegisterActivationCodeAlreadyOwned = 4
End Enum

Enum EP2PSessionError
	k_EP2PSessionErrorNone = 0
	k_EP2PSessionErrorNotRunningApp = 1
	k_EP2PSessionErrorNoRightsToApp = 2
	k_EP2PSessionErrorDestinationNotLoggedIn = 3
	k_EP2PSessionErrorTimeout = 4
	k_EP2PSessionErrorMax = 5
End Enum

Enum EP2PSend
	k_EP2PSendUnreliable = 0
	k_EP2PSendUnreliableNoDelay = 1
	k_EP2PSendReliable = 2
	k_EP2PSendReliableWithBuffering = 3
End Enum

Enum ESNetSocketState
	k_ESNetSocketStateInvalid = 0
	k_ESNetSocketStateConnected = 1
	k_ESNetSocketStateInitiated = 10
	k_ESNetSocketStateLocalCandidatesFound = 11
	k_ESNetSocketStateReceivedRemoteCandidates = 12
	k_ESNetSocketStateChallengeHandshake = 15
	k_ESNetSocketStateDisconnecting = 21
	k_ESNetSocketStateLocalDisconnect = 22
	k_ESNetSocketStateTimeoutDuringConnect = 23
	k_ESNetSocketStateRemoteEndDisconnected = 24
	k_ESNetSocketStateConnectionBroken = 25
End Enum

Enum ESNetSocketConnectionType
	k_ESNetSocketConnectionTypeNotConnected = 0
	k_ESNetSocketConnectionTypeUDP = 1
	k_ESNetSocketConnectionTypeUDPRelay = 2
End Enum

Enum EVRScreenshotType
	k_EVRScreenshotType_None = 0
	k_EVRScreenshotType_Mono = 1
	k_EVRScreenshotType_Stereo = 2
	k_EVRScreenshotType_MonoCubemap = 3
	k_EVRScreenshotType_MonoPanorama = 4
	k_EVRScreenshotType_StereoPanorama = 5
End Enum

Enum AudioPlayback_Status
	AudioPlayback_Undefined = 0
	AudioPlayback_Playing = 1
	AudioPlayback_Paused = 2
	AudioPlayback_Idle = 3
End Enum

Enum EHTTPMethod
	k_EHTTPMethodInvalid = 0
	k_EHTTPMethodGET = 1
	k_EHTTPMethodHEAD = 2
	k_EHTTPMethodPOST = 3
	k_EHTTPMethodPUT = 4
	k_EHTTPMethodDELETE = 5
	k_EHTTPMethodOPTIONS = 6
	k_EHTTPMethodPATCH = 7
End Enum

Enum EHTTPStatusCode
	k_EHTTPStatusCodeInvalid = 0
	k_EHTTPStatusCode100Continue = 100
	k_EHTTPStatusCode101SwitchingProtocols = 101
	k_EHTTPStatusCode200OK = 200
	k_EHTTPStatusCode201Created = 201
	k_EHTTPStatusCode202Accepted = 202
	k_EHTTPStatusCode203NonAuthoritative = 203
	k_EHTTPStatusCode204NoContent = 204
	k_EHTTPStatusCode205ResetContent = 205
	k_EHTTPStatusCode206PartialContent = 206
	k_EHTTPStatusCode300MultipleChoices = 300
	k_EHTTPStatusCode301MovedPermanently = 301
	k_EHTTPStatusCode302Found = 302
	k_EHTTPStatusCode303SeeOther = 303
	k_EHTTPStatusCode304NotModified = 304
	k_EHTTPStatusCode305UseProxy = 305
	k_EHTTPStatusCode307TemporaryRedirect = 307
	k_EHTTPStatusCode400BadRequest = 400
	k_EHTTPStatusCode401Unauthorized = 401
	k_EHTTPStatusCode402PaymentRequired = 402
	k_EHTTPStatusCode403Forbidden = 403
	k_EHTTPStatusCode404NotFound = 404
	k_EHTTPStatusCode405MethodNotAllowed = 405
	k_EHTTPStatusCode406NotAcceptable = 406
	k_EHTTPStatusCode407ProxyAuthRequired = 407
	k_EHTTPStatusCode408RequestTimeout = 408
	k_EHTTPStatusCode409Conflict = 409
	k_EHTTPStatusCode410Gone = 410
	k_EHTTPStatusCode411LengthRequired = 411
	k_EHTTPStatusCode412PreconditionFailed = 412
	k_EHTTPStatusCode413RequestEntityTooLarge = 413
	k_EHTTPStatusCode414RequestURITooLong = 414
	k_EHTTPStatusCode415UnsupportedMediaType = 415
	k_EHTTPStatusCode416RequestedRangeNotSatisfiable = 416
	k_EHTTPStatusCode417ExpectationFailed = 417
	k_EHTTPStatusCode4xxUnknown = 418
	k_EHTTPStatusCode429TooManyRequests = 429
	k_EHTTPStatusCode500InternalServerError = 500
	k_EHTTPStatusCode501NotImplemented = 501
	k_EHTTPStatusCode502BadGateway = 502
	k_EHTTPStatusCode503ServiceUnavailable = 503
	k_EHTTPStatusCode504GatewayTimeout = 504
	k_EHTTPStatusCode505HTTPVersionNotSupported = 505
	k_EHTTPStatusCode5xxUnknown = 599
End Enum

Enum EInputSource
	k_EInputSource_None = 0
	k_EInputSource_LeftTrackpad = 1
	k_EInputSource_RightTrackpad = 2
	k_EInputSource_Joystick = 3
	k_EInputSource_ABXY = 4
	k_EInputSource_Switch = 5
	k_EInputSource_LeftTrigger = 6
	k_EInputSource_RightTrigger = 7
	k_EInputSource_LeftBumper = 8
	k_EInputSource_RightBumper = 9
	k_EInputSource_Gyro = 10
	k_EInputSource_CenterTrackpad = 11
	k_EInputSource_RightJoystick = 12
	k_EInputSource_DPad = 13
	k_EInputSource_Key = 14
	k_EInputSource_Mouse = 15
	k_EInputSource_LeftGyro = 16
	k_EInputSource_Count = 17
End Enum

Enum EInputSourceMode
	k_EInputSourceMode_None = 0
	k_EInputSourceMode_Dpad = 1
	k_EInputSourceMode_Buttons = 2
	k_EInputSourceMode_FourButtons = 3
	k_EInputSourceMode_AbsoluteMouse = 4
	k_EInputSourceMode_RelativeMouse = 5
	k_EInputSourceMode_JoystickMove = 6
	k_EInputSourceMode_JoystickMouse = 7
	k_EInputSourceMode_JoystickCamera = 8
	k_EInputSourceMode_ScrollWheel = 9
	k_EInputSourceMode_Trigger = 10
	k_EInputSourceMode_TouchMenu = 11
	k_EInputSourceMode_MouseJoystick = 12
	k_EInputSourceMode_MouseRegion = 13
	k_EInputSourceMode_RadialMenu = 14
	k_EInputSourceMode_SingleButton = 15
	k_EInputSourceMode_Switches = 16
End Enum

Enum EInputActionOrigin
	k_EInputActionOrigin_None = 0
	k_EInputActionOrigin_SteamController_A = 1
	k_EInputActionOrigin_SteamController_B = 2
	k_EInputActionOrigin_SteamController_X = 3
	k_EInputActionOrigin_SteamController_Y = 4
	k_EInputActionOrigin_SteamController_LeftBumper = 5
	k_EInputActionOrigin_SteamController_RightBumper = 6
	k_EInputActionOrigin_SteamController_LeftGrip = 7
	k_EInputActionOrigin_SteamController_RightGrip = 8
	k_EInputActionOrigin_SteamController_Start = 9
	k_EInputActionOrigin_SteamController_Back = 10
	k_EInputActionOrigin_SteamController_LeftPad_Touch = 11
	k_EInputActionOrigin_SteamController_LeftPad_Swipe = 12
	k_EInputActionOrigin_SteamController_LeftPad_Click = 13
	k_EInputActionOrigin_SteamController_LeftPad_DPadNorth = 14
	k_EInputActionOrigin_SteamController_LeftPad_DPadSouth = 15
	k_EInputActionOrigin_SteamController_LeftPad_DPadWest = 16
	k_EInputActionOrigin_SteamController_LeftPad_DPadEast = 17
	k_EInputActionOrigin_SteamController_RightPad_Touch = 18
	k_EInputActionOrigin_SteamController_RightPad_Swipe = 19
	k_EInputActionOrigin_SteamController_RightPad_Click = 20
	k_EInputActionOrigin_SteamController_RightPad_DPadNorth = 21
	k_EInputActionOrigin_SteamController_RightPad_DPadSouth = 22
	k_EInputActionOrigin_SteamController_RightPad_DPadWest = 23
	k_EInputActionOrigin_SteamController_RightPad_DPadEast = 24
	k_EInputActionOrigin_SteamController_LeftTrigger_Pull = 25
	k_EInputActionOrigin_SteamController_LeftTrigger_Click = 26
	k_EInputActionOrigin_SteamController_RightTrigger_Pull = 27
	k_EInputActionOrigin_SteamController_RightTrigger_Click = 28
	k_EInputActionOrigin_SteamController_LeftStick_Move = 29
	k_EInputActionOrigin_SteamController_LeftStick_Click = 30
	k_EInputActionOrigin_SteamController_LeftStick_DPadNorth = 31
	k_EInputActionOrigin_SteamController_LeftStick_DPadSouth = 32
	k_EInputActionOrigin_SteamController_LeftStick_DPadWest = 33
	k_EInputActionOrigin_SteamController_LeftStick_DPadEast = 34
	k_EInputActionOrigin_SteamController_Gyro_Move = 35
	k_EInputActionOrigin_SteamController_Gyro_Pitch = 36
	k_EInputActionOrigin_SteamController_Gyro_Yaw = 37
	k_EInputActionOrigin_SteamController_Gyro_Roll = 38
	k_EInputActionOrigin_SteamController_Reserved0 = 39
	k_EInputActionOrigin_SteamController_Reserved1 = 40
	k_EInputActionOrigin_SteamController_Reserved2 = 41
	k_EInputActionOrigin_SteamController_Reserved3 = 42
	k_EInputActionOrigin_SteamController_Reserved4 = 43
	k_EInputActionOrigin_SteamController_Reserved5 = 44
	k_EInputActionOrigin_SteamController_Reserved6 = 45
	k_EInputActionOrigin_SteamController_Reserved7 = 46
	k_EInputActionOrigin_SteamController_Reserved8 = 47
	k_EInputActionOrigin_SteamController_Reserved9 = 48
	k_EInputActionOrigin_SteamController_Reserved10 = 49
	k_EInputActionOrigin_PS4_X = 50
	k_EInputActionOrigin_PS4_Circle = 51
	k_EInputActionOrigin_PS4_Triangle = 52
	k_EInputActionOrigin_PS4_Square = 53
	k_EInputActionOrigin_PS4_LeftBumper = 54
	k_EInputActionOrigin_PS4_RightBumper = 55
	k_EInputActionOrigin_PS4_Options = 56
	k_EInputActionOrigin_PS4_Share = 57
	k_EInputActionOrigin_PS4_LeftPad_Touch = 58
	k_EInputActionOrigin_PS4_LeftPad_Swipe = 59
	k_EInputActionOrigin_PS4_LeftPad_Click = 60
	k_EInputActionOrigin_PS4_LeftPad_DPadNorth = 61
	k_EInputActionOrigin_PS4_LeftPad_DPadSouth = 62
	k_EInputActionOrigin_PS4_LeftPad_DPadWest = 63
	k_EInputActionOrigin_PS4_LeftPad_DPadEast = 64
	k_EInputActionOrigin_PS4_RightPad_Touch = 65
	k_EInputActionOrigin_PS4_RightPad_Swipe = 66
	k_EInputActionOrigin_PS4_RightPad_Click = 67
	k_EInputActionOrigin_PS4_RightPad_DPadNorth = 68
	k_EInputActionOrigin_PS4_RightPad_DPadSouth = 69
	k_EInputActionOrigin_PS4_RightPad_DPadWest = 70
	k_EInputActionOrigin_PS4_RightPad_DPadEast = 71
	k_EInputActionOrigin_PS4_CenterPad_Touch = 72
	k_EInputActionOrigin_PS4_CenterPad_Swipe = 73
	k_EInputActionOrigin_PS4_CenterPad_Click = 74
	k_EInputActionOrigin_PS4_CenterPad_DPadNorth = 75
	k_EInputActionOrigin_PS4_CenterPad_DPadSouth = 76
	k_EInputActionOrigin_PS4_CenterPad_DPadWest = 77
	k_EInputActionOrigin_PS4_CenterPad_DPadEast = 78
	k_EInputActionOrigin_PS4_LeftTrigger_Pull = 79
	k_EInputActionOrigin_PS4_LeftTrigger_Click = 80
	k_EInputActionOrigin_PS4_RightTrigger_Pull = 81
	k_EInputActionOrigin_PS4_RightTrigger_Click = 82
	k_EInputActionOrigin_PS4_LeftStick_Move = 83
	k_EInputActionOrigin_PS4_LeftStick_Click = 84
	k_EInputActionOrigin_PS4_LeftStick_DPadNorth = 85
	k_EInputActionOrigin_PS4_LeftStick_DPadSouth = 86
	k_EInputActionOrigin_PS4_LeftStick_DPadWest = 87
	k_EInputActionOrigin_PS4_LeftStick_DPadEast = 88
	k_EInputActionOrigin_PS4_RightStick_Move = 89
	k_EInputActionOrigin_PS4_RightStick_Click = 90
	k_EInputActionOrigin_PS4_RightStick_DPadNorth = 91
	k_EInputActionOrigin_PS4_RightStick_DPadSouth = 92
	k_EInputActionOrigin_PS4_RightStick_DPadWest = 93
	k_EInputActionOrigin_PS4_RightStick_DPadEast = 94
	k_EInputActionOrigin_PS4_DPad_North = 95
	k_EInputActionOrigin_PS4_DPad_South = 96
	k_EInputActionOrigin_PS4_DPad_West = 97
	k_EInputActionOrigin_PS4_DPad_East = 98
	k_EInputActionOrigin_PS4_Gyro_Move = 99
	k_EInputActionOrigin_PS4_Gyro_Pitch = 100
	k_EInputActionOrigin_PS4_Gyro_Yaw = 101
	k_EInputActionOrigin_PS4_Gyro_Roll = 102
	k_EInputActionOrigin_PS4_Reserved0 = 103
	k_EInputActionOrigin_PS4_Reserved1 = 104
	k_EInputActionOrigin_PS4_Reserved2 = 105
	k_EInputActionOrigin_PS4_Reserved3 = 106
	k_EInputActionOrigin_PS4_Reserved4 = 107
	k_EInputActionOrigin_PS4_Reserved5 = 108
	k_EInputActionOrigin_PS4_Reserved6 = 109
	k_EInputActionOrigin_PS4_Reserved7 = 110
	k_EInputActionOrigin_PS4_Reserved8 = 111
	k_EInputActionOrigin_PS4_Reserved9 = 112
	k_EInputActionOrigin_PS4_Reserved10 = 113
	k_EInputActionOrigin_XBoxOne_A = 114
	k_EInputActionOrigin_XBoxOne_B = 115
	k_EInputActionOrigin_XBoxOne_X = 116
	k_EInputActionOrigin_XBoxOne_Y = 117
	k_EInputActionOrigin_XBoxOne_LeftBumper = 118
	k_EInputActionOrigin_XBoxOne_RightBumper = 119
	k_EInputActionOrigin_XBoxOne_Menu = 120
	k_EInputActionOrigin_XBoxOne_View = 121
	k_EInputActionOrigin_XBoxOne_LeftTrigger_Pull = 122
	k_EInputActionOrigin_XBoxOne_LeftTrigger_Click = 123
	k_EInputActionOrigin_XBoxOne_RightTrigger_Pull = 124
	k_EInputActionOrigin_XBoxOne_RightTrigger_Click = 125
	k_EInputActionOrigin_XBoxOne_LeftStick_Move = 126
	k_EInputActionOrigin_XBoxOne_LeftStick_Click = 127
	k_EInputActionOrigin_XBoxOne_LeftStick_DPadNorth = 128
	k_EInputActionOrigin_XBoxOne_LeftStick_DPadSouth = 129
	k_EInputActionOrigin_XBoxOne_LeftStick_DPadWest = 130
	k_EInputActionOrigin_XBoxOne_LeftStick_DPadEast = 131
	k_EInputActionOrigin_XBoxOne_RightStick_Move = 132
	k_EInputActionOrigin_XBoxOne_RightStick_Click = 133
	k_EInputActionOrigin_XBoxOne_RightStick_DPadNorth = 134
	k_EInputActionOrigin_XBoxOne_RightStick_DPadSouth = 135
	k_EInputActionOrigin_XBoxOne_RightStick_DPadWest = 136
	k_EInputActionOrigin_XBoxOne_RightStick_DPadEast = 137
	k_EInputActionOrigin_XBoxOne_DPad_North = 138
	k_EInputActionOrigin_XBoxOne_DPad_South = 139
	k_EInputActionOrigin_XBoxOne_DPad_West = 140
	k_EInputActionOrigin_XBoxOne_DPad_East = 141
	k_EInputActionOrigin_XBoxOne_Reserved0 = 142
	k_EInputActionOrigin_XBoxOne_Reserved1 = 143
	k_EInputActionOrigin_XBoxOne_Reserved2 = 144
	k_EInputActionOrigin_XBoxOne_Reserved3 = 145
	k_EInputActionOrigin_XBoxOne_Reserved4 = 146
	k_EInputActionOrigin_XBoxOne_Reserved5 = 147
	k_EInputActionOrigin_XBoxOne_Reserved6 = 148
	k_EInputActionOrigin_XBoxOne_Reserved7 = 149
	k_EInputActionOrigin_XBoxOne_Reserved8 = 150
	k_EInputActionOrigin_XBoxOne_Reserved9 = 151
	k_EInputActionOrigin_XBoxOne_Reserved10 = 152
	k_EInputActionOrigin_XBox360_A = 153
	k_EInputActionOrigin_XBox360_B = 154
	k_EInputActionOrigin_XBox360_X = 155
	k_EInputActionOrigin_XBox360_Y = 156
	k_EInputActionOrigin_XBox360_LeftBumper = 157
	k_EInputActionOrigin_XBox360_RightBumper = 158
	k_EInputActionOrigin_XBox360_Start = 159
	k_EInputActionOrigin_XBox360_Back = 160
	k_EInputActionOrigin_XBox360_LeftTrigger_Pull = 161
	k_EInputActionOrigin_XBox360_LeftTrigger_Click = 162
	k_EInputActionOrigin_XBox360_RightTrigger_Pull = 163
	k_EInputActionOrigin_XBox360_RightTrigger_Click = 164
	k_EInputActionOrigin_XBox360_LeftStick_Move = 165
	k_EInputActionOrigin_XBox360_LeftStick_Click = 166
	k_EInputActionOrigin_XBox360_LeftStick_DPadNorth = 167
	k_EInputActionOrigin_XBox360_LeftStick_DPadSouth = 168
	k_EInputActionOrigin_XBox360_LeftStick_DPadWest = 169
	k_EInputActionOrigin_XBox360_LeftStick_DPadEast = 170
	k_EInputActionOrigin_XBox360_RightStick_Move = 171
	k_EInputActionOrigin_XBox360_RightStick_Click = 172
	k_EInputActionOrigin_XBox360_RightStick_DPadNorth = 173
	k_EInputActionOrigin_XBox360_RightStick_DPadSouth = 174
	k_EInputActionOrigin_XBox360_RightStick_DPadWest = 175
	k_EInputActionOrigin_XBox360_RightStick_DPadEast = 176
	k_EInputActionOrigin_XBox360_DPad_North = 177
	k_EInputActionOrigin_XBox360_DPad_South = 178
	k_EInputActionOrigin_XBox360_DPad_West = 179
	k_EInputActionOrigin_XBox360_DPad_East = 180
	k_EInputActionOrigin_XBox360_Reserved0 = 181
	k_EInputActionOrigin_XBox360_Reserved1 = 182
	k_EInputActionOrigin_XBox360_Reserved2 = 183
	k_EInputActionOrigin_XBox360_Reserved3 = 184
	k_EInputActionOrigin_XBox360_Reserved4 = 185
	k_EInputActionOrigin_XBox360_Reserved5 = 186
	k_EInputActionOrigin_XBox360_Reserved6 = 187
	k_EInputActionOrigin_XBox360_Reserved7 = 188
	k_EInputActionOrigin_XBox360_Reserved8 = 189
	k_EInputActionOrigin_XBox360_Reserved9 = 190
	k_EInputActionOrigin_XBox360_Reserved10 = 191
	k_EInputActionOrigin_Switch_A = 192
	k_EInputActionOrigin_Switch_B = 193
	k_EInputActionOrigin_Switch_X = 194
	k_EInputActionOrigin_Switch_Y = 195
	k_EInputActionOrigin_Switch_LeftBumper = 196
	k_EInputActionOrigin_Switch_RightBumper = 197
	k_EInputActionOrigin_Switch_Plus = 198
	k_EInputActionOrigin_Switch_Minus = 199
	k_EInputActionOrigin_Switch_Capture = 200
	k_EInputActionOrigin_Switch_LeftTrigger_Pull = 201
	k_EInputActionOrigin_Switch_LeftTrigger_Click = 202
	k_EInputActionOrigin_Switch_RightTrigger_Pull = 203
	k_EInputActionOrigin_Switch_RightTrigger_Click = 204
	k_EInputActionOrigin_Switch_LeftStick_Move = 205
	k_EInputActionOrigin_Switch_LeftStick_Click = 206
	k_EInputActionOrigin_Switch_LeftStick_DPadNorth = 207
	k_EInputActionOrigin_Switch_LeftStick_DPadSouth = 208
	k_EInputActionOrigin_Switch_LeftStick_DPadWest = 209
	k_EInputActionOrigin_Switch_LeftStick_DPadEast = 210
	k_EInputActionOrigin_Switch_RightStick_Move = 211
	k_EInputActionOrigin_Switch_RightStick_Click = 212
	k_EInputActionOrigin_Switch_RightStick_DPadNorth = 213
	k_EInputActionOrigin_Switch_RightStick_DPadSouth = 214
	k_EInputActionOrigin_Switch_RightStick_DPadWest = 215
	k_EInputActionOrigin_Switch_RightStick_DPadEast = 216
	k_EInputActionOrigin_Switch_DPad_North = 217
	k_EInputActionOrigin_Switch_DPad_South = 218
	k_EInputActionOrigin_Switch_DPad_West = 219
	k_EInputActionOrigin_Switch_DPad_East = 220
	k_EInputActionOrigin_Switch_ProGyro_Move = 221
	k_EInputActionOrigin_Switch_ProGyro_Pitch = 222
	k_EInputActionOrigin_Switch_ProGyro_Yaw = 223
	k_EInputActionOrigin_Switch_ProGyro_Roll = 224
	k_EInputActionOrigin_Switch_Reserved0 = 225
	k_EInputActionOrigin_Switch_Reserved1 = 226
	k_EInputActionOrigin_Switch_Reserved2 = 227
	k_EInputActionOrigin_Switch_Reserved3 = 228
	k_EInputActionOrigin_Switch_Reserved4 = 229
	k_EInputActionOrigin_Switch_Reserved5 = 230
	k_EInputActionOrigin_Switch_Reserved6 = 231
	k_EInputActionOrigin_Switch_Reserved7 = 232
	k_EInputActionOrigin_Switch_Reserved8 = 233
	k_EInputActionOrigin_Switch_Reserved9 = 234
	k_EInputActionOrigin_Switch_Reserved10 = 235
	k_EInputActionOrigin_Switch_RightGyro_Move = 236
	k_EInputActionOrigin_Switch_RightGyro_Pitch = 237
	k_EInputActionOrigin_Switch_RightGyro_Yaw = 238
	k_EInputActionOrigin_Switch_RightGyro_Roll = 239
	k_EInputActionOrigin_Switch_LeftGyro_Move = 240
	k_EInputActionOrigin_Switch_LeftGyro_Pitch = 241
	k_EInputActionOrigin_Switch_LeftGyro_Yaw = 242
	k_EInputActionOrigin_Switch_LeftGyro_Roll = 243
	k_EInputActionOrigin_Switch_LeftGrip_Lower = 244
	k_EInputActionOrigin_Switch_LeftGrip_Upper = 245
	k_EInputActionOrigin_Switch_RightGrip_Lower = 246
	k_EInputActionOrigin_Switch_RightGrip_Upper = 247
	k_EInputActionOrigin_Switch_Reserved11 = 248
	k_EInputActionOrigin_Switch_Reserved12 = 249
	k_EInputActionOrigin_Switch_Reserved13 = 250
	k_EInputActionOrigin_Switch_Reserved14 = 251
	k_EInputActionOrigin_Switch_Reserved15 = 252
	k_EInputActionOrigin_Switch_Reserved16 = 253
	k_EInputActionOrigin_Switch_Reserved17 = 254
	k_EInputActionOrigin_Switch_Reserved18 = 255
	k_EInputActionOrigin_Switch_Reserved19 = 256
	k_EInputActionOrigin_Switch_Reserved20 = 257
	k_EInputActionOrigin_Count = 258
	k_EInputActionOrigin_MaximumPossibleValue = 32767
End Enum

Enum EXboxOrigin
	k_EXboxOrigin_A = 0
	k_EXboxOrigin_B = 1
	k_EXboxOrigin_X = 2
	k_EXboxOrigin_Y = 3
	k_EXboxOrigin_LeftBumper = 4
	k_EXboxOrigin_RightBumper = 5
	k_EXboxOrigin_Menu = 6
	k_EXboxOrigin_View = 7
	k_EXboxOrigin_LeftTrigger_Pull = 8
	k_EXboxOrigin_LeftTrigger_Click = 9
	k_EXboxOrigin_RightTrigger_Pull = 10
	k_EXboxOrigin_RightTrigger_Click = 11
	k_EXboxOrigin_LeftStick_Move = 12
	k_EXboxOrigin_LeftStick_Click = 13
	k_EXboxOrigin_LeftStick_DPadNorth = 14
	k_EXboxOrigin_LeftStick_DPadSouth = 15
	k_EXboxOrigin_LeftStick_DPadWest = 16
	k_EXboxOrigin_LeftStick_DPadEast = 17
	k_EXboxOrigin_RightStick_Move = 18
	k_EXboxOrigin_RightStick_Click = 19
	k_EXboxOrigin_RightStick_DPadNorth = 20
	k_EXboxOrigin_RightStick_DPadSouth = 21
	k_EXboxOrigin_RightStick_DPadWest = 22
	k_EXboxOrigin_RightStick_DPadEast = 23
	k_EXboxOrigin_DPad_North = 24
	k_EXboxOrigin_DPad_South = 25
	k_EXboxOrigin_DPad_West = 26
	k_EXboxOrigin_DPad_East = 27
	k_EXboxOrigin_Count = 28
End Enum

Enum ESteamControllerPad
	k_ESteamControllerPad_Left = 0
	k_ESteamControllerPad_Right = 1
End Enum

Enum ESteamInputType
	k_ESteamInputType_Unknown = 0
	k_ESteamInputType_SteamController = 1
	k_ESteamInputType_XBox360Controller = 2
	k_ESteamInputType_XBoxOneController = 3
	k_ESteamInputType_GenericGamepad = 4
	k_ESteamInputType_PS4Controller = 5
	k_ESteamInputType_AppleMFiController = 6
	k_ESteamInputType_AndroidController = 7
	k_ESteamInputType_SwitchJoyConPair = 8
	k_ESteamInputType_SwitchJoyConSingle = 9
	k_ESteamInputType_SwitchProController = 10
	k_ESteamInputType_MobileTouch = 11
	k_ESteamInputType_PS3Controller = 12
	k_ESteamInputType_Count = 13
	k_ESteamInputType_MaximumPossibleValue = 255
End Enum

Enum ESteamInputLEDFlag
	k_ESteamInputLEDFlag_SetColor = 0
	k_ESteamInputLEDFlag_RestoreUserDefault = 1
End Enum

Enum EControllerSource
	k_EControllerSource_None = 0
	k_EControllerSource_LeftTrackpad = 1
	k_EControllerSource_RightTrackpad = 2
	k_EControllerSource_Joystick = 3
	k_EControllerSource_ABXY = 4
	k_EControllerSource_Switch = 5
	k_EControllerSource_LeftTrigger = 6
	k_EControllerSource_RightTrigger = 7
	k_EControllerSource_LeftBumper = 8
	k_EControllerSource_RightBumper = 9
	k_EControllerSource_Gyro = 10
	k_EControllerSource_CenterTrackpad = 11
	k_EControllerSource_RightJoystick = 12
	k_EControllerSource_DPad = 13
	k_EControllerSource_Key = 14
	k_EControllerSource_Mouse = 15
	k_EControllerSource_LeftGyro = 16
	k_EControllerSource_Count = 17
End Enum

Enum EControllerSourceMode
	k_EControllerSourceMode_None = 0
	k_EControllerSourceMode_Dpad = 1
	k_EControllerSourceMode_Buttons = 2
	k_EControllerSourceMode_FourButtons = 3
	k_EControllerSourceMode_AbsoluteMouse = 4
	k_EControllerSourceMode_RelativeMouse = 5
	k_EControllerSourceMode_JoystickMove = 6
	k_EControllerSourceMode_JoystickMouse = 7
	k_EControllerSourceMode_JoystickCamera = 8
	k_EControllerSourceMode_ScrollWheel = 9
	k_EControllerSourceMode_Trigger = 10
	k_EControllerSourceMode_TouchMenu = 11
	k_EControllerSourceMode_MouseJoystick = 12
	k_EControllerSourceMode_MouseRegion = 13
	k_EControllerSourceMode_RadialMenu = 14
	k_EControllerSourceMode_SingleButton = 15
	k_EControllerSourceMode_Switches = 16
End Enum

Enum EControllerActionOrigin
	k_EControllerActionOrigin_None = 0
	k_EControllerActionOrigin_A = 1
	k_EControllerActionOrigin_B = 2
	k_EControllerActionOrigin_X = 3
	k_EControllerActionOrigin_Y = 4
	k_EControllerActionOrigin_LeftBumper = 5
	k_EControllerActionOrigin_RightBumper = 6
	k_EControllerActionOrigin_LeftGrip = 7
	k_EControllerActionOrigin_RightGrip = 8
	k_EControllerActionOrigin_Start = 9
	k_EControllerActionOrigin_Back = 10
	k_EControllerActionOrigin_LeftPad_Touch = 11
	k_EControllerActionOrigin_LeftPad_Swipe = 12
	k_EControllerActionOrigin_LeftPad_Click = 13
	k_EControllerActionOrigin_LeftPad_DPadNorth = 14
	k_EControllerActionOrigin_LeftPad_DPadSouth = 15
	k_EControllerActionOrigin_LeftPad_DPadWest = 16
	k_EControllerActionOrigin_LeftPad_DPadEast = 17
	k_EControllerActionOrigin_RightPad_Touch = 18
	k_EControllerActionOrigin_RightPad_Swipe = 19
	k_EControllerActionOrigin_RightPad_Click = 20
	k_EControllerActionOrigin_RightPad_DPadNorth = 21
	k_EControllerActionOrigin_RightPad_DPadSouth = 22
	k_EControllerActionOrigin_RightPad_DPadWest = 23
	k_EControllerActionOrigin_RightPad_DPadEast = 24
	k_EControllerActionOrigin_LeftTrigger_Pull = 25
	k_EControllerActionOrigin_LeftTrigger_Click = 26
	k_EControllerActionOrigin_RightTrigger_Pull = 27
	k_EControllerActionOrigin_RightTrigger_Click = 28
	k_EControllerActionOrigin_LeftStick_Move = 29
	k_EControllerActionOrigin_LeftStick_Click = 30
	k_EControllerActionOrigin_LeftStick_DPadNorth = 31
	k_EControllerActionOrigin_LeftStick_DPadSouth = 32
	k_EControllerActionOrigin_LeftStick_DPadWest = 33
	k_EControllerActionOrigin_LeftStick_DPadEast = 34
	k_EControllerActionOrigin_Gyro_Move = 35
	k_EControllerActionOrigin_Gyro_Pitch = 36
	k_EControllerActionOrigin_Gyro_Yaw = 37
	k_EControllerActionOrigin_Gyro_Roll = 38
	k_EControllerActionOrigin_PS4_X = 39
	k_EControllerActionOrigin_PS4_Circle = 40
	k_EControllerActionOrigin_PS4_Triangle = 41
	k_EControllerActionOrigin_PS4_Square = 42
	k_EControllerActionOrigin_PS4_LeftBumper = 43
	k_EControllerActionOrigin_PS4_RightBumper = 44
	k_EControllerActionOrigin_PS4_Options = 45
	k_EControllerActionOrigin_PS4_Share = 46
	k_EControllerActionOrigin_PS4_LeftPad_Touch = 47
	k_EControllerActionOrigin_PS4_LeftPad_Swipe = 48
	k_EControllerActionOrigin_PS4_LeftPad_Click = 49
	k_EControllerActionOrigin_PS4_LeftPad_DPadNorth = 50
	k_EControllerActionOrigin_PS4_LeftPad_DPadSouth = 51
	k_EControllerActionOrigin_PS4_LeftPad_DPadWest = 52
	k_EControllerActionOrigin_PS4_LeftPad_DPadEast = 53
	k_EControllerActionOrigin_PS4_RightPad_Touch = 54
	k_EControllerActionOrigin_PS4_RightPad_Swipe = 55
	k_EControllerActionOrigin_PS4_RightPad_Click = 56
	k_EControllerActionOrigin_PS4_RightPad_DPadNorth = 57
	k_EControllerActionOrigin_PS4_RightPad_DPadSouth = 58
	k_EControllerActionOrigin_PS4_RightPad_DPadWest = 59
	k_EControllerActionOrigin_PS4_RightPad_DPadEast = 60
	k_EControllerActionOrigin_PS4_CenterPad_Touch = 61
	k_EControllerActionOrigin_PS4_CenterPad_Swipe = 62
	k_EControllerActionOrigin_PS4_CenterPad_Click = 63
	k_EControllerActionOrigin_PS4_CenterPad_DPadNorth = 64
	k_EControllerActionOrigin_PS4_CenterPad_DPadSouth = 65
	k_EControllerActionOrigin_PS4_CenterPad_DPadWest = 66
	k_EControllerActionOrigin_PS4_CenterPad_DPadEast = 67
	k_EControllerActionOrigin_PS4_LeftTrigger_Pull = 68
	k_EControllerActionOrigin_PS4_LeftTrigger_Click = 69
	k_EControllerActionOrigin_PS4_RightTrigger_Pull = 70
	k_EControllerActionOrigin_PS4_RightTrigger_Click = 71
	k_EControllerActionOrigin_PS4_LeftStick_Move = 72
	k_EControllerActionOrigin_PS4_LeftStick_Click = 73
	k_EControllerActionOrigin_PS4_LeftStick_DPadNorth = 74
	k_EControllerActionOrigin_PS4_LeftStick_DPadSouth = 75
	k_EControllerActionOrigin_PS4_LeftStick_DPadWest = 76
	k_EControllerActionOrigin_PS4_LeftStick_DPadEast = 77
	k_EControllerActionOrigin_PS4_RightStick_Move = 78
	k_EControllerActionOrigin_PS4_RightStick_Click = 79
	k_EControllerActionOrigin_PS4_RightStick_DPadNorth = 80
	k_EControllerActionOrigin_PS4_RightStick_DPadSouth = 81
	k_EControllerActionOrigin_PS4_RightStick_DPadWest = 82
	k_EControllerActionOrigin_PS4_RightStick_DPadEast = 83
	k_EControllerActionOrigin_PS4_DPad_North = 84
	k_EControllerActionOrigin_PS4_DPad_South = 85
	k_EControllerActionOrigin_PS4_DPad_West = 86
	k_EControllerActionOrigin_PS4_DPad_East = 87
	k_EControllerActionOrigin_PS4_Gyro_Move = 88
	k_EControllerActionOrigin_PS4_Gyro_Pitch = 89
	k_EControllerActionOrigin_PS4_Gyro_Yaw = 90
	k_EControllerActionOrigin_PS4_Gyro_Roll = 91
	k_EControllerActionOrigin_XBoxOne_A = 92
	k_EControllerActionOrigin_XBoxOne_B = 93
	k_EControllerActionOrigin_XBoxOne_X = 94
	k_EControllerActionOrigin_XBoxOne_Y = 95
	k_EControllerActionOrigin_XBoxOne_LeftBumper = 96
	k_EControllerActionOrigin_XBoxOne_RightBumper = 97
	k_EControllerActionOrigin_XBoxOne_Menu = 98
	k_EControllerActionOrigin_XBoxOne_View = 99
	k_EControllerActionOrigin_XBoxOne_LeftTrigger_Pull = 100
	k_EControllerActionOrigin_XBoxOne_LeftTrigger_Click = 101
	k_EControllerActionOrigin_XBoxOne_RightTrigger_Pull = 102
	k_EControllerActionOrigin_XBoxOne_RightTrigger_Click = 103
	k_EControllerActionOrigin_XBoxOne_LeftStick_Move = 104
	k_EControllerActionOrigin_XBoxOne_LeftStick_Click = 105
	k_EControllerActionOrigin_XBoxOne_LeftStick_DPadNorth = 106
	k_EControllerActionOrigin_XBoxOne_LeftStick_DPadSouth = 107
	k_EControllerActionOrigin_XBoxOne_LeftStick_DPadWest = 108
	k_EControllerActionOrigin_XBoxOne_LeftStick_DPadEast = 109
	k_EControllerActionOrigin_XBoxOne_RightStick_Move = 110
	k_EControllerActionOrigin_XBoxOne_RightStick_Click = 111
	k_EControllerActionOrigin_XBoxOne_RightStick_DPadNorth = 112
	k_EControllerActionOrigin_XBoxOne_RightStick_DPadSouth = 113
	k_EControllerActionOrigin_XBoxOne_RightStick_DPadWest = 114
	k_EControllerActionOrigin_XBoxOne_RightStick_DPadEast = 115
	k_EControllerActionOrigin_XBoxOne_DPad_North = 116
	k_EControllerActionOrigin_XBoxOne_DPad_South = 117
	k_EControllerActionOrigin_XBoxOne_DPad_West = 118
	k_EControllerActionOrigin_XBoxOne_DPad_East = 119
	k_EControllerActionOrigin_XBox360_A = 120
	k_EControllerActionOrigin_XBox360_B = 121
	k_EControllerActionOrigin_XBox360_X = 122
	k_EControllerActionOrigin_XBox360_Y = 123
	k_EControllerActionOrigin_XBox360_LeftBumper = 124
	k_EControllerActionOrigin_XBox360_RightBumper = 125
	k_EControllerActionOrigin_XBox360_Start = 126
	k_EControllerActionOrigin_XBox360_Back = 127
	k_EControllerActionOrigin_XBox360_LeftTrigger_Pull = 128
	k_EControllerActionOrigin_XBox360_LeftTrigger_Click = 129
	k_EControllerActionOrigin_XBox360_RightTrigger_Pull = 130
	k_EControllerActionOrigin_XBox360_RightTrigger_Click = 131
	k_EControllerActionOrigin_XBox360_LeftStick_Move = 132
	k_EControllerActionOrigin_XBox360_LeftStick_Click = 133
	k_EControllerActionOrigin_XBox360_LeftStick_DPadNorth = 134
	k_EControllerActionOrigin_XBox360_LeftStick_DPadSouth = 135
	k_EControllerActionOrigin_XBox360_LeftStick_DPadWest = 136
	k_EControllerActionOrigin_XBox360_LeftStick_DPadEast = 137
	k_EControllerActionOrigin_XBox360_RightStick_Move = 138
	k_EControllerActionOrigin_XBox360_RightStick_Click = 139
	k_EControllerActionOrigin_XBox360_RightStick_DPadNorth = 140
	k_EControllerActionOrigin_XBox360_RightStick_DPadSouth = 141
	k_EControllerActionOrigin_XBox360_RightStick_DPadWest = 142
	k_EControllerActionOrigin_XBox360_RightStick_DPadEast = 143
	k_EControllerActionOrigin_XBox360_DPad_North = 144
	k_EControllerActionOrigin_XBox360_DPad_South = 145
	k_EControllerActionOrigin_XBox360_DPad_West = 146
	k_EControllerActionOrigin_XBox360_DPad_East = 147
	k_EControllerActionOrigin_SteamV2_A = 148
	k_EControllerActionOrigin_SteamV2_B = 149
	k_EControllerActionOrigin_SteamV2_X = 150
	k_EControllerActionOrigin_SteamV2_Y = 151
	k_EControllerActionOrigin_SteamV2_LeftBumper = 152
	k_EControllerActionOrigin_SteamV2_RightBumper = 153
	k_EControllerActionOrigin_SteamV2_LeftGrip_Lower = 154
	k_EControllerActionOrigin_SteamV2_LeftGrip_Upper = 155
	k_EControllerActionOrigin_SteamV2_RightGrip_Lower = 156
	k_EControllerActionOrigin_SteamV2_RightGrip_Upper = 157
	k_EControllerActionOrigin_SteamV2_LeftBumper_Pressure = 158
	k_EControllerActionOrigin_SteamV2_RightBumper_Pressure = 159
	k_EControllerActionOrigin_SteamV2_LeftGrip_Pressure = 160
	k_EControllerActionOrigin_SteamV2_RightGrip_Pressure = 161
	k_EControllerActionOrigin_SteamV2_LeftGrip_Upper_Pressure = 162
	k_EControllerActionOrigin_SteamV2_RightGrip_Upper_Pressure = 163
	k_EControllerActionOrigin_SteamV2_Start = 164
	k_EControllerActionOrigin_SteamV2_Back = 165
	k_EControllerActionOrigin_SteamV2_LeftPad_Touch = 166
	k_EControllerActionOrigin_SteamV2_LeftPad_Swipe = 167
	k_EControllerActionOrigin_SteamV2_LeftPad_Click = 168
	k_EControllerActionOrigin_SteamV2_LeftPad_Pressure = 169
	k_EControllerActionOrigin_SteamV2_LeftPad_DPadNorth = 170
	k_EControllerActionOrigin_SteamV2_LeftPad_DPadSouth = 171
	k_EControllerActionOrigin_SteamV2_LeftPad_DPadWest = 172
	k_EControllerActionOrigin_SteamV2_LeftPad_DPadEast = 173
	k_EControllerActionOrigin_SteamV2_RightPad_Touch = 174
	k_EControllerActionOrigin_SteamV2_RightPad_Swipe = 175
	k_EControllerActionOrigin_SteamV2_RightPad_Click = 176
	k_EControllerActionOrigin_SteamV2_RightPad_Pressure = 177
	k_EControllerActionOrigin_SteamV2_RightPad_DPadNorth = 178
	k_EControllerActionOrigin_SteamV2_RightPad_DPadSouth = 179
	k_EControllerActionOrigin_SteamV2_RightPad_DPadWest = 180
	k_EControllerActionOrigin_SteamV2_RightPad_DPadEast = 181
	k_EControllerActionOrigin_SteamV2_LeftTrigger_Pull = 182
	k_EControllerActionOrigin_SteamV2_LeftTrigger_Click = 183
	k_EControllerActionOrigin_SteamV2_RightTrigger_Pull = 184
	k_EControllerActionOrigin_SteamV2_RightTrigger_Click = 185
	k_EControllerActionOrigin_SteamV2_LeftStick_Move = 186
	k_EControllerActionOrigin_SteamV2_LeftStick_Click = 187
	k_EControllerActionOrigin_SteamV2_LeftStick_DPadNorth = 188
	k_EControllerActionOrigin_SteamV2_LeftStick_DPadSouth = 189
	k_EControllerActionOrigin_SteamV2_LeftStick_DPadWest = 190
	k_EControllerActionOrigin_SteamV2_LeftStick_DPadEast = 191
	k_EControllerActionOrigin_SteamV2_Gyro_Move = 192
	k_EControllerActionOrigin_SteamV2_Gyro_Pitch = 193
	k_EControllerActionOrigin_SteamV2_Gyro_Yaw = 194
	k_EControllerActionOrigin_SteamV2_Gyro_Roll = 195
	k_EControllerActionOrigin_Switch_A = 196
	k_EControllerActionOrigin_Switch_B = 197
	k_EControllerActionOrigin_Switch_X = 198
	k_EControllerActionOrigin_Switch_Y = 199
	k_EControllerActionOrigin_Switch_LeftBumper = 200
	k_EControllerActionOrigin_Switch_RightBumper = 201
	k_EControllerActionOrigin_Switch_Plus = 202
	k_EControllerActionOrigin_Switch_Minus = 203
	k_EControllerActionOrigin_Switch_Capture = 204
	k_EControllerActionOrigin_Switch_LeftTrigger_Pull = 205
	k_EControllerActionOrigin_Switch_LeftTrigger_Click = 206
	k_EControllerActionOrigin_Switch_RightTrigger_Pull = 207
	k_EControllerActionOrigin_Switch_RightTrigger_Click = 208
	k_EControllerActionOrigin_Switch_LeftStick_Move = 209
	k_EControllerActionOrigin_Switch_LeftStick_Click = 210
	k_EControllerActionOrigin_Switch_LeftStick_DPadNorth = 211
	k_EControllerActionOrigin_Switch_LeftStick_DPadSouth = 212
	k_EControllerActionOrigin_Switch_LeftStick_DPadWest = 213
	k_EControllerActionOrigin_Switch_LeftStick_DPadEast = 214
	k_EControllerActionOrigin_Switch_RightStick_Move = 215
	k_EControllerActionOrigin_Switch_RightStick_Click = 216
	k_EControllerActionOrigin_Switch_RightStick_DPadNorth = 217
	k_EControllerActionOrigin_Switch_RightStick_DPadSouth = 218
	k_EControllerActionOrigin_Switch_RightStick_DPadWest = 219
	k_EControllerActionOrigin_Switch_RightStick_DPadEast = 220
	k_EControllerActionOrigin_Switch_DPad_North = 221
	k_EControllerActionOrigin_Switch_DPad_South = 222
	k_EControllerActionOrigin_Switch_DPad_West = 223
	k_EControllerActionOrigin_Switch_DPad_East = 224
	k_EControllerActionOrigin_Switch_ProGyro_Move = 225
	k_EControllerActionOrigin_Switch_ProGyro_Pitch = 226
	k_EControllerActionOrigin_Switch_ProGyro_Yaw = 227
	k_EControllerActionOrigin_Switch_ProGyro_Roll = 228
	k_EControllerActionOrigin_Switch_RightGyro_Move = 229
	k_EControllerActionOrigin_Switch_RightGyro_Pitch = 230
	k_EControllerActionOrigin_Switch_RightGyro_Yaw = 231
	k_EControllerActionOrigin_Switch_RightGyro_Roll = 232
	k_EControllerActionOrigin_Switch_LeftGyro_Move = 233
	k_EControllerActionOrigin_Switch_LeftGyro_Pitch = 234
	k_EControllerActionOrigin_Switch_LeftGyro_Yaw = 235
	k_EControllerActionOrigin_Switch_LeftGyro_Roll = 236
	k_EControllerActionOrigin_Switch_LeftGrip_Lower = 237
	k_EControllerActionOrigin_Switch_LeftGrip_Upper = 238
	k_EControllerActionOrigin_Switch_RightGrip_Lower = 239
	k_EControllerActionOrigin_Switch_RightGrip_Upper = 240
	k_EControllerActionOrigin_Count = 241
	k_EControllerActionOrigin_MaximumPossibleValue = 32767
End Enum

Enum ESteamControllerLEDFlag
	k_ESteamControllerLEDFlag_SetColor = 0
	k_ESteamControllerLEDFlag_RestoreUserDefault = 1
End Enum

Rem
bbdoc: Specifies the types of UGC to obtain from a call to #CreateQueryUserUGCRequest or #CreateQueryAllUGCRequest.
End Rem
Enum EUGCMatchingUGCType
	k_EUGCMatchingUGCType_Items = 0
	k_EUGCMatchingUGCType_Items_Mtx = 1
	k_EUGCMatchingUGCType_Items_ReadyToUse = 2
	k_EUGCMatchingUGCType_Collections = 3
	k_EUGCMatchingUGCType_Artwork = 4
	k_EUGCMatchingUGCType_Videos = 5
	k_EUGCMatchingUGCType_Screenshots = 6
	k_EUGCMatchingUGCType_AllGuides = 7
	k_EUGCMatchingUGCType_WebGuides = 8
	k_EUGCMatchingUGCType_IntegratedGuides = 9
	k_EUGCMatchingUGCType_UsableInGame = 10
	k_EUGCMatchingUGCType_ControllerBindings = 11
	k_EUGCMatchingUGCType_GameManagedItems = 12
	k_EUGCMatchingUGCType_All = -1
End Enum

Rem
bbdoc: Used with #CreateQueryUserUGCRequest to obtain different lists of published UGC for a user.
End Rem
Enum EUserUGCList
	k_EUserUGCList_Published = 0
	k_EUserUGCList_VotedOn = 1
	k_EUserUGCList_VotedUp = 2
	k_EUserUGCList_VotedDown = 3
	k_EUserUGCList_WillVoteLater = 4
	k_EUserUGCList_Favorited = 5
	k_EUserUGCList_Subscribed = 6
	k_EUserUGCList_UsedOrPlayed = 7
	k_EUserUGCList_Followed = 8
End Enum

Enum EUserUGCListSortOrder
	k_EUserUGCListSortOrder_CreationOrderDesc = 0
	k_EUserUGCListSortOrder_CreationOrderAsc = 1
	k_EUserUGCListSortOrder_TitleAsc = 2
	k_EUserUGCListSortOrder_LastUpdatedDesc = 3
	k_EUserUGCListSortOrder_SubscriptionDateDesc = 4
	k_EUserUGCListSortOrder_VoteScoreDesc = 5
	k_EUserUGCListSortOrder_ForModeration = 6
End Enum

Rem
bbdoc: Used with #CreateQueryAllUGCRequest to specify the sorting and filtering for queries across all available UGC.
End Rem
Enum EUGCQuery
	k_EUGCQuery_RankedByVote = 0
	k_EUGCQuery_RankedByPublicationDate = 1
	k_EUGCQuery_AcceptedForGameRankedByAcceptanceDate = 2
	k_EUGCQuery_RankedByTrend = 3
	k_EUGCQuery_FavoritedByFriendsRankedByPublicationDate = 4
	k_EUGCQuery_CreatedByFriendsRankedByPublicationDate = 5
	k_EUGCQuery_RankedByNumTimesReported = 6
	k_EUGCQuery_CreatedByFollowedUsersRankedByPublicationDate = 7
	k_EUGCQuery_NotYetRated = 8
	k_EUGCQuery_RankedByTotalVotesAsc = 9
	k_EUGCQuery_RankedByVotesUp = 10
	k_EUGCQuery_RankedByTextSearch = 11
	k_EUGCQuery_RankedByTotalUniqueSubscriptions = 12
	k_EUGCQuery_RankedByPlaytimeTrend = 13
	k_EUGCQuery_RankedByTotalPlaytime = 14
	k_EUGCQuery_RankedByAveragePlaytimeTrend = 15
	k_EUGCQuery_RankedByLifetimeAveragePlaytime = 16
	k_EUGCQuery_RankedByPlaytimeSessionsTrend = 17
	k_EUGCQuery_RankedByLifetimePlaytimeSessions = 18
End Enum

Enum EItemUpdateStatus
	k_EItemUpdateStatusInvalid = 0
	k_EItemUpdateStatusPreparingConfig = 1
	k_EItemUpdateStatusPreparingContent = 2
	k_EItemUpdateStatusUploadingContent = 3
	k_EItemUpdateStatusUploadingPreviewFile = 4
	k_EItemUpdateStatusCommittingChanges = 5
End Enum

Enum EItemState Flags
	k_EItemStateNone = 0
	k_EItemStateSubscribed = 1
	k_EItemStateLegacyItem = 2
	k_EItemStateInstalled = 4
	k_EItemStateNeedsUpdate = 8
	k_EItemStateDownloading = 16
	k_EItemStateDownloadPending = 32
End Enum

Enum EItemStatistic
	k_EItemStatistic_NumSubscriptions = 0
	k_EItemStatistic_NumFavorites = 1
	k_EItemStatistic_NumFollowers = 2
	k_EItemStatistic_NumUniqueSubscriptions = 3
	k_EItemStatistic_NumUniqueFavorites = 4
	k_EItemStatistic_NumUniqueFollowers = 5
	k_EItemStatistic_NumUniqueWebsiteViews = 6
	k_EItemStatistic_ReportScore = 7
	k_EItemStatistic_NumSecondsPlayed = 8
	k_EItemStatistic_NumPlaytimeSessions = 9
	k_EItemStatistic_NumComments = 10
	k_EItemStatistic_NumSecondsPlayedDuringTimePeriod = 11
	k_EItemStatistic_NumPlaytimeSessionsDuringTimePeriod = 12
End Enum

Rem
bbdoc: Flags that specify the type of preview an item has. 
about: Set with #AddItemPreviewFile, and received with #GetQueryUGCAdditionalPreview.
End Rem
Enum EItemPreviewType
	k_EItemPreviewType_Image = 0
	k_EItemPreviewType_YouTubeVideo = 1
	k_EItemPreviewType_Sketchfab = 2
	k_EItemPreviewType_EnvironmentMap_HorizontalCross = 3
	k_EItemPreviewType_EnvironmentMap_LatLong = 4
	k_EItemPreviewType_ReservedMax = 255
End Enum

Enum EHTMLMouseButton
	eHTMLMouseButton_Left = 0
	eHTMLMouseButton_Right = 1
	eHTMLMouseButton_Middle = 2
End Enum

Enum EMouseCursor
	dc_user = 0
	dc_none = 1
	dc_arrow = 2
	dc_ibeam = 3
	dc_hourglass = 4
	dc_waitarrow = 5
	dc_crosshair = 6
	dc_up = 7
	dc_sizenw = 8
	dc_sizese = 9
	dc_sizene = 10
	dc_sizesw = 11
	dc_sizew = 12
	dc_sizee = 13
	dc_sizen = 14
	dc_sizes = 15
	dc_sizewe = 16
	dc_sizens = 17
	dc_sizeall = 18
	dc_no = 19
	dc_hand = 20
	dc_blank = 21
	dc_middle_pan = 22
	dc_north_pan = 23
	dc_north_east_pan = 24
	dc_east_pan = 25
	dc_south_east_pan = 26
	dc_south_pan = 27
	dc_south_west_pan = 28
	dc_west_pan = 29
	dc_north_west_pan = 30
	dc_alias = 31
	dc_cell = 32
	dc_colresize = 33
	dc_copycur = 34
	dc_verticaltext = 35
	dc_rowresize = 36
	dc_zoomin = 37
	dc_zoomout = 38
	dc_help = 39
	dc_custom = 40
	dc_last = 41
End Enum

Enum EHTMLKeyModifiers Flags
	k_eHTMLKeyModifier_None = 0
	k_eHTMLKeyModifier_AltDown = 1
	k_eHTMLKeyModifier_CtrlDown = 2
	k_eHTMLKeyModifier_ShiftDown = 4
End Enum

Enum ESteamItemFlags Flags
	k_ESteamItemNoTrade = 1
	k_ESteamItemRemoved = 256
	k_ESteamItemConsumed = 512
End Enum

Enum EParentalFeature
	k_EFeatureInvalid = 0
	k_EFeatureStore = 1
	k_EFeatureCommunity = 2
	k_EFeatureProfile = 3
	k_EFeatureFriends = 4
	k_EFeatureNews = 5
	k_EFeatureTrading = 6
	k_EFeatureSettings = 7
	k_EFeatureConsole = 8
	k_EFeatureBrowser = 9
	k_EFeatureParentalSetup = 10
	k_EFeatureLibrary = 11
	k_EFeatureTest = 12
	k_EFeatureMax = 13
End Enum
