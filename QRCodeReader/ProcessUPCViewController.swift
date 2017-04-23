//
//  ProcessUPCViewController.swift
//  QRCodeReader
//
//  Created by Dan Edgar on 4/23/17.
//  Copyright © 2017 AppCoda. All rights reserved.
//

import UIKit
import GoogleAPIClientForREST
//import GTMOAuth2

class ProcessUPCViewController: UIViewController {

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public var discoveredUPCCode : String?
    

    //
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    private let kKeychainItemName = "Google Sheets API"
    
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    private let scopes = [kGTLRAuthScopeSheetsSpreadsheetsReadonly]
    
    private let service : GTLRSheetsService = (UIApplication.shared.delegate as! AppDelegate).googleSheetsService
    
    let output = UITextView()
    
    // When the view loads, create necessary subviews
    // and initialize the Google Sheets API service
    override func viewDidLoad() {
        super.viewDidLoad()
        
        output.frame = view.bounds
        output.isEditable = false
        output.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        output.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        view.addSubview(output);
        
        //TODO: Route to the App Delegate and do an auth.
        
        /*if let auth = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychain(
            forName: kKeychainItemName,
            clientID: kClientID,
            clientSecret: nil) {
            service.authorizer = auth
        }*/
        
    }
    
    // When the view appears, ensure that the Google Sheets API service is authorized
    // and perform API calls
    override func viewDidAppear(_ animated: Bool) {
        //if let authorizer = service.authorizer,
        if GAuthorizer.shared.isAuthorized() {
            listMajors()
        } else {
            GAuthorizer.shared.authorizationCompletion = {
                (result) in
                
                if result {
                    self.service.authorizer = GAuthorizer.shared.authorization
                } else {
                    self.service.authorizer = nil //Failed!
                }
                
                /*switch result {
                case .ok:
                    googleSheetsService.authorizer = GAuthorizer.shared.authorization
                // Log event, show alert, ...
                case .canceled:
                    fallthrough
                case .failed:
                    googleSheetsService.authorizer = nil
                    // Log event, show alert, ... 
                }*/
            }
            
            GAuthorizer.shared.authorize(in: self)
        }
    }
    
    let spreadsheetId = "1kfUZLrV8JyN2GZNOM1tMle1ulDIOGP4u7Di-8LxU30Y"

    
    // Display (in the UITextView) the names and majors of students in a sample
    // spreadsheet:
    // https://docs.google.com/spreadsheets/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit
    func listMajors() {
        output.text = "Getting sheet data..."
               /*let range = "Class Data!A2:E"
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet
            .query(withSpreadsheetId: spreadsheetId, range:range)
        service.executeQuery(query,
                             delegate: self,
                             didFinish: "displayResultWithTicket:finishedWithObject:error:"
        )*/
        
        //First check to see if the UPC code already has a row.
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet.query(withSpreadsheetId: spreadsheetId, range: "Sheet1!A:E")
        
        service.executeQuery(query, delegate:self, didFinish: #selector(showValuesIfExistOrAppend))
        
        
       
    }
    
    func showValuesIfExistOrAppend(_ ticket: GTLRServiceTicket,
                                   finishedWithObject result : GTLRSheets_ValueRange,
                                   error : NSError?) {
        if let error = error {
            showAlert(title: "Error", message: error.localizedDescription)
            return
        }
        
        //The result should be of the format:
        //Look are result.values and see what we can see
        //The result is an 'array' or arrays.
        //Each member of the results.values array is an array of columns.
        
        var UPCDiscovered = false
        
        if let rows = result.values,
            let scannedUPC = self.discoveredUPCCode {
            for row in rows {
                if let possibleUPC = row[0] as? String,
                    scannedUPC.hasSuffix(possibleUPC) {
                    
                    //Just output all the columns in an alert box.
                    let message = row.flatMap({$0 as? String}).joined(separator: "\n")
                    showAlert(title: "UPC found", message: message)
                    
                    UPCDiscovered = true
                    
                    break
                }
            }
        }
        
        if !UPCDiscovered {
            //Then append it into the spreadsheet.
            let range = "Sheet1"
             let valueRange = GTLRSheets_ValueRange.init();
             valueRange.values = [
             [self.discoveredUPCCode!]
             ]
             let query = GTLRSheetsQuery_SpreadsheetsValuesAppend
             .query(withObject: valueRange, spreadsheetId:spreadsheetId, range:range)
             query.valueInputOption = "USER_ENTERED"
             service.executeQuery(query,
             delegate: self,
             didFinish: #selector(displayAppendResultWithTicket)
             )
        }
    }
    
    // Process the response and display output
    func displayAppendResultWithTicket(_ ticket: GTLRServiceTicket,
                                 finishedWithObject result : GTLRSheets_ValueRange,
                                 error : NSError?) {
        
        if let error = error {
            showAlert(title: "Error", message: error.localizedDescription)
            return
        }
        
        //var majorsString = ""
        
      
        
        /*if let rows = result.values {
        
            if rows.isEmpty {
                output.text = "No data found."
                return
            }
            
            majorsString += "Name, Major:\n"
            for row in rows {
                let name = row[0]
                let major = row[4]
                
                majorsString += "\(name), \(major)\n"
            }
        }*/
        
        //output.text = majorsString
        
        showAlert(title:"Added", message:"\(self.discoveredUPCCode!) put into sheet")
    }
    
    
    
    // Creates the auth controller for authorizing access to Google Sheets API
    /*private func createAuthController() -> GTMOAuth2ViewControllerTouch {
        let scopeString = scopes.joined(separator: " ")
        return GTMOAuth2ViewControllerTouch(
            scope: scopeString,
            clientID: kClientID,
            clientSecret: nil,
            keychainItemName: kKeychainItemName,
            delegate: self,
            finishedSelector: "viewController:finishedWithAuth:error:"
        )
    }
    
    // Handle completion of the authorization process, and update the Google Sheets API
    // with the new credentials.
    func viewController(vc : UIViewController,
                        finishedWithAuth authResult : GTMOAuth2Authentication, error : NSError?) {
        
        if let error = error {
            service.authorizer = nil
            showAlert(title: "Authentication Error", message: error.localizedDescription)
            return
        }
        
        service.authorizer = authResult
        dismiss(animated: true, completion: nil)
    }*/
    
    // Helper for showing an alert
    func showAlert(title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertActionStyle.default,
            handler: nil
        )
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }

}
