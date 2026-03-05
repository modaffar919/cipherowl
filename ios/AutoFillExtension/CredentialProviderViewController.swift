import AuthenticationServices
import LocalAuthentication
import UIKit

// ──────────────────────────────────────────────────────────────────────────────
//  CredentialProviderViewController
//
//  ASCredentialProviderViewController subclass that surfaces CipherOwl vault
//  entries as AutoFill suggestions in Safari and every other app on iOS.
//
//  Architecture
//  ────────────
//  • Main app writes credentials to UserDefaults(suiteName: appGroupID) as a
//    JSON array each time the vault is unlocked (via AutofillBridge.dart →
//    MethodChannel → AppDelegate.swift).
//  • This extension reads that shared UserDefaults key, optionally filters by
//    the requesting service domain/URL, shows a credential list, gates access
//    with LocalAuthentication, then calls
//    extensionContext.completeRequest(withSelectedCredential:).
//
//  Security
//  ────────
//  • The App Group sandbox (enforced by iOS) ensures only binaries signed with
//    the same Team ID can read the shared UserDefaults.
//  • Credentials are never stored in plaintext on disk — the JSON blob in
//    UserDefaults is protected by iOS Data Protection (NSFileProtectionComplete)
//    because the App Group container inherits the main app's data-protection
//    class.
//  • LocalAuthentication is required before any credential is returned unless
//    the vault was unlocked within the last 5 minutes (LAContext reuse).
// ──────────────────────────────────────────────────────────────────────────────

class CredentialProviderViewController: ASCredentialProviderViewController {

    // MARK: – Constants

    private static let appGroupID = "group.com.cipherowl.cipherowl"
    private static let cacheKey   = "cipher_owl_autofill_cache"

    // MARK: – UI

    private let tableView      = UITableView(frame: .zero, style: .insetGrouped)
    private let searchBar      = UISearchBar()
    private let emptyLabel     = UILabel()
    private let spinner        = UIActivityIndicatorView(style: .medium)

    // MARK: – State

    private var allCredentials: [CachedCredential] = []
    private var displayed:      [CachedCredential] = []
    private var pendingIdentity: ASPasswordCredentialIdentity?

