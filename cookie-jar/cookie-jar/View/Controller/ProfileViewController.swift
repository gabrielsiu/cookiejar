//
//  ProfileViewController.swift
//  cookie-jar
//
//  Created by Gabriel Siu on 2019-08-17.
//  Copyright © 2019 Gabriel Siu. All rights reserved.
//

import UIKit

final class ProfileViewController: UIViewController {
    // MARK: Properties
    private let profileViewModel: ProfileViewModel
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    private let greetingLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 30, weight: .semibold)
        label.text = "Your Profile"
        return label
    }()
    
    private let pointsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22, weight: .light)
        return label
    }()
    
    private lazy var labelStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [greetingLabel, pointsLabel])
        stackView.axis = .vertical
        stackView.alignment = .leading
        return stackView
    }()
    
    private var cookieTableView: CookieTableView = {
        let tableView = CookieTableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: PURCHASED_COOKIE_IDENTIFIER)
        tableView.isScrollEnabled = false
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        return tableView
    }()
    
    private let shopButton: RoundedButton = {
        let button = RoundedButton(title: "Cookie Shop", textColor: .brown)
        button.addTarget(nil, action: #selector(toCookieShopVC), for: .touchUpInside)
        return button
    }()
    
    private let resetButton: RoundedButton = {
        let button = RoundedButton(title: "Reset data", textColor: .red)
        button.addTarget(nil, action: #selector(toResetDataView), for: .touchUpInside)
        return button
    }()
    
    private let aboutButton: RoundedButton = {
        let button = RoundedButton(title: "About", textColor: .black)
        button.addTarget(nil, action: #selector(toAboutView), for: .touchUpInside)
        return button
    }()
    
    private lazy var buttonStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [shopButton, resetButton, aboutButton])
        stackView.axis = .vertical
        stackView.spacing = 10
        return stackView
    }()
    
    // MARK: Lifecycle
    init(dataService: DataService) {
        profileViewModel = ProfileViewModel(dataService: dataService)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(scrollView)
        scrollView.setEdgeConstraints(top: view.topAnchor, bottom: view.bottomAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor)
        [labelStack, cookieTableView, buttonStack].forEach { scrollView.addSubview($0) }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissScreen))
        cookieTableView.delegate = self
        cookieTableView.dataSource = self
        
        labelStack.setEdgeConstraints(top: scrollView.topAnchor, bottom: cookieTableView.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top: 20, left: 16, bottom: 20, right: 16))
        cookieTableView.setEdgeConstraints(top: labelStack.bottomAnchor, bottom: buttonStack.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top: 20, left: 0, bottom: 20, right: 0))
        buttonStack.setEdgeConstraints(top: cookieTableView.bottomAnchor, bottom: scrollView.bottomAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top: 20, left: 16, bottom: 20, right: 16))
        
        pointsLabel.text = profileViewModel.getCurrentPointsString()
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshViews), name: Notification.Name(rawValue: NOTIF_POINTS_CHANGED), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshViews), name: Notification.Name(rawValue: NOTIF_COOKIE_LIST_CHANGED), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("ProfileViewController deinit")
    }
    
    // MARK: Actions
    @objc func dismissScreen() {
        dismiss(animated: true) {}
    }
    
    @objc func toCookieShopVC() {
        let cookieShopVC = CookieShopViewController(dataService: DataService(defaults: UserDefaults.standard))
        self.navigationController?.pushViewController(cookieShopVC, animated: true)
    }
    
    @objc func toResetDataView() {
        let actionSheet = UIAlertController(title: "Which data do you want to reset?", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Reset points", style: .destructive, handler: { (action) in
            self.profileViewModel.resetPoints()
        }))
        actionSheet.addAction(UIAlertAction(title: "Reset cookies purchased", style: .destructive, handler: { (action) in
            self.profileViewModel.resetCookieList()
        }))
        actionSheet.addAction(UIAlertAction(title: "Reset to-do list", style: .destructive, handler: { (action) in
            self.profileViewModel.resetToDoList()
        }))
        actionSheet.addAction(UIAlertAction(title: "Reset all data", style: .destructive, handler: { (action) in
            self.profileViewModel.resetPoints()
            self.profileViewModel.resetCookieList()
            self.profileViewModel.resetToDoList()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    @objc func toAboutView() {
        self.view.addSubview(AboutView())
    }
    
    @objc func refreshViews() {
        pointsLabel.text = profileViewModel.getCurrentPointsString()
        cookieTableView.reloadData()
    }
}

// MARK: - Delegate Methods
extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Your Cookies"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if profileViewModel.getCookieList().count == 0 {
            return 1 // Show a "You currently have no purchased cookies" cell if no cookies have been purchased
        }
        return profileViewModel.getCookieList().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: PURCHASED_COOKIE_IDENTIFIER, for: indexPath)
        if profileViewModel.getCookieList().count == 0 {
            cell.textLabel?.text = "You currently have no purchased cookies"
            cell.imageView?.image = nil
        } else {
            cell = UITableViewCell(style: .value1, reuseIdentifier: PURCHASED_COOKIE_IDENTIFIER)
            cell.textLabel?.text = profileViewModel.getCookieList()[indexPath.row].name
            cell.imageView?.image = UIImage(named: profileViewModel.getCookieList()[indexPath.row].imagePath)
        }
        return cell
    }
}

// MARK: - Self-Sizing UITableView
final class CookieTableView: UITableView {
    override func reloadData() {
      super.reloadData()
      self.invalidateIntrinsicContentSize()
      self.layoutIfNeeded()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: contentSize.width, height: contentSize.height)
    }
}
