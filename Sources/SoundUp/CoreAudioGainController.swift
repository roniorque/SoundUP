import AudioToolbox
import CoreAudio
import Foundation
import SoundUpCore

/// Real Core Audio-backed implementation of `ProcessGainController`.
///
/// For each controlled app, this creates a private Process Tap on that app's
/// audio (muted at the source, so the original unmodified audio never reaches
/// hardware directly), wraps it in a private aggregate device alongside the
/// system's default output device, and installs an IOProc that copies the
/// tap's input buffers to the aggregate's output buffers scaled by the
/// current gain.
///
/// This is the least-verified part of SoundUp: it depends on Apple's Process
/// Tap API family (available from macOS 14.4), assumes a 32-bit-float,
/// buffer-count-matching stream format between the tap and the default
/// output device, and uses a simple lock for cross-thread gain updates into
/// the real-time audio callback. All of this needs manual, on-hardware
/// verification and likely iteration in Xcode — see Issue 0002 in
/// docs/issues/0001-soundup/.
@available(macOS 14.4, *)
final class CoreAudioGainController: ProcessGainController {
    enum GainControllerError: Error {
        case processNotFound
        case tapCreationFailed(OSStatus)
        case aggregateDeviceCreationFailed(OSStatus)
        case ioProcCreationFailed(OSStatus)
        case deviceStartFailed(OSStatus)
        case defaultOutputDeviceUnavailable(OSStatus)
    }

    /// Thread-safe box for the current gain, read from the real-time audio
    /// callback and written from the main/UI thread.
    private final class GainBox {
        private let lock = NSLock()
        private var _value: Double

        init(value: Double) {
            _value = value
        }

        var value: Double {
            get { lock.lock(); defer { lock.unlock() }; return _value }
            set { lock.lock(); defer { lock.unlock() }; _value = newValue }
        }
    }

    /// Thread-safe call counter for `[DEBUG-au1]` IOProc instrumentation (BUG-1).
    private final class DebugCounter {
        private let lock = NSLock()
        private var count = 0

        func increment() -> Int {
            lock.lock(); defer { lock.unlock() }
            count += 1
            return count
        }
    }

    private struct ActiveControl {
        var tapID: AudioObjectID
        var aggregateDeviceID: AudioObjectID
        var ioProcID: AudioDeviceIOProcID
        var gainBox: GainBox
    }

    private var controls: [String: ActiveControl] = [:]

    func setGain(_ gain: Double, forBundleID bundleID: String) {
        if let existing = controls[bundleID] {
            existing.gainBox.value = gain
            return
        }

        do {
            controls[bundleID] = try createControl(forBundleID: bundleID, initialGain: gain)
        } catch {
            NSLog("SoundUp: failed to create audio control for \(bundleID): \(error)")
        }
    }

    func removeControl(forBundleID bundleID: String) {
        guard let control = controls.removeValue(forKey: bundleID) else { return }
        AudioDeviceStop(control.aggregateDeviceID, control.ioProcID)
        AudioDeviceDestroyIOProcID(control.aggregateDeviceID, control.ioProcID)
        AudioHardwareDestroyAggregateDevice(control.aggregateDeviceID)
        AudioHardwareDestroyProcessTap(control.tapID)
    }

    // MARK: - Control creation

