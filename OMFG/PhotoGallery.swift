import UIKit

// MARK: - Constants

private enum Gallery {
    static let cellSpacing: CGFloat = 2
    static let cornerRadius: CGFloat = 12
    static let maxVisiblePhotos = 5
    static let badgeOverlayAlpha: CGFloat = 0.5
    static let badgeFontSize: CGFloat = 24
    static let locationSearchRadius = 200 // characters after :IMAGE: to look for :LOCATION:
}

private enum Viewer {
    static let animationDuration: TimeInterval = 0.05
    static let swipeCrossfadeDuration: TimeInterval = 0.2
    static let backgroundAlpha: CGFloat = 0.95
    static let imageHeightRatio: CGFloat = 0.7
    static let imageCenterYOffset: CGFloat = -40
    static let metadataPadding: CGFloat = 20
    static let metadataSpacing: CGFloat = 4
    static let timestampFontSize: CGFloat = 15
    static let locationFontSize: CGFloat = 13
    static let dotInactiveColor = UIColor(white: 0.4, alpha: 1)
}

// MARK: - Photo Entry

struct PhotoEntry {
    let filename: String
    let location: String?
    let noteDirectory: URL

    var imageURL: URL { noteDirectory.appendingPathComponent(filename) }

    var timestamp: String? {
        let name = (filename as NSString).deletingPathExtension
        guard name.count == 6,
              let h = Int(name.prefix(2)),
              let m = Int(name.dropFirst(2).prefix(2))
        else { return nil }
        let ampm = h >= 12 ? "PM" : "AM"
        let hour = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        return String(format: "%d:%02d %@", hour, m, ampm)
    }
}

// MARK: - Photo Parser

enum PhotoParser {
    private static let imagePattern = try! NSRegularExpression(
        pattern: ":IMAGE:\\s*(.+?)\\s*$",
        options: .anchorsMatchLines
    )
    private static let locationPattern = try! NSRegularExpression(
        pattern: ":LOCATION:\\s*(.+?)\\s*$",
        options: .anchorsMatchLines
    )

    static func parse(from text: String, noteDirectory: URL) -> [PhotoEntry] {
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)

        let imageMatches = imagePattern.matches(in: text, range: fullRange)

        return imageMatches.compactMap { match -> PhotoEntry? in
            guard let filenameRange = Range(match.range(at: 1), in: text) else { return nil }
            let filename = String(text[filenameRange])

            let searchStart = match.range.location
            let searchEnd = min(searchStart + Gallery.locationSearchRadius, nsText.length)
            let searchRange = NSRange(location: searchStart, length: searchEnd - searchStart)

            var location: String?
            if let locMatch = locationPattern.firstMatch(in: text, range: searchRange),
               let locRange = Range(locMatch.range(at: 1), in: text) {
                let fullLoc = String(text[locRange])
                if let pipeIndex = fullLoc.firstIndex(of: "|") {
                    location = fullLoc[..<pipeIndex].trimmingCharacters(in: .whitespaces)
                } else {
                    location = fullLoc
                }
            }

            return PhotoEntry(filename: filename, location: location, noteDirectory: noteDirectory)
        }
    }
}

// MARK: - Photo Gallery View

final class PhotoGalleryView: UIView {
    private var photoEntries: [PhotoEntry] = []
    private var imageViews: [UIImageView] = []
    private var badgeLabel: UILabel?

    /// Passes (index, entries, sourceFrame in window coordinates)
    var onPhotoTapped: ((Int, [PhotoEntry], CGRect) -> Void)?

    func update(with entries: [PhotoEntry]) {
        photoEntries = entries
        rebuildImageViews()
        setNeedsLayout()
    }

