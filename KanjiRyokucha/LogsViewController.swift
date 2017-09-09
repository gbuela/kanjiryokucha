//
//  LogsViewController.swift
//  KanjiRyokucha
//
//  Created by German Buela on 8/22/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit

class LogsViewController: UIViewController {
    
    @IBOutlet weak var logs: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = []
        title = "Logs"
        logs.text = DebugLogsManager().readLogs()
    }

    @IBAction func deleteLogsPressed() {
        DebugLogsManager().clear()
        logs.text = DebugLogsManager().readLogs()
    }

}
