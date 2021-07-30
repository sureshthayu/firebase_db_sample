/// Copyright (c) 2021 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import Firebase

class GroceryListTableViewController: UITableViewController {
  // MARK: Constants
  let listToUsers = "ListToUsers"

  // MARK: Properties
  var items: [GroceryItem] = []
  var user: User?
  var onlineUserCount = UIBarButtonItem()

  let ref = Database.database(url: "https://grocr-9723e-default-rtdb.asia-southeast1.firebasedatabase.app").reference(withPath: "grocery-items")
  var refObservers: [DatabaseHandle] = []

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  // MARK: UIViewController Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.allowsMultipleSelectionDuringEditing = false

    onlineUserCount = UIBarButtonItem(
      title: "1",
      style: .plain,
      target: self,
      action: #selector(onlineUserCountDidTouch))
    onlineUserCount.tintColor = .white
    navigationItem.leftBarButtonItem = onlineUserCount
    user = User(uid: "FakeId", email: "hungry@person.food")
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(true)
    
    let completed = ref
      .queryOrdered(byChild: "completed")
      .observe(.value) { snapshot in
        var newItems: [GroceryItem] = []
        for child in snapshot.children {
          if
            let snapshot = child as? DataSnapshot,
            let groceryItem = GroceryItem(snapshot: snapshot) {
            newItems.append(groceryItem)
          }
        }
        self.items = newItems
        self.tableView.reloadData()
      }

    // 6
    refObservers.append(completed)

  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(true)
  }

  // MARK: UITableView Delegate methods
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
    let groceryItem = items[indexPath.row]

    cell.textLabel?.text = groceryItem.name
    cell.detailTextLabel?.text = groceryItem.addedByUser

    toggleCellCheckbox(cell, isCompleted: groceryItem.completed)

    return cell
  }

  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let groceryItem = items[indexPath.row]
      groceryItem.ref?.removeValue()
    }

  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let cell = tableView.cellForRow(at: indexPath) else { return }
    var groceryItem = items[indexPath.row]
    let toggledCompletion = !groceryItem.completed

    toggleCellCheckbox(cell, isCompleted: toggledCompletion)
    groceryItem.completed = toggledCompletion
    groceryItem.ref?.updateChildValues([
      "completed": toggledCompletion
    ])
  }

  func toggleCellCheckbox(_ cell: UITableViewCell, isCompleted: Bool) {
    if !isCompleted {
      cell.accessoryType = .none
      cell.textLabel?.textColor = .black
      cell.detailTextLabel?.textColor = .black
    } else {
      cell.accessoryType = .checkmark
      cell.textLabel?.textColor = .gray
      cell.detailTextLabel?.textColor = .gray
    }
  }

  // MARK: Add Item
  @IBAction func addItemDidTouch(_ sender: AnyObject) {
    let alert = UIAlertController(
      title: "Grocery Item",
      message: "Add an Item",
      preferredStyle: .alert)

    let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
      // 1
      guard
        let textField = alert.textFields?.first,
        let text = textField.text,
        let user = self.user
      else { return }
      
      // 2
      let groceryItem = GroceryItem(
        name: text,
        addedByUser: user.email,
        completed: false)

      // 3
      let groceryItemRef = self.ref.child(text.lowercased())

      // 4
      groceryItemRef.setValue(groceryItem.toAnyObject())
    }

    let cancelAction = UIAlertAction(
      title: "Cancel",
      style: .cancel)

    alert.addTextField()
    alert.addAction(saveAction)
    alert.addAction(cancelAction)

    present(alert, animated: true, completion: nil)
  }

  @objc func onlineUserCountDidTouch() {
    performSegue(withIdentifier: listToUsers, sender: nil)
  }
}
