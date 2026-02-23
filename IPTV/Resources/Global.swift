//
//  Global.swift
//  AR-Tattoo
//
//  Created by Shivshankar T Tiwari on 09/12/25.
//

import Foundation

class Global {
    
    static var shared = Global()
    
    let appID:String = "6759247382"
    
    func storeIsUserPro(_ isPro : Bool){
        UserDefaults.standard.set(isPro, forKey: "isProUser")
    }
    
    func getIsUserPro() -> Bool {
        return UserDefaults.standard.bool(forKey: "isProUser")
    }

    func getFirstChallangeStartedSince() -> Int?{
        let defaults = UserDefaults.standard
        let installDateKey = "FirstChallangeStartedDate"

        if let installDate = defaults.object(forKey: installDateKey) as? Date {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: installDate, to: Date())
            return components.day
        } else {
            print("Install date not found.")
            return nil
        }
    }
    
    func storeFirstChallangeInstallDate() {
        let currentDate = Date()
        UserDefaults.standard.set(currentDate, forKey: "FirstChallangeStartedDate")
    }
    
    func secondChallangeStartedSince() -> Int?{
        let defaults = UserDefaults.standard
        let installDateKey = "SecondChallangeStartedDate"

        if let installDate = defaults.object(forKey: installDateKey) as? Date {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: installDate, to: Date())
            return components.day
        } else {
            print("Install date not found.")
            return nil
        }
    }
    
    
    func storeSecondChallangeInstallDate() {
        let currentDate = Date()
        UserDefaults.standard.set(currentDate, forKey: "SecondChallangeStartedDate")
    }
    
    
    func getChallangeStartedSince() -> Int? {

        let defaults = UserDefaults.standard
        let installDateKey = "installDate"

        if let installDate = defaults.object(forKey: installDateKey) as? Date {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: installDate, to: Date())
            return components.day
        } else {
            print("Install date not found.")
            return nil
        }
    }
    
    func storeInstallDate() {
        let currentDate = Date()
        UserDefaults.standard.set(currentDate, forKey: "installDate")
    }
    
    func retrieveInstalledDate() -> Date? {
        if let retrievedDate = UserDefaults.standard.object(forKey: "installDate") as? Date {
          //  print("Date retrieved: \(retrievedDate)")
            return retrievedDate
        } else {
            self.storeInstallDate()
            print("No date found in UserDefaults")
            return Date()
        }
    }

    func is24HoursPassedFromDate() -> Bool {
        // Retrieve the stored date
        guard let storedDate = retrieveInstalledDate() else {
            print("No stored date to compare.")
            return false
        }

        // Get the current date
        let currentDate = Date()

        // Calculate the time interval between the two dates
        let timeInterval = currentDate.timeIntervalSince(storedDate)

        // Check if 24 hours (86,400 seconds) have passed
        
        if timeInterval >= 86400 {
            print("24 hours have passed.")
            return true
        } else {
           // print("24 hours have not yet passed.")
            return false
        }
    }
}
