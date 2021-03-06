//
//  SendUTXO.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation

class SendUTXO {
    
    var amount = Double()
    var changeAddress = ""
    var addressToPay = ""
    var sweep = Bool()
    var spendableUtxos = [NSDictionary]()
    var inputArray = [Any]()
    var utxoTxId = String()
    var utxoVout = Int()
    var changeAmount = Double()
    var inputs = ""
    var signedRawTx = ""
    var index = 0
    var indexarray = [String]()
    var unsignedRawTx = ""
    var addresses = [String]()
    var errorBool = Bool()
    var errorDescription = ""
    
    func createRawTransaction(completion: @escaping () -> Void) {
        print("addresses = \(addresses)")
        
        let reducer = Reducer()
        
        func getAddressInfo(addresses: [String]) {
            print("getAddressInfo: \(addresses)")
            
            var privkeyarray = [String]()
            
            func sign() {
                
                let param = "\"\(unsignedRawTx)\", \(privkeyarray)"
                reducer.makeCommand(command: .signrawtransactionwithkey, param: param) {
                    
                    if !reducer.errorBool {
                        
                        let dict = reducer.dictToReturn
                        let complete = dict["complete"] as! Bool
                        print("dict = \(dict)")
                        
                        if complete {
                            
                            let hex = dict["hex"] as! String
                            self.signedRawTx = hex
                            completion()
                            
                        }
                        
                    }
                    
                }
                
            }
            
            func getinfo() {
                
                if !reducer.errorBool {
                    
                    self.index += 1
                    let result = reducer.dictToReturn
                    print("result: \(result)")
                    let hdkeypath = result["hdkeypath"] as! String
                    let arr = hdkeypath.components(separatedBy: "/")
                    indexarray.append(arr[1])
                    print("indexarray = \(indexarray)")
                    getAddressInfo(addresses: addresses)
                        
                } else {
                    
                    errorBool = true
                    errorDescription = reducer.errorDescription
                    completion()
                    
                }
                
            }
            
            if addresses.count > self.index {
                
                reducer.makeCommand(command: .getaddressinfo,
                                    param: "\"\(addresses[self.index])\"",
                                    completion: getinfo)
                
            } else {
                
                print("loop finished")
                // loop is finished get the private keys
                let keyfetcher = KeyFetcher()
                print("indexarray2 = \(indexarray)")
                
                for (i, keypathint) in indexarray.enumerated() {
                    
                    let int = Int(keypathint)!
                    
                    keyfetcher.privKey(index: int) { (privKey, error) in
                        
                        if !error {
                            
                            privkeyarray.append(privKey!)
                            
                            if i == self.indexarray.count - 1 {
                                
                                // get the unsigned raw transaction and sign it
                                print("privekeys = \(privkeyarray)")
                                sign()
                                
                            }
                            
                        } else {
                            
                            self.errorBool = true
                            self.errorDescription = "error getting private key"
                            completion()
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        func executeNodeCommand(method: BTC_CLI_COMMAND, param: String) {
            
            func getResult() {
                
                if !reducer.errorBool {
                    
                    switch method {
                        
                    case .createrawtransaction:
                        
                        unsignedRawTx = reducer.stringToReturn
                        //executeNodeCommand(method: .signrawtransactionwithwallet, param: "\"\(unsignedRawTx)\"")
                        getAddressInfo(addresses: addresses)
                        
                    default:
                        
                        break
                        
                    }
                    
                } else {
                    
                    errorBool = true
                    errorDescription = reducer.errorDescription
                    completion()
                    
                }
                
            }
            
            reducer.makeCommand(command: method,
                                param: param,
                                completion: getResult)
            
        }
        
        func processInputs() {
            
            self.inputs = self.inputArray.description
            self.inputs = self.inputs.replacingOccurrences(of: "[\"", with: "[")
            self.inputs = self.inputs.replacingOccurrences(of: "\"]", with: "]")
            self.inputs = self.inputs.replacingOccurrences(of: "\"{", with: "{")
            self.inputs = self.inputs.replacingOccurrences(of: "}\"", with: "}")
            self.inputs = self.inputs.replacingOccurrences(of: "\\", with: "")
            
        }
        
        processInputs()
        
        var param = ""
        
        if !sweep {
            
            let receiver = "\"\(self.addressToPay)\":\(self.amount)"
            let change = "\"\(self.changeAddress)\":\(self.changeAmount)"
            param = "''\(self.inputs)'', ''{\(receiver), \(change)}''"
            param = param.replacingOccurrences(of: "\"{", with: "{")
            param = param.replacingOccurrences(of: "}\"", with: "}")
            
        } else {
            
            let receiver = "\"\(self.addressToPay)\":\(self.amount)"
            param = "''\(self.inputs)'', ''{\(receiver)}''"
            param = param.replacingOccurrences(of: "\"{", with: "{")
            param = param.replacingOccurrences(of: "}\"", with: "}")
            
        }
        
        executeNodeCommand(method: BTC_CLI_COMMAND.createrawtransaction,
                           param: param)
        
    }
    
}
