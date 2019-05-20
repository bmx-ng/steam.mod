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