    private func createControl(forBundleID bundleID: String, initialGain: Double) throws -> ActiveControl {
        let processIDs = Self.audioProcessObjectIDs(forBundleID: bundleID)
        guard !processIDs.isEmpty else { throw GainControllerError.processNotFound }

        let tapDescription = CATapDescription()
        tapDescription.processes = processIDs
        tapDescription.isMono = false
        tapDescription.isMixdown = true
        tapDescription.isExclusive = false
        tapDescription.isPrivate = true
        // Mute the tapped process at the source: SoundUp sends its own
        // gain-adjusted copy to the output device instead.
        tapDescription.muteBehavior = .muted

        var tapID: AudioObjectID = 0
        var status = AudioHardwareCreateProcessTap(tapDescription, &tapID)
        guard status == noErr else { throw GainControllerError.tapCreationFailed(status) }
        let tapUID = tapDescription.uuid.uuidString

        let outputDeviceID: AudioObjectID
        let outputUID: String
        do {
            outputDeviceID = try Self.defaultOutputDeviceID()
            outputUID = try Self.deviceUID(for: outputDeviceID)
        } catch {
            AudioHardwareDestroyProcessTap(tapID)
            throw error
        }

        let composition: [String: Any] = [
            kAudioAggregateDeviceNameKey: "SoundUp (\(bundleID))",
            kAudioAggregateDeviceUIDKey: UUID().uuidString,
            kAudioAggregateDeviceMainSubDeviceKey: outputUID,
            kAudioAggregateDeviceIsPrivateKey: true,
            kAudioAggregateDeviceSubDeviceListKey: [
                [kAudioSubDeviceUIDKey: outputUID]
            ],
            kAudioAggregateDeviceTapListKey: [
                [kAudioSubTapUIDKey: tapUID]
            ],
        ]

        var aggregateDeviceID: AudioObjectID = 0
        status = AudioHardwareCreateAggregateDevice(composition as CFDictionary, &aggregateDeviceID)
        guard status == noErr else {
            AudioHardwareDestroyProcessTap(tapID)
            throw GainControllerError.aggregateDeviceCreationFailed(status)
        }

        NSLog(
            "[DEBUG-au1] tap+aggregate created for \(bundleID): tapUID=\(tapUID) tapID=\(tapID) "
            + "aggregateDeviceID=\(aggregateDeviceID) outputUID=\(outputUID)"
        )

        let gainBox = GainBox(value: initialGain)
        let callCounter = DebugCounter()
        var ioProcID: AudioDeviceIOProcID?
        status = AudioDeviceCreateIOProcIDWithBlock(
            &ioProcID, aggregateDeviceID, nil
        ) { _, inInputData, _, outOutputData, _ in
            let callNumber = callCounter.increment()
            if callNumber <= 3 || callNumber % 200 == 0 {
                let inputList = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: inInputData))
                let outputList = UnsafeMutableAudioBufferListPointer(outOutputData)
                let inputDescription = inputList.map { "\($0.mNumberChannels)ch/\($0.mDataByteSize)B/nonNil=\($0.mData != nil)" }
                let outputDescription = outputList.map { "\($0.mNumberChannels)ch/\($0.mDataByteSize)B/nonNil=\($0.mData != nil)" }
                NSLog(
                    "[DEBUG-au1] IOProc call #\(callNumber) for \(bundleID): "
                    + "input=\(inputDescription) output=\(outputDescription)"
                )
            }
            Self.applyGain(gainBox.value, from: inInputData, to: outOutputData)
        }
        guard status == noErr, let ioProcID else {
            AudioHardwareDestroyAggregateDevice(aggregateDeviceID)
            AudioHardwareDestroyProcessTap(tapID)
            throw GainControllerError.ioProcCreationFailed(status)
        }

        status = AudioDeviceStart(aggregateDeviceID, ioProcID)
        guard status == noErr else {
            AudioDeviceDestroyIOProcID(aggregateDeviceID, ioProcID)
            AudioHardwareDestroyAggregateDevice(aggregateDeviceID)
            AudioHardwareDestroyProcessTap(tapID)
            throw GainControllerError.deviceStartFailed(status)
        }

        NSLog("[DEBUG-au1] AudioDeviceStart succeeded for \(bundleID)")

        return ActiveControl(
            tapID: tapID, aggregateDeviceID: aggregateDeviceID, ioProcID: ioProcID, gainBox: gainBox
        )
    }

    // MARK: - Real-time audio callback

    private static func applyGain(
        _ gain: Double,
        from inputData: UnsafePointer<AudioBufferList>,
        to outputData: UnsafeMutablePointer<AudioBufferList>
    ) {
        let inputList = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: inputData))
        let outputList = UnsafeMutableAudioBufferListPointer(outputData)
        let gainFactor = Float32(gain)

        for bufferIndex in 0..<min(inputList.count, outputList.count) {
            guard
                let inputBytes = inputList[bufferIndex].mData,
                let outputBytes = outputList[bufferIndex].mData
            else { continue }

            let frameCount = Int(outputList[bufferIndex].mDataByteSize) / MemoryLayout<Float32>.size
            let inputSamples = inputBytes.assumingMemoryBound(to: Float32.self)
            let outputSamples = outputBytes.assumingMemoryBound(to: Float32.self)

            for frame in 0..<frameCount {
                outputSamples[frame] = inputSamples[frame] * gainFactor
            }
        }
    }

    // MARK: - Core Audio helpers

    private static func audioProcessObjectIDs(forBundleID bundleID: String) -> [AudioObjectID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessObjectList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize
        )
        guard status == noErr, dataSize > 0 else { return [] }

        let count = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var processIDs = [AudioObjectID](repeating: 0, count: count)
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &processIDs
        )
        guard status == noErr else { return [] }

        return processIDs.filter { Self.bundleID(for: $0) == bundleID }
    }

    private static func bundleID(for processID: AudioObjectID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioProcessPropertyBundleID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(processID, &address, 0, nil, &dataSize)
        guard status == noErr, dataSize > 0 else { return nil }

        var cfStringRef: CFString? = nil
        status = withUnsafeMutablePointer(to: &cfStringRef) { pointer -> OSStatus in
            AudioObjectGetPropertyData(processID, &address, 0, nil, &dataSize, pointer)
        }
        guard status == noErr, let cfStringRef else { return nil }
        return cfStringRef as String
    }

    private static func defaultOutputDeviceID() throws -> AudioObjectID {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID: AudioObjectID = 0
        var dataSize = UInt32(MemoryLayout<AudioObjectID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &deviceID
        )
        guard status == noErr else { throw GainControllerError.defaultOutputDeviceUnavailable(status) }
        return deviceID
    }

    private static func deviceUID(for deviceID: AudioObjectID) throws -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize = UInt32(MemoryLayout<CFString?>.size)
        var cfStringRef: CFString? = nil
        let status = withUnsafeMutablePointer(to: &cfStringRef) { pointer -> OSStatus in
            AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, pointer)
        }
        guard status == noErr, let cfStringRef else {
            throw GainControllerError.defaultOutputDeviceUnavailable(status)
        }
        return cfStringRef as String
    }
}
