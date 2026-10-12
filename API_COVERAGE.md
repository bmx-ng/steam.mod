# Steamworks API coverage

This module wraps selected Steamworks interface families rather than presenting
the entire SDK as one undifferentiated API. The list below describes the bundled
Steamworks SDK (1.53a); a future SDK update may add more methods or interfaces.
The native bridge obtains interfaces using the version macros from the bundled
SDK headers, rather than duplicating those strings in bridge calls. The public
constants mirror those header versions for reference. When the SDK is updated,
the affected interfaces still need review because Steam interfaces are
versioned ABI contracts.

## Covered interface families

- `ISteamApps`: subscriptions, languages, DLC, beta/build information, install
  locations, ownership, launch parameters, family sharing, timed trials, file
  details, and related callbacks.
- `ISteamUser`: identity, login state, voice capture/decompression,
  authentication tickets and validation, licence checks, encrypted app tickets,
  account security state, store authentication, and duration controls. The two
  obsolete game-connection methods are intentionally omitted.
- `ISteamFriends`: friends, clans, chat, personas, avatars, rich presence, and
  overlay/invitation operations.
- `ISteamMatchmaking`: favourites, lobby filters, creation and joining,
  membership, metadata, chat, game-server association, ownership, linked
  lobbies, and callbacks.
- `ISteamNetworkingMessages`: reliable/unreliable sending, receiving, session
  acceptance and closure, failure callbacks, and connection diagnostics. The
  wrapper's `ReceiveMessage` consumes one native message safely rather than
  exposing Steam-owned message pointers.
- `ISteamRemoteStorage`: synchronous and asynchronous Steam Cloud reads and
  writes, streamed writes, file enumeration and metadata, quota and enablement
  state, platform sync selection, synchronized-change inspection, and related
  write batching. Asynchronous writes retain their own data and concurrent
  operations have independent call-result ownership. Legacy Workshop calls are
  omitted in favour of `ISteamUGC`.
- `ISteamUserStats`: achievements, local and remote stats, global stats,
  leaderboards, downloaded entries, progress limits, attached UGC, and callbacks.
- `ISteamUtils`: application/platform information, images, overlay and text
  input, text filtering, Steam Deck and IPv6 checks, launcher mode, signature
  checks, and callbacks. Raw `SteamAPICall_t` inspection and the native warning
  function pointer are intentionally kept internal because typed call-result
  handlers are safer in BlitzMax.
- `ISteamUGC`: Workshop queries and result details, tags and metadata, item
  creation/update/subscription, dependencies, playtime, EULA state, and
  callbacks. The deprecated `RequestUGCDetails` call is omitted in favour of
  `CreateQueryUGCDetailsRequest`.

## Steamworks subsystems not yet wrapped

These are complete service areas, not accidental holes in the interfaces above:

- Steam Input and the deprecated Steam Controller interface
- Inventory
- HTTP
- Networking Sockets and Networking Utils
- Dedicated game-server APIs and game-server stats
- Matchmaking server browser, ping, player, and rules queries
- Screenshots
- Remote Play and Parties
- Parental Settings
- App List
- Video and Music/Music Remote
- HTML Surface
- Game Search

They should be added as focused types with appropriate BlitzMax value objects
and callback listeners. In particular, exposing native structures or callback
pointers directly would make the wrapper fragile and is not considered useful
coverage.