    private func rebuildImageViews() {
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()
        badgeLabel?.removeFromSuperview()
        badgeLabel = nil

        let count = min(photoEntries.count, Gallery.maxVisiblePhotos)
        for i in 0..<count {
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.isUserInteractionEnabled = true
            iv.tag = i

            let tap = UITapGestureRecognizer(target: self, action: #selector(photoTapped(_:)))
            iv.addGestureRecognizer(tap)

            if let data = try? Data(contentsOf: photoEntries[i].imageURL),
               let image = UIImage(data: data) {
                iv.image = image
            }

            addSubview(iv)
            imageViews.append(iv)
        }

        if photoEntries.count > Gallery.maxVisiblePhotos {
            let overlay = UIView()
            overlay.backgroundColor = UIColor.black.withAlphaComponent(Gallery.badgeOverlayAlpha)
            overlay.isUserInteractionEnabled = false
            imageViews.last?.addSubview(overlay)
            overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            overlay.frame = imageViews.last?.bounds ?? .zero

            let label = UILabel()
            label.text = "+\(photoEntries.count - Gallery.maxVisiblePhotos + 1)"
            label.textColor = .white
            label.font = .systemFont(ofSize: Gallery.badgeFontSize, weight: .semibold)
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            imageViews.last?.addSubview(label)
            if let last = imageViews.last {
                NSLayoutConstraint.activate([
                    label.centerXAnchor.constraint(equalTo: last.centerXAnchor),
                    label.centerYAnchor.constraint(equalTo: last.centerYAnchor)
                ])
            }
            badgeLabel = label
        }
    }

    @objc private func photoTapped(_ gesture: UITapGestureRecognizer) {
        guard let iv = gesture.view as? UIImageView, let window = window else { return }
        let sourceFrame = iv.convert(iv.bounds, to: window)
        onPhotoTapped?(iv.tag, photoEntries, sourceFrame)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let count = imageViews.count
        guard count > 0 else { return }

        let w = bounds.width
        let h = bounds.height
        let sp = Gallery.cellSpacing

        switch count {
        case 1:
            imageViews[0].frame = bounds
            applyCorners(imageViews[0], corners: .allCorners)

        case 2:
            let halfW = (w - sp) / 2
            imageViews[0].frame = CGRect(x: 0, y: 0, width: halfW, height: h)
            imageViews[1].frame = CGRect(x: halfW + sp, y: 0, width: halfW, height: h)
            applyCorners(imageViews[0], corners: [.topLeft, .bottomLeft])
            applyCorners(imageViews[1], corners: [.topRight, .bottomRight])

        case 3:
            let halfW = (w - sp) / 2
            let halfH = (h - sp) / 2
            imageViews[0].frame = CGRect(x: 0, y: 0, width: halfW, height: h)
            imageViews[1].frame = CGRect(x: halfW + sp, y: 0, width: halfW, height: halfH)
            imageViews[2].frame = CGRect(x: halfW + sp, y: halfH + sp, width: halfW, height: halfH)
            applyCorners(imageViews[0], corners: [.topLeft, .bottomLeft])
            applyCorners(imageViews[1], corners: [.topRight])
            applyCorners(imageViews[2], corners: [.bottomRight])

        case 4:
            let halfW = (w - sp) / 2
            let halfH = (h - sp) / 2
            imageViews[0].frame = CGRect(x: 0, y: 0, width: halfW, height: halfH)
            imageViews[1].frame = CGRect(x: halfW + sp, y: 0, width: halfW, height: halfH)
            imageViews[2].frame = CGRect(x: 0, y: halfH + sp, width: halfW, height: halfH)
            imageViews[3].frame = CGRect(x: halfW + sp, y: halfH + sp, width: halfW, height: halfH)
            applyCorners(imageViews[0], corners: [.topLeft])
            applyCorners(imageViews[1], corners: [.topRight])
            applyCorners(imageViews[2], corners: [.bottomLeft])
            applyCorners(imageViews[3], corners: [.bottomRight])

        default: // 5+
            let halfW = (w - sp) / 2
            let cellW = (halfW - sp) / 2
            let cellH = (h - sp) / 2
            imageViews[0].frame = CGRect(x: 0, y: 0, width: halfW, height: h)
            imageViews[1].frame = CGRect(x: halfW + sp, y: 0, width: cellW, height: cellH)
            imageViews[2].frame = CGRect(x: halfW + sp + cellW + sp, y: 0, width: cellW, height: cellH)
            imageViews[3].frame = CGRect(x: halfW + sp, y: cellH + sp, width: cellW, height: cellH)
            imageViews[4].frame = CGRect(x: halfW + sp + cellW + sp, y: cellH + sp, width: cellW, height: cellH)
            applyCorners(imageViews[0], corners: [.topLeft, .bottomLeft])
            applyCorners(imageViews[1], corners: [])
            applyCorners(imageViews[2], corners: [.topRight])
            applyCorners(imageViews[3], corners: [])
            applyCorners(imageViews[4], corners: [.bottomRight])
        }

        if let last = imageViews.last, let overlay = last.subviews.first(where: { $0 != badgeLabel }) {
            overlay.frame = last.bounds
        }
    }

    private func applyCorners(_ view: UIView, corners: UIRectCorner) {
        let mask = CAShapeLayer()
        let radii = CGSize(width: Gallery.cornerRadius, height: Gallery.cornerRadius)
        mask.path = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: corners, cornerRadii: radii).cgPath
        view.layer.mask = mask
    }
}

// MARK: - Fullscreen Photo Viewer

final class PhotoViewerOverlay: UIView {
    private let imageView = UIImageView()
    private let pageControl = UIPageControl()
    private let timestampLabel = UILabel()
    private let locationLabel = UILabel()
    private let metadataStack = UIStackView()

    private var entries: [PhotoEntry] = []
    private var currentIndex = 0
    private var sourceFrame: CGRect = .zero
    private var finalImageFrame: CGRect = .zero

