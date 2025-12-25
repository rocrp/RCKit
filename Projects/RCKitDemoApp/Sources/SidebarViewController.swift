import SharedUI
import UIKit

final class SidebarViewController: UIViewController {
    var onSectionSelected: ((DemoSection) -> Void)?

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, DemoSection>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "RCKit Demo"
        setupCollectionView()
        setupDataSource()
        applySnapshot()
    }

    private func setupCollectionView() {
        var config = UICollectionLayoutListConfiguration(appearance: .sidebar)
        config.headerMode = .none
        let layout = UICollectionViewCompositionalLayout.list(using: config)

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.delegate = self
        view.addSubview(collectionView)
    }

    private func setupDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, DemoSection> {
            cell,
            _,
            section in
            var content = cell.defaultContentConfiguration()
            content.text = section.title
            content.image = UIImage(systemName: section.systemImage)
            cell.contentConfiguration = content
            cell.accessories = [.disclosureIndicator()]
        }

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) {
            collectionView,
            indexPath,
            section in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: section)
        }
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, DemoSection>()
        snapshot.appendSections([0])
        snapshot.appendItems(DemoSection.allCases, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - UICollectionViewDelegate

extension SidebarViewController: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let section = dataSource.itemIdentifier(for: indexPath) else { return }
        onSectionSelected?(section)
    }
}
