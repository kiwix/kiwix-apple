//
//  SearchTuneController.swift
//  Kiwix
//
//  Created by Chris Li on 6/23/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class SettingSearchTuneController: UIViewController, UITableViewDataSource {
    @IBOutlet weak var y1Value: UITextField!
    @IBOutlet weak var y2Value: UITextField!
    @IBOutlet weak var x1Value: UITextField!
    @IBOutlet weak var x2Value: UITextField!

    @IBOutlet weak var mLabel: UILabel!
    @IBOutlet weak var nLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    let e = 2.718281828459
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "y=ln(n-mx) 🤓"
        
        let button = UIBarButtonItem(title: "Calculate", style: .Plain, target: self, action: #selector(SettingSearchTuneController.calculate))
        navigationItem.rightBarButtonItem = button
        
        tableView.dataSource = self
        
        if Defaults[.m] == nil {
            Defaults[.x1] = 1
            Defaults[.x2] = 0.75
            Defaults[.y1] = 0.1
            Defaults[.y2] = 1
        }
        
        y1Value.text = String(Defaults[.y1])
        y2Value.text = String(Defaults[.y2])
        x1Value.text = String(Defaults[.x1])
        x2Value.text = String(Defaults[.x2])
        
        calculate()
    }
    
    override func viewWillDisappear(animated: Bool) {
        Defaults[.x1] = Double(x1Value.text ?? "") ?? 0
        Defaults[.x2] = Double(x2Value.text ?? "") ?? 0
        Defaults[.y1] = Double(y1Value.text ?? "") ?? 0
        Defaults[.y2] = Double(y2Value.text ?? "") ?? 0
    }
    
    func calculate() {
        guard let y1Text = y1Value.text, let y2Text = y2Value.text, let x1Text = x1Value.text, let x2Text = x2Value.text else {return}
        guard let y1 = Double(y1Text), let y2 = Double(y2Text), let x1 = Double(x1Text), let x2 = Double(x2Text) else {return}
        let ey1 = pow(e, y1)
        let ey2 = pow(e, y2)
        let m = (ey1 - ey2) / (x2 - x1)
        let n = ey1 + m * x1
        
        Defaults[.m] = m
        Defaults[.n] = n
        
        mLabel.text = "m = " + String(format: "%.5f", m)
        nLabel.text = "n = " + String(format: "%.5f", n)
        
        y1Value.resignFirstResponder()
        y2Value.resignFirstResponder()
        x1Value.resignFirstResponder()
        x2Value.resignFirstResponder()
        tableView.reloadData()
    }
    
    // MARK: -  UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        let prob: Double = indexPath.section == 0 ? ((100 - Double(indexPath.row)) / 100.0) : ((10.0 - Double(indexPath.row)) / 10.0)
        cell.textLabel?.text = "\(prob * 100)%"
        cell.detailTextLabel?.text = String(format: "%.5f", WeightFactor.calculate(prob) ?? "NA")
        return cell
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "100% -- 90%" : "100% -- 10%"
    }
}

class WeightFactor {
    class func calculate(prob: Double) -> Double {
        if UIApplication.buildStatus == .Alpha {
            if let m = Defaults[.m], let n = Defaults[.n] {
                return caluclateLog(m: m, n: n, prob: prob)
            } else {
                return 1
            }
        } else {
            let m = 6.4524436415334163
            let n = 7.5576145596090623
            return caluclateLog(m: m, n: n, prob: prob)
        }
    }
    
    private class func caluclateLog(m m: Double, n: Double, prob: Double) -> Double {
        let e = 2.718281828459
        return log(n - m * prob) / log(e)
    }
}

extension DefaultsKeys {
    static let x1 = DefaultsKey<Double>("Debug-x1")
    static let x2 = DefaultsKey<Double>("Debug-x2")
    static let y1 = DefaultsKey<Double>("Debug-y1")
    static let y2 = DefaultsKey<Double>("Debug-y2")
    
    static let m = DefaultsKey<Double?>("Debug-m")
    static let n = DefaultsKey<Double?>("Debug-n")
}
