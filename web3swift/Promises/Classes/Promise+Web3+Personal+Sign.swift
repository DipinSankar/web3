//
//  Promise+Web3+Personal+Sign.swift
//  web3swift
//
//  Created by Alexander Vlasov on 18.06.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import BigInt
import PromiseKit

extension web3.Personal {
    
    func sendPersonalMessagePromise(message: Data, from: EthereumAddress, password:String = "BANKEXFOUNDATION") -> Promise<Data> {
        let queue = web3.requestDispatcher.queue
        do {
            if self.web3.provider.attachedKeystoreManager == nil {
                let hexData = message.toHexString().addHexPrefix()
                let request = JSONRPCRequestFabric.prepareRequest(.personalSign, parameters: [from.address.lowercased(), hexData])
                return self.web3.dispatch(request).map(on: queue) {response in
                    guard let value: Data = response.getValue() else {
                        throw Web3Error.nodeError("Invalid value from Ethereum node")
                    }
                    return value
                }
            }
            guard let signature = try Web3Signer.signPersonalMessage(message, keystore: self.web3.provider.attachedKeystoreManager!, account: from, password: password) else { throw Web3Error.inputError("Failed to locally sign a message") }
            let returnPromise = Promise<Data>.pending()
            queue.async {
                returnPromise.resolver.fulfill(signature)
            }
            return returnPromise.promise
        } catch {
            let returnPromise = Promise<Data>.pending()
            queue.async {
                returnPromise.resolver.reject(error)
            }
            return returnPromise.promise
        }
    }
}
