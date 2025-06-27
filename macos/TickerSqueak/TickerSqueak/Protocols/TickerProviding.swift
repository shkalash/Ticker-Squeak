//
//  TickerPayload.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import Combine


protocol TickerProviding {
    /// A publisher that emits new ticker payloads as they are received.
    var payloadPublisher: PassthroughSubject<TickerPayload, Never> { get }
    /// A publisher that emits the current running state of the server.
    var isRunningPublisher: CurrentValueSubject<Bool, Never> { get }
    func start()
    func stop()
}
