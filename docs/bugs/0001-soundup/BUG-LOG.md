# Bug Log — SoundUp

| Bug | Status | Summary |
|-----|--------|---------|
| [BUG-2](./BUG-2.md) | open | Apps already playing audio before SoundUp launches are not detected |
| [BUG-1](../closed/0001-soundup/BUG-1.md) | closed (verified) | No audio produced despite successful Core Audio tap/aggregate/IOProc setup — root cause was tapping a spurious blank-bundle-ID process alongside the real one, causing dual-aggregate-device conflict on the same output. |
