/*
  Copyright (c) 2019-2026 Bruce A Henderson

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
#define GC_THREADS
#include "brl.mod/blitz.mod/bdwgc/include/gc.h"
#include "brl.mod/blitz.mod/blitz.h"

#include "steam/steam_api_flat.h"
#include "steam/isteamdualsense.h"

#include <chrono>
#include <atomic>
#include <cstdio>
#include <thread>
#include <functional>
#include <vector>
#include <algorithm>

class MaxUtils;
class MaxUserStats;
class MaxUser;
class MaxUGC;
class MaxFriends;
class MaxApps;
class MaxMatchmaking;
class MaxNetworkingMessages;
class MaxRemoteStorage;
class MaxRemoteStorageWriteRequest;
class MaxRemoteStorageReadRequest;
class MaxInput;
class MaxTimeline;

static std::vector<MaxRemoteStorageWriteRequest *> g_remoteStorageWriteRequests;
static std::vector<MaxRemoteStorageReadRequest *> g_remoteStorageReadRequests;
static void CancelRemoteStorageRequests();

#define BUFFER_SIZE 2048
#define VALUE_SIZE 16384
#define METADATA_SIZE 5000

extern "C" {

	void steam_steamsdk_TSteamUtils__OnCheckFileSignature(BBObject * maxHandle, ECheckFileSignature checkFileSignature);
	void steam_steamsdk_TSteamUtils__OnGamepadTextInputDismissed( BBObject * maxHandle, int ubmitted, uint32 submittedTextLength);
	void steam_steamsdk_TSteamUtils__OnLowBatteryPower(BBObject * maxHandle, int minutesBatteryLeft);
	void steam_steamsdk_TSteamUtils__OnSteamShutdown(BBObject * maxHandle);

	void steam_steamsdk_TSteamUserStats__OnUserStatsReceived( BBObject * maxHandle, uint64 gameID, EResult result, uint64 steamID);
	void steam_steamsdk_TSteamUserStats__OnUserStatsStored(BBObject * maxHandle, uint64 gameID, EResult result);
	void steam_steamsdk_TSteamUserStats__OnGetNumberOfCurrentPlayers(BBObject * maxHandle, int success, int players);
	void steam_steamsdk_TSteamUserStats__OnLeaderboardFindResult( BBObject * maxHandle, uint64 leaderboardHandle, int leaderboardFound);
	void steam_steamsdk_TSteamUserStats__OnLeaderboardScoresDownloaded( BBObject * maxHandle, uint64 leaderboardHandle, uint64 leaderboardEntriesHandle, int entryCount);
	void steam_steamsdk_TSteamUserStats__OnGlobalAchievementPercentagesReady( BBObject * maxHandle, uint64 gameID, EResult result);
	void steam_steamsdk_TSteamUserStats__OnGlobalStatsReceived(BBObject * maxHandle, uint64 gameID, EResult result);
	void steam_steamsdk_TSteamUserStats__OnLeaderboardScoreUploaded(BBObject * maxHandle, int success, uint64 leaderboardHandle, int score, int scoreChanged, int globalRankNew, int globalRankPrevious);
	void steam_steamsdk_TSteamUserStats__OnLeaderboardUGCSet( BBObject * maxHandle, EResult result, uint64 leaderboardHandle, int failure);
	void steam_steamsdk_TSteamUserStats__OnUserStatsUnloaded(BBObject * maxHandle, uint64 steamID);
	void steam_steamsdk_TSteamUserStats__OnUserAchievementIconFetched( BBObject * maxHandle, uint64 gameID, BBString * achievementName, int achieved, int iconHandle);
	void steam_steamsdk_TSteamUserStats__OnUserAchievementStored(BBObject * maxHandle, uint64 gameID, int groupAchievement, BBString * achievementName, uint32 curProgress, uint32 maxProgress);

	void steam_steamsdk_TSteamUGC__OnAddAppDependency( BBObject * maxHandle, EResult result, uint64 publishedFileId, uint32 appID);
	void steam_steamsdk_TSteamUGC__OnAddDependency( BBObject * maxHandle, EResult result, uint64 publishedFileId, uint64 childPublishedFileId);
	void steam_steamsdk_TSteamUGC__OnUserFavoriteItemsListChanged( BBObject * maxHandle, uint64 publishedFileId, EResult result, int wasAddRequest);
	void steam_steamsdk_TSteamUGC__OnCreateItem( BBObject * maxHandle, EResult result, uint64 publishedFileId, int userNeedsToAcceptWorkshopLegalAgreement);
	void steam_steamsdk_TSteamUGC__OnDeleteItem(BBObject * maxHandle, EResult result, uint64 publishedFileId);
	void steam_steamsdk_TSteamUGC__OnDownloadItem( BBObject * maxHandle, EResult result, uint32 appID, uint64 publishedFileId);
	void steam_steamsdk_TSteamUGC__OnGetUserItemVote( BBObject * maxHandle, uint64 publishedFileId, EResult result, int votedUp, int votedDown, int voteSkipped);
	void steam_steamsdk_TSteamUGC__OnItemInstalled(BBObject * maxHandle, uint32 appID, uint64 publishedFileId);
	void steam_steamsdk_TSteamUGC__OnRemoveAppDependency( BBObject * maxHandle, EResult result, uint64 publishedFileId, uint32 appID);
	void steam_steamsdk_TSteamUGC__OnRemoveUGCDependency( BBObject * maxHandle, EResult result, uint64 publishedFileId, uint64 childPublishedFileId);
	void steam_steamsdk_TSteamUGC__OnSteamUGCQueryCompleted(BBObject * maxHandle, uint64 handle, EResult result, uint32 numResultsReturned, uint32 totalMatchingResults, int cachedData);
	void steam_steamsdk_TSteamUGC__OnSetUserItemVote( BBObject * maxHandle, uint64 publishedFileId, EResult result, int voteUp);
	void steam_steamsdk_TSteamUGC__OnStartPlaytimeTracking(BBObject * maxHandle, EResult result);
	void steam_steamsdk_TSteamUGC__OnStopPlaytimeTracking(BBObject * maxHandle, EResult result);
	void steam_steamsdk_TSteamUGC__OnGetAppDependencies(BBObject * maxHandle, EResult result, uint64 publishedFileId, uint32 * appID, int numAppDependencies, int totalNumAppDependencies);
	void steam_steamsdk_TSteamUGC__OnSubmitItemUpdate( BBObject * maxHandle, EResult result, int userNeedsToAcceptWorkshopLegalAgreement);
	void steam_steamsdk_TSteamUGC__OnRemoteStorageSubscribePublishedFile( BBObject * maxHandle, EResult result, uint64 publishedFileId);
	void steam_steamsdk_TSteamUGC__OnRemoteStorageUnsubscribePublishedFile( BBObject * maxHandle, EResult result, uint64 publishedFileId);
	void steam_steamsdk_TSteamUGC__OnWorkshopEULAStatus(BBObject * maxHandle, EResult result, uint32 appID, uint32 version, uint32 actionTime, int accepted, int needsAction, int failure);
	BBObject * steam_steamsdk_TSteamUGCDetails__Create(uint64 publishedFileId, EResult result, EWorkshopFileType fileType, uint32 creatorAppID, uint32 consumerAppID, BBString * title, BBString * description, uint64 steamIDOwner, uint32 timeCreated, uint32 timeUpdated, uint32 timeAddedToUserList, ERemoteStoragePublishedFileVisibility visibility, int banned, int acceptedForUse, int tagsTruncated, BBString * tags, uint64 fileHandle, uint64 previewFileHandle, BBString * fileName, int fileSize, int previewFileSize, BBString * url, uint32 votesUp, uint32 votesDown, float score, uint32 numChildren);

	void steam_steamsdk_TSteamFriends__OnAvatarImageLoaded( BBObject * maxHandle, uint64 steamID, int image, int width, int height);
	void steam_steamsdk_TSteamFriends__OnFriendRichPresenceUpdated( BBObject * maxHandle, uint64 steamIDFriend, uint32 appID);
	void steam_steamsdk_TSteamFriends__OnGameConnectedChatLeave( BBObject * maxHandle, uint64 steamIDClanChat, uint64 steamIDUser, int kicked, int dropped);
	void steam_steamsdk_TSteamFriends__OnGameConnectedFriendChatMsg( BBObject * maxHandle, uint64 steamIDUser, int messageID);
	void steam_steamsdk_TSteamFriends__OnGameLobbyJoinRequested( BBObject * maxHandle, uint64 steamIDLobby, uint64 steamIDFriend);
	void steam_steamsdk_TSteamFriends__OnGameOverlayActivated(BBObject * maxHandle, int active);
	void steam_steamsdk_TSteamFriends__OnGameRichPresenceJoinRequested( BBObject * maxHandle, uint64 steamIDFriend, BBString * connect);
	void steam_steamsdk_TSteamFriends__OnGameServerChangeRequested( BBObject * maxHandle, BBString * server, BBString * pass);
	void steam_steamsdk_TSteamFriends__OnPersonaStateChanged(BBObject * maxHandle, uint64 steamID, int changeFlags);
	void steam_steamsdk_TSteamFriends__OnClanOfficerList( BBObject * maxHandle, uint64 steamIDClan, int officers, int success);
	void steam_steamsdk_TSteamFriends__OnDownloadClanActivityCounts(BBObject * maxHandle, int success);
	void steam_steamsdk_TSteamFriends__OnFriendsEnumerateFollowingList( BBObject * maxHandle, EResult result, uint64 * steamIDs, int resultsReturned, int totalResultCount);
	void steam_steamsdk_TSteamFriends__OnFriendsGetFollowerCount( BBObject * maxHandle, EResult result, uint64 steamID, int count);
	void steam_steamsdk_TSteamFriends__OnFriendsIsFollowing( BBObject * maxHandle, EResult result, uint64 steamID, int isFollowing);
	void steam_steamsdk_TSteamFriends__OnGameConnectedChatJoined( BBObject * maxHandle, uint64 steamIDUser, uint64 steamIDClanChat);
	void steam_steamsdk_TSteamFriends__OnGameConnectedClanChatMsg( BBObject * maxHandle, uint64 steamIDUser, uint64 steamIDClanChat, int messageID);
	void steam_steamsdk_TSteamFriends__OnJoinClanChatRoomCompletion( BBObject * maxHandle, uint64 steamIDClanChat, EChatRoomEnterResponse chatRoomEnterResponse);
	void steam_steamsdk_TSteamFriends__OnEquippedProfileItemsChanged(BBObject * maxHandle, uint64 steamID);
	void steam_steamsdk_TSteamFriends__OnEquippedProfileItems(BBObject * maxHandle, EResult result, uint64 steamID, int animatedAvatar, int avatarFrame, int profileModifier, int profileBackground, int miniProfileBackground, int fromCache);

	void steam_steamsdk_TSteamMatchmaking__OnLobbyCreated( BBObject * maxHandle, EResult result, uint64 steamIDLobby, int failure);
	void steam_steamsdk_TSteamMatchmaking__OnLobbyMatchList(BBObject * maxHandle, uint32 lobbyCount, int failure);
	void steam_steamsdk_TSteamMatchmaking__OnLobbyEnter( BBObject * maxHandle, uint64 steamIDLobby, int locked, uint32 response);
	void steam_steamsdk_TSteamMatchmaking__OnLobbyDataUpdate( BBObject * maxHandle, uint64 steamIDLobby, uint64 steamIDMember, int success);
	void steam_steamsdk_TSteamMatchmaking__OnLobbyChatUpdate(BBObject * maxHandle, uint64 steamIDLobby, uint64 steamIDUserChanged, uint64 steamIDMakingChange, uint32 stateChange);
	void steam_steamsdk_TSteamMatchmaking__OnLobbyChatMessage( BBObject * maxHandle, uint64 steamIDLobby, uint64 steamIDUser, int chatEntryType, uint32 chatID);
	void steam_steamsdk_TSteamMatchmaking__OnLobbyGameCreated( BBObject * maxHandle, uint64 steamIDLobby, uint64 steamIDGameServer, uint32 ip, uint16 port);
	void steam_steamsdk_TSteamMatchmaking__OnLobbyInvite( BBObject * maxHandle, uint64 steamIDUser, uint64 steamIDLobby, uint64 gameID);
	void steam_steamsdk_TSteamMatchmaking__OnLobbyJoinRequested( BBObject * maxHandle, uint64 steamIDLobby, uint64 steamIDFriend);

	void steam_steamsdk_TSteamNetworkingMessages__OnSessionRequest(BBObject * maxHandle, uint64 steamIDRemote);
	void steam_steamsdk_TSteamNetworkingMessages__OnSessionFailed( BBObject * maxHandle, uint64 steamIDRemote, int state, int endReason, BBString * debugMessage);
	void steam_steamsdk_TSteamApps__OnDlcInstalled(BBObject * maxHandle, uint32 appID);
	void steam_steamsdk_TSteamApps__OnNewUrlLaunchParameters(BBObject * maxHandle);
	void steam_steamsdk_TSteamApps__OnAppProofOfPurchaseKey( BBObject * maxHandle, EResult result, uint32 appID, BBString * key);
	void steam_steamsdk_TSteamApps__OnTimedTrialStatus( BBObject * maxHandle, uint32 appID, int offline, uint32 secondsAllowed, uint32 secondsPlayed);
	void steam_steamsdk_TSteamApps__OnFileDetails( BBObject * maxHandle, EResult result, uint64 fileSize, BBString * sha1, uint32 flags, int failure);
	void steam_steamsdk_TSteamUser__OnValidateAuthTicket( BBObject * maxHandle, uint64 steamID, EAuthSessionResponse response, uint64 ownerSteamID);
	void steam_steamsdk_TSteamUser__OnGetAuthSessionTicket(BBObject * maxHandle, uint32 authTicket, EResult result);
	void steam_steamsdk_TSteamUser__OnGetTicketForWebApi(BBObject * maxHandle, uint32 authTicket, EResult result, void * ticket, int ticketSize);
	void steam_steamsdk_TSteamUser__OnEncryptedAppTicket(BBObject * maxHandle, EResult result, int failure);
	void steam_steamsdk_TSteamUser__OnStoreAuthURL(BBObject * maxHandle, BBString * url, int failure);
	void steam_steamsdk_TSteamUser__OnMarketEligibility(BBObject * maxHandle, int allowed, EMarketNotAllowedReasonFlags reason, uint32 allowedAtTime, int steamGuardRequiredDays, int newDeviceCooldown, int failure);
	void steam_steamsdk_TSteamUser__OnDurationControl(BBObject * maxHandle, EResult result, uint32 appID, int applicable, int secondsLast5h, EDurationControlProgress progress, EDurationControlNotification notification, int secondsToday, int secondsRemaining, int failure);
	void steam_steamsdk_TSteamRemoteStorage__OnLocalFileChange(BBObject * maxHandle);
	void steam_steamsdk_TSteamRemoteStorage__OnFileWriteAsyncComplete( BBObject * maxHandle, uint64 callHandle, EResult result, int failure);
	void steam_steamsdk_TSteamRemoteStorage__OnFileReadAsyncComplete( BBObject * maxHandle, uint64 callHandle, EResult result, uint32 offset, uint32 bytesRead, int failure);
	void steam_steamsdk_TSteamInput__OnDeviceConnected(BBObject * maxHandle, uint64 inputHandle);
	void steam_steamsdk_TSteamInput__OnDeviceDisconnected(BBObject * maxHandle, uint64 inputHandle);
	void steam_steamsdk_TSteamInput__OnConfigurationLoaded(BBObject * maxHandle, uint32 appID, uint64 inputHandle, uint64 mappingCreator, uint32 majorRevision, uint32 minorRevision, int usesSteamInputAPI, int usesGamepadAPI);
	void steam_steamsdk_TSteamInput__OnDigitalAction( BBObject * maxHandle, uint64 inputHandle, uint64 actionHandle, int state, int active);
	void steam_steamsdk_TSteamInput__OnAnalogAction( BBObject * maxHandle, uint64 inputHandle, uint64 actionHandle, EInputSourceMode mode, float x, float y, int active);
	void steam_steamsdk_TSteamTimeline__OnEventRecordingExists(BBObject * maxHandle, uint64 eventHandle, int recordingExists, int failure);
	void steam_steamsdk_TSteamTimeline__OnGamePhaseRecordingExists(BBObject * maxHandle, BBString * phaseID, uint64 recordingMS, uint64 longestClipMS, uint32 clipCount, uint32 screenshotCount, int failure);

	int bmx_SteamAPI_Init();
	void bmx_SteamAPI_Shutdown();
	void bmx_SteamAPI_startBackgroundTimer();
	void bmx_SteamAPI_stopBackgroundTimer();
	void bmx_SteamAPI_RunCallbacks();
	int bmx_SteamAPI_RestartAppIfNecessary(uint32 ownAppID);

	HSteamPipe bmx_SteamAPI_GetHSteamPipe();

	void * bmx_SteamAPI_SteamClient();

	void * bmx_steamsdk_register_steamutils(ISteamUtils * instancePtr, BBObject * obj);
	void bmx_steamsdk_unregister_steamutils(void * callbackPtr);

	void * bmx_SteamAPI_ISteamClient_GetISteamUtils(ISteamClient * instancePtr, HSteamPipe pipe);
	HSteamUser bmx_SteamAPI_ISteamClient_ConnectToGlobalUser(ISteamClient * instancePtr, HSteamPipe pipe);
	void * bmx_SteamAPI_ISteamClient_GetISteamUserStats(ISteamClient * instancePtr, HSteamUser user, HSteamPipe pipe);
	void * bmx_SteamAPI_ISteamClient_GetISteamUGC(ISteamClient * instancePtr, HSteamUser user, HSteamPipe pipe);
	void * bmx_SteamAPI_ISteamClient_GetISteamFriends(ISteamClient * instancePtr, HSteamUser user, HSteamPipe pipe);
	void * bmx_SteamAPI_ISteamClient_GetISteamUser(ISteamClient * instancePtr, HSteamUser user, HSteamPipe pipe);
	void * bmx_SteamAPI_ISteamClient_GetISteamMatchmaking(ISteamClient * instancePtr, HSteamUser user, HSteamPipe pipe);
	void * bmx_SteamAPI_ISteamClient_GetISteamApps(ISteamClient * instancePtr, HSteamUser user, HSteamPipe pipe);
	void * bmx_SteamAPI_ISteamClient_GetISteamRemoteStorage(ISteamClient * instancePtr, HSteamUser user, HSteamPipe pipe);
	void * bmx_SteamAPI_ISteamClient_GetISteamInput(ISteamClient * instancePtr, HSteamUser user, HSteamPipe pipe);
	void * bmx_SteamAPI_SteamTimeline();
	void * bmx_steamsdk_register_steaminput(ISteamInput * instancePtr, BBObject * obj);
	void bmx_steamsdk_unregister_steaminput(void * callbackPtr);
	int bmx_SteamAPI_ISteamInput_Init(ISteamInput * instancePtr, int explicitlyCallRunFrame);
	int bmx_SteamAPI_ISteamInput_Shutdown(ISteamInput * instancePtr);
	int bmx_SteamAPI_ISteamInput_SetInputActionManifestFilePath(ISteamInput * instancePtr, BBString * path);
	void bmx_SteamAPI_ISteamInput_RunFrame(ISteamInput * instancePtr);
	int bmx_SteamAPI_ISteamInput_BWaitForData(ISteamInput * instancePtr, int waitForever, uint32 timeout);
	int bmx_SteamAPI_ISteamInput_BNewDataAvailable(ISteamInput * instancePtr);
	int bmx_SteamAPI_ISteamInput_GetConnectedControllers(ISteamInput * instancePtr, uint64 * handles, int capacity);
	void bmx_SteamAPI_ISteamInput_EnableDeviceCallbacks(ISteamInput * instancePtr);
	void bmx_SteamAPI_ISteamInput_EnableActionEventCallbacks(MaxInput * input);
	uint64 bmx_SteamAPI_ISteamInput_GetActionSetHandle(ISteamInput * instancePtr, BBString * name);
	void bmx_SteamAPI_ISteamInput_ActivateActionSet(ISteamInput * instancePtr, uint64 inputHandle, uint64 actionSetHandle);
	uint64 bmx_SteamAPI_ISteamInput_GetCurrentActionSet(ISteamInput * instancePtr, uint64 inputHandle);
	void bmx_SteamAPI_ISteamInput_ActivateActionSetLayer( ISteamInput * instancePtr, uint64 inputHandle, uint64 actionSetLayerHandle);
	void bmx_SteamAPI_ISteamInput_DeactivateActionSetLayer( ISteamInput * instancePtr, uint64 inputHandle, uint64 actionSetLayerHandle);
	void bmx_SteamAPI_ISteamInput_DeactivateAllActionSetLayers(ISteamInput * instancePtr, uint64 inputHandle);
	int bmx_SteamAPI_ISteamInput_GetActiveActionSetLayers( ISteamInput * instancePtr, uint64 inputHandle, uint64 * handles, int capacity);
	uint64 bmx_SteamAPI_ISteamInput_GetDigitalActionHandle(ISteamInput * instancePtr, BBString * name);
	void bmx_SteamAPI_ISteamInput_GetDigitalActionData( ISteamInput * instancePtr, uint64 inputHandle, uint64 actionHandle, int * state, int * active);
	int bmx_SteamAPI_ISteamInput_GetDigitalActionOrigins(ISteamInput * instancePtr, uint64 inputHandle, uint64 actionSetHandle, uint64 actionHandle, int * origins, int capacity);
	BBString * bmx_SteamAPI_ISteamInput_GetStringForDigitalActionName(ISteamInput * instancePtr, uint64 actionHandle);
	uint64 bmx_SteamAPI_ISteamInput_GetAnalogActionHandle(ISteamInput * instancePtr, BBString * name);
	void bmx_SteamAPI_ISteamInput_GetAnalogActionData(ISteamInput * instancePtr, uint64 inputHandle, uint64 actionHandle, EInputSourceMode * mode, float * x, float * y, int * active);
	int bmx_SteamAPI_ISteamInput_GetAnalogActionOrigins(ISteamInput * instancePtr, uint64 inputHandle, uint64 actionSetHandle, uint64 actionHandle, int * origins, int capacity);
	BBString * bmx_SteamAPI_ISteamInput_GetGlyphPNGForActionOrigin( ISteamInput * instancePtr, EInputActionOrigin origin, ESteamInputGlyphSize size, uint32 flags);
	BBString * bmx_SteamAPI_ISteamInput_GetGlyphSVGForActionOrigin( ISteamInput * instancePtr, EInputActionOrigin origin, uint32 flags);
	BBString * bmx_SteamAPI_ISteamInput_GetStringForActionOrigin(ISteamInput * instancePtr, EInputActionOrigin origin);
	BBString * bmx_SteamAPI_ISteamInput_GetStringForAnalogActionName(ISteamInput * instancePtr, uint64 actionHandle);
	void bmx_SteamAPI_ISteamInput_StopAnalogActionMomentum( ISteamInput * instancePtr, uint64 inputHandle, uint64 actionHandle);
	void bmx_SteamAPI_ISteamInput_GetMotionData(ISteamInput * instancePtr, uint64 inputHandle, float * rotQuatX, float * rotQuatY, float * rotQuatZ, float * rotQuatW, float * posAccelX, float * posAccelY, float * posAccelZ, float * rotVelX, float * rotVelY, float * rotVelZ);
	void bmx_SteamAPI_ISteamInput_TriggerVibration( ISteamInput * instancePtr, uint64 inputHandle, int leftSpeed, int rightSpeed);
	void bmx_SteamAPI_ISteamInput_TriggerVibrationExtended(ISteamInput * instancePtr, uint64 inputHandle, int leftSpeed, int rightSpeed, int leftTriggerSpeed, int rightTriggerSpeed);
	void bmx_SteamAPI_ISteamInput_TriggerSimpleHapticEvent(ISteamInput * instancePtr, uint64 inputHandle, EControllerHapticLocation location, int intensity, int gainDB, int otherIntensity, int otherGainDB);
	void bmx_SteamAPI_ISteamInput_SetLEDColor( ISteamInput * instancePtr, uint64 inputHandle, int red, int green, int blue, uint32 flags);
	int bmx_SteamAPI_ISteamInput_ShowBindingPanel(ISteamInput * instancePtr, uint64 inputHandle);
	ESteamInputType bmx_SteamAPI_ISteamInput_GetInputTypeForHandle(ISteamInput * instancePtr, uint64 inputHandle);
	uint64 bmx_SteamAPI_ISteamInput_GetControllerForGamepadIndex(ISteamInput * instancePtr, int index);
	int bmx_SteamAPI_ISteamInput_GetGamepadIndexForController(ISteamInput * instancePtr, uint64 inputHandle);
	BBString * bmx_SteamAPI_ISteamInput_GetStringForXboxOrigin(ISteamInput * instancePtr, EXboxOrigin origin);
	BBString * bmx_SteamAPI_ISteamInput_GetGlyphForXboxOrigin(ISteamInput * instancePtr, EXboxOrigin origin);
	EInputActionOrigin bmx_SteamAPI_ISteamInput_GetActionOriginFromXboxOrigin( ISteamInput * instancePtr, uint64 inputHandle, EXboxOrigin origin);
	EInputActionOrigin bmx_SteamAPI_ISteamInput_TranslateActionOrigin( ISteamInput * instancePtr, ESteamInputType destinationType, EInputActionOrigin sourceOrigin);
	int bmx_SteamAPI_ISteamInput_GetDeviceBindingRevision( ISteamInput * instancePtr, uint64 inputHandle, int * major, int * minor);
	uint32 bmx_SteamAPI_ISteamInput_GetRemotePlaySessionID(ISteamInput * instancePtr, uint64 inputHandle);
	int bmx_SteamAPI_ISteamInput_GetSessionInputConfigurationSettings(ISteamInput * instancePtr);
	int bmx_SteamAPI_ISteamInput_SetDualSenseTriggerEffect(ISteamInput * instancePtr, uint64 inputHandle, int trigger, int mode, int first, int second, int third, int fourth, const uint8 * values, int count);
	void * bmx_steamsdk_register_steamtimeline(ISteamTimeline * instancePtr, BBObject * obj);
	void bmx_steamsdk_unregister_steamtimeline(void * callbackPtr);
	void bmx_SteamAPI_ISteamTimeline_SetTimelineTooltip(ISteamTimeline * instancePtr, BBString * description, float timeDelta);
	void bmx_SteamAPI_ISteamTimeline_ClearTimelineTooltip(ISteamTimeline * instancePtr, float timeDelta);
	void bmx_SteamAPI_ISteamTimeline_SetTimelineGameMode(ISteamTimeline * instancePtr, ETimelineGameMode mode);
	uint64 bmx_SteamAPI_ISteamTimeline_AddInstantaneousTimelineEvent(ISteamTimeline * instancePtr, BBString * title, BBString * description, BBString * icon, uint32 iconPriority, float startOffsetSeconds, ETimelineEventClipPriority clipPriority);
	uint64 bmx_SteamAPI_ISteamTimeline_AddRangeTimelineEvent(ISteamTimeline * instancePtr, BBString * title, BBString * description, BBString * icon, uint32 iconPriority, float startOffsetSeconds, float duration, ETimelineEventClipPriority clipPriority);
	uint64 bmx_SteamAPI_ISteamTimeline_StartRangeTimelineEvent(ISteamTimeline * instancePtr, BBString * title, BBString * description, BBString * icon, uint32 priority, float startOffsetSeconds, ETimelineEventClipPriority clipPriority);
	void bmx_SteamAPI_ISteamTimeline_UpdateRangeTimelineEvent(ISteamTimeline * instancePtr, uint64 eventHandle, BBString * title, BBString * description, BBString * icon, uint32 priority, ETimelineEventClipPriority clipPriority);
	void bmx_SteamAPI_ISteamTimeline_EndRangeTimelineEvent(ISteamTimeline * instancePtr, uint64 eventHandle, float endOffsetSeconds);
	void bmx_SteamAPI_ISteamTimeline_RemoveTimelineEvent(ISteamTimeline * instancePtr, uint64 eventHandle);
	uint64 bmx_SteamAPI_ISteamTimeline_DoesEventRecordingExist(MaxTimeline * timeline, uint64 eventHandle);
	void bmx_SteamAPI_ISteamTimeline_StartGamePhase(ISteamTimeline * instancePtr);
	void bmx_SteamAPI_ISteamTimeline_EndGamePhase(ISteamTimeline * instancePtr);
	void bmx_SteamAPI_ISteamTimeline_SetGamePhaseID(ISteamTimeline * instancePtr, BBString * phaseID);
	uint64 bmx_SteamAPI_ISteamTimeline_DoesGamePhaseRecordingExist(MaxTimeline * timeline, BBString * phaseID);
	void bmx_SteamAPI_ISteamTimeline_AddGamePhaseTag(ISteamTimeline * instancePtr, BBString * tagName, BBString * tagIcon, BBString * tagGroup, uint32 priority);
	void bmx_SteamAPI_ISteamTimeline_SetGamePhaseAttribute(ISteamTimeline * instancePtr, BBString * attributeGroup, BBString * attributeValue, uint32 priority);
	void bmx_SteamAPI_ISteamTimeline_OpenOverlayToGamePhase(ISteamTimeline * instancePtr, BBString * phaseID);
	void bmx_SteamAPI_ISteamTimeline_OpenOverlayToTimelineEvent(ISteamTimeline * instancePtr, uint64 eventHandle);
	void * bmx_steamsdk_register_steamremotestorage(ISteamRemoteStorage * instancePtr, BBObject * obj);
	void bmx_steamsdk_unregister_steamremotestorage(void * callbackPtr);
	int bmx_SteamAPI_ISteamRemoteStorage_FileWrite( ISteamRemoteStorage * instancePtr, BBString * file, const void * data, int size);
	int bmx_SteamAPI_ISteamRemoteStorage_FileRead( ISteamRemoteStorage * instancePtr, BBString * file, void * data, int capacity);
	uint64 bmx_SteamAPI_ISteamRemoteStorage_FileWriteAsync( MaxRemoteStorage * storage, BBString * file, const void * data, uint32 size);
	uint64 bmx_SteamAPI_ISteamRemoteStorage_FileReadAsync( MaxRemoteStorage * storage, BBString * file, uint32 offset, uint32 bytesToRead);
	int bmx_SteamAPI_ISteamRemoteStorage_FileReadAsyncComplete( ISteamRemoteStorage * instancePtr, uint64 readCall, void * data, uint32 bytesToRead);
	int bmx_SteamAPI_ISteamRemoteStorage_FileForget(ISteamRemoteStorage * instancePtr, BBString * file);
	int bmx_SteamAPI_ISteamRemoteStorage_FileDelete(ISteamRemoteStorage * instancePtr, BBString * file);
	int bmx_SteamAPI_ISteamRemoteStorage_SetSyncPlatforms( ISteamRemoteStorage * instancePtr, BBString * file, ERemoteStoragePlatform platforms);
	uint64 bmx_SteamAPI_ISteamRemoteStorage_FileWriteStreamOpen(ISteamRemoteStorage * instancePtr, BBString * file);
	int bmx_SteamAPI_ISteamRemoteStorage_FileWriteStreamWriteChunk( ISteamRemoteStorage * instancePtr, uint64 streamHandle, const void * data, int size);
	int bmx_SteamAPI_ISteamRemoteStorage_FileWriteStreamClose(ISteamRemoteStorage * instancePtr, uint64 streamHandle);
	int bmx_SteamAPI_ISteamRemoteStorage_FileWriteStreamCancel(ISteamRemoteStorage * instancePtr, uint64 streamHandle);
	int bmx_SteamAPI_ISteamRemoteStorage_FileExists(ISteamRemoteStorage * instancePtr, BBString * file);
	int bmx_SteamAPI_ISteamRemoteStorage_FilePersisted(ISteamRemoteStorage * instancePtr, BBString * file);
	int bmx_SteamAPI_ISteamRemoteStorage_GetFileSize(ISteamRemoteStorage * instancePtr, BBString * file);
	int64 bmx_SteamAPI_ISteamRemoteStorage_GetFileTimestamp(ISteamRemoteStorage * instancePtr, BBString * file);
	ERemoteStoragePlatform bmx_SteamAPI_ISteamRemoteStorage_GetSyncPlatforms( ISteamRemoteStorage * instancePtr, BBString * file);
	int bmx_SteamAPI_ISteamRemoteStorage_GetFileCount(ISteamRemoteStorage * instancePtr);
	BBString * bmx_SteamAPI_ISteamRemoteStorage_GetFileNameAndSize( ISteamRemoteStorage * instancePtr, int index, int * size);
	int bmx_SteamAPI_ISteamRemoteStorage_GetQuota( ISteamRemoteStorage * instancePtr, uint64 * totalBytes, uint64 * availableBytes);
	int bmx_SteamAPI_ISteamRemoteStorage_IsCloudEnabledForAccount(ISteamRemoteStorage * instancePtr);
	int bmx_SteamAPI_ISteamRemoteStorage_IsCloudEnabledForApp(ISteamRemoteStorage * instancePtr);
	void bmx_SteamAPI_ISteamRemoteStorage_SetCloudEnabledForApp(ISteamRemoteStorage * instancePtr, int enabled);
	int bmx_SteamAPI_ISteamRemoteStorage_GetLocalFileChangeCount(ISteamRemoteStorage * instancePtr);
	BBString * bmx_SteamAPI_ISteamRemoteStorage_GetLocalFileChange(ISteamRemoteStorage * instancePtr, int index, ERemoteStorageLocalFileChange * changeType, ERemoteStorageFilePathType * pathType);
	int bmx_SteamAPI_ISteamRemoteStorage_BeginFileWriteBatch(ISteamRemoteStorage * instancePtr);
	int bmx_SteamAPI_ISteamRemoteStorage_EndFileWriteBatch(ISteamRemoteStorage * instancePtr);
	int bmx_SteamAPI_ISteamUser_BLoggedOn(ISteamUser * instancePtr);
	uint64 bmx_SteamAPI_ISteamUser_GetSteamID(ISteamUser * instancePtr);
	void * bmx_steamsdk_register_steamuser(ISteamUser * instancePtr, BBObject * obj);
	void bmx_steamsdk_unregister_steamuser(void * callbackPtr);
	int bmx_SteamAPI_ISteamUser_GetHSteamUser(ISteamUser * instancePtr);
	int bmx_SteamAPI_ISteamUser_GetUserDataFolder(ISteamUser * instancePtr, BBString ** folder);
	void bmx_SteamAPI_ISteamUser_StartVoiceRecording(ISteamUser * instancePtr);
	void bmx_SteamAPI_ISteamUser_StopVoiceRecording(ISteamUser * instancePtr);
	EVoiceResult bmx_SteamAPI_ISteamUser_GetAvailableVoice(ISteamUser * instancePtr, uint32 * compressedBytes);
	EVoiceResult bmx_SteamAPI_ISteamUser_GetVoice( ISteamUser * instancePtr, void * destination, uint32 capacity, uint32 * bytesWritten);
	EVoiceResult bmx_SteamAPI_ISteamUser_DecompressVoice(ISteamUser * instancePtr, const void * compressed, uint32 compressedSize, void * destination, uint32 capacity, uint32 * bytesWritten, uint32 sampleRate);
	uint32 bmx_SteamAPI_ISteamUser_GetVoiceOptimalSampleRate(ISteamUser * instancePtr);
	uint32 bmx_SteamAPI_ISteamUser_GetAuthSessionTicket( ISteamUser * instancePtr, void * ticket, int capacity, uint32 * ticketSize);
	uint32 bmx_SteamAPI_ISteamUser_GetAuthTicketForWebApi(ISteamUser * instancePtr, BBString * identity);
	EBeginAuthSessionResult bmx_SteamAPI_ISteamUser_BeginAuthSession( ISteamUser * instancePtr, const void * ticket, int ticketSize, uint64 steamID);
	void bmx_SteamAPI_ISteamUser_EndAuthSession(ISteamUser * instancePtr, uint64 steamID);
	void bmx_SteamAPI_ISteamUser_CancelAuthTicket(ISteamUser * instancePtr, uint32 authTicket);
	EUserHasLicenseForAppResult bmx_SteamAPI_ISteamUser_UserHasLicenseForApp( ISteamUser * instancePtr, uint64 steamID, uint32 appID);
	int bmx_SteamAPI_ISteamUser_BIsBehindNAT(ISteamUser * instancePtr);
	void bmx_SteamAPI_ISteamUser_AdvertiseGame(ISteamUser * instancePtr, uint64 steamIDGameServer, uint32 ip, uint16 port);
	void bmx_SteamAPI_ISteamUser_TrackAppUsageEvent( ISteamUser * instancePtr, uint64 gameID, int appUsageEvent, BBString * extraInfo);
	void bmx_SteamAPI_ISteamUser_RequestEncryptedAppTicket(MaxUser * user, void * data, int size);
	int bmx_SteamAPI_ISteamUser_GetEncryptedAppTicket( ISteamUser * instancePtr, void * ticket, int capacity, uint32 * ticketSize);
	int bmx_SteamAPI_ISteamUser_GetGameBadgeLevel(ISteamUser * instancePtr, int series, int foil);
	int bmx_SteamAPI_ISteamUser_GetPlayerSteamLevel(ISteamUser * instancePtr);
	void bmx_SteamAPI_ISteamUser_RequestStoreAuthURL(MaxUser * user, BBString * redirectURL);
	int bmx_SteamAPI_ISteamUser_BIsPhoneVerified(ISteamUser * instancePtr);
	int bmx_SteamAPI_ISteamUser_BIsTwoFactorEnabled(ISteamUser * instancePtr);
	int bmx_SteamAPI_ISteamUser_BIsPhoneIdentifying(ISteamUser * instancePtr);
	int bmx_SteamAPI_ISteamUser_BIsPhoneRequiringVerification(ISteamUser * instancePtr);
	void bmx_SteamAPI_ISteamUser_GetMarketEligibility(MaxUser * user);
	void bmx_SteamAPI_ISteamUser_GetDurationControl(MaxUser * user);
	int bmx_SteamAPI_ISteamUser_BSetDurationControlOnlineState(ISteamUser * instancePtr, EDurationControlOnlineState state);
	BBString * bmx_SteamAPI_ISteamApps_GetLaunchCommandLine(ISteamApps * instancePtr);
	void * bmx_steamsdk_register_steamapps(ISteamApps * instancePtr, BBObject * obj);
	void bmx_steamsdk_unregister_steamapps(void * callbackPtr);
	int bmx_SteamAPI_ISteamApps_BIsSubscribed(ISteamApps * instancePtr);
	int bmx_SteamAPI_ISteamApps_BIsLowViolence(ISteamApps * instancePtr);
	int bmx_SteamAPI_ISteamApps_BIsCybercafe(ISteamApps * instancePtr);
	int bmx_SteamAPI_ISteamApps_BIsVACBanned(ISteamApps * instancePtr);
	BBString * bmx_SteamAPI_ISteamApps_GetCurrentGameLanguage(ISteamApps * instancePtr);
	BBString * bmx_SteamAPI_ISteamApps_GetAvailableGameLanguages(ISteamApps * instancePtr);
	int bmx_SteamAPI_ISteamApps_BIsSubscribedApp(ISteamApps * instancePtr, uint32 appID);
	int bmx_SteamAPI_ISteamApps_BIsDlcInstalled(ISteamApps * instancePtr, uint32 appID);
	uint32 bmx_SteamAPI_ISteamApps_GetEarliestPurchaseUnixTime(ISteamApps * instancePtr, uint32 appID);
	int bmx_SteamAPI_ISteamApps_BIsSubscribedFromFreeWeekend(ISteamApps * instancePtr);
	int bmx_SteamAPI_ISteamApps_GetDLCCount(ISteamApps * instancePtr);
	int bmx_SteamAPI_ISteamApps_BGetDLCDataByIndex( ISteamApps * instancePtr, int index, uint32 * appID, int * available, BBString ** name);
	void bmx_SteamAPI_ISteamApps_InstallDLC(ISteamApps * instancePtr, uint32 appID);
	void bmx_SteamAPI_ISteamApps_UninstallDLC(ISteamApps * instancePtr, uint32 appID);
	void bmx_SteamAPI_ISteamApps_RequestAppProofOfPurchaseKey(ISteamApps * instancePtr, uint32 appID);
	int bmx_SteamAPI_ISteamApps_GetCurrentBetaName(ISteamApps * instancePtr, BBString ** name);
	int bmx_SteamAPI_ISteamApps_MarkContentCorrupt(ISteamApps * instancePtr, int missingFilesOnly);
	uint32 bmx_SteamAPI_ISteamApps_GetInstalledDepots( ISteamApps * instancePtr, uint32 appID, uint32 * depots, uint32 maxDepots);
	uint32 bmx_SteamAPI_ISteamApps_GetAppInstallDir(ISteamApps * instancePtr, uint32 appID, BBString ** folder);
	int bmx_SteamAPI_ISteamApps_BIsAppInstalled(ISteamApps * instancePtr, uint32 appID);
	uint64 bmx_SteamAPI_ISteamApps_GetAppOwner(ISteamApps * instancePtr);
	BBString * bmx_SteamAPI_ISteamApps_GetLaunchQueryParam(ISteamApps * instancePtr, BBString * key);
	int bmx_SteamAPI_ISteamApps_GetDlcDownloadProgress( ISteamApps * instancePtr, uint32 appID, uint64 * downloaded, uint64 * total);
	int bmx_SteamAPI_ISteamApps_GetAppBuildId(ISteamApps * instancePtr);
	void bmx_SteamAPI_ISteamApps_RequestAllProofOfPurchaseKeys(ISteamApps * instancePtr);
	void bmx_SteamAPI_ISteamApps_GetFileDetails(MaxApps * apps, BBString * fileName);
	int bmx_SteamAPI_ISteamApps_BIsSubscribedFromFamilySharing(ISteamApps * instancePtr);
	int bmx_SteamAPI_ISteamApps_BIsTimedTrial(ISteamApps * instancePtr, uint32 * secondsAllowed, uint32 * secondsPlayed);
	int bmx_SteamAPI_ISteamApps_SetDlcContext(ISteamApps * instancePtr, uint32 appID);
	int bmx_SteamAPI_ISteamApps_GetNumBetas(ISteamApps * instancePtr, int * available, int * privateBetas);
	int bmx_SteamAPI_ISteamApps_GetBetaInfo(ISteamApps * instancePtr, int index, uint32 * flags, uint32 * buildID, BBString ** name, BBString ** description, uint32 * lastUpdated);
	int bmx_SteamAPI_ISteamApps_SetActiveBeta(ISteamApps * instancePtr, BBString * name);
	void bmx_SteamAPI_ISteamApps_SetGamePerformanceSetting(ISteamApps * instancePtr, EGamePerformanceSetting setting);
	void bmx_SteamAPI_ISteamApps_SetGameRenderResolution(ISteamApps * instancePtr, uint32 width, uint32 height);

	void * bmx_steamsdk_register_steammatchmaking(ISteamMatchmaking * instancePtr, BBObject * obj);
	void bmx_steamsdk_unregister_steammatchmaking(void * callbackPtr);
	int bmx_SteamAPI_ISteamMatchmaking_GetFavoriteGameCount(ISteamMatchmaking * instancePtr);
	int bmx_SteamAPI_ISteamMatchmaking_GetFavoriteGame(ISteamMatchmaking * instancePtr, int index, uint32 * appID, uint32 * ip, uint16 * connectionPort, uint16 * queryPort, uint32 * flags, uint32 * lastPlayed);
	int bmx_SteamAPI_ISteamMatchmaking_AddFavoriteGame(ISteamMatchmaking * instancePtr, uint32 appID, uint32 ip, uint16 connectionPort, uint16 queryPort, uint32 flags, uint32 lastPlayed);
	int bmx_SteamAPI_ISteamMatchmaking_RemoveFavoriteGame( ISteamMatchmaking * instancePtr, uint32 appID, uint32 ip, uint16 connectionPort, uint16 queryPort, uint32 flags);
	void bmx_SteamAPI_ISteamMatchmaking_AddRequestLobbyListStringFilter( ISteamMatchmaking * instancePtr, BBString * key, BBString * value, ELobbyComparison comparison);
	void bmx_SteamAPI_ISteamMatchmaking_AddRequestLobbyListNumericalFilter( ISteamMatchmaking * instancePtr, BBString * key, int value, ELobbyComparison comparison);
	void bmx_SteamAPI_ISteamMatchmaking_AddRequestLobbyListNearValueFilter( ISteamMatchmaking * instancePtr, BBString * key, int value);
	void bmx_SteamAPI_ISteamMatchmaking_AddRequestLobbyListResultCountFilter( ISteamMatchmaking * instancePtr, int maxResults);
	void bmx_SteamAPI_ISteamMatchmaking_AddRequestLobbyListFilterSlotsAvailable( ISteamMatchmaking * instancePtr, int slotsAvailable);
	void bmx_SteamAPI_ISteamMatchmaking_AddRequestLobbyListDistanceFilter( ISteamMatchmaking * instancePtr, ELobbyDistanceFilter distance);
	void bmx_SteamAPI_ISteamMatchmaking_AddRequestLobbyListCompatibleMembersFilter( ISteamMatchmaking * instancePtr, uint64 steamIDLobby);
	void bmx_SteamAPI_ISteamMatchmaking_RequestLobbyList(MaxMatchmaking * matchmaking);
	void bmx_SteamAPI_ISteamMatchmaking_CreateLobby(MaxMatchmaking * matchmaking, ELobbyType lobbyType, int maxMembers);
	void bmx_SteamAPI_ISteamMatchmaking_JoinLobby(ISteamMatchmaking * instancePtr, uint64 steamIDLobby);
	void bmx_SteamAPI_ISteamMatchmaking_LeaveLobby(ISteamMatchmaking * instancePtr, uint64 steamIDLobby);
	uint64 bmx_SteamAPI_ISteamMatchmaking_GetLobbyByIndex(ISteamMatchmaking * instancePtr, int index);
	int bmx_SteamAPI_ISteamMatchmaking_GetNumLobbyMembers(ISteamMatchmaking * instancePtr, uint64 steamIDLobby);
	uint64 bmx_SteamAPI_ISteamMatchmaking_GetLobbyMemberByIndex( ISteamMatchmaking * instancePtr, uint64 steamIDLobby, int member);
	BBString * bmx_SteamAPI_ISteamMatchmaking_GetLobbyData( ISteamMatchmaking * instancePtr, uint64 steamIDLobby, BBString * key);
	int bmx_SteamAPI_ISteamMatchmaking_SetLobbyData( ISteamMatchmaking * instancePtr, uint64 steamIDLobby, BBString * key, BBString * value);
	int bmx_SteamAPI_ISteamMatchmaking_GetLobbyDataCount(ISteamMatchmaking * instancePtr, uint64 steamIDLobby);
	int bmx_SteamAPI_ISteamMatchmaking_GetLobbyDataByIndex( ISteamMatchmaking * instancePtr, uint64 steamIDLobby, int index, BBString ** key, BBString ** value);
	int bmx_SteamAPI_ISteamMatchmaking_DeleteLobbyData( ISteamMatchmaking * instancePtr, uint64 steamIDLobby, BBString * key);
	BBString * bmx_SteamAPI_ISteamMatchmaking_GetLobbyMemberData( ISteamMatchmaking * instancePtr, uint64 steamIDLobby, uint64 steamIDUser, BBString * key);
	void bmx_SteamAPI_ISteamMatchmaking_SetLobbyMemberData( ISteamMatchmaking * instancePtr, uint64 steamIDLobby, BBString * key, BBString * value);
	int bmx_SteamAPI_ISteamMatchmaking_SendLobbyChatMsg( ISteamMatchmaking * instancePtr, uint64 steamIDLobby, void * data, int size);
	int bmx_SteamAPI_ISteamMatchmaking_GetLobbyChatEntry(ISteamMatchmaking * instancePtr, uint64 steamIDLobby, int chatId, uint64 * steamIDUser, void * data, int capacity, EChatEntryType * chatEntryType);
	int bmx_SteamAPI_ISteamMatchmaking_RequestLobbyData(ISteamMatchmaking * instancePtr, uint64 steamIDLobby);
	void bmx_SteamAPI_ISteamMatchmaking_SetLobbyGameServer( ISteamMatchmaking * instancePtr, uint64 steamIDLobby, uint32 ip, uint16 port, uint64 steamIDGameServer);
	int bmx_SteamAPI_ISteamMatchmaking_GetLobbyGameServer( ISteamMatchmaking * instancePtr, uint64 steamIDLobby, uint32 * ip, uint16 * port, uint64 * steamIDGameServer);
	int bmx_SteamAPI_ISteamMatchmaking_SetLobbyMemberLimit( ISteamMatchmaking * instancePtr, uint64 steamIDLobby, int maxMembers);
	int bmx_SteamAPI_ISteamMatchmaking_GetLobbyMemberLimit(ISteamMatchmaking * instancePtr, uint64 steamIDLobby);
	int bmx_SteamAPI_ISteamMatchmaking_SetLobbyType( ISteamMatchmaking * instancePtr, uint64 steamIDLobby, ELobbyType lobbyType);
	int bmx_SteamAPI_ISteamMatchmaking_SetLobbyJoinable(ISteamMatchmaking * instancePtr, uint64 steamIDLobby, int joinable);
	uint64 bmx_SteamAPI_ISteamMatchmaking_GetLobbyOwner(ISteamMatchmaking * instancePtr, uint64 steamIDLobby);
	int bmx_SteamAPI_ISteamMatchmaking_SetLobbyOwner( ISteamMatchmaking * instancePtr, uint64 steamIDLobby, uint64 steamIDNewOwner);
	int bmx_SteamAPI_ISteamMatchmaking_SetLinkedLobby( ISteamMatchmaking * instancePtr, uint64 steamIDLobby, uint64 steamIDLobbyDependent);
	int bmx_SteamAPI_ISteamMatchmaking_InviteUserToLobby( ISteamMatchmaking * instancePtr, uint64 steamIDLobby, uint64 steamIDInvitee);

	void * bmx_SteamAPI_SteamNetworkingMessages();
	void * bmx_steamsdk_register_steamnetworkingmessages(ISteamNetworkingMessages * instancePtr, BBObject * obj);
	void bmx_steamsdk_unregister_steamnetworkingmessages(void * callbackPtr);
	EResult bmx_SteamAPI_ISteamNetworkingMessages_SendMessageToUser(ISteamNetworkingMessages * instancePtr, uint64 steamIDRemote, void * data, uint32 size, int sendFlags, int remoteChannel);
	int bmx_SteamAPI_ISteamNetworkingMessages_ReceiveMessage(ISteamNetworkingMessages * instancePtr, int localChannel, void * data, uint32 capacity, uint32 * size, uint64 * steamIDRemote, int * reliable);
	int bmx_SteamAPI_ISteamNetworkingMessages_AcceptSessionWithUser( ISteamNetworkingMessages * instancePtr, uint64 steamIDRemote);
	int bmx_SteamAPI_ISteamNetworkingMessages_CloseSessionWithUser( ISteamNetworkingMessages * instancePtr, uint64 steamIDRemote);
	int bmx_SteamAPI_ISteamNetworkingMessages_CloseChannelWithUser( ISteamNetworkingMessages * instancePtr, uint64 steamIDRemote, int localChannel);
	ESteamNetworkingConnectionState bmx_SteamAPI_ISteamNetworkingMessages_GetSessionConnectionInfo( ISteamNetworkingMessages * instancePtr, uint64 steamIDRemote, int * endReason, BBString ** endDebug, int * ping, float * qualityLocal, float * qualityRemote, int * pendingUnreliable, int * pendingReliable, int * sentUnackedReliable, int64 * queueTimeMicroseconds);

	uint32 bmx_SteamAPI_ISteamUtils_GetSecondsSinceAppActive(ISteamUtils * instancePtr);
	uint32 bmx_SteamAPI_ISteamUtils_GetSecondsSinceComputerActive(ISteamUtils * instancePtr);
	uint32 bmx_SteamAPI_ISteamUtils_GetServerRealTime(ISteamUtils * instancePtr);
	BBString * bmx_SteamAPI_ISteamUtils_GetIPCountry(ISteamUtils * instancePtr);
	uint32 bmx_SteamAPI_ISteamUtils_GetAppID(ISteamUtils * instancePtr);
	int bmx_SteamAPI_ISteamUtils_IsOverlayEnabled(ISteamUtils * instancePtr);
	int bmx_SteamAPI_ISteamUtils_IsSteamInBigPictureMode(ISteamUtils * instancePtr);
	int bmx_SteamAPI_ISteamUtils_IsSteamRunningInVR(ISteamUtils * instancePtr);
	int bmx_SteamAPI_ISteamUtils_IsVRHeadsetStreamingEnabled(ISteamUtils * instancePtr);
	void bmx_SteamAPI_ISteamUtils_SetOverlayNotificationInset( ISteamUtils * instancePtr, int horizontalInset, int verticalInset);
	void bmx_SteamAPI_ISteamUtils_SetOverlayNotificationPosition(ISteamUtils * instancePtr, ENotificationPosition position);
	void bmx_SteamAPI_ISteamUtils_SetVRHeadsetStreamingEnabled(ISteamUtils * instancePtr, int enabled);
	void bmx_SteamAPI_ISteamUtils_StartVRDashboard(ISteamUtils * instancePtr);
	int bmx_SteamAPI_ISteamUtils_BOverlayNeedsPresent(ISteamUtils * instancePtr);
	int bmx_SteamAPI_ISteamUtils_GetCurrentBatteryPower(ISteamUtils * instancePtr);
	int bmx_SteamAPI_ISteamUtils_GetEnteredGamepadTextInput(ISteamUtils * instancePtr, BBString ** txt);
	int bmx_SteamAPI_ISteamUtils_GetImageRGBA(ISteamUtils * instancePtr, int image, uint8 * dest, int destBufferSize);
	int bmx_SteamAPI_ISteamUtils_GetImageSize(ISteamUtils * instancePtr, int image, uint32 * width, uint32 * height);
	uint32 bmx_SteamAPI_ISteamUtils_GetEnteredGamepadTextLength(ISteamUtils * instancePtr);
	BBString * bmx_SteamAPI_ISteamUtils_GetSteamUILanguage(ISteamUtils * instancePtr);
	int bmx_SteamAPI_ISteamUtils_ShowGamepadTextInput(ISteamUtils * instancePtr, EGamepadTextInputMode inputMode, EGamepadTextInputLineMode lineInputMode, BBString * description, uint32 charMax, BBString * existingText);
	void bmx_SteamAPI_ISteamUtils_CheckFileSignature(ISteamUtils * instancePtr, BBString * fileName);
	int bmx_SteamAPI_ISteamUtils_IsSteamChinaLauncher(ISteamUtils * instancePtr);
	int bmx_SteamAPI_ISteamUtils_InitFilterText(ISteamUtils * instancePtr, uint32 filterOptions);
	int bmx_SteamAPI_ISteamUtils_FilterText(ISteamUtils * instancePtr, ETextFilteringContext context, uint64 sourceSteamID, BBString * input, BBString ** output);
	ESteamIPv6ConnectivityState bmx_SteamAPI_ISteamUtils_GetIPv6ConnectivityState( ISteamUtils * instancePtr, ESteamIPv6ConnectivityProtocol protocol);
	ESteamHardwareType bmx_SteamAPI_ISteamUtils_IsRunningOnSteamHardware(ISteamUtils * instancePtr);
	ESteamHardwareDefaultConfig bmx_SteamAPI_ISteamUtils_GetSteamHardwareDefaultConfig(ISteamUtils * instancePtr);
	int bmx_SteamAPI_ISteamUtils_IsRunningUnderProton(ISteamUtils * instancePtr);
	int bmx_SteamAPI_ISteamUtils_ShowFloatingGamepadTextInput( ISteamUtils * instancePtr, EFloatingGamepadTextInputMode keyboardMode, int x, int y, int width, int height);
	int bmx_SteamAPI_ISteamUtils_DismissFloatingGamepadTextInput(ISteamUtils * instancePtr);
	int bmx_SteamAPI_ISteamUtils_DismissGamepadTextInput(ISteamUtils * instancePtr);
	void bmx_SteamAPI_ISteamUtils_SetGameLauncherMode(ISteamUtils * instancePtr, int launcherMode);
	EUniverse bmx_SteamAPI_ISteamUtils_GetConnectedUniverse(ISteamUtils * instancePtr);
	uint32 bmx_SteamAPI_ISteamUtils_GetIPCCallCount(ISteamUtils * instancePtr);

	void * bmx_steamsdk_register_steamuserstats(ISteamUserStats * instancePtr, BBObject * obj);
	void bmx_steamsdk_unregister_steamuserstats(void * callbackPtr);

	void bmx_SteamAPI_ISteamUserStats_GetNumberOfCurrentPlayers(MaxUserStats * userStats);
	int bmx_SteamAPI_ISteamUserStats_GetMostAchievedAchievementInfo( ISteamUserStats * instancePtr, BBString ** name, float * percent, int * achieved);
	int bmx_SteamAPI_ISteamUserStats_GetNextMostAchievedAchievementInfo( ISteamUserStats * instancePtr, int previous, BBString ** name, float * percent, int * achieved);
	uint32 bmx_SteamAPI_ISteamUserStats_GetNumAchievements(ISteamUserStats * instancePtr);
	int bmx_SteamAPI_ISteamUserStats_ClearAchievement(ISteamUserStats * instancePtr, BBString * name);
	void bmx_SteamAPI_ISteamUserStats_DownloadLeaderboardEntries(MaxUserStats * userStats, uint64 leaderboardHandle, ELeaderboardDataRequest leaderboardDataRequest, int rangeStart, int rangeEnd);
	void bmx_SteamAPI_ISteamUserStats_DownloadLeaderboardEntriesForUsers( MaxUserStats * userStats, uint64 leaderboardHandle, uint64 * users, int count);
	void bmx_SteamAPI_ISteamUserStats_FindLeaderboard(MaxUserStats * userStats, BBString * leaderboardName);
	void bmx_SteamAPI_ISteamUserStats_FindOrCreateLeaderboard(MaxUserStats * userStats, BBString * leaderboardName, ELeaderboardSortMethod sortMethod, ELeaderboardDisplayType displayType);
	int bmx_SteamAPI_ISteamUserStats_GetAchievement(ISteamUserStats * instancePtr, BBString * name, int * achieved);
	int bmx_SteamAPI_ISteamUserStats_GetAchievementAchievedPercent( ISteamUserStats * instancePtr, BBString * name, float * percent);
	int bmx_SteamAPI_ISteamUserStats_GetAchievementAndUnlockTime( ISteamUserStats * instancePtr, BBString * name, int * achieved, uint32 * unlockTime);
	BBString * bmx_SteamAPI_ISteamUserStats_GetAchievementDisplayAttribute( ISteamUserStats * instancePtr, BBString * name, BBString * key);
	int bmx_SteamAPI_ISteamUserStats_GetAchievementIcon(ISteamUserStats * instancePtr, BBString * name);
	BBString * bmx_SteamAPI_ISteamUserStats_GetAchievementName(ISteamUserStats * instancePtr, uint32 achievement);
	int bmx_SteamAPI_ISteamUserStats_GetGlobalStatInt64(ISteamUserStats * instancePtr, BBString * statName, int64 * data);
	int bmx_SteamAPI_ISteamUserStats_GetGlobalStatDouble(ISteamUserStats * instancePtr, BBString * statName, double * data);
	int bmx_SteamAPI_ISteamUserStats_GetGlobalStatHistoryInt64( ISteamUserStats * instancePtr, BBString * statName, int64 * data, uint32 count);
	int bmx_SteamAPI_ISteamUserStats_GetGlobalStatHistoryDouble( ISteamUserStats * instancePtr, BBString * statName, double * data, uint32 count);
	ELeaderboardDisplayType bmx_SteamAPI_ISteamUserStats_GetLeaderboardDisplayType( ISteamUserStats * instancePtr, uint64 leaderboardHandle);
	int bmx_SteamAPI_ISteamUserStats_GetLeaderboardEntryCount(ISteamUserStats * instancePtr, uint64 leaderboardHandle);
	BBString * bmx_SteamAPI_ISteamUserStats_GetLeaderboardName(ISteamUserStats * instancePtr, uint64 leaderboardHandle);
	ELeaderboardSortMethod bmx_SteamAPI_ISteamUserStats_GetLeaderboardSortMethod( ISteamUserStats * instancePtr, uint64 leaderboardHandle);
	int bmx_SteamAPI_ISteamUserStats_GetStatInt32(ISteamUserStats * instancePtr, BBString * name, int * data);
	int bmx_SteamAPI_ISteamUserStats_GetStatFloat(ISteamUserStats * instancePtr, BBString * name, float * data);
	int bmx_SteamAPI_ISteamUserStats_GetUserAchievement( ISteamUserStats * instancePtr, uint64 steamID, BBString * name, int * achieved);
	int bmx_SteamAPI_ISteamUserStats_GetUserAchievementAndUnlockTime( ISteamUserStats * instancePtr, uint64 steamID, BBString * name, int * achieved, uint32 * unlockTime);
	int bmx_SteamAPI_ISteamUserStats_GetUserStatInt32( ISteamUserStats * instancePtr, uint64 steamID, BBString * name, int * data);
	int bmx_SteamAPI_ISteamUserStats_GetUserStatFloat( ISteamUserStats * instancePtr, uint64 steamID, BBString * name, float * data);
	int bmx_SteamAPI_ISteamUserStats_IndicateAchievementProgress( ISteamUserStats * instancePtr, BBString * name, uint32 curProgress, uint32 maxProgress);
	void bmx_SteamAPI_ISteamUserStats_RequestGlobalAchievementPercentages(MaxUserStats * userStats);
	void bmx_SteamAPI_ISteamUserStats_RequestGlobalStats(MaxUserStats * userStats, int historyDays);
	void bmx_SteamAPI_ISteamUserStats_RequestUserStats(MaxUserStats * userStats, uint64 steamID);
	int bmx_SteamAPI_ISteamUserStats_GetAchievementProgressLimitsInt32( ISteamUserStats * instancePtr, BBString * name, int32 * minimum, int32 * maximum);
	int bmx_SteamAPI_ISteamUserStats_GetAchievementProgressLimitsFloat( ISteamUserStats * instancePtr, BBString * name, float * minimum, float * maximum);
	int bmx_SteamAPI_ISteamUserStats_GetDownloadedLeaderboardEntry(ISteamUserStats * instancePtr, uint64 entriesHandle, int index, uint64 * steamID, int * globalRank, int * score, int * details, int detailsCapacity, int * detailsCount, uint64 * ugcHandle);
	void bmx_SteamAPI_ISteamUserStats_AttachLeaderboardUGC( MaxUserStats * userStats, uint64 leaderboardHandle, uint64 ugcHandle);
	int bmx_SteamAPI_ISteamUserStats_ResetAllStats(ISteamUserStats * instancePtr, int achievementsToo);
	int bmx_SteamAPI_ISteamUserStats_SetAchievement(ISteamUserStats * instancePtr, BBString * name);
	int bmx_SteamAPI_ISteamUserStats_SetStatInt32(ISteamUserStats * instancePtr, BBString * name, int data);
	int bmx_SteamAPI_ISteamUserStats_SetStatFloat(ISteamUserStats * instancePtr, BBString * name, float data);
	int bmx_SteamAPI_ISteamUserStats_StoreStats(ISteamUserStats * instancePtr);
	int bmx_SteamAPI_ISteamUserStats_UpdateAvgRateStat( ISteamUserStats * instancePtr, BBString * name, float countThisSession, double sessionLength);
	void bmx_SteamAPI_ISteamUserStats_UploadLeaderboardScore(MaxUserStats * userStats, uint64 leaderboardHandle, ELeaderboardUploadScoreMethod uploadScoreMethod, int score, int * scoreDetails, int count);

	void * bmx_steamsdk_register_steamugc(ISteamUGC * instancePtr, BBObject * obj);
	void bmx_steamsdk_unregister_steamugc(void * callbackPtr);

	void bmx_SteamAPI_ISteamUGC_AddAppDependency(MaxUGC * ugc, uint64 publishedFileID, uint32 appID);
	void bmx_SteamAPI_ISteamUGC_AddDependency(MaxUGC * ugc, uint64 publishedFileId, uint64 childPublishedFileId);
	int bmx_SteamAPI_ISteamUGC_AddExcludedTag(ISteamUGC * instancePtr, uint64 queryHandle, BBString * tagName);
	int bmx_SteamAPI_ISteamUGC_AddItemKeyValueTag( ISteamUGC * instancePtr, uint64 queryHandle, BBString * key, BBString * value);
	int bmx_SteamAPI_ISteamUGC_AddItemPreviewFile( ISteamUGC * instancePtr, uint64 queryHandle, BBString * previewFile, EItemPreviewType previewType);
	int bmx_SteamAPI_ISteamUGC_AddItemPreviewVideo(ISteamUGC * instancePtr, uint64 queryHandle, BBString * videoID);
	void bmx_SteamAPI_ISteamUGC_AddItemToFavorites(MaxUGC * ugc, uint32 appId, uint64 publishedFileID);
	int bmx_SteamAPI_ISteamUGC_AddRequiredKeyValueTag( ISteamUGC * instancePtr, uint64 queryHandle, BBString * key, BBString * value);
	int bmx_SteamAPI_ISteamUGC_AddRequiredTag(ISteamUGC * instancePtr, uint64 queryHandle, BBString * tagName);
	int bmx_SteamAPI_ISteamUGC_InitWorkshopForGameServer( ISteamUGC * instancePtr, uint64 workshopDepotID, BBString * folder);
	void bmx_SteamAPI_ISteamUGC_CreateItem(MaxUGC * ugc, uint32 consumerAppId, EWorkshopFileType fileType);
	uint64 bmx_SteamAPI_ISteamUGC_CreateQueryAllUGCRequestPage(ISteamUGC * instancePtr, EUGCQuery queryType, EUGCMatchingUGCType matchingeMatchingUGCTypeFileType, uint32 creatorAppID, uint32 consumerAppID, uint32 page);
	uint64 bmx_SteamAPI_ISteamUGC_CreateQueryAllUGCRequestCursor(ISteamUGC * instancePtr, EUGCQuery queryType, EUGCMatchingUGCType matchingUGCType, uint32 creatorAppID, uint32 consumerAppID, BBString * cursor);
	BBObject * bmx_SteamAPI_ISteamUGC_GetQueryUGCResult(ISteamUGC * instancePtr, uint64 queryHandle, uint32 index);
	uint32 bmx_SteamAPI_ISteamUGC_GetQueryUGCNumTags(ISteamUGC * instancePtr, uint64 queryHandle, uint32 index);
	int bmx_SteamAPI_ISteamUGC_GetQueryUGCTag( ISteamUGC * instancePtr, uint64 queryHandle, uint32 index, uint32 tagIndex, BBString ** value);
	int bmx_SteamAPI_ISteamUGC_GetQueryUGCTagDisplayName( ISteamUGC * instancePtr, uint64 queryHandle, uint32 index, uint32 tagIndex, BBString ** value);
	int bmx_SteamAPI_ISteamUGC_GetQueryUGCKeyValueTagByKey( ISteamUGC * instancePtr, uint64 queryHandle, uint32 index, BBString * key, BBString ** value);
	int bmx_SteamAPI_ISteamUGC_AddRequiredTagGroup(ISteamUGC * instancePtr, uint64 queryHandle, BBArray * tags);
	int bmx_SteamAPI_ISteamUGC_SetTimeCreatedDateRange( ISteamUGC * instancePtr, uint64 queryHandle, uint32 startTime, uint32 endTime);
	int bmx_SteamAPI_ISteamUGC_SetTimeUpdatedDateRange( ISteamUGC * instancePtr, uint64 queryHandle, uint32 startTime, uint32 endTime);
	int bmx_SteamAPI_ISteamUGC_SetAllowLegacyUpload(ISteamUGC * instancePtr, uint64 updateHandle, int allowLegacyUpload);
	int bmx_SteamAPI_ISteamUGC_RemoveAllItemKeyValueTags(ISteamUGC * instancePtr, uint64 updateHandle);
	int bmx_SteamAPI_ISteamUGC_ShowWorkshopEULA(ISteamUGC * instancePtr);
	void bmx_SteamAPI_ISteamUGC_GetWorkshopEULAStatus(MaxUGC * ugc);
	uint64 bmx_SteamAPI_ISteamUGC_CreateQueryUGCDetailsRequest( ISteamUGC * instancePtr, uint64 * publishedFileIDs, int numPublishedFileIDs);
	uint64 bmx_SteamAPI_ISteamUGC_CreateQueryUserUGCRequest(ISteamUGC * instancePtr, uint32 accountID, EUserUGCList listType, EUGCMatchingUGCType matchingUGCType, EUserUGCListSortOrder sortOrder, uint32 creatorAppID, uint32 consumerAppID, uint32 page);
	void bmx_SteamAPI_ISteamUGC_DeleteItem(MaxUGC * ugc, uint64 publishedFileID);
	int bmx_SteamAPI_ISteamUGC_DownloadItem(ISteamUGC * instancePtr, uint64 publishedFileID, int highPriority);
	void bmx_SteamAPI_ISteamUGC_GetAppDependencies(MaxUGC * ugc, uint64 publishedFileID);
	int bmx_SteamAPI_ISteamUGC_GetItemDownloadInfo( ISteamUGC * instancePtr, uint64 publishedFileID, uint64 * bytesDownloaded, uint64 * bytesTotal);
	int bmx_SteamAPI_ISteamUGC_GetItemInstallInfo( ISteamUGC * instancePtr, uint64 publishedFileID, uint64 * sizeOnDisk, BBString ** folder, uint32 * timestamp);
	uint32 bmx_SteamAPI_ISteamUGC_GetItemState(ISteamUGC * instancePtr, uint64 publishedFileID);
	EItemUpdateStatus bmx_SteamAPI_ISteamUGC_GetItemUpdateProgress( ISteamUGC * instancePtr, uint64 queryHandle, uint64 * bytesProcessed, uint64 * bytesTotal);
	uint32 bmx_SteamAPI_ISteamUGC_GetNumSubscribedItems(ISteamUGC * instancePtr, int includeLocallyDisabled);
	int bmx_SteamAPI_ISteamUGC_GetQueryUGCAdditionalPreview(ISteamUGC * instancePtr, uint64 queryHandle, uint32 index, uint32 previewIndex, BBString ** URLOrVideoID, BBString ** originalFileName, EItemPreviewType * previewType);
	int bmx_SteamAPI_ISteamUGC_GetQueryUGCChildren( ISteamUGC * instancePtr, uint64 queryHandle, uint32 index, uint64 * publishedFileIDs, uint32 maxEntries);
	int bmx_SteamAPI_ISteamUGC_GetQueryUGCKeyValueTag(ISteamUGC * instancePtr, uint64 queryHandle, uint32 index, uint32 keyValueTagIndex, BBString ** key, BBString ** value);
	int bmx_SteamAPI_ISteamUGC_GetQueryUGCMetadata( ISteamUGC * instancePtr, uint64 queryHandle, uint32 index, BBString ** metadata);
	uint32 bmx_SteamAPI_ISteamUGC_GetQueryUGCNumAdditionalPreviews( ISteamUGC * instancePtr, uint64 queryHandle, uint32 index);
	uint32 bmx_SteamAPI_ISteamUGC_GetQueryUGCNumKeyValueTags(ISteamUGC * instancePtr, uint64 queryHandle, uint32 index);
	int bmx_SteamAPI_ISteamUGC_GetQueryUGCPreviewURL( ISteamUGC * instancePtr, uint64 queryHandle, uint32 index, BBString ** URL);
	int bmx_SteamAPI_ISteamUGC_GetQueryUGCStatistic( ISteamUGC * instancePtr, uint64 queryHandle, uint32 index, EItemStatistic statType, uint64 * statValue);
	uint32 bmx_SteamAPI_ISteamUGC_GetSubscribedItems(ISteamUGC * instancePtr, uint64 * publishedFileIDs, uint32 maxEntries, int includeLocallyDisabled);
	uint32 bmx_SteamAPI_ISteamUGC_GetNumSupportedGameVersions(ISteamUGC * instancePtr, uint64 queryHandle, uint32 index);
	int bmx_SteamAPI_ISteamUGC_GetSupportedGameVersionData(ISteamUGC * instancePtr, uint64 queryHandle, uint32 index, uint32 versionIndex, BBString ** minimum, BBString ** maximum);
	uint32 bmx_SteamAPI_ISteamUGC_GetQueryUGCContentDescriptors(ISteamUGC * instancePtr, uint64 queryHandle, uint32 index, EUGCContentDescriptorID * descriptors, uint32 maxEntries);
	int bmx_SteamAPI_ISteamUGC_SetAdminQuery(ISteamUGC * instancePtr, uint64 queryHandle, int adminQuery);
	int bmx_SteamAPI_ISteamUGC_AddContentDescriptor(ISteamUGC * instancePtr, uint64 updateHandle, EUGCContentDescriptorID descriptor);
	int bmx_SteamAPI_ISteamUGC_RemoveContentDescriptor(ISteamUGC * instancePtr, uint64 updateHandle, EUGCContentDescriptorID descriptor);
	int bmx_SteamAPI_ISteamUGC_SetRequiredGameVersions(ISteamUGC * instancePtr, uint64 updateHandle, BBString * minimum, BBString * maximum);
	uint32 bmx_SteamAPI_ISteamUGC_GetUserContentDescriptorPreferences(ISteamUGC * instancePtr, EUGCContentDescriptorID * descriptors, uint32 maxEntries);
	int bmx_SteamAPI_ISteamUGC_SetItemsDisabledLocally(ISteamUGC * instancePtr, uint64 * publishedFileIDs, uint32 count, int disabled);
	int bmx_SteamAPI_ISteamUGC_SetSubscriptionsLoadOrder(ISteamUGC * instancePtr, uint64 * publishedFileIDs, uint32 count);
	int bmx_SteamAPI_ISteamUGC_MarkDownloadedItemAsUnused(ISteamUGC * instancePtr, uint64 publishedFileID);
	uint32 bmx_SteamAPI_ISteamUGC_GetNumDownloadedItems(ISteamUGC * instancePtr);
	uint32 bmx_SteamAPI_ISteamUGC_GetDownloadedItems(ISteamUGC * instancePtr, uint64 * publishedFileIDs, uint32 maxEntries);
	void bmx_SteamAPI_ISteamUGC_GetUserItemVote(MaxUGC * ugc, uint64 publishedFileID);
	int bmx_SteamAPI_ISteamUGC_ReleaseQueryUGCRequest(ISteamUGC * instancePtr, uint64 queryHandle);
	void bmx_SteamAPI_ISteamUGC_RemoveAppDependency(MaxUGC * ugc, uint64 publishedFileID, uint32 appID);
	void bmx_SteamAPI_ISteamUGC_RemoveDependency(MaxUGC * ugc, uint64 parentPublishedFileID, uint64 childPublishedFileID);
	void bmx_SteamAPI_ISteamUGC_RemoveItemFromFavorites(MaxUGC * ugc, uint32 appId, uint64 publishedFileID);
	int bmx_SteamAPI_ISteamUGC_RemoveItemKeyValueTags(ISteamUGC * instancePtr, uint64 queryHandle, BBString * key);
	int bmx_SteamAPI_ISteamUGC_RemoveItemPreview(ISteamUGC * instancePtr, uint64 queryHandle, uint32 index);
	void bmx_SteamAPI_ISteamUGC_SendQueryUGCRequest(MaxUGC * ugc, uint64 queryHandle);
	int bmx_SteamAPI_ISteamUGC_SetAllowCachedResponse(ISteamUGC * instancePtr, uint64 queryHandle, uint32 maxAgeSeconds);
	int bmx_SteamAPI_ISteamUGC_SetCloudFileNameFilter( ISteamUGC * instancePtr, uint64 queryHandle, BBString * matchCloudFileName);
	int bmx_SteamAPI_ISteamUGC_SetItemContent(ISteamUGC * instancePtr, uint64 updateHandle, BBString * contentFolder);
	int bmx_SteamAPI_ISteamUGC_SetItemDescription(ISteamUGC * instancePtr, uint64 updateHandle, BBString * description);
	int bmx_SteamAPI_ISteamUGC_SetItemMetadata(ISteamUGC * instancePtr, uint64 updateHandle, BBString * metaData);
	int bmx_SteamAPI_ISteamUGC_SetItemPreview(ISteamUGC * instancePtr, uint64 updateHandle, BBString * previewFile);
	int bmx_SteamAPI_ISteamUGC_SetItemTags(ISteamUGC * instancePtr, uint64 updateHandle, BBArray * tags, int allowAdminTags);
	int bmx_SteamAPI_ISteamUGC_SetItemTitle(ISteamUGC * instancePtr, uint64 updateHandle, BBString * title);
	int bmx_SteamAPI_ISteamUGC_SetItemUpdateLanguage(ISteamUGC * instancePtr, uint64 updateHandle, BBString * language);
	int bmx_SteamAPI_ISteamUGC_SetItemVisibility( ISteamUGC * instancePtr, uint64 updateHandle, ERemoteStoragePublishedFileVisibility visibility);
	int bmx_SteamAPI_ISteamUGC_SetLanguage(ISteamUGC * instancePtr, uint64 queryHandle, BBString * language);
	int bmx_SteamAPI_ISteamUGC_SetMatchAnyTag(ISteamUGC * instancePtr, uint64 queryHandle, int matchAnyTag);
	int bmx_SteamAPI_ISteamUGC_SetRankedByTrendDays(ISteamUGC * instancePtr, uint64 queryHandle, uint32 days);
	int bmx_SteamAPI_ISteamUGC_SetReturnAdditionalPreviews( ISteamUGC * instancePtr, uint64 queryHandle, int returnAdditionalPreviews);
	int bmx_SteamAPI_ISteamUGC_SetReturnChildren(ISteamUGC * instancePtr, uint64 queryHandle, int returnChildren);
	int bmx_SteamAPI_ISteamUGC_SetReturnKeyValueTags(ISteamUGC * instancePtr, uint64 queryHandle, int returnKeyValueTags);
	int bmx_SteamAPI_ISteamUGC_SetReturnLongDescription( ISteamUGC * instancePtr, uint64 queryHandle, int returnLongDescription);
	int bmx_SteamAPI_ISteamUGC_SetReturnMetadata(ISteamUGC * instancePtr, uint64 queryHandle, int returnMetadata);
	int bmx_SteamAPI_ISteamUGC_SetReturnOnlyIDs(ISteamUGC * instancePtr, uint64 queryHandle, int returnOnlyIDs);
	int bmx_SteamAPI_ISteamUGC_SetReturnPlaytimeStats(ISteamUGC * instancePtr, uint64 queryHandle, uint32 days);
	int bmx_SteamAPI_ISteamUGC_SetReturnTotalOnly(ISteamUGC * instancePtr, uint64 queryHandle, int returnTotalOnly);
	int bmx_SteamAPI_ISteamUGC_SetSearchText(ISteamUGC * instancePtr, uint64 queryHandle, BBString * searchText);
	void bmx_SteamAPI_ISteamUGC_SetUserItemVote(MaxUGC * ugc, uint64 publishedFileID, int voteUp);
	uint64 bmx_SteamAPI_ISteamUGC_StartItemUpdate(ISteamUGC * instancePtr, uint32 consumerAppId, uint64 publishedFileID);
	void bmx_SteamAPI_ISteamUGC_StartPlaytimeTracking(MaxUGC * ugc, uint64 * publishedFileIDs, uint32 numPublishedFileIDs);
	void bmx_SteamAPI_ISteamUGC_StopPlaytimeTracking(MaxUGC * ugc, uint64 * publishedFileIDs, uint32 numPublishedFileIDs);
	void bmx_SteamAPI_ISteamUGC_StopPlaytimeTrackingForAllItems(MaxUGC * ugc);
	void bmx_SteamAPI_ISteamUGC_SubmitItemUpdate(MaxUGC * ugc, uint64 updateHandle, BBString * changeNote);
	void bmx_SteamAPI_ISteamUGC_SubscribeItem(MaxUGC * ugc, uint64 publishedFileID);
	void bmx_SteamAPI_ISteamUGC_SuspendDownloads(ISteamUGC * instancePtr, int suspend);
	void bmx_SteamAPI_ISteamUGC_UnsubscribeItem(MaxUGC * ugc, uint64 publishedFileID);
	int bmx_SteamAPI_ISteamUGC_UpdateItemPreviewFile( ISteamUGC * instancePtr, uint64 updateHandle, uint32 index, BBString * previewFile);
	int bmx_SteamAPI_ISteamUGC_UpdateItemPreviewVideo( ISteamUGC * instancePtr, uint64 updateHandle, uint32 index, BBString * videoID);

	void * bmx_steamsdk_register_steamfriends(ISteamFriends * instancePtr, BBObject * obj);
	void bmx_steamsdk_unregister_steamfriends(void * callbackPtr);

	void bmx_SteamAPI_ISteamFriends_ActivateGameOverlay(ISteamFriends * instancePtr, BBString * dialog);
	void bmx_SteamAPI_ISteamFriends_ActivateGameOverlayInviteDialog(ISteamFriends * instancePtr, uint64 steamIDLobby);
	void bmx_SteamAPI_ISteamFriends_ActivateGameOverlayInviteDialogConnectString( ISteamFriends * instancePtr, BBString * connectString);
	void bmx_SteamAPI_ISteamFriends_ActivateGameOverlayRemotePlayTogetherInviteDialog( ISteamFriends * instancePtr, uint64 steamIDLobby);
	int bmx_SteamAPI_ISteamFriends_GetNumChatsWithUnreadPriorityMessages(ISteamFriends * instancePtr);
	int bmx_SteamAPI_ISteamFriends_RegisterProtocolInOverlayBrowser(ISteamFriends * instancePtr, BBString * protocol);
	void bmx_SteamAPI_ISteamFriends_ActivateGameOverlayToStore( ISteamFriends * instancePtr, uint32 appID, EOverlayToStoreFlag flag);
	void bmx_SteamAPI_ISteamFriends_ActivateGameOverlayToUser( ISteamFriends * instancePtr, BBString * dialog, uint64 steamID);
	void bmx_SteamAPI_ISteamFriends_ActivateGameOverlayToWebPage(ISteamFriends * instancePtr, BBString * url);
	void bmx_SteamAPI_ISteamFriends_ClearRichPresence(ISteamFriends * instancePtr);
	int bmx_SteamAPI_ISteamFriends_CloseClanChatWindowInSteam(ISteamFriends * instancePtr, uint64 steamIDClanChat);
	void bmx_SteamAPI_ISteamFriends_DownloadClanActivityCounts( MaxFriends * friends, uint64 * steamIDClans, int clansToRequest);
	void bmx_SteamAPI_ISteamFriends_EnumerateFollowingList(MaxFriends * friends, uint32 startIndex);
	uint64 bmx_SteamAPI_ISteamFriends_GetChatMemberByIndex(ISteamFriends * instancePtr, uint64 steamIDClan, int user);
	int bmx_SteamAPI_ISteamFriends_GetClanActivityCounts( ISteamFriends * instancePtr, uint64 steamIDClan, int * online, int * inGame, int * chatting);
	uint64 bmx_SteamAPI_ISteamFriends_GetClanByIndex(ISteamFriends * instancePtr, int clan);
	int bmx_SteamAPI_ISteamFriends_GetClanChatMemberCount(ISteamFriends * instancePtr, uint64 steamIDClan);
	int bmx_SteamAPI_ISteamFriends_GetClanChatMessage(ISteamFriends * instancePtr, uint64 steamIDClanChat, int message, BBString ** txt, EChatEntryType * chatEntryType, uint64 * steamidChatter);
	int bmx_SteamAPI_ISteamFriends_GetClanCount(ISteamFriends * instancePtr);
	BBString * bmx_SteamAPI_ISteamFriends_GetClanName(ISteamFriends * instancePtr, uint64 steamIDClan);
	uint64 bmx_SteamAPI_ISteamFriends_GetClanOfficerByIndex(ISteamFriends * instancePtr, uint64 steamIDClan, int officer);
	int bmx_SteamAPI_ISteamFriends_GetClanOfficerCount(ISteamFriends * instancePtr, uint64 steamIDClan);
	uint64 bmx_SteamAPI_ISteamFriends_GetClanOwner(ISteamFriends * instancePtr, uint64 steamIDClan);
	BBString * bmx_SteamAPI_ISteamFriends_GetClanTag(ISteamFriends * instancePtr, uint64 steamIDClan);
	uint64 bmx_SteamAPI_ISteamFriends_GetCoplayFriend(ISteamFriends * instancePtr, int coplayFriend);
	int bmx_SteamAPI_ISteamFriends_GetCoplayFriendCount(ISteamFriends * instancePtr);
	void bmx_SteamAPI_ISteamFriends_GetFollowerCount(MaxFriends * friends, uint64 steamID);
	uint64 bmx_SteamAPI_ISteamFriends_GetFriendByIndex(ISteamFriends * instancePtr, int friendIndex, int friendFlags);
	uint32 bmx_SteamAPI_ISteamFriends_GetFriendCoplayGame(ISteamFriends * instancePtr, uint64 steamIDFriend);
	int bmx_SteamAPI_ISteamFriends_GetFriendCoplayTime(ISteamFriends * instancePtr, uint64 steamIDFriend);
	int bmx_SteamAPI_ISteamFriends_GetFriendCount(ISteamFriends * instancePtr, int friendFlags);
	int bmx_SteamAPI_ISteamFriends_GetFriendCountFromSource(ISteamFriends * instancePtr, uint64 steamIDSource);
	uint64 bmx_SteamAPI_ISteamFriends_GetFriendFromSourceByIndex( ISteamFriends * instancePtr, uint64 steamIDSource, int friendIndex);
	int bmx_SteamAPI_ISteamFriends_GetFriendGamePlayed(ISteamFriends * instancePtr, uint64 steamIDFriend, uint64 * gameID, uint32 * gameIP, BBSHORT * gamePort, BBSHORT * queryPort, uint64 * steamIDLobby);
	int bmx_SteamAPI_ISteamFriends_GetFriendMessage( ISteamFriends * instancePtr, uint64 steamIDFriend, int messageID, BBString ** txt, EChatEntryType * chatEntryType);
	BBString * bmx_SteamAPI_ISteamFriends_GetFriendPersonaName(ISteamFriends * instancePtr, uint64 steamIDFriend);
	BBString * bmx_SteamAPI_ISteamFriends_GetFriendPersonaNameHistory( ISteamFriends * instancePtr, uint64 steamIDFriend, int personaName);
	EPersonaState bmx_SteamAPI_ISteamFriends_GetFriendPersonaState(ISteamFriends * instancePtr, uint64 steamIDFriend);
	EFriendRelationship bmx_SteamAPI_ISteamFriends_GetFriendRelationship(ISteamFriends * instancePtr, uint64 steamIDFriend);
	BBString * bmx_SteamAPI_ISteamFriends_GetFriendRichPresence( ISteamFriends * instancePtr, uint64 steamIDFriend, BBString * key);
	BBString * bmx_SteamAPI_ISteamFriends_GetFriendRichPresenceKeyByIndex( ISteamFriends * instancePtr, uint64 steamIDFriend, int key);
	int bmx_SteamAPI_ISteamFriends_GetFriendRichPresenceKeyCount(ISteamFriends * instancePtr, uint64 steamIDFriend);
	int bmx_SteamAPI_ISteamFriends_GetFriendsGroupCount(ISteamFriends * instancePtr);
	BBSHORT bmx_SteamAPI_ISteamFriends_GetFriendsGroupIDByIndex(ISteamFriends * instancePtr, int fg);
	int bmx_SteamAPI_ISteamFriends_GetFriendsGroupMembersCount(ISteamFriends * instancePtr, BBSHORT friendsGroupID);
	void bmx_SteamAPI_ISteamFriends_GetFriendsGroupMembersList( ISteamFriends * instancePtr, BBSHORT friendsGroupID, uint64 * outSteamIDMembers, int membersCount);
	BBString * bmx_SteamAPI_ISteamFriends_GetFriendsGroupName(ISteamFriends * instancePtr, BBSHORT friendsGroupID);
	int bmx_SteamAPI_ISteamFriends_GetFriendSteamLevel(ISteamFriends * instancePtr, uint64 steamIDFriend);
	int bmx_SteamAPI_ISteamFriends_GetLargeFriendAvatar(ISteamFriends * instancePtr, uint64 steamIDFriend);
	int bmx_SteamAPI_ISteamFriends_GetMediumFriendAvatar(ISteamFriends * instancePtr, uint64 steamIDFriend);
	BBString * bmx_SteamAPI_ISteamFriends_GetPersonaName(ISteamFriends * instancePtr);
	EPersonaState bmx_SteamAPI_ISteamFriends_GetPersonaState(ISteamFriends * instancePtr);
	BBString * bmx_SteamAPI_ISteamFriends_GetPlayerNickname(ISteamFriends * instancePtr, uint64 steamIDPlayer);
	int bmx_SteamAPI_ISteamFriends_GetSmallFriendAvatar(ISteamFriends * instancePtr, uint64 steamIDFriend);
	int bmx_SteamAPI_ISteamFriends_HasFriend(ISteamFriends * instancePtr, uint64 steamIDFriend, int friendFlags);
	int bmx_SteamAPI_ISteamFriends_InviteUserToGame( ISteamFriends * instancePtr, uint64 steamIDFriend, BBString * connectString);
	int bmx_SteamAPI_ISteamFriends_IsClanChatAdmin(ISteamFriends * instancePtr, uint64 steamIDClanChat, uint64 steamIDUser);
	int bmx_SteamAPI_ISteamFriends_IsClanPublic(ISteamFriends * instancePtr, uint64 steamIDClan);
	int bmx_SteamAPI_ISteamFriends_IsClanOfficialGameGroup(ISteamFriends * instancePtr, uint64 steamIDClan);
	int bmx_SteamAPI_ISteamFriends_IsClanChatWindowOpenInSteam(ISteamFriends * instancePtr, uint64 steamIDClanChat);
	void bmx_SteamAPI_ISteamFriends_IsFollowing(MaxFriends * friends, uint64 steamID);
	int bmx_SteamAPI_ISteamFriends_IsUserInSource(ISteamFriends * instancePtr, uint64 steamIDUser, uint64 steamIDSource);
	void bmx_SteamAPI_ISteamFriends_JoinClanChatRoom(MaxFriends * friends, uint64 steamIDClan);
	int bmx_SteamAPI_ISteamFriends_LeaveClanChatRoom(ISteamFriends * instancePtr, uint64 steamIDClan);
	int bmx_SteamAPI_ISteamFriends_OpenClanChatWindowInSteam(ISteamFriends * instancePtr, uint64 steamIDClanChat);
	int bmx_SteamAPI_ISteamFriends_ReplyToFriendMessage( ISteamFriends * instancePtr, uint64 steamIDFriend, BBString * msgToSend);
	void bmx_SteamAPI_ISteamFriends_RequestClanOfficerList(MaxFriends * friends, uint64 steamIDClan);
	void bmx_SteamAPI_ISteamFriends_RequestFriendRichPresence(ISteamFriends * instancePtr, uint64 steamIDFriend);
	int bmx_SteamAPI_ISteamFriends_RequestUserInformation( ISteamFriends * instancePtr, uint64 steamIDUser, int requireNameOnly);
	int bmx_SteamAPI_ISteamFriends_SendClanChatMessage(ISteamFriends * instancePtr, uint64 steamIDClanChat, BBString * txt);
	void bmx_SteamAPI_ISteamFriends_SetInGameVoiceSpeaking(ISteamFriends * instancePtr, uint64 steamIDUser, int speaking);
	int bmx_SteamAPI_ISteamFriends_SetListenForFriendsMessages(ISteamFriends * instancePtr, int interceptEnabled);
	void bmx_SteamAPI_ISteamFriends_SetPlayedWith(ISteamFriends * instancePtr, uint64 steamIDUserPlayedWith);
	int bmx_SteamAPI_ISteamFriends_SetRichPresence(ISteamFriends * instancePtr, BBString * key, BBString * value);
	void bmx_SteamAPI_ISteamFriends_RequestEquippedProfileItems(MaxFriends * friends, uint64 steamID);
	int bmx_SteamAPI_ISteamFriends_BHasEquippedProfileItem(ISteamFriends * instancePtr, uint64 steamID, ECommunityProfileItemType itemType);
	BBString * bmx_SteamAPI_ISteamFriends_GetProfileItemPropertyString(ISteamFriends * instancePtr, uint64 steamID, ECommunityProfileItemType itemType, ECommunityProfileItemProperty property);
	uint32 bmx_SteamAPI_ISteamFriends_GetProfileItemPropertyUint(ISteamFriends * instancePtr, uint64 steamID, ECommunityProfileItemType itemType, ECommunityProfileItemProperty property);
}

int bmx_SteamAPI_Init() {
	return SteamAPI_Init();
}

void bmx_SteamAPI_Shutdown() {
	CancelRemoteStorageRequests();
	SteamAPI_Shutdown();
}

HSteamPipe bmx_SteamAPI_GetHSteamPipe() {
	return SteamAPI_GetHSteamPipe();
}

void * bmx_SteamAPI_SteamClient() {
	return SteamInternal_CreateInterface(STEAMCLIENT_INTERFACE_VERSION);
}

void bmx_SteamAPI_RunCallbacks() {
	SteamAPI_RunCallbacks();
}

int bmx_SteamAPI_RestartAppIfNecessary(uint32 ownAppID) {
	return SteamAPI_RestartAppIfNecessary(ownAppID);
}

class CallbackTimer
{
	std::thread th;
	std::atomic<bool> running{false};
	BBThread * bbThread = NULL;

public:
	typedef std::chrono::milliseconds Interval;
	typedef std::function<void(void)> Timeout;

	void start(const Interval & interval, const Timeout & timeout) {
		if (running.exchange(true)) {
			return;
		}

		th = std::thread([=]() {

#ifdef _WIN32
			bb_thread_t nativeThread = ::GetCurrentThreadId();
#else
			bb_thread_t nativeThread = pthread_self();
#endif
			bbThread = bbThreadRegister(nativeThread);

			while (running.load()) {
				std::this_thread::sleep_for(interval);
				if (!running.load()) {
					break;
				}
				timeout();
			}

			bbThreadUnregister(bbThread);
		});
	}

	void stop() {
		if (!running.exchange(false)) {
			return;
		}
		if (th.joinable()) {
			th.join();
		}
	}
};

CallbackTimer _callbackTimer;

void bmx_SteamAPI_startBackgroundTimer() {
	_callbackTimer.start(std::chrono::milliseconds(100), [] { SteamAPI_RunCallbacks(); });
}

void bmx_SteamAPI_stopBackgroundTimer() {
	_callbackTimer.stop();
}

// ISteamClient -------------------------------------------

void * bmx_SteamAPI_ISteamClient_GetISteamUtils(ISteamClient * instancePtr, HSteamPipe pipe) {
	return SteamAPI_ISteamClient_GetISteamUtils(instancePtr, pipe, STEAMUTILS_INTERFACE_VERSION);
}

HSteamUser bmx_SteamAPI_ISteamClient_ConnectToGlobalUser(ISteamClient * instancePtr, HSteamPipe pipe) {
	return SteamAPI_ISteamClient_ConnectToGlobalUser(instancePtr, pipe);
}

void * bmx_SteamAPI_ISteamClient_GetISteamUserStats(ISteamClient * instancePtr, HSteamUser user, HSteamPipe pipe) {
	return SteamAPI_ISteamClient_GetISteamUserStats(instancePtr, user, pipe, STEAMUSERSTATS_INTERFACE_VERSION);
}

void * bmx_SteamAPI_ISteamClient_GetISteamUGC(ISteamClient * instancePtr, HSteamUser user, HSteamPipe pipe) {
	return SteamAPI_ISteamClient_GetISteamUGC(instancePtr, user, pipe, STEAMUGC_INTERFACE_VERSION);
}

void * bmx_SteamAPI_ISteamClient_GetISteamFriends(ISteamClient * instancePtr, HSteamUser user, HSteamPipe pipe) {
	return SteamAPI_ISteamClient_GetISteamFriends(instancePtr, user, pipe, STEAMFRIENDS_INTERFACE_VERSION);
}

void * bmx_SteamAPI_ISteamClient_GetISteamUser(ISteamClient * instancePtr, HSteamUser user, HSteamPipe pipe) {
	return SteamAPI_ISteamClient_GetISteamUser(instancePtr, user, pipe, STEAMUSER_INTERFACE_VERSION);
}

void * bmx_SteamAPI_ISteamClient_GetISteamMatchmaking(ISteamClient * instancePtr, HSteamUser user, HSteamPipe pipe) {
	return SteamAPI_ISteamClient_GetISteamMatchmaking(instancePtr, user, pipe, STEAMMATCHMAKING_INTERFACE_VERSION);
}

void * bmx_SteamAPI_ISteamClient_GetISteamApps(ISteamClient * instancePtr, HSteamUser user, HSteamPipe pipe) {
	return SteamAPI_ISteamClient_GetISteamApps(instancePtr, user, pipe, STEAMAPPS_INTERFACE_VERSION);
}

void * bmx_SteamAPI_ISteamClient_GetISteamRemoteStorage(ISteamClient * instancePtr, HSteamUser user, HSteamPipe pipe) {
	return SteamAPI_ISteamClient_GetISteamRemoteStorage(instancePtr, user, pipe, STEAMREMOTESTORAGE_INTERFACE_VERSION);
}

void * bmx_SteamAPI_ISteamClient_GetISteamInput(ISteamClient * instancePtr, HSteamUser user, HSteamPipe pipe) {
	return SteamAPI_ISteamClient_GetISteamInput(instancePtr, user, pipe, STEAMINPUT_INTERFACE_VERSION);
}

void * bmx_SteamAPI_SteamTimeline() {
	return SteamAPI_SteamTimeline();
}

// ISteamInput --------------------------------------------

class MaxInput;
static MaxInput * g_actionEventInput = nullptr;

class MaxInput
{
private:
	ISteamInput * instancePtr;
	BBObject * maxHandle;

public:
	STEAM_CALLBACK(MaxInput, OnDeviceConnected, SteamInputDeviceConnected_t, m_CallbackDeviceConnected);
	STEAM_CALLBACK(MaxInput, OnDeviceDisconnected, SteamInputDeviceDisconnected_t, m_CallbackDeviceDisconnected);
	STEAM_CALLBACK(MaxInput, OnConfigurationLoaded, SteamInputConfigurationLoaded_t, m_CallbackConfigurationLoaded);

	MaxInput(ISteamInput * instancePtr, BBObject * handle)
		: instancePtr(instancePtr), maxHandle(handle), m_CallbackDeviceConnected(this, &MaxInput::OnDeviceConnected),
		  m_CallbackDeviceDisconnected(this, &MaxInput::OnDeviceDisconnected),
		  m_CallbackConfigurationLoaded(this, &MaxInput::OnConfigurationLoaded) {
	}

	~MaxInput() {
		if (g_actionEventInput == this) {
			SteamAPI_ISteamInput_EnableActionEventCallbacks(instancePtr, nullptr);
			g_actionEventInput = nullptr;
		}
	}

	void EnableActionEvents();
	void DispatchActionEvent(SteamInputActionEvent_t * event);
};

static void OnSteamInputActionEvent(SteamInputActionEvent_t * event) {
	if (g_actionEventInput) {
		g_actionEventInput->DispatchActionEvent(event);
	}
}

void MaxInput::EnableActionEvents() {
	g_actionEventInput = this;
	SteamAPI_ISteamInput_EnableActionEventCallbacks(instancePtr, &OnSteamInputActionEvent);
}

void MaxInput::DispatchActionEvent(SteamInputActionEvent_t * event) {
	if (event->eEventType == ESteamInputActionEventType_DigitalAction) {
		steam_steamsdk_TSteamInput__OnDigitalAction(maxHandle, event->controllerHandle,
			event->digitalAction.actionHandle, event->digitalAction.digitalActionData.bState,
			event->digitalAction.digitalActionData.bActive);
	} else if (event->eEventType == ESteamInputActionEventType_AnalogAction) {
		const InputAnalogActionData_t & data = event->analogAction.analogActionData;
		steam_steamsdk_TSteamInput__OnAnalogAction(maxHandle, event->controllerHandle, event->analogAction.actionHandle,
			data.eMode, data.x, data.y, data.bActive);
	}
}

void MaxInput::OnDeviceConnected(SteamInputDeviceConnected_t * event) {
	steam_steamsdk_TSteamInput__OnDeviceConnected(maxHandle, event->m_ulConnectedDeviceHandle);
}

void MaxInput::OnDeviceDisconnected(SteamInputDeviceDisconnected_t * event) {
	steam_steamsdk_TSteamInput__OnDeviceDisconnected(maxHandle, event->m_ulDisconnectedDeviceHandle);
}

void MaxInput::OnConfigurationLoaded(SteamInputConfigurationLoaded_t * event) {
	steam_steamsdk_TSteamInput__OnConfigurationLoaded(maxHandle, event->m_unAppID, event->m_ulDeviceHandle,
		event->m_ulMappingCreator.ConvertToUint64(), event->m_unMajorRevision, event->m_unMinorRevision,
		event->m_bUsesSteamInputAPI, event->m_bUsesGamepadAPI);
}

static BBString * SteamInputString(const char * value) {
	return bbStringFromUTF8String((unsigned char *)(value ? value : ""));
}

void * bmx_steamsdk_register_steaminput(ISteamInput * instancePtr, BBObject * obj) {
	return new MaxInput(instancePtr, obj);
}

void bmx_steamsdk_unregister_steaminput(void * callbackPtr) {
	delete static_cast<MaxInput *>(callbackPtr);
}

int bmx_SteamAPI_ISteamInput_Init(ISteamInput * instancePtr, int explicitlyCallRunFrame) {
	return SteamAPI_ISteamInput_Init(instancePtr, explicitlyCallRunFrame);
}

int bmx_SteamAPI_ISteamInput_Shutdown(ISteamInput * instancePtr) {
	return SteamAPI_ISteamInput_Shutdown(instancePtr);
}

int bmx_SteamAPI_ISteamInput_SetInputActionManifestFilePath(ISteamInput * instancePtr, BBString * path) {
	char * nativePath = (char *)bbStringToUTF8String(path);
	bool result = SteamAPI_ISteamInput_SetInputActionManifestFilePath(instancePtr, nativePath);
	bbMemFree(nativePath);
	return result;
}

void bmx_SteamAPI_ISteamInput_RunFrame(ISteamInput * instancePtr) {
	SteamAPI_ISteamInput_RunFrame(instancePtr, true);
}

int bmx_SteamAPI_ISteamInput_BWaitForData(ISteamInput * instancePtr, int waitForever, uint32 timeout) {
	return SteamAPI_ISteamInput_BWaitForData(instancePtr, waitForever, timeout);
}

int bmx_SteamAPI_ISteamInput_BNewDataAvailable(ISteamInput * instancePtr) {
	return SteamAPI_ISteamInput_BNewDataAvailable(instancePtr);
}

int bmx_SteamAPI_ISteamInput_GetConnectedControllers(ISteamInput * instancePtr, uint64 * handles, int capacity) {
	InputHandle_t values[STEAM_INPUT_MAX_COUNT];
	int count = SteamAPI_ISteamInput_GetConnectedControllers(instancePtr, values);
	int copied = std::min(std::max(capacity, 0), count);

	if (handles) {
		std::copy(values, values + copied, handles);
	}

	return copied;
}

void bmx_SteamAPI_ISteamInput_EnableDeviceCallbacks(ISteamInput * instancePtr) {
	SteamAPI_ISteamInput_EnableDeviceCallbacks(instancePtr);
}

void bmx_SteamAPI_ISteamInput_EnableActionEventCallbacks(MaxInput * input) {
	input->EnableActionEvents();
}

uint64 bmx_SteamAPI_ISteamInput_GetActionSetHandle(ISteamInput * instancePtr, BBString * name) {
	char * nativeName = (char *)bbStringToUTF8String(name);
	uint64 result = SteamAPI_ISteamInput_GetActionSetHandle(instancePtr, nativeName);
	bbMemFree(nativeName);
	return result;
}

void bmx_SteamAPI_ISteamInput_ActivateActionSet(ISteamInput * instancePtr, uint64 inputHandle, uint64 actionSetHandle) {
	SteamAPI_ISteamInput_ActivateActionSet(instancePtr, inputHandle, actionSetHandle);
}

uint64 bmx_SteamAPI_ISteamInput_GetCurrentActionSet(ISteamInput * instancePtr, uint64 inputHandle) {
	return SteamAPI_ISteamInput_GetCurrentActionSet(instancePtr, inputHandle);
}

void bmx_SteamAPI_ISteamInput_ActivateActionSetLayer(
	ISteamInput * instancePtr, uint64 inputHandle, uint64 actionSetLayerHandle) {
	SteamAPI_ISteamInput_ActivateActionSetLayer(instancePtr, inputHandle, actionSetLayerHandle);
}

void bmx_SteamAPI_ISteamInput_DeactivateActionSetLayer(
	ISteamInput * instancePtr, uint64 inputHandle, uint64 actionSetLayerHandle) {
	SteamAPI_ISteamInput_DeactivateActionSetLayer(instancePtr, inputHandle, actionSetLayerHandle);
}

void bmx_SteamAPI_ISteamInput_DeactivateAllActionSetLayers(ISteamInput * instancePtr, uint64 inputHandle) {
	SteamAPI_ISteamInput_DeactivateAllActionSetLayers(instancePtr, inputHandle);
}

int bmx_SteamAPI_ISteamInput_GetActiveActionSetLayers(
	ISteamInput * instancePtr, uint64 inputHandle, uint64 * handles, int capacity) {
	InputActionSetHandle_t values[STEAM_INPUT_MAX_ACTIVE_LAYERS];
	int count = SteamAPI_ISteamInput_GetActiveActionSetLayers(instancePtr, inputHandle, values);
	int copied = std::min(std::max(capacity, 0), count);

	if (handles) {
		std::copy(values, values + copied, handles);
	}

	return copied;
}

uint64 bmx_SteamAPI_ISteamInput_GetDigitalActionHandle(ISteamInput * instancePtr, BBString * name) {
	char * nativeName = (char *)bbStringToUTF8String(name);
	uint64 result = SteamAPI_ISteamInput_GetDigitalActionHandle(instancePtr, nativeName);
	bbMemFree(nativeName);
	return result;
}

void bmx_SteamAPI_ISteamInput_GetDigitalActionData(
	ISteamInput * instancePtr, uint64 inputHandle, uint64 actionHandle, int * state, int * active) {
	InputDigitalActionData_t data = SteamAPI_ISteamInput_GetDigitalActionData(instancePtr, inputHandle, actionHandle);
	*state = data.bState;
	*active = data.bActive;
}

int bmx_SteamAPI_ISteamInput_GetDigitalActionOrigins(ISteamInput * instancePtr, uint64 inputHandle,
	uint64 actionSetHandle, uint64 actionHandle, int * origins, int capacity) {
	EInputActionOrigin values[STEAM_INPUT_MAX_ORIGINS];
	int count =
		SteamAPI_ISteamInput_GetDigitalActionOrigins(instancePtr, inputHandle, actionSetHandle, actionHandle, values);
	int copied = std::min(std::max(capacity, 0), count);

	for (int i = 0; origins && i < copied; ++i) {
		origins[i] = values[i];
	}

	return copied;
}

BBString * bmx_SteamAPI_ISteamInput_GetStringForDigitalActionName(ISteamInput * instancePtr, uint64 actionHandle) {
	const char * value = SteamAPI_ISteamInput_GetStringForDigitalActionName(instancePtr, actionHandle);
	return SteamInputString(value);
}

uint64 bmx_SteamAPI_ISteamInput_GetAnalogActionHandle(ISteamInput * instancePtr, BBString * name) {
	char * nativeName = (char *)bbStringToUTF8String(name);
	uint64 result = SteamAPI_ISteamInput_GetAnalogActionHandle(instancePtr, nativeName);
	bbMemFree(nativeName);
	return result;
}

void bmx_SteamAPI_ISteamInput_GetAnalogActionData(ISteamInput * instancePtr, uint64 inputHandle, uint64 actionHandle,
	EInputSourceMode * mode, float * x, float * y, int * active) {
	InputAnalogActionData_t data = SteamAPI_ISteamInput_GetAnalogActionData(instancePtr, inputHandle, actionHandle);
	*mode = data.eMode;
	*x = data.x;
	*y = data.y;
	*active = data.bActive;
}

int bmx_SteamAPI_ISteamInput_GetAnalogActionOrigins(ISteamInput * instancePtr, uint64 inputHandle,
	uint64 actionSetHandle, uint64 actionHandle, int * origins, int capacity) {
	EInputActionOrigin values[STEAM_INPUT_MAX_ORIGINS];
	int count =
		SteamAPI_ISteamInput_GetAnalogActionOrigins(instancePtr, inputHandle, actionSetHandle, actionHandle, values);
	int copied = std::min(std::max(capacity, 0), count);

	for (int i = 0; origins && i < copied; ++i) {
		origins[i] = values[i];
	}

	return copied;
}

BBString * bmx_SteamAPI_ISteamInput_GetGlyphPNGForActionOrigin(
	ISteamInput * instancePtr, EInputActionOrigin origin, ESteamInputGlyphSize size, uint32 flags) {
	const char * value = SteamAPI_ISteamInput_GetGlyphPNGForActionOrigin(instancePtr, origin, size, flags);
	return SteamInputString(value);
}

BBString * bmx_SteamAPI_ISteamInput_GetGlyphSVGForActionOrigin(
	ISteamInput * instancePtr, EInputActionOrigin origin, uint32 flags) {
	const char * value = SteamAPI_ISteamInput_GetGlyphSVGForActionOrigin(instancePtr, origin, flags);
	return SteamInputString(value);
}

BBString * bmx_SteamAPI_ISteamInput_GetStringForActionOrigin(ISteamInput * instancePtr, EInputActionOrigin origin) {
	const char * value = SteamAPI_ISteamInput_GetStringForActionOrigin(instancePtr, origin);
	return SteamInputString(value);
}

BBString * bmx_SteamAPI_ISteamInput_GetStringForAnalogActionName(ISteamInput * instancePtr, uint64 actionHandle) {
	const char * value = SteamAPI_ISteamInput_GetStringForAnalogActionName(instancePtr, actionHandle);
	return SteamInputString(value);
}

void bmx_SteamAPI_ISteamInput_StopAnalogActionMomentum(
	ISteamInput * instancePtr, uint64 inputHandle, uint64 actionHandle) {
	SteamAPI_ISteamInput_StopAnalogActionMomentum(instancePtr, inputHandle, actionHandle);
}

void bmx_SteamAPI_ISteamInput_GetMotionData(ISteamInput * instancePtr, uint64 inputHandle, float * rotQuatX,
	float * rotQuatY, float * rotQuatZ, float * rotQuatW, float * posAccelX, float * posAccelY, float * posAccelZ,
	float * rotVelX, float * rotVelY, float * rotVelZ) {
	InputMotionData_t data = SteamAPI_ISteamInput_GetMotionData(instancePtr, inputHandle);
	*rotQuatX = data.rotQuatX;
	*rotQuatY = data.rotQuatY;
	*rotQuatZ = data.rotQuatZ;
	*rotQuatW = data.rotQuatW;
	*posAccelX = data.posAccelX;
	*posAccelY = data.posAccelY;
	*posAccelZ = data.posAccelZ;
	*rotVelX = data.rotVelX;
	*rotVelY = data.rotVelY;
	*rotVelZ = data.rotVelZ;
}

void bmx_SteamAPI_ISteamInput_TriggerVibration(
	ISteamInput * instancePtr, uint64 inputHandle, int leftSpeed, int rightSpeed) {
	SteamAPI_ISteamInput_TriggerVibration(instancePtr, inputHandle, (uint16)leftSpeed, (uint16)rightSpeed);
}

void bmx_SteamAPI_ISteamInput_TriggerVibrationExtended(ISteamInput * instancePtr, uint64 inputHandle, int leftSpeed,
	int rightSpeed, int leftTriggerSpeed, int rightTriggerSpeed) {
	SteamAPI_ISteamInput_TriggerVibrationExtended(instancePtr, inputHandle, (uint16)leftSpeed, (uint16)rightSpeed,
		(uint16)leftTriggerSpeed, (uint16)rightTriggerSpeed);
}

void bmx_SteamAPI_ISteamInput_TriggerSimpleHapticEvent(ISteamInput * instancePtr, uint64 inputHandle,
	EControllerHapticLocation location, int intensity, int gainDB, int otherIntensity, int otherGainDB) {
	SteamAPI_ISteamInput_TriggerSimpleHapticEvent(
		instancePtr, inputHandle, location, (uint8)intensity, (int8)gainDB, (uint8)otherIntensity, (int8)otherGainDB);
}

void bmx_SteamAPI_ISteamInput_SetLEDColor(
	ISteamInput * instancePtr, uint64 inputHandle, int red, int green, int blue, uint32 flags) {
	SteamAPI_ISteamInput_SetLEDColor(instancePtr, inputHandle, (uint8)red, (uint8)green, (uint8)blue, flags);
}

int bmx_SteamAPI_ISteamInput_ShowBindingPanel(ISteamInput * instancePtr, uint64 inputHandle) {
	return SteamAPI_ISteamInput_ShowBindingPanel(instancePtr, inputHandle);
}

ESteamInputType bmx_SteamAPI_ISteamInput_GetInputTypeForHandle(ISteamInput * instancePtr, uint64 inputHandle) {
	return SteamAPI_ISteamInput_GetInputTypeForHandle(instancePtr, inputHandle);
}

uint64 bmx_SteamAPI_ISteamInput_GetControllerForGamepadIndex(ISteamInput * instancePtr, int index) {
	return SteamAPI_ISteamInput_GetControllerForGamepadIndex(instancePtr, index);
}

int bmx_SteamAPI_ISteamInput_GetGamepadIndexForController(ISteamInput * instancePtr, uint64 inputHandle) {
	return SteamAPI_ISteamInput_GetGamepadIndexForController(instancePtr, inputHandle);
}

BBString * bmx_SteamAPI_ISteamInput_GetStringForXboxOrigin(ISteamInput * instancePtr, EXboxOrigin origin) {
	const char * value = SteamAPI_ISteamInput_GetStringForXboxOrigin(instancePtr, origin);
	return SteamInputString(value);
}

BBString * bmx_SteamAPI_ISteamInput_GetGlyphForXboxOrigin(ISteamInput * instancePtr, EXboxOrigin origin) {
	const char * value = SteamAPI_ISteamInput_GetGlyphForXboxOrigin(instancePtr, origin);
	return SteamInputString(value);
}

EInputActionOrigin bmx_SteamAPI_ISteamInput_GetActionOriginFromXboxOrigin(
	ISteamInput * instancePtr, uint64 inputHandle, EXboxOrigin origin) {
	return SteamAPI_ISteamInput_GetActionOriginFromXboxOrigin(instancePtr, inputHandle, origin);
}

EInputActionOrigin bmx_SteamAPI_ISteamInput_TranslateActionOrigin(
	ISteamInput * instancePtr, ESteamInputType destinationType, EInputActionOrigin sourceOrigin) {
	return SteamAPI_ISteamInput_TranslateActionOrigin(instancePtr, destinationType, sourceOrigin);
}

int bmx_SteamAPI_ISteamInput_GetDeviceBindingRevision(
	ISteamInput * instancePtr, uint64 inputHandle, int * major, int * minor) {
	return SteamAPI_ISteamInput_GetDeviceBindingRevision(instancePtr, inputHandle, major, minor);
}

uint32 bmx_SteamAPI_ISteamInput_GetRemotePlaySessionID(ISteamInput * instancePtr, uint64 inputHandle) {
	return SteamAPI_ISteamInput_GetRemotePlaySessionID(instancePtr, inputHandle);
}

int bmx_SteamAPI_ISteamInput_GetSessionInputConfigurationSettings(ISteamInput * instancePtr) {
	return SteamAPI_ISteamInput_GetSessionInputConfigurationSettings(instancePtr);
}

int bmx_SteamAPI_ISteamInput_SetDualSenseTriggerEffect(ISteamInput * instancePtr, uint64 inputHandle, int trigger,
	int mode, int first, int second, int third, int fourth, const uint8 * values, int count) {
	if (trigger < SCE_PAD_TRIGGER_EFFECT_TRIGGER_MASK_L2 ||
		trigger > (SCE_PAD_TRIGGER_EFFECT_TRIGGER_MASK_L2 | SCE_PAD_TRIGGER_EFFECT_TRIGGER_MASK_R2) ||
		mode < SCE_PAD_TRIGGER_EFFECT_MODE_OFF || mode > SCE_PAD_TRIGGER_EFFECT_MODE_MULTIPLE_POSITION_VIBRATION) {
		return false;
	}

	if ((mode == SCE_PAD_TRIGGER_EFFECT_MODE_MULTIPLE_POSITION_FEEDBACK ||
		mode == SCE_PAD_TRIGGER_EFFECT_MODE_MULTIPLE_POSITION_VIBRATION) && (!values || count < 10)) {
		return false;
	}

	auto inRange = [](int value, int minimum, int maximum) {
		return value >= minimum && value <= maximum;
	};
	if ((mode == SCE_PAD_TRIGGER_EFFECT_MODE_FEEDBACK &&
		(!inRange(first, 0, 9) || !inRange(second, 0, 8))) ||
		(mode == SCE_PAD_TRIGGER_EFFECT_MODE_WEAPON &&
		(!inRange(first, 2, 7) || !inRange(second, first + 1, 8) || !inRange(third, 0, 8))) ||
		(mode == SCE_PAD_TRIGGER_EFFECT_MODE_VIBRATION &&
		(!inRange(first, 0, 9) || !inRange(second, 0, 8) || !inRange(third, 0, 255))) ||
		(mode == SCE_PAD_TRIGGER_EFFECT_MODE_SLOPE_FEEDBACK &&
		(!inRange(first, 0, 8) || !inRange(second, first + 1, 9) ||
		 !inRange(third, 1, 8) || !inRange(fourth, 1, 8))) ||
		(mode == SCE_PAD_TRIGGER_EFFECT_MODE_MULTIPLE_POSITION_VIBRATION && !inRange(first, 0, 255))) {
		return false;
	}

	if (mode == SCE_PAD_TRIGGER_EFFECT_MODE_MULTIPLE_POSITION_FEEDBACK ||
		mode == SCE_PAD_TRIGGER_EFFECT_MODE_MULTIPLE_POSITION_VIBRATION) {
		for (int i = 0; i < 10; ++i) {
			if (values[i] > 8) {
				return false;
			}
		}
	}

	ScePadTriggerEffectParam effect = {};
	effect.triggerMask = (uint8)trigger;

	for (int index = 0; index < SCE_PAD_TRIGGER_EFFECT_TRIGGER_NUM; ++index) {
		int mask = index == SCE_PAD_TRIGGER_EFFECT_PARAM_INDEX_FOR_L2
			? SCE_PAD_TRIGGER_EFFECT_TRIGGER_MASK_L2 : SCE_PAD_TRIGGER_EFFECT_TRIGGER_MASK_R2;
		if (!(trigger & mask)) {
			continue;
		}

		ScePadTriggerEffectCommand & command = effect.command[index];
		command.mode = (ScePadTriggerEffectMode)mode;
		switch (mode) {
			case SCE_PAD_TRIGGER_EFFECT_MODE_FEEDBACK:
				command.commandData.feedbackParam.position = (uint8)first;
				command.commandData.feedbackParam.strength = (uint8)second;
				break;
			case SCE_PAD_TRIGGER_EFFECT_MODE_WEAPON:
				command.commandData.weaponParam.startPosition = (uint8)first;
				command.commandData.weaponParam.endPosition = (uint8)second;
				command.commandData.weaponParam.strength = (uint8)third;
				break;
			case SCE_PAD_TRIGGER_EFFECT_MODE_VIBRATION:
				command.commandData.vibrationParam.position = (uint8)first;
				command.commandData.vibrationParam.amplitude = (uint8)second;
				command.commandData.vibrationParam.frequency = (uint8)third;
				break;
			case SCE_PAD_TRIGGER_EFFECT_MODE_MULTIPLE_POSITION_FEEDBACK:
				std::copy(values, values + 10, command.commandData.multiplePositionFeedbackParam.strength);
				break;
			case SCE_PAD_TRIGGER_EFFECT_MODE_SLOPE_FEEDBACK:
				command.commandData.slopeFeedbackParam.startPosition = (uint8)first;
				command.commandData.slopeFeedbackParam.endPosition = (uint8)second;
				command.commandData.slopeFeedbackParam.startStrength = (uint8)third;
				command.commandData.slopeFeedbackParam.endStrength = (uint8)fourth;
				break;
			case SCE_PAD_TRIGGER_EFFECT_MODE_MULTIPLE_POSITION_VIBRATION:
				command.commandData.multiplePositionVibrationParam.frequency = (uint8)first;
				std::copy(values, values + 10, command.commandData.multiplePositionVibrationParam.amplitude);
				break;
		}
	}

	SteamAPI_ISteamInput_SetDualSenseTriggerEffect(instancePtr, inputHandle, &effect);
	return true;
}

// ISteamTimeline -----------------------------------------

class MaxTimeline
{
private:
	ISteamTimeline * instancePtr;
	BBObject * maxHandle;
	CCallResult<MaxTimeline, SteamTimelineEventRecordingExists_t> m_EventRecordingExistsCallResult;
	CCallResult<MaxTimeline, SteamTimelineGamePhaseRecordingExists_t> m_GamePhaseRecordingExistsCallResult;

public:
	MaxTimeline(ISteamTimeline * instancePtr, BBObject * handle)
		: instancePtr(instancePtr), maxHandle(handle) {
	}

	SteamAPICall_t DoesEventRecordingExist(uint64 eventHandle) {
		SteamAPICall_t call = SteamAPI_ISteamTimeline_DoesEventRecordingExist(instancePtr, eventHandle);
		m_EventRecordingExistsCallResult.Set(call, this, &MaxTimeline::OnEventRecordingExists);
		return call;
	}

	SteamAPICall_t DoesGamePhaseRecordingExist(const char * phaseID) {
		SteamAPICall_t call = SteamAPI_ISteamTimeline_DoesGamePhaseRecordingExist(instancePtr, phaseID);
		m_GamePhaseRecordingExistsCallResult.Set(call, this, &MaxTimeline::OnGamePhaseRecordingExists);
		return call;
	}

	void OnEventRecordingExists(SteamTimelineEventRecordingExists_t * result, bool failure) {
		steam_steamsdk_TSteamTimeline__OnEventRecordingExists(
			maxHandle, result->m_ulEventID, result->m_bRecordingExists, failure);
	}

	void OnGamePhaseRecordingExists(SteamTimelineGamePhaseRecordingExists_t * result, bool failure) {
		steam_steamsdk_TSteamTimeline__OnGamePhaseRecordingExists(maxHandle,
			bbStringFromUTF8String((unsigned char *)result->m_rgchPhaseID), result->m_ulRecordingMS,
			result->m_ulLongestClipMS, result->m_unClipCount, result->m_unScreenshotCount, failure);
	}
};

void * bmx_steamsdk_register_steamtimeline(ISteamTimeline * instancePtr, BBObject * obj) {
	return new MaxTimeline(instancePtr, obj);
}

void bmx_steamsdk_unregister_steamtimeline(void * callbackPtr) {
	delete static_cast<MaxTimeline *>(callbackPtr);
}

void bmx_SteamAPI_ISteamTimeline_SetTimelineTooltip(
	ISteamTimeline * instancePtr, BBString * description, float timeDelta) {
	char * value = (char *)bbStringToUTF8String(description);
	SteamAPI_ISteamTimeline_SetTimelineTooltip(instancePtr, value, timeDelta);
	bbMemFree(value);
}

void bmx_SteamAPI_ISteamTimeline_ClearTimelineTooltip(ISteamTimeline * instancePtr, float timeDelta) {
	SteamAPI_ISteamTimeline_ClearTimelineTooltip(instancePtr, timeDelta);
}

void bmx_SteamAPI_ISteamTimeline_SetTimelineGameMode(ISteamTimeline * instancePtr, ETimelineGameMode mode) {
	SteamAPI_ISteamTimeline_SetTimelineGameMode(instancePtr, mode);
}

uint64 bmx_SteamAPI_ISteamTimeline_AddInstantaneousTimelineEvent(ISteamTimeline * instancePtr, BBString * title,
	BBString * description, BBString * icon, uint32 iconPriority, float startOffsetSeconds,
	ETimelineEventClipPriority clipPriority) {
	char * nativeTitle = (char *)bbStringToUTF8String(title);
	char * nativeDescription = (char *)bbStringToUTF8String(description);
	char * nativeIcon = (char *)bbStringToUTF8String(icon);
	uint64 result = SteamAPI_ISteamTimeline_AddInstantaneousTimelineEvent(instancePtr, nativeTitle,
		nativeDescription, nativeIcon, iconPriority, startOffsetSeconds, clipPriority);
	bbMemFree(nativeTitle);
	bbMemFree(nativeDescription);
	bbMemFree(nativeIcon);
	return result;
}

uint64 bmx_SteamAPI_ISteamTimeline_AddRangeTimelineEvent(ISteamTimeline * instancePtr, BBString * title,
	BBString * description, BBString * icon, uint32 iconPriority, float startOffsetSeconds, float duration,
	ETimelineEventClipPriority clipPriority) {
	char * nativeTitle = (char *)bbStringToUTF8String(title);
	char * nativeDescription = (char *)bbStringToUTF8String(description);
	char * nativeIcon = (char *)bbStringToUTF8String(icon);
	uint64 result = SteamAPI_ISteamTimeline_AddRangeTimelineEvent(instancePtr, nativeTitle, nativeDescription,
		nativeIcon, iconPriority, startOffsetSeconds, duration, clipPriority);
	bbMemFree(nativeTitle);
	bbMemFree(nativeDescription);
	bbMemFree(nativeIcon);
	return result;
}

uint64 bmx_SteamAPI_ISteamTimeline_StartRangeTimelineEvent(ISteamTimeline * instancePtr, BBString * title,
	BBString * description, BBString * icon, uint32 priority, float startOffsetSeconds,
	ETimelineEventClipPriority clipPriority) {
	char * nativeTitle = (char *)bbStringToUTF8String(title);
	char * nativeDescription = (char *)bbStringToUTF8String(description);
	char * nativeIcon = (char *)bbStringToUTF8String(icon);
	uint64 result = SteamAPI_ISteamTimeline_StartRangeTimelineEvent(instancePtr, nativeTitle, nativeDescription,
		nativeIcon, priority, startOffsetSeconds, clipPriority);
	bbMemFree(nativeTitle);
	bbMemFree(nativeDescription);
	bbMemFree(nativeIcon);
	return result;
}

void bmx_SteamAPI_ISteamTimeline_UpdateRangeTimelineEvent(ISteamTimeline * instancePtr, uint64 eventHandle,
	BBString * title, BBString * description, BBString * icon, uint32 priority,
	ETimelineEventClipPriority clipPriority) {
	char * nativeTitle = (char *)bbStringToUTF8String(title);
	char * nativeDescription = (char *)bbStringToUTF8String(description);
	char * nativeIcon = (char *)bbStringToUTF8String(icon);
	SteamAPI_ISteamTimeline_UpdateRangeTimelineEvent(
		instancePtr, eventHandle, nativeTitle, nativeDescription, nativeIcon, priority, clipPriority);
	bbMemFree(nativeTitle);
	bbMemFree(nativeDescription);
	bbMemFree(nativeIcon);
}

void bmx_SteamAPI_ISteamTimeline_EndRangeTimelineEvent(
	ISteamTimeline * instancePtr, uint64 eventHandle, float endOffsetSeconds) {
	SteamAPI_ISteamTimeline_EndRangeTimelineEvent(instancePtr, eventHandle, endOffsetSeconds);
}

void bmx_SteamAPI_ISteamTimeline_RemoveTimelineEvent(ISteamTimeline * instancePtr, uint64 eventHandle) {
	SteamAPI_ISteamTimeline_RemoveTimelineEvent(instancePtr, eventHandle);
}

uint64 bmx_SteamAPI_ISteamTimeline_DoesEventRecordingExist(MaxTimeline * timeline, uint64 eventHandle) {
	return timeline->DoesEventRecordingExist(eventHandle);
}

void bmx_SteamAPI_ISteamTimeline_StartGamePhase(ISteamTimeline * instancePtr) {
	SteamAPI_ISteamTimeline_StartGamePhase(instancePtr);
}

void bmx_SteamAPI_ISteamTimeline_EndGamePhase(ISteamTimeline * instancePtr) {
	SteamAPI_ISteamTimeline_EndGamePhase(instancePtr);
}

void bmx_SteamAPI_ISteamTimeline_SetGamePhaseID(ISteamTimeline * instancePtr, BBString * phaseID) {
	char * value = (char *)bbStringToUTF8String(phaseID);
	SteamAPI_ISteamTimeline_SetGamePhaseID(instancePtr, value);
	bbMemFree(value);
}

uint64 bmx_SteamAPI_ISteamTimeline_DoesGamePhaseRecordingExist(MaxTimeline * timeline, BBString * phaseID) {
	char * value = (char *)bbStringToUTF8String(phaseID);
	uint64 result = timeline->DoesGamePhaseRecordingExist(value);
	bbMemFree(value);
	return result;
}

void bmx_SteamAPI_ISteamTimeline_AddGamePhaseTag(ISteamTimeline * instancePtr, BBString * tagName,
	BBString * tagIcon, BBString * tagGroup, uint32 priority) {
	char * nativeName = (char *)bbStringToUTF8String(tagName);
	char * nativeIcon = (char *)bbStringToUTF8String(tagIcon);
	char * nativeGroup = (char *)bbStringToUTF8String(tagGroup);
	SteamAPI_ISteamTimeline_AddGamePhaseTag(instancePtr, nativeName, nativeIcon, nativeGroup, priority);
	bbMemFree(nativeName);
	bbMemFree(nativeIcon);
	bbMemFree(nativeGroup);
}

void bmx_SteamAPI_ISteamTimeline_SetGamePhaseAttribute(ISteamTimeline * instancePtr, BBString * attributeGroup,
	BBString * attributeValue, uint32 priority) {
	char * nativeGroup = (char *)bbStringToUTF8String(attributeGroup);
	char * nativeValue = (char *)bbStringToUTF8String(attributeValue);
	SteamAPI_ISteamTimeline_SetGamePhaseAttribute(instancePtr, nativeGroup, nativeValue, priority);
	bbMemFree(nativeGroup);
	bbMemFree(nativeValue);
}

void bmx_SteamAPI_ISteamTimeline_OpenOverlayToGamePhase(ISteamTimeline * instancePtr, BBString * phaseID) {
	char * value = (char *)bbStringToUTF8String(phaseID);
	SteamAPI_ISteamTimeline_OpenOverlayToGamePhase(instancePtr, value);
	bbMemFree(value);
}

void bmx_SteamAPI_ISteamTimeline_OpenOverlayToTimelineEvent(ISteamTimeline * instancePtr, uint64 eventHandle) {
	SteamAPI_ISteamTimeline_OpenOverlayToTimelineEvent(instancePtr, eventHandle);
}

// ISteamRemoteStorage ------------------------------------

class MaxRemoteStorageWriteRequest
{
private:
	ISteamRemoteStorage * instancePtr;
	BBObject * maxHandle;
	SteamAPICall_t callHandle;
	std::vector<uint8> data;
	CCallResult<MaxRemoteStorageWriteRequest, RemoteStorageFileWriteAsyncComplete_t> callResult;

public:
	MaxRemoteStorageWriteRequest(
		ISteamRemoteStorage * instancePtr, BBObject * maxHandle, const void * source, uint32 size)
		: instancePtr(instancePtr), maxHandle(maxHandle), callHandle(k_uAPICallInvalid),
		  data((const uint8 *)source, (const uint8 *)source + size) {
		BBRETAIN(maxHandle);
		g_remoteStorageWriteRequests.push_back(this);
	}

	~MaxRemoteStorageWriteRequest() {
		g_remoteStorageWriteRequests.erase(
			std::remove(g_remoteStorageWriteRequests.begin(), g_remoteStorageWriteRequests.end(), this),
			g_remoteStorageWriteRequests.end());
		BBRELEASE(maxHandle);
	}

	SteamAPICall_t Start(const char * file) {
		const void * buffer = data.empty() ? nullptr : data.data();
		callHandle = SteamAPI_ISteamRemoteStorage_FileWriteAsync(instancePtr, file, buffer, (uint32)data.size());
		if (callHandle != k_uAPICallInvalid) {
			callResult.Set(callHandle, this, &MaxRemoteStorageWriteRequest::OnComplete);
		}
		return callHandle;
	}

	void OnComplete(RemoteStorageFileWriteAsyncComplete_t * result, bool failure) {
		steam_steamsdk_TSteamRemoteStorage__OnFileWriteAsyncComplete(maxHandle, callHandle, result->m_eResult, failure);
		delete this;
	}
};

class MaxRemoteStorageReadRequest
{
private:
	ISteamRemoteStorage * instancePtr;
	BBObject * maxHandle;
	SteamAPICall_t callHandle;
	CCallResult<MaxRemoteStorageReadRequest, RemoteStorageFileReadAsyncComplete_t> callResult;

public:
	MaxRemoteStorageReadRequest(ISteamRemoteStorage * instancePtr, BBObject * maxHandle)
		: instancePtr(instancePtr), maxHandle(maxHandle), callHandle(k_uAPICallInvalid) {
		BBRETAIN(maxHandle);
		g_remoteStorageReadRequests.push_back(this);
	}

	~MaxRemoteStorageReadRequest() {
		g_remoteStorageReadRequests.erase(
			std::remove(g_remoteStorageReadRequests.begin(), g_remoteStorageReadRequests.end(), this),
			g_remoteStorageReadRequests.end());
		BBRELEASE(maxHandle);
	}

	SteamAPICall_t Start(const char * file, uint32 offset, uint32 bytesToRead) {
		callHandle = SteamAPI_ISteamRemoteStorage_FileReadAsync(instancePtr, file, offset, bytesToRead);
		if (callHandle != k_uAPICallInvalid) {
			callResult.Set(callHandle, this, &MaxRemoteStorageReadRequest::OnComplete);
		}
		return callHandle;
	}

	void OnComplete(RemoteStorageFileReadAsyncComplete_t * result, bool failure) {
		steam_steamsdk_TSteamRemoteStorage__OnFileReadAsyncComplete(
			maxHandle, callHandle, result->m_eResult, result->m_nOffset, result->m_cubRead, failure);
		delete this;
	}
};

class MaxRemoteStorage
{
private:
	ISteamRemoteStorage * instancePtr;
	BBObject * maxHandle;

public:
	STEAM_CALLBACK(MaxRemoteStorage, OnLocalFileChange, RemoteStorageLocalFileChange_t, m_CallbackLocalFileChange);

	MaxRemoteStorage(ISteamRemoteStorage * instancePtr, BBObject * handle)
		: instancePtr(instancePtr), maxHandle(handle),
		  m_CallbackLocalFileChange(this, &MaxRemoteStorage::OnLocalFileChange) {
	}

	SteamAPICall_t FileWriteAsync(const char * file, const void * data, uint32 size) {
		MaxRemoteStorageWriteRequest * request = new MaxRemoteStorageWriteRequest(instancePtr, maxHandle, data, size);
		SteamAPICall_t call = request->Start(file);
		if (call == k_uAPICallInvalid) {
			delete request;
		}
		return call;
	}

	SteamAPICall_t FileReadAsync(const char * file, uint32 offset, uint32 bytesToRead) {
		MaxRemoteStorageReadRequest * request = new MaxRemoteStorageReadRequest(instancePtr, maxHandle);
		SteamAPICall_t call = request->Start(file, offset, bytesToRead);
		if (call == k_uAPICallInvalid) {
			delete request;
		}
		return call;
	}
};

void MaxRemoteStorage::OnLocalFileChange(RemoteStorageLocalFileChange_t *) {
	steam_steamsdk_TSteamRemoteStorage__OnLocalFileChange(maxHandle);
}

static void CancelRemoteStorageRequests() {
	while (!g_remoteStorageWriteRequests.empty()) {
		delete g_remoteStorageWriteRequests.back();
	}
	while (!g_remoteStorageReadRequests.empty()) {
		delete g_remoteStorageReadRequests.back();
	}
}

void * bmx_steamsdk_register_steamremotestorage(ISteamRemoteStorage * instancePtr, BBObject * obj) {
	return new MaxRemoteStorage(instancePtr, obj);
}

void bmx_steamsdk_unregister_steamremotestorage(void * callbackPtr) {
	delete static_cast<MaxRemoteStorage *>(callbackPtr);
}

int bmx_SteamAPI_ISteamRemoteStorage_FileWrite(
	ISteamRemoteStorage * instancePtr, BBString * file, const void * data, int size) {
	char * name = (char *)bbStringToUTF8String(file);
	bool result = SteamAPI_ISteamRemoteStorage_FileWrite(instancePtr, name, data, size);
	bbMemFree(name);
	return result;
}

int bmx_SteamAPI_ISteamRemoteStorage_FileRead(
	ISteamRemoteStorage * instancePtr, BBString * file, void * data, int capacity) {
	char * name = (char *)bbStringToUTF8String(file);
	int result = SteamAPI_ISteamRemoteStorage_FileRead(instancePtr, name, data, capacity);
	bbMemFree(name);
	return result;
}

uint64 bmx_SteamAPI_ISteamRemoteStorage_FileWriteAsync(
	MaxRemoteStorage * storage, BBString * file, const void * data, uint32 size) {
	char * name = (char *)bbStringToUTF8String(file);
	uint64 result = storage->FileWriteAsync(name, data, size);
	bbMemFree(name);
	return result;
}

uint64 bmx_SteamAPI_ISteamRemoteStorage_FileReadAsync(
	MaxRemoteStorage * storage, BBString * file, uint32 offset, uint32 bytesToRead) {
	char * name = (char *)bbStringToUTF8String(file);
	uint64 result = storage->FileReadAsync(name, offset, bytesToRead);
	bbMemFree(name);
	return result;
}

int bmx_SteamAPI_ISteamRemoteStorage_FileReadAsyncComplete(
	ISteamRemoteStorage * instancePtr, uint64 readCall, void * data, uint32 bytesToRead) {
	return SteamAPI_ISteamRemoteStorage_FileReadAsyncComplete(instancePtr, readCall, data, bytesToRead);
}

int bmx_SteamAPI_ISteamRemoteStorage_FileForget(ISteamRemoteStorage * instancePtr, BBString * file) {
	char * name = (char *)bbStringToUTF8String(file);
	bool result = SteamAPI_ISteamRemoteStorage_FileForget(instancePtr, name);
	bbMemFree(name);
	return result;
}

int bmx_SteamAPI_ISteamRemoteStorage_FileDelete(ISteamRemoteStorage * instancePtr, BBString * file) {
	char * name = (char *)bbStringToUTF8String(file);
	bool result = SteamAPI_ISteamRemoteStorage_FileDelete(instancePtr, name);
	bbMemFree(name);
	return result;
}

int bmx_SteamAPI_ISteamRemoteStorage_SetSyncPlatforms(
	ISteamRemoteStorage * instancePtr, BBString * file, ERemoteStoragePlatform platforms) {
	char * name = (char *)bbStringToUTF8String(file);
	bool result = SteamAPI_ISteamRemoteStorage_SetSyncPlatforms(instancePtr, name, platforms);
	bbMemFree(name);
	return result;
}

uint64 bmx_SteamAPI_ISteamRemoteStorage_FileWriteStreamOpen(ISteamRemoteStorage * instancePtr, BBString * file) {
	char * name = (char *)bbStringToUTF8String(file);
	uint64 result = SteamAPI_ISteamRemoteStorage_FileWriteStreamOpen(instancePtr, name);
	bbMemFree(name);
	return result;
}

int bmx_SteamAPI_ISteamRemoteStorage_FileWriteStreamWriteChunk(
	ISteamRemoteStorage * instancePtr, uint64 streamHandle, const void * data, int size) {
	return SteamAPI_ISteamRemoteStorage_FileWriteStreamWriteChunk(instancePtr, streamHandle, data, size);
}

int bmx_SteamAPI_ISteamRemoteStorage_FileWriteStreamClose(ISteamRemoteStorage * instancePtr, uint64 streamHandle) {
	return SteamAPI_ISteamRemoteStorage_FileWriteStreamClose(instancePtr, streamHandle);
}

int bmx_SteamAPI_ISteamRemoteStorage_FileWriteStreamCancel(ISteamRemoteStorage * instancePtr, uint64 streamHandle) {
	return SteamAPI_ISteamRemoteStorage_FileWriteStreamCancel(instancePtr, streamHandle);
}

int bmx_SteamAPI_ISteamRemoteStorage_FileExists(ISteamRemoteStorage * instancePtr, BBString * file) {
	char * name = (char *)bbStringToUTF8String(file);
	bool result = SteamAPI_ISteamRemoteStorage_FileExists(instancePtr, name);
	bbMemFree(name);
	return result;
}

int bmx_SteamAPI_ISteamRemoteStorage_FilePersisted(ISteamRemoteStorage * instancePtr, BBString * file) {
	char * name = (char *)bbStringToUTF8String(file);
	bool result = SteamAPI_ISteamRemoteStorage_FilePersisted(instancePtr, name);
	bbMemFree(name);
	return result;
}

int bmx_SteamAPI_ISteamRemoteStorage_GetFileSize(ISteamRemoteStorage * instancePtr, BBString * file) {
	char * name = (char *)bbStringToUTF8String(file);
	int result = SteamAPI_ISteamRemoteStorage_GetFileSize(instancePtr, name);
	bbMemFree(name);
	return result;
}

int64 bmx_SteamAPI_ISteamRemoteStorage_GetFileTimestamp(ISteamRemoteStorage * instancePtr, BBString * file) {
	char * name = (char *)bbStringToUTF8String(file);
	int64 result = SteamAPI_ISteamRemoteStorage_GetFileTimestamp(instancePtr, name);
	bbMemFree(name);
	return result;
}

ERemoteStoragePlatform bmx_SteamAPI_ISteamRemoteStorage_GetSyncPlatforms(
	ISteamRemoteStorage * instancePtr, BBString * file) {
	char * name = (char *)bbStringToUTF8String(file);
	ERemoteStoragePlatform result = SteamAPI_ISteamRemoteStorage_GetSyncPlatforms(instancePtr, name);
	bbMemFree(name);
	return result;
}

int bmx_SteamAPI_ISteamRemoteStorage_GetFileCount(ISteamRemoteStorage * instancePtr) {
	return SteamAPI_ISteamRemoteStorage_GetFileCount(instancePtr);
}

BBString * bmx_SteamAPI_ISteamRemoteStorage_GetFileNameAndSize(
	ISteamRemoteStorage * instancePtr, int index, int * size) {
	const char * name = SteamAPI_ISteamRemoteStorage_GetFileNameAndSize(instancePtr, index, size);
	return name ? bbStringFromUTF8String((unsigned char *)name) : &bbEmptyString;
}

int bmx_SteamAPI_ISteamRemoteStorage_GetQuota(
	ISteamRemoteStorage * instancePtr, uint64 * totalBytes, uint64 * availableBytes) {
	return SteamAPI_ISteamRemoteStorage_GetQuota(instancePtr, totalBytes, availableBytes);
}

int bmx_SteamAPI_ISteamRemoteStorage_IsCloudEnabledForAccount(ISteamRemoteStorage * instancePtr) {
	return SteamAPI_ISteamRemoteStorage_IsCloudEnabledForAccount(instancePtr);
}

int bmx_SteamAPI_ISteamRemoteStorage_IsCloudEnabledForApp(ISteamRemoteStorage * instancePtr) {
	return SteamAPI_ISteamRemoteStorage_IsCloudEnabledForApp(instancePtr);
}

void bmx_SteamAPI_ISteamRemoteStorage_SetCloudEnabledForApp(ISteamRemoteStorage * instancePtr, int enabled) {
	SteamAPI_ISteamRemoteStorage_SetCloudEnabledForApp(instancePtr, enabled);
}

int bmx_SteamAPI_ISteamRemoteStorage_GetLocalFileChangeCount(ISteamRemoteStorage * instancePtr) {
	return SteamAPI_ISteamRemoteStorage_GetLocalFileChangeCount(instancePtr);
}

BBString * bmx_SteamAPI_ISteamRemoteStorage_GetLocalFileChange(ISteamRemoteStorage * instancePtr, int index,
	ERemoteStorageLocalFileChange * changeType, ERemoteStorageFilePathType * pathType) {
	const char * path = SteamAPI_ISteamRemoteStorage_GetLocalFileChange(instancePtr, index, changeType, pathType);
	return path ? bbStringFromUTF8String((unsigned char *)path) : &bbEmptyString;
}

int bmx_SteamAPI_ISteamRemoteStorage_BeginFileWriteBatch(ISteamRemoteStorage * instancePtr) {
	return SteamAPI_ISteamRemoteStorage_BeginFileWriteBatch(instancePtr);
}

int bmx_SteamAPI_ISteamRemoteStorage_EndFileWriteBatch(ISteamRemoteStorage * instancePtr) {
	return SteamAPI_ISteamRemoteStorage_EndFileWriteBatch(instancePtr);
}

BBString * bmx_SteamAPI_ISteamApps_GetLaunchCommandLine(ISteamApps * instancePtr) {
	char commandLine[BUFFER_SIZE] = {0};
	int length = SteamAPI_ISteamApps_GetLaunchCommandLine(instancePtr, commandLine, BUFFER_SIZE);
	if (length <= 0) {
		return &bbEmptyString;
	}
	return bbStringFromUTF8String((unsigned char *)commandLine);
}

class MaxApps
{
private:
	ISteamApps * instancePtr;
	BBObject * maxHandle;
	CCallResult<MaxApps, FileDetailsResult_t> m_FileDetailsCallResult;

public:
	STEAM_CALLBACK(MaxApps, OnDlcInstalled, DlcInstalled_t, m_CallbackDlcInstalled);
	STEAM_CALLBACK(MaxApps, OnNewUrlLaunchParameters, NewUrlLaunchParameters_t, m_CallbackNewUrlLaunchParameters);
	STEAM_CALLBACK(MaxApps, OnAppProofOfPurchaseKey, AppProofOfPurchaseKeyResponse_t, m_CallbackAppProofOfPurchaseKey);
	STEAM_CALLBACK(MaxApps, OnTimedTrialStatus, TimedTrialStatus_t, m_CallbackTimedTrialStatus);

	MaxApps(ISteamApps * instancePtr, BBObject * handle)
		: instancePtr(instancePtr), maxHandle(handle), m_CallbackDlcInstalled(this, &MaxApps::OnDlcInstalled),
		  m_CallbackNewUrlLaunchParameters(this, &MaxApps::OnNewUrlLaunchParameters),
		  m_CallbackAppProofOfPurchaseKey(this, &MaxApps::OnAppProofOfPurchaseKey),
		  m_CallbackTimedTrialStatus(this, &MaxApps::OnTimedTrialStatus) {
	}

	void GetFileDetails(const char * fileName) {
		SteamAPICall_t call = SteamAPI_ISteamApps_GetFileDetails(instancePtr, fileName);
		m_FileDetailsCallResult.Set(call, this, &MaxApps::OnFileDetails);
	}

	void OnFileDetails(FileDetailsResult_t * result, bool failure) {
		char sha1[41];
		for (int i = 0; i < 20; ++i)
			std::snprintf(sha1 + i * 2, 3, "%02x", result->m_FileSHA[i]);
		steam_steamsdk_TSteamApps__OnFileDetails(maxHandle, result->m_eResult, result->m_ulFileSize,
			bbStringFromUTF8String((unsigned char *)sha1), result->m_unFlags, failure);
	}
};

void MaxApps::OnDlcInstalled(DlcInstalled_t * result) {
	steam_steamsdk_TSteamApps__OnDlcInstalled(maxHandle, result->m_nAppID);
}
void MaxApps::OnNewUrlLaunchParameters(NewUrlLaunchParameters_t *) {
	steam_steamsdk_TSteamApps__OnNewUrlLaunchParameters(maxHandle);
}
void MaxApps::OnAppProofOfPurchaseKey(AppProofOfPurchaseKeyResponse_t * result) {
	steam_steamsdk_TSteamApps__OnAppProofOfPurchaseKey(
		maxHandle, result->m_eResult, result->m_nAppID, bbStringFromUTF8String((unsigned char *)result->m_rgchKey));
}
void MaxApps::OnTimedTrialStatus(TimedTrialStatus_t * result) {
	steam_steamsdk_TSteamApps__OnTimedTrialStatus(
		maxHandle, result->m_unAppID, result->m_bIsOffline, result->m_unSecondsAllowed, result->m_unSecondsPlayed);
}

void * bmx_steamsdk_register_steamapps(ISteamApps * instancePtr, BBObject * obj) {
	return new MaxApps(instancePtr, obj);
}
void bmx_steamsdk_unregister_steamapps(void * callbackPtr) {
	delete static_cast<MaxApps *>(callbackPtr);
}
int bmx_SteamAPI_ISteamApps_BIsSubscribed(ISteamApps * instancePtr) {
	return SteamAPI_ISteamApps_BIsSubscribed(instancePtr);
}
int bmx_SteamAPI_ISteamApps_BIsLowViolence(ISteamApps * instancePtr) {
	return SteamAPI_ISteamApps_BIsLowViolence(instancePtr);
}
int bmx_SteamAPI_ISteamApps_BIsCybercafe(ISteamApps * instancePtr) {
	return SteamAPI_ISteamApps_BIsCybercafe(instancePtr);
}
int bmx_SteamAPI_ISteamApps_BIsVACBanned(ISteamApps * instancePtr) {
	return SteamAPI_ISteamApps_BIsVACBanned(instancePtr);
}
BBString * bmx_SteamAPI_ISteamApps_GetCurrentGameLanguage(ISteamApps * instancePtr) {
	return bbStringFromUTF8String((unsigned char *)SteamAPI_ISteamApps_GetCurrentGameLanguage(instancePtr));
}
BBString * bmx_SteamAPI_ISteamApps_GetAvailableGameLanguages(ISteamApps * instancePtr) {
	return bbStringFromUTF8String((unsigned char *)SteamAPI_ISteamApps_GetAvailableGameLanguages(instancePtr));
}
int bmx_SteamAPI_ISteamApps_BIsSubscribedApp(ISteamApps * instancePtr, uint32 appID) {
	return SteamAPI_ISteamApps_BIsSubscribedApp(instancePtr, appID);
}
int bmx_SteamAPI_ISteamApps_BIsDlcInstalled(ISteamApps * instancePtr, uint32 appID) {
	return SteamAPI_ISteamApps_BIsDlcInstalled(instancePtr, appID);
}
uint32 bmx_SteamAPI_ISteamApps_GetEarliestPurchaseUnixTime(ISteamApps * instancePtr, uint32 appID) {
	return SteamAPI_ISteamApps_GetEarliestPurchaseUnixTime(instancePtr, appID);
}
int bmx_SteamAPI_ISteamApps_BIsSubscribedFromFreeWeekend(ISteamApps * instancePtr) {
	return SteamAPI_ISteamApps_BIsSubscribedFromFreeWeekend(instancePtr);
}
int bmx_SteamAPI_ISteamApps_GetDLCCount(ISteamApps * instancePtr) {
	return SteamAPI_ISteamApps_GetDLCCount(instancePtr);
}
int bmx_SteamAPI_ISteamApps_BGetDLCDataByIndex(
	ISteamApps * instancePtr, int index, uint32 * appID, int * available, BBString ** name) {
	bool isAvailable = false;
	char buffer[BUFFER_SIZE] = {0};
	bool result = SteamAPI_ISteamApps_BGetDLCDataByIndex(instancePtr, index, appID, &isAvailable, buffer, BUFFER_SIZE);
	*available = isAvailable;
	*name = bbStringFromUTF8String((unsigned char *)buffer);
	return result;
}
void bmx_SteamAPI_ISteamApps_InstallDLC(ISteamApps * instancePtr, uint32 appID) {
	SteamAPI_ISteamApps_InstallDLC(instancePtr, appID);
}
void bmx_SteamAPI_ISteamApps_UninstallDLC(ISteamApps * instancePtr, uint32 appID) {
	SteamAPI_ISteamApps_UninstallDLC(instancePtr, appID);
}
void bmx_SteamAPI_ISteamApps_RequestAppProofOfPurchaseKey(ISteamApps * instancePtr, uint32 appID) {
	SteamAPI_ISteamApps_RequestAppProofOfPurchaseKey(instancePtr, appID);
}
int bmx_SteamAPI_ISteamApps_GetCurrentBetaName(ISteamApps * instancePtr, BBString ** name) {
	char buffer[BUFFER_SIZE] = {0};
	bool result = SteamAPI_ISteamApps_GetCurrentBetaName(instancePtr, buffer, BUFFER_SIZE);
	*name = bbStringFromUTF8String((unsigned char *)buffer);
	return result;
}
int bmx_SteamAPI_ISteamApps_MarkContentCorrupt(ISteamApps * instancePtr, int missingFilesOnly) {
	return SteamAPI_ISteamApps_MarkContentCorrupt(instancePtr, missingFilesOnly);
}
uint32 bmx_SteamAPI_ISteamApps_GetInstalledDepots(
	ISteamApps * instancePtr, uint32 appID, uint32 * depots, uint32 maxDepots) {
	return SteamAPI_ISteamApps_GetInstalledDepots(instancePtr, appID, depots, maxDepots);
}
uint32 bmx_SteamAPI_ISteamApps_GetAppInstallDir(ISteamApps * instancePtr, uint32 appID, BBString ** folder) {
	char buffer[VALUE_SIZE] = {0};
	uint32 result = SteamAPI_ISteamApps_GetAppInstallDir(instancePtr, appID, buffer, VALUE_SIZE);
	*folder = bbStringFromUTF8String((unsigned char *)buffer);
	return result;
}
int bmx_SteamAPI_ISteamApps_BIsAppInstalled(ISteamApps * instancePtr, uint32 appID) {
	return SteamAPI_ISteamApps_BIsAppInstalled(instancePtr, appID);
}
uint64 bmx_SteamAPI_ISteamApps_GetAppOwner(ISteamApps * instancePtr) {
	return SteamAPI_ISteamApps_GetAppOwner(instancePtr);
}
BBString * bmx_SteamAPI_ISteamApps_GetLaunchQueryParam(ISteamApps * instancePtr, BBString * key) {
	char * k = (char *)bbStringToUTF8String(key);
	const char * value = SteamAPI_ISteamApps_GetLaunchQueryParam(instancePtr, k);
	BBString * result = bbStringFromUTF8String((unsigned char *)value);
	bbMemFree(k);
	return result;
}
int bmx_SteamAPI_ISteamApps_GetDlcDownloadProgress(
	ISteamApps * instancePtr, uint32 appID, uint64 * downloaded, uint64 * total) {
	return SteamAPI_ISteamApps_GetDlcDownloadProgress(instancePtr, appID, downloaded, total);
}
int bmx_SteamAPI_ISteamApps_GetAppBuildId(ISteamApps * instancePtr) {
	return SteamAPI_ISteamApps_GetAppBuildId(instancePtr);
}
void bmx_SteamAPI_ISteamApps_RequestAllProofOfPurchaseKeys(ISteamApps * instancePtr) {
	SteamAPI_ISteamApps_RequestAllProofOfPurchaseKeys(instancePtr);
}
void bmx_SteamAPI_ISteamApps_GetFileDetails(MaxApps * apps, BBString * fileName) {
	char * f = (char *)bbStringToUTF8String(fileName);
	apps->GetFileDetails(f);
	bbMemFree(f);
}
int bmx_SteamAPI_ISteamApps_BIsSubscribedFromFamilySharing(ISteamApps * instancePtr) {
	return SteamAPI_ISteamApps_BIsSubscribedFromFamilySharing(instancePtr);
}
int bmx_SteamAPI_ISteamApps_BIsTimedTrial(ISteamApps * instancePtr, uint32 * secondsAllowed, uint32 * secondsPlayed) {
	return SteamAPI_ISteamApps_BIsTimedTrial(instancePtr, secondsAllowed, secondsPlayed);
}

int bmx_SteamAPI_ISteamApps_SetDlcContext(ISteamApps * instancePtr, uint32 appID) {
	return SteamAPI_ISteamApps_SetDlcContext(instancePtr, appID);
}

int bmx_SteamAPI_ISteamApps_GetNumBetas(ISteamApps * instancePtr, int * available, int * privateBetas) {
	return SteamAPI_ISteamApps_GetNumBetas(instancePtr, available, privateBetas);
}

int bmx_SteamAPI_ISteamApps_GetBetaInfo(ISteamApps * instancePtr, int index, uint32 * flags, uint32 * buildID,
	BBString ** name, BBString ** description, uint32 * lastUpdated) {
	char nameBuffer[BUFFER_SIZE] = {0};
	char descriptionBuffer[BUFFER_SIZE] = {0};
	bool result = SteamAPI_ISteamApps_GetBetaInfo(instancePtr, index, flags, buildID, nameBuffer, BUFFER_SIZE,
		descriptionBuffer, BUFFER_SIZE, lastUpdated);
	*name = bbStringFromUTF8String((unsigned char *)nameBuffer);
	*description = bbStringFromUTF8String((unsigned char *)descriptionBuffer);
	return result;
}

int bmx_SteamAPI_ISteamApps_SetActiveBeta(ISteamApps * instancePtr, BBString * name) {
	char * value = (char *)bbStringToUTF8String(name);
	bool result = SteamAPI_ISteamApps_SetActiveBeta(instancePtr, value);
	bbMemFree(value);
	return result;
}

void bmx_SteamAPI_ISteamApps_SetGamePerformanceSetting(
	ISteamApps * instancePtr, EGamePerformanceSetting setting) {
	SteamAPI_ISteamApps_SetGamePerformanceSetting(instancePtr, setting);
}

void bmx_SteamAPI_ISteamApps_SetGameRenderResolution(ISteamApps * instancePtr, uint32 width, uint32 height) {
	SteamAPI_ISteamApps_SetGameRenderResolution(instancePtr, width, height);
}

class MaxUser
{
private:
	ISteamUser * instancePtr;
	BBObject * maxHandle;
	CCallResult<MaxUser, EncryptedAppTicketResponse_t> m_EncryptedAppTicketCallResult;
	CCallResult<MaxUser, StoreAuthURLResponse_t> m_StoreAuthURLCallResult;
	CCallResult<MaxUser, MarketEligibilityResponse_t> m_MarketEligibilityCallResult;
	CCallResult<MaxUser, DurationControl_t> m_DurationControlCallResult;

public:
	STEAM_CALLBACK(MaxUser, OnValidateAuthTicket, ValidateAuthTicketResponse_t, m_CallbackValidateAuthTicket);
	STEAM_CALLBACK(MaxUser, OnGetAuthSessionTicket, GetAuthSessionTicketResponse_t, m_CallbackGetAuthSessionTicket);
	STEAM_CALLBACK(MaxUser, OnGetTicketForWebApi, GetTicketForWebApiResponse_t, m_CallbackGetTicketForWebApi);

	MaxUser(ISteamUser * instancePtr, BBObject * handle)
		: instancePtr(instancePtr), maxHandle(handle),
		  m_CallbackValidateAuthTicket(this, &MaxUser::OnValidateAuthTicket),
		  m_CallbackGetAuthSessionTicket(this, &MaxUser::OnGetAuthSessionTicket),
		  m_CallbackGetTicketForWebApi(this, &MaxUser::OnGetTicketForWebApi) {
	}

	void RequestEncryptedAppTicket(void * data, int size) {
		SteamAPICall_t call = SteamAPI_ISteamUser_RequestEncryptedAppTicket(instancePtr, data, size);
		m_EncryptedAppTicketCallResult.Set(call, this, &MaxUser::OnEncryptedAppTicket);
	}
	void RequestStoreAuthURL(const char * url) {
		SteamAPICall_t call = SteamAPI_ISteamUser_RequestStoreAuthURL(instancePtr, url);
		m_StoreAuthURLCallResult.Set(call, this, &MaxUser::OnStoreAuthURL);
	}
	void GetMarketEligibility() {
		SteamAPICall_t call = SteamAPI_ISteamUser_GetMarketEligibility(instancePtr);
		m_MarketEligibilityCallResult.Set(call, this, &MaxUser::OnMarketEligibility);
	}
	void GetDurationControl() {
		SteamAPICall_t call = SteamAPI_ISteamUser_GetDurationControl(instancePtr);
		m_DurationControlCallResult.Set(call, this, &MaxUser::OnDurationControl);
	}
	void OnEncryptedAppTicket(EncryptedAppTicketResponse_t * result, bool failure) {
		steam_steamsdk_TSteamUser__OnEncryptedAppTicket(maxHandle, result->m_eResult, failure);
	}
	void OnStoreAuthURL(StoreAuthURLResponse_t * result, bool failure) {
		steam_steamsdk_TSteamUser__OnStoreAuthURL(
			maxHandle, bbStringFromUTF8String((unsigned char *)result->m_szURL), failure);
	}
	void OnMarketEligibility(MarketEligibilityResponse_t * result, bool failure) {
		steam_steamsdk_TSteamUser__OnMarketEligibility(maxHandle, result->m_bAllowed, result->m_eNotAllowedReason,
			result->m_rtAllowedAtTime, result->m_cdaySteamGuardRequiredDays, result->m_cdayNewDeviceCooldown, failure);
	}
	void OnDurationControl(DurationControl_t * result, bool failure) {
		steam_steamsdk_TSteamUser__OnDurationControl(maxHandle, result->m_eResult, result->m_appid,
			result->m_bApplicable, result->m_csecsLast5h, result->m_progress, result->m_notification,
			result->m_csecsToday, result->m_csecsRemaining, failure);
	}
};

void MaxUser::OnValidateAuthTicket(ValidateAuthTicketResponse_t * result) {
	steam_steamsdk_TSteamUser__OnValidateAuthTicket(maxHandle, result->m_SteamID.ConvertToUint64(),
		result->m_eAuthSessionResponse, result->m_OwnerSteamID.ConvertToUint64());
}
void MaxUser::OnGetAuthSessionTicket(GetAuthSessionTicketResponse_t * result) {
	steam_steamsdk_TSteamUser__OnGetAuthSessionTicket(maxHandle, result->m_hAuthTicket, result->m_eResult);
}

void MaxUser::OnGetTicketForWebApi(GetTicketForWebApiResponse_t * result) {
	steam_steamsdk_TSteamUser__OnGetTicketForWebApi(
		maxHandle, result->m_hAuthTicket, result->m_eResult, result->m_rgubTicket, result->m_cubTicket);
}

void * bmx_steamsdk_register_steamuser(ISteamUser * instancePtr, BBObject * obj) {
	return new MaxUser(instancePtr, obj);
}
void bmx_steamsdk_unregister_steamuser(void * callbackPtr) {
	delete static_cast<MaxUser *>(callbackPtr);
}
int bmx_SteamAPI_ISteamUser_GetHSteamUser(ISteamUser * instancePtr) {
	return SteamAPI_ISteamUser_GetHSteamUser(instancePtr);
}
int bmx_SteamAPI_ISteamUser_GetUserDataFolder(ISteamUser * instancePtr, BBString ** folder) {
	char buffer[VALUE_SIZE] = {0};
	bool result = SteamAPI_ISteamUser_GetUserDataFolder(instancePtr, buffer, VALUE_SIZE);
	*folder = bbStringFromUTF8String((unsigned char *)buffer);
	return result;
}
void bmx_SteamAPI_ISteamUser_StartVoiceRecording(ISteamUser * instancePtr) {
	SteamAPI_ISteamUser_StartVoiceRecording(instancePtr);
}
void bmx_SteamAPI_ISteamUser_StopVoiceRecording(ISteamUser * instancePtr) {
	SteamAPI_ISteamUser_StopVoiceRecording(instancePtr);
}
EVoiceResult bmx_SteamAPI_ISteamUser_GetAvailableVoice(ISteamUser * instancePtr, uint32 * compressedBytes) {
	return SteamAPI_ISteamUser_GetAvailableVoice(instancePtr, compressedBytes, nullptr, 0);
}
EVoiceResult bmx_SteamAPI_ISteamUser_GetVoice(
	ISteamUser * instancePtr, void * destination, uint32 capacity, uint32 * bytesWritten) {
	return SteamAPI_ISteamUser_GetVoice(
		instancePtr, true, destination, capacity, bytesWritten, false, nullptr, 0, nullptr, 0);
}
EVoiceResult bmx_SteamAPI_ISteamUser_DecompressVoice(ISteamUser * instancePtr, const void * compressed,
	uint32 compressedSize, void * destination, uint32 capacity, uint32 * bytesWritten, uint32 sampleRate) {
	return SteamAPI_ISteamUser_DecompressVoice(
		instancePtr, compressed, compressedSize, destination, capacity, bytesWritten, sampleRate);
}
uint32 bmx_SteamAPI_ISteamUser_GetVoiceOptimalSampleRate(ISteamUser * instancePtr) {
	return SteamAPI_ISteamUser_GetVoiceOptimalSampleRate(instancePtr);
}
uint32 bmx_SteamAPI_ISteamUser_GetAuthSessionTicket(
	ISteamUser * instancePtr, void * ticket, int capacity, uint32 * ticketSize) {
	return SteamAPI_ISteamUser_GetAuthSessionTicket(instancePtr, ticket, capacity, ticketSize, nullptr);
}

uint32 bmx_SteamAPI_ISteamUser_GetAuthTicketForWebApi(ISteamUser * instancePtr, BBString * identity) {
	char * value = (char *)bbStringToUTF8String(identity);
	uint32 result = SteamAPI_ISteamUser_GetAuthTicketForWebApi(instancePtr, value);
	bbMemFree(value);
	return result;
}
EBeginAuthSessionResult bmx_SteamAPI_ISteamUser_BeginAuthSession(
	ISteamUser * instancePtr, const void * ticket, int ticketSize, uint64 steamID) {
	return SteamAPI_ISteamUser_BeginAuthSession(instancePtr, ticket, ticketSize, steamID);
}
void bmx_SteamAPI_ISteamUser_EndAuthSession(ISteamUser * instancePtr, uint64 steamID) {
	SteamAPI_ISteamUser_EndAuthSession(instancePtr, steamID);
}
void bmx_SteamAPI_ISteamUser_CancelAuthTicket(ISteamUser * instancePtr, uint32 authTicket) {
	SteamAPI_ISteamUser_CancelAuthTicket(instancePtr, authTicket);
}
EUserHasLicenseForAppResult bmx_SteamAPI_ISteamUser_UserHasLicenseForApp(
	ISteamUser * instancePtr, uint64 steamID, uint32 appID) {
	return SteamAPI_ISteamUser_UserHasLicenseForApp(instancePtr, steamID, appID);
}
int bmx_SteamAPI_ISteamUser_BIsBehindNAT(ISteamUser * instancePtr) {
	return SteamAPI_ISteamUser_BIsBehindNAT(instancePtr);
}
void bmx_SteamAPI_ISteamUser_AdvertiseGame(ISteamUser * instancePtr, uint64 steamIDGameServer, uint32 ip, uint16 port) {
	SteamAPI_ISteamUser_AdvertiseGame(instancePtr, steamIDGameServer, ip, port);
}
void bmx_SteamAPI_ISteamUser_TrackAppUsageEvent(
	ISteamUser * instancePtr, uint64 gameID, int appUsageEvent, BBString * extraInfo) {
	char * value = (char *)bbStringToUTF8String(extraInfo);
	SteamAPI_ISteamUser_TrackAppUsageEvent(instancePtr, gameID, appUsageEvent, value);
	bbMemFree(value);
}
void bmx_SteamAPI_ISteamUser_RequestEncryptedAppTicket(MaxUser * user, void * data, int size) {
	user->RequestEncryptedAppTicket(data, size);
}
int bmx_SteamAPI_ISteamUser_GetEncryptedAppTicket(
	ISteamUser * instancePtr, void * ticket, int capacity, uint32 * ticketSize) {
	return SteamAPI_ISteamUser_GetEncryptedAppTicket(instancePtr, ticket, capacity, ticketSize);
}
int bmx_SteamAPI_ISteamUser_GetGameBadgeLevel(ISteamUser * instancePtr, int series, int foil) {
	return SteamAPI_ISteamUser_GetGameBadgeLevel(instancePtr, series, foil);
}
int bmx_SteamAPI_ISteamUser_GetPlayerSteamLevel(ISteamUser * instancePtr) {
	return SteamAPI_ISteamUser_GetPlayerSteamLevel(instancePtr);
}
void bmx_SteamAPI_ISteamUser_RequestStoreAuthURL(MaxUser * user, BBString * redirectURL) {
	char * url = (char *)bbStringToUTF8String(redirectURL);
	user->RequestStoreAuthURL(url);
	bbMemFree(url);
}
int bmx_SteamAPI_ISteamUser_BIsPhoneVerified(ISteamUser * instancePtr) {
	return SteamAPI_ISteamUser_BIsPhoneVerified(instancePtr);
}
int bmx_SteamAPI_ISteamUser_BIsTwoFactorEnabled(ISteamUser * instancePtr) {
	return SteamAPI_ISteamUser_BIsTwoFactorEnabled(instancePtr);
}
int bmx_SteamAPI_ISteamUser_BIsPhoneIdentifying(ISteamUser * instancePtr) {
	return SteamAPI_ISteamUser_BIsPhoneIdentifying(instancePtr);
}
int bmx_SteamAPI_ISteamUser_BIsPhoneRequiringVerification(ISteamUser * instancePtr) {
	return SteamAPI_ISteamUser_BIsPhoneRequiringVerification(instancePtr);
}
void bmx_SteamAPI_ISteamUser_GetMarketEligibility(MaxUser * user) {
	user->GetMarketEligibility();
}
void bmx_SteamAPI_ISteamUser_GetDurationControl(MaxUser * user) {
	user->GetDurationControl();
}
int bmx_SteamAPI_ISteamUser_BSetDurationControlOnlineState(
	ISteamUser * instancePtr, EDurationControlOnlineState state) {
	return SteamAPI_ISteamUser_BSetDurationControlOnlineState(instancePtr, state);
}

int bmx_SteamAPI_ISteamUser_BLoggedOn(ISteamUser * instancePtr) {
	return SteamAPI_ISteamUser_BLoggedOn(instancePtr);
}

uint64 bmx_SteamAPI_ISteamUser_GetSteamID(ISteamUser * instancePtr) {
	return SteamAPI_ISteamUser_GetSteamID(instancePtr);
}

// ISteamUtils --------------------------------------------

class MaxUtils
{
private:
	ISteamUtils * instancePtr;
	BBObject * maxHandle;

public:
	STEAM_CALLBACK(MaxUtils, OnCheckFileSignature, CheckFileSignature_t, m_CallbackCheckFileSignature);
	STEAM_CALLBACK(
		MaxUtils, OnGamepadTextInputDismissed, GamepadTextInputDismissed_t, m_CallbackGamepadTextInputDismissed);
	STEAM_CALLBACK(MaxUtils, OnLowBatteryPower, LowBatteryPower_t, m_CallbackLowBatteryPower);
	STEAM_CALLBACK(MaxUtils, OnSteamShutdown, SteamShutdown_t, m_CallbackSteamShutdown);

	MaxUtils(ISteamUtils * instancePtr, BBObject * handle);
	~MaxUtils() = default;
};

MaxUtils::MaxUtils(ISteamUtils * instancePtr, BBObject * handle)
	: instancePtr(instancePtr), maxHandle(handle), m_CallbackCheckFileSignature(this, &MaxUtils::OnCheckFileSignature),
	  m_CallbackGamepadTextInputDismissed(this, &MaxUtils::OnGamepadTextInputDismissed),
	  m_CallbackLowBatteryPower(this, &MaxUtils::OnLowBatteryPower),
	  m_CallbackSteamShutdown(this, &MaxUtils::OnSteamShutdown) {
}

void MaxUtils::OnCheckFileSignature(CheckFileSignature_t * result) {
	steam_steamsdk_TSteamUtils__OnCheckFileSignature(maxHandle, result->m_eCheckFileSignature);
}

void MaxUtils::OnGamepadTextInputDismissed(GamepadTextInputDismissed_t * result) {
	steam_steamsdk_TSteamUtils__OnGamepadTextInputDismissed(maxHandle, result->m_bSubmitted, result->m_unSubmittedText);
}

void MaxUtils::OnLowBatteryPower(LowBatteryPower_t * result) {
	steam_steamsdk_TSteamUtils__OnLowBatteryPower(maxHandle, result->m_nMinutesBatteryLeft);
}

void MaxUtils::OnSteamShutdown(SteamShutdown_t * result) {
	steam_steamsdk_TSteamUtils__OnSteamShutdown(maxHandle);
}

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void * bmx_steamsdk_register_steamutils(ISteamUtils * instancePtr, BBObject * obj) {
	return new MaxUtils(instancePtr, obj);
}

void bmx_steamsdk_unregister_steamutils(void * callbackPtr) {
	delete static_cast<MaxUtils *>(callbackPtr);
}

uint32 bmx_SteamAPI_ISteamUtils_GetSecondsSinceAppActive(ISteamUtils * instancePtr) {
	return SteamAPI_ISteamUtils_GetSecondsSinceAppActive(instancePtr);
}

uint32 bmx_SteamAPI_ISteamUtils_GetSecondsSinceComputerActive(ISteamUtils * instancePtr) {
	return SteamAPI_ISteamUtils_GetSecondsSinceComputerActive(instancePtr);
}

uint32 bmx_SteamAPI_ISteamUtils_GetServerRealTime(ISteamUtils * instancePtr) {
	return SteamAPI_ISteamUtils_GetServerRealTime(instancePtr);
}

BBString * bmx_SteamAPI_ISteamUtils_GetIPCountry(ISteamUtils * instancePtr) {
	return bbStringFromUTF8String((unsigned char *)SteamAPI_ISteamUtils_GetIPCountry(instancePtr));
}

uint32 bmx_SteamAPI_ISteamUtils_GetAppID(ISteamUtils * instancePtr) {
	return SteamAPI_ISteamUtils_GetAppID(instancePtr);
}

int bmx_SteamAPI_ISteamUtils_IsOverlayEnabled(ISteamUtils * instancePtr) {
	return SteamAPI_ISteamUtils_IsOverlayEnabled(instancePtr);
}

int bmx_SteamAPI_ISteamUtils_IsSteamInBigPictureMode(ISteamUtils * instancePtr) {
	return SteamAPI_ISteamUtils_IsSteamInBigPictureMode(instancePtr);
}

int bmx_SteamAPI_ISteamUtils_IsSteamRunningInVR(ISteamUtils * instancePtr) {
	return SteamAPI_ISteamUtils_IsSteamRunningInVR(instancePtr);
}

int bmx_SteamAPI_ISteamUtils_IsVRHeadsetStreamingEnabled(ISteamUtils * instancePtr) {
	return SteamAPI_ISteamUtils_IsVRHeadsetStreamingEnabled(instancePtr);
}

void bmx_SteamAPI_ISteamUtils_SetOverlayNotificationInset(
	ISteamUtils * instancePtr, int horizontalInset, int verticalInset) {
	SteamAPI_ISteamUtils_SetOverlayNotificationInset(instancePtr, horizontalInset, verticalInset);
}

void bmx_SteamAPI_ISteamUtils_SetOverlayNotificationPosition(
	ISteamUtils * instancePtr, ENotificationPosition position) {
	SteamAPI_ISteamUtils_SetOverlayNotificationPosition(instancePtr, position);
}

void bmx_SteamAPI_ISteamUtils_SetVRHeadsetStreamingEnabled(ISteamUtils * instancePtr, int enabled) {
	SteamAPI_ISteamUtils_SetVRHeadsetStreamingEnabled(instancePtr, enabled);
}

void bmx_SteamAPI_ISteamUtils_StartVRDashboard(ISteamUtils * instancePtr) {
	SteamAPI_ISteamUtils_StartVRDashboard(instancePtr);
}

int bmx_SteamAPI_ISteamUtils_BOverlayNeedsPresent(ISteamUtils * instancePtr) {
	return SteamAPI_ISteamUtils_BOverlayNeedsPresent(instancePtr);
}

int bmx_SteamAPI_ISteamUtils_GetCurrentBatteryPower(ISteamUtils * instancePtr) {
	return SteamAPI_ISteamUtils_GetCurrentBatteryPower(instancePtr);
}

int bmx_SteamAPI_ISteamUtils_GetEnteredGamepadTextInput(ISteamUtils * instancePtr, BBString ** txt) {
	char buf[2048];
	int res = SteamAPI_ISteamUtils_GetEnteredGamepadTextInput(instancePtr, buf, 2048);
	if (strlen(buf) == 0) {
		*txt = &bbEmptyString;
	} else {
		*txt = bbStringFromUTF8String((unsigned char *)buf);
	}
	return res;
}

int bmx_SteamAPI_ISteamUtils_GetImageRGBA(ISteamUtils * instancePtr, int image, uint8 * dest, int destBufferSize) {
	return SteamAPI_ISteamUtils_GetImageRGBA(instancePtr, image, dest, destBufferSize);
}

int bmx_SteamAPI_ISteamUtils_GetImageSize(ISteamUtils * instancePtr, int image, uint32 * width, uint32 * height) {
	return SteamAPI_ISteamUtils_GetImageSize(instancePtr, image, width, height);
}

uint32 bmx_SteamAPI_ISteamUtils_GetEnteredGamepadTextLength(ISteamUtils * instancePtr) {
	return SteamAPI_ISteamUtils_GetEnteredGamepadTextLength(instancePtr);
}

BBString * bmx_SteamAPI_ISteamUtils_GetSteamUILanguage(ISteamUtils * instancePtr) {
	return bbStringFromUTF8String((unsigned char *)SteamAPI_ISteamUtils_GetSteamUILanguage(instancePtr));
}

int bmx_SteamAPI_ISteamUtils_ShowGamepadTextInput(ISteamUtils * instancePtr, EGamepadTextInputMode inputMode,
	EGamepadTextInputLineMode lineInputMode, BBString * description, uint32 charMax, BBString * existingText) {
	char * d = (char *)bbStringToUTF8String(description);
	char * e = (char *)bbStringToUTF8String(existingText);
	int res = SteamAPI_ISteamUtils_ShowGamepadTextInput(instancePtr, inputMode, lineInputMode, d, charMax, e);
	bbMemFree(e);
	bbMemFree(d);
	return res;
}

// IUserStats ---------------------------------------------

class MaxUserStats
{
private:
	ISteamUserStats * instancePtr;
	BBObject * maxHandle;

	CCallResult<MaxUserStats, NumberOfCurrentPlayers_t> m_NumberOfCurrentPlayersCallResult;
	CCallResult<MaxUserStats, LeaderboardScoresDownloaded_t> m_LeaderboardScoresDownloadedCallResult;
	CCallResult<MaxUserStats, LeaderboardFindResult_t> m_LeaderboardFindResultCallResult;
	CCallResult<MaxUserStats, GlobalAchievementPercentagesReady_t> m_GlobalAchievementPercentagesReadyResult;
	CCallResult<MaxUserStats, GlobalStatsReceived_t> m_GlobalStatsReceivedResult;
	CCallResult<MaxUserStats, UserStatsReceived_t> m_UserStatsReceivedResult;
	CCallResult<MaxUserStats, LeaderboardScoreUploaded_t> m_LeaderboardScoreUploadedResult;
	CCallResult<MaxUserStats, LeaderboardUGCSet_t> m_LeaderboardUGCSetResult;

public:
	STEAM_CALLBACK(MaxUserStats, OnUserStatsReceived, UserStatsReceived_t, m_CallbackUserStatsReceived);
	STEAM_CALLBACK(MaxUserStats, OnUserStatsStored, UserStatsStored_t, m_CallbackUserStatsStored);
	STEAM_CALLBACK(MaxUserStats, OnUserStatsUnloaded, UserStatsUnloaded_t, m_CallbackUserStatsUnloaded);
	STEAM_CALLBACK(
		MaxUserStats, OnUserAchievementIconFetched, UserAchievementIconFetched_t, m_CallbackUserAchievementIconFetched);
	STEAM_CALLBACK(MaxUserStats, OnUserAchievementStored, UserAchievementStored_t, m_CallbackUserAchievementStored);

	MaxUserStats(ISteamUserStats * instancePtr, BBObject * handle);
	~MaxUserStats() = default;

	// calls
	void GetNumberOfCurrentPlayers();
	void DownloadLeaderboardEntries(
		uint64 leaderboardHandle, ELeaderboardDataRequest dataRequest, int rangeStart, int rangeEnd);
	void DownloadLeaderboardEntriesForUsers(uint64 leaderboardHandle, uint64 * users, int count);
	void FindLeaderboard(BBString * leaderboardName);
	void FindOrCreateLeaderboard(
		BBString * leaderboardName, ELeaderboardSortMethod sortMethod, ELeaderboardDisplayType displayType);
	void RequestGlobalAchievementPercentages();
	void RequestGlobalStats(int historyDays);
	void RequestUserStats(uint64 steamID);
	void UploadLeaderboardScore(uint64 leaderboardHandle, ELeaderboardUploadScoreMethod uploadScoreMethod, int score,
		int * scoreDetails, int count);
	void AttachLeaderboardUGC(uint64 leaderboardHandle, uint64 ugcHandle);

	// callbacks
	void OnGetNumberOfCurrentPlayers(NumberOfCurrentPlayers_t * result, bool failure);
	void OnLeaderboardScoresDownloaded(LeaderboardScoresDownloaded_t * result, bool failure);
	void OnLeaderboardFindResult(LeaderboardFindResult_t * result, bool failure);
	void OnGlobalAchievementPercentagesReady(GlobalAchievementPercentagesReady_t * result, bool failure);
	void OnGlobalStatsReceived(GlobalStatsReceived_t * result, bool failure);
	void OnUserStatsReceived(UserStatsReceived_t * result, bool failure);
	void OnLeaderboardScoreUploaded(LeaderboardScoreUploaded_t * result, bool failure);
	void OnLeaderboardUGCSet(LeaderboardUGCSet_t * result, bool failure);
};

MaxUserStats::MaxUserStats(ISteamUserStats * instancePtr, BBObject * handle)
	: instancePtr(instancePtr), maxHandle(handle),
	  m_CallbackUserStatsReceived(this, &MaxUserStats::OnUserStatsReceived),
	  m_CallbackUserStatsStored(this, &MaxUserStats::OnUserStatsStored),
	  m_CallbackUserStatsUnloaded(this, &MaxUserStats::OnUserStatsUnloaded),
	  m_CallbackUserAchievementIconFetched(this, &MaxUserStats::OnUserAchievementIconFetched),
	  m_CallbackUserAchievementStored(this, &MaxUserStats::OnUserAchievementStored) {
}

void MaxUserStats::OnUserStatsReceived(UserStatsReceived_t * result) {
	steam_steamsdk_TSteamUserStats__OnUserStatsReceived(
		maxHandle, result->m_nGameID, result->m_eResult, result->m_steamIDUser.ConvertToUint64());
}

void MaxUserStats::OnUserStatsStored(UserStatsStored_t * result) {
	steam_steamsdk_TSteamUserStats__OnUserStatsStored(maxHandle, result->m_nGameID, result->m_eResult);
}

void MaxUserStats::OnUserStatsUnloaded(UserStatsUnloaded_t * result) {
	steam_steamsdk_TSteamUserStats__OnUserStatsUnloaded(maxHandle, result->m_steamIDUser.ConvertToUint64());
}

void MaxUserStats::OnUserAchievementIconFetched(UserAchievementIconFetched_t * result) {
	steam_steamsdk_TSteamUserStats__OnUserAchievementIconFetched(maxHandle, result->m_nGameID.ToUint64(),
		bbStringFromUTF8String((unsigned char *)result->m_rgchAchievementName), result->m_bAchieved,
		result->m_nIconHandle);
}

void MaxUserStats::OnUserAchievementStored(UserAchievementStored_t * result) {
	steam_steamsdk_TSteamUserStats__OnUserAchievementStored(maxHandle, result->m_nGameID, result->m_bGroupAchievement,
		bbStringFromUTF8String((unsigned char *)result->m_rgchAchievementName), result->m_nCurProgress,
		result->m_nMaxProgress);
}

void MaxUserStats::GetNumberOfCurrentPlayers() {
	SteamAPICall_t apiCall = SteamUserStats()->GetNumberOfCurrentPlayers();
	m_NumberOfCurrentPlayersCallResult.Set(apiCall, this, &MaxUserStats::OnGetNumberOfCurrentPlayers);
}

void MaxUserStats::DownloadLeaderboardEntries(
	uint64 leaderboardHandle, ELeaderboardDataRequest dataRequest, int rangeStart, int rangeEnd) {
	SteamAPICall_t apiCall =
		SteamUserStats()->DownloadLeaderboardEntries(leaderboardHandle, dataRequest, rangeStart, rangeEnd);
	m_LeaderboardScoresDownloadedCallResult.Set(apiCall, this, &MaxUserStats::OnLeaderboardScoresDownloaded);
}

void MaxUserStats::DownloadLeaderboardEntriesForUsers(uint64 leaderboardHandle, uint64 * users, int count) {
	std::vector<CSteamID> steamUsers;
	for (int i = 0; i < count; i++) {
		steamUsers.push_back(CSteamID(users[i]));
	}

	SteamAPICall_t apiCall =
		SteamUserStats()->DownloadLeaderboardEntriesForUsers(leaderboardHandle, steamUsers.data(), count);
	m_LeaderboardScoresDownloadedCallResult.Set(apiCall, this, &MaxUserStats::OnLeaderboardScoresDownloaded);
}

void MaxUserStats::FindLeaderboard(BBString * leaderboardName) {
	char * n = (char *)bbStringToUTF8String(leaderboardName);
	SteamAPICall_t apiCall = SteamUserStats()->FindLeaderboard(n);
	m_LeaderboardFindResultCallResult.Set(apiCall, this, &MaxUserStats::OnLeaderboardFindResult);
	bbMemFree(n);
}

void MaxUserStats::FindOrCreateLeaderboard(
	BBString * leaderboardName, ELeaderboardSortMethod sortMethod, ELeaderboardDisplayType displayType) {
	char * n = (char *)bbStringToUTF8String(leaderboardName);
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

void MaxUserStats::UploadLeaderboardScore(uint64 leaderboardHandle, ELeaderboardUploadScoreMethod uploadScoreMethod,
	int score, int * scoreDetails, int count) {
	SteamAPICall_t apiCall =
		SteamUserStats()->UploadLeaderboardScore(leaderboardHandle, uploadScoreMethod, score, scoreDetails, count);
	m_LeaderboardScoreUploadedResult.Set(apiCall, this, &MaxUserStats::OnLeaderboardScoreUploaded);
}

void MaxUserStats::AttachLeaderboardUGC(uint64 leaderboardHandle, uint64 ugcHandle) {
	SteamAPICall_t apiCall = SteamAPI_ISteamUserStats_AttachLeaderboardUGC(instancePtr, leaderboardHandle, ugcHandle);
	m_LeaderboardUGCSetResult.Set(apiCall, this, &MaxUserStats::OnLeaderboardUGCSet);
}

void MaxUserStats::OnGetNumberOfCurrentPlayers(NumberOfCurrentPlayers_t * result, bool failure) {
	steam_steamsdk_TSteamUserStats__OnGetNumberOfCurrentPlayers(maxHandle, result->m_bSuccess, result->m_cPlayers);
}

void MaxUserStats::OnLeaderboardScoresDownloaded(LeaderboardScoresDownloaded_t * result, bool failure) {
	steam_steamsdk_TSteamUserStats__OnLeaderboardScoresDownloaded(
		maxHandle, result->m_hSteamLeaderboard, result->m_hSteamLeaderboardEntries, result->m_cEntryCount);
}

void MaxUserStats::OnLeaderboardFindResult(LeaderboardFindResult_t * result, bool failure) {
	steam_steamsdk_TSteamUserStats__OnLeaderboardFindResult(
		maxHandle, result->m_hSteamLeaderboard, result->m_bLeaderboardFound);
}

void MaxUserStats::OnGlobalAchievementPercentagesReady(GlobalAchievementPercentagesReady_t * result, bool failure) {
	steam_steamsdk_TSteamUserStats__OnGlobalAchievementPercentagesReady(
		maxHandle, result->m_nGameID, result->m_eResult);
}

void MaxUserStats::OnGlobalStatsReceived(GlobalStatsReceived_t * result, bool failure) {
	steam_steamsdk_TSteamUserStats__OnGlobalStatsReceived(maxHandle, result->m_nGameID, result->m_eResult);
}

void MaxUserStats::OnUserStatsReceived(UserStatsReceived_t * result, bool failure) {
	steam_steamsdk_TSteamUserStats__OnUserStatsReceived(
		maxHandle, result->m_nGameID, result->m_eResult, result->m_steamIDUser.ConvertToUint64());
}

void MaxUserStats::OnLeaderboardScoreUploaded(LeaderboardScoreUploaded_t * result, bool failure) {
	steam_steamsdk_TSteamUserStats__OnLeaderboardScoreUploaded(maxHandle, result->m_bSuccess,
		result->m_hSteamLeaderboard, result->m_nScore, result->m_bScoreChanged, result->m_nGlobalRankNew,
		result->m_nGlobalRankPrevious);
}

void MaxUserStats::OnLeaderboardUGCSet(LeaderboardUGCSet_t * result, bool failure) {
	steam_steamsdk_TSteamUserStats__OnLeaderboardUGCSet(
		maxHandle, result->m_eResult, result->m_hSteamLeaderboard, failure);
}

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void * bmx_steamsdk_register_steamuserstats(ISteamUserStats * instancePtr, BBObject * obj) {
	return new MaxUserStats(instancePtr, obj);
}

void bmx_steamsdk_unregister_steamuserstats(void * callbackPtr) {
	delete static_cast<MaxUserStats *>(callbackPtr);
}

void bmx_SteamAPI_ISteamUserStats_GetNumberOfCurrentPlayers(MaxUserStats * userStats) {
	userStats->GetNumberOfCurrentPlayers();
}

int bmx_SteamAPI_ISteamUserStats_GetMostAchievedAchievementInfo(
	ISteamUserStats * instancePtr, BBString ** name, float * percent, int * achieved) {
	char buf[1024];
	bool ach;
	int res = SteamAPI_ISteamUserStats_GetMostAchievedAchievementInfo(instancePtr, buf, 1024, percent, &ach);
	if (res != -1) {
		*achieved = ach;
		*name = bbStringFromUTF8String((unsigned char *)buf);
	}
	return res;
}

int bmx_SteamAPI_ISteamUserStats_GetNextMostAchievedAchievementInfo(
	ISteamUserStats * instancePtr, int previous, BBString ** name, float * percent, int * achieved) {
	char buf[1024];
	bool ach;
	int res =
		SteamAPI_ISteamUserStats_GetNextMostAchievedAchievementInfo(instancePtr, previous, buf, 1024, percent, &ach);
	if (res != -1) {
		*achieved = ach;
		*name = bbStringFromUTF8String((unsigned char *)buf);
	}
	return res;
}

uint32 bmx_SteamAPI_ISteamUserStats_GetNumAchievements(ISteamUserStats * instancePtr) {
	return SteamAPI_ISteamUserStats_GetNumAchievements(instancePtr);
}

int bmx_SteamAPI_ISteamUserStats_ClearAchievement(ISteamUserStats * instancePtr, BBString * name) {
	char * n = (char *)bbStringToUTF8String(name);
	int res = SteamAPI_ISteamUserStats_ClearAchievement(instancePtr, n);
	bbMemFree(n);
	return res;
}

void bmx_SteamAPI_ISteamUserStats_DownloadLeaderboardEntries(MaxUserStats * userStats, uint64 leaderboardHandle,
	ELeaderboardDataRequest leaderboardDataRequest, int rangeStart, int rangeEnd) {
	userStats->DownloadLeaderboardEntries(leaderboardHandle, leaderboardDataRequest, rangeStart, rangeEnd);
}

void bmx_SteamAPI_ISteamUserStats_DownloadLeaderboardEntriesForUsers(
	MaxUserStats * userStats, uint64 leaderboardHandle, uint64 * users, int count) {
	userStats->DownloadLeaderboardEntriesForUsers(leaderboardHandle, users, count);
}

void bmx_SteamAPI_ISteamUserStats_FindLeaderboard(MaxUserStats * userStats, BBString * leaderboardName) {
	userStats->FindLeaderboard(leaderboardName);
}

void bmx_SteamAPI_ISteamUserStats_FindOrCreateLeaderboard(MaxUserStats * userStats, BBString * leaderboardName,
	ELeaderboardSortMethod sortMethod, ELeaderboardDisplayType displayType) {
	userStats->FindOrCreateLeaderboard(leaderboardName, sortMethod, displayType);
}

int bmx_SteamAPI_ISteamUserStats_GetAchievement(ISteamUserStats * instancePtr, BBString * name, int * achieved) {
	char * n = (char *)bbStringToUTF8String(name);
	bool ach;
	int res = SteamAPI_ISteamUserStats_GetAchievement(instancePtr, n, &ach);
	*achieved = ach;
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_GetAchievementAchievedPercent(
	ISteamUserStats * instancePtr, BBString * name, float * percent) {
	char * n = (char *)bbStringToUTF8String(name);
	int res = SteamAPI_ISteamUserStats_GetAchievementAchievedPercent(instancePtr, n, percent);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_GetAchievementAndUnlockTime(
	ISteamUserStats * instancePtr, BBString * name, int * achieved, uint32 * unlockTime) {
	char * n = (char *)bbStringToUTF8String(name);
	bool ach;
	int res = SteamAPI_ISteamUserStats_GetAchievementAndUnlockTime(instancePtr, n, &ach, unlockTime);
	*achieved = ach;
	bbMemFree(n);
	return res;
}

BBString * bmx_SteamAPI_ISteamUserStats_GetAchievementDisplayAttribute(
	ISteamUserStats * instancePtr, BBString * name, BBString * key) {
	char * n = (char *)bbStringToUTF8String(name);
	char * k = (char *)bbStringToUTF8String(key);
	const char * r = SteamAPI_ISteamUserStats_GetAchievementDisplayAttribute(instancePtr, n, k);
	bbMemFree(k);
	bbMemFree(n);
	if (strlen(r) == 0) {
		return &bbEmptyString;
	} else {
		return bbStringFromUTF8String((unsigned char *)r);
	}
}

int bmx_SteamAPI_ISteamUserStats_GetAchievementIcon(ISteamUserStats * instancePtr, BBString * name) {
	char * n = (char *)bbStringToUTF8String(name);
	int res = SteamAPI_ISteamUserStats_GetAchievementIcon(instancePtr, n);
	bbMemFree(n);
	return res;
}

BBString * bmx_SteamAPI_ISteamUserStats_GetAchievementName(ISteamUserStats * instancePtr, uint32 achievement) {
	const char * n = SteamAPI_ISteamUserStats_GetAchievementName(instancePtr, achievement);
	if (strlen(n) == 0) {
		return &bbEmptyString;
	} else {
		return bbStringFromUTF8String((unsigned char *)n);
	}
}

int bmx_SteamAPI_ISteamUserStats_GetGlobalStatInt64(ISteamUserStats * instancePtr, BBString * statName, int64 * data) {
	char * n = (char *)bbStringToUTF8String(statName);
	int res = SteamAPI_ISteamUserStats_GetGlobalStatInt64(instancePtr, n, data);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_GetGlobalStatDouble(
	ISteamUserStats * instancePtr, BBString * statName, double * data) {
	char * n = (char *)bbStringToUTF8String(statName);
	int res = SteamAPI_ISteamUserStats_GetGlobalStatDouble(instancePtr, n, data);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_GetGlobalStatHistoryInt64(
	ISteamUserStats * instancePtr, BBString * statName, int64 * data, uint32 count) {
	char * n = (char *)bbStringToUTF8String(statName);
	int res = SteamAPI_ISteamUserStats_GetGlobalStatHistoryInt64(instancePtr, n, data, count);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_GetGlobalStatHistoryDouble(
	ISteamUserStats * instancePtr, BBString * statName, double * data, uint32 count) {
	char * n = (char *)bbStringToUTF8String(statName);
	int res = SteamAPI_ISteamUserStats_GetGlobalStatHistoryDouble(instancePtr, n, data, count);
	bbMemFree(n);
	return res;
}

ELeaderboardDisplayType bmx_SteamAPI_ISteamUserStats_GetLeaderboardDisplayType(
	ISteamUserStats * instancePtr, uint64 leaderboardHandle) {
	return SteamAPI_ISteamUserStats_GetLeaderboardDisplayType(instancePtr, leaderboardHandle);
}

int bmx_SteamAPI_ISteamUserStats_GetLeaderboardEntryCount(ISteamUserStats * instancePtr, uint64 leaderboardHandle) {
	return SteamAPI_ISteamUserStats_GetLeaderboardEntryCount(instancePtr, leaderboardHandle);
}

BBString * bmx_SteamAPI_ISteamUserStats_GetLeaderboardName(ISteamUserStats * instancePtr, uint64 leaderboardHandle) {
	const char * n = SteamAPI_ISteamUserStats_GetLeaderboardName(instancePtr, leaderboardHandle);
	if (strlen(n) == 0) {
		return &bbEmptyString;
	} else {
		return bbStringFromUTF8String((unsigned char *)n);
	}
}

ELeaderboardSortMethod bmx_SteamAPI_ISteamUserStats_GetLeaderboardSortMethod(
	ISteamUserStats * instancePtr, uint64 leaderboardHandle) {
	return SteamAPI_ISteamUserStats_GetLeaderboardSortMethod(instancePtr, leaderboardHandle);
}

int bmx_SteamAPI_ISteamUserStats_GetStatInt32(ISteamUserStats * instancePtr, BBString * name, int * data) {
	char * n = (char *)bbStringToUTF8String(name);
	int res = SteamAPI_ISteamUserStats_GetStatInt32(instancePtr, n, data);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_GetStatFloat(ISteamUserStats * instancePtr, BBString * name, float * data) {
	char * n = (char *)bbStringToUTF8String(name);
	int res = SteamAPI_ISteamUserStats_GetStatFloat(instancePtr, n, data);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_GetUserAchievement(
	ISteamUserStats * instancePtr, uint64 steamID, BBString * name, int * achieved) {
	char * n = (char *)bbStringToUTF8String(name);
	bool ach;
	int res = SteamAPI_ISteamUserStats_GetUserAchievement(instancePtr, uint64_steamid(steamID), n, &ach);
	*achieved = ach;
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_GetUserAchievementAndUnlockTime(
	ISteamUserStats * instancePtr, uint64 steamID, BBString * name, int * achieved, uint32 * unlockTime) {
	char * n = (char *)bbStringToUTF8String(name);
	bool ach;
	int res = SteamAPI_ISteamUserStats_GetUserAchievementAndUnlockTime(
		instancePtr, uint64_steamid(steamID), n, &ach, unlockTime);
	*achieved = ach;
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_GetUserStatInt32(
	ISteamUserStats * instancePtr, uint64 steamID, BBString * name, int * data) {
	char * n = (char *)bbStringToUTF8String(name);
	int res = SteamAPI_ISteamUserStats_GetUserStatInt32(instancePtr, uint64_steamid(steamID), n, data);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_GetUserStatFloat(
	ISteamUserStats * instancePtr, uint64 steamID, BBString * name, float * data) {
	char * n = (char *)bbStringToUTF8String(name);
	int res = SteamAPI_ISteamUserStats_GetUserStatFloat(instancePtr, uint64_steamid(steamID), n, data);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_IndicateAchievementProgress(
	ISteamUserStats * instancePtr, BBString * name, uint32 curProgress, uint32 maxProgress) {
	char * n = (char *)bbStringToUTF8String(name);
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

void bmx_SteamAPI_ISteamUserStats_RequestUserStats(MaxUserStats * userStats, uint64 steamID) {
	userStats->RequestUserStats(steamID);
}

int bmx_SteamAPI_ISteamUserStats_GetAchievementProgressLimitsInt32(
	ISteamUserStats * instancePtr, BBString * name, int32 * minimum, int32 * maximum) {
	char * n = (char *)bbStringToUTF8String(name);
	bool result = SteamAPI_ISteamUserStats_GetAchievementProgressLimitsInt32(instancePtr, n, minimum, maximum);
	bbMemFree(n);
	return result;
}
int bmx_SteamAPI_ISteamUserStats_GetAchievementProgressLimitsFloat(
	ISteamUserStats * instancePtr, BBString * name, float * minimum, float * maximum) {
	char * n = (char *)bbStringToUTF8String(name);
	bool result = SteamAPI_ISteamUserStats_GetAchievementProgressLimitsFloat(instancePtr, n, minimum, maximum);
	bbMemFree(n);
	return result;
}
int bmx_SteamAPI_ISteamUserStats_GetDownloadedLeaderboardEntry(ISteamUserStats * instancePtr, uint64 entriesHandle,
	int index, uint64 * steamID, int * globalRank, int * score, int * details, int detailsCapacity, int * detailsCount,
	uint64 * ugcHandle) {
	LeaderboardEntry_t entry = {};
	bool result = SteamAPI_ISteamUserStats_GetDownloadedLeaderboardEntry(
		instancePtr, entriesHandle, index, &entry, details, detailsCapacity);
	*steamID = entry.m_steamIDUser.ConvertToUint64();
	*globalRank = entry.m_nGlobalRank;
	*score = entry.m_nScore;
	*detailsCount = entry.m_cDetails;
	*ugcHandle = entry.m_hUGC;
	return result;
}
void bmx_SteamAPI_ISteamUserStats_AttachLeaderboardUGC(
	MaxUserStats * userStats, uint64 leaderboardHandle, uint64 ugcHandle) {
	userStats->AttachLeaderboardUGC(leaderboardHandle, ugcHandle);
}

int bmx_SteamAPI_ISteamUserStats_ResetAllStats(ISteamUserStats * instancePtr, int achievementsToo) {
	return SteamAPI_ISteamUserStats_ResetAllStats(instancePtr, achievementsToo);
}

int bmx_SteamAPI_ISteamUserStats_SetAchievement(ISteamUserStats * instancePtr, BBString * name) {
	char * n = (char *)bbStringToUTF8String(name);
	int res = SteamAPI_ISteamUserStats_SetAchievement(instancePtr, n);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_SetStatInt32(ISteamUserStats * instancePtr, BBString * name, int data) {
	char * n = (char *)bbStringToUTF8String(name);
	int res = SteamAPI_ISteamUserStats_SetStatInt32(instancePtr, n, data);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_SetStatFloat(ISteamUserStats * instancePtr, BBString * name, float data) {
	char * n = (char *)bbStringToUTF8String(name);
	int res = SteamAPI_ISteamUserStats_SetStatFloat(instancePtr, n, data);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUserStats_StoreStats(ISteamUserStats * instancePtr) {
	return SteamAPI_ISteamUserStats_StoreStats(instancePtr);
}

int bmx_SteamAPI_ISteamUserStats_UpdateAvgRateStat(
	ISteamUserStats * instancePtr, BBString * name, float countThisSession, double sessionLength) {
	char * n = (char *)bbStringToUTF8String(name);
	int res = SteamAPI_ISteamUserStats_UpdateAvgRateStat(instancePtr, n, countThisSession, sessionLength);
	bbMemFree(n);
	return res;
}

void bmx_SteamAPI_ISteamUserStats_UploadLeaderboardScore(MaxUserStats * userStats, uint64 leaderboardHandle,
	ELeaderboardUploadScoreMethod uploadScoreMethod, int score, int * scoreDetails, int count) {
	userStats->UploadLeaderboardScore(leaderboardHandle, uploadScoreMethod, score, scoreDetails, count);
}

// ISteamUGC --------------------------------------------

class MaxUGC
{
private:
	ISteamUGC * instancePtr;
	BBObject * maxHandle;

	CCallResult<MaxUGC, AddAppDependencyResult_t> m_AddAppDependencyCallResult;
	CCallResult<MaxUGC, AddUGCDependencyResult_t> m_AddDependencyCallResult;
	CCallResult<MaxUGC, UserFavoriteItemsListChanged_t> m_UserFavoriteItemsListChangedCallResult;
	CCallResult<MaxUGC, CreateItemResult_t> m_CreateItemCallResult;
	CCallResult<MaxUGC, DeleteItemResult_t> m_DeleteItemCallResult;
	CCallResult<MaxUGC, GetUserItemVoteResult_t> m_GetUserItemVoteCallResult;
	CCallResult<MaxUGC, RemoveAppDependencyResult_t> m_RemoveAppDependencyCallResult;
	CCallResult<MaxUGC, RemoveUGCDependencyResult_t> m_RemoveUGCDependencyCallResult;
	CCallResult<MaxUGC, SteamUGCQueryCompleted_t> m_SteamUGCQueryCompletedCallResult;
	CCallResult<MaxUGC, SetUserItemVoteResult_t> m_SetUserItemVoteCallResult;
	CCallResult<MaxUGC, StartPlaytimeTrackingResult_t> m_StartPlaytimeTrackingCallResult;
	CCallResult<MaxUGC, StopPlaytimeTrackingResult_t> m_StopPlaytimeTrackingCallResult;
	CCallResult<MaxUGC, GetAppDependenciesResult_t> m_GetAppDependenciesCallResult;
	CCallResult<MaxUGC, SubmitItemUpdateResult_t> m_SubmitItemUpdateCallResult;
	CCallResult<MaxUGC, RemoteStorageSubscribePublishedFileResult_t> m_RemoteStorageSubscribePublishedFileCallResult;
	CCallResult<MaxUGC, RemoteStorageUnsubscribePublishedFileResult_t>
		m_RemoteStorageUnsubscribePublishedFileCallResult;
	CCallResult<MaxUGC, WorkshopEULAStatus_t> m_WorkshopEULAStatusCallResult;

public:
	STEAM_CALLBACK(MaxUGC, OnDownloadItem, DownloadItemResult_t, m_CallbackDownloadItem);
	STEAM_CALLBACK(MaxUGC, OnItemInstalled, ItemInstalled_t, m_CallbackItemInstalled);

	MaxUGC(ISteamUGC * instancePtr, BBObject * handle);
	~MaxUGC() = default;

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
	void GetWorkshopEULAStatus();

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
	void OnWorkshopEULAStatus(WorkshopEULAStatus_t * result, bool failure);
};

MaxUGC::MaxUGC(ISteamUGC * instancePtr, BBObject * handle)
	: instancePtr(instancePtr), maxHandle(handle), m_CallbackDownloadItem(this, &MaxUGC::OnDownloadItem),
	  m_CallbackItemInstalled(this, &MaxUGC::OnItemInstalled) {
}

void MaxUGC::OnDownloadItem(DownloadItemResult_t * result) {
	steam_steamsdk_TSteamUGC__OnDownloadItem(
		maxHandle, result->m_eResult, result->m_unAppID, result->m_nPublishedFileId);
}

void MaxUGC::OnItemInstalled(ItemInstalled_t * result) {
	steam_steamsdk_TSteamUGC__OnItemInstalled(maxHandle, result->m_unAppID, result->m_nPublishedFileId);
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

void MaxUGC::GetWorkshopEULAStatus() {
	SteamAPICall_t apiCall = SteamAPI_ISteamUGC_GetWorkshopEULAStatus(instancePtr);
	m_WorkshopEULAStatusCallResult.Set(apiCall, this, &MaxUGC::OnWorkshopEULAStatus);
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
	m_RemoteStorageUnsubscribePublishedFileCallResult.Set(
		apiCall, this, &MaxUGC::OnRemoteStorageUnsubscribePublishedFile);
}

void MaxUGC::OnAddAppDependency(AddAppDependencyResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnAddAppDependency(
		maxHandle, result->m_eResult, result->m_nPublishedFileId, result->m_nAppID);
}

void MaxUGC::OnAddDependency(AddUGCDependencyResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnAddDependency(
		maxHandle, result->m_eResult, result->m_nPublishedFileId, result->m_nChildPublishedFileId);
}

void MaxUGC::OnUserFavoriteItemsListChanged(UserFavoriteItemsListChanged_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnUserFavoriteItemsListChanged(
		maxHandle, result->m_nPublishedFileId, result->m_eResult, static_cast<int>(result->m_bWasAddRequest));
}

void MaxUGC::OnCreateItem(CreateItemResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnCreateItem(maxHandle, result->m_eResult, result->m_nPublishedFileId,
		static_cast<int>(result->m_bUserNeedsToAcceptWorkshopLegalAgreement));
}

void MaxUGC::OnDeleteItem(DeleteItemResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnDeleteItem(maxHandle, result->m_eResult, result->m_nPublishedFileId);
}

void MaxUGC::OnGetUserItemVote(GetUserItemVoteResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnGetUserItemVote(maxHandle, result->m_nPublishedFileId, result->m_eResult,
		static_cast<int>(result->m_bVotedUp), static_cast<int>(result->m_bVotedDown),
		static_cast<int>(result->m_bVoteSkipped));
}

void MaxUGC::OnRemoveAppDependency(RemoveAppDependencyResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnRemoveAppDependency(
		maxHandle, result->m_eResult, result->m_nPublishedFileId, result->m_nAppID);
}

void MaxUGC::OnRemoveUGCDependency(RemoveUGCDependencyResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnRemoveUGCDependency(
		maxHandle, result->m_eResult, result->m_nPublishedFileId, result->m_nChildPublishedFileId);
}

void MaxUGC::OnSteamUGCQueryCompleted(SteamUGCQueryCompleted_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnSteamUGCQueryCompleted(maxHandle, result->m_handle, result->m_eResult,
		result->m_unNumResultsReturned, result->m_unTotalMatchingResults, static_cast<int>(result->m_bCachedData));
}

void MaxUGC::OnSetUserItemVote(SetUserItemVoteResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnSetUserItemVote(
		maxHandle, result->m_nPublishedFileId, result->m_eResult, static_cast<int>(result->m_bVoteUp));
}

void MaxUGC::OnStartPlaytimeTracking(StartPlaytimeTrackingResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnStartPlaytimeTracking(maxHandle, result->m_eResult);
}

void MaxUGC::OnStopPlaytimeTracking(StopPlaytimeTrackingResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnStopPlaytimeTracking(maxHandle, result->m_eResult);
}

void MaxUGC::OnGetAppDependencies(GetAppDependenciesResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnGetAppDependencies(maxHandle, result->m_eResult, result->m_nPublishedFileId,
		result->m_rgAppIDs, result->m_nNumAppDependencies, result->m_nTotalNumAppDependencies);
}

void MaxUGC::OnSubmitItemUpdate(SubmitItemUpdateResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnSubmitItemUpdate(
		maxHandle, result->m_eResult, static_cast<int>(result->m_bUserNeedsToAcceptWorkshopLegalAgreement));
}

void MaxUGC::OnRemoteStorageSubscribePublishedFile(RemoteStorageSubscribePublishedFileResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnRemoteStorageSubscribePublishedFile(
		maxHandle, result->m_eResult, result->m_nPublishedFileId);
}

void MaxUGC::OnRemoteStorageUnsubscribePublishedFile(
	RemoteStorageUnsubscribePublishedFileResult_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnRemoteStorageUnsubscribePublishedFile(
		maxHandle, result->m_eResult, result->m_nPublishedFileId);
}

void MaxUGC::OnWorkshopEULAStatus(WorkshopEULAStatus_t * result, bool failure) {
	steam_steamsdk_TSteamUGC__OnWorkshopEULAStatus(maxHandle, result->m_eResult, result->m_nAppID, result->m_unVersion,
		result->m_rtAction, result->m_bAccepted, result->m_bNeedsAction, failure);
}

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void * bmx_steamsdk_register_steamugc(ISteamUGC * instancePtr, BBObject * obj) {
	return new MaxUGC(instancePtr, obj);
}

void bmx_steamsdk_unregister_steamugc(void * callbackPtr) {
	delete static_cast<MaxUGC *>(callbackPtr);
}

void bmx_SteamAPI_ISteamUGC_AddAppDependency(MaxUGC * ugc, uint64 publishedFileID, uint32 appID) {
	ugc->AddAppDependency(publishedFileID, appID);
}

void bmx_SteamAPI_ISteamUGC_AddDependency(MaxUGC * ugc, uint64 publishedFileId, uint64 childPublishedFileId) {
	ugc->AddDependency(publishedFileId, childPublishedFileId);
}

int bmx_SteamAPI_ISteamUGC_AddExcludedTag(ISteamUGC * instancePtr, uint64 queryHandle, BBString * tagName) {
	char * t = (char *)bbStringToUTF8String(tagName);
	bool res = SteamAPI_ISteamUGC_AddExcludedTag(instancePtr, queryHandle, t);
	bbMemFree(t);
	return res;
}

int bmx_SteamAPI_ISteamUGC_AddItemKeyValueTag(
	ISteamUGC * instancePtr, uint64 queryHandle, BBString * key, BBString * value) {
	char * k = (char *)bbStringToUTF8String(key);
	char * v = (char *)bbStringToUTF8String(value);
	bool res = SteamAPI_ISteamUGC_AddItemKeyValueTag(instancePtr, queryHandle, k, v);
	bbMemFree(v);
	bbMemFree(k);
	return res;
}

int bmx_SteamAPI_ISteamUGC_AddItemPreviewFile(
	ISteamUGC * instancePtr, uint64 queryHandle, BBString * previewFile, EItemPreviewType previewType) {
	char * p = (char *)bbStringToUTF8String(previewFile);
	bool res = SteamAPI_ISteamUGC_AddItemPreviewFile(instancePtr, queryHandle, p, previewType);
	bbMemFree(p);
	return res;
}

int bmx_SteamAPI_ISteamUGC_AddItemPreviewVideo(ISteamUGC * instancePtr, uint64 queryHandle, BBString * videoID) {
	char * v = (char *)bbStringToUTF8String(videoID);
	bool res = SteamAPI_ISteamUGC_AddItemPreviewVideo(instancePtr, queryHandle, v);
	bbMemFree(v);
	return res;
}

void bmx_SteamAPI_ISteamUGC_AddItemToFavorites(MaxUGC * ugc, uint32 appId, uint64 publishedFileID) {
	ugc->AddItemToFavorites(appId, publishedFileID);
}

int bmx_SteamAPI_ISteamUGC_AddRequiredKeyValueTag(
	ISteamUGC * instancePtr, uint64 queryHandle, BBString * key, BBString * value) {
	char * k = (char *)bbStringToUTF8String(key);
	char * v = (char *)bbStringToUTF8String(value);
	bool res = SteamAPI_ISteamUGC_AddRequiredKeyValueTag(instancePtr, queryHandle, k, v);
	bbMemFree(v);
	bbMemFree(k);
	return res;
}

int bmx_SteamAPI_ISteamUGC_AddRequiredTag(ISteamUGC * instancePtr, uint64 queryHandle, BBString * tagName) {
	char * t = (char *)bbStringToUTF8String(tagName);
	bool res = SteamAPI_ISteamUGC_AddRequiredTag(instancePtr, queryHandle, t);
	bbMemFree(t);
	return res;
}

int bmx_SteamAPI_ISteamUGC_InitWorkshopForGameServer(
	ISteamUGC * instancePtr, uint64 workshopDepotID, BBString * folder) {
	char * f = (char *)bbStringToUTF8String(folder);
	bool res = SteamAPI_ISteamUGC_BInitWorkshopForGameServer(instancePtr, workshopDepotID, f);
	bbMemFree(f);
	return res;
}

void bmx_SteamAPI_ISteamUGC_CreateItem(MaxUGC * ugc, uint32 consumerAppId, EWorkshopFileType fileType) {
	ugc->CreateItem(consumerAppId, fileType);
}

uint64 bmx_SteamAPI_ISteamUGC_CreateQueryAllUGCRequestPage(ISteamUGC * instancePtr, EUGCQuery queryType,
	EUGCMatchingUGCType matchingeMatchingUGCTypeFileType, uint32 creatorAppID, uint32 consumerAppID, uint32 page) {
	return SteamAPI_ISteamUGC_CreateQueryAllUGCRequestPage(
		instancePtr, queryType, matchingeMatchingUGCTypeFileType, creatorAppID, consumerAppID, page);
}

uint64 bmx_SteamAPI_ISteamUGC_CreateQueryAllUGCRequestCursor(ISteamUGC * instancePtr, EUGCQuery queryType,
	EUGCMatchingUGCType matchingUGCType, uint32 creatorAppID, uint32 consumerAppID, BBString * cursor) {
	char * value = (char *)bbStringToUTF8String(cursor);
	uint64 result = SteamAPI_ISteamUGC_CreateQueryAllUGCRequestCursor(
		instancePtr, queryType, matchingUGCType, creatorAppID, consumerAppID, value);
	bbMemFree(value);
	return result;
}

BBObject * bmx_SteamAPI_ISteamUGC_GetQueryUGCResult(ISteamUGC * instancePtr, uint64 queryHandle, uint32 index) {
	SteamUGCDetails_t details = {};
	if (!SteamAPI_ISteamUGC_GetQueryUGCResult(instancePtr, queryHandle, index, &details))
		return &bbNullObject;
	return steam_steamsdk_TSteamUGCDetails__Create(details.m_nPublishedFileId, details.m_eResult, details.m_eFileType,
		details.m_nCreatorAppID, details.m_nConsumerAppID, bbStringFromUTF8String((unsigned char *)details.m_rgchTitle),
		bbStringFromUTF8String((unsigned char *)details.m_rgchDescription), details.m_ulSteamIDOwner,
		details.m_rtimeCreated, details.m_rtimeUpdated, details.m_rtimeAddedToUserList, details.m_eVisibility,
		details.m_bBanned, details.m_bAcceptedForUse, details.m_bTagsTruncated,
		bbStringFromUTF8String((unsigned char *)details.m_rgchTags), details.m_hFile, details.m_hPreviewFile,
		bbStringFromUTF8String((unsigned char *)details.m_pchFileName), details.m_nFileSize, details.m_nPreviewFileSize,
		bbStringFromUTF8String((unsigned char *)details.m_rgchURL), details.m_unVotesUp, details.m_unVotesDown,
		details.m_flScore, details.m_unNumChildren);
}
uint32 bmx_SteamAPI_ISteamUGC_GetQueryUGCNumTags(ISteamUGC * instancePtr, uint64 queryHandle, uint32 index) {
	return SteamAPI_ISteamUGC_GetQueryUGCNumTags(instancePtr, queryHandle, index);
}
int bmx_SteamAPI_ISteamUGC_GetQueryUGCTag(
	ISteamUGC * instancePtr, uint64 queryHandle, uint32 index, uint32 tagIndex, BBString ** value) {
	char buffer[BUFFER_SIZE] = {0};
	bool result = SteamAPI_ISteamUGC_GetQueryUGCTag(instancePtr, queryHandle, index, tagIndex, buffer, BUFFER_SIZE);
	*value = bbStringFromUTF8String((unsigned char *)buffer);
	return result;
}
int bmx_SteamAPI_ISteamUGC_GetQueryUGCTagDisplayName(
	ISteamUGC * instancePtr, uint64 queryHandle, uint32 index, uint32 tagIndex, BBString ** value) {
	char buffer[BUFFER_SIZE] = {0};
	bool result =
		SteamAPI_ISteamUGC_GetQueryUGCTagDisplayName(instancePtr, queryHandle, index, tagIndex, buffer, BUFFER_SIZE);
	*value = bbStringFromUTF8String((unsigned char *)buffer);
	return result;
}
int bmx_SteamAPI_ISteamUGC_GetQueryUGCKeyValueTagByKey(
	ISteamUGC * instancePtr, uint64 queryHandle, uint32 index, BBString * key, BBString ** value) {
	char * keyValue = (char *)bbStringToUTF8String(key);
	char buffer[BUFFER_SIZE] = {0};
	bool result = instancePtr->GetQueryUGCKeyValueTag(queryHandle, index, keyValue, buffer, BUFFER_SIZE);
	*value = bbStringFromUTF8String((unsigned char *)buffer);
	bbMemFree(keyValue);
	return result;
}
int bmx_SteamAPI_ISteamUGC_AddRequiredTagGroup(ISteamUGC * instancePtr, uint64 queryHandle, BBArray * tags) {
	int count = tags->scales[0];
	BBString ** strings = (BBString **)BBARRAYDATA(tags, tags->dims);
	SteamParamStringArray_t array = {0};
	array.m_nNumStrings = count;
	array.m_ppStrings = (const char **)malloc(sizeof(char *) * count);
	for (int i = 0; i < count; ++i)
		array.m_ppStrings[i] = (char *)bbStringToUTF8String(strings[i]);
	bool result = SteamAPI_ISteamUGC_AddRequiredTagGroup(instancePtr, queryHandle, &array);
	for (int i = 0; i < count; ++i)
		bbMemFree((char *)array.m_ppStrings[i]);
	free(array.m_ppStrings);
	return result;
}
int bmx_SteamAPI_ISteamUGC_SetTimeCreatedDateRange(
	ISteamUGC * instancePtr, uint64 queryHandle, uint32 startTime, uint32 endTime) {
	return SteamAPI_ISteamUGC_SetTimeCreatedDateRange(instancePtr, queryHandle, startTime, endTime);
}
int bmx_SteamAPI_ISteamUGC_SetTimeUpdatedDateRange(
	ISteamUGC * instancePtr, uint64 queryHandle, uint32 startTime, uint32 endTime) {
	return SteamAPI_ISteamUGC_SetTimeUpdatedDateRange(instancePtr, queryHandle, startTime, endTime);
}
int bmx_SteamAPI_ISteamUGC_SetAllowLegacyUpload(ISteamUGC * instancePtr, uint64 updateHandle, int allowLegacyUpload) {
	return SteamAPI_ISteamUGC_SetAllowLegacyUpload(instancePtr, updateHandle, allowLegacyUpload);
}
int bmx_SteamAPI_ISteamUGC_RemoveAllItemKeyValueTags(ISteamUGC * instancePtr, uint64 updateHandle) {
	return SteamAPI_ISteamUGC_RemoveAllItemKeyValueTags(instancePtr, updateHandle);
}
int bmx_SteamAPI_ISteamUGC_ShowWorkshopEULA(ISteamUGC * instancePtr) {
	return SteamAPI_ISteamUGC_ShowWorkshopEULA(instancePtr);
}
void bmx_SteamAPI_ISteamUGC_GetWorkshopEULAStatus(MaxUGC * ugc) {
	ugc->GetWorkshopEULAStatus();
}

uint64 bmx_SteamAPI_ISteamUGC_CreateQueryUGCDetailsRequest(
	ISteamUGC * instancePtr, uint64 * publishedFileIDs, int numPublishedFileIDs) {
	return SteamAPI_ISteamUGC_CreateQueryUGCDetailsRequest(instancePtr, publishedFileIDs, numPublishedFileIDs);
}

uint64 bmx_SteamAPI_ISteamUGC_CreateQueryUserUGCRequest(ISteamUGC * instancePtr, uint32 accountID,
	EUserUGCList listType, EUGCMatchingUGCType matchingUGCType, EUserUGCListSortOrder sortOrder, uint32 creatorAppID,
	uint32 consumerAppID, uint32 page) {
	return SteamAPI_ISteamUGC_CreateQueryUserUGCRequest(
		instancePtr, accountID, listType, matchingUGCType, sortOrder, creatorAppID, consumerAppID, page);
}

void bmx_SteamAPI_ISteamUGC_DeleteItem(MaxUGC * ugc, uint64 publishedFileID) {
	ugc->DeleteItem(publishedFileID);
}

int bmx_SteamAPI_ISteamUGC_DownloadItem(ISteamUGC * instancePtr, uint64 publishedFileID, int highPriority) {
	return SteamAPI_ISteamUGC_DownloadItem(instancePtr, publishedFileID, highPriority);
}

void bmx_SteamAPI_ISteamUGC_GetAppDependencies(MaxUGC * ugc, uint64 publishedFileID) {
	ugc->GetAppDependencies(publishedFileID);
}

int bmx_SteamAPI_ISteamUGC_GetItemDownloadInfo(
	ISteamUGC * instancePtr, uint64 publishedFileID, uint64 * bytesDownloaded, uint64 * bytesTotal) {
	return SteamAPI_ISteamUGC_GetItemDownloadInfo(instancePtr, publishedFileID, bytesDownloaded, bytesTotal);
}

int bmx_SteamAPI_ISteamUGC_GetItemInstallInfo(
	ISteamUGC * instancePtr, uint64 publishedFileID, uint64 * sizeOnDisk, BBString ** folder, uint32 * timestamp) {
	char fbuf[BUFFER_SIZE];
	bool res =
		SteamAPI_ISteamUGC_GetItemInstallInfo(instancePtr, publishedFileID, sizeOnDisk, fbuf, BUFFER_SIZE, timestamp);
	*folder = bbStringFromUTF8String((unsigned char *)fbuf);
	return res;
}

uint32 bmx_SteamAPI_ISteamUGC_GetItemState(ISteamUGC * instancePtr, uint64 publishedFileID) {
	return SteamAPI_ISteamUGC_GetItemState(instancePtr, publishedFileID);
}

EItemUpdateStatus bmx_SteamAPI_ISteamUGC_GetItemUpdateProgress(
	ISteamUGC * instancePtr, uint64 queryHandle, uint64 * bytesProcessed, uint64 * bytesTotal) {
	return SteamAPI_ISteamUGC_GetItemUpdateProgress(instancePtr, queryHandle, bytesProcessed, bytesTotal);
}

uint32 bmx_SteamAPI_ISteamUGC_GetNumSubscribedItems(ISteamUGC * instancePtr, int includeLocallyDisabled) {
	return SteamAPI_ISteamUGC_GetNumSubscribedItems(instancePtr, includeLocallyDisabled);
}

int bmx_SteamAPI_ISteamUGC_GetQueryUGCAdditionalPreview(ISteamUGC * instancePtr, uint64 queryHandle, uint32 index,
	uint32 previewIndex, BBString ** URLOrVideoID, BBString ** originalFileName, EItemPreviewType * previewType) {
	char urlbuf[BUFFER_SIZE];
	char filebuf[BUFFER_SIZE];
	bool res = SteamAPI_ISteamUGC_GetQueryUGCAdditionalPreview(
		instancePtr, queryHandle, index, previewIndex, urlbuf, BUFFER_SIZE, filebuf, BUFFER_SIZE, previewType);
	*URLOrVideoID = bbStringFromUTF8String((unsigned char *)urlbuf);
	*originalFileName = bbStringFromUTF8String((unsigned char *)filebuf);
	return res;
}

int bmx_SteamAPI_ISteamUGC_GetQueryUGCChildren(
	ISteamUGC * instancePtr, uint64 queryHandle, uint32 index, uint64 * publishedFileIDs, uint32 maxEntries) {
	return SteamAPI_ISteamUGC_GetQueryUGCChildren(instancePtr, queryHandle, index, publishedFileIDs, maxEntries);
}

int bmx_SteamAPI_ISteamUGC_GetQueryUGCKeyValueTag(ISteamUGC * instancePtr, uint64 queryHandle, uint32 index,
	uint32 keyValueTagIndex, BBString ** key, BBString ** value) {
	char keybuf[BUFFER_SIZE];
	char valuebuf[VALUE_SIZE];
	bool res = SteamAPI_ISteamUGC_GetQueryUGCKeyValueTag(
		instancePtr, queryHandle, index, keyValueTagIndex, keybuf, BUFFER_SIZE, valuebuf, VALUE_SIZE);
	*key = bbStringFromUTF8String((unsigned char *)keybuf);
	*value = bbStringFromUTF8String((unsigned char *)valuebuf);
	return res;
}

int bmx_SteamAPI_ISteamUGC_GetQueryUGCMetadata(
	ISteamUGC * instancePtr, uint64 queryHandle, uint32 index, BBString ** metadata) {
	char metabuf[METADATA_SIZE];
	bool res = SteamAPI_ISteamUGC_GetQueryUGCMetadata(instancePtr, queryHandle, index, metabuf, METADATA_SIZE);
	*metadata = bbStringFromUTF8String((unsigned char *)metabuf);
	return res;
}

uint32 bmx_SteamAPI_ISteamUGC_GetQueryUGCNumAdditionalPreviews(
	ISteamUGC * instancePtr, uint64 queryHandle, uint32 index) {
	return SteamAPI_ISteamUGC_GetQueryUGCNumAdditionalPreviews(instancePtr, queryHandle, index);
}

uint32 bmx_SteamAPI_ISteamUGC_GetQueryUGCNumKeyValueTags(ISteamUGC * instancePtr, uint64 queryHandle, uint32 index) {
	return SteamAPI_ISteamUGC_GetQueryUGCNumKeyValueTags(instancePtr, queryHandle, index);
}

int bmx_SteamAPI_ISteamUGC_GetQueryUGCPreviewURL(
	ISteamUGC * instancePtr, uint64 queryHandle, uint32 index, BBString ** URL) {
	char urlbuf[BUFFER_SIZE];
	bool res = SteamAPI_ISteamUGC_GetQueryUGCPreviewURL(instancePtr, queryHandle, index, urlbuf, BUFFER_SIZE);
	*URL = bbStringFromUTF8String((unsigned char *)urlbuf);
	return res;
}

int bmx_SteamAPI_ISteamUGC_GetQueryUGCStatistic(
	ISteamUGC * instancePtr, uint64 queryHandle, uint32 index, EItemStatistic statType, uint64 * statValue) {
	return SteamAPI_ISteamUGC_GetQueryUGCStatistic(instancePtr, queryHandle, index, statType, statValue);
}

uint32 bmx_SteamAPI_ISteamUGC_GetSubscribedItems(
	ISteamUGC * instancePtr, uint64 * publishedFileIDs, uint32 maxEntries, int includeLocallyDisabled) {
	return SteamAPI_ISteamUGC_GetSubscribedItems(
		instancePtr, publishedFileIDs, maxEntries, includeLocallyDisabled);
}

uint32 bmx_SteamAPI_ISteamUGC_GetNumSupportedGameVersions(
	ISteamUGC * instancePtr, uint64 queryHandle, uint32 index) {
	return SteamAPI_ISteamUGC_GetNumSupportedGameVersions(instancePtr, queryHandle, index);
}

int bmx_SteamAPI_ISteamUGC_GetSupportedGameVersionData(ISteamUGC * instancePtr, uint64 queryHandle,
	uint32 index, uint32 versionIndex, BBString ** minimum, BBString ** maximum) {
	char minimumBuffer[BUFFER_SIZE] = {0};
	char maximumBuffer[BUFFER_SIZE] = {0};
	bool result = SteamAPI_ISteamUGC_GetSupportedGameVersionData(instancePtr, queryHandle, index, versionIndex,
		minimumBuffer, maximumBuffer, BUFFER_SIZE);
	*minimum = bbStringFromUTF8String((unsigned char *)minimumBuffer);
	*maximum = bbStringFromUTF8String((unsigned char *)maximumBuffer);
	return result;
}

uint32 bmx_SteamAPI_ISteamUGC_GetQueryUGCContentDescriptors(ISteamUGC * instancePtr, uint64 queryHandle,
	uint32 index, EUGCContentDescriptorID * descriptors, uint32 maxEntries) {
	return SteamAPI_ISteamUGC_GetQueryUGCContentDescriptors(
		instancePtr, queryHandle, index, descriptors, maxEntries);
}

int bmx_SteamAPI_ISteamUGC_SetAdminQuery(ISteamUGC * instancePtr, uint64 queryHandle, int adminQuery) {
	return SteamAPI_ISteamUGC_SetAdminQuery(instancePtr, queryHandle, adminQuery);
}

int bmx_SteamAPI_ISteamUGC_AddContentDescriptor(
	ISteamUGC * instancePtr, uint64 updateHandle, EUGCContentDescriptorID descriptor) {
	return SteamAPI_ISteamUGC_AddContentDescriptor(instancePtr, updateHandle, descriptor);
}

int bmx_SteamAPI_ISteamUGC_RemoveContentDescriptor(
	ISteamUGC * instancePtr, uint64 updateHandle, EUGCContentDescriptorID descriptor) {
	return SteamAPI_ISteamUGC_RemoveContentDescriptor(instancePtr, updateHandle, descriptor);
}

int bmx_SteamAPI_ISteamUGC_SetRequiredGameVersions(
	ISteamUGC * instancePtr, uint64 updateHandle, BBString * minimum, BBString * maximum) {
	char * minValue = (char *)bbStringToUTF8String(minimum);
	char * maxValue = (char *)bbStringToUTF8String(maximum);
	bool result = SteamAPI_ISteamUGC_SetRequiredGameVersions(instancePtr, updateHandle, minValue, maxValue);
	bbMemFree(maxValue);
	bbMemFree(minValue);
	return result;
}

uint32 bmx_SteamAPI_ISteamUGC_GetUserContentDescriptorPreferences(
	ISteamUGC * instancePtr, EUGCContentDescriptorID * descriptors, uint32 maxEntries) {
	return SteamAPI_ISteamUGC_GetUserContentDescriptorPreferences(instancePtr, descriptors, maxEntries);
}

int bmx_SteamAPI_ISteamUGC_SetItemsDisabledLocally(
	ISteamUGC * instancePtr, uint64 * publishedFileIDs, uint32 count, int disabled) {
	return SteamAPI_ISteamUGC_SetItemsDisabledLocally(instancePtr, publishedFileIDs, count, disabled);
}

int bmx_SteamAPI_ISteamUGC_SetSubscriptionsLoadOrder(
	ISteamUGC * instancePtr, uint64 * publishedFileIDs, uint32 count) {
	return SteamAPI_ISteamUGC_SetSubscriptionsLoadOrder(instancePtr, publishedFileIDs, count);
}

int bmx_SteamAPI_ISteamUGC_MarkDownloadedItemAsUnused(ISteamUGC * instancePtr, uint64 publishedFileID) {
	return SteamAPI_ISteamUGC_MarkDownloadedItemAsUnused(instancePtr, publishedFileID);
}

uint32 bmx_SteamAPI_ISteamUGC_GetNumDownloadedItems(ISteamUGC * instancePtr) {
	return SteamAPI_ISteamUGC_GetNumDownloadedItems(instancePtr);
}

uint32 bmx_SteamAPI_ISteamUGC_GetDownloadedItems(
	ISteamUGC * instancePtr, uint64 * publishedFileIDs, uint32 maxEntries) {
	return SteamAPI_ISteamUGC_GetDownloadedItems(instancePtr, publishedFileIDs, maxEntries);
}

void bmx_SteamAPI_ISteamUGC_GetUserItemVote(MaxUGC * ugc, uint64 publishedFileID) {
	ugc->GetUserItemVote(publishedFileID);
}

int bmx_SteamAPI_ISteamUGC_ReleaseQueryUGCRequest(ISteamUGC * instancePtr, uint64 queryHandle) {
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

int bmx_SteamAPI_ISteamUGC_RemoveItemKeyValueTags(ISteamUGC * instancePtr, uint64 queryHandle, BBString * key) {
	char * k = (char *)bbStringToUTF8String(key);
	bool res = SteamAPI_ISteamUGC_RemoveItemKeyValueTags(instancePtr, queryHandle, k);
	bbMemFree(k);
	return res;
}

int bmx_SteamAPI_ISteamUGC_RemoveItemPreview(ISteamUGC * instancePtr, uint64 queryHandle, uint32 index) {
	return SteamAPI_ISteamUGC_RemoveItemPreview(instancePtr, queryHandle, index);
}

void bmx_SteamAPI_ISteamUGC_SendQueryUGCRequest(MaxUGC * ugc, uint64 queryHandle) {
	ugc->SendQueryUGCRequest(queryHandle);
}

int bmx_SteamAPI_ISteamUGC_SetAllowCachedResponse(ISteamUGC * instancePtr, uint64 queryHandle, uint32 maxAgeSeconds) {
	return SteamAPI_ISteamUGC_SetAllowCachedResponse(instancePtr, queryHandle, maxAgeSeconds);
}

int bmx_SteamAPI_ISteamUGC_SetCloudFileNameFilter(
	ISteamUGC * instancePtr, uint64 queryHandle, BBString * matchCloudFileName) {
	char * n = (char *)bbStringToUTF8String(matchCloudFileName);
	bool res = SteamAPI_ISteamUGC_SetCloudFileNameFilter(instancePtr, queryHandle, n);
	bbMemFree(n);
	return res;
}

int bmx_SteamAPI_ISteamUGC_SetItemContent(ISteamUGC * instancePtr, uint64 updateHandle, BBString * contentFolder) {
	char * c = (char *)bbStringToUTF8String(contentFolder);
	bool res = SteamAPI_ISteamUGC_SetItemContent(instancePtr, updateHandle, c);
	bbMemFree(c);
	return res;
}

int bmx_SteamAPI_ISteamUGC_SetItemDescription(ISteamUGC * instancePtr, uint64 updateHandle, BBString * description) {
	char * d = (char *)bbStringToUTF8String(description);
	bool res = SteamAPI_ISteamUGC_SetItemDescription(instancePtr, updateHandle, d);
	bbMemFree(d);
	return res;
}

int bmx_SteamAPI_ISteamUGC_SetItemMetadata(ISteamUGC * instancePtr, uint64 updateHandle, BBString * metaData) {
	char * m = (char *)bbStringToUTF8String(metaData);
	bool res = SteamAPI_ISteamUGC_SetItemMetadata(instancePtr, updateHandle, m);
	bbMemFree(m);
	return res;
}

int bmx_SteamAPI_ISteamUGC_SetItemPreview(ISteamUGC * instancePtr, uint64 updateHandle, BBString * previewFile) {
	char * p = (char *)bbStringToUTF8String(previewFile);
	bool res = SteamAPI_ISteamUGC_SetItemPreview(instancePtr, updateHandle, p);
	bbMemFree(p);
	return res;
}

int bmx_SteamAPI_ISteamUGC_SetItemTags(
	ISteamUGC * instancePtr, uint64 updateHandle, BBArray * tags, int allowAdminTags) {
	int n = tags->scales[0];
	BBString ** s = (BBString **)BBARRAYDATA(tags, tags->dims);

	SteamParamStringArray_t array = {0};
	array.m_nNumStrings = n;
	array.m_ppStrings = (const char **)malloc(sizeof(char *) * n);

	for (int i = 0; i < n; i++) {
		array.m_ppStrings[i] = (char *)bbStringToUTF8String(s[i]);
	}

	bool res = SteamAPI_ISteamUGC_SetItemTags(instancePtr, updateHandle, &array, allowAdminTags);

	for (int i = 0; i < n; i++) {
		bbMemFree((char *)array.m_ppStrings[i]);
	}

	free(array.m_ppStrings);
	return res;
}

int bmx_SteamAPI_ISteamUGC_SetItemTitle(ISteamUGC * instancePtr, uint64 updateHandle, BBString * title) {
	char * t = (char *)bbStringToUTF8String(title);
	bool res = SteamAPI_ISteamUGC_SetItemTitle(instancePtr, updateHandle, t);
	bbMemFree(t);
	return res;
}

int bmx_SteamAPI_ISteamUGC_SetItemUpdateLanguage(ISteamUGC * instancePtr, uint64 updateHandle, BBString * language) {
	char * t = (char *)bbStringToUTF8String(language);
	bool res = SteamAPI_ISteamUGC_SetItemUpdateLanguage(instancePtr, updateHandle, t);
	bbMemFree(t);
	return res;
}

int bmx_SteamAPI_ISteamUGC_SetItemVisibility(
	ISteamUGC * instancePtr, uint64 updateHandle, ERemoteStoragePublishedFileVisibility visibility) {
	return SteamAPI_ISteamUGC_SetItemVisibility(instancePtr, updateHandle, visibility);
}

int bmx_SteamAPI_ISteamUGC_SetLanguage(ISteamUGC * instancePtr, uint64 queryHandle, BBString * language) {
	char * t = (char *)bbStringToUTF8String(language);
	bool res = SteamAPI_ISteamUGC_SetLanguage(instancePtr, queryHandle, t);
	bbMemFree(t);
	return res;
}

int bmx_SteamAPI_ISteamUGC_SetMatchAnyTag(ISteamUGC * instancePtr, uint64 queryHandle, int matchAnyTag) {
	return SteamAPI_ISteamUGC_SetMatchAnyTag(instancePtr, queryHandle, matchAnyTag);
}

int bmx_SteamAPI_ISteamUGC_SetRankedByTrendDays(ISteamUGC * instancePtr, uint64 queryHandle, uint32 days) {
	return SteamAPI_ISteamUGC_SetRankedByTrendDays(instancePtr, queryHandle, days);
}

int bmx_SteamAPI_ISteamUGC_SetReturnAdditionalPreviews(
	ISteamUGC * instancePtr, uint64 queryHandle, int returnAdditionalPreviews) {
	return SteamAPI_ISteamUGC_SetReturnAdditionalPreviews(instancePtr, queryHandle, returnAdditionalPreviews);
}

int bmx_SteamAPI_ISteamUGC_SetReturnChildren(ISteamUGC * instancePtr, uint64 queryHandle, int returnChildren) {
	return SteamAPI_ISteamUGC_SetReturnChildren(instancePtr, queryHandle, returnChildren);
}

int bmx_SteamAPI_ISteamUGC_SetReturnKeyValueTags(ISteamUGC * instancePtr, uint64 queryHandle, int returnKeyValueTags) {
	return SteamAPI_ISteamUGC_SetReturnKeyValueTags(instancePtr, queryHandle, returnKeyValueTags);
}

int bmx_SteamAPI_ISteamUGC_SetReturnLongDescription(
	ISteamUGC * instancePtr, uint64 queryHandle, int returnLongDescription) {
	return SteamAPI_ISteamUGC_SetReturnLongDescription(instancePtr, queryHandle, returnLongDescription);
}

int bmx_SteamAPI_ISteamUGC_SetReturnMetadata(ISteamUGC * instancePtr, uint64 queryHandle, int returnMetadata) {
	return SteamAPI_ISteamUGC_SetReturnMetadata(instancePtr, queryHandle, returnMetadata);
}

int bmx_SteamAPI_ISteamUGC_SetReturnOnlyIDs(ISteamUGC * instancePtr, uint64 queryHandle, int returnOnlyIDs) {
	return SteamAPI_ISteamUGC_SetReturnOnlyIDs(instancePtr, queryHandle, returnOnlyIDs);
}

int bmx_SteamAPI_ISteamUGC_SetReturnPlaytimeStats(ISteamUGC * instancePtr, uint64 queryHandle, uint32 days) {
	return SteamAPI_ISteamUGC_SetReturnPlaytimeStats(instancePtr, queryHandle, days);
}

int bmx_SteamAPI_ISteamUGC_SetReturnTotalOnly(ISteamUGC * instancePtr, uint64 queryHandle, int returnTotalOnly) {
	return SteamAPI_ISteamUGC_SetReturnTotalOnly(instancePtr, queryHandle, returnTotalOnly);
}

int bmx_SteamAPI_ISteamUGC_SetSearchText(ISteamUGC * instancePtr, uint64 queryHandle, BBString * searchText) {
	char * s = (char *)bbStringToUTF8String(searchText);
	bool res = SteamAPI_ISteamUGC_SetSearchText(instancePtr, queryHandle, s);
	bbMemFree(s);
	return res;
}

void bmx_SteamAPI_ISteamUGC_SetUserItemVote(MaxUGC * ugc, uint64 publishedFileID, int voteUp) {
	ugc->SetUserItemVote(publishedFileID, voteUp);
}

uint64 bmx_SteamAPI_ISteamUGC_StartItemUpdate(ISteamUGC * instancePtr, uint32 consumerAppId, uint64 publishedFileID) {
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
		c = (char *)bbStringToUTF8String(changeNote);
	}
	ugc->SubmitItemUpdate(updateHandle, c);
	if (c) {
		bbMemFree(c);
	}
}

void bmx_SteamAPI_ISteamUGC_SubscribeItem(MaxUGC * ugc, uint64 publishedFileID) {
	ugc->SubscribeItem(publishedFileID);
}

void bmx_SteamAPI_ISteamUGC_SuspendDownloads(ISteamUGC * instancePtr, int suspend) {
	SteamAPI_ISteamUGC_SuspendDownloads(instancePtr, suspend);
}

void bmx_SteamAPI_ISteamUGC_UnsubscribeItem(MaxUGC * ugc, uint64 publishedFileID) {
	ugc->UnsubscribeItem(publishedFileID);
}

int bmx_SteamAPI_ISteamUGC_UpdateItemPreviewFile(
	ISteamUGC * instancePtr, uint64 updateHandle, uint32 index, BBString * previewFile) {
	char * f = (char *)bbStringToUTF8String(previewFile);
	bool res = SteamAPI_ISteamUGC_UpdateItemPreviewFile(instancePtr, updateHandle, index, f);
	bbMemFree(f);
	return res;
}

int bmx_SteamAPI_ISteamUGC_UpdateItemPreviewVideo(
	ISteamUGC * instancePtr, uint64 updateHandle, uint32 index, BBString * videoID) {
	char * v = (char *)bbStringToUTF8String(videoID);
	bool res = SteamAPI_ISteamUGC_UpdateItemPreviewVideo(instancePtr, updateHandle, index, v);
	bbMemFree(v);
	return res;
}

// ISteamFriends --------------------------------------------

class MaxFriends
{
private:
	ISteamFriends * instancePtr;
	BBObject * maxHandle;

	CCallResult<MaxFriends, ClanOfficerListResponse_t> m_ClanOfficerListResponseCallResult;
	CCallResult<MaxFriends, DownloadClanActivityCountsResult_t> m_DownloadClanActivityCountsCallResult;
	CCallResult<MaxFriends, FriendsEnumerateFollowingList_t> m_FriendsEnumerateFollowingListCallResult;
	CCallResult<MaxFriends, FriendsGetFollowerCount_t> m_FriendsGetFollowerCountCallResult;
	CCallResult<MaxFriends, FriendsIsFollowing_t> m_FriendsIsFollowingCallResult;
	CCallResult<MaxFriends, GameConnectedChatJoin_t> m_GameConnectedChatJoinCallResult;
	CCallResult<MaxFriends, GameConnectedClanChatMsg_t> m_GameConnectedClanChatMsgCallResult;
	CCallResult<MaxFriends, JoinClanChatRoomCompletionResult_t> m_JoinClanChatRoomCompletionCallResult;
	CCallResult<MaxFriends, EquippedProfileItems_t> m_EquippedProfileItemsCallResult;

public:
	STEAM_CALLBACK(MaxFriends, OnAvatarImageLoaded, AvatarImageLoaded_t, m_CallbackAvatarImageLoaded);
	STEAM_CALLBACK(
		MaxFriends, OnFriendRichPresenceUpdated, FriendRichPresenceUpdate_t, m_CallbackFriendRichPresenceUpdated);
	STEAM_CALLBACK(MaxFriends, OnGameConnectedChatLeave, GameConnectedChatLeave_t, m_CallbackGameConnectedChatLeave);
	STEAM_CALLBACK(
		MaxFriends, OnGameConnectedFriendChatMsg, GameConnectedFriendChatMsg_t, m_CallbackGameConnectedFriendChatMsg);
	STEAM_CALLBACK(MaxFriends, OnGameLobbyJoinRequested, GameLobbyJoinRequested_t, m_CallbackGameLobbyJoinRequested);
	STEAM_CALLBACK(MaxFriends, OnGameOverlayActivated, GameOverlayActivated_t, m_CallbackGameOverlayActivated);
	STEAM_CALLBACK(MaxFriends, OnGameRichPresenceJoinRequested, GameRichPresenceJoinRequested_t,
		m_CallbackGameRichPresenceJoinRequested);
	STEAM_CALLBACK(
		MaxFriends, OnGameServerChangeRequested, GameServerChangeRequested_t, m_CallbackGameServerChangeRequested);
	STEAM_CALLBACK(MaxFriends, OnPersonaStateChanged, PersonaStateChange_t, m_CallbackPersonaStateChanged);
	STEAM_CALLBACK(MaxFriends, OnEquippedProfileItemsChanged, EquippedProfileItemsChanged_t, m_CallbackEquippedProfileItemsChanged);

	MaxFriends(ISteamFriends * instancePtr, BBObject * handle);
	~MaxFriends() = default;

	// calls
	void RequestClanOfficerList(uint64 steamIDClan);
	void DownloadClanActivityCounts(uint64 * steamIDClans, int clansToRequest);
	void EnumerateFollowingList(uint32 startIndex);
	void GetFollowerCount(uint64 steamID);
	void IsFollowing(uint64 steamID);
	void JoinClanChatRoom(uint64 steamIDClan);
	void RequestEquippedProfileItems(uint64 steamID);

	// Callbacks
	void OnClanOfficerList(ClanOfficerListResponse_t * result, bool failure);
	void OnDownloadClanActivityCounts(DownloadClanActivityCountsResult_t * result, bool failure);
	void OnFriendsEnumerateFollowingList(FriendsEnumerateFollowingList_t * result, bool failure);
	void OnFriendsGetFollowerCount(FriendsGetFollowerCount_t * result, bool failure);
	void OnFriendsIsFollowing(FriendsIsFollowing_t * result, bool failure);
	void OnGameConnectedChatJoined(GameConnectedChatJoin_t * result, bool failure);
	void OnGameConnectedClanChatMsg(GameConnectedClanChatMsg_t * result, bool failure);
	void OnJoinClanChatRoomCompletion(JoinClanChatRoomCompletionResult_t * result, bool failure);
	void OnEquippedProfileItems(EquippedProfileItems_t * result, bool failure);
};

MaxFriends::MaxFriends(ISteamFriends * instancePtr, BBObject * handle)
	: instancePtr(instancePtr), maxHandle(handle), m_CallbackAvatarImageLoaded(this, &MaxFriends::OnAvatarImageLoaded),
	  m_CallbackFriendRichPresenceUpdated(this, &MaxFriends::OnFriendRichPresenceUpdated),
	  m_CallbackGameConnectedChatLeave(this, &MaxFriends::OnGameConnectedChatLeave),
	  m_CallbackGameConnectedFriendChatMsg(this, &MaxFriends::OnGameConnectedFriendChatMsg),
	  m_CallbackGameLobbyJoinRequested(this, &MaxFriends::OnGameLobbyJoinRequested),
	  m_CallbackGameOverlayActivated(this, &MaxFriends::OnGameOverlayActivated),
	  m_CallbackGameRichPresenceJoinRequested(this, &MaxFriends::OnGameRichPresenceJoinRequested),
	  m_CallbackGameServerChangeRequested(this, &MaxFriends::OnGameServerChangeRequested),
	  m_CallbackPersonaStateChanged(this, &MaxFriends::OnPersonaStateChanged),
	  m_CallbackEquippedProfileItemsChanged(this, &MaxFriends::OnEquippedProfileItemsChanged) {
}

void MaxFriends::OnAvatarImageLoaded(AvatarImageLoaded_t * result) {
	steam_steamsdk_TSteamFriends__OnAvatarImageLoaded(
		maxHandle, result->m_steamID.ConvertToUint64(), result->m_iImage, result->m_iWide, result->m_iTall);
}

void MaxFriends::OnFriendRichPresenceUpdated(FriendRichPresenceUpdate_t * result) {
	steam_steamsdk_TSteamFriends__OnFriendRichPresenceUpdated(
		maxHandle, result->m_steamIDFriend.ConvertToUint64(), result->m_nAppID);
}

void MaxFriends::OnGameConnectedChatLeave(GameConnectedChatLeave_t * result) {
	steam_steamsdk_TSteamFriends__OnGameConnectedChatLeave(maxHandle, result->m_steamIDClanChat.ConvertToUint64(),
		result->m_steamIDUser.ConvertToUint64(), result->m_bKicked, result->m_bDropped);
}

void MaxFriends::OnGameConnectedFriendChatMsg(GameConnectedFriendChatMsg_t * result) {
	steam_steamsdk_TSteamFriends__OnGameConnectedFriendChatMsg(
		maxHandle, result->m_steamIDUser.ConvertToUint64(), result->m_iMessageID);
}

void MaxFriends::OnGameLobbyJoinRequested(GameLobbyJoinRequested_t * result) {
	steam_steamsdk_TSteamFriends__OnGameLobbyJoinRequested(
		maxHandle, result->m_steamIDLobby.ConvertToUint64(), result->m_steamIDFriend.ConvertToUint64());
}

void MaxFriends::OnGameOverlayActivated(GameOverlayActivated_t * result) {
	steam_steamsdk_TSteamFriends__OnGameOverlayActivated(maxHandle, result->m_bActive);
}

void MaxFriends::OnGameRichPresenceJoinRequested(GameRichPresenceJoinRequested_t * result) {
	steam_steamsdk_TSteamFriends__OnGameRichPresenceJoinRequested(maxHandle, result->m_steamIDFriend.ConvertToUint64(),
		bbStringFromUTF8String((unsigned char *)result->m_rgchConnect));
}

void MaxFriends::OnGameServerChangeRequested(GameServerChangeRequested_t * result) {
	BBString * s = bbStringFromUTF8String((unsigned char *)result->m_rgchServer);
	BBString * p = &bbEmptyString;
	if (strlen(result->m_rgchPassword) > 0) {
		p = bbStringFromUTF8String((unsigned char *)result->m_rgchPassword);
	}
	steam_steamsdk_TSteamFriends__OnGameServerChangeRequested(maxHandle, s, p);
}

void MaxFriends::OnPersonaStateChanged(PersonaStateChange_t * result) {
	steam_steamsdk_TSteamFriends__OnPersonaStateChanged(maxHandle, result->m_ulSteamID, result->m_nChangeFlags);
}

void MaxFriends::RequestClanOfficerList(uint64 steamIDClan) {
	SteamAPICall_t apiCall = SteamFriends()->RequestClanOfficerList(steamIDClan);
	m_JoinClanChatRoomCompletionCallResult.Set(apiCall, this, &MaxFriends::OnJoinClanChatRoomCompletion);
}

void MaxFriends::DownloadClanActivityCounts(uint64 * steamIDClans, int clansToRequest) {
	SteamAPICall_t apiCall = SteamFriends()->DownloadClanActivityCounts((CSteamID *)steamIDClans, clansToRequest);
	m_DownloadClanActivityCountsCallResult.Set(apiCall, this, &MaxFriends::OnDownloadClanActivityCounts);
}

void MaxFriends::EnumerateFollowingList(uint32 startIndex) {
	SteamAPICall_t apiCall = SteamFriends()->EnumerateFollowingList(startIndex);
	m_FriendsEnumerateFollowingListCallResult.Set(apiCall, this, &MaxFriends::OnFriendsEnumerateFollowingList);
}

void MaxFriends::GetFollowerCount(uint64 steamID) {
	SteamAPICall_t apiCall = SteamFriends()->GetFollowerCount(steamID);
	m_JoinClanChatRoomCompletionCallResult.Set(apiCall, this, &MaxFriends::OnJoinClanChatRoomCompletion);
}

void MaxFriends::IsFollowing(uint64 steamID) {
	SteamAPICall_t apiCall = SteamFriends()->IsFollowing(steamID);
	m_FriendsIsFollowingCallResult.Set(apiCall, this, &MaxFriends::OnFriendsIsFollowing);
}

void MaxFriends::JoinClanChatRoom(uint64 steamIDClan) {
	SteamAPICall_t apiCall = SteamFriends()->JoinClanChatRoom(steamIDClan);
	m_JoinClanChatRoomCompletionCallResult.Set(apiCall, this, &MaxFriends::OnJoinClanChatRoomCompletion);
	m_GameConnectedChatJoinCallResult.Set(apiCall, this, &MaxFriends::OnGameConnectedChatJoined);
	m_GameConnectedClanChatMsgCallResult.Set(apiCall, this, &MaxFriends::OnGameConnectedClanChatMsg);
}

void MaxFriends::RequestEquippedProfileItems(uint64 steamID) {
	SteamAPICall_t apiCall = SteamFriends()->RequestEquippedProfileItems(steamID);
	m_EquippedProfileItemsCallResult.Set(apiCall, this, &MaxFriends::OnEquippedProfileItems);
}

void MaxFriends::OnEquippedProfileItemsChanged(EquippedProfileItemsChanged_t * result) {
	steam_steamsdk_TSteamFriends__OnEquippedProfileItemsChanged(maxHandle, result->m_steamID.ConvertToUint64());
}

void MaxFriends::OnEquippedProfileItems(EquippedProfileItems_t * result, bool failure) {
	steam_steamsdk_TSteamFriends__OnEquippedProfileItems(maxHandle, result->m_eResult,
		result->m_steamID.ConvertToUint64(), result->m_bHasAnimatedAvatar, result->m_bHasAvatarFrame,
		result->m_bHasProfileModifier, result->m_bHasProfileBackground, result->m_bHasMiniProfileBackground,
		result->m_bFromCache);
}

void MaxFriends::OnClanOfficerList(ClanOfficerListResponse_t * result, bool failure) {
	steam_steamsdk_TSteamFriends__OnClanOfficerList(
		maxHandle, result->m_steamIDClan.ConvertToUint64(), result->m_cOfficers, result->m_bSuccess);
}

void MaxFriends::OnDownloadClanActivityCounts(DownloadClanActivityCountsResult_t * result, bool failure) {
	steam_steamsdk_TSteamFriends__OnDownloadClanActivityCounts(maxHandle, result->m_bSuccess);
}

void MaxFriends::OnFriendsEnumerateFollowingList(FriendsEnumerateFollowingList_t * result, bool failure) {
	steam_steamsdk_TSteamFriends__OnFriendsEnumerateFollowingList(maxHandle, result->m_eResult,
		(uint64 *)result->m_rgSteamID, result->m_nResultsReturned, result->m_nTotalResultCount);
}

void MaxFriends::OnFriendsGetFollowerCount(FriendsGetFollowerCount_t * result, bool failure) {
	steam_steamsdk_TSteamFriends__OnFriendsGetFollowerCount(
		maxHandle, result->m_eResult, result->m_steamID.ConvertToUint64(), result->m_nCount);
}

void MaxFriends::OnFriendsIsFollowing(FriendsIsFollowing_t * result, bool failure) {
	steam_steamsdk_TSteamFriends__OnFriendsIsFollowing(
		maxHandle, result->m_eResult, result->m_steamID.ConvertToUint64(), result->m_bIsFollowing);
}

void MaxFriends::OnGameConnectedChatJoined(GameConnectedChatJoin_t * result, bool failure) {
	steam_steamsdk_TSteamFriends__OnGameConnectedChatJoined(
		maxHandle, result->m_steamIDUser.ConvertToUint64(), result->m_steamIDClanChat.ConvertToUint64());
}

void MaxFriends::OnGameConnectedClanChatMsg(GameConnectedClanChatMsg_t * result, bool failure) {
	steam_steamsdk_TSteamFriends__OnGameConnectedClanChatMsg(maxHandle, result->m_steamIDUser.ConvertToUint64(),
		result->m_steamIDClanChat.ConvertToUint64(), result->m_iMessageID);
}

void MaxFriends::OnJoinClanChatRoomCompletion(JoinClanChatRoomCompletionResult_t * result, bool failure) {
	steam_steamsdk_TSteamFriends__OnJoinClanChatRoomCompletion(
		maxHandle, result->m_steamIDClanChat.ConvertToUint64(), result->m_eChatRoomEnterResponse);
}

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void * bmx_steamsdk_register_steamfriends(ISteamFriends * instancePtr, BBObject * obj) {
	return new MaxFriends(instancePtr, obj);
}

void bmx_steamsdk_unregister_steamfriends(void * callbackPtr) {
	delete static_cast<MaxFriends *>(callbackPtr);
}

void bmx_SteamAPI_ISteamFriends_ActivateGameOverlay(ISteamFriends * instancePtr, BBString * dialog) {
	char * d = (char *)bbStringToUTF8String(dialog);
	SteamAPI_ISteamFriends_ActivateGameOverlay(instancePtr, d);
	bbMemFree(d);
}

void bmx_SteamAPI_ISteamFriends_ActivateGameOverlayInviteDialog(ISteamFriends * instancePtr, uint64 steamIDLobby) {
	SteamAPI_ISteamFriends_ActivateGameOverlayInviteDialog(instancePtr, steamIDLobby);
}

void bmx_SteamAPI_ISteamFriends_ActivateGameOverlayInviteDialogConnectString(
	ISteamFriends * instancePtr, BBString * connectString) {
	char * value = (char *)bbStringToUTF8String(connectString);
	SteamAPI_ISteamFriends_ActivateGameOverlayInviteDialogConnectString(instancePtr, value);
	bbMemFree(value);
}
void bmx_SteamAPI_ISteamFriends_ActivateGameOverlayRemotePlayTogetherInviteDialog(
	ISteamFriends * instancePtr, uint64 steamIDLobby) {
	SteamAPI_ISteamFriends_ActivateGameOverlayRemotePlayTogetherInviteDialog(instancePtr, steamIDLobby);
}
int bmx_SteamAPI_ISteamFriends_GetNumChatsWithUnreadPriorityMessages(ISteamFriends * instancePtr) {
	return SteamAPI_ISteamFriends_GetNumChatsWithUnreadPriorityMessages(instancePtr);
}
int bmx_SteamAPI_ISteamFriends_RegisterProtocolInOverlayBrowser(ISteamFriends * instancePtr, BBString * protocol) {
	char * value = (char *)bbStringToUTF8String(protocol);
	bool result = SteamAPI_ISteamFriends_RegisterProtocolInOverlayBrowser(instancePtr, value);
	bbMemFree(value);
	return result;
}

void bmx_SteamAPI_ISteamFriends_ActivateGameOverlayToStore(
	ISteamFriends * instancePtr, uint32 appID, EOverlayToStoreFlag flag) {
	SteamAPI_ISteamFriends_ActivateGameOverlayToStore(instancePtr, appID, flag);
}

void bmx_SteamAPI_ISteamFriends_ActivateGameOverlayToUser(
	ISteamFriends * instancePtr, BBString * dialog, uint64 steamID) {
	char * d = (char *)bbStringToUTF8String(dialog);
	SteamAPI_ISteamFriends_ActivateGameOverlayToUser(instancePtr, d, steamID);
	bbMemFree(d);
}

void bmx_SteamAPI_ISteamFriends_ActivateGameOverlayToWebPage(ISteamFriends * instancePtr, BBString * url) {
	char * u = (char *)bbStringToUTF8String(url);
	SteamAPI_ISteamFriends_ActivateGameOverlayToWebPage(instancePtr, u, k_EActivateGameOverlayToWebPageMode_Default);
	bbMemFree(u);
}

void bmx_SteamAPI_ISteamFriends_ClearRichPresence(ISteamFriends * instancePtr) {
	SteamAPI_ISteamFriends_ClearRichPresence(instancePtr);
}

int bmx_SteamAPI_ISteamFriends_CloseClanChatWindowInSteam(ISteamFriends * instancePtr, uint64 steamIDClanChat) {
	return SteamAPI_ISteamFriends_CloseClanChatWindowInSteam(instancePtr, steamIDClanChat);
}

void bmx_SteamAPI_ISteamFriends_DownloadClanActivityCounts(
	MaxFriends * friends, uint64 * steamIDClans, int clansToRequest) {
	friends->DownloadClanActivityCounts(steamIDClans, clansToRequest);
}

void bmx_SteamAPI_ISteamFriends_EnumerateFollowingList(MaxFriends * friends, uint32 startIndex) {
	friends->EnumerateFollowingList(startIndex);
}

uint64 bmx_SteamAPI_ISteamFriends_GetChatMemberByIndex(ISteamFriends * instancePtr, uint64 steamIDClan, int user) {
	return SteamAPI_ISteamFriends_GetChatMemberByIndex(instancePtr, steamIDClan, user);
}

int bmx_SteamAPI_ISteamFriends_GetClanActivityCounts(
	ISteamFriends * instancePtr, uint64 steamIDClan, int * online, int * inGame, int * chatting) {
	return SteamAPI_ISteamFriends_GetClanActivityCounts(instancePtr, steamIDClan, online, inGame, chatting);
}

uint64 bmx_SteamAPI_ISteamFriends_GetClanByIndex(ISteamFriends * instancePtr, int clan) {
	return SteamAPI_ISteamFriends_GetClanByIndex(instancePtr, clan);
}

int bmx_SteamAPI_ISteamFriends_GetClanChatMemberCount(ISteamFriends * instancePtr, uint64 steamIDClan) {
	return SteamAPI_ISteamFriends_GetClanChatMemberCount(instancePtr, steamIDClan);
}

int bmx_SteamAPI_ISteamFriends_GetClanChatMessage(ISteamFriends * instancePtr, uint64 steamIDClanChat, int message,
	BBString ** txt, EChatEntryType * chatEntryType, uint64 * steamidChatter) {
	char txtbuf[VALUE_SIZE];
	CSteamID chatter;
	bool res = SteamAPI_ISteamFriends_GetClanChatMessage(
		instancePtr, steamIDClanChat, message, txtbuf, VALUE_SIZE, chatEntryType, &chatter);
	if (strlen(txtbuf) == 0) {
		*txt = &bbEmptyString;
	} else {
		*txt = bbStringFromUTF8String((unsigned char *)txtbuf);
	}
	*steamidChatter = chatter.ConvertToUint64();
	return res;
}

int bmx_SteamAPI_ISteamFriends_GetClanCount(ISteamFriends * instancePtr) {
	return SteamAPI_ISteamFriends_GetClanCount(instancePtr);
}

BBString * bmx_SteamAPI_ISteamFriends_GetClanName(ISteamFriends * instancePtr, uint64 steamIDClan) {
	BBString * n = &bbEmptyString;
	const char * name = SteamAPI_ISteamFriends_GetClanName(instancePtr, steamIDClan);
	if (strlen(name) > 0) {
		n = bbStringFromUTF8String((unsigned char *)name);
	}
	return n;
}

uint64 bmx_SteamAPI_ISteamFriends_GetClanOfficerByIndex(ISteamFriends * instancePtr, uint64 steamIDClan, int officer) {
	return SteamAPI_ISteamFriends_GetClanOfficerByIndex(instancePtr, steamIDClan, officer);
}

int bmx_SteamAPI_ISteamFriends_GetClanOfficerCount(ISteamFriends * instancePtr, uint64 steamIDClan) {
	return SteamAPI_ISteamFriends_GetClanOfficerCount(instancePtr, steamIDClan);
}

uint64 bmx_SteamAPI_ISteamFriends_GetClanOwner(ISteamFriends * instancePtr, uint64 steamIDClan) {
	return SteamAPI_ISteamFriends_GetClanOwner(instancePtr, steamIDClan);
}

BBString * bmx_SteamAPI_ISteamFriends_GetClanTag(ISteamFriends * instancePtr, uint64 steamIDClan) {
	BBString * t = &bbEmptyString;
	const char * tag = SteamAPI_ISteamFriends_GetClanTag(instancePtr, steamIDClan);
	if (strlen(tag) > 0) {
		t = bbStringFromUTF8String((unsigned char *)tag);
	}
	return t;
}

uint64 bmx_SteamAPI_ISteamFriends_GetCoplayFriend(ISteamFriends * instancePtr, int coplayFriend) {
	return SteamAPI_ISteamFriends_GetCoplayFriend(instancePtr, coplayFriend);
}

int bmx_SteamAPI_ISteamFriends_GetCoplayFriendCount(ISteamFriends * instancePtr) {
	return SteamAPI_ISteamFriends_GetCoplayFriendCount(instancePtr);
}

void bmx_SteamAPI_ISteamFriends_GetFollowerCount(MaxFriends * friends, uint64 steamID) {
	friends->GetFollowerCount(steamID);
}

uint64 bmx_SteamAPI_ISteamFriends_GetFriendByIndex(ISteamFriends * instancePtr, int friendIndex, int friendFlags) {
	return SteamAPI_ISteamFriends_GetFriendByIndex(instancePtr, friendIndex, friendFlags);
}

uint32 bmx_SteamAPI_ISteamFriends_GetFriendCoplayGame(ISteamFriends * instancePtr, uint64 steamIDFriend) {
	return SteamAPI_ISteamFriends_GetFriendCoplayGame(instancePtr, steamIDFriend);
}

int bmx_SteamAPI_ISteamFriends_GetFriendCoplayTime(ISteamFriends * instancePtr, uint64 steamIDFriend) {
	return SteamAPI_ISteamFriends_GetFriendCoplayTime(instancePtr, steamIDFriend);
}

int bmx_SteamAPI_ISteamFriends_GetFriendCount(ISteamFriends * instancePtr, int friendFlags) {
	return SteamAPI_ISteamFriends_GetFriendCount(instancePtr, friendFlags);
}

int bmx_SteamAPI_ISteamFriends_GetFriendCountFromSource(ISteamFriends * instancePtr, uint64 steamIDSource) {
	return SteamAPI_ISteamFriends_GetFriendCountFromSource(instancePtr, steamIDSource);
}

uint64 bmx_SteamAPI_ISteamFriends_GetFriendFromSourceByIndex(
	ISteamFriends * instancePtr, uint64 steamIDSource, int friendIndex) {
	return SteamAPI_ISteamFriends_GetFriendFromSourceByIndex(instancePtr, steamIDSource, friendIndex);
}

int bmx_SteamAPI_ISteamFriends_GetFriendGamePlayed(ISteamFriends * instancePtr, uint64 steamIDFriend, uint64 * gameID,
	uint32 * gameIP, BBSHORT * gamePort, BBSHORT * queryPort, uint64 * steamIDLobby) {
	FriendGameInfo_t info;
	bool res = SteamAPI_ISteamFriends_GetFriendGamePlayed(instancePtr, steamIDFriend, &info);
	*gameID = info.m_gameID.ToUint64();
	*gameIP = info.m_unGameIP;
	*gamePort = info.m_usGamePort;
	*queryPort = info.m_usQueryPort;
	*steamIDLobby = info.m_steamIDLobby.ConvertToUint64();
	return res;
}

int bmx_SteamAPI_ISteamFriends_GetFriendMessage(
	ISteamFriends * instancePtr, uint64 steamIDFriend, int messageID, BBString ** txt, EChatEntryType * chatEntryType) {
	char txtbuf[VALUE_SIZE];
	bool res = SteamAPI_ISteamFriends_GetFriendMessage(
		instancePtr, steamIDFriend, messageID, txtbuf, VALUE_SIZE, chatEntryType);
	if (strlen(txtbuf) == 0) {
		*txt = &bbEmptyString;
	} else {
		*txt = bbStringFromUTF8String((unsigned char *)txtbuf);
	}
	return res;
}

BBString * bmx_SteamAPI_ISteamFriends_GetFriendPersonaName(ISteamFriends * instancePtr, uint64 steamIDFriend) {
	BBString * n = &bbEmptyString;
	const char * name = SteamAPI_ISteamFriends_GetFriendPersonaName(instancePtr, steamIDFriend);
	if (strlen(name) > 0) {
		n = bbStringFromUTF8String((unsigned char *)name);
	}
	return n;
}

BBString * bmx_SteamAPI_ISteamFriends_GetFriendPersonaNameHistory(
	ISteamFriends * instancePtr, uint64 steamIDFriend, int personaName) {
	BBString * n = &bbEmptyString;
	const char * name = SteamAPI_ISteamFriends_GetFriendPersonaNameHistory(instancePtr, steamIDFriend, personaName);
	if (strlen(name) > 0) {
		n = bbStringFromUTF8String((unsigned char *)name);
	}
	return n;
}

EPersonaState bmx_SteamAPI_ISteamFriends_GetFriendPersonaState(ISteamFriends * instancePtr, uint64 steamIDFriend) {
	return SteamAPI_ISteamFriends_GetFriendPersonaState(instancePtr, steamIDFriend);
}

EFriendRelationship bmx_SteamAPI_ISteamFriends_GetFriendRelationship(
	ISteamFriends * instancePtr, uint64 steamIDFriend) {
	return SteamAPI_ISteamFriends_GetFriendRelationship(instancePtr, steamIDFriend);
}

BBString * bmx_SteamAPI_ISteamFriends_GetFriendRichPresence(
	ISteamFriends * instancePtr, uint64 steamIDFriend, BBString * key) {
	char * k = (char *)bbStringToUTF8String(key);
	BBString * v = &bbEmptyString;
	const char * value = SteamAPI_ISteamFriends_GetFriendRichPresence(instancePtr, steamIDFriend, k);
	bbMemFree(k);
	if (strlen(value) > 0) {
		v = bbStringFromUTF8String((unsigned char *)value);
	}
	return v;
}

BBString * bmx_SteamAPI_ISteamFriends_GetFriendRichPresenceKeyByIndex(
	ISteamFriends * instancePtr, uint64 steamIDFriend, int key) {
	BBString * v = &bbEmptyString;
	const char * value = SteamAPI_ISteamFriends_GetFriendRichPresenceKeyByIndex(instancePtr, steamIDFriend, key);
	if (strlen(value) > 0) {
		v = bbStringFromUTF8String((unsigned char *)value);
	}
	return v;
}

int bmx_SteamAPI_ISteamFriends_GetFriendRichPresenceKeyCount(ISteamFriends * instancePtr, uint64 steamIDFriend) {
	return SteamAPI_ISteamFriends_GetFriendRichPresenceKeyCount(instancePtr, steamIDFriend);
}

int bmx_SteamAPI_ISteamFriends_GetFriendsGroupCount(ISteamFriends * instancePtr) {
	return SteamAPI_ISteamFriends_GetFriendsGroupCount(instancePtr);
}

BBSHORT bmx_SteamAPI_ISteamFriends_GetFriendsGroupIDByIndex(ISteamFriends * instancePtr, int fg) {
	return SteamAPI_ISteamFriends_GetFriendsGroupIDByIndex(instancePtr, fg);
}

int bmx_SteamAPI_ISteamFriends_GetFriendsGroupMembersCount(ISteamFriends * instancePtr, BBSHORT friendsGroupID) {
	return SteamAPI_ISteamFriends_GetFriendsGroupMembersCount(instancePtr, friendsGroupID);
}

void bmx_SteamAPI_ISteamFriends_GetFriendsGroupMembersList(
	ISteamFriends * instancePtr, BBSHORT friendsGroupID, uint64 * outSteamIDMembers, int membersCount) {
	std::vector<CSteamID> members;
	for (int i = 0; i < membersCount; i++) {
		members.push_back(CSteamID(outSteamIDMembers[i]));
	}

	SteamAPI_ISteamFriends_GetFriendsGroupMembersList(instancePtr, friendsGroupID, members.data(), membersCount);
}

BBString * bmx_SteamAPI_ISteamFriends_GetFriendsGroupName(ISteamFriends * instancePtr, BBSHORT friendsGroupID) {
	BBString * n = &bbEmptyString;
	const char * name = SteamAPI_ISteamFriends_GetFriendsGroupName(instancePtr, friendsGroupID);
	if (strlen(name) > 0) {
		n = bbStringFromUTF8String((unsigned char *)name);
	}
	return n;
}

int bmx_SteamAPI_ISteamFriends_GetFriendSteamLevel(ISteamFriends * instancePtr, uint64 steamIDFriend) {
	return SteamAPI_ISteamFriends_GetFriendSteamLevel(instancePtr, steamIDFriend);
}

int bmx_SteamAPI_ISteamFriends_GetLargeFriendAvatar(ISteamFriends * instancePtr, uint64 steamIDFriend) {
	return SteamAPI_ISteamFriends_GetLargeFriendAvatar(instancePtr, steamIDFriend);
}

int bmx_SteamAPI_ISteamFriends_GetMediumFriendAvatar(ISteamFriends * instancePtr, uint64 steamIDFriend) {
	return SteamAPI_ISteamFriends_GetMediumFriendAvatar(instancePtr, steamIDFriend);
}

BBString * bmx_SteamAPI_ISteamFriends_GetPersonaName(ISteamFriends * instancePtr) {
	BBString * n = &bbEmptyString;
	const char * name = SteamAPI_ISteamFriends_GetPersonaName(instancePtr);
	if (strlen(name) > 0) {
		n = bbStringFromUTF8String((unsigned char *)name);
	}
	return n;
}

EPersonaState bmx_SteamAPI_ISteamFriends_GetPersonaState(ISteamFriends * instancePtr) {
	return SteamAPI_ISteamFriends_GetPersonaState(instancePtr);
}

BBString * bmx_SteamAPI_ISteamFriends_GetPlayerNickname(ISteamFriends * instancePtr, uint64 steamIDPlayer) {
	BBString * n = &bbEmptyString;
	const char * name = SteamAPI_ISteamFriends_GetPlayerNickname(instancePtr, steamIDPlayer);
	if (name != NULL && strlen(name) > 0) {
		n = bbStringFromUTF8String((unsigned char *)name);
	}
	return n;
}

int bmx_SteamAPI_ISteamFriends_GetSmallFriendAvatar(ISteamFriends * instancePtr, uint64 steamIDFriend) {
	return SteamAPI_ISteamFriends_GetSmallFriendAvatar(instancePtr, steamIDFriend);
}

int bmx_SteamAPI_ISteamFriends_HasFriend(ISteamFriends * instancePtr, uint64 steamIDFriend, int friendFlags) {
	return SteamAPI_ISteamFriends_HasFriend(instancePtr, steamIDFriend, friendFlags);
}

int bmx_SteamAPI_ISteamFriends_InviteUserToGame(
	ISteamFriends * instancePtr, uint64 steamIDFriend, BBString * connectString) {
	char * s = (char *)bbStringToUTF8String(connectString);
	bool res = SteamAPI_ISteamFriends_InviteUserToGame(instancePtr, steamIDFriend, s);
	bbMemFree(s);
	return res;
}

int bmx_SteamAPI_ISteamFriends_IsClanChatAdmin(
	ISteamFriends * instancePtr, uint64 steamIDClanChat, uint64 steamIDUser) {
	return SteamAPI_ISteamFriends_IsClanChatAdmin(instancePtr, steamIDClanChat, steamIDUser);
}

int bmx_SteamAPI_ISteamFriends_IsClanPublic(ISteamFriends * instancePtr, uint64 steamIDClan) {
	return SteamAPI_ISteamFriends_IsClanPublic(instancePtr, steamIDClan);
}

int bmx_SteamAPI_ISteamFriends_IsClanOfficialGameGroup(ISteamFriends * instancePtr, uint64 steamIDClan) {
	return SteamAPI_ISteamFriends_IsClanOfficialGameGroup(instancePtr, steamIDClan);
}

int bmx_SteamAPI_ISteamFriends_IsClanChatWindowOpenInSteam(ISteamFriends * instancePtr, uint64 steamIDClanChat) {
	return SteamAPI_ISteamFriends_IsClanChatWindowOpenInSteam(instancePtr, steamIDClanChat);
}

void bmx_SteamAPI_ISteamFriends_IsFollowing(MaxFriends * friends, uint64 steamID) {
	friends->IsFollowing(steamID);
}

int bmx_SteamAPI_ISteamFriends_IsUserInSource(ISteamFriends * instancePtr, uint64 steamIDUser, uint64 steamIDSource) {
	return SteamAPI_ISteamFriends_IsUserInSource(instancePtr, steamIDUser, steamIDSource);
}

void bmx_SteamAPI_ISteamFriends_JoinClanChatRoom(MaxFriends * friends, uint64 steamIDClan) {
	friends->JoinClanChatRoom(steamIDClan);
}

int bmx_SteamAPI_ISteamFriends_LeaveClanChatRoom(ISteamFriends * instancePtr, uint64 steamIDClan) {
	return SteamAPI_ISteamFriends_LeaveClanChatRoom(instancePtr, steamIDClan);
}

int bmx_SteamAPI_ISteamFriends_OpenClanChatWindowInSteam(ISteamFriends * instancePtr, uint64 steamIDClanChat) {
	return SteamAPI_ISteamFriends_OpenClanChatWindowInSteam(instancePtr, steamIDClanChat);
}

int bmx_SteamAPI_ISteamFriends_ReplyToFriendMessage(
	ISteamFriends * instancePtr, uint64 steamIDFriend, BBString * msgToSend) {
	char * m = (char *)bbStringToUTF8String(msgToSend);
	bool res = SteamAPI_ISteamFriends_ReplyToFriendMessage(instancePtr, steamIDFriend, m);
	bbMemFree(m);
	return res;
}

void bmx_SteamAPI_ISteamFriends_RequestClanOfficerList(MaxFriends * friends, uint64 steamIDClan) {
	friends->RequestClanOfficerList(steamIDClan);
}

void bmx_SteamAPI_ISteamFriends_RequestFriendRichPresence(ISteamFriends * instancePtr, uint64 steamIDFriend) {
	SteamAPI_ISteamFriends_RequestFriendRichPresence(instancePtr, steamIDFriend);
}

int bmx_SteamAPI_ISteamFriends_RequestUserInformation(
	ISteamFriends * instancePtr, uint64 steamIDUser, int requireNameOnly) {
	return SteamAPI_ISteamFriends_RequestUserInformation(instancePtr, steamIDUser, requireNameOnly);
}

int bmx_SteamAPI_ISteamFriends_SendClanChatMessage(
	ISteamFriends * instancePtr, uint64 steamIDClanChat, BBString * txt) {
	char * t = (char *)bbStringToUTF8String(txt);
	bool res = SteamAPI_ISteamFriends_SendClanChatMessage(instancePtr, steamIDClanChat, t);
	bbMemFree(t);
	return res;
}

void bmx_SteamAPI_ISteamFriends_SetInGameVoiceSpeaking(ISteamFriends * instancePtr, uint64 steamIDUser, int speaking) {
	SteamAPI_ISteamFriends_SetInGameVoiceSpeaking(instancePtr, steamIDUser, speaking);
}

int bmx_SteamAPI_ISteamFriends_SetListenForFriendsMessages(ISteamFriends * instancePtr, int interceptEnabled) {
	return SteamAPI_ISteamFriends_SetListenForFriendsMessages(instancePtr, interceptEnabled);
}

void bmx_SteamAPI_ISteamFriends_SetPlayedWith(ISteamFriends * instancePtr, uint64 steamIDUserPlayedWith) {
	SteamAPI_ISteamFriends_SetPlayedWith(instancePtr, steamIDUserPlayedWith);
}

int bmx_SteamAPI_ISteamFriends_SetRichPresence(ISteamFriends * instancePtr, BBString * key, BBString * value) {
	char * k = (char *)bbStringToUTF8String(key);
	char * v = (char *)bbStringToUTF8String(value);
	bool res = SteamAPI_ISteamFriends_SetRichPresence(instancePtr, k, v);
	bbMemFree(v);
	bbMemFree(k);
	return res;
}

void bmx_SteamAPI_ISteamFriends_RequestEquippedProfileItems(MaxFriends * friends, uint64 steamID) {
	friends->RequestEquippedProfileItems(steamID);
}

int bmx_SteamAPI_ISteamFriends_BHasEquippedProfileItem(
	ISteamFriends * instancePtr, uint64 steamID, ECommunityProfileItemType itemType) {
	return SteamAPI_ISteamFriends_BHasEquippedProfileItem(instancePtr, steamID, itemType);
}

BBString * bmx_SteamAPI_ISteamFriends_GetProfileItemPropertyString(ISteamFriends * instancePtr, uint64 steamID,
	ECommunityProfileItemType itemType, ECommunityProfileItemProperty property) {
	const char * value = SteamAPI_ISteamFriends_GetProfileItemPropertyString(instancePtr, steamID, itemType, property);
	return bbStringFromUTF8String((const unsigned char *)value);
}

uint32 bmx_SteamAPI_ISteamFriends_GetProfileItemPropertyUint(ISteamFriends * instancePtr, uint64 steamID,
	ECommunityProfileItemType itemType, ECommunityProfileItemProperty property) {
	return SteamAPI_ISteamFriends_GetProfileItemPropertyUint(instancePtr, steamID, itemType, property);
}

// ISteamMatchmaking ---------------------------------------

class MaxMatchmaking
{
private:
	ISteamMatchmaking * instancePtr;
	BBObject * maxHandle;
	CCallResult<MaxMatchmaking, LobbyCreated_t> m_LobbyCreatedCallResult;
	CCallResult<MaxMatchmaking, LobbyMatchList_t> m_LobbyMatchListCallResult;

public:
	STEAM_CALLBACK(MaxMatchmaking, OnLobbyEnter, LobbyEnter_t, m_CallbackLobbyEnter);
	STEAM_CALLBACK(MaxMatchmaking, OnLobbyDataUpdate, LobbyDataUpdate_t, m_CallbackLobbyDataUpdate);
	STEAM_CALLBACK(MaxMatchmaking, OnLobbyChatUpdate, LobbyChatUpdate_t, m_CallbackLobbyChatUpdate);
	STEAM_CALLBACK(MaxMatchmaking, OnLobbyChatMessage, LobbyChatMsg_t, m_CallbackLobbyChatMessage);
	STEAM_CALLBACK(MaxMatchmaking, OnLobbyGameCreated, LobbyGameCreated_t, m_CallbackLobbyGameCreated);
	STEAM_CALLBACK(MaxMatchmaking, OnLobbyInvite, LobbyInvite_t, m_CallbackLobbyInvite);
	STEAM_CALLBACK(MaxMatchmaking, OnLobbyJoinRequested, GameLobbyJoinRequested_t, m_CallbackLobbyJoinRequested);

	MaxMatchmaking(ISteamMatchmaking * instancePtr, BBObject * handle)
		: instancePtr(instancePtr), maxHandle(handle), m_CallbackLobbyEnter(this, &MaxMatchmaking::OnLobbyEnter),
		  m_CallbackLobbyDataUpdate(this, &MaxMatchmaking::OnLobbyDataUpdate),
		  m_CallbackLobbyChatUpdate(this, &MaxMatchmaking::OnLobbyChatUpdate),
		  m_CallbackLobbyChatMessage(this, &MaxMatchmaking::OnLobbyChatMessage),
		  m_CallbackLobbyGameCreated(this, &MaxMatchmaking::OnLobbyGameCreated),
		  m_CallbackLobbyInvite(this, &MaxMatchmaking::OnLobbyInvite),
		  m_CallbackLobbyJoinRequested(this, &MaxMatchmaking::OnLobbyJoinRequested) {
	}

	void RequestLobbyList() {
		SteamAPICall_t call = SteamAPI_ISteamMatchmaking_RequestLobbyList(instancePtr);
		m_LobbyMatchListCallResult.Set(call, this, &MaxMatchmaking::OnLobbyMatchList);
	}

	void CreateLobby(ELobbyType lobbyType, int maxMembers) {
		SteamAPICall_t call = SteamAPI_ISteamMatchmaking_CreateLobby(instancePtr, lobbyType, maxMembers);
		m_LobbyCreatedCallResult.Set(call, this, &MaxMatchmaking::OnLobbyCreated);
	}

	void OnLobbyCreated(LobbyCreated_t * result, bool failure) {
		steam_steamsdk_TSteamMatchmaking__OnLobbyCreated(
			maxHandle, result->m_eResult, result->m_ulSteamIDLobby, failure);
	}

	void OnLobbyMatchList(LobbyMatchList_t * result, bool failure) {
		steam_steamsdk_TSteamMatchmaking__OnLobbyMatchList(maxHandle, result->m_nLobbiesMatching, failure);
	}
};

void MaxMatchmaking::OnLobbyEnter(LobbyEnter_t * result) {
	steam_steamsdk_TSteamMatchmaking__OnLobbyEnter(
		maxHandle, result->m_ulSteamIDLobby, result->m_bLocked, result->m_EChatRoomEnterResponse);
}

void MaxMatchmaking::OnLobbyDataUpdate(LobbyDataUpdate_t * result) {
	steam_steamsdk_TSteamMatchmaking__OnLobbyDataUpdate(
		maxHandle, result->m_ulSteamIDLobby, result->m_ulSteamIDMember, result->m_bSuccess);
}

void MaxMatchmaking::OnLobbyChatUpdate(LobbyChatUpdate_t * result) {
	steam_steamsdk_TSteamMatchmaking__OnLobbyChatUpdate(maxHandle, result->m_ulSteamIDLobby,
		result->m_ulSteamIDUserChanged, result->m_ulSteamIDMakingChange, result->m_rgfChatMemberStateChange);
}

void MaxMatchmaking::OnLobbyChatMessage(LobbyChatMsg_t * result) {
	steam_steamsdk_TSteamMatchmaking__OnLobbyChatMessage(
		maxHandle, result->m_ulSteamIDLobby, result->m_ulSteamIDUser, result->m_eChatEntryType, result->m_iChatID);
}

void MaxMatchmaking::OnLobbyGameCreated(LobbyGameCreated_t * result) {
	steam_steamsdk_TSteamMatchmaking__OnLobbyGameCreated(
		maxHandle, result->m_ulSteamIDLobby, result->m_ulSteamIDGameServer, result->m_unIP, result->m_usPort);
}

void MaxMatchmaking::OnLobbyInvite(LobbyInvite_t * result) {
	steam_steamsdk_TSteamMatchmaking__OnLobbyInvite(
		maxHandle, result->m_ulSteamIDUser, result->m_ulSteamIDLobby, result->m_ulGameID);
}

void MaxMatchmaking::OnLobbyJoinRequested(GameLobbyJoinRequested_t * result) {
	steam_steamsdk_TSteamMatchmaking__OnLobbyJoinRequested(
		maxHandle, result->m_steamIDLobby.ConvertToUint64(), result->m_steamIDFriend.ConvertToUint64());
}

void * bmx_steamsdk_register_steammatchmaking(ISteamMatchmaking * instancePtr, BBObject * obj) {
	return new MaxMatchmaking(instancePtr, obj);
}

void bmx_steamsdk_unregister_steammatchmaking(void * callbackPtr) {
	delete static_cast<MaxMatchmaking *>(callbackPtr);
}

int bmx_SteamAPI_ISteamMatchmaking_GetFavoriteGameCount(ISteamMatchmaking * instancePtr) {
	return SteamAPI_ISteamMatchmaking_GetFavoriteGameCount(instancePtr);
}
int bmx_SteamAPI_ISteamMatchmaking_GetFavoriteGame(ISteamMatchmaking * instancePtr, int index, uint32 * appID,
	uint32 * ip, uint16 * connectionPort, uint16 * queryPort, uint32 * flags, uint32 * lastPlayed) {
	return SteamAPI_ISteamMatchmaking_GetFavoriteGame(
		instancePtr, index, appID, ip, connectionPort, queryPort, flags, lastPlayed);
}
int bmx_SteamAPI_ISteamMatchmaking_AddFavoriteGame(ISteamMatchmaking * instancePtr, uint32 appID, uint32 ip,
	uint16 connectionPort, uint16 queryPort, uint32 flags, uint32 lastPlayed) {
	return SteamAPI_ISteamMatchmaking_AddFavoriteGame(
		instancePtr, appID, ip, connectionPort, queryPort, flags, lastPlayed);
}
int bmx_SteamAPI_ISteamMatchmaking_RemoveFavoriteGame(
	ISteamMatchmaking * instancePtr, uint32 appID, uint32 ip, uint16 connectionPort, uint16 queryPort, uint32 flags) {
	return SteamAPI_ISteamMatchmaking_RemoveFavoriteGame(instancePtr, appID, ip, connectionPort, queryPort, flags);
}

void bmx_SteamAPI_ISteamMatchmaking_AddRequestLobbyListStringFilter(
	ISteamMatchmaking * instancePtr, BBString * key, BBString * value, ELobbyComparison comparison) {
	char * k = (char *)bbStringToUTF8String(key);
	char * v = (char *)bbStringToUTF8String(value);
	SteamAPI_ISteamMatchmaking_AddRequestLobbyListStringFilter(instancePtr, k, v, comparison);
	bbMemFree(v);
	bbMemFree(k);
}

void bmx_SteamAPI_ISteamMatchmaking_AddRequestLobbyListNumericalFilter(
	ISteamMatchmaking * instancePtr, BBString * key, int value, ELobbyComparison comparison) {
	char * k = (char *)bbStringToUTF8String(key);
	SteamAPI_ISteamMatchmaking_AddRequestLobbyListNumericalFilter(instancePtr, k, value, comparison);
	bbMemFree(k);
}

void bmx_SteamAPI_ISteamMatchmaking_AddRequestLobbyListNearValueFilter(
	ISteamMatchmaking * instancePtr, BBString * key, int value) {
	char * k = (char *)bbStringToUTF8String(key);
	SteamAPI_ISteamMatchmaking_AddRequestLobbyListNearValueFilter(instancePtr, k, value);
	bbMemFree(k);
}

void bmx_SteamAPI_ISteamMatchmaking_AddRequestLobbyListResultCountFilter(
	ISteamMatchmaking * instancePtr, int maxResults) {
	SteamAPI_ISteamMatchmaking_AddRequestLobbyListResultCountFilter(instancePtr, maxResults);
}

void bmx_SteamAPI_ISteamMatchmaking_AddRequestLobbyListFilterSlotsAvailable(
	ISteamMatchmaking * instancePtr, int slotsAvailable) {
	SteamAPI_ISteamMatchmaking_AddRequestLobbyListFilterSlotsAvailable(instancePtr, slotsAvailable);
}

void bmx_SteamAPI_ISteamMatchmaking_AddRequestLobbyListDistanceFilter(
	ISteamMatchmaking * instancePtr, ELobbyDistanceFilter distance) {
	SteamAPI_ISteamMatchmaking_AddRequestLobbyListDistanceFilter(instancePtr, distance);
}
void bmx_SteamAPI_ISteamMatchmaking_AddRequestLobbyListCompatibleMembersFilter(
	ISteamMatchmaking * instancePtr, uint64 steamIDLobby) {
	SteamAPI_ISteamMatchmaking_AddRequestLobbyListCompatibleMembersFilter(instancePtr, steamIDLobby);
}

void bmx_SteamAPI_ISteamMatchmaking_RequestLobbyList(MaxMatchmaking * matchmaking) {
	matchmaking->RequestLobbyList();
}
void bmx_SteamAPI_ISteamMatchmaking_CreateLobby(MaxMatchmaking * matchmaking, ELobbyType lobbyType, int maxMembers) {
	matchmaking->CreateLobby(lobbyType, maxMembers);
}
void bmx_SteamAPI_ISteamMatchmaking_JoinLobby(ISteamMatchmaking * instancePtr, uint64 steamIDLobby) {
	SteamAPI_ISteamMatchmaking_JoinLobby(instancePtr, steamIDLobby);
}
void bmx_SteamAPI_ISteamMatchmaking_LeaveLobby(ISteamMatchmaking * instancePtr, uint64 steamIDLobby) {
	SteamAPI_ISteamMatchmaking_LeaveLobby(instancePtr, steamIDLobby);
}
uint64 bmx_SteamAPI_ISteamMatchmaking_GetLobbyByIndex(ISteamMatchmaking * instancePtr, int index) {
	return SteamAPI_ISteamMatchmaking_GetLobbyByIndex(instancePtr, index);
}
int bmx_SteamAPI_ISteamMatchmaking_GetNumLobbyMembers(ISteamMatchmaking * instancePtr, uint64 steamIDLobby) {
	return SteamAPI_ISteamMatchmaking_GetNumLobbyMembers(instancePtr, steamIDLobby);
}
uint64 bmx_SteamAPI_ISteamMatchmaking_GetLobbyMemberByIndex(
	ISteamMatchmaking * instancePtr, uint64 steamIDLobby, int member) {
	return SteamAPI_ISteamMatchmaking_GetLobbyMemberByIndex(instancePtr, steamIDLobby, member);
}

BBString * bmx_SteamAPI_ISteamMatchmaking_GetLobbyData(
	ISteamMatchmaking * instancePtr, uint64 steamIDLobby, BBString * key) {
	char * k = (char *)bbStringToUTF8String(key);
	const char * value = SteamAPI_ISteamMatchmaking_GetLobbyData(instancePtr, steamIDLobby, k);
	BBString * result = bbStringFromUTF8String((const unsigned char *)value);
	bbMemFree(k);
	return result;
}

void bmx_SteamAPI_ISteamUtils_CheckFileSignature(ISteamUtils * instancePtr, BBString * fileName) {
	char * value = (char *)bbStringToUTF8String(fileName);
	SteamAPI_ISteamUtils_CheckFileSignature(instancePtr, value);
	bbMemFree(value);
}
int bmx_SteamAPI_ISteamUtils_IsSteamChinaLauncher(ISteamUtils * instancePtr) {
	return SteamAPI_ISteamUtils_IsSteamChinaLauncher(instancePtr);
}
int bmx_SteamAPI_ISteamUtils_InitFilterText(ISteamUtils * instancePtr, uint32 filterOptions) {
	return SteamAPI_ISteamUtils_InitFilterText(instancePtr, filterOptions);
}
int bmx_SteamAPI_ISteamUtils_FilterText(ISteamUtils * instancePtr, ETextFilteringContext context, uint64 sourceSteamID,
	BBString * input, BBString ** output) {
	char * source = (char *)bbStringToUTF8String(input);
	uint32 capacity = input->length * 4 + 1;
	std::vector<char> filtered(capacity);
	int result =
		SteamAPI_ISteamUtils_FilterText(instancePtr, context, sourceSteamID, source, filtered.data(), capacity);
	*output = bbStringFromUTF8String((unsigned char *)filtered.data());
	bbMemFree(source);
	return result;
}
ESteamIPv6ConnectivityState bmx_SteamAPI_ISteamUtils_GetIPv6ConnectivityState(
	ISteamUtils * instancePtr, ESteamIPv6ConnectivityProtocol protocol) {
	return SteamAPI_ISteamUtils_GetIPv6ConnectivityState(instancePtr, protocol);
}
ESteamHardwareType bmx_SteamAPI_ISteamUtils_IsRunningOnSteamHardware(ISteamUtils * instancePtr) {
	return SteamAPI_ISteamUtils_IsRunningOnSteamHardware(instancePtr);
}

ESteamHardwareDefaultConfig bmx_SteamAPI_ISteamUtils_GetSteamHardwareDefaultConfig(ISteamUtils * instancePtr) {
	return SteamAPI_ISteamUtils_GetSteamHardwareDefaultConfig(instancePtr);
}

int bmx_SteamAPI_ISteamUtils_IsRunningUnderProton(ISteamUtils * instancePtr) {
	return SteamAPI_ISteamUtils_IsRunningUnderProton(instancePtr);
}
int bmx_SteamAPI_ISteamUtils_ShowFloatingGamepadTextInput(
	ISteamUtils * instancePtr, EFloatingGamepadTextInputMode keyboardMode, int x, int y, int width, int height) {
	return SteamAPI_ISteamUtils_ShowFloatingGamepadTextInput(instancePtr, keyboardMode, x, y, width, height);
}
int bmx_SteamAPI_ISteamUtils_DismissFloatingGamepadTextInput(ISteamUtils * instancePtr) {
	return SteamAPI_ISteamUtils_DismissFloatingGamepadTextInput(instancePtr);
}

int bmx_SteamAPI_ISteamUtils_DismissGamepadTextInput(ISteamUtils * instancePtr) {
	return SteamAPI_ISteamUtils_DismissGamepadTextInput(instancePtr);
}
void bmx_SteamAPI_ISteamUtils_SetGameLauncherMode(ISteamUtils * instancePtr, int launcherMode) {
	SteamAPI_ISteamUtils_SetGameLauncherMode(instancePtr, launcherMode);
}
EUniverse bmx_SteamAPI_ISteamUtils_GetConnectedUniverse(ISteamUtils * instancePtr) {
	return SteamAPI_ISteamUtils_GetConnectedUniverse(instancePtr);
}
uint32 bmx_SteamAPI_ISteamUtils_GetIPCCallCount(ISteamUtils * instancePtr) {
	return SteamAPI_ISteamUtils_GetIPCCallCount(instancePtr);
}

int bmx_SteamAPI_ISteamMatchmaking_SetLobbyData(
	ISteamMatchmaking * instancePtr, uint64 steamIDLobby, BBString * key, BBString * value) {
	char * k = (char *)bbStringToUTF8String(key);
	char * v = (char *)bbStringToUTF8String(value);
	bool result = SteamAPI_ISteamMatchmaking_SetLobbyData(instancePtr, steamIDLobby, k, v);
	bbMemFree(v);
	bbMemFree(k);
	return result;
}

int bmx_SteamAPI_ISteamMatchmaking_GetLobbyDataCount(ISteamMatchmaking * instancePtr, uint64 steamIDLobby) {
	return SteamAPI_ISteamMatchmaking_GetLobbyDataCount(instancePtr, steamIDLobby);
}

int bmx_SteamAPI_ISteamMatchmaking_GetLobbyDataByIndex(
	ISteamMatchmaking * instancePtr, uint64 steamIDLobby, int index, BBString ** key, BBString ** value) {
	char k[k_nMaxLobbyKeyLength];
	char v[k_cubChatMetadataMax];
	bool result =
		SteamAPI_ISteamMatchmaking_GetLobbyDataByIndex(instancePtr, steamIDLobby, index, k, sizeof(k), v, sizeof(v));
	if (result) {
		*key = bbStringFromUTF8String((unsigned char *)k);
		*value = bbStringFromUTF8String((unsigned char *)v);
	}
	return result;
}

int bmx_SteamAPI_ISteamMatchmaking_DeleteLobbyData(
	ISteamMatchmaking * instancePtr, uint64 steamIDLobby, BBString * key) {
	char * k = (char *)bbStringToUTF8String(key);
	bool result = SteamAPI_ISteamMatchmaking_DeleteLobbyData(instancePtr, steamIDLobby, k);
	bbMemFree(k);
	return result;
}

BBString * bmx_SteamAPI_ISteamMatchmaking_GetLobbyMemberData(
	ISteamMatchmaking * instancePtr, uint64 steamIDLobby, uint64 steamIDUser, BBString * key) {
	char * k = (char *)bbStringToUTF8String(key);
	const char * value = SteamAPI_ISteamMatchmaking_GetLobbyMemberData(instancePtr, steamIDLobby, steamIDUser, k);
	BBString * result = bbStringFromUTF8String((const unsigned char *)value);
	bbMemFree(k);
	return result;
}

void bmx_SteamAPI_ISteamMatchmaking_SetLobbyMemberData(
	ISteamMatchmaking * instancePtr, uint64 steamIDLobby, BBString * key, BBString * value) {
	char * k = (char *)bbStringToUTF8String(key);
	char * v = (char *)bbStringToUTF8String(value);
	SteamAPI_ISteamMatchmaking_SetLobbyMemberData(instancePtr, steamIDLobby, k, v);
	bbMemFree(v);
	bbMemFree(k);
}

int bmx_SteamAPI_ISteamMatchmaking_SendLobbyChatMsg(
	ISteamMatchmaking * instancePtr, uint64 steamIDLobby, void * data, int size) {
	return SteamAPI_ISteamMatchmaking_SendLobbyChatMsg(instancePtr, steamIDLobby, data, size);
}
int bmx_SteamAPI_ISteamMatchmaking_GetLobbyChatEntry(ISteamMatchmaking * instancePtr, uint64 steamIDLobby, int chatId,
	uint64 * steamIDUser, void * data, int capacity, EChatEntryType * chatEntryType) {
	CSteamID user;
	int result = SteamAPI_ISteamMatchmaking_GetLobbyChatEntry(
		instancePtr, steamIDLobby, chatId, &user, data, capacity, chatEntryType);
	*steamIDUser = user.ConvertToUint64();
	return result;
}
int bmx_SteamAPI_ISteamMatchmaking_RequestLobbyData(ISteamMatchmaking * instancePtr, uint64 steamIDLobby) {
	return SteamAPI_ISteamMatchmaking_RequestLobbyData(instancePtr, steamIDLobby);
}
void bmx_SteamAPI_ISteamMatchmaking_SetLobbyGameServer(
	ISteamMatchmaking * instancePtr, uint64 steamIDLobby, uint32 ip, uint16 port, uint64 steamIDGameServer) {
	SteamAPI_ISteamMatchmaking_SetLobbyGameServer(instancePtr, steamIDLobby, ip, port, steamIDGameServer);
}
int bmx_SteamAPI_ISteamMatchmaking_GetLobbyGameServer(
	ISteamMatchmaking * instancePtr, uint64 steamIDLobby, uint32 * ip, uint16 * port, uint64 * steamIDGameServer) {
	CSteamID server;
	bool result = SteamAPI_ISteamMatchmaking_GetLobbyGameServer(instancePtr, steamIDLobby, ip, port, &server);
	*steamIDGameServer = server.ConvertToUint64();
	return result;
}

int bmx_SteamAPI_ISteamMatchmaking_SetLobbyMemberLimit(
	ISteamMatchmaking * instancePtr, uint64 steamIDLobby, int maxMembers) {
	return SteamAPI_ISteamMatchmaking_SetLobbyMemberLimit(instancePtr, steamIDLobby, maxMembers);
}
int bmx_SteamAPI_ISteamMatchmaking_GetLobbyMemberLimit(ISteamMatchmaking * instancePtr, uint64 steamIDLobby) {
	return SteamAPI_ISteamMatchmaking_GetLobbyMemberLimit(instancePtr, steamIDLobby);
}
int bmx_SteamAPI_ISteamMatchmaking_SetLobbyType(
	ISteamMatchmaking * instancePtr, uint64 steamIDLobby, ELobbyType lobbyType) {
	return SteamAPI_ISteamMatchmaking_SetLobbyType(instancePtr, steamIDLobby, lobbyType);
}
int bmx_SteamAPI_ISteamMatchmaking_SetLobbyJoinable(
	ISteamMatchmaking * instancePtr, uint64 steamIDLobby, int joinable) {
	return SteamAPI_ISteamMatchmaking_SetLobbyJoinable(instancePtr, steamIDLobby, joinable);
}
uint64 bmx_SteamAPI_ISteamMatchmaking_GetLobbyOwner(ISteamMatchmaking * instancePtr, uint64 steamIDLobby) {
	return SteamAPI_ISteamMatchmaking_GetLobbyOwner(instancePtr, steamIDLobby);
}
int bmx_SteamAPI_ISteamMatchmaking_SetLobbyOwner(
	ISteamMatchmaking * instancePtr, uint64 steamIDLobby, uint64 steamIDNewOwner) {
	return SteamAPI_ISteamMatchmaking_SetLobbyOwner(instancePtr, steamIDLobby, steamIDNewOwner);
}
int bmx_SteamAPI_ISteamMatchmaking_SetLinkedLobby(
	ISteamMatchmaking * instancePtr, uint64 steamIDLobby, uint64 steamIDLobbyDependent) {
	return SteamAPI_ISteamMatchmaking_SetLinkedLobby(instancePtr, steamIDLobby, steamIDLobbyDependent);
}
int bmx_SteamAPI_ISteamMatchmaking_InviteUserToLobby(
	ISteamMatchmaking * instancePtr, uint64 steamIDLobby, uint64 steamIDInvitee) {
	return SteamAPI_ISteamMatchmaking_InviteUserToLobby(instancePtr, steamIDLobby, steamIDInvitee);
}

// ISteamNetworkingMessages --------------------------------

class MaxNetworkingMessages
{
private:
	BBObject * maxHandle;

public:
	STEAM_CALLBACK(
		MaxNetworkingMessages, OnSessionRequest, SteamNetworkingMessagesSessionRequest_t, m_CallbackSessionRequest);
	STEAM_CALLBACK(
		MaxNetworkingMessages, OnSessionFailed, SteamNetworkingMessagesSessionFailed_t, m_CallbackSessionFailed);
	MaxNetworkingMessages(BBObject * handle)
		: maxHandle(handle), m_CallbackSessionRequest(this, &MaxNetworkingMessages::OnSessionRequest),
		  m_CallbackSessionFailed(this, &MaxNetworkingMessages::OnSessionFailed) {
	}
};

void MaxNetworkingMessages::OnSessionRequest(SteamNetworkingMessagesSessionRequest_t * result) {
	steam_steamsdk_TSteamNetworkingMessages__OnSessionRequest(maxHandle, result->m_identityRemote.GetSteamID64());
}

void MaxNetworkingMessages::OnSessionFailed(SteamNetworkingMessagesSessionFailed_t * result) {
	steam_steamsdk_TSteamNetworkingMessages__OnSessionFailed(maxHandle, result->m_info.m_identityRemote.GetSteamID64(),
		result->m_info.m_eState, result->m_info.m_eEndReason,
		bbStringFromUTF8String((unsigned char *)result->m_info.m_szEndDebug));
}

static SteamNetworkingIdentity SteamIdentity(uint64 steamID) {
	SteamNetworkingIdentity identity;
	identity.Clear();
	identity.SetSteamID64(steamID);
	return identity;
}

void * bmx_SteamAPI_SteamNetworkingMessages() {
	return SteamAPI_SteamNetworkingMessages_SteamAPI();
}
void * bmx_steamsdk_register_steamnetworkingmessages(ISteamNetworkingMessages *, BBObject * obj) {
	return new MaxNetworkingMessages(obj);
}
void bmx_steamsdk_unregister_steamnetworkingmessages(void * callbackPtr) {
	delete static_cast<MaxNetworkingMessages *>(callbackPtr);
}

EResult bmx_SteamAPI_ISteamNetworkingMessages_SendMessageToUser(ISteamNetworkingMessages * instancePtr,
	uint64 steamIDRemote, void * data, uint32 size, int sendFlags, int remoteChannel) {
	SteamNetworkingIdentity identity = SteamIdentity(steamIDRemote);
	return SteamAPI_ISteamNetworkingMessages_SendMessageToUser(
		instancePtr, identity, data, size, sendFlags, remoteChannel);
}

int bmx_SteamAPI_ISteamNetworkingMessages_ReceiveMessage(ISteamNetworkingMessages * instancePtr, int localChannel,
	void * data, uint32 capacity, uint32 * size, uint64 * steamIDRemote, int * reliable) {
	SteamNetworkingMessage_t * message = nullptr;
	int count = SteamAPI_ISteamNetworkingMessages_ReceiveMessagesOnChannel(instancePtr, localChannel, &message, 1);
	if (count <= 0)
		return 0;
	*size = message->m_cbSize;
	*steamIDRemote = message->m_identityPeer.GetSteamID64();
	*reliable = (message->m_nFlags & k_nSteamNetworkingSend_Reliable) != 0;
	int result = 1;
	if ((uint32)message->m_cbSize > capacity)
		result = -1;
	else if (message->m_cbSize > 0)
		memcpy(data, message->m_pData, message->m_cbSize);
	message->Release();
	return result;
}

int bmx_SteamAPI_ISteamNetworkingMessages_AcceptSessionWithUser(
	ISteamNetworkingMessages * instancePtr, uint64 steamIDRemote) {
	SteamNetworkingIdentity identity = SteamIdentity(steamIDRemote);
	return SteamAPI_ISteamNetworkingMessages_AcceptSessionWithUser(instancePtr, identity);
}
int bmx_SteamAPI_ISteamNetworkingMessages_CloseSessionWithUser(
	ISteamNetworkingMessages * instancePtr, uint64 steamIDRemote) {
	SteamNetworkingIdentity identity = SteamIdentity(steamIDRemote);
	return SteamAPI_ISteamNetworkingMessages_CloseSessionWithUser(instancePtr, identity);
}
int bmx_SteamAPI_ISteamNetworkingMessages_CloseChannelWithUser(
	ISteamNetworkingMessages * instancePtr, uint64 steamIDRemote, int localChannel) {
	SteamNetworkingIdentity identity = SteamIdentity(steamIDRemote);
	return SteamAPI_ISteamNetworkingMessages_CloseChannelWithUser(instancePtr, identity, localChannel);
}

ESteamNetworkingConnectionState bmx_SteamAPI_ISteamNetworkingMessages_GetSessionConnectionInfo(
	ISteamNetworkingMessages * instancePtr, uint64 steamIDRemote, int * endReason, BBString ** endDebug, int * ping,
	float * qualityLocal, float * qualityRemote, int * pendingUnreliable, int * pendingReliable,
	int * sentUnackedReliable, int64 * queueTimeMicroseconds) {
	SteamNetworkingIdentity identity = SteamIdentity(steamIDRemote);
	SteamNetConnectionInfo_t info = {};
	SteamNetConnectionRealTimeStatus_t status = {};
	ESteamNetworkingConnectionState state =
		SteamAPI_ISteamNetworkingMessages_GetSessionConnectionInfo(instancePtr, identity, &info, &status);
	*endReason = info.m_eEndReason;
	*endDebug = bbStringFromUTF8String((unsigned char *)info.m_szEndDebug);
	*ping = status.m_nPing;
	*qualityLocal = status.m_flConnectionQualityLocal;
	*qualityRemote = status.m_flConnectionQualityRemote;
	*pendingUnreliable = status.m_cbPendingUnreliable;
	*pendingReliable = status.m_cbPendingReliable;
	*sentUnackedReliable = status.m_cbSentUnackedReliable;
	*queueTimeMicroseconds = status.m_usecQueueTime;
	return state;
}
