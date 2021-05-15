// The MIT License (MIT)
// Copyright © 2020 Ivan Vorobei (hello@ivanvorobei.by)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit

#if os(iOS)

public class SPPermissionsListController: UITableViewController, SPPermissionsControllerInterface {
    
    public weak var dataSource: SPPermissionsDataSource?
    public weak var delegate: SPPermissionsDelegate?
    
    public var titleText = Text.header
    public var headerText = Text.description
    public var footerText = Text.comment
    public var prefersLargeTitles = true
    
    private var permissions: [SPPermission]
    
    // MARK: - Init
    
    init(_ permissions: [SPPermission]) {
        self.permissions = permissions
        if #available(iOS 13.0, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    // MARK: - Lifecycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissAnimated))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissAnimated))
        }
        
        navigationItem.title = titleText
        navigationItem.largeTitleDisplayMode = .automatic
        navigationController?.navigationBar.prefersLargeTitles = prefersLargeTitles
        navigationController?.presentationController?.delegate = self
        
        tableView.delaysContentTouches = false
        tableView.allowsSelection = false
        tableView.register(SPPermissionTableCell.self, forCellReuseIdentifier: SPPermissionTableCell.id)
        tableView.register(SPPermissionsListHeaderView.self, forHeaderFooterViewReuseIdentifier: SPPermissionsListHeaderView.id)
        tableView.register(SPPermissionsListFooterCommentView.self, forHeaderFooterViewReuseIdentifier: SPPermissionsListFooterCommentView.id)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc func applicationDidBecomeActive() {
        tableView.reloadData()
    }
    
    // MARK: - Helpers
    
    public func present(on controller: UIViewController) {
        let navigationController = UINavigationController(rootViewController: self)
        navigationController.modalPresentationStyle = .formSheet
        navigationController.preferredContentSize = CGSize.init(width: 480, height: 560)
        controller.present(navigationController, animated: true, completion: nil)
    }
    
    @objc func process(button: SPPermissionActionButton) {
        
    }
    
    @objc func dismissAnimated() {
        self.dismiss(animated: true, completion: nil)
    }
    
    public override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: { [weak self] in
            completion?()
            self?.processDissmissedEvent()
        })
    }
    
    private func processDissmissedEvent() {
        let ids: [Int] = self.permissions.map { $0.rawValue }
        self.delegate?.didHidePermissions?(ids)
    }
}

// MARK: - Table Data Source & Delegate

extension SPPermissionsListController {
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return permissions.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let permission = permissions[indexPath.row]
        var cell = tableView.dequeueReusableCell(withIdentifier: SPPermissionTableCell.id, for: indexPath) as! SPPermissionTableCell
        cell.defaultConfigure(for: permission)
        cell = dataSource?.configure?(cell, for: permission) ?? cell
        cell.permissionButton.addTarget(self, action: #selector(self.process(button:)), for: .touchUpInside)
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: SPPermissionsListHeaderView.id) as! SPPermissionsListHeaderView
        view.titleLabel.text = headerText
        return view
    }
    
    public override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: SPPermissionsListFooterCommentView.id) as! SPPermissionsListFooterCommentView
        view.titleLabel.text = footerText
        return view
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension SPPermissionsListController: UIAdaptivePresentationControllerDelegate {
    
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.processDissmissedEvent()
    }
}

#endif
