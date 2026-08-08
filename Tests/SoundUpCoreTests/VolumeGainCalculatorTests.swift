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

    @Test("the maximum slider percent is 3000%, enough headroom to counteract macOS call-ducking (~10x reduction)")
    func maxPercentIsThreeThousand() {
        #expect(VolumeGainCalculator.maxPercent == 3000)
    }

    @Test("200% boosts gain above unity")
    func twoHundredPercentBoostsAboveUnity() {
        #expect(VolumeGainCalculator.gain(forPercent: 200) > 1.0)
    }

    @Test("boost is fully linear (uncompressed) up to the compression threshold (2000%)")
    func boostIsFullyLinearUpToThreshold() {
        for percent: Double in [150, 500, 1000, 1500, 2000] {
            let expectedLinear = percent / 100.0
            #expect(abs(VolumeGainCalculator.gain(forPercent: percent) - expectedLinear) < 0.0001)
        }
    }

    @Test("boost above the compression threshold is gently limited below the unlimited linear equivalent")
    func boostAboveThresholdIsLimitedBelowLinear() {
        for percent: Double in [2200, 2500, 2800, 3000] {
            let limited = VolumeGainCalculator.gain(forPercent: percent)
            let unlimitedLinearEquivalent = percent / 100.0
            #expect(limited < unlimitedLinearEquivalent)
        }
    }

    @Test("gain at max percent still retains at least 20x — enough to counteract a ~10x system duck with margin")
    func gainAtMaxIsStillSubstantial() {
        let limited = VolumeGainCalculator.gain(forPercent: 3000)
        #expect(limited >= 20.0)
    }

    @Test("gain is monotonically increasing across the full range")
    func gainIsMonotonicallyIncreasing() {
        let percents: [Double] = [0, 25, 50, 75, 100, 500, 1000, 1500, 2000, 2200, 2500, 2800, 3000]
        let gains = percents.map { VolumeGainCalculator.gain(forPercent: $0) }
        for i in 1..<gains.count {
            #expect(gains[i] > gains[i - 1])
        }
    }

    @Test("values are clamped to the 0-3000 slider range")
    func valuesAreClampedToSliderRange() {
        #expect(VolumeGainCalculator.gain(forPercent: -50) == VolumeGainCalculator.gain(forPercent: 0))
        #expect(VolumeGainCalculator.gain(forPercent: 5000) == VolumeGainCalculator.gain(forPercent: 3000))
    }
}
