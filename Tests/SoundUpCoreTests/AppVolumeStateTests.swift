import Testing
@testable import SoundUpCore

@Suite("AppVolumeState")
struct AppVolumeStateTests {
    @Test("starts unmuted at the given percent")
    func startsUnmutedAtGivenPercent() {
        let state = AppVolumeState(percent: 150)
        #expect(state.isMuted == false)
        #expect(state.percent == 150)
    }

    @Test("muting silences effective gain without changing stored percent")
    func mutingSilencesWithoutChangingPercent() {
        var state = AppVolumeState(percent: 150)
        state.mute()
        #expect(state.isMuted == true)
        #expect(state.percent == 150)
        #expect(state.effectiveGain == 0.0)
    }

    @Test("unmuting restores gain at the preserved percent")
    func unmutingRestoresGainAtPreservedPercent() {
        var state = AppVolumeState(percent: 150)
        state.mute()
        state.unmute()
        #expect(state.isMuted == false)
        #expect(state.percent == 150)
        #expect(state.effectiveGain == VolumeGainCalculator.gain(forPercent: 150))
    }

    @Test("moving the slider while muted updates percent but stays silent")
    func movingSliderWhileMutedStaysSilent() {
        var state = AppVolumeState(percent: 100)
        state.mute()
        state.percent = 180
        #expect(state.isMuted == true)
        #expect(state.effectiveGain == 0.0)
        state.unmute()
        #expect(state.effectiveGain == VolumeGainCalculator.gain(forPercent: 180))
    }
}