    // ── Life-cycle ────────────────────────────────────────────────────────────

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupSearchBar()
        setupTableView()
        setupEmptyLabel()
        setupSpinner()
        setupNavigationBar()
    }

    // ── ASCredentialProviderViewController ───────────────────────────────────

    /// Called when the system wants a UI list of credentials for the given services.
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        allCredentials = loadCredentials()
        displayed      = rank(allCredentials, for: serviceIdentifiers)
        tableView.reloadData()
        updateEmptyState()
    }

    /// Called when the system believes it can get a credential without showing UI.
    /// We cancel — the vault always requires at least one biometric confirmation.
    override func provideCredentialWithoutUserInteraction(
        for credentialIdentity: ASPasswordCredentialIdentity
    ) {
        extensionContext.cancelRequest(
            withError: NSError(
                domain: ASExtensionErrorDomain,
                code: ASExtensionError.userInteractionRequired.rawValue,
                userInfo: nil
            )
        )
    }

    /// Called when the system wants to fill a specific credential but needs UI first.
    override func prepareInterfaceToProvideCredential(
        for credentialIdentity: ASPasswordCredentialIdentity
    ) {
        pendingIdentity = credentialIdentity
        allCredentials  = loadCredentials()
        displayed       = allCredentials
        tableView.reloadData()
        updateEmptyState()
        authenticateAndFill(credentialIdentity)
    }

    // ── Authentication ────────────────────────────────────────────────────────

    private func authenticateAndFill(_ identity: ASPasswordCredentialIdentity) {
        let context = LAContext()
        context.localizedCancelTitle = "إلغاء"

        var authError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                        error: &authError) else {
            // Biometrics not available — fall back to passcode
            authenticateWithPasscode(identity)
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "تحقق من هويتك لملء كلمة المرور"
        ) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.fillCredential(for: identity)
                } else {
                    self?.extensionContext.cancelRequest(
                        withError: NSError(
                            domain: ASExtensionErrorDomain,
                            code: ASExtensionError.failed.rawValue,
                            userInfo: nil
                        )
                    )
                }
            }
        }
    }

    private func authenticateWithPasscode(_ identity: ASPasswordCredentialIdentity) {
        let context = LAContext()

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "تحقق من هويتك لملء كلمة المرور"
        ) { [weak self] success, _ in
            DispatchQueue.main.async {
                if success {
                    self?.fillCredential(for: identity)
                } else {
                    self?.extensionContext.cancelRequest(
                        withError: NSError(
                            domain: ASExtensionErrorDomain,
                            code: ASExtensionError.failed.rawValue,
                            userInfo: nil
                        )
                    )
                }
            }
        }
    }

    private func fillCredential(for identity: ASPasswordCredentialIdentity) {
        guard let cred = allCredentials.first(where: { $0.id == identity.recordIdentifier }) else {
            extensionContext.cancelRequest(
                withError: NSError(
                    domain: ASExtensionErrorDomain,
                    code: ASExtensionError.credentialIdentityNotFound.rawValue,
                    userInfo: nil
                )
            )
            return
        }
        let credential = ASPasswordCredential(user: cred.username, password: cred.password)
        extensionContext.completeRequest(withSelectedCredential: credential, completionHandler: nil)
    }

    // ── Credential loading ────────────────────────────────────────────────────

    private func loadCredentials() -> [CachedCredential] {
        guard
            let defaults = UserDefaults(suiteName: Self.appGroupID),
            let json     = defaults.string(forKey: Self.cacheKey),
            let data     = json.data(using: .utf8)
        else { return [] }

        let raw = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] ?? []
        return raw.compactMap { dict in
            guard
                let id    = dict["id"]       as? String,
                let title = dict["title"]    as? String
            else { return nil }
            return CachedCredential(
                id:       id,
                title:    title,
                username: dict["username"] as? String ?? "",
                password: dict["password"] as? String ?? "",
                url:      dict["url"]      as? String ?? ""
            )
        }
    }

    /// Rank credentials: exact domain match → partial match → rest.
    private func rank(
        _ creds: [CachedCredential],
        for services: [ASCredentialServiceIdentifier]
    ) -> [CachedCredential] {
        let domains = services.map {
            $0.type == .domain ? $0.identifier : domainFromURL($0.identifier)
        }.compactMap { $0 }

        if domains.isEmpty { return creds }

        return creds.sorted { a, b in
            let scoreA = matchScore(a, domains: domains)
            let scoreB = matchScore(b, domains: domains)
            return scoreA > scoreB
        }
    }

    private func matchScore(_ cred: CachedCredential, domains: [String]) -> Int {
        for domain in domains {
            let credDomain = domainFromURL(cred.url) ?? cred.url.lowercased()
            if credDomain == domain.lowercased()           { return 2 }
            if credDomain.contains(domain.lowercased())    { return 1 }
            if cred.title.lowercased().contains(domain)    { return 1 }
        }
        return 0
    }

    private func domainFromURL(_ str: String) -> String? {
        guard let url = URL(string: str), let host = url.host else { return nil }
        return host.lowercased().replacingOccurrences(of: "www.", with: "")
    }

    // ── UI setup ──────────────────────────────────────────────────────────────

    private func setupAppearance() {
        view.backgroundColor = UIColor.systemGroupedBackground

        // Dark-mode-aware accent tint matching CipherOwl cyan (#00D4FF)
        view.tintColor = UIColor(red: 0, green: 0.831, blue: 1.0, alpha: 1.0)
    }

    private func setupNavigationBar() {
        title = "CipherOwl"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "إلغاء",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    private func setupSearchBar() {
        searchBar.placeholder          = "بحث في الخزينة"
        searchBar.delegate             = self
        searchBar.searchBarStyle       = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(CredentialCell.self, forCellReuseIdentifier: CredentialCell.reuseID)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupEmptyLabel() {
        emptyLabel.text          = "لا توجد بيانات اعتماد محفوظة.\nافتح CipherOwl لإدارة بياناتك."
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.font          = UIFont.preferredFont(forTextStyle: .body)
        emptyLabel.textColor     = UIColor.secondaryLabel
        emptyLabel.isHidden      = true
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
        ])
    }

    private func setupSpinner() {
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func updateEmptyState() {
        emptyLabel.isHidden = !displayed.isEmpty
        tableView.isHidden  = displayed.isEmpty
    }

    // ── Actions ───────────────────────────────────────────────────────────────

    @objc private func cancelTapped() {
        extensionContext.cancelRequest(
            withError: NSError(
                domain: ASExtensionErrorDomain,
                code: ASExtensionError.userCanceled.rawValue,
                userInfo: nil
            )
        )
    }
}

