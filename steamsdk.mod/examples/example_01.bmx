SuperStrict

Framework steam.steamsdk
Import brl.standardio

If Not SteamInit() Then
	Print "Steam is not running"
	End
End If


Local client:TSteamClient = New TSteamClient

Local utils:TSteamUtils = client.GetISteamUtils()

Print "Seconds since app active      : " + utils.GetSecondsSinceAppActive()
Print "Seconds since computer active : " + utils.GetSecondsSinceComputerActive()
Print "App ID                        : " + utils.GetAppID()

Print "Remaining Power               : " + utils.GetCurrentBatteryPower()

Local userStats:TSteamUserStats = client.GetISteamUserStats()

Local listener:TUserStats = New TUserStats(userStats)

userStats.SetListener(listener)

Print "count = " + userStats.GetNumAchievements()

userStats.RequestCurrentStats()
userStats.GetNumberOfCurrentPlayers()


For Local i:Int = 0 Until 50
	Delay 100
Next

SteamShutdown()

End

Function ListAchievements(userStats:TSteamUserStats)
	Print "ListAchievements:"
	For Local i:UInt = 0 Until userStats.GetNumAchievements()
		Local achieved:Int
		Local name:String = userStats.GetAchievementName(i)
		userStats.GetAchievement(name, achieved)
		Print "  " + name + " : " + achieved
	Next
End Function


Type TUserStats Implements ISteamUserStatsListener

	Field userStats:TSteamUserStats

	Method New(userStats:TSteamUserStats)
		Self.userStats = userStats
	End Method

	Method OnGlobalAchievementPercentagesReady(gameID:ULong, result:EResult)
		Print "OnGlobalAchievementPercentagesReady"
	End Method
	
	Method OnGlobalStatsReceived(gameID:ULong, result:EResult)
		Print "OnGlobalStatsReceived"
	End Method
	
	Method OnLeaderboardFindResult(leaderboardHandle:ULong, leaderboardFound:Int)
		Print "OnLeaderboardFindResult"
	End Method
	
	Method OnLeaderboardScoresDownloaded(leaderboardHandle:ULong, leaderboardEntriesHandle:ULong, entryCount:Int)
		Print "OnLeaderboardScoresDownloaded"
	End Method
	
	Method OnLeaderboardScoreUploaded(success:Int, leaderboardHandle:ULong, score:UInt, scoreChanged:Int, globalRankNew:Int, globalRankPrevious:Int)
		Print "OnLeaderboardScoreUploaded"
	End Method
	
	Method OnGetNumberOfCurrentPlayers(success:Int, players:Int)
		Print "OnGetNumberOfCurrentPlayers = " + players
	End Method
	
	Method OnUserAchievementIconFetched(gameID:ULong, achievementName:String, achieved:Int, iconHandle:Int)
		Print "OnUserAchievementIconFetched"
	End Method
	
	Method OnUserAchievementStored(gameID:ULong, groupAchievement:Int, achievementName:String, curProgress:UInt, maxProgress:UInt)
		Print "OnUserAchievementStored"
	End Method
	
	Method OnUserStatsReceived(gameID:ULong, result:EResult, steamID:ULong)
		Print "OnUserStatsReceived"
		
		ListAchievements(userStats)
	End Method
	
	Method OnUserStatsStored(gameID:ULong, result:EResult)
		Print "OnUserStatsStored"
	End Method
	
	Method OnUserStatsUnloaded(userID:ULong)
		Print "OnUserStatsUnloaded"
	End Method
	
End Type
