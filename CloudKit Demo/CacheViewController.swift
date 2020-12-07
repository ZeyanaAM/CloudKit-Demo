//
//  CacheViewController.swift
//  CloudKit Demo
//
//  Created by Zeyana Musthafa on 12/3/20.
//

import UIKit
import Firebase
import FirebaseFirestore

class CacheViewController: UIViewController {
    
    let db = Firestore.firestore()

    @IBOutlet weak var executionTime: UILabel!
    @IBOutlet weak var dataLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var pendingWritesLabel: UILabel!
    @IBOutlet weak var newDataField: UITextField!
    
    @IBOutlet weak var clearPersistenceToggle: UISwitch!
    
    var networkEnabled: Bool = true
    var shouldClearPersistence: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        clearPersistenceToggle.setOn(shouldClearPersistence, animated: false)

        // Do any additional setup after loading the view.

                
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        db.settings = settings
        
        getSnapshotData()
    }
    
    
    @IBAction func getDataButtonPressed(_ sender: UIButton) {
        if networkEnabled {
            Firestore.firestore().enableNetwork { (error) in
                self.getData()
            }
        } else {
            Firestore.firestore().disableNetwork { (error) in
                self.getData()
            }
        }
        
    }
    
    func getData() {
        self.dataLabel.text = "Data: "
        self.sourceLabel.text = "Source: "
        self.pendingWritesLabel.text = ""
        self.executionTime.text = "Execution time:"
        let docRef = db.collection("testCollection").document("testDoc")
        let startDate = Date()
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let requestExecutionTime = Date().timeIntervalSince(startDate)
                print("time it took to execute request: ", requestExecutionTime)
                self.executionTime.text = "Execution time: \(requestExecutionTime)" 
                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                print("Document data: \(dataDescription)")
//                if let docData = document.data() {
                self.dataLabel.text = "Data: \(document.data()!["data"] ?? "")"
                let source = document.metadata.isFromCache ? "Cache" : "Server"
                print("Metadata: Data fetched from \(source)")
                self.sourceLabel.text = "Source: \(source)"
                
            } else {
                print("Document does not exist")
            }
        }

    }
    
    func getSnapshotData() {
        
        db.collection("testCollection").document("testDoc")
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                self.dataLabel.text = "Data: \(document.data()!["data"] ?? "")"
                let pendingWrites = document.metadata.hasPendingWrites ? "Yes" : "No"
                self.pendingWritesLabel.text = "Has Pending Writes: \(pendingWrites)"
                let source = document.metadata.isFromCache ? "Cache" : "Server"
                print("Metadata: Data fetched from \(source)")
                self.sourceLabel.text = "Source: \(source)"
                self.executionTime.text = ""
        }
    }
    
    @IBAction func submitDataPressed(_ sender: Any) {
        if let newData = newDataField.text {
            db.collection("testCollection").document("testDoc").updateData([
                "data": newData
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
        }
    }
    
    @IBAction func networkSettingsChanged(_ sender: Any) {
        networkEnabled.toggle()
    }
    
    @IBAction func clearPersistencePressed(_ sender: UISwitch) {
        if sender.isOn {
            print("clearing persistence")
            Firestore.firestore().clearPersistence()
        }
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