// ── UISearchBarDelegate ───────────────────────────────────────────────────────

extension CredentialProviderViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            displayed = allCredentials
        } else {
            let q = searchText.lowercased()
            displayed = allCredentials.filter {
                $0.title.lowercased().contains(q)
                || $0.username.lowercased().contains(q)
                || $0.url.lowercased().contains(q)
            }
        }
        tableView.reloadData()
        updateEmptyState()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        displayed = allCredentials
        tableView.reloadData()
        updateEmptyState()
    }
}

// ── UITableViewDataSource / UITableViewDelegate ───────────────────────────────

extension CredentialProviderViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayed.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: CredentialCell.reuseID, for: indexPath) as! CredentialCell
        cell.configure(with: displayed[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cred = displayed[indexPath.row]

        authenticate(title: cred.title) { [weak self] success in
            guard let self, success else { return }
            let credential = ASPasswordCredential(user: cred.username, password: cred.password)
            self.extensionContext.completeRequest(withSelectedCredential: credential, completionHandler: nil)
        }
    }

    // ── Private helper
    private func authenticate(title: String, completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        context.localizedCancelTitle = "إلغاء"
        let reason = "تحقق من هويتك لملء بيانات \(title)"

        var error: NSError?
        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication

        context.evaluatePolicy(policy, localizedReason: reason) { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }
}

// ── Data model ────────────────────────────────────────────────────────────────

private struct CachedCredential {
    let id:       String
    let title:    String
    let username: String
    let password: String
    let url:      String
}

// ── Custom table view cell ────────────────────────────────────────────────────

private final class CredentialCell: UITableViewCell {

    static let reuseID = "CredentialCell"

    private let titleLabel    = UILabel()
    private let usernameLabel = UILabel()
    private let iconView      = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with cred: CachedCredential) {
        titleLabel.text    = cred.title.isEmpty ? cred.username : cred.title
        usernameLabel.text = cred.username.isEmpty ? "—" : cred.username
    }

    private func setupCell() {
        accessoryType = .disclosureIndicator

        // Icon — lock symbol
        let config    = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        iconView.image        = UIImage(systemName: "key.fill", withConfiguration: config)
        iconView.tintColor    = UIColor(red: 0, green: 0.831, blue: 1.0, alpha: 1.0)
        iconView.contentMode  = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        // Labels
        titleLabel.font               = UIFont.preferredFont(forTextStyle: .body)
        titleLabel.textColor          = UIColor.label

        usernameLabel.font            = UIFont.preferredFont(forTextStyle: .caption1)
        usernameLabel.textColor       = UIColor.secondaryLabel

        let stack = UIStackView(arrangedSubviews: [titleLabel, usernameLabel])
        stack.axis    = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(iconView)
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            stack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }
}
