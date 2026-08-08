# Bug Log — SoundUp

| Bug | Status | Summary |
|-----|--------|---------|
| [BUG-3](../closed/0001-soundup/BUG-3.md) | closed (verified) | Other apps sound capped during active FaceTime calls due to macOS's system-wide call-ducking (~10x reduction) — fixed by raising max boost to 3000% (~22.5x), enough to out-muscle the ducking at the cost of some distortion at extreme settings. |
| [BUG-2](./BUG-2.md) | open | Idle-app list filter shows non-media regular apps (Terminal, code editors) as noise — needs a tighter heuristic (e.g. only show idle apps with a previously saved custom setting). |
| [BUG-1](../closed/0001-soundup/BUG-1.md) | closed (verified) | No audio produced despite successful Core Audio tap/aggregate/IOProc setup — root cause was tapping a spurious blank-bundle-ID process alongside the real one, causing dual-aggregate-device conflict on the same output. |
