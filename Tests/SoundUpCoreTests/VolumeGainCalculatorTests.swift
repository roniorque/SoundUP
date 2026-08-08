import Testing
@testable import SoundUpCore

@Suite("VolumeGainCalculator")
struct VolumeGainCalculatorTests {
    @Test("0% is fully silent")
    func zeroPercentIsFullySilent() {
        #expect(abs(VolumeGainCalculator.gain(forPercent: 0) - 0.0) < 0.0001)
    }

    @Test("100% is unity gain")
    func hundredPercentIsUnityGain() {
        #expect(abs(VolumeGainCalculator.gain(forPercent: 100) - 1.0) < 0.0001)
    }

    @Test("50% is half gain")
    func fiftyPercentIsHalfGain() {
        #expect(abs(VolumeGainCalculator.gain(forPercent: 50) - 0.5) < 0.0001)
    }

    @Test("200% boosts gain above unity")
    func twoHundredPercentBoostsAboveUnity() {
        #expect(VolumeGainCalculator.gain(forPercent: 200) > 1.0)
    }

    @Test("boost above 100% is limited below unlimited linear gain")
    func boostIsLimitedBelowLinearEquivalent() {
        let limited = VolumeGainCalculator.gain(forPercent: 200)
        let unlimitedLinearEquivalent = 200.0 / 100.0 // what linear scaling would give: 2.0
        #expect(limited < unlimitedLinearEquivalent)
    }

    @Test("gain is monotonically increasing across the full range")
    func gainIsMonotonicallyIncreasing() {
        let percents: [Double] = [0, 25, 50, 75, 100, 125, 150, 175, 200]
        let gains = percents.map { VolumeGainCalculator.gain(forPercent: $0) }
        for i in 1..<gains.count {
            #expect(gains[i] > gains[i - 1])
        }
    }

    @Test("values are clamped to the 0-200 slider range")
    func valuesAreClampedToSliderRange() {
        #expect(VolumeGainCalculator.gain(forPercent: -50) == VolumeGainCalculator.gain(forPercent: 0))
        #expect(VolumeGainCalculator.gain(forPercent: 500) == VolumeGainCalculator.gain(forPercent: 200))
    }
}
