//
//  AKModalResonanceFilter.swift
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright (c) 2016 Aurelius Prochazka. All rights reserved.
//

import AVFoundation

/// A modal resonance filter used for modal synthesis. Plucked and bell sounds
/// can be created using  passing an impulse through a combination of modal
/// filters.
///
/// - Parameters:
///   - input: Input node to process
///   - frequency: Resonant frequency of the filter.
///   - qualityFactor: Quality factor of the filter. Roughly equal to Q/frequency.
///
open class AKModalResonanceFilter: AKNode, AKToggleable {

    // MARK: - Properties

    internal var internalAU: AKModalResonanceFilterAudioUnit?
    internal var token: AUParameterObserverToken?

    fileprivate var frequencyParameter: AUParameter?
    fileprivate var qualityFactorParameter: AUParameter?

    /// Ramp Time represents the speed at which parameters are allowed to change
    open var rampTime: Double = AKSettings.rampTime {
        willSet {
            if rampTime != newValue {
                internalAU?.rampTime = newValue
                internalAU?.setUpParameterRamp()
            }
        }
    }

    /// Resonant frequency of the filter.
    open var frequency: Double = 500.0 {
        willSet {
            if frequency != newValue {
                if internalAU!.isSetUp() {
                    frequencyParameter?.setValue(Float(newValue), originator: token!)
                } else {
                    internalAU?.frequency = Float(newValue)
                }
            }
        }
    }
    /// Quality factor of the filter. Roughly equal to Q/frequency.
    open var qualityFactor: Double = 50.0 {
        willSet {
            if qualityFactor != newValue {
                if internalAU!.isSetUp() {
                    qualityFactorParameter?.setValue(Float(newValue), originator: token!)
                } else {
                    internalAU?.qualityFactor = Float(newValue)
                }
            }
        }
    }

    /// Tells whether the node is processing (ie. started, playing, or active)
    open var isStarted: Bool {
        return internalAU!.isPlaying()
    }

    // MARK: - Initialization

    /// Initialize this filter node
    ///
    /// - Parameters:
    ///   - input: Input node to process
    ///   - frequency: Resonant frequency of the filter.
    ///   - qualityFactor: Quality factor of the filter. Roughly equal to Q/frequency.
    ///
    public init(
        _ input: AKNode,
        frequency: Double = 500.0,
        qualityFactor: Double = 50.0) {

        self.frequency = frequency
        self.qualityFactor = qualityFactor

        let description = AudioComponentDescription(effect: "modf")

        AUAudioUnit.registerSubclass(
            AKModalResonanceFilterAudioUnit.self,
            as: description,
            name: "Local AKModalResonanceFilter",
            version: UInt32.max)

        super.init()
        AVAudioUnit.instantiate(with: description, options: []) {
            avAudioUnit, error in

            guard let avAudioUnitEffect = avAudioUnit else { return }

            self.avAudioNode = avAudioUnitEffect
            self.internalAU = avAudioUnitEffect.auAudioUnit as? AKModalResonanceFilterAudioUnit

            AudioKit.engine.attach(self.avAudioNode)
            input.addConnectionPoint(self)
        }

        guard let tree = internalAU?.parameterTree else { return }

        frequencyParameter     = tree["frequency"]
        qualityFactorParameter = tree["qualityFactor"]

        token = tree.token (byAddingParameterObserver: {
            address, value in

            DispatchQueue.main.async {
                if address == self.frequencyParameter!.address {
                    self.frequency = Double(value)
                } else if address == self.qualityFactorParameter!.address {
                    self.qualityFactor = Double(value)
                }
            }
        })

        internalAU?.frequency = Float(frequency)
        internalAU?.qualityFactor = Float(qualityFactor)
    }

    // MARK: - Control

    /// Function to start, play, or activate the node, all do the same thing
    open func start() {
        self.internalAU!.start()
    }

    /// Function to stop or bypass the node, both are equivalent
    open func stop() {
        self.internalAU!.stop()
    }
}
