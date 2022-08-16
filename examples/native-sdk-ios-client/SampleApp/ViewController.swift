//
//  ViewController.swift
//  SampleWeb3App
//
//  Created by Jungho Bang on 6/27/22.
//

import UIKit
import CoinbaseWalletSDK

class ViewController: UITableViewController {
    
    @IBOutlet weak var isCBWalletInstalledLabel: UILabel!
    @IBOutlet weak var isConnectedLabel: UILabel!
    @IBOutlet weak var ownPubKeyLabel: UILabel!
    @IBOutlet weak var peerPubKeyLabel: UILabel!
    @IBOutlet weak var logTextView: UITextView!
    
    private let cbwallet = CoinbaseWalletSDK.shared
    private var address: String?
    
    private var address: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isCBWalletInstalledLabel.text = "\(CoinbaseWalletSDK.isCoinbaseWalletInstalled())"
        updateSessionStatus()
    }
    
    @IBAction func initiateHandshake() {
        cbwallet.initiateHandshake(
            initialActions: [
                Action(jsonRpc: .eth_requestAccounts)
            ]
        ) { result, account in
            switch result {
            case .success(let response):
                self.logObject(label: "Response:\n", [
                    "sender": response.sender.rawRepresentation.base64EncodedString(),
                    "content": "\(response.content)"
                ])
                
                guard let account = account else { return }
                self.logObject(label: "Account:\n", account)
                self.address = account.address
                self.log("Address: \(self.address!)")
                
                guard let returnValue = response.content.first,
                      case .result(value: let address) = returnValue else { break }
                self.address = address
                self.log("Address: \(address)")
            case .failure(let error):
                self.log("\(error)")
            }
            self.updateSessionStatus()
        }
    }
    
    @IBAction func resetConnection() {
        let result = cbwallet.resetSession()
        self.log("\(result)")
        
        updateSessionStatus()
    }
    
    @IBAction func makeRequest() {
        cbwallet.makeRequest(
            Request(
                actions: [
                    Action(jsonRpc: .personal_sign(address: self.address ?? "", message: "message".data(using: .utf8)!)),
                ]
//              , account: Account(chain: "eth", networkId: 1, address: self.address)
            )
        ) { result in
            switch result {
            case .success(let response):
                self.logObject(response)
            case .failure(let error):
                self.log("\(error)")
            }
        }
    }
    
    // i should have chosen SwiftUI template...
    
    private func updateSessionStatus() {
        DispatchQueue.main.async {
            let isConnected = self.cbwallet.isConnected()
            self.isConnectedLabel.textColor = isConnected ? .green : .red
            self.isConnectedLabel.text = "\(isConnected)"
            
            self.ownPubKeyLabel.text = self.cbwallet.keyManager.ownPublicKey.rawRepresentation.base64EncodedString()
            self.peerPubKeyLabel.text = self.cbwallet.keyManager.peerPublicKey?.rawRepresentation.base64EncodedString() ?? "(nil)"
        }
    }
    
    private func logObject<T: Encodable>(label: String = "", _ object: T, function: String = #function) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(object)
            let jsonString = String(data: data, encoding: .utf8)!
            self.log("\(label)\(jsonString)", function: function)
        } catch {
            self.log("\(error)")
        }
    }
    
    func logURL(_ url: URL?, function: String = #function) {
        guard let url = url else { return }
        self.log("URL: \(url)", function: function)
        
        guard
            !cbwallet.isConnected(),
            let message: RequestMessage = try? MessageConverter.decode(url, with: nil)
        else { return }
        self.logObject(message, function: function)
    }
    
    private func log(_ text: String, function: String = #function) {
        DispatchQueue.main.async {
            self.logTextView.text = "\(function): \(text)\n\n\(self.logTextView.text ?? "")"
//            self.logTextView.text += "\(function): \(text)\n\n"
//            self.logTextView.scrollRangeToVisible(NSMakeRange(self.logTextView.text.count - 1, 1))
        }
    }
}

