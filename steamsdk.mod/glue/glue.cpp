/*
  Copyright (c) 2019 Bruce A Henderson
  
  This software is provided 'as-is', without any express or implied
  warranty. In no event will the authors be held liable for any damages
  arising from the use of this software.
  
  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:
  
  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/
#include "../sdk/public/steam/steam_api.h"
#include "include/flat.h"

#define GC_THREADS
#include "brl.mod/blitz.mod/bdwgc/include/gc.h"
#include "brl.mod/blitz.mod/blitz.h"

#include <chrono>
#include <thread>
#include <functional>
#include <vector>

class MaxUtils;
class MaxUserStats;
class MaxUGC;

#define BUFFER_SIZE 2048
#define VALUE_SIZE 16384
#define METADATA_SIZE 5000

extern "C" {

	void steam_steamsdk_TSteamUtils__OnCheckFileSignature(BBObject * maxHandle, ECheckFileSignature checkFileSignature);
	void steam_steamsdk_TSteamUtils__OnGamepadTextInputDismissed(BBObject * maxHandle, int ubmitted, uint32 submittedTextLength);
	void steam_steamsdk_TSteamUtils__OnLowBatteryPower(BBObject * maxHandle, int minutesBatteryLeft);
	void steam_steamsdk_TSteamUtils__OnSteamShutdown(BBObject * maxHandle);

	void steam_steamsdk_TSteamUserStats__OnUserStatsReceived(BBObject * maxHandle, uint64 gameID, EResult result, uint64 steamID);
	void steam_steamsdk_TSteamUserStats__OnUserStatsStored(BBObject * maxHandle, uint64 gameID, EResult result);
	void steam_steamsdk_TSteamUserStats__OnGetNumberOfCurrentPlayers(BBObject * maxHandle, int success, int players);
	void steam_steamsdk_TSteamUserStats__OnLeaderboardFindResult(BBObject * maxHandle, uint64 leaderboardHandle, int leaderboardFound);
	void steam_steamsdk_TSteamUserStats__OnLeaderboardScoresDownloaded(BBObject * maxHandle, uint64 leaderboardHandle, uint64 leaderboardEntriesHandle, int entryCount);
	void steam_steamsdk_TSteamUserStats__OnGlobalAchievementPercentagesReady(BBObject * maxHandle, uint64 gameID, EResult result);
	void steam_steamsdk_TSteamUserStats__OnGlobalStatsReceived(BBObject * maxHandle, uint64 gameID, EResult result);
	void steam_steamsdk_TSteamUserStats__OnLeaderboardScoreUploaded(BBObject * maxHandle, int success, uint64 leaderboardHandle, int score, int scoreChanged, int globalRankNew, int globalRankPrevious);
	void steam_steamsdk_TSteamUserStats__OnUserStatsUnloaded(BBObject * maxHandle, uint64 steamID);
	void steam_steamsdk_TSteamUserStats__OnUserAchievementIconFetched(BBObject * maxHandle, uint64 gameID, BBString * achievementName, int achieved, int iconHandle);
	void steam_steamsdk_TSteamUserStats__OnUserAchievementStored(BBObject * maxHandle, uint64 gameID, int groupAchievement, BBString * achievementName, uint32 curProgress, uint32 maxProgress);

	void steam_steamsdk_TSteamUGC__OnAddAppDependency(BBObject * maxHandle, EResult result, uint64 publishedFileId, uint32 appID);
	void steam_steamsdk_TSteamUGC__OnAddDependency(BBObject * maxHandle, EResult result, uint64 publishedFileId, uint64 childPublishedFileId);
	void steam_steamsdk_TSteamUGC__OnUserFavoriteItemsListChanged(BBObject * maxHandle, uint64 publishedFileId, EResult result, int wasAddRequest);
	void steam_steamsdk_TSteamUGC__OnCreateItem(BBObject * maxHandle, EResult result, uint64 publishedFileId, int userNeedsToAcceptWorkshopLegalAgreement);
	void steam_steamsdk_TSteamUGC__OnDeleteItem(BBObject * maxHandle, EResult result, uint64 publishedFileId);
	void steam_steamsdk_TSteamUGC__OnDownloadItem(BBObject * maxHandle, EResult result, uint32 appID, uint64 publishedFileId);
	void steam_steamsdk_TSteamUGC__OnGetUserItemVote(BBObject * maxHandle, uint64 publishedFileId, EResult result, int votedUp, int votedDown, int voteSkipped);
	void steam_steamsdk_TSteamUGC__OnRemoveAppDependency(BBObject * maxHandle, EResult result, uint64 publishedFileId, uint32 appID);
	void steam_steamsdk_TSteamUGC__OnRemoveUGCDependency(BBObject * maxHandle, EResult result, uint64 publishedFileId, uint64 childPublishedFileId);
	void steam_steamsdk_TSteamUGC__OnSteamUGCQueryCompleted(BBObject * maxHandle, uint64 handle, EResult result, uint32 numResultsReturned, uint32 totalMatchingResults, int cachedData);
	void steam_steamsdk_TSteamUGC__OnSetUserItemVote(BBObject * maxHandle, uint64 publishedFileId, EResult result, int voteUp);
	void steam_steamsdk_TSteamUGC__OnStartPlaytimeTracking(BBObject * maxHandle, EResult result);
	void steam_steamsdk_TSteamUGC__OnStopPlaytimeTracking(BBObject * maxHandle, EResult result);
	void steam_steamsdk_TSteamUGC__OnGetAppDependencies(BBObject * maxHandle, EResult result, uint64 publishedFileId, uint32 * appID, int numAppDependencies, int totalNumAppDependencies);
	void steam_steamsdk_TSteamUGC__OnSubmitItemUpdate(BBObject * maxHandle, EResult result, int userNeedsToAcceptWorkshopLegalAgreement);
	void steam_steamsdk_TSteamUGC__OnRemoteStorageSubscribePublishedFile(BBObject * maxHandle, EResult result, uint64 publishedFileId);
	void steam_steamsdk_TSteamUGC__OnRemoteStorageUnsubscribePublishedFile(BBObject * maxHandle, EResult result, uint64 publishedFileId);

	int bmx_SteamAPI_Init();
	void bmx_SteamAPI_Shutdown();
	void bmx_SteamAPI_startBackgroundTimer();
	void bmx_SteamAPI_stopBackgroundTimer();
	void bmx_SteamAPI_RunCallbacks();
		
	HSteamPipe bmx_SteamAPI_GetHSteamPipe();

	void * bmx_SteamInternal_CreateInterface(BBString * version);

	void *  bmx_steamsdk_register_steamuutils(intptr_t instancePtr, BBObject * obj);
	void bmx_steamsdk_unregister_steamutils(void * callbackPtr);

	void * bmx_SteamAPI_ISteamClient_GetISteamUtils(intptr_t instancePtr, HSteamPipe pipe, BBString * version);
	HSteamUser bmx_SteamAPI_ISteamClient_ConnectToGlobalUser(intptr_t instancePtr, HSteamPipe pipe);
	void * bmx_SteamAPI_ISteamClient_GetISteamUserStats(intptr_t instancePtr, HSteamUser user, HSteamPipe pipe, BBString * version);
	void * bmx_SteamAPI_ISteamClient_GetISteamUGC(intptr_t instancePtr, HSteamUser user, HSteamPipe pipe, BBString * version);


	uint32 bmx_SteamAPI_ISteamUtils_GetSecondsSinceAppActive(intptr_t instancePtr);
	uint32 bmx_SteamAPI_ISteamUtils_GetSecondsSinceComputerActive(intptr_t instancePtr);
	uint32 bmx_SteamAPI_ISteamUtils_GetServerRealTime(intptr_t instancePtr);
	BBString * bmx_SteamAPI_ISteamUtils_GetIPCountry(intptr_t instancePtr);
	uint32 bmx_SteamAPI_ISteamUtils_GetAppID(intptr_t instancePtr);
	int bmx_SteamAPI_ISteamUtils_IsOverlayEnabled(intptr_t instancePtr);
	int bmx_SteamAPI_ISteamUtils_IsSteamInBigPictureMode(intptr_t instancePtr);
	int bmx_SteamAPI_ISteamUtils_IsSteamRunningInVR(intptr_t instancePtr);
	int bmx_SteamAPI_ISteamUtils_IsVRHeadsetStreamingEnabled(intptr_t instancePtr);
	void bmx_SteamAPI_ISteamUtils_SetOverlayNotificationInset(intptr_t instancePtr, int horizontalInset, int verticalInset);
	void bmx_SteamAPI_ISteamUtils_SetOverlayNotificationPosition(intptr_t instancePtr, ENotificationPosition position);
	void bmx_SteamAPI_ISteamUtils_SetVRHeadsetStreamingEnabled(intptr_t instancePtr, int enabled);
	void bmx_SteamAPI_ISteamUtils_StartVRDashboard(intptr_t instancePtr);
	int bmx_SteamAPI_ISteamUtils_BOverlayNeedsPresent(intptr_t instancePtr);
	int bmx_SteamAPI_ISteamUtils_GetCurrentBatteryPower(intptr_t instancePtr);
	int bmx_SteamAPI_ISteamUtils_GetEnteredGamepadTextInput(intptr_t instancePtr, BBString ** txt);
	int bmx_SteamAPI_ISteamUtils_GetImageRGBA(intptr_t instancePtr, int image, uint8 * dest, int destBufferSize);
	int bmx_SteamAPI_ISteamUtils_GetImageSize(intptr_t instancePtr, int image, uint32 * width, uint32 * height);
	uint32 bmx_SteamAPI_ISteamUtils_GetEnteredGamepadTextLength(intptr_t instancePtr);
	BBString * bmx_SteamAPI_ISteamUtils_GetSteamUILanguage(intptr_t instancePtr);
	int bmx_SteamAPI_ISteamUtils_ShowGamepadTextInput(intptr_t instancePtr, EGamepadTextInputMode inputMode, EGamepadTextInputLineMode lineInputMode, BBString * description, uint32 charMax, BBString * existingText);

	void * bmx_steamsdk_register_steamuserstats(intptr_t instancePtr, BBObject * obj);
	void bmx_steamsdk_unregister_steamuserstats(void * callbackPtr);

	int bmx_SteamAPI_ISteamUserStats_RequestCurrentStats(intptr_t instancePtr);
	void bmx_SteamAPI_ISteamUserStats_GetNumberOfCurrentPlayers(MaxUserStats * userStats);
	int bmx_SteamAPI_ISteamUserStats_GetMostAchievedAchievementInfo(intptr_t instancePtr, BBString ** name, float * percent, int * achieved);
	int bmx_SteamAPI_ISteamUserStats_GetNextMostAchievedAchievementInfo(intptr_t instancePtr, int previous, BBString ** name, float * percent, int * achieved);
	uint32 bmx_SteamAPI_ISteamUserStats_GetNumAchievements(intptr_t instancePtr);
	int bmx_SteamAPI_ISteamUserStats_ClearAchievement(intptr_t instancePtr, BBString * name);
	void bmx_SteamAPI_ISteamUserStats_DownloadLeaderboardEntries(MaxUserStats * userStats, uint64 leaderboardHandle, ELeaderboardDataRequest leaderboardDataRequest, int rangeStart, int rangeEnd);
	void bmx_SteamAPI_ISteamUserStats_DownloadLeaderboardEntriesForUsers(MaxUserStats * userStats, uint64 leaderboardHandle, uint64 * users, int count);
	void bmx_SteamAPI_ISteamUserStats_FindLeaderboard(MaxUserStats * userStats, BBString * leaderboardName);
	void bmx_SteamAPI_ISteamUserStats_FindOrCreateLeaderboard(MaxUserStats * userStats, BBString * leaderboardName, ELeaderboardSortMethod sortMethod, ELeaderboardDisplayType displayType);
	int bmx_SteamAPI_ISteamUserStats_GetAchievement(intptr_t instancePtr, BBString * name, int * achieved);
	int bmx_SteamAPI_ISteamUserStats_GetAchievementAchievedPercent(intptr_t instancePtr, BBString * name, float * percent);
	int bmx_SteamAPI_ISteamUserStats_GetAchievementAndUnlockTime(intptr_t instancePtr, BBString * name, int * achieved, uint32 * unlockTime);
	BBString * bmx_SteamAPI_ISteamUserStats_GetAchievementDisplayAttribute(intptr_t instancePtr, BBString * name, BBString * key);
	int bmx_SteamAPI_ISteamUserStats_GetAchievementIcon(intptr_t instancePtr, BBString * name);
	BBString * bmx_SteamAPI_ISteamUserStats_GetAchievementName(intptr_t instancePtr, uint32 achievement);
	int bmx_SteamAPI_ISteamUserStats_GetGlobalStat(intptr_t instancePtr, BBString * statName, int64 * data);
	int bmx_SteamAPI_ISteamUserStats_GetGlobalStat0(intptr_t instancePtr, BBString * statName, double * data);
	int bmx_SteamAPI_ISteamUserStats_GetGlobalStatHistory(intptr_t instancePtr, BBString * statName, int64 * data, uint32 count);
	int bmx_SteamAPI_ISteamUserStats_GetGlobalStatHistory0(intptr_t instancePtr, BBString * statName, double * data, uint32 count);
	ELeaderboardDisplayType bmx_SteamAPI_ISteamUserStats_GetLeaderboardDisplayType(intptr_t instancePtr, uint64 leaderboardHandle);
	int bmx_SteamAPI_ISteamUserStats_GetLeaderboardEntryCount(intptr_t instancePtr, uint64 leaderboardHandle);
	BBString * bmx_SteamAPI_ISteamUserStats_GetLeaderboardName(intptr_t instancePtr, uint64 leaderboardHandle);
	ELeaderboardSortMethod bmx_SteamAPI_ISteamUserStats_GetLeaderboardSortMethod(intptr_t instancePtr, uint64 leaderboardHandle);
	int bmx_SteamAPI_ISteamGameServerStats_GetUserAchievement(intptr_t instancePtr, uint64 steamID, BBString * name, int * achieved);
	int bmx_SteamAPI_ISteamUserStats_GetUserAchievementAndUnlockTime(intptr_t instancePtr, uint64 steamID, BBString * name, int * achieved, uint32 * unlockTime);
	int bmx_SteamAPI_ISteamGameServerStats_GetUserStat(intptr_t instancePtr, uint64 steamID, BBString * name, int * data);
	int bmx_SteamAPI_ISteamGameServerStats_GetUserStat0(intptr_t instancePtr, uint64 steamID, BBString * name, float * data);
	int bmx_SteamAPI_ISteamUserStats_IndicateAchievementProgress(intptr_t instancePtr, BBString * name, uint32 curProgress, uint32 maxProgress);
	void bmx_SteamAPI_ISteamUserStats_RequestGlobalAchievementPercentages(MaxUserStats * userStats);
	void bmx_SteamAPI_ISteamUserStats_RequestGlobalStats(MaxUserStats * userStats, int historyDays);
	void bmx_SteamAPI_ISteamGameServerStats_RequestUserStats(MaxUserStats * userStats, uint64 steamID);
	int bmx_SteamAPI_ISteamUserStats_ResetAllStats(intptr_t instancePtr, int achievementsToo);
	int bmx_SteamAPI_ISteamUserStats_SetAchievement(intptr_t instancePtr, BBString * name);
	int bmx_SteamAPI_ISteamUserStats_SetStat(intptr_t instancePtr, BBString * name, int data);
	int bmx_SteamAPI_ISteamUserStats_SetStat0(intptr_t instancePtr, BBString * name, float data);
	int bmx_SteamAPI_ISteamUserStats_StoreStats(intptr_t instancePtr);
	int bmx_SteamAPI_ISteamUserStats_UpdateAvgRateStat(intptr_t instancePtr, BBString * name, float countThisSession, double sessionLength);
	void bmx_SteamAPI_ISteamUserStats_UploadLeaderboardScore(MaxUserStats * userStats, uint64 leaderboardHandle, ELeaderboardUploadScoreMethod uploadScoreMethod, int score, int * scoreDetails, int count);

	void * bmx_steamsdk_register_steamugc(intptr_t instancePtr, BBObject * obj);
	void bmx_steamsdk_unregister_steamugc(void * callbackPtr);
	
	void bmx_SteamAPI_ISteamUGC_AddAppDependency(MaxUGC * ugc, uint64 publishedFileID, uint32 appID);
	void bmx_SteamAPI_ISteamUGC_AddDependency(MaxUGC * ugc, uint64 publishedFileId, uint64 childPublishedFileId);
	int bmx_SteamAPI_ISteamUGC_AddExcludedTag(intptr_t instancePtr, uint64 queryHandle, BBString * tagName);
	int bmx_SteamAPI_ISteamUGC_AddItemKeyValueTag(intptr_t instancePtr, uint64 queryHandle, BBString * key, BBString * value);
	int bmx_SteamAPI_ISteamUGC_AddItemPreviewFile(intptr_t instancePtr, uint64 queryHandle, BBString * previewFile, EItemPreviewType previewType);
	int bmx_SteamAPI_ISteamUGC_AddItemPreviewVideo(intptr_t instancePtr, uint64 queryHandle, BBString * videoID);
	void bmx_SteamAPI_ISteamUGC_AddItemToFavorites(MaxUGC * ugc, uint32 appId, uint64 publishedFileID);
	int bmx_SteamAPI_ISteamUGC_AddRequiredKeyValueTag(intptr_t instancePtr, uint64 queryHandle, BBString * key, BBString * value);
	int bmx_SteamAPI_ISteamUGC_AddRequiredTag(intptr_t instancePtr, uint64 queryHandle, BBString * tagName);
	int bmx_SteamAPI_ISteamUGC_InitWorkshopForGameServer(intptr_t instancePtr, uint64 workshopDepotID, BBString * folder);
	void bmx_SteamAPI_ISteamUGC_CreateItem(MaxUGC * ugc, uint32 consumerAppId, EWorkshopFileType fileType);
	uint64 bmx_SteamAPI_ISteamUGC_CreateQueryAllUGCRequest(intptr_t instancePtr, EUGCQuery queryType, EUGCMatchingUGCType matchingeMatchingUGCTypeFileType, uint32 creatorAppID, uint32 consumerAppID, uint32 page);
	uint64 bmx_SteamAPI_ISteamUGC_CreateQueryUGCDetailsRequest(intptr_t instancePtr, uint64 * publishedFileIDs, int numPublishedFileIDs);
	uint64 bmx_SteamAPI_ISteamUGC_CreateQueryUserUGCRequest(intptr_t instancePtr, uint32 accountID, EUserUGCList listType, EUGCMatchingUGCType matchingUGCType, EUserUGCListSortOrder sortOrder, uint32 creatorAppID, uint32 consumerAppID, uint32 page);
	void bmx_SteamAPI_ISteamUGC_DeleteItem(MaxUGC * ugc, uint64 publishedFileID);
	int bmx_SteamAPI_ISteamUGC_DownloadItem(intptr_t instancePtr, uint64 publishedFileID, int highPriority);
	void bmx_SteamAPI_ISteamUGC_GetAppDependencies(MaxUGC * ugc, uint64 publishedFileID);
	int bmx_SteamAPI_ISteamUGC_GetItemDownloadInfo(intptr_t instancePtr, uint64 publishedFileID, uint64 * bytesDownloaded, uint64 * bytesTotal);
	int bmx_SteamAPI_ISteamUGC_GetItemInstallInfo(intptr_t instancePtr, uint64 publishedFileID, uint64 * sizeOnDisk, BBString ** folder, uint32 * timestamp);
	uint32 bmx_SteamAPI_ISteamUGC_GetItemState(intptr_t instancePtr, uint64 publishedFileID);
	EItemUpdateStatus bmx_SteamAPI_ISteamUGC_GetItemUpdateProgress(intptr_t instancePtr, uint64 queryHandle, uint64 * bytesProcessed, uint64 * bytesTotal);
	uint32 bmx_SteamAPI_ISteamUGC_GetNumSubscribedItems(intptr_t instancePtr);
	int bmx_SteamAPI_ISteamUGC_GetQueryUGCAdditionalPreview(intptr_t instancePtr, uint64 queryHandle, uint32 index, uint32 previewIndex, BBString ** URLOrVideoID, BBString ** originalFileName, EItemPreviewType * previewType);
	int bmx_SteamAPI_ISteamUGC_GetQueryUGCChildren(intptr_t instancePtr, uint64 queryHandle, uint32 index, uint64 * publishedFileIDs, uint32 maxEntries);
	int bmx_SteamAPI_ISteamUGC_GetQueryUGCKeyValueTag(intptr_t instancePtr, uint64 queryHandle, uint32 index, uint32 keyValueTagIndex, BBString ** key, BBString ** value);
	int bmx_SteamAPI_ISteamUGC_GetQueryUGCMetadata(intptr_t instancePtr, uint64 queryHandle, uint32 index, BBString ** metadata);
	uint32 bmx_SteamAPI_ISteamUGC_GetQueryUGCNumAdditionalPreviews(intptr_t instancePtr, uint64 queryHandle, uint32 index);
	uint32 bmx_SteamAPI_ISteamUGC_GetQueryUGCNumKeyValueTags(intptr_t instancePtr, uint64 queryHandle, uint32 index);
	int bmx_SteamAPI_ISteamUGC_GetQueryUGCPreviewURL(intptr_t instancePtr, uint64 queryHandle, uint32 index, BBString ** URL);
	int bmx_SteamAPI_ISteamUGC_GetQueryUGCStatistic(intptr_t instancePtr, uint64 queryHandle, uint32 index, EItemStatistic statType, uint64 * statValue);
	uint32 bmx_SteamAPI_ISteamUGC_GetSubscribedItems(intptr_t instancePtr, uint64 * publishedFileIDs, uint32 maxEntries);
	void bmx_SteamAPI_ISteamUGC_GetUserItemVote(MaxUGC * ugc, uint64 publishedFileID);
	int bmx_SteamAPI_ISteamUGC_ReleaseQueryUGCRequest(intptr_t instancePtr, uint64 queryHandle);
	void bmx_SteamAPI_ISteamUGC_RemoveAppDependency(MaxUGC * ugc, uint64 publishedFileID, uint32 appID);
	void bmx_SteamAPI_ISteamUGC_RemoveDependency(MaxUGC * ugc, uint64 parentPublishedFileID, uint64 childPublishedFileID);
	void bmx_SteamAPI_ISteamUGC_RemoveItemFromFavorites(MaxUGC * ugc, uint32 appId, uint64 publishedFileID);
	int bmx_SteamAPI_ISteamUGC_RemoveItemKeyValueTags(intptr_t instancePtr, uint64 queryHandle, BBString * key);
	int bmx_SteamAPI_ISteamUGC_RemoveItemPreview(intptr_t instancePtr, uint64 queryHandle, uint32 index);
	void bmx_SteamAPI_ISteamUGC_SendQueryUGCRequest(MaxUGC * ugc, uint64 queryHandle);
	int bmx_SteamAPI_ISteamUGC_SetAllowCachedResponse(intptr_t instancePtr, uint64 queryHandle, uint32 maxAgeSeconds);
	int bmx_SteamAPI_ISteamUGC_SetCloudFileNameFilter(intptr_t instancePtr, uint64 queryHandle, BBString * matchCloudFileName);
	int bmx_SteamAPI_ISteamUGC_SetItemContent(intptr_t instancePtr, uint64 updateHandle, BBString * contentFolder);
	int bmx_SteamAPI_ISteamUGC_SetItemDescription(intptr_t instancePtr, uint64 updateHandle, BBString * description);
	int bmx_SteamAPI_ISteamUGC_SetItemMetadata(intptr_t instancePtr, uint64 updateHandle, BBString * metaData);
	int bmx_SteamAPI_ISteamUGC_SetItemPreview(intptr_t instancePtr, uint64 updateHandle, BBString * previewFile);
	int bmx_SteamAPI_ISteamUGC_SetItemTags(intptr_t instancePtr, uint64 updateHandle, BBArray * tags);
	int bmx_SteamAPI_ISteamUGC_SetItemTitle(intptr_t instancePtr, uint64 updateHandle, BBString * title);
	int bmx_SteamAPI_ISteamUGC_SetItemUpdateLanguage(intptr_t instancePtr, uint64 updateHandle, BBString * language);
	int bmx_SteamAPI_ISteamUGC_SetItemVisibility(intptr_t instancePtr, uint64 updateHandle, ERemoteStoragePublishedFileVisibility visibility);
	int bmx_SteamAPI_ISteamUGC_SetLanguage(intptr_t instancePtr, uint64 queryHandle, BBString * language);
	int bmx_SteamAPI_ISteamUGC_SetMatchAnyTag(intptr_t instancePtr, uint64 queryHandle, int matchAnyTag);
	int bmx_SteamAPI_ISteamUGC_SetRankedByTrendDays(intptr_t instancePtr, uint64 queryHandle, uint32 days);
	int bmx_SteamAPI_ISteamUGC_SetReturnAdditionalPreviews(intptr_t instancePtr, uint64 queryHandle, int returnAdditionalPreviews);
	int bmx_SteamAPI_ISteamUGC_SetReturnChildren(intptr_t instancePtr, uint64 queryHandle, int returnChildren);
	int bmx_SteamAPI_ISteamUGC_SetReturnKeyValueTags(intptr_t instancePtr, uint64 queryHandle, int returnKeyValueTags);
	int bmx_SteamAPI_ISteamUGC_SetReturnLongDescription(intptr_t instancePtr, uint64 queryHandle, int returnLongDescription);
	int bmx_SteamAPI_ISteamUGC_SetReturnMetadata(intptr_t instancePtr, uint64 queryHandle, int returnMetadata);
	int bmx_SteamAPI_ISteamUGC_SetReturnOnlyIDs(intptr_t instancePtr, uint64 queryHandle, int returnOnlyIDs);
	int bmx_SteamAPI_ISteamUGC_SetReturnPlaytimeStats(intptr_t instancePtr, uint64 queryHandle, uint32 days);
	int bmx_SteamAPI_ISteamUGC_SetReturnTotalOnly(intptr_t instancePtr, uint64 queryHandle, int returnTotalOnly);
	int bmx_SteamAPI_ISteamUGC_SetSearchText(intptr_t instancePtr, uint64 queryHandle, BBString * searchText);
	void bmx_SteamAPI_ISteamUGC_SetUserItemVote(MaxUGC * ugc, uint64 publishedFileID, int voteUp);
	uint64 bmx_SteamAPI_ISteamUGC_StartItemUpdate(intptr_t instancePtr, uint32 consumerAppId, uint64 publishedFileID);
	void bmx_SteamAPI_ISteamUGC_StartPlaytimeTracking(MaxUGC * ugc, uint64 * publishedFileIDs, uint32 numPublishedFileIDs);
	void bmx_SteamAPI_ISteamUGC_StopPlaytimeTracking(MaxUGC * ugc, uint64 * publishedFileIDs, uint32 numPublishedFileIDs);
	void bmx_SteamAPI_ISteamUGC_StopPlaytimeTrackingForAllItems(MaxUGC * ugc);
	void bmx_SteamAPI_ISteamUGC_SubmitItemUpdate(MaxUGC * ugc, uint64 updateHandle, BBString * changeNote);
	void bmx_SteamAPI_ISteamUGC_SubscribeItem(MaxUGC * ugc, uint64 publishedFileID);
	void bmx_SteamAPI_ISteamUGC_SuspendDownloads(intptr_t instancePtr, int suspend);
	void bmx_SteamAPI_ISteamUGC_UnsubscribeItem(MaxUGC * ugc, uint64 publishedFileID);
	int bmx_SteamAPI_ISteamUGC_UpdateItemPreviewFile(intptr_t instancePtr, uint64 updateHandle, uint32 index, BBString * previewFile);
	int bmx_SteamAPI_ISteamUGC_UpdateItemPreviewVideo(intptr_t instancePtr, uint64 updateHandle, uint32 index, BBString * videoID);
}


int bmx_SteamAPI_Init() {
	return SteamAPI_Init();
}

void bmx_SteamAPI_Shutdown() {
	SteamAPI_Shutdown();
}

HSteamPipe bmx_SteamAPI_GetHSteamPipe() {
	return SteamAPI_GetHSteamPipe();
}

void * bmx_SteamInternal_CreateInterface(BBString * version) {
	char * v = bbStringToUTF8String(version);
	void * inst = SteamInternal_CreateInterface(v);
	bbMemFree(v);
	return inst;
}

void bmx_SteamAPI_RunCallbacks() {
	SteamAPI_RunCallbacks();
}

class CallbackTimer
{
    std::thread th;
    bool running = false;

public:
    typedef std::chrono::milliseconds Interval;
    typedef std::function<void(void)> Timeout;

    void start(const Interval &interval, const Timeout &timeout) {
        running = true;

        th = std::thread([=]() {
			struct GC_stack_base base;;
			GC_get_stack_base(&base);
			GC_register_my_thread(&base);
            while (running) {
                std::this_thread::sleep_for(interval);
                timeout();
            }
        });
    }

    void stop() {
        running = false;
		th.detach();
    }
};

CallbackTimer _callbackTimer;

void bmx_SteamAPI_startBackgroundTimer() {
	_callbackTimer.start(std::chrono::milliseconds(100), [] {
		SteamAPI_RunCallbacks();
	});
}

void bmx_SteamAPI_stopBackgroundTimer() {
	std::this_thread::sleep_for(std::chrono::milliseconds(100));
	_callbackTimer.stop();
}

// ISteamClient -------------------------------------------

void * bmx_SteamAPI_ISteamClient_GetISteamUtils(intptr_t instancePtr, HSteamPipe pipe, BBString * version) {
	char * v = bbStringToUTF8String(version);
	void * inst = SteamAPI_ISteamClient_GetISteamUtils(instancePtr, pipe, v);
	bbMemFree(v);
	return inst;
}

HSteamUser bmx_SteamAPI_ISteamClient_ConnectToGlobalUser(intptr_t instancePtr, HSteamPipe pipe) {
	return SteamAPI_ISteamClient_ConnectToGlobalUser(instancePtr, pipe);
}

void * bmx_SteamAPI_ISteamClient_GetISteamUserStats(intptr_t instancePtr, HSteamUser user, HSteamPipe pipe, BBString * version) {
	char * v = bbStringToUTF8String(version);
	void * inst = SteamAPI_ISteamClient_GetISteamUserStats(instancePtr, user, pipe, v);
	bbMemFree(v);
	return inst;
}

void * bmx_SteamAPI_ISteamClient_GetISteamUGC(intptr_t instancePtr, HSteamUser user, HSteamPipe pipe, BBString * version) {
	char * v = bbStringToUTF8String(version);
	void * inst = SteamAPI_ISteamClient_GetISteamUGC(instancePtr, user, pipe, v);
	bbMemFree(v);
	return inst;
}

// ISteamUtils --------------------------------------------

class MaxUtils
{
private:
	intptr_t instancePtr;
	BBObject * maxHandle;

public:
	STEAM_CALLBACK( MaxUtils, OnCheckFileSignature, CheckFileSignature_t, m_CallbackCheckFileSignature );
	STEAM_CALLBACK( MaxUtils, OnGamepadTextInputDismissed, GamepadTextInputDismissed_t, m_CallbackGamepadTextInputDismissed );
	STEAM_CALLBACK( MaxUtils, OnLowBatteryPower, LowBatteryPower_t, m_CallbackLowBatteryPower );
	STEAM_CALLBACK( MaxUtils, OnSteamShutdown, SteamShutdown_t, m_CallbackSteamShutdown );

	MaxUtils(intptr_t instancePtr, BBObject * handle);
	~MaxUtils();
};

MaxUtils::MaxUtils(intptr_t instancePtr, BBObject * handle) :
	instancePtr(instancePtr), maxHandle(handle),
	m_CallbackCheckFileSignature( this, &MaxUtils::OnCheckFileSignature ),
	m_CallbackGamepadTextInputDismissed( this, &MaxUtils::OnGamepadTextInputDismissed ),
	m_CallbackLowBatteryPower( this, &MaxUtils::OnLowBatteryPower ),
	m_CallbackSteamShutdown( this, &MaxUtils::OnSteamShutdown )
{
}

void MaxUtils::OnCheckFileSignature( CheckFileSignature_t * result ) {
	steam_steamsdk_TSteamUtils__OnCheckFileSignature(maxHandle, result->m_eCheckFileSignature);
}

void MaxUtils::OnGamepadTextInputDismissed( GamepadTextInputDismissed_t * result ) {
	steam_steamsdk_TSteamUtils__OnGamepadTextInputDismissed(maxHandle, result->m_bSubmitted, result->m_unSubmittedText);
}

void MaxUtils::OnLowBatteryPower( LowBatteryPower_t * result ) {
	steam_steamsdk_TSteamUtils__OnLowBatteryPower(maxHandle, result->m_nMinutesBatteryLeft);
}

void MaxUtils::OnSteamShutdown( SteamShutdown_t * result ) {
	steam_steamsdk_TSteamUtils__OnSteamShutdown(maxHandle);
}

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void *  bmx_steamsdk_register_steamuutils(intptr_t instancePtr, BBObject * obj) {
	return new MaxUtils(instancePtr, obj);
}

void bmx_steamsdk_unregister_steamutils(void * callbackPtr) {
	delete(callbackPtr);
}

uint32 bmx_SteamAPI_ISteamUtils_GetSecondsSinceAppActive(intptr_t instancePtr) {
	return SteamAPI_ISteamUtils_GetSecondsSinceAppActive(instancePtr);
}

uint32 bmx_SteamAPI_ISteamUtils_GetSecondsSinceComputerActive(intptr_t instancePtr) {
	return SteamAPI_ISteamUtils_GetSecondsSinceComputerActive(instancePtr);
}

uint32 bmx_SteamAPI_ISteamUtils_GetServerRealTime(intptr_t instancePtr) {
	return SteamAPI_ISteamUtils_GetServerRealTime(instancePtr);
}

BBString * bmx_SteamAPI_ISteamUtils_GetIPCountry(intptr_t instancePtr) {
	return bbStringFromUTF8String(SteamAPI_ISteamUtils_GetIPCountry(instancePtr));
}

uint32 bmx_SteamAPI_ISteamUtils_GetAppID(intptr_t instancePtr) {
	return SteamAPI_ISteamUtils_GetAppID(instancePtr);
}

int bmx_SteamAPI_ISteamUtils_IsOverlayEnabled(intptr_t instancePtr) {
	return SteamAPI_ISteamUtils_IsOverlayEnabled(instancePtr);
}

int bmx_SteamAPI_ISteamUtils_IsSteamInBigPictureMode(intptr_t instancePtr) {
	return SteamAPI_ISteamUtils_IsSteamInBigPictureMode(instancePtr);
}

int bmx_SteamAPI_ISteamUtils_IsSteamRunningInVR(intptr_t instancePtr) {
	return SteamAPI_ISteamUtils_IsSteamRunningInVR(instancePtr);
}

int bmx_SteamAPI_ISteamUtils_IsVRHeadsetStreamingEnabled(intptr_t instancePtr) {
	return SteamAPI_ISteamUtils_IsVRHeadsetStreamingEnabled(instancePtr);
}

void bmx_SteamAPI_ISteamUtils_SetOverlayNotificationInset(intptr_t instancePtr, int horizontalInset, int verticalInset) {
	SteamAPI_ISteamUtils_SetOverlayNotificationInset(instancePtr, horizontalInset, verticalInset);
}

void bmx_SteamAPI_ISteamUtils_SetOverlayNotificationPosition(intptr_t instancePtr, ENotificationPosition position) {
	SteamAPI_ISteamUtils_SetOverlayNotificationPosition(instancePtr, position);
}

void bmx_SteamAPI_ISteamUtils_SetVRHeadsetStreamingEnabled(intptr_t instancePtr, int enabled) {
	SteamAPI_ISteamUtils_SetVRHeadsetStreamingEnabled(instancePtr, enabled);
}

void bmx_SteamAPI_ISteamUtils_StartVRDashboard(intptr_t instancePtr) {
	SteamAPI_ISteamUtils_StartVRDashboard(instancePtr);
}

int bmx_SteamAPI_ISteamUtils_BOverlayNeedsPresent(intptr_t instancePtr) {
	return SteamAPI_ISteamUtils_BOverlayNeedsPresent(instancePtr);
}

int bmx_SteamAPI_ISteamUtils_GetCurrentBatteryPower(intptr_t instancePtr) {
	return SteamAPI_ISteamUtils_GetCurrentBatteryPower(instancePtr);
}

int bmx_SteamAPI_ISteamUtils_GetEnteredGamepadTextInput(intptr_t instancePtr, BBString ** txt) {
	char buf[2048];
	int res = SteamAPI_ISteamUtils_GetEnteredGamepadTextInput(instancePtr, buf, 2048);
	if (strlen(buf) == 0) {
		*txt = &bbEmptyString;
	} else {
		*txt = bbStringFromUTF8String(buf);
	}
	return res;	
}

int bmx_SteamAPI_ISteamUtils_GetImageRGBA(intptr_t instancePtr, int image, uint8 * dest, int destBufferSize) {
	return SteamAPI_ISteamUtils_GetImageRGBA(instancePtr, image, dest, destBufferSize);
}

int bmx_SteamAPI_ISteamUtils_GetImageSize(intptr_t instancePtr, int image, uint32 * width, uint32 * height) {
	return SteamAPI_ISteamUtils_GetImageSize(instancePtr, image, width, height);
}

uint32 bmx_SteamAPI_ISteamUtils_GetEnteredGamepadTextLength(intptr_t instancePtr) {
	return SteamAPI_ISteamUtils_GetEnteredGamepadTextLength(instancePtr);
}

BBString * bmx_SteamAPI_ISteamUtils_GetSteamUILanguage(intptr_t instancePtr) {
	return bbStringFromUTF8String(SteamAPI_ISteamUtils_GetSteamUILanguage(instancePtr));
}

int bmx_SteamAPI_ISteamUtils_ShowGamepadTextInput(intptr_t instancePtr, EGamepadTextInputMode inputMode, EGamepadTextInputLineMode lineInputMode, BBString * description, uint32 charMax, BBString * existingText) {
	char * d = bbStringToUTF8String(description);
	char * e = bbStringToUTF8String(existingText);
	int res = SteamAPI_ISteamUtils_ShowGamepadTextInput(instancePtr, inputMode, lineInputMode, d, charMax, e);
	bbMemFree(e);
	bbMemFree(d);
	return res;
}

// IUserStats ---------------------------------------------

class MaxUserStats
{
private:
	intptr_t instancePtr;
	BBObject * maxHandle;
	
	CCallResult< MaxUserStats, NumberOfCurrentPlayers_t > m_NumberOfCurrentPlayersCallResult;
	CCallResult< MaxUserStats, LeaderboardScoresDownloaded_t > m_LeaderboardScoresDownloadedCallResult;
	CCallResult< MaxUserStats, LeaderboardFindResult_t > m_LeaderboardFindResultCallResult;
	CCallResult< MaxUserStats, GlobalAchievementPercentagesReady_t > m_GlobalAchievementPercentagesReadyResult;
	CCallResult< MaxUserStats, GlobalStatsReceived_t > m_GlobalStatsReceivedResult;
	CCallResult< MaxUserStats, UserStatsReceived_t > m_UserStatsReceivedResult;
	CCallResult< MaxUserStats, LeaderboardScoreUploaded_t > m_LeaderboardScoreUploadedResult;
	
public:
	STEAM_CALLBACK( MaxUserStats, OnUserStatsReceived, UserStatsReceived_t, m_CallbackUserStatsReceived );
	STEAM_CALLBACK( MaxUserStats, OnUserStatsStored, UserStatsStored_t, m_CallbackUserStatsStored );
	STEAM_CALLBACK( MaxUserStats, OnUserStatsUnloaded, UserStatsUnloaded_t, m_CallbackUserStatsUnloaded);
	STEAM_CALLBACK( MaxUserStats, OnUserAchievementIconFetched, UserAchievementIconFetched_t, m_CallbackUserAchievementIconFetched);
	STEAM_CALLBACK( MaxUserStats, OnUserAchievementStored, UserAchievementStored_t, m_CallbackUserAchievementStored);

	MaxUserStats(intptr_t instancePtr, BBObject * handle);
	~MaxUserStats();

	// calls
	void GetNumberOfCurrentPlayers();
	void DownloadLeaderboardEntries(uint64 leaderboardHandle, ELeaderboardDataRequest dataRequest, int rangeStart, int rangeEnd);
	void DownloadLeaderboardEntriesForUsers(uint64 leaderboardHandle, uint64 * users, int count);
	void FindLeaderboard(BBString * leaderboardName);
	void FindOrCreateLeaderboard(BBString * leaderboardName, ELeaderboardSortMethod sortMethod, ELeaderboardDisplayType displayType);
	void RequestGlobalAchievementPercentages();
	void RequestGlobalStats(int historyDays);
	void RequestUserStats(uint64 steamID);
	void UploadLeaderboardScore(uint64 leaderboardHandle, ELeaderboardUploadScoreMethod uploadScoreMethod, int score, int * scoreDetails, int count);

	// callbacks
	void OnGetNumberOfCurrentPlayers(NumberOfCurrentPlayers_t * result, bool failure);
	void OnLeaderboardScoresDownloaded(LeaderboardScoresDownloaded_t * result, bool failure);
	void OnLeaderboardFindResult(LeaderboardFindResult_t * result, bool failure);
	void OnGlobalAchievementPercentagesReady(GlobalAchievementPercentagesReady_t * result, bool failure);
	void OnGlobalStatsReceived(GlobalStatsReceived_t * result, bool failure);
	void OnUserStatsReceived(UserStatsReceived_t * result, bool failure);
	void OnLeaderboardScoreUploaded(LeaderboardScoreUploaded_t * result, bool failure);
};

MaxUserStats::MaxUserStats(intptr_t instancePtr, BBObject * handle) :
	instancePtr(instancePtr), maxHandle(handle),
	m_CallbackUserStatsReceived( this, &MaxUserStats::OnUserStatsReceived ),
	m_CallbackUserStatsStored( this, &MaxUserStats::OnUserStatsStored ),
	m_CallbackUserStatsUnloaded( this, &MaxUserStats::OnUserStatsUnloaded ),
	m_CallbackUserAchievementIconFetched( this, &MaxUserStats::OnUserAchievementIconFetched ),
	m_CallbackUserAchievementStored( this, &MaxUserStats::OnUserAchievementStored )
{
}

void MaxUserStats::OnUserStatsReceived( UserStatsReceived_t * result ) {
	steam_steamsdk_TSteamUserStats__OnUserStatsReceived(maxHandle, result->m_nGameID, result->m_eResult, result->m_steamIDUser.ConvertToUint64());
}

void MaxUserStats::OnUserStatsStored( UserStatsStored_t * result ) {
	steam_steamsdk_TSteamUserStats__OnUserStatsStored(maxHandle, result->m_nGameID, result->m_eResult);
}

void MaxUserStats::OnUserStatsUnloaded( UserStatsUnloaded_t * result ) {
	steam_steamsdk_TSteamUserStats__OnUserStatsUnloaded(maxHandle, result->m_steamIDUser.ConvertToUint64());
}

void MaxUserStats::OnUserAchievementIconFetched( UserAchievementIconFetched_t * result ) {
	steam_steamsdk_TSteamUserStats__OnUserAchievementIconFetched(maxHandle, result->m_nGameID.ToUint64(), bbStringFromUTF8String(result->m_rgchAchievementName), result->m_bAchieved, result->m_nIconHandle);
}

void MaxUserStats::OnUserAchievementStored( UserAchievementStored_t * result ) {
	steam_steamsdk_TSteamUserStats__OnUserAchievementStored(maxHandle, result->m_nGameID, result->m_bGroupAchievement, bbStringFromUTF8String(result->m_rgchAchievementName), result->m_nCurProgress, result->m_nMaxProgress);
}

void MaxUserStats::GetNumberOfCurrentPlayers() {
	SteamAPICall_t apiCall = SteamUserStats()->GetNumberOfCurrentPlayers();
	m_NumberOfCurrentPlayersCallResult.Set(apiCall, this, &MaxUserStats::OnGetNumberOfCurrentPlayers);
}

void MaxUserStats::DownloadLeaderboardEntries(uint64 leaderboardHandle, ELeaderboardDataRequest dataRequest, int rangeStart, int rangeEnd) {
	SteamAPICall_t apiCall = SteamUserStats()->DownloadLeaderboardEntries(leaderboardHandle, dataRequest, rangeStart, rangeEnd);
	m_LeaderboardScoresDownloadedCallResult.Set( apiCall, this, &MaxUserStats::OnLeaderboardScoresDownloaded);
}

void MaxUserStats::DownloadLeaderboardEntriesForUsers(uint64 leaderboardHandle, uint64 * users, int count) {
	std::vector<CSteamID> steamUsers;
	for (int i = 0; i < count; i++) {
		steamUsers.push_back(CSteamID(users[i]));
	}
	
	SteamAPICall_t apiCall = SteamUserStats()->DownloadLeaderboardEntriesForUsers(leaderboardHandle, steamUsers.data(), count);
	m_LeaderboardScoresDownloadedCallResult.Set(apiCall, this, &MaxUserStats::OnLeaderboardScoresDownloaded);
}

void MaxUserStats::FindLeaderboard(BBString * leaderboardName) {
	char * n = bbStringToUTF8String(leaderboardName);
	SteamAPICall_t apiCall = SteamUserStats()->FindLeaderboard(n);
	m_LeaderboardFindResultCallResult.Set(apiCall, this, &MaxUserStats::OnLeaderboardFindResult);
	bbMemFree(n);
}

void MaxUserStats::FindOrCreateLeaderboard(BBString * leaderboardName, ELeaderboardSortMethod sortMethod, ELeaderboardDisplayType displayType) {
	char * n = bbStringToUTF8String(leaderboardName);
	SteamAPICall_t apiCall = SteamUserStats()->FindOrCreateLeaderboard(n, sortMethod, displayType);
	m_LeaderboardFindResultCallResult.Set(apiCall, this, &MaxUserStats::OnLeaderboardFindResult);
	bbMemFree(n);
}

void MaxUserStats::RequestGlobalAchievementPercentages() {
	SteamAPICall_t apiCall = SteamUserStats()->RequestGlobalAchievementPercentages();
	m_GlobalAchievementPercentagesReadyResult.Set(apiCall, this, &MaxUserStats::OnGlobalAchievementPercentagesReady);
}

void MaxUserStats::RequestGlobalStats(int historyDays) {
	SteamAPICall_t apiCall = SteamUserStats()->RequestGlobalStats(historyDays);
	m_GlobalStatsReceivedResult.Set(apiCall, this, &MaxUserStats::OnGlobalStatsReceived);
}

void MaxUserStats::RequestUserStats(uint64 steamID) {
	SteamAPICall_t apiCall = SteamUserStats()->RequestUserStats(CSteamID(steamID));
	m_UserStatsReceivedResult.Set(apiCall, this, &MaxUserStats::OnUserStatsReceived);
}

void MaxUserStats::UploadLeaderboardScore(uint64 leaderboardHandle, ELeaderboardUploadScoreMethod uploadScoreMethod, int score, int * scoreDetails, int count) {
	SteamAPICall_t apiCall = SteamUserStats()->UploadLeaderboardScore(leaderboardHandle, uploadScoreMethod, score, scoreDetails, count);
	m_LeaderboardScoreUploadedResult.Set(apiCall, this, &MaxUserStats::OnLeaderboardScoreUploaded);
}

void MaxUserStats::OnGetNumberOfCurrentPlayers( NumberOfCurrentPlayers_t *result, bool failure ) {
	steam_steamsdk_TSteamUserStats__OnGetNumberOfCurrentPlayers(maxHandle, result->m_bSuccess, result->m_cPlayers);
}

void MaxUserStats::OnLeaderboardScoresDownloaded( LeaderboardScoresDownloaded_t * result, bool failure ) {
	steam_steamsdk_TSteamUserStats__OnLeaderboardScoresDownloaded(maxHandle, result->m_hSteamLeaderboard, result->m_hSteamLeaderboardEntries, result->m_cEntryCount);
}

void MaxUserStats::OnLeaderboardFindResult( LeaderboardFindResult_t * result, bool failure ) {
	steam_steamsdk_TSteamUserStats__OnLeaderboardFindResult(maxHandle, result->m_hSteamLeaderboard, result->m_bLeaderboardFound);
}

void MaxUserStats::OnGlobalAchievementPercentagesReady(GlobalAchievementPercentagesReady_t * result, bool failure) {
	steam_steamsdk_TSteamUserStats__OnGlobalAchievementPercentagesReady(maxHandle, result->m_nGameID, result->m_eResult);
}

void MaxUserStats::OnGlobalStatsReceived(GlobalStatsReceived_t * result, bool failure) {
	steam_steamsdk_TSteamUserStats__OnGlobalStatsReceived(maxHandle, result->m_nGameID, result->m_eResult);
}

void MaxUserStats::OnUserStatsReceived(UserStatsReceived_t * result, bool failure) {
	steam_steamsdk_TSteamUserStats__OnUserStatsReceived(maxHandle, result->m_nGameID, result->m_eResult, result->m_steamIDUser.ConvertToUint64());
}

void MaxUserStats::OnLeaderboardScoreUploaded(LeaderboardScoreUploaded_t * result, bool failure) {
	steam_steamsdk_TSteamUserStats__OnLeaderboardScoreUploaded(maxHandle, result->m_bSuccess, result->m_hSteamLeaderboard, result->m_nScore, result->m_bScoreChanged, result->m_nGlobalRankNew, result->m_nGlobalRankPrevious);
}

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void * bmx_steamsdk_register_steamuserstats(intptr_t instancePtr, BBObject * obj) {
	return new MaxUserStats(instancePtr, obj);
}

void bmx_steamsdk_unregister_steamuserstats(void * callbackPtr) {
	delete(callbackPtr);
}

int bmx_SteamAPI_ISteamUserStats_RequestCurrentStats(intptr_t instancePtr) {
	return SteamAPI_ISteamUserStats_RequestCurrentStats(instancePtr);
}

void bmx_SteamAPI_ISteamUserStats_GetNumberOfCurrentPlayers(MaxUserStats * userStats) {
	userStats->GetNumberOfCurrentPlayers();
}

int bmx_SteamAPI_ISteamUserStats_GetMostAchievedAchievementInfo(intptr_t instancePtr, BBString ** name, float * percent, int * achieved) {
	char buf[1024];
	bool ach;
	int res = SteamAPI_ISteamUserStats_GetMostAchievedAchievementInfo(instancePtr, buf, 1024, percent, &ach);
	if (res != -1) {
		*achieved = ach;
		*name = bbStringFromUTF8String(buf);
	}
	return res;
}

int bmx_SteamAPI_ISteamUserStats_GetNextMostAchievedAchievementInfo(intptr_t instancePtr, int previous, BBString ** name, float * percent, int * achieved) {
	char buf[1024];
	bool ach;
	int res = SteamAPI_ISteamUserStats_GetNextMostAchievedAchievementInfo(instancePtr, previous, buf, 1024, percent, &ach);
	if (res != -1) {
		*achieved = ach;
		*name = bbStringFromUTF8String(buf);
	}
	return res;
}

uint32 bmx_SteamAPI_ISteamUserStats_GetNumAchievements(intptr_t instancePtr) {
	return SteamAPI_ISteamUserStats_GetNumAchievements(instancePtr);
}

int bmx_SteamAPI_ISteamUserStats_ClearAchievement(intptr_t instancePtr, BBString * name) {
	char * n = bbStringToUTF8String(name);
	int res = SteamAPI_ISteamUserStats_ClearAchievement(instancePtr, n);
	bbMemFree(n);
	return res;
}

void bmx_SteamAPI_ISteamUserStats_DownloadLeaderboardEntries(MaxUserStats * userStats, uint64 leaderboardHandle, ELeaderboardDataRequest leaderboardDataRequest, int rangeStart, int rangeEnd) {
	userStats->DownloadLeaderboardEntries(leaderboardHandle, leaderboardDataRequest, rangeStart, rangeEnd);
}

void bmx_SteamAPI_ISteamUserStats_DownloadLeaderboardEntriesForUsers(MaxUserStats * userStats, uint64 leaderboardHandle, uint64 * users, int count) {
	userStats->DownloadLeaderboardEntriesForUsers(leaderboardHandle, users, count);
}

void bmx_SteamAPI_ISteamUserStats_FindLeaderboard(MaxUserStats * userStats, BBString * leaderboardName) {
	userStats->FindLeaderboard(leaderboardName);
}

void bmx_SteamAPI_ISteamUserStats_FindOrCreateLeaderboard(MaxUserStats * userStats, BBString * leaderboardName, ELeaderboardSortMethod sortMethod, ELeaderboardDisplayType displayType) {
	userStats->FindOrCreateLeaderboard(leaderboardName, sortMethod, displayType);
}

int bmx_SteamAPI_ISteamUserStats_GetAchievement(intptr_t instancePtr, BBString * name, int * achieved) {
	char * n = bbStringToUTF8String(name);
	bool ach;
	int res = SteamAPI_ISteamUserStats_GetAchievement(instancePtr, n, &ach);
	*achieved = ach;
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_GetAchievementAchievedPercent(intptr_t instancePtr, BBString * name, float * percent) {
	char * n = bbStringToUTF8String(name);
	int res = SteamAPI_ISteamUserStats_GetAchievementAchievedPercent(instancePtr, n, percent);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_GetAchievementAndUnlockTime(intptr_t instancePtr, BBString * name, int * achieved, uint32 * unlockTime) {
	char * n = bbStringToUTF8String(name);
	bool ach;
	int res = SteamAPI_ISteamUserStats_GetAchievementAndUnlockTime(instancePtr, n, &ach, unlockTime);
	*achieved = ach;
	bbMemFree(n);
	return res;
}

BBString * bmx_SteamAPI_ISteamUserStats_GetAchievementDisplayAttribute(intptr_t instancePtr, BBString * name, BBString * key) {
	char * n = bbStringToUTF8String(name);
	char * k = bbStringToUTF8String(key);
	const char * r = SteamAPI_ISteamUserStats_GetAchievementDisplayAttribute(instancePtr, n, k);
	bbMemFree(k);
	bbMemFree(n);
	if (strlen(r) == 0) {
		return &bbEmptyString;
	} else {
		return bbStringFromUTF8String(r);
	}
}

int bmx_SteamAPI_ISteamUserStats_GetAchievementIcon(intptr_t instancePtr, BBString * name) {
	char * n = bbStringToUTF8String(name);
	int res = SteamAPI_ISteamUserStats_GetAchievementIcon(instancePtr, n);
	bbMemFree(n);
	return res;
}

BBString * bmx_SteamAPI_ISteamUserStats_GetAchievementName(intptr_t instancePtr, uint32 achievement) {
	const char * n = SteamAPI_ISteamUserStats_GetAchievementName(instancePtr, achievement);
	if (strlen(n) == 0) {
		return &bbEmptyString;
	} else {
		return bbStringFromUTF8String(n);
	}
}

int bmx_SteamAPI_ISteamUserStats_GetGlobalStat(intptr_t instancePtr, BBString * statName, int64 * data) {
	char * n = bbStringToUTF8String(statName);
	int res = SteamAPI_ISteamUserStats_GetGlobalStat(instancePtr, n, data);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_GetGlobalStat0(intptr_t instancePtr, BBString * statName, double * data) {
	char * n = bbStringToUTF8String(statName);
	int res = SteamAPI_ISteamUserStats_GetGlobalStat0(instancePtr, n, data);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_GetGlobalStatHistory(intptr_t instancePtr, BBString * statName, int64 * data, uint32 count) {
	char * n = bbStringToUTF8String(statName);
	int res = SteamAPI_ISteamUserStats_GetGlobalStatHistory(instancePtr, n, data, count);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_GetGlobalStatHistory0(intptr_t instancePtr, BBString * statName, double * data, uint32 count) {
	char * n = bbStringToUTF8String(statName);
	int res = SteamAPI_ISteamUserStats_GetGlobalStatHistory0(instancePtr, n, data, count);
	bbMemFree(n);
	return res;
}

ELeaderboardDisplayType bmx_SteamAPI_ISteamUserStats_GetLeaderboardDisplayType(intptr_t instancePtr, uint64 leaderboardHandle) {
	return SteamAPI_ISteamUserStats_GetLeaderboardDisplayType(instancePtr, leaderboardHandle);
}

int bmx_SteamAPI_ISteamUserStats_GetLeaderboardEntryCount(intptr_t instancePtr, uint64 leaderboardHandle) {
	return SteamAPI_ISteamUserStats_GetLeaderboardEntryCount(instancePtr, leaderboardHandle);
}

BBString * bmx_SteamAPI_ISteamUserStats_GetLeaderboardName(intptr_t instancePtr, uint64 leaderboardHandle) {
	const char * n = SteamAPI_ISteamUserStats_GetLeaderboardName(instancePtr, leaderboardHandle);
	if (strlen(n) == 0) {
		return &bbEmptyString;
	} else {
		return bbStringFromUTF8String(n);
	}
}

ELeaderboardSortMethod bmx_SteamAPI_ISteamUserStats_GetLeaderboardSortMethod(intptr_t instancePtr, uint64 leaderboardHandle) {
	return SteamAPI_ISteamUserStats_GetLeaderboardSortMethod(instancePtr, leaderboardHandle);
}

int bmx_SteamAPI_ISteamGameServerStats_GetUserAchievement(intptr_t instancePtr, uint64 steamID, BBString * name, int * achieved) {
	char * n = bbStringToUTF8String(name);
	bool ach;
	int res = SteamAPI_ISteamGameServerStats_GetUserAchievement(instancePtr, CSteamID(steamID), n, &ach);
	*achieved = ach;
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_GetUserAchievementAndUnlockTime(intptr_t instancePtr, uint64 steamID, BBString * name, int * achieved, uint32 * unlockTime) {
	char * n = bbStringToUTF8String(name);
	bool ach;
	int res = SteamAPI_ISteamUserStats_GetUserAchievementAndUnlockTime(instancePtr, CSteamID(steamID), n, &ach, unlockTime);
	*achieved = ach;
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamGameServerStats_GetUserStat(intptr_t instancePtr, uint64 steamID, BBString * name, int * data) {
	char * n = bbStringToUTF8String(name);
	int res = SteamAPI_ISteamGameServerStats_GetUserStat(instancePtr, CSteamID(steamID), n, data);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamGameServerStats_GetUserStat0(intptr_t instancePtr, uint64 steamID, BBString * name, float * data) {
	char * n = bbStringToUTF8String(name);
	int res = SteamAPI_ISteamGameServerStats_GetUserStat0(instancePtr, CSteamID(steamID), n, data);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_IndicateAchievementProgress(intptr_t instancePtr, BBString * name, uint32 curProgress, uint32 maxProgress) {
	char * n = bbStringToUTF8String(name);
	int res = SteamAPI_ISteamUserStats_IndicateAchievementProgress(instancePtr, n, curProgress, maxProgress);
	bbMemFree(n);
	return res;
}

void bmx_SteamAPI_ISteamUserStats_RequestGlobalAchievementPercentages(MaxUserStats * userStats) {
	userStats->RequestGlobalAchievementPercentages();
}

void bmx_SteamAPI_ISteamUserStats_RequestGlobalStats(MaxUserStats * userStats, int historyDays) {
	userStats->RequestGlobalStats(historyDays);
}

void bmx_SteamAPI_ISteamGameServerStats_RequestUserStats(MaxUserStats * userStats, uint64 steamID) {
	userStats->RequestUserStats(steamID);
}

int bmx_SteamAPI_ISteamUserStats_ResetAllStats(intptr_t instancePtr, int achievementsToo) {
	return SteamAPI_ISteamUserStats_ResetAllStats(instancePtr, achievementsToo);
}

int bmx_SteamAPI_ISteamUserStats_SetAchievement(intptr_t instancePtr, BBString * name) {
	char * n = bbStringToUTF8String(name);
	int res = SteamAPI_ISteamUserStats_SetAchievement(instancePtr, n);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_SetStat(intptr_t instancePtr, BBString * name, int data) {
	char * n = bbStringToUTF8String(name);
	int res = SteamAPI_ISteamUserStats_SetStat(instancePtr, n,  data);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_SetStat0(intptr_t instancePtr, BBString * name, float data) {
	char * n = bbStringToUTF8String(name);
	int res = SteamAPI_ISteamUserStats_SetStat0(instancePtr, n, data);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_StoreStats(intptr_t instancePtr) {
	return SteamAPI_ISteamUserStats_StoreStats(instancePtr);
}

int bmx_SteamAPI_ISteamUserStats_UpdateAvgRateStat(intptr_t instancePtr, BBString * name, float countThisSession, double sessionLength) {
	char * n = bbStringToUTF8String(name);
	int res = SteamAPI_ISteamUserStats_UpdateAvgRateStat(instancePtr, n, countThisSession, sessionLength);
}

void bmx_SteamAPI_ISteamUserStats_UploadLeaderboardScore(MaxUserStats * userStats, uint64 leaderboardHandle, ELeaderboardUploadScoreMethod uploadScoreMethod, int score, int * scoreDetails, int count) {
	userStats->UploadLeaderboardScore(leaderboardHandle, uploadScoreMethod, score, scoreDetails, count);
}

// ISteamUGC --------------------------------------------

class MaxUGC
{
private:
	intptr_t instancePtr;
	BBObject * maxHandle;

	CCallResult< MaxUGC, AddAppDependencyResult_t > m_AddAppDependencyCallResult;
	CCallResult< MaxUGC, AddUGCDependencyResult_t > m_AddDependencyCallResult;
	CCallResult< MaxUGC, UserFavoriteItemsListChanged_t > m_UserFavoriteItemsListChangedCallResult;
	CCallResult< MaxUGC, CreateItemResult_t > m_CreateItemCallResult;
	CCallResult< MaxUGC, DeleteItemResult_t > m_DeleteItemCallResult;
	CCallResult< MaxUGC, GetUserItemVoteResult_t > m_GetUserItemVoteCallResult;
	CCallResult< MaxUGC, RemoveAppDependencyResult_t > m_RemoveAppDependencyCallResult;
	CCallResult< MaxUGC, RemoveUGCDependencyResult_t > m_RemoveUGCDependencyCallResult;
	CCallResult< MaxUGC, SteamUGCQueryCompleted_t > m_SteamUGCQueryCompletedCallResult;
	CCallResult< MaxUGC, SetUserItemVoteResult_t > m_SetUserItemVoteCallResult;
	CCallResult< MaxUGC, StartPlaytimeTrackingResult_t > m_StartPlaytimeTrackingCallResult;
	CCallResult< MaxUGC, StopPlaytimeTrackingResult_t > m_StopPlaytimeTrackingCallResult;
	CCallResult< MaxUGC, GetAppDependenciesResult_t > m_GetAppDependenciesCallResult;
	CCallResult< MaxUGC, SubmitItemUpdateResult_t > m_SubmitItemUpdateCallResult;
	CCallResult< MaxUGC, RemoteStorageSubscribePublishedFileResult_t > m_RemoteStorageSubscribePublishedFileCallResult;
	CCallResult< MaxUGC, RemoteStorageUnsubscribePublishedFileResult_t > m_RemoteStorageUnsubscribePublishedFileCallResult;

public:
	STEAM_CALLBACK( MaxUGC, OnDownloadItem, DownloadItemResult_t, m_CallbackDownloadItem );

	MaxUGC(intptr_t instancePtr, BBObject * handle);
	~MaxUGC();

	// calls
	void AddAppDependency(uint64 publishedFileID, uint32 appID);
	void AddDependency(uint64 parentPublishedFileID, uint64 childPublishedFileID);
	void AddItemToFavorites(uint32 appId, uint64 publishedFileID);
	void CreateItem(uint32 consumerAppId, EWorkshopFileType fileType);
	void DeleteItem(uint64 publishedFileID);
	void GetUserItemVote(uint64 publishedFileID);
	void RemoveAppDependency(uint64 publishedFileID, uint32 appID);
	void RemoveDependency(uint64 parentPublishedFileID, uint64 childPublishedFileID);
	void RemoveItemFromFavorites(uint32 appId, uint64 publishedFileID);
	void SendQueryUGCRequest(uint64 queryHandle);
	void SetUserItemVote(uint64 publishedFileID, bool voteUp);
	void StartPlaytimeTracking(uint64 * publishedFileIDs, uint32 numPublishedFileIDs);
	void StopPlaytimeTracking(uint64 * publishedFileID, uint32 numPublishedFileIDs);
	void StopPlaytimeTrackingForAllItems();
	void GetAppDependencies(uint64 publishedFileID);
	void SubmitItemUpdate(uint64 updateHandle, const char * changeNote);
	void SubscribeItem(uint64 publishedFileID);
	void UnsubscribeItem(uint64 publishedFileID);

	// Callbacks
	void OnAddAppDependency(AddAppDependencyResult_t * result, bool failure);
	void OnAddDependency(AddUGCDependencyResult_t * result, bool failure);
	void OnUserFavoriteItemsListChanged(UserFavoriteItemsListChanged_t * result, bool failure);
	void OnCreateItem(CreateItemResult_t * result, bool failure);
	void OnDeleteItem(DeleteItemResult_t * result, bool failure);
	void OnGetUserItemVote(GetUserItemVoteResult_t * result, bool failure);
	void OnRemoveAppDependency(RemoveAppDependencyResult_t * result, bool failure);
	void OnRemoveUGCDependency(RemoveUGCDependencyResult_t * result, bool failure);
	void OnSteamUGCQueryCompleted(SteamUGCQueryCompleted_t * result, bool failure);
	void OnSetUserItemVote(SetUserItemVoteResult_t * result, bool failure);
	void OnStartPlaytimeTracking(StartPlaytimeTrackingResult_t * result, bool failure);
	void OnStopPlaytimeTracking(StopPlaytimeTrackingResult_t * result, bool failure);
	void OnGetAppDependencies(GetAppDependenciesResult_t * result, bool failure);
	void OnSubmitItemUpdate(SubmitItemUpdateResult_t * result, bool failure);
	void OnRemoteStorageSubscribePublishedFile(RemoteStorageSubscribePublishedFileResult_t * result, bool failure);
	void OnRemoteStorageUnsubscribePublishedFile(RemoteStorageUnsubscribePublishedFileResult_t * result, bool failure);
};


MaxUGC::MaxUGC(intptr_t instancePtr, BBObject * handle) :
	instancePtr(instancePtr), maxHandle(handle),
	m_CallbackDownloadItem( this, &MaxUGC::OnDownloadItem )
{
}

void MaxUGC::OnDownloadItem(DownloadItemResult_t * result) {
	steam_steamsdk_TSteamUGC__OnDownloadItem(maxHandle, result->m_eResult, result->m_unAppID, result->m_nPublishedFileId);
}

void MaxUGC::AddAppDependency(uint64 publishedFileID, uint32 appID) {
	SteamAPICall_t apiCall = SteamUGC()->AddAppDependency(publishedFileID, appID);
	m_AddAppDependencyCallResult.Set(apiCall, this, &MaxUGC::OnAddAppDependency);
}

void MaxUGC::AddDependency(uint64 parentPublishedFileID, uint64 childPublishedFileID) {
	SteamAPICall_t apiCall = SteamUGC()->AddDependency(parentPublishedFileID, childPublishedFileID);
	m_AddDependencyCallResult.Set(apiCall, this, &MaxUGC::OnAddDependency);
}

void MaxUGC::AddItemToFavorites(uint32 appId, uint64 publishedFileID) {
	SteamAPICall_t apiCall = SteamUGC()->AddItemToFavorites(appId, publishedFileID);
	m_UserFavoriteItemsListChangedCallResult.Set(apiCall, this, &MaxUGC::OnUserFavoriteItemsListChanged);
}

void MaxUGC::CreateItem(uint32 consumerAppId, EWorkshopFileType fileType) {
	SteamAPICall_t apiCall = SteamUGC()->CreateItem(consumerAppId, fileType);
	m_CreateItemCallResult.Set(apiCall, this, &MaxUGC::OnCreateItem);
}

void MaxUGC::DeleteItem(uint64 publishedFileID) {
	SteamAPICall_t apiCall = SteamUGC()->DeleteItem(publishedFileID);
	m_DeleteItemCallResult.Set(apiCall, this, &MaxUGC::OnDeleteItem);
}

void MaxUGC::GetUserItemVote(uint64 publishedFileID) {
	SteamAPICall_t apiCall = SteamUGC()->GetUserItemVote(publishedFileID);
	m_GetUserItemVoteCallResult.Set(apiCall, this, &MaxUGC::OnGetUserItemVote);
}

void MaxUGC::RemoveAppDependency(uint64 publishedFileID, uint32 appID) {
	SteamAPICall_t apiCall = SteamUGC()->RemoveAppDependency(publishedFileID, appID);
	m_RemoveAppDependencyCallResult.Set(apiCall, this, &MaxUGC::OnRemoveAppDependency);
}

void MaxUGC::RemoveDependency(uint64 parentPublishedFileID, uint64 childPublishedFileID) {
	SteamAPICall_t apiCall = SteamUGC()->RemoveDependency(parentPublishedFileID, childPublishedFileID);
	m_RemoveUGCDependencyCallResult.Set(apiCall, this, &MaxUGC::OnRemoveUGCDependency);
}

void MaxUGC::RemoveItemFromFavorites(uint32 appId, uint64 publishedFileID) {
	SteamAPICall_t apiCall = SteamUGC()->RemoveItemFromFavorites(appId, publishedFileID);
	m_UserFavoriteItemsListChangedCallResult.Set(apiCall, this, &MaxUGC::OnUserFavoriteItemsListChanged);
}

void MaxUGC::SendQueryUGCRequest(uint64 queryHandle) {
	SteamAPICall_t apiCall = SteamUGC()->SendQueryUGCRequest(queryHandle);
	m_SteamUGCQueryCompletedCallResult.Set(apiCall, this, &MaxUGC::OnSteamUGCQueryCompleted);
}

void MaxUGC::SetUserItemVote(uint64 publishedFileID, bool voteUp) {
	SteamAPICall_t apiCall = SteamUGC()->SetUserItemVote(publishedFileID, voteUp);
	m_SetUserItemVoteCallResult.Set(apiCall, this, &MaxUGC::OnSetUserItemVote);
}

void MaxUGC::StartPlaytimeTracking(uint64 * publishedFileIDs, uint32 numPublishedFileIDs) {
	SteamAPICall_t apiCall = SteamUGC()->StartPlaytimeTracking(publishedFileIDs, numPublishedFileIDs);
	m_StartPlaytimeTrackingCallResult.Set(apiCall, this, &MaxUGC::OnStartPlaytimeTracking);
}

void MaxUGC::StopPlaytimeTracking(uint64 * publishedFileID, uint32 numPublishedFileIDs) {
	SteamAPICall_t apiCall = SteamUGC()->StopPlaytimeTracking(publishedFileID, numPublishedFileIDs);
	m_StopPlaytimeTrackingCallResult.Set(apiCall, this, &MaxUGC::OnStopPlaytimeTracking);
}

void MaxUGC::StopPlaytimeTrackingForAllItems() {
	SteamAPICall_t apiCall = SteamUGC()->StopPlaytimeTrackingForAllItems();
	m_StopPlaytimeTrackingCallResult.Set(apiCall, this, &MaxUGC::OnStopPlaytimeTracking);
}

void MaxUGC::GetAppDependencies(uint64 publishedFileID) {
	SteamAPICall_t apiCall = SteamUGC()->GetAppDependencies(publishedFileID);
	m_GetAppDependenciesCallResult.Set(apiCall, this, &MaxUGC::OnGetAppDependencies);
}

void MaxUGC::SubmitItemUpdate(uint64 updateHandle, const char * changeNote) {
	SteamAPICall_t apiCall = SteamUGC()->SubmitItemUpdate(updateHandle, changeNote);
	m_SubmitItemUpdateCallResult.Set(apiCall, this, &MaxUGC::OnSubmitItemUpdate);
}

void MaxUGC::SubscribeItem(uint64 publishedFileID) {
	SteamAPICall_t apiCall = SteamUGC()->SubscribeItem(publishedFileID);
	m_RemoteStorageSubscribePublishedFileCallResult.Set(apiCall, this, &MaxUGC::OnRemoteStorageSubscribePublishedFile);
}

void MaxUGC::UnsubscribeItem(uint64 publishedFileID) {
	SteamAPICall_t apiCall = SteamUGC()->UnsubscribeItem(publishedFileID);
	m_RemoteStorageUnsubscribePublishedFileCallResult.Set(apiCall, this, &MaxUGC::OnRemoteStorageUnsubscribePublishedFile);
}


void MaxUGC::OnAddAppDependency(AddAppDependencyResult_t *result, bool failure) {
	steam_steamsdk_TSteamUGC__OnAddAppDependency(maxHandle, result->m_eResult, result->m_nPublishedFileId, result->m_nAppID);
}

void MaxUGC::OnAddDependency(AddUGCDependencyResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnAddDependency(maxHandle, result->m_eResult, result->m_nPublishedFileId, result->m_nChildPublishedFileId);
}

void MaxUGC::OnUserFavoriteItemsListChanged(UserFavoriteItemsListChanged_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnUserFavoriteItemsListChanged(maxHandle, result->m_nPublishedFileId, result->m_eResult, static_cast<int>(result->m_bWasAddRequest));
}

void MaxUGC::OnCreateItem(CreateItemResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnCreateItem(maxHandle, result->m_eResult, result->m_nPublishedFileId, static_cast<int>(result->m_bUserNeedsToAcceptWorkshopLegalAgreement));
}

void MaxUGC::OnDeleteItem(DeleteItemResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnDeleteItem(maxHandle, result->m_eResult, result->m_nPublishedFileId);
}

void MaxUGC::OnGetUserItemVote(GetUserItemVoteResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnGetUserItemVote(maxHandle, result->m_nPublishedFileId, result->m_eResult, static_cast<int>(result->m_bVotedUp), static_cast<int>(result->m_bVotedDown), static_cast<int>(result->m_bVoteSkipped));
}

void MaxUGC::OnRemoveAppDependency(RemoveAppDependencyResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnRemoveAppDependency(maxHandle, result->m_eResult, result->m_nPublishedFileId, result->m_nAppID);
}

void MaxUGC::OnRemoveUGCDependency(RemoveUGCDependencyResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnRemoveUGCDependency(maxHandle, result->m_eResult, result->m_nPublishedFileId, result->m_nChildPublishedFileId);
}

void MaxUGC::OnSteamUGCQueryCompleted(SteamUGCQueryCompleted_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnSteamUGCQueryCompleted(maxHandle, result->m_handle, result->m_eResult, result->m_unNumResultsReturned, result->m_unTotalMatchingResults, static_cast<int>(result->m_bCachedData));
}

void MaxUGC::OnSetUserItemVote(SetUserItemVoteResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnSetUserItemVote(maxHandle, result->m_nPublishedFileId, result->m_eResult, static_cast<int>(result->m_bVoteUp));
}

void MaxUGC::OnStartPlaytimeTracking(StartPlaytimeTrackingResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnStartPlaytimeTracking(maxHandle, result->m_eResult);
}

void MaxUGC::OnStopPlaytimeTracking(StopPlaytimeTrackingResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnStopPlaytimeTracking(maxHandle, result->m_eResult);
}

void MaxUGC::OnGetAppDependencies(GetAppDependenciesResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnGetAppDependencies(maxHandle, result->m_eResult, result->m_nPublishedFileId, result->m_rgAppIDs, result->m_nNumAppDependencies, result->m_nTotalNumAppDependencies);
}

void MaxUGC::OnSubmitItemUpdate(SubmitItemUpdateResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnSubmitItemUpdate(maxHandle, result->m_eResult, static_cast<int>(result->m_bUserNeedsToAcceptWorkshopLegalAgreement));
}

void MaxUGC::OnRemoteStorageSubscribePublishedFile(RemoteStorageSubscribePublishedFileResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnRemoteStorageSubscribePublishedFile(maxHandle, result->m_eResult, result->m_nPublishedFileId);
}

void MaxUGC::OnRemoteStorageUnsubscribePublishedFile(RemoteStorageUnsubscribePublishedFileResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnRemoteStorageUnsubscribePublishedFile(maxHandle, result->m_eResult, result->m_nPublishedFileId);
}

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void * bmx_steamsdk_register_steamugc(intptr_t instancePtr, BBObject * obj) {
	return new MaxUGC(instancePtr, obj);
}

void bmx_steamsdk_unregister_steamugc(void * callbackPtr) {
	delete(callbackPtr);
}

void bmx_SteamAPI_ISteamUGC_AddAppDependency(MaxUGC * ugc, uint64 publishedFileID, uint32 appID) {
	ugc->AddAppDependency(publishedFileID, appID);
}

void bmx_SteamAPI_ISteamUGC_AddDependency(MaxUGC * ugc, uint64 publishedFileId, uint64 childPublishedFileId) {
	ugc->AddDependency(publishedFileId, childPublishedFileId);
}

int bmx_SteamAPI_ISteamUGC_AddExcludedTag(intptr_t instancePtr, uint64 queryHandle, BBString * tagName) {
	char * t = bbStringToUTF8String(tagName);
	bool res = SteamAPI_ISteamUGC_AddExcludedTag(instancePtr, queryHandle, t);
	bbMemFree(t);
	return res;
}

int bmx_SteamAPI_ISteamUGC_AddItemKeyValueTag(intptr_t instancePtr, uint64 queryHandle, BBString * key, BBString * value) {
	char * k = bbStringToUTF8String(key);
	char * v = bbStringToUTF8String(value);
	bool res = SteamAPI_ISteamUGC_AddItemKeyValueTag(instancePtr, queryHandle, k, v);
	bbMemFree(v);
	bbMemFree(k);
	return res;
}

int bmx_SteamAPI_ISteamUGC_AddItemPreviewFile(intptr_t instancePtr, uint64 queryHandle, BBString * previewFile, EItemPreviewType previewType) {
	char * p = bbStringToUTF8String(previewFile);
	bool res = SteamAPI_ISteamUGC_AddItemPreviewFile(instancePtr, queryHandle, p, previewType);
	bbMemFree(p);
	return res;
}

int bmx_SteamAPI_ISteamUGC_AddItemPreviewVideo(intptr_t instancePtr, uint64 queryHandle, BBString * videoID) {
	char * v = bbStringToUTF8String(videoID);
	bool res = SteamAPI_ISteamUGC_AddItemPreviewVideo(instancePtr, queryHandle, v);
	bbMemFree(v);
	return res;
}

void bmx_SteamAPI_ISteamUGC_AddItemToFavorites(MaxUGC * ugc, uint32 appId, uint64 publishedFileID) {
	ugc->AddItemToFavorites(appId, publishedFileID);
}

int bmx_SteamAPI_ISteamUGC_AddRequiredKeyValueTag(intptr_t instancePtr, uint64 queryHandle, BBString * key, BBString * value) {
	char * k = bbStringToUTF8String(key);
	char * v = bbStringToUTF8String(value);
	bool res = SteamAPI_ISteamUGC_AddRequiredKeyValueTag(instancePtr, queryHandle, k, v);
	bbMemFree(v);
	bbMemFree(k);
	return res;
}

int bmx_SteamAPI_ISteamUGC_AddRequiredTag(intptr_t instancePtr, uint64 queryHandle, BBString * tagName) {
	char * t = bbStringToUTF8String(tagName);
	bool res = SteamAPI_ISteamUGC_AddRequiredTag(instancePtr, queryHandle, t);
	bbMemFree(t);
	return res;
}

int bmx_SteamAPI_ISteamUGC_InitWorkshopForGameServer(intptr_t instancePtr, uint64 workshopDepotID, BBString * folder) {
	char * f = bbStringToUTF8String(folder);
	bool res = SteamAPI_ISteamUGC_BInitWorkshopForGameServer(instancePtr, workshopDepotID, f);
	bbMemFree(f);
	return res;
}

void bmx_SteamAPI_ISteamUGC_CreateItem(MaxUGC * ugc, uint32 consumerAppId, EWorkshopFileType fileType) {
	ugc->CreateItem(consumerAppId, fileType);
}

uint64 bmx_SteamAPI_ISteamUGC_CreateQueryAllUGCRequest(intptr_t instancePtr, EUGCQuery queryType, EUGCMatchingUGCType matchingeMatchingUGCTypeFileType, uint32 creatorAppID, uint32 consumerAppID, uint32 page) {
	return SteamAPI_ISteamUGC_CreateQueryAllUGCRequest(instancePtr, queryType, matchingeMatchingUGCTypeFileType, creatorAppID, consumerAppID, page);
}

uint64 bmx_SteamAPI_ISteamUGC_CreateQueryUGCDetailsRequest(intptr_t instancePtr, uint64 * publishedFileIDs, int numPublishedFileIDs) {
	return SteamAPI_ISteamUGC_CreateQueryUGCDetailsRequest(instancePtr, publishedFileIDs, numPublishedFileIDs);
}

uint64 bmx_SteamAPI_ISteamUGC_CreateQueryUserUGCRequest(intptr_t instancePtr, uint32 accountID, EUserUGCList listType, EUGCMatchingUGCType matchingUGCType, EUserUGCListSortOrder sortOrder, uint32 creatorAppID, uint32 consumerAppID, uint32 page) {
	return SteamAPI_ISteamUGC_CreateQueryUserUGCRequest(instancePtr, accountID, listType, matchingUGCType, sortOrder, creatorAppID, consumerAppID, page);
}

void bmx_SteamAPI_ISteamUGC_DeleteItem(MaxUGC * ugc, uint64 publishedFileID) {
	ugc->DeleteItem(publishedFileID);
}

int bmx_SteamAPI_ISteamUGC_DownloadItem(intptr_t instancePtr, uint64 publishedFileID, int highPriority) {
	return SteamAPI_ISteamUGC_DownloadItem(instancePtr, publishedFileID, highPriority);
}

void bmx_SteamAPI_ISteamUGC_GetAppDependencies(MaxUGC * ugc, uint64 publishedFileID) {
	ugc->GetAppDependencies(publishedFileID);
}

int bmx_SteamAPI_ISteamUGC_GetItemDownloadInfo(intptr_t instancePtr, uint64 publishedFileID, uint64 * bytesDownloaded, uint64 * bytesTotal) {
	return SteamAPI_ISteamUGC_GetItemDownloadInfo(instancePtr, publishedFileID, bytesDownloaded, bytesTotal);
}

int bmx_SteamAPI_ISteamUGC_GetItemInstallInfo(intptr_t instancePtr, uint64 publishedFileID, uint64 * sizeOnDisk, BBString ** folder, uint32 * timestamp) {
	char fbuf[BUFFER_SIZE];
	bool res = SteamAPI_ISteamUGC_GetItemInstallInfo(instancePtr, publishedFileID, sizeOnDisk, fbuf, BUFFER_SIZE, timestamp);
	*folder = bbStringFromUTF8String(fbuf);
	return res;
}

uint32 bmx_SteamAPI_ISteamUGC_GetItemState(intptr_t instancePtr, uint64 publishedFileID) {
	return SteamAPI_ISteamUGC_GetItemState(instancePtr, publishedFileID);
}

EItemUpdateStatus bmx_SteamAPI_ISteamUGC_GetItemUpdateProgress(intptr_t instancePtr, uint64 queryHandle, uint64 * bytesProcessed, uint64 * bytesTotal) {
	return SteamAPI_ISteamUGC_GetItemUpdateProgress(instancePtr, queryHandle, bytesProcessed, bytesTotal);
}

uint32 bmx_SteamAPI_ISteamUGC_GetNumSubscribedItems(intptr_t instancePtr) {
	return SteamAPI_ISteamUGC_GetNumSubscribedItems(instancePtr);
}

int bmx_SteamAPI_ISteamUGC_GetQueryUGCAdditionalPreview(intptr_t instancePtr, uint64 queryHandle, uint32 index, uint32 previewIndex, BBString ** URLOrVideoID, BBString ** originalFileName, EItemPreviewType * previewType) {
	char urlbuf[BUFFER_SIZE];
	char filebuf[BUFFER_SIZE];
	bool res = SteamAPI_ISteamUGC_GetQueryUGCAdditionalPreview(instancePtr, queryHandle, index, previewIndex, urlbuf, BUFFER_SIZE, filebuf, BUFFER_SIZE, previewType);
	*URLOrVideoID = bbStringFromUTF8String(urlbuf);
	*originalFileName = bbStringFromUTF8String(filebuf);
	return res;
}

int bmx_SteamAPI_ISteamUGC_GetQueryUGCChildren(intptr_t instancePtr, uint64 queryHandle, uint32 index, uint64 * publishedFileIDs, uint32 maxEntries) {
	return SteamAPI_ISteamUGC_GetQueryUGCChildren(instancePtr, queryHandle, index, publishedFileIDs, maxEntries);
}

int bmx_SteamAPI_ISteamUGC_GetQueryUGCKeyValueTag(intptr_t instancePtr, uint64 queryHandle, uint32 index, uint32 keyValueTagIndex, BBString ** key, BBString ** value) {
	char keybuf[BUFFER_SIZE];
	char valuebuf[VALUE_SIZE];
	bool res = SteamAPI_ISteamUGC_GetQueryUGCKeyValueTag(instancePtr, queryHandle, index, keyValueTagIndex, keybuf, BUFFER_SIZE, valuebuf, VALUE_SIZE);
	*key = bbStringFromUTF8String(keybuf);
	*value = bbStringFromUTF8String(valuebuf);
	return res;
}

int bmx_SteamAPI_ISteamUGC_GetQueryUGCMetadata(intptr_t instancePtr, uint64 queryHandle, uint32 index, BBString ** metadata) {
	char metabuf[METADATA_SIZE];
	bool res = SteamAPI_ISteamUGC_GetQueryUGCMetadata(instancePtr, queryHandle, index, metabuf, METADATA_SIZE);
	*metadata = bbStringFromUTF8String(metabuf);
	return res;
}

uint32 bmx_SteamAPI_ISteamUGC_GetQueryUGCNumAdditionalPreviews(intptr_t instancePtr, uint64 queryHandle, uint32 index) {
	return SteamAPI_ISteamUGC_GetQueryUGCNumAdditionalPreviews(instancePtr, queryHandle, index);
}

uint32 bmx_SteamAPI_ISteamUGC_GetQueryUGCNumKeyValueTags(intptr_t instancePtr, uint64 queryHandle, uint32 index) {
	return SteamAPI_ISteamUGC_GetQueryUGCNumKeyValueTags(instancePtr, queryHandle, index);
}

int bmx_SteamAPI_ISteamUGC_GetQueryUGCPreviewURL(intptr_t instancePtr, uint64 queryHandle, uint32 index, BBString ** URL) {
	char urlbuf[BUFFER_SIZE];
	bool res = SteamAPI_ISteamUGC_GetQueryUGCPreviewURL(instancePtr, queryHandle, index, urlbuf, BUFFER_SIZE);
	*URL = bbStringFromUTF8String(urlbuf);
	return res;
}

int bmx_SteamAPI_ISteamUGC_GetQueryUGCStatistic(intptr_t instancePtr, uint64 queryHandle, uint32 index, EItemStatistic statType, uint64 * statValue) {
	return SteamAPI_ISteamUGC_GetQueryUGCStatistic(instancePtr, queryHandle, index, statType, statValue);
}

uint32 bmx_SteamAPI_ISteamUGC_GetSubscribedItems(intptr_t instancePtr, uint64 * publishedFileIDs, uint32 maxEntries) {
	return SteamAPI_ISteamUGC_GetSubscribedItems(instancePtr, publishedFileIDs, maxEntries);
}

void bmx_SteamAPI_ISteamUGC_GetUserItemVote(MaxUGC * ugc, uint64 publishedFileID) {
	ugc->GetUserItemVote(publishedFileID);
}

int bmx_SteamAPI_ISteamUGC_ReleaseQueryUGCRequest(intptr_t instancePtr, uint64 queryHandle) {
	return SteamAPI_ISteamUGC_ReleaseQueryUGCRequest(instancePtr, queryHandle);
}

void bmx_SteamAPI_ISteamUGC_RemoveAppDependency(MaxUGC * ugc, uint64 publishedFileID, uint32 appID) {
	ugc->RemoveAppDependency(publishedFileID, appID);
}

void bmx_SteamAPI_ISteamUGC_RemoveDependency(MaxUGC * ugc, uint64 parentPublishedFileID, uint64 childPublishedFileID) {
	ugc->RemoveDependency(parentPublishedFileID, childPublishedFileID);
}

void bmx_SteamAPI_ISteamUGC_RemoveItemFromFavorites(MaxUGC * ugc, uint32 appId, uint64 publishedFileID) {
	ugc->RemoveItemFromFavorites(appId, publishedFileID);
}

int bmx_SteamAPI_ISteamUGC_RemoveItemKeyValueTags(intptr_t instancePtr, uint64 queryHandle, BBString * key) {
	char * k = bbStringToUTF8String(key);
	bool res = SteamAPI_ISteamUGC_RemoveItemKeyValueTags(instancePtr, queryHandle, k);
	bbMemFree(k);
	return res;
}

int bmx_SteamAPI_ISteamUGC_RemoveItemPreview(intptr_t instancePtr, uint64 queryHandle, uint32 index) {
	return SteamAPI_ISteamUGC_RemoveItemPreview(instancePtr, queryHandle, index);
}

void bmx_SteamAPI_ISteamUGC_SendQueryUGCRequest(MaxUGC * ugc, uint64 queryHandle) {
	ugc->SendQueryUGCRequest(queryHandle);
}

int bmx_SteamAPI_ISteamUGC_SetAllowCachedResponse(intptr_t instancePtr, uint64 queryHandle, uint32 maxAgeSeconds) {
	return SteamAPI_ISteamUGC_SetAllowCachedResponse(instancePtr, queryHandle, maxAgeSeconds);
}

int bmx_SteamAPI_ISteamUGC_SetCloudFileNameFilter(intptr_t instancePtr, uint64 queryHandle, BBString * matchCloudFileName) {
	char * n = bbStringToUTF8String(matchCloudFileName);
	bool res = SteamAPI_ISteamUGC_SetCloudFileNameFilter(instancePtr, queryHandle, n);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUGC_SetItemContent(intptr_t instancePtr, uint64 updateHandle, BBString * contentFolder) {
	char * c = bbStringToUTF8String(contentFolder);
	bool res = SteamAPI_ISteamUGC_SetItemContent(instancePtr, updateHandle, c);
	bbMemFree(c);
	return res;	
}

int bmx_SteamAPI_ISteamUGC_SetItemDescription(intptr_t instancePtr, uint64 updateHandle, BBString * description) {
	char * d = bbStringToUTF8String(description);
	bool res = SteamAPI_ISteamUGC_SetItemDescription(instancePtr, updateHandle, d);
	bbMemFree(d);
	return res;		
}

int bmx_SteamAPI_ISteamUGC_SetItemMetadata(intptr_t instancePtr, uint64 updateHandle, BBString * metaData) {
	char * m = bbStringToUTF8String(metaData);
	bool res = SteamAPI_ISteamUGC_SetItemMetadata(instancePtr, updateHandle, m);
	bbMemFree(m);
	return res;		
}

int bmx_SteamAPI_ISteamUGC_SetItemPreview(intptr_t instancePtr, uint64 updateHandle, BBString * previewFile) {
	char * p = bbStringToUTF8String(previewFile);
	bool res = SteamAPI_ISteamUGC_SetItemPreview(instancePtr, updateHandle, p);
	bbMemFree(p);
	return res;		
}

int bmx_SteamAPI_ISteamUGC_SetItemTags(intptr_t instancePtr, uint64 updateHandle, BBArray * tags) {
	int n = tags->scales[0];
	BBString **s=(BBString**)BBARRAYDATA(tags, tags->dims);

	SteamParamStringArray_t array = { 0 };
	array.m_nNumStrings = n;
	array.m_ppStrings = (const char**)malloc(sizeof(char*) * n);

	for (int i = 0; i < n; i++) {
		array.m_ppStrings[i] = bbStringToUTF8String(s[i]);
	}

	bool res = SteamAPI_ISteamUGC_SetItemTags(instancePtr, updateHandle, &array);

	for (int i = 0; i < n; i++) {
		bbMemFree((char*)array.m_ppStrings[i]);
	}

	free(array.m_ppStrings);
	return res;
}

int bmx_SteamAPI_ISteamUGC_SetItemTitle(intptr_t instancePtr, uint64 updateHandle, BBString * title) {
	char * t = bbStringToUTF8String(title);
	bool res = SteamAPI_ISteamUGC_SetItemTitle(instancePtr, updateHandle, t);
	bbMemFree(t);
	return res;		
}

int bmx_SteamAPI_ISteamUGC_SetItemUpdateLanguage(intptr_t instancePtr, uint64 updateHandle, BBString * language) {
	char * t = bbStringToUTF8String(language);
	bool res = SteamAPI_ISteamUGC_SetItemUpdateLanguage(instancePtr, updateHandle, t);
	bbMemFree(t);
	return res;		
}

int bmx_SteamAPI_ISteamUGC_SetItemVisibility(intptr_t instancePtr, uint64 updateHandle, ERemoteStoragePublishedFileVisibility visibility) {
	return SteamAPI_ISteamUGC_SetItemVisibility(instancePtr, updateHandle, visibility);
}

int bmx_SteamAPI_ISteamUGC_SetLanguage(intptr_t instancePtr, uint64 queryHandle, BBString * language) {
	char * t = bbStringToUTF8String(language);
	bool res = SteamAPI_ISteamUGC_SetLanguage(instancePtr, queryHandle, t);
	bbMemFree(t);
	return res;		
}

int bmx_SteamAPI_ISteamUGC_SetMatchAnyTag(intptr_t instancePtr, uint64 queryHandle, int matchAnyTag) {
	return SteamAPI_ISteamUGC_SetMatchAnyTag(instancePtr, queryHandle, matchAnyTag);
}

int bmx_SteamAPI_ISteamUGC_SetRankedByTrendDays(intptr_t instancePtr, uint64 queryHandle, uint32 days) {
	return SteamAPI_ISteamUGC_SetRankedByTrendDays(instancePtr, queryHandle, days);
}

int bmx_SteamAPI_ISteamUGC_SetReturnAdditionalPreviews(intptr_t instancePtr, uint64 queryHandle, int returnAdditionalPreviews) {
	return SteamAPI_ISteamUGC_SetReturnAdditionalPreviews(instancePtr, queryHandle, returnAdditionalPreviews);
}

int bmx_SteamAPI_ISteamUGC_SetReturnChildren(intptr_t instancePtr, uint64 queryHandle, int returnChildren) {
	return SteamAPI_ISteamUGC_SetReturnChildren(instancePtr, queryHandle, returnChildren);
}

int bmx_SteamAPI_ISteamUGC_SetReturnKeyValueTags(intptr_t instancePtr, uint64 queryHandle, int returnKeyValueTags) {
	return SteamAPI_ISteamUGC_SetReturnKeyValueTags(instancePtr, queryHandle, returnKeyValueTags);
}

int bmx_SteamAPI_ISteamUGC_SetReturnLongDescription(intptr_t instancePtr, uint64 queryHandle, int returnLongDescription) {
	return SteamAPI_ISteamUGC_SetReturnLongDescription(instancePtr, queryHandle, returnLongDescription);
}

int bmx_SteamAPI_ISteamUGC_SetReturnMetadata(intptr_t instancePtr, uint64 queryHandle, int returnMetadata) {
	return SteamAPI_ISteamUGC_SetReturnMetadata(instancePtr, queryHandle, returnMetadata);
}

int bmx_SteamAPI_ISteamUGC_SetReturnOnlyIDs(intptr_t instancePtr, uint64 queryHandle, int returnOnlyIDs) {
	return SteamAPI_ISteamUGC_SetReturnOnlyIDs(instancePtr, queryHandle, returnOnlyIDs);
}

int bmx_SteamAPI_ISteamUGC_SetReturnPlaytimeStats(intptr_t instancePtr, uint64 queryHandle, uint32 days) {
	return SteamAPI_ISteamUGC_SetReturnPlaytimeStats(instancePtr, queryHandle, days);
}

int bmx_SteamAPI_ISteamUGC_SetReturnTotalOnly(intptr_t instancePtr, uint64 queryHandle, int returnTotalOnly) {
	return SteamAPI_ISteamUGC_SetReturnTotalOnly(instancePtr, queryHandle, returnTotalOnly);
}

int bmx_SteamAPI_ISteamUGC_SetSearchText(intptr_t instancePtr, uint64 queryHandle, BBString * searchText) {
	char * s = bbStringToUTF8String(searchText);
	bool res = SteamAPI_ISteamUGC_SetSearchText(instancePtr, queryHandle, s);
	bbMemFree(s);
	return res;		
}

void bmx_SteamAPI_ISteamUGC_SetUserItemVote(MaxUGC * ugc, uint64 publishedFileID, int voteUp) {
	ugc->SetUserItemVote(publishedFileID, voteUp);
}

uint64 bmx_SteamAPI_ISteamUGC_StartItemUpdate(intptr_t instancePtr, uint32 consumerAppId, uint64 publishedFileID) {
	return SteamAPI_ISteamUGC_StartItemUpdate(instancePtr, consumerAppId, publishedFileID);
}

void bmx_SteamAPI_ISteamUGC_StartPlaytimeTracking(MaxUGC * ugc, uint64 * publishedFileIDs, uint32 numPublishedFileIDs) {
	ugc->StartPlaytimeTracking(publishedFileIDs, numPublishedFileIDs);
}

void bmx_SteamAPI_ISteamUGC_StopPlaytimeTracking(MaxUGC * ugc, uint64 * publishedFileIDs, uint32 numPublishedFileIDs) {
	ugc->StopPlaytimeTracking(publishedFileIDs, numPublishedFileIDs);
}

void bmx_SteamAPI_ISteamUGC_StopPlaytimeTrackingForAllItems(MaxUGC * ugc) {
	ugc->StopPlaytimeTrackingForAllItems();
}

void bmx_SteamAPI_ISteamUGC_SubmitItemUpdate(MaxUGC * ugc, uint64 updateHandle, BBString * changeNote) {
	char * c = NULL;
	if (changeNote != &bbEmptyString) {
		c = bbStringToUTF8String(changeNote);
	}
	ugc->SubmitItemUpdate(updateHandle, c);
	if (c) {
		bbMemFree(c);
	}
}

void bmx_SteamAPI_ISteamUGC_SubscribeItem(MaxUGC * ugc, uint64 publishedFileID) {
	ugc->SubscribeItem(publishedFileID);
}

void bmx_SteamAPI_ISteamUGC_SuspendDownloads(intptr_t instancePtr, int suspend) {
	SteamAPI_ISteamUGC_SuspendDownloads(instancePtr, suspend);
}

void bmx_SteamAPI_ISteamUGC_UnsubscribeItem(MaxUGC * ugc, uint64 publishedFileID) {
	ugc->UnsubscribeItem(publishedFileID);
}

int bmx_SteamAPI_ISteamUGC_UpdateItemPreviewFile(intptr_t instancePtr, uint64 updateHandle, uint32 index, BBString * previewFile) {
	char * f = bbStringToUTF8String(previewFile);
	bool res = SteamAPI_ISteamUGC_UpdateItemPreviewFile(instancePtr, updateHandle, index, f);
	bbMemFree(f);
	return res;		
}

int bmx_SteamAPI_ISteamUGC_UpdateItemPreviewVideo(intptr_t instancePtr, uint64 updateHandle, uint32 index, BBString * videoID) {
	char * v = bbStringToUTF8String(videoID);
	bool res = SteamAPI_ISteamUGC_UpdateItemPreviewVideo(instancePtr, updateHandle, index, v);
	bbMemFree(v);
	return res;		
}
