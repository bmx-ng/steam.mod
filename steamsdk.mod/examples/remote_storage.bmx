SuperStrict

Framework steam.steamsdk
Import brl.standardio

Const EXAMPLE_FILE:String = "blitzmax-remote-storage-example.dat"

If Not SteamInit(False) Then
	Print "Steam is not running"
	End
End If

Local client:TSteamClient = New TSteamClient
Local storage:TSteamRemoteStorage = client.GetISteamRemoteStorage()
If Not storage Then
	Print "Steam Remote Storage is unavailable"
	SteamShutdown()
	End
End If

Print "Cloud enabled for account: " + storage.IsCloudEnabledForAccount()
Print "Cloud enabled for app: " + storage.IsCloudEnabledForApp()

Local totalBytes:ULong
Local availableBytes:ULong
If storage.GetQuota(totalBytes, availableBytes) Then
	Print "Cloud quota: " + availableBytes + " of " + totalBytes + " bytes available"
End If

Local writtenValue:UInt = $42584d58
If storage.FileWrite(EXAMPLE_FILE, Byte Ptr(Varptr writtenValue), Int(SizeOf(writtenValue))) Then
	Local readValue:UInt
	Local bytesRead:Int = storage.FileRead(EXAMPLE_FILE, Byte Ptr(Varptr readValue), Int(SizeOf(readValue)))
	Print "Read " + bytesRead + " bytes; value matches: " + (readValue = writtenValue)
	Print "Persisted: " + storage.FilePersisted(EXAMPLE_FILE)
	Print "Sync platforms: " + storage.GetSyncPlatforms(EXAMPLE_FILE)
	Print "Deleted example file: " + storage.FileDelete(EXAMPLE_FILE)
Else
	Print "The example file could not be written"
End If

SteamShutdown()
