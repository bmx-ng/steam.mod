# steam.mod

Steamworks SDK support for BlitzMax NG.

`Steam.SteamSDK` currently wraps utilities, users and identity, achievements
and leaderboards, Workshop/UGC, friends and overlays, matchmaking lobbies, and
Steam Networking Messages. Direct Steam Cloud file access is available through
`TSteamRemoteStorage`, while `TSteamInput` provides action-based controller
input, controller glyphs, motion data, and feedback.

The currently wrapped interface families now include their contemporary public
feature APIs from the bundled Steamworks SDK. See [API_COVERAGE.md](API_COVERAGE.md)
for the distinction between deliberately omitted low-level/deprecated calls and
Steamworks subsystems which do not yet have BlitzMax types.

Call `SteamInit` before creating interfaces from `TSteamClient`. Applications
which want callbacks on their game thread should initialize with
`SteamInit(False)`, call `SteamRunCallbacks` regularly, or switch an existing
initialization with `SteamSetAutoRunCallbacks(False)`.

Lobby applications use `TSteamMatchmaking` and an
`ISteamMatchmakingListener`. `TSteamNetworkingMessages` provides reliable and
unreliable peer messages addressed by 64-bit Steam IDs. Received messages are
copied into a caller-owned buffer and released inside the wrapper.

Cloud-enabled applications can use `TSteamRemoteStorage` for saves and settings.
Related multi-file updates should be enclosed by `BeginFileWriteBatch` and
`EndFileWriteBatch` so Steam treats them as one logical state change.

Steam Input applications should define actions and action sets in an input
action manifest, cache their handles after `TSteamInput.Init`, and read action
state each frame. The supplied action-state structs are unmanaged values, so a
game can reuse them without allocating managed objects in its input loop.
