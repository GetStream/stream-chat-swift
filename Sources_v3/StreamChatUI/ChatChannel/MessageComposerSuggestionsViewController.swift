//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

open class MessageComposerSuggestionsViewController<ExtraData: UIExtraDataTypes>: UIViewController,
    UITableViewDelegate,
    UITableViewDataSource {
    // MARK: - Property
    
    public weak var owningViewController: UIViewController?

    public let uiConfig: UIConfig<ExtraData>
    
    public var suggestions: [String] = ["Brian", "David", "Pavel"] {
        didSet {
            updateContent()
        }
    }
    
    public var position: CGPoint = CGPoint(x: 0, y: 300) {
        didSet {
            updateContent()
        }
    }
    
    public var maxHeight: CGFloat = 300.0 {
        didSet {
            updateContent()
        }
    }
    
    public var calculatedHeight: CGFloat {
        min(CGFloat(40 * suggestions.count), maxHeight)
    }
    
    // MARK: - Subviews
    
    public private(set) lazy var tableView = UITableView().withoutAutoresizingMaskConstraints
    
    // MARK: - Init
    
    public required init(
        uiConfig: UIConfig<ExtraData> = .default
    ) {
        self.uiConfig = uiConfig

        super.init(nibName: nil, bundle: nil)
        
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        uiConfig = .default
        
        super.init(coder: coder)
        
        commonInit()
    }
    
    public func commonInit() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        modalPresentationStyle = .custom
        modalTransitionStyle = .crossDissolve
    }
    
    // MARK: - Overrides
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        view.embed(tableView)
        
        setupAppearance()
        setupLayout()
    }
    
    override open func updateViewConstraints() {
        widthConstraint?.constant = UIScreen.main.bounds.width
        heightConstraint?.constant = calculatedHeight
        
        positionXConstraint?.constant = position.x
        positionYConstraint?.constant = position.y
        
        super.updateViewConstraints()
    }
    
    // MARK: - Public
    
    open func setupAppearance() {
        view.backgroundColor = .clear
        tableView.backgroundColor = .white
        tableView.estimatedRowHeight = 40
        tableView.showsVerticalScrollIndicator = false
    }
    
    var heightConstraint: NSLayoutConstraint?
    var widthConstraint: NSLayoutConstraint?
    var positionXConstraint: NSLayoutConstraint?
    var positionYConstraint: NSLayoutConstraint?
    
    open func setupLayout() {
        view.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        heightConstraint = .init(
            item: tableView,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: 300
        )
        
        widthConstraint = .init(
            item: tableView,
            attribute: .width,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: UIScreen.main.bounds.width
        )
        
        positionXConstraint = .init(
            item: tableView,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: view,
            attribute: .centerX,
            multiplier: 1,
            constant: 200
        )
        
        positionYConstraint = .init(
            item: tableView,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: view,
            attribute: .centerY,
            multiplier: 1,
            constant: 200
        )
        
        let constraints = [heightConstraint, widthConstraint, positionXConstraint, positionYConstraint].compactMap { $0 }
        NSLayoutConstraint.activate(constraints)
        
        updateContent()
    }
    
    open func updateContent() {
        tableView.reloadData()
        
        view.setNeedsUpdateConstraints()
        view.layoutIfNeeded()
    }
        
    public func show() {
        guard let owner = owningViewController else { return }
        owningViewController?.addChild(self)
        owner.view.addSubview(view)
        didMove(toParent: owner)
    }
    
    public func dismiss() {
        removeFromParent()
        view.removeFromSuperview()
    }
    
    // MARK: - UITableView
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        suggestions.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = suggestions[indexPath.row]
        
        return cell
    }
}
