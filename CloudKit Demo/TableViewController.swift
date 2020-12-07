//
//  TableViewController.swift
//  CloudKit Demo
//
//  Created by Zeyana Musthafa on 12/2/20.
//

import UIKit
import CloudKit

class TableViewController: UITableViewController {
    
    var songs = [CKRecord]()
    var selectedSongIndex: IndexPath?


    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // TODO: Call getSongs function
        getSongs()
        
        subscribeToChanges()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        unsubscribeToChanges()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return songs.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedSongIndex = indexPath
        performSegue(withIdentifier: "updateSongSegue", sender: self)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewCell", for: indexPath) as! TableViewCell

        // Configure the cell...
        cell.title.text = songs[indexPath.row]["title"] as? String
        cell.artist.text = songs[indexPath.row]["artist"] as? String
        cell.album.text = songs[indexPath.row]["album"] as? String
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteRecord(record: songs[indexPath.row])
            
            // Handles deleting cell from table view controller
            songs.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        }
    }
    
    // TODO: Initialize variable for database to access from
    let database = CKContainer.default().publicCloudDatabase

    // TODO: Create a subscription ID variable
    let subscriptionID = "All Songs"
    
    var retryCount: Int = 0
    let retryLimit = 10
    // TODO: Create a function that gets songs from the database and loads into tableview
    // TODO: Handle retry on error
    func getSongs() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Song", predicate: predicate)
        database.perform(query, inZoneWith: .default) { (records, error) in
            if let error = error as? CKError {
                print("error", error.localizedDescription)
                // can target specific error types that are worth retrying
                if error.code == CKError.networkFailure || error.code == CKError.networkUnavailable {
                    if self.retryCount < self.retryLimit {
                        //can pass retryAfterSeconds that's provided with some errors
                        self.retry(retryInterval: error.retryAfterSeconds)
                    }
                }
                
                return
            }
            guard let records = records else {return}
            
            DispatchQueue.main.async {
                self.songs = records
//                print("record: ", records[0])
                self.tableView.reloadData()
            }
        }
        
    }
   
    
    func retry(retryInterval: Double?) {
        Timer.scheduledTimer(withTimeInterval: retryInterval ?? 1.0, repeats: false) { (timer) in
            self.getSongs()
        }
    }
    
    
    func subscribeToChanges() {
        //TODO: subscribe to changes in the database
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: "Song", predicate: predicate, subscriptionID: subscriptionID, options: [.firesOnRecordUpdate, .firesOnRecordCreation, .firesOnRecordDeletion])
//        subscription.notificationInfo = CKSubscription.NotificationInfo()
        let notification = CKSubscription.NotificationInfo()
        notification.shouldSendContentAvailable = true
        subscription.notificationInfo = notification
        database.save(subscription) { (result, error) in
            if let error = error {
                print("error", error)
                return
            }
            print("subscription saved succesfully")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updatesReceived(notification:)), name: Notification.Name("updateSong"), object: nil)
        
        
    }
    
    @objc func updatesReceived(notification: Notification) {
        if let queryNotification = notification.userInfo!["queryNotification"] as? CKQueryNotification {
            if queryNotification.subscriptionID == subscriptionID {
                if let recordID = queryNotification.recordID {
                    if queryNotification.queryNotificationReason == .recordDeleted { //handle delete
                        if let index = self.songs.firstIndex(where: {$0.recordID.recordName == recordID.recordName}) {
                            DispatchQueue.main.async {
                                self.songs.remove(at: index) //remove record from list
                                self.tableView.reloadData()
                            }
                        }
                        return
                    }
                    // don't need to fetch record for case of delete
                    database.fetch(withRecordID: recordID) { (record, error) in
                        if let error = error {
                            print("error", error.localizedDescription)
                            return
                        }
                        guard let record = record else {return}
                        if queryNotification.queryNotificationReason == .recordCreated {
                            DispatchQueue.main.async {
                                self.songs = self.songs + [record] //add record to list
                                self.tableView.reloadData()
                            }
                        } else if queryNotification.queryNotificationReason == .recordUpdated {
                            if let index = self.songs.firstIndex(where: {$0.recordID.recordName == recordID.recordName}) {
                                DispatchQueue.main.async {
                                self.songs[index] = record //update relevant record in list
                                    self.tableView.reloadData()
                                    
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    

    func unsubscribeToChanges() {
        // TODO: unsubscribe to changes in the database
        database.delete(withSubscriptionID: subscriptionID) { (subscriptionID, error) in
            //Handle on completion as relevant
        }
    }
        
    func deleteRecord(record: CKRecord) {
        // TODO: Delete record from database
        database.delete(withRecordID: record.recordID) { (recordID, error) in
            // Handle on completion
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "updateSongSegue" {
            if let selectedSongIndex = selectedSongIndex {
                if let updateSongViewController = segue.destination as? EntryViewController {
                    updateSongViewController.title = "Update Song"
                    updateSongViewController.record = songs[selectedSongIndex.row]
                    updateSongViewController.titleValue = songs[selectedSongIndex.row]["title"] as? String
                    updateSongViewController.artistValue = songs[selectedSongIndex.row]["artist"] as? String
                    updateSongViewController.albumValue = songs[selectedSongIndex.row]["album"] as? String
                }
                
            }
            
            
        }
    }
    

}
