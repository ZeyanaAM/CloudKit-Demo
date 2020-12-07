//
//  EntryViewController.swift
//  CloudKit Demo
//
//  Created by Zeyana Musthafa on 12/3/20.
//

import UIKit
import CloudKit

class EntryViewController: UIViewController {

    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var artistField: UITextField!
    @IBOutlet weak var albumField: UITextField!
    @IBOutlet weak var addSongButton: UIButton!
    
    var record: CKRecord?
    var titleValue: String?
    var artistValue: String?
    var albumValue: String?
    
    
    let database = CKContainer.default().publicCloudDatabase
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if record != nil {
            print("changing title")
            addSongButton.titleLabel?.text = "Update Song"
            addSongButton.setTitle("Update Song", for: .normal)
        }
        
        titleField.text = titleValue
        artistField.text = artistValue
        albumField.text = albumValue
    }
    

    @IBAction func addSongPressed(_ sender: Any) {
        if let record = record { //existing song
            updateSongRecord(record: record)
            
        } else if let title = titleField.text {
            if !title.isEmpty {
                let artist = artistField.text
                let album = albumField.text
                createSongRecord(title: title, artist: artist, album: album)
            }
            
        }
    
    }
    
    func updateSongRecord(record: CKRecord) {
        // TODO: Update song record in database, alert when
        
        // can set specific values
//        record.setValue(albumField.text, forKey: "album")

        // can be used to update all values
        record.setValuesForKeys([
            "title": titleField.text ?? "",
            "artist": artistField.text ?? "",
            "album": albumField.text ?? ""
        ])
        
        database.save(record) { (record, error) in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Song Updated!", message: "", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    
    func createSongRecord(title: String, artist: String?, album: String?) {
        // TODO: Create a song record and save in database
        
        let record = CKRecord(recordType: "Song")
        record.setValuesForKeys([
            "title": title,
            "artist": artist ?? "",
            "album": album ?? ""
        ])
        database.save(record) { (record, error) in
            //Do additional things
            if let error = error {
                print("error", error.localizedDescription)
                return
                
            }
            print("record was saved successfully")
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
