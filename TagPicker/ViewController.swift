//
//  ViewController.swift
//  TagPicker
//
//  Created by Jorge Bernal Ordovas on 20/04/2017.
//  Copyright © 2017 Jorge Bernal. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
//    @IBOutlet var textView: UITextView!
//    @IBOutlet var textContainerHeightConstraint: NSLayoutConstraint!
//    @IBOutlet var tableView: UITableView!
    let textView = UITextView()
    let textViewContainer = UIView()
    let tableView = UITableView(frame: .zero, style: .grouped)
    let dataSource = SuggestionsDataSource()
    lazy var textContainerHeightConstraint: NSLayoutConstraint = {
        return self.textViewContainer.heightAnchor.constraint(equalToConstant: 44)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Tags"

        textView.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: dataSource.cellIdentifier)
        tableView.delegate = self
        tableView.dataSource = dataSource
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))

        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none

        textViewContainer.addSubview(textView)
        view.addSubview(textViewContainer)
        view.addSubview(tableView)

        textView.translatesAutoresizingMaskIntoConstraints = false
        textViewContainer.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: textViewContainer.topAnchor),
            textView.bottomAnchor.constraint(equalTo: textViewContainer.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),

            textViewContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 35),
            textContainerHeightConstraint,
            textViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -1),
            textViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 1),

            textViewContainer.bottomAnchor.constraint(equalTo: tableView.topAnchor),

            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        updateTextViewHeight()

        view.backgroundColor = UIColor.groupTableViewBackground
        textViewContainer.backgroundColor = UIColor.white
        textViewContainer.layer.borderColor = UIColor.lightGray.cgColor
        textViewContainer.layer.borderWidth = 1
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateSuggestions()
        textView.becomeFirstResponder()
    }

    func updateTextViewHeight() {
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        textContainerHeightConstraint.constant = min(size.height, 44)
    }

    func updateSuggestions() {
        let tags = tagsInField
        let partial = lastTag
        let matches = match(filter: partial)
        dataSource.suggestions = matches
        tableView.reloadData()
    }

    var tagsInField: [String] {
        return textView.text
            .components(separatedBy: ",")
            .map({ $0.trimmingCharacters(in: .whitespaces) })
    }

    var lastTag: String {
        return tagsInField.last ?? ""
    }

    func match(filter: String?) -> [String] {
        guard let filter = filter, !filter.isEmpty else {
            return unusedTags
        }
        return unusedTags.filter({ $0.localizedCaseInsensitiveContains(filter) })
    }

    func complete(tag: String) {
        var tags = tagsInField
        tags.removeLast()
        tags.append(tag)
        tags.append("")
        textView.text = tags.joined(separator: ", ")
        updateSuggestions()
    }

    var usedTags: Set<String> {
        return Set(tagsInField.dropLast())
    }

    var unusedTags: [String] {
        let used = usedTags
        return allTags.filter({ !used.contains($0) })
    }

    var allTags: [String] {
        return "Food,apple,fail,photo,code,sous-vide,wtf,video,iphone,cat,cocoa,photography,germany,cooking,screenshot,objective-c,development,birra,objc,sxsw,sxsw11,xcode,meetup,automattic,youtube,copyright,a8cgm,swift,64-bit,iphone 5s,armv8,typography,ui,chrome,pricing,smoothie,ios,sel,selectors,internals,icloud,NSString,snippet,recursion,updates,devforums,facetime,douglas adams,salmon of doubt,san diego,travel,samsung,galaxy s3,gadgets,DIY,lighting setup,chocolate,desserts,space,iss,nasa,awesomeness,quartz core,software,testing,mobile,wordpress,screencast,nonsense,gema,crepes,breakfast,brownies,cologne,cash,ec,kvb,vrs,transport,lazarus,web forms,extension,carrot soup,garlic cheese,candy cane,vide,nutella,Piña Colada,Cheesecake,Fried egg,coconut milk,cheese lasagna,blue cheese,xkcd,email,funny,api,archive,internet archive,wayback machine".components(separatedBy: ",")

    }

    func normalizeText() {
        // Remove any space before a comma, and allow one space at most after.
        let regexp = try! NSRegularExpression(pattern: "\\s*(,(\\s|(\\s(?=\\s)))?)\\s*", options: [])
        let text = textView.text ?? ""
        let range = NSRange(location: 0, length: (text as NSString).length)
        textView.text = regexp.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "$1")
    }
}

extension ViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        normalizeText()
        updateTextViewHeight()
        updateSuggestions()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let original = textView.text as NSString
        if range.length == 0,
            text == ",",
            lastTag.isEmpty {
            // Don't allow a second comma if the last tag is blank
            return false
        } else if
            range.length == 1 && text == "", // Deleting last character
            range.location > 0, // Not at the beginning
            original.substring(with: NSRange(location: range.location - 1, length: 1)) == "," // Previous is a comma
            {
                // Delete the comma as well
                textView.text = original.substring(to: range.location - 1)
                return false
        } else if range.length == 0, // Inserting
            text == ",", // a comma
            range.location == original.length // at the end
        {
            // Append a space
            textView.text = original.replacingCharacters(in: range, with: ", ")
            return false
        }
        return true
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let cell = tableView.cellForRow(at: indexPath),
            let tag = cell.textLabel?.text else {
                return
        }
        complete(tag: tag)
    }
}

class SuggestionsDataSource: NSObject, UITableViewDataSource {
    let cellIdentifier = "Default"
    var suggestions = [String]()

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.textLabel?.text = suggestions[indexPath.row]
        return cell
    }
}
