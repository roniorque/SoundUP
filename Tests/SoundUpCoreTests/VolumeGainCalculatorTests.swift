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

    @Test("the maximum slider percent is 500%")
    func maxPercentIsFiveHundred() {
        #expect(VolumeGainCalculator.maxPercent == 500)
    }

    @Test("200% boosts gain above unity")
    func twoHundredPercentBoostsAboveUnity() {
        #expect(VolumeGainCalculator.gain(forPercent: 200) > 1.0)
    }

    @Test("gain keeps increasing meaningfully well past 200%, not just plateauing")
    func gainKeepsIncreasingPastTwoHundredPercent() {
        let at300 = VolumeGainCalculator.gain(forPercent: 300)
        let at500 = VolumeGainCalculator.gain(forPercent: 500)
        // At least 20% louder at the new max than at 300%, so raising the cap to 500%
        // actually buys meaningfully more loudness rather than saturating early.
        #expect(at500 > at300 * 1.2)
    }

    @Test("boost above 100% is limited below unlimited linear gain, at every boosted percent")
    func boostIsLimitedBelowLinearEquivalent() {
        for percent: Double in [150, 200, 300, 400, 500] {
            let limited = VolumeGainCalculator.gain(forPercent: percent)
            let unlimitedLinearEquivalent = percent / 100.0
            #expect(limited < unlimitedLinearEquivalent)
        }
    }

    @Test("gain is monotonically increasing across the full range")
    func gainIsMonotonicallyIncreasing() {
        let percents: [Double] = [0, 25, 50, 75, 100, 150, 200, 250, 300, 350, 400, 450, 500]
        let gains = percents.map { VolumeGainCalculator.gain(forPercent: $0) }
        for i in 1..<gains.count {
            #expect(gains[i] > gains[i - 1])
        }
    }

    @Test("values are clamped to the 0-500 slider range")
    func valuesAreClampedToSliderRange() {
        #expect(VolumeGainCalculator.gain(forPercent: -50) == VolumeGainCalculator.gain(forPercent: 0))
        #expect(VolumeGainCalculator.gain(forPercent: 1000) == VolumeGainCalculator.gain(forPercent: 500))
    }
}