    func show(entries: [PhotoEntry], startIndex: Int, sourceFrame: CGRect, in parentView: UIView) {
        self.entries = entries
        self.currentIndex = startIndex
        self.sourceFrame = sourceFrame

        frame = parentView.bounds
        backgroundColor = UIColor(white: 0, alpha: 0)
        parentView.addSubview(self)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Gallery.cornerRadius
        imageView.frame = sourceFrame
        addSubview(imageView)

        metadataStack.axis = .vertical
        metadataStack.alignment = .center
        metadataStack.spacing = Viewer.metadataSpacing
        metadataStack.translatesAutoresizingMaskIntoConstraints = false
        metadataStack.alpha = 0
        addSubview(metadataStack)

        pageControl.numberOfPages = entries.count
        pageControl.currentPage = startIndex
        pageControl.isUserInteractionEnabled = false
        pageControl.pageIndicatorTintColor = Viewer.dotInactiveColor
        pageControl.currentPageIndicatorTintColor = .white
        pageControl.isHidden = entries.count <= 1
        metadataStack.addArrangedSubview(pageControl)

        timestampLabel.textColor = .white
        timestampLabel.font = .systemFont(ofSize: Viewer.timestampFontSize, weight: .semibold)
        timestampLabel.textAlignment = .center
        metadataStack.addArrangedSubview(timestampLabel)

        locationLabel.textColor = .lightGray
        locationLabel.font = .systemFont(ofSize: Viewer.locationFontSize)
        locationLabel.textAlignment = .center
        locationLabel.numberOfLines = 0
        metadataStack.addArrangedSubview(locationLabel)

        NSLayoutConstraint.activate([
            metadataStack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -Viewer.metadataPadding),
            metadataStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Viewer.metadataPadding),
            metadataStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Viewer.metadataPadding),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissTapped))
        addGestureRecognizer(tap)

        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(dismissTapped))
        swipeDown.direction = .down
        addGestureRecognizer(swipeDown)

        if entries.count > 1 {
            let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
            swipeLeft.direction = .left
            addGestureRecognizer(swipeLeft)

            let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
            swipeRight.direction = .right
            addGestureRecognizer(swipeRight)
        }

        loadImage(for: entries[startIndex])
        updateMetadata(for: entries[startIndex])
        finalImageFrame = computeFinalFrame()

        UIView.animate(withDuration: Viewer.animationDuration, delay: 0, options: .curveEaseOut, animations: {
            self.backgroundColor = UIColor(white: 0, alpha: Viewer.backgroundAlpha)
            self.imageView.frame = self.finalImageFrame
            self.imageView.layer.cornerRadius = 0
            self.metadataStack.alpha = 1
        }) { _ in
            self.imageView.contentMode = .scaleAspectFit
        }
    }

    private func loadImage(for entry: PhotoEntry) {
        if let data = try? Data(contentsOf: entry.imageURL),
           let image = UIImage(data: data) {
            imageView.image = image
        }
    }

    private func computeFinalFrame() -> CGRect {
        guard let image = imageView.image else { return bounds }
        let availW = bounds.width
        let availH = bounds.height * Viewer.imageHeightRatio
        let aspect = image.size.width / image.size.height
        var w: CGFloat, h: CGFloat
        if aspect > availW / availH {
            w = availW
            h = w / aspect
        } else {
            h = availH
            w = h * aspect
        }
        let x = (bounds.width - w) / 2
        let y = (bounds.height - h) / 2 + Viewer.imageCenterYOffset
        return CGRect(x: x, y: y, width: w, height: h)
    }

    private func updateMetadata(for entry: PhotoEntry) {
        let dirName = entry.noteDirectory.lastPathComponent
        let dateStr = formatDate(dirName)
        if let time = entry.timestamp {
            timestampLabel.text = "\(dateStr) · \(time)"
        } else {
            timestampLabel.text = dateStr
        }

        locationLabel.text = entry.location
        locationLabel.isHidden = entry.location == nil

        pageControl.currentPage = currentIndex
    }

    private func formatDate(_ dirName: String) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        guard let date = df.date(from: dirName) else { return dirName }
        df.dateFormat = "MMM d, yyyy"
        return df.string(from: date)
    }

    @objc private func handleSwipeLeft() {
        guard currentIndex < entries.count - 1 else { return }
        currentIndex += 1
        let entry = entries[currentIndex]
        UIView.transition(with: imageView, duration: Viewer.swipeCrossfadeDuration, options: .transitionCrossDissolve) {
            self.loadImage(for: entry)
        }
        updateMetadata(for: entry)
    }

    @objc private func handleSwipeRight() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        let entry = entries[currentIndex]
        UIView.transition(with: imageView, duration: Viewer.swipeCrossfadeDuration, options: .transitionCrossDissolve) {
            self.loadImage(for: entry)
        }
        updateMetadata(for: entry)
    }

    @objc private func dismissTapped() {
        imageView.contentMode = .scaleAspectFill

        UIView.animate(withDuration: Viewer.animationDuration, delay: 0, options: .curveEaseIn, animations: {
            self.backgroundColor = UIColor(white: 0, alpha: 0)
            self.imageView.frame = self.sourceFrame
            self.imageView.layer.cornerRadius = Gallery.cornerRadius
            self.metadataStack.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }
}
