//
//  BackupService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 25.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@available(iOS 13.0, *)
public class BackupService {
    private let sdk: TangemSdk
    private var delegate: BackupServiceDelegate
    private var repo: BackupRepo = .init()
    private var cancellable: AnyCancellable? = nil
    
    public init(sdk: TangemSdk, delegate: BackupServiceDelegate) {
        self.sdk = sdk
        self.delegate = delegate
    }
    
    public func start() {
        cancellable = Just(())
            .setFailureType(to: TangemSdkError.self)
            .flatMap {[unowned self] in self.getBackupCardsCount() }
            .flatMap {[unowned self] _ in self.readOriginCard() }
            .sink(receiveCompletion: {[unowned self] completion in
                switch completion {
                case .finished:
                    self.delegate.onSuccess()
                case .failure(let error):
                    self.delegate.onError(error)
                }
            }, receiveValue: { value in
                print(value)
            })
    }
    
    private func getBackupCardsCount() -> AnyPublisher<Int, TangemSdkError> {
        if let count = repo.backupCardsCount {
            return Just(count)
                .setFailureType(to: TangemSdkError.self)
                .eraseToAnyPublisher()
        }
        
        return delegate.getBackupCardsCount()
            .handleEvents(receiveOutput: {[weak self] count in
                self?.repo.backupCardsCount = count
            })
            .eraseToAnyPublisher()
    }
    
    private func readOriginCard() -> AnyPublisher<Card, TangemSdkError> {
        if let card = repo.originCard {
            return Just(card)
                .setFailureType(to: TangemSdkError.self)
                .eraseToAnyPublisher()
        }
        
        return sdk
            .startSessionPublisher(with: ScanTask())
            .handleEvents(receiveOutput: {[weak self] card in
                self?.repo.originCard = card
            })
            .eraseToAnyPublisher()
    }
}

@available(iOS 13.0, *)
class BackupRepo {
    var backupCardsCount: Int? = nil
    var originCard: Card? = nil
}

@available(iOS 13.0, *)
public protocol BackupServiceDelegate {
    func getBackupCardsCount() -> AnyPublisher<Int, TangemSdkError>
    func onSuccess()
    func onError(_ error: TangemSdkError)
}

@available(iOS 13.0, *)
public class DefaultBackupServiceDelegate: BackupServiceDelegate {
    public func getBackupCardsCount() -> AnyPublisher<Int, TangemSdkError> {
        return Just(2)
            .setFailureType(to: TangemSdkError.self)
            .eraseToAnyPublisher()
    }
    
    public func onSuccess() {
        print("Backup created!!!")
    }
    
    public func onError(_ error: TangemSdkError) {
        print(error)
    }
}
