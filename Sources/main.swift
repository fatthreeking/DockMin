import Cocoa
import ApplicationServices
import Foundation

@_silgen_name("_AXUIElementGetWindow")
func _AXUIElementGetWindow(_ element: AXUIElement, _ windowID: UnsafeMutablePointer<CGWindowID>) -> AXError

@_silgen_name("GetProcessForPID")
func _DockMinGetProcessForPID(_ pid: pid_t, _ psn: UnsafeMutablePointer<ProcessSerialNumber>) -> OSStatus

@_silgen_name("SetFrontProcessWithOptions")
func _DockMinSetFrontProcessWithOptions(_ psn: UnsafePointer<ProcessSerialNumber>, _ options: UInt32) -> OSStatus

private typealias SLPSSetFrontProcessWithOptionsFunc = @convention(c) (
    UnsafePointer<ProcessSerialNumber>,
    CGWindowID,
    UInt32
) -> CGError

private let _DockMinSLPSSetFrontProcessWithOptions: SLPSSetFrontProcessWithOptionsFunc? = {
    guard let sym = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "_SLPSSetFrontProcessWithOptions") else {
        return nil
    }
    return unsafeBitCast(sym, to: SLPSSetFrontProcessWithOptionsFunc.self)
}()

@_silgen_name("CGWindowListCreateImage")
func _DockMinCaptureWindowImage(
    _ screenBounds: CGRect,
    _ listOption: CGWindowListOption,
    _ windowID: CGWindowID,
    _ imageOption: CGWindowImageOption
) -> CGImage?

// MARK: - Multi-Window Hover Preview Data Model
struct WindowPreviewItem {
    let windowID: CGWindowID
    let element: AXUIElement
    let title: String
    let isMinimized: Bool
    let isFocused: Bool
    let thumbnail: NSImage?
}

// MARK: - Preview Card Top-Right Close Button
final class WindowCloseButton: NSView {
    private var isHovered = false {
        didSet {
            needsDisplay = true
        }
    }
    private var trackingArea: NSTrackingArea?
    var onClick: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        toolTip = "Close Window"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
    }

    override func mouseDown(with event: NSEvent) {
        // Intercept mouseDown so clicking close does not trigger window activation on the card
    }

    override func mouseUp(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        if bounds.contains(loc) {
            onClick?()
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let circleRect = bounds.insetBy(dx: 1.0, dy: 1.0)
        let path = NSBezierPath(ovalIn: circleRect)

        if isHovered {
            NSColor.systemRed.setFill()
            path.fill()

            NSColor.white.setStroke()
            let crossPath = NSBezierPath()
            let crossInset: CGFloat = 4.2
            let innerRect = circleRect.insetBy(dx: crossInset, dy: crossInset)
            crossPath.move(to: NSPoint(x: innerRect.minX, y: innerRect.minY))
            crossPath.line(to: NSPoint(x: innerRect.maxX, y: innerRect.maxY))
            crossPath.move(to: NSPoint(x: innerRect.minX, y: innerRect.maxY))
            crossPath.line(to: NSPoint(x: innerRect.maxX, y: innerRect.minY))
            crossPath.lineWidth = 1.3
            crossPath.lineCapStyle = .round
            crossPath.stroke()
        } else {
            NSColor.labelColor.withAlphaComponent(0.08).setFill()
            path.fill()

            NSColor.secondaryLabelColor.withAlphaComponent(0.75).setStroke()
            let crossPath = NSBezierPath()
            let crossInset: CGFloat = 4.8
            let innerRect = circleRect.insetBy(dx: crossInset, dy: crossInset)
            crossPath.move(to: NSPoint(x: innerRect.minX, y: innerRect.minY))
            crossPath.line(to: NSPoint(x: innerRect.maxX, y: innerRect.maxY))
            crossPath.move(to: NSPoint(x: innerRect.minX, y: innerRect.maxY))
            crossPath.line(to: NSPoint(x: innerRect.maxX, y: innerRect.minY))
            crossPath.lineWidth = 1.2
            crossPath.lineCapStyle = .round
            crossPath.stroke()
        }
    }
}

// MARK: - Single Window Preview Card View
final class WindowPreviewCardView: NSView {
    private let item: WindowPreviewItem
    private let appIcon: NSImage?
    private let onSelect: (WindowPreviewItem) -> Void
    private let onClose: (WindowPreviewItem) -> Void
    private var isHovered = false {
        didSet {
            needsDisplay = true
        }
    }
    private var trackingArea: NSTrackingArea?

    init(frame frameRect: NSRect, item: WindowPreviewItem, appIcon: NSImage?, onSelect: @escaping (WindowPreviewItem) -> Void, onClose: @escaping (WindowPreviewItem) -> Void) {
        self.item = item
        self.appIcon = appIcon
        self.onSelect = onSelect
        self.onClose = onClose
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.masksToBounds = true
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        // Header bar (app icon + window title + close button)
        let headerHeight: CGFloat = 26
        let padding: CGFloat = 8

        let closeBtnSize: CGFloat = 16
        let closeBtnRect = NSRect(
            x: bounds.width - padding - closeBtnSize,
            y: bounds.height - headerHeight + (headerHeight - closeBtnSize) / 2,
            width: closeBtnSize,
            height: closeBtnSize
        )
        let closeButton = WindowCloseButton(frame: closeBtnRect)
        closeButton.onClick = { [weak self] in
            guard let self = self else { return }
            self.onClose(self.item)
        }
        addSubview(closeButton)

        var titleX = padding
        if let icon = appIcon {
            let iconView = NSImageView(frame: NSRect(x: padding, y: bounds.height - headerHeight + 5, width: 16, height: 16))
            iconView.image = icon
            iconView.imageScaling = .scaleProportionallyUpOrDown
            addSubview(iconView)
            titleX += 20
        }

        let titleWidth = max(40, closeBtnRect.minX - titleX - 6)
        let titleLabel = NSTextField(labelWithString: item.title)
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = NSColor.labelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.maximumNumberOfLines = 1
        titleLabel.frame = NSRect(
            x: titleX,
            y: bounds.height - headerHeight + 4,
            width: titleWidth,
            height: 18
        )
        addSubview(titleLabel)

        // Thumbnail region (falls back to lightweight native window skeleton without prompting for Screen Recording)
        let previewRect = NSRect(
            x: padding,
            y: padding,
            width: bounds.width - padding * 2,
            height: bounds.height - headerHeight - padding - 2
        )

        let previewContainer = NSView(frame: previewRect)
        previewContainer.wantsLayer = true
        previewContainer.layer?.cornerRadius = 6
        previewContainer.layer?.masksToBounds = true
        previewContainer.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.45).cgColor
        previewContainer.layer?.borderWidth = 0.5
        previewContainer.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.35).cgColor

        if let thumb = item.thumbnail {
            let thumbView = NSImageView(frame: previewContainer.bounds)
            thumbView.image = thumb
            thumbView.imageScaling = .scaleProportionallyUpOrDown
            previewContainer.addSubview(thumbView)
        } else {
            let skeletonFrame = NSRect(
                x: 12,
                y: 23,
                width: previewRect.width - 24,
                height: previewRect.height - 29
            )
            let skeletonView = WindowSkeletonView(frame: skeletonFrame, isMinimized: item.isMinimized, isFocused: item.isFocused)
            previewContainer.addSubview(skeletonView)

            let hintText = item.isMinimized ? "Click to restore" : "Click to activate"
            let hintLabel = NSTextField(labelWithString: hintText)
            hintLabel.font = NSFont.systemFont(ofSize: 10.0, weight: .medium)
            hintLabel.textColor = NSColor.secondaryLabelColor
            hintLabel.alignment = .center
            hintLabel.frame = NSRect(x: 4, y: 5, width: previewRect.width - 8, height: 14)
            previewContainer.addSubview(hintLabel)
        }

        addSubview(previewContainer)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
    }

    override func mouseDown(with event: NSEvent) {
        onSelect(item)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let bgColor: NSColor
        if isHovered {
            bgColor = NSColor.controlAccentColor.withAlphaComponent(0.24)
        } else if item.isFocused && !item.isMinimized {
            bgColor = NSColor.labelColor.withAlphaComponent(0.09)
        } else {
            bgColor = NSColor.labelColor.withAlphaComponent(0.04)
        }
        bgColor.setFill()
        let path = NSBezierPath(roundedRect: bounds, xRadius: 10, yRadius: 10)
        path.fill()

        if isHovered {
            NSColor.controlAccentColor.withAlphaComponent(0.65).setStroke()
            path.lineWidth = 1.5
            path.stroke()
        }
    }
}

// MARK: - Lightweight Window Skeleton View
final class WindowSkeletonView: NSView {
    private let isMinimized: Bool
    private let isFocused: Bool

    init(frame frameRect: NSRect, isMinimized: Bool, isFocused: Bool) {
        self.isMinimized = isMinimized
        self.isFocused = isFocused
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let alphaScale: CGFloat = isMinimized ? 0.55 : 1.0

        // 1. Miniature window frame
        let winRect = bounds.insetBy(dx: 0.5, dy: 0.5)
        let winPath = NSBezierPath(roundedRect: winRect, xRadius: 5, yRadius: 5)
        NSColor.labelColor.withAlphaComponent(0.04 * alphaScale).setFill()
        winPath.fill()
        NSColor.separatorColor.withAlphaComponent(0.32 * alphaScale).setStroke()
        winPath.lineWidth = 0.8
        winPath.stroke()

        // 2. Top window title bar and traffic light dots
        let headerH: CGFloat = 13
        let headerY = winRect.maxY - headerH
        let divider = NSBezierPath()
        divider.move(to: NSPoint(x: winRect.minX, y: headerY))
        divider.line(to: NSPoint(x: winRect.maxX, y: headerY))
        NSColor.separatorColor.withAlphaComponent(0.25 * alphaScale).setStroke()
        divider.lineWidth = 0.6
        divider.stroke()

        let dotSize: CGFloat = 4.5
        let dotY = headerY + (headerH - dotSize) / 2
        let dotColors: [NSColor] = isMinimized
            ? [
                NSColor.labelColor.withAlphaComponent(0.16),
                NSColor.labelColor.withAlphaComponent(0.16),
                NSColor.labelColor.withAlphaComponent(0.16)
            ]
            : [
                NSColor.systemRed.withAlphaComponent(0.55),
                NSColor.systemYellow.withAlphaComponent(0.55),
                NSColor.systemGreen.withAlphaComponent(0.55)
            ]
        for (i, color) in dotColors.enumerated() {
            let dotX = winRect.minX + 7 + CGFloat(i) * 7.5
            let dotPath = NSBezierPath(ovalIn: NSRect(x: dotX, y: dotY, width: dotSize, height: dotSize))
            color.setFill()
            dotPath.fill()
        }

        // Top toolbar/address capsule skeleton
        let pillW: CGFloat = min(68, winRect.width - 48)
        let pillH: CGFloat = 4.5
        let pillRect = NSRect(x: winRect.minX + 34, y: headerY + (headerH - pillH) / 2, width: pillW, height: pillH)
        NSColor.labelColor.withAlphaComponent(0.11 * alphaScale).setFill()
        NSBezierPath(roundedRect: pillRect, xRadius: 2.25, yRadius: 2.25).fill()

        // 3. Window body: left sidebar skeleton + three content lines on the right
        let bodyTop = headerY - 6
        let bodyBottom = winRect.minY + 6
        let bodyH = max(12, bodyTop - bodyBottom)

        let sidebarW: CGFloat = 34
        let sidebarRect = NSRect(x: winRect.minX + 7, y: bodyBottom, width: sidebarW, height: bodyH)
        NSColor.labelColor.withAlphaComponent(0.09 * alphaScale).setFill()
        NSBezierPath(roundedRect: sidebarRect, xRadius: 3, yRadius: 3).fill()

        let contentX = sidebarRect.maxX + 8
        let maxContentW = max(20, winRect.maxX - contentX - 8)
        let line1H: CGFloat = 6.0
        let line2H: CGFloat = 5.0
        let line3H: CGFloat = 5.0

        // Line 1 (primary title skeleton bar, accented when focused)
        let line1Rect = NSRect(x: contentX, y: bodyTop - line1H - 1, width: maxContentW * 0.62, height: line1H)
        let primaryBarColor = (isFocused && !isMinimized)
            ? NSColor.controlAccentColor.withAlphaComponent(0.32)
            : NSColor.labelColor.withAlphaComponent(0.16 * alphaScale)
        primaryBarColor.setFill()
        NSBezierPath(roundedRect: line1Rect, xRadius: 3, yRadius: 3).fill()

        // Line 2 (long content skeleton bar)
        let line2Rect = NSRect(x: contentX, y: line1Rect.minY - line2H - 4.5, width: maxContentW * 0.92, height: line2H)
        NSColor.labelColor.withAlphaComponent(0.11 * alphaScale).setFill()
        NSBezierPath(roundedRect: line2Rect, xRadius: 2.5, yRadius: 2.5).fill()

        // Line 3 (short content skeleton bar)
        let line3Rect = NSRect(x: contentX, y: line2Rect.minY - line3H - 4.5, width: maxContentW * 0.74, height: line3H)
        NSColor.labelColor.withAlphaComponent(0.09 * alphaScale).setFill()
        NSBezierPath(roundedRect: line3Rect, xRadius: 2.5, yRadius: 2.5).fill()
    }
}

private extension NSColor {
    static var SecondaryLabelColorCompat: NSColor {
        return NSColor.secondaryLabelColor
    }
}

// MARK: - Multi-Window Hover Preview Floating Panel Controller
final class WindowPreviewController {
    static let shared = WindowPreviewController()

    private var panel: NSPanel?
    private(set) var currentPID: pid_t = 0
    private(set) var currentDockItemRect: NSRect = .zero

    var isVisible: Bool {
        return panel?.isVisible == true
    }

    func hide() {
        currentPID = 0
        currentDockItemRect = .zero
        panel?.orderOut(nil)
    }

    func isMouseInsidePanel(appKitPoint: NSPoint) -> Bool {
        guard let panel = panel, panel.isVisible else { return false }
        return panel.frame.insetBy(dx: -12, dy: -12).contains(appKitPoint)
    }

    func isMouseInPreviewOrDockRegion(appKitPoint: NSPoint) -> Bool {
        guard let panel = panel, panel.isVisible else { return false }
        let expandedPanel = panel.frame.insetBy(dx: -18, dy: -18)
        let expandedIcon = currentDockItemRect.insetBy(dx: -18, dy: -18)
        // Allow smooth mouse movement across the corridor between the Dock icon and the preview panel
        let unionCorridor = expandedPanel.union(expandedIcon)
        return expandedPanel.contains(appKitPoint)
            || expandedIcon.contains(appKitPoint)
            || (unionCorridor.contains(appKitPoint) && abs(appKitPoint.x - currentDockItemRect.midX) <= max(expandedPanel.width / 2, 70))
    }

    func showPreview(
        for app: NSRunningApplication,
        items: [WindowPreviewItem],
        dockItemRect: NSRect,
        onSelectWindow: @escaping (WindowPreviewItem) -> Void,
        onCloseWindow: @escaping (WindowPreviewItem) -> Void
    ) {
        guard !items.isEmpty else {
            hide()
            return
        }

        currentPID = app.processIdentifier
        currentDockItemRect = dockItemRect

        let cardWidth: CGFloat = 200
        let cardHeight: CGFloat = 128
        let spacing: CGFloat = 10
        let outerPadding: CGFloat = 12
        let maxColumns = 4

        let count = items.count
        let columns = min(count, maxColumns)
        let rows = Int(ceil(Double(count) / Double(columns)))

        let panelWidth = CGFloat(columns) * cardWidth + CGFloat(max(0, columns - 1)) * spacing + outerPadding * 2
        let panelHeight = CGFloat(rows) * cardHeight + CGFloat(max(0, rows - 1)) * spacing + outerPadding * 2

        let panelFrame = computePanelFrame(
            panelSize: NSSize(width: panelWidth, height: panelHeight),
            dockItemRect: dockItemRect
        )

        let targetPanel: NSPanel
        if let existing = panel {
            targetPanel = existing
        } else {
            let newPanel = NSPanel(
                contentRect: panelFrame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            newPanel.isFloatingPanel = true
            newPanel.level = .statusBar
            newPanel.backgroundColor = .clear
            newPanel.isOpaque = false
            newPanel.hasShadow = true
            newPanel.acceptsMouseMovedEvents = true
            newPanel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
            self.panel = newPanel
            targetPanel = newPanel
        }

        let effectView = NSVisualEffectView(frame: NSRect(origin: .zero, size: panelFrame.size))
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 14
        effectView.layer?.masksToBounds = true
        effectView.layer?.borderWidth = 0.8
        effectView.layer?.borderColor = NSColor.white.withAlphaComponent(0.18).cgColor

        for (index, item) in items.enumerated() {
            let row = index / columns
            let col = index % columns
            let cardX = outerPadding + CGFloat(col) * (cardWidth + spacing)
            // Place the first row at the top
            let cardY = panelFrame.height - outerPadding - CGFloat(row + 1) * cardHeight - CGFloat(row) * spacing
            let cardFrame = NSRect(x: cardX, y: cardY, width: cardWidth, height: cardHeight)

            let cardView = WindowPreviewCardView(
                frame: cardFrame,
                item: item,
                appIcon: app.icon,
                onSelect: { [weak self] selected in
                    self?.hide()
                    onSelectWindow(selected)
                },
                onClose: { toClose in
                    onCloseWindow(toClose)
                }
            )
            effectView.addSubview(cardView)
        }

        targetPanel.contentView = effectView
        targetPanel.setFrame(panelFrame, display: true)
        targetPanel.orderFrontRegardless()
    }

    private func computePanelFrame(panelSize: NSSize, dockItemRect: NSRect) -> NSRect {
        let screen = NSScreen.screens.first(where: { $0.frame.intersects(dockItemRect) })
            ?? NSScreen.main
            ?? NSScreen.screens.first
        let screenFrame = screen?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let margin: CGFloat = 10

        var x = dockItemRect.midX - panelSize.width / 2
        var y = dockItemRect.maxY + 12

        // Determine whether the Dock is positioned on the left, right, or bottom
        let distBottom = abs(dockItemRect.minY - screenFrame.minY)
        let distLeft = abs(dockItemRect.minX - screenFrame.minX)
        let distRight = abs(screenFrame.maxX - dockItemRect.maxX)

        if distLeft < 100 && distLeft < distBottom {
            // Dock on the left
            x = dockItemRect.maxX + 12
            y = dockItemRect.midY - panelSize.height / 2
        } else if distRight < 100 && distRight < distBottom {
            // Dock on the right
            x = dockItemRect.minX - panelSize.width - 12
            y = dockItemRect.midY - panelSize.height / 2
        } else {
            // Dock at the bottom
            x = dockItemRect.midX - panelSize.width / 2
            y = dockItemRect.maxY + 12
        }

        x = max(screenFrame.minX + margin, min(x, screenFrame.maxX - panelSize.width - margin))
        y = max(screenFrame.minY + margin, min(y, screenFrame.maxY - panelSize.height - margin))

        return NSRect(x: round(x), y: round(y), width: panelSize.width, height: panelSize.height)
    }
}

// MARK: - DockMin (Click to Minimize Mac Dock Windows | Open Source)
class DockMinApp: NSObject, NSApplicationDelegate {
    static let shared = DockMinApp()

    // Tag synthetic MouseDown events replayed by DockMin for native drag/long-press to avoid re-intercepting
    private static let syntheticEventTag: Int64 = 0x444F434B // "DOCK"

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var permissionPollTimer: Timer?
    private var longPressTimer: Timer?
    private var hoverDebounceTimer: Timer?
    private var globalMouseMoveMonitor: Any?
    private var localMouseMoveMonitor: Any?
    private var lastHoveredDockTitle: String?
    private var lastActionTime: TimeInterval = 0
    private let debounceInterval: TimeInterval = 0.22

    // Cache the Dock process PID and only perform hit-testing against com.apple.dock
    private var dockPID: pid_t = 0

    // Track current left-mouse-down Dock click context (distinguishing short click from drag/long-press menu)
    private struct PendingDockClick {
        let itemTitle: String
        let dockItem: AXUIElement
        let mouseDownEvent: CGEvent
        let mouseDownLocation: CGPoint
        let mouseDownTime: TimeInterval
    }
    private var pendingClick: PendingDockClick?

    // Remember pre-minimize screen position and thumbnail per CGWindowID (supports multi-display & multi-window)
    private struct SavedWindowInfo {
        let windowID: CGWindowID
        let element: AXUIElement
        let title: String?
        let size: CGSize?
        let position: CGPoint
    }
    private var savedWindowPositions: [pid_t: [SavedWindowInfo]] = [:]
    private var cachedWindowThumbnails: [CGWindowID: NSImage] = [:]
    private let launchTime = Date()
    private var isShowingManagementAlert = false
    private var initialAppBundlePath: String?

    private static let bundleIdentifier = "com.github.fatthreeking.DockMin"
    private static let reopenNotificationName = NSNotification.Name("com.github.fatthreeking.DockMin.reopen")

    func applicationDidFinishLaunching(_ notification: Notification) {
        // If an instance is already running, notify it to show the management/uninstall dialog and exit
        if notifyExistingInstanceIfNeeded() {
            exit(0)
        }

        if Bundle.main.bundleURL.pathExtension == "app" {
            initialAppBundlePath = Bundle.main.bundleURL.path
        }

        // Silent background mode with no menu bar icon and no Dock icon
        NSApp.setActivationPolicy(.accessory)
        updateDockPID()
        setupSignalHandlers()
        ensureLaunchAgentRegistered()
        setupAccessibilityPermissionObserver()
        setupReopenNotificationObserver()
        setupHoverMonitors()

        // Start continuous Accessibility permission monitoring and event tap
        startPermissionCheckLoop()
    }

    // Show management dialog when the user reopens DockMin.app from Applications or Spotlight
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard Date().timeIntervalSince(launchTime) > 1.0 else {
            return false
        }
        DispatchQueue.main.async { [weak self] in
            self?.showManagementDialog()
        }
        return false
    }

    private func notifyExistingInstanceIfNeeded() -> Bool {
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleIdentifier)
            .filter { $0.processIdentifier != currentPID && !$0.isTerminated }
        guard !running.isEmpty else {
            return false
        }
        DistributedNotificationCenter.default().postNotificationName(
            Self.reopenNotificationName,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
        return true
    }

    private func setupReopenNotificationObserver() {
        DistributedNotificationCenter.default().addObserver(
            forName: Self.reopenNotificationName,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.showManagementDialog()
        }
    }

    // MARK: - Management & Uninstall Dialog on Reopen
    func showManagementDialog() {
        WindowPreviewController.shared.hide()
        guard !isShowingManagementAlert else {
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        isShowingManagementAlert = true
        defer { isShowingManagementAlert = false }

        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.icon = NSApp.applicationIconImage
        alert.messageText = "DockMin is Running in the Background"

        let permissionStatus = AXIsProcessTrusted()
            ? "Status: Active (Accessibility permission granted)"
            : "Status: Waiting for Accessibility permission"

        alert.informativeText = """
        \(permissionStatus)

        • Quit DockMin: Stop the background service (you can move the app to Trash in Finder afterwards).
        • Uninstall Completely: Stop the service, remove login item and permission records, and move DockMin to Trash.
        """

        alert.addButton(withTitle: "Quit DockMin")
        let uninstallButton = alert.addButton(withTitle: "Uninstall Completely")
        if #available(macOS 11.0, *) {
            uninstallButton.hasDestructiveAction = true
        }
        let continueButton = alert.addButton(withTitle: "Keep Running")
        continueButton.keyEquivalent = "\u{1b}"

        alert.window.level = .floating
        alert.window.center()

        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            stopEventTap()
            NSApp.terminate(nil)
            exit(0)
        case .alertSecondButtonReturn:
            performFullUninstall(showConfirmation: true)
        default:
            break
        }
    }

    func performFullUninstall(showConfirmation: Bool) {
        permissionPollTimer?.invalidate()
        permissionPollTimer = nil
        hoverDebounceTimer?.invalidate()
        hoverDebounceTimer = nil
        stopEventTap()

        // Terminate any other running DockMin instances when triggered via --uninstall
        let currentPID = ProcessInfo.processInfo.processIdentifier
        for app in NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleIdentifier) where app.processIdentifier != currentPID {
            app.forceTerminate()
        }

        // 1. Remove LaunchAgent configuration and log files
        cleanupLaunchAgentAndLogs()

        // 2. Move application bundle to Trash (covering current bundle path, /Applications, and ~/Applications)
        let fileManager = FileManager.default
        var candidateURLs: [URL] = []
        if Bundle.main.bundleURL.pathExtension == "app" {
            candidateURLs.append(Bundle.main.bundleURL.standardizedFileURL)
        }
        candidateURLs.append(URL(fileURLWithPath: "/Applications/DockMin.app").standardizedFileURL)
        candidateURLs.append(
            fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications/DockMin.app")
                .standardizedFileURL
        )

        var seenPaths = Set<String>()
        for appURL in candidateURLs {
            let path = appURL.path
            guard !seenPaths.contains(path), fileManager.fileExists(atPath: path) else { continue }
            seenPaths.insert(path)
            do {
                try fileManager.trashItem(at: appURL, resultingItemURL: nil)
            } catch {
                try? fileManager.removeItem(at: appURL)
            }
        }

        // 3. Reset macOS Accessibility (TCC) permission record
        let tccProcess = Process()
        tccProcess.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        tccProcess.arguments = ["reset", "Accessibility", Self.bundleIdentifier]
        try? tccProcess.run()
        tccProcess.waitUntilExit()

        if showConfirmation {
            let doneAlert = NSAlert()
            doneAlert.alertStyle = .informational
            doneAlert.icon = NSApp.applicationIconImage
            doneAlert.messageText = "DockMin Uninstalled"
            doneAlert.informativeText = "The application has been moved to Trash, and all login items and Accessibility permission records have been removed."
            doneAlert.addButton(withTitle: "OK")
            doneAlert.window.level = .floating
            doneAlert.window.center()
            NSApp.activate(ignoringOtherApps: true)
            doneAlert.runModal()
        }

        // 4. Asynchronously remove launchctl job and exit
        let cleanupTask = Process()
        cleanupTask.executableURL = URL(fileURLWithPath: "/bin/sh")
        cleanupTask.arguments = ["-c", "sleep 0.2; launchctl remove \(Self.bundleIdentifier) >/dev/null 2>&1 || true"]
        try? cleanupTask.run()

        exit(0)
    }

    private func cleanupLaunchAgentAndLogs() {
        let fileManager = FileManager.default
        let plistURL = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(Self.bundleIdentifier).plist")
        try? fileManager.removeItem(at: plistURL)
        try? fileManager.removeItem(atPath: "/tmp/dockmin.log")
        try? fileManager.removeItem(atPath: "/tmp/dockmin.err")
    }

    // Automatically register LaunchAgent on startup so DMG and Homebrew installs auto-start on login
    private func ensureLaunchAgentRegistered() {
        guard let execPath = Bundle.main.executablePath,
              execPath.contains(".app/Contents/MacOS/") else {
            return
        }

        let fileManager = FileManager.default
        let launchAgentsDir = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
        let plistURL = launchAgentsDir.appendingPathComponent("com.github.fatthreeking.DockMin.plist")

        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.github.fatthreeking.DockMin</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(execPath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <false/>
            <key>StandardErrorPath</key>
            <string>/tmp/dockmin.err</string>
            <key>StandardOutPath</key>
            <string>/tmp/dockmin.log</string>
        </dict>
        </plist>
        """

        do {
            try fileManager.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true)
            let existing = try? String(contentsOf: plistURL, encoding: .utf8)
            if existing != plistContent {
                try plistContent.write(to: plistURL, atomically: true, encoding: .utf8)
            }
        } catch {
            NSLog("[DockMin] Failed to write LaunchAgent configuration: \(error.localizedDescription)")
        }
    }

    private func updateDockPID() {
        if let dockApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first {
            dockPID = dockApp.processIdentifier
        }
    }

    private func setupSignalHandlers() {
        signal(SIGINT) { _ in exit(0) }
        signal(SIGTERM) { _ in exit(0) }
    }

    // Observe system Accessibility permission changes and immediately tear down EventTap if revoked
    private func setupAccessibilityPermissionObserver() {
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.accessibility.api"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self?.syncPermissionState()
            }
        }
    }

    // MARK: - Passive Hover Preview Monitor
    private func setupHoverMonitors() {
        globalMouseMoveMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            self?.handleMouseMovedForHoverPreview()
        }
        localMouseMoveMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMovedForHoverPreview()
            return event
        }
    }

    private func handleMouseMovedForHoverPreview() {
        guard AXIsProcessTrusted() else {
            WindowPreviewController.shared.hide()
            return
        }

        let appKitMouseLoc = NSEvent.mouseLocation

        // Keep the preview panel open while the cursor moves inside it
        if WindowPreviewController.shared.isMouseInsidePanel(appKitPoint: appKitMouseLoc) {
            hoverDebounceTimer?.invalidate()
            return
        }

        // Re-evaluate hover state when the cursor leaves the panel or Dock icon corridor
        hoverDebounceTimer?.invalidate()
        hoverDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.14, repeats: false) { [weak self] _ in
            self?.evaluateHoverAtCurrentMouseLocation()
        }
    }

    private func evaluateHoverAtCurrentMouseLocation() {
        guard AXIsProcessTrusted(), pendingClick == nil else { return }

        let appKitMouseLoc = NSEvent.mouseLocation
        if WindowPreviewController.shared.isMouseInsidePanel(appKitPoint: appKitMouseLoc) {
            return
        }

        let cgPoint = appKitToCGPoint(appKitMouseLoc)
        if dockPID == 0 { updateDockPID() }
        guard dockPID != 0 else { return }

        let dockElement = AXUIElementCreateApplication(dockPID)
        AXUIElementSetMessagingTimeout(dockElement, 0.08)

        var axElement: AXUIElement?
        let err = AXUIElementCopyElementAtPosition(dockElement, Float(cgPoint.x), Float(cgPoint.y), &axElement)
        guard err == .success,
              let element = axElement,
              let (itemTitle, dockItem) = extractDockAppItem(from: element),
              let targetApp = findRunningApp(forDockTitle: itemTitle) else {
            if !WindowPreviewController.shared.isMouseInPreviewOrDockRegion(appKitPoint: appKitMouseLoc) {
                lastHoveredDockTitle = nil
                WindowPreviewController.shared.hide()
            }
            return
        }

        let dockRect = getDockItemAppKitRect(dockItem: dockItem, fallbackAppKitPoint: appKitMouseLoc)
        if WindowPreviewController.shared.isVisible && lastHoveredDockTitle == itemTitle {
            return
        }

        let items = collectPreviewItems(for: targetApp)
        // Show hover preview only when the app has 2 or more windows (visible or minimized)
        guard items.count >= 2 else {
            lastHoveredDockTitle = nil
            WindowPreviewController.shared.hide()
            return
        }

        lastHoveredDockTitle = itemTitle
        WindowPreviewController.shared.showPreview(
            for: targetApp,
            items: items,
            dockItemRect: dockRect,
            onSelectWindow: { [weak self] selectedItem in
                self?.lastHoveredDockTitle = nil
                self?.activateSingleWindow(app: targetApp, item: selectedItem)
            },
            onCloseWindow: { [weak self] itemToClose in
                self?.handleCloseWindow(app: targetApp, item: itemToClose, dockRect: dockRect)
            }
        )
    }

    private func appKitToCGPoint(_ point: NSPoint) -> CGPoint {
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080
        return CGPoint(x: point.x, y: primaryHeight - point.y)
    }

    private func getDockItemAppKitRect(dockItem: AXUIElement, fallbackAppKitPoint: NSPoint) -> NSRect {
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080
        if let pos = getWindowPosition(window: dockItem),
           let size = getWindowSize(window: dockItem),
           size.width > 10, size.height > 10 {
            let appKitY = primaryHeight - pos.y - size.height
            return NSRect(x: pos.x, y: appKitY, width: size.width, height: size.height)
        }
        return NSRect(x: fallbackAppKitPoint.x - 28, y: fallbackAppKitPoint.y - 28, width: 56, height: 56)
    }

    // Collect all standard windows of the target app (both visible and minimized) for the hover preview
    private func collectPreviewItems(for app: NSRunningApplication) -> [WindowPreviewItem] {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(appElement, 0.35)

        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windows = windowsRef as? [AXUIElement] else {
            return []
        }

        var focusedWin: AXUIElement?
        var focusedRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedRef) == .success,
           let f = focusedRef {
            focusedWin = (f as! AXUIElement)
        }

        let standardWindows = windows.filter { isMinimizableStandardWindow($0) }
        guard standardWindows.count >= 2 else { return [] }

        var items: [WindowPreviewItem] = []
        for (idx, win) in standardWindows.enumerated() {
            var isMinRef: CFTypeRef?
            let isMin = (AXUIElementCopyAttributeValue(win, kAXMinimizedAttribute as CFString, &isMinRef) == .success) && ((isMinRef as? Bool) == true)
            let wid = getWindowID(window: win, pid: app.processIdentifier)
            let rawTitle = getWindowTitle(window: win) ?? "\(app.localizedName ?? "Window") #\(idx + 1)"
            let isFocused = !isMin && app.isActive && (focusedWin != nil && CFEqual(focusedWin!, win))

            var thumb: NSImage?
            if !isMin, wid != 0, let liveThumb = captureWindowThumbnailIfPermitted(windowID: wid) {
                cachedWindowThumbnails[wid] = liveThumb
                thumb = liveThumb
            } else if wid != 0 {
                thumb = cachedWindowThumbnails[wid]
            }

            items.append(WindowPreviewItem(
                windowID: wid,
                element: win,
                title: rawTitle,
                isMinimized: isMin,
                isFocused: isFocused,
                thumbnail: thumb
            ))
        }
        return items
    }

    // Capture live window thumbnail only if Screen Recording permission is already granted (never prompt the user)
    private func captureWindowThumbnailIfPermitted(windowID: CGWindowID) -> NSImage? {
        guard windowID != 0, CGPreflightScreenCaptureAccess() else { return nil }
        guard let cgImage = _DockMinCaptureWindowImage(
            .null,
            .optionIncludingWindow,
            windowID,
            [.boundsIgnoreFraming, .bestResolution]
        ), cgImage.width > 20, cgImage.height > 20 else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    // MARK: - Close Specific Window from Preview Card
    func handleCloseWindow(app: NSRunningApplication, item: WindowPreviewItem, dockRect: NSRect) {
        closeSingleWindow(item: item)

        // Allow brief time for WindowServer and the app to close the window before refreshing the preview
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self = self else { return }
            let remainingItems = self.collectPreviewItems(for: app)
            if remainingItems.count >= 2 {
                // Refresh preview cards in place if 2 or more windows remain
                WindowPreviewController.shared.showPreview(
                    for: app,
                    items: remainingItems,
                    dockItemRect: dockRect,
                    onSelectWindow: { [weak self] selected in
                        self?.lastHoveredDockTitle = nil
                        self?.activateSingleWindow(app: app, item: selected)
                    },
                    onCloseWindow: { [weak self] toClose in
                        self?.handleCloseWindow(app: app, item: toClose, dockRect: dockRect)
                    }
                )
            } else {
                // Hide the preview panel when fewer than 2 windows remain
                self.lastHoveredDockTitle = nil
                WindowPreviewController.shared.hide()
            }
        }
    }

    func closeSingleWindow(item: WindowPreviewItem) {
        let win = item.element
        var closeButtonRef: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(win, kAXCloseButtonAttribute as CFString, &closeButtonRef)
        if err == .success, let closeButton = closeButtonRef {
            let pressErr = AXUIElementPerformAction(closeButton as! AXUIElement, kAXPressAction as CFString)
            if pressErr != .success {
                AXUIElementPerformAction(win, "AXCancel" as CFString)
            }
        } else {
            AXUIElementPerformAction(win, "AXCancel" as CFString)
        }
    }

    // Restore and bring only the selected window to the front when clicked in the preview panel
    func activateSingleWindow(app: NSRunningApplication, item: WindowPreviewItem) {
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(appElement, 0.50)

        if app.isHidden {
            app.unhide()
        }

        let win = item.element
        var isMinRef: CFTypeRef?
        let isMin = (AXUIElementCopyAttributeValue(win, kAXMinimizedAttribute as CFString, &isMinRef) == .success) && ((isMinRef as? Bool) == true)

        if isMin {
            let targetPos = consumeSavedWindowPosition(pid: pid, window: win)
            AXUIElementSetAttributeValue(win, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
            if let pos = targetPos {
                ensureWindowPosition(window: win, targetPos: pos)
                for delay in [0.08, 0.20, 0.35] {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                        self?.ensureWindowPosition(window: win, targetPos: pos)
                    }
                }
            }
        }

        focusSingleWindowOnly(pid: pid, windowID: item.windowID, window: win)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) { [weak self] in
            self?.focusSingleWindowOnly(pid: pid, windowID: item.windowID, window: win)
        }
    }

    // Bring only the target window to front focus without raising all other windows of the same app
    private func focusSingleWindowOnly(pid: pid_t, windowID: CGWindowID, window: AXUIElement) {
        AXUIElementSetAttributeValue(window, kAXMainAttribute as CFString, kCFBooleanTrue)
        AXUIElementSetAttributeValue(window, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        AXUIElementPerformAction(window, kAXRaiseAction as CFString)

        var psn = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: 0)
        if _DockMinGetProcessForPID(pid, &psn) == noErr {
            let wid = windowID != 0 ? windowID : getWindowID(window: window, pid: pid)
            if wid != 0, let slpsSetFront = _DockMinSLPSSetFrontProcessWithOptions {
                _ = slpsSetFront(&psn, wid, 0x200)
            }
            // kSetFrontProcessFrontWindowOnly = 1 brings only the key window forward
            _ = _DockMinSetFrontProcessWithOptions(&psn, 1)
        }

        AXUIElementPerformAction(window, kAXRaiseAction as CFString)
    }

    // MARK: - Permission Monitoring & Dynamic EventTap Control
    private func startPermissionCheckLoop() {
        let promptOption: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(promptOption)

        if trusted {
            startEventTap()
        } else {
            NSLog("[DockMin] Waiting for Accessibility permission...")
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }

        // Continuously poll permission status in case the user toggles Accessibility in System Settings
        permissionPollTimer?.invalidate()
        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.syncPermissionState()
        }
    }

    private func syncPermissionState() {
        // If the original .app bundle was removed externally, clean up LaunchAgent and exit
        if let bundlePath = initialAppBundlePath, !FileManager.default.fileExists(atPath: bundlePath) {
            NSLog("[DockMin] Application bundle removed; cleaning up LaunchAgent and exiting...")
            cleanupLaunchAgentAndLogs()
            stopEventTap()
            exit(0)
        }

        if AXIsProcessTrusted() {
            if eventTap == nil {
                NSLog("[DockMin] Accessibility permission granted; starting event tap...")
                startEventTap()
            }
        } else {
            if eventTap != nil {
                NSLog("[DockMin] Accessibility permission revoked; stopping event tap...")
                stopEventTap()
            }
        }
    }

    // MARK: - CGEventTap Management
    func reEnableTap() {
        cancelPendingClick()
        guard AXIsProcessTrusted(), let tap = eventTap else {
            stopEventTap()
            return
        }
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stopEventTap() {
        cancelPendingClick()
        WindowPreviewController.shared.hide()
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
            eventTap = nil
        }
    }

    private func cancelPendingClick() {
        longPressTimer?.invalidate()
        longPressTimer = nil
        pendingClick = nil
    }

    // Replay the pending MouseDown event to the Dock when the user drags an icon or long-presses for the menu
    private func replayPendingMouseDownToDock() {
        guard let pending = pendingClick else { return }
        cancelPendingClick()
        if let copy = pending.mouseDownEvent.copy() {
            copy.setIntegerValueField(.eventSourceUserData, value: Self.syntheticEventTag)
            copy.post(tap: .cghidEventTap)
        }
    }

    private func startEventTap() {
        guard eventTap == nil, AXIsProcessTrusted() else { return }
        updateDockPID()

        let eventMask = (1 << CGEventType.leftMouseDown.rawValue)
                      | (1 << CGEventType.leftMouseUp.rawValue)
                      | (1 << CGEventType.leftMouseDragged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: dockEventCallback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            NSLog("[DockMin] Failed to create CGEventTap; waiting for permission...")
            return
        }

        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        NSLog("[DockMin] Service started in background mode.")
    }

    // MARK: - Core Click Event Handling
    func handleEvent(type: CGEventType, event: CGEvent) -> Bool {
        // 1. Immediately disable EventTap and pass through all mouse events if permission is revoked
        guard AXIsProcessTrusted() else {
            stopEventTap()
            return false
        }

        // 2. Pass through synthetic drag/long-press events replayed by DockMin
        if event.getIntegerValueField(.eventSourceUserData) == Self.syntheticEventTag {
            return false
        }

        switch type {
        case .leftMouseDragged:
            // Replay MouseDown to the Dock if the user drags the icon (>= 3.5pt)
            if let pending = pendingClick {
                let loc = event.location
                let dist = hypot(loc.x - pending.mouseDownLocation.x, loc.y - pending.mouseDownLocation.y)
                if dist >= 3.5 {
                    replayPendingMouseDownToDock()
                }
            }
            return false

        case .leftMouseUp:
            // A pending click that did not turn into a drag or long-press is a clean single click
            guard let pending = pendingClick else {
                return false
            }
            cancelPendingClick()

            let now = Date().timeIntervalSince1970
            let location = event.location
            let dist = hypot(location.x - pending.mouseDownLocation.x, location.y - pending.mouseDownLocation.y)

            guard dist < 5.0, (now - lastActionTime) > debounceInterval else {
                return true
            }
            lastActionTime = now

            // Perform window query and minimize/restore asynchronously outside the EventTap callback
            let clickedTitle = pending.itemTitle
            let clickedDockItem = pending.dockItem
            DispatchQueue.main.async { [weak self] in
                self?.lastHoveredDockTitle = nil
                WindowPreviewController.shared.hide()
                self?.toggleApplication(forDockTitle: clickedTitle, dockItem: clickedDockItem)
            }
            return true // Swallow MouseUp to prevent native Dock behavior from pulling secondary display windows to the main screen

        case .leftMouseDown:
            cancelPendingClick()

            // Pass through clicks inside the hover preview panel so card views can handle them
            let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080
            let appKitLoc = NSPoint(x: event.location.x, y: primaryHeight - event.location.y)
            if WindowPreviewController.shared.isMouseInsidePanel(appKitPoint: appKitLoc) {
                return false
            }

            // Hide hover preview when clicking elsewhere
            if WindowPreviewController.shared.isVisible {
                DispatchQueue.main.async {
                    WindowPreviewController.shared.hide()
                }
            }

            // Pass through clicks with modifier keys (Cmd/Ctrl/Option/Shift) for native Dock behavior
            let modifiers = event.flags.intersection([.maskCommand, .maskControl, .maskAlternate, .maskShift])
            guard modifiers.isEmpty else { return false }

            if dockPID == 0 { updateDockPID() }
            guard dockPID != 0 else { return false }

            // Hit-test only against com.apple.dock with an 80ms timeout
            let location = event.location
            let dockElement = AXUIElementCreateApplication(dockPID)
            AXUIElementSetMessagingTimeout(dockElement, 0.08)

            var axElement: AXUIElement?
            let err = AXUIElementCopyElementAtPosition(dockElement, Float(location.x), Float(location.y), &axElement)
            guard err == .success, let element = axElement else { return false }

            // Extract clicked Dock app title and AXDockItem reference (filtering out Trash, folders, and minimized window tiles)
            guard let (itemTitle, dockItem) = extractDockAppItem(from: element) else { return false }

            // Only intercept running applications; let native Dock launch non-running apps
            guard findRunningApp(forDockTitle: itemTitle) != nil,
                  let savedEvent = event.copy() else {
                return false
            }

            let now = Date().timeIntervalSince1970
            pendingClick = PendingDockClick(
                itemTitle: itemTitle,
                dockItem: dockItem,
                mouseDownEvent: savedEvent,
                mouseDownLocation: location,
                mouseDownTime: now
            )

            // Replay MouseDown to the Dock if held longer than 0.25s (long-press menu or drag)
            longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
                self?.replayPendingMouseDownToDock()
            }

            return true // Hold MouseDown briefly to distinguish short click from drag/long-press

        default:
            return false
        }
    }

    // MARK: - Toggle Application State (Async on Main Thread, Multi-Window & Multi-Display)
    private func toggleApplication(forDockTitle itemTitle: String, dockItem: AXUIElement? = nil) {
        guard let targetApp = findRunningApp(forDockTitle: itemTitle) else { return }

        let appElement = AXUIElementCreateApplication(targetApp.processIdentifier)
        // Set a 0.5s IPC timeout on the target app to handle apps with many open windows
        AXUIElementSetMessagingTimeout(appElement, 0.50)

        let isFrontmost = isAppFrontmost(app: targetApp, appElement: appElement)
        let isGemini = (targetApp.bundleIdentifier == "com.google.GeminiMacOS" || (targetApp.localizedName ?? "") == "Gemini")
        let hasVisible = isGemini
            ? (!targetApp.isHidden && hasOnScreenWindow(pid: targetApp.processIdentifier))
            : checkHasVisibleWindow(appElement: appElement)
        let isCurrentlyVisible = !targetApp.isHidden && isFrontmost && hasVisible

        if isCurrentlyVisible {
            minimizeApplication(appElement: appElement, app: targetApp)
        } else {
            restoreApplication(appElement: appElement, app: targetApp, dockItem: dockItem)
        }
    }

    private func isAppFrontmost(app: NSRunningApplication, appElement: AXUIElement) -> Bool {
        if app.isActive { return true }
        if NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier {
            return true
        }
        var frontRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXFrontmostAttribute as CFString, &frontRef) == .success,
           let isFront = frontRef as? Bool, isFront {
            return true
        }
        return false
    }

    private func extractDockAppItem(from element: AXUIElement) -> (String, AXUIElement)? {
        var current: AXUIElement? = element
        var dockItemElement: AXUIElement?

        for _ in 0..<5 {
            guard let el = current else { break }
            AXUIElementSetMessagingTimeout(el, 0.08)

            var roleRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(el, kAXRoleAttribute as CFString, &roleRef) == .success,
               let role = roleRef as? String, role == "AXDockItem" {
                dockItemElement = el
            }

            // Check Subrole to exclude minimized window tiles, folder stacks, Trash, and separators
            var subroleRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(el, kAXSubroleAttribute as CFString, &subroleRef) == .success,
               let subrole = subroleRef as? String {
                if subrole == "AXMinimizedWindowDockItem" ||
                   subrole == "AXTrashDockItem" ||
                   subrole == "AXFolderDockItem" ||
                   subrole == "AXURLDockItem" ||
                   subrole == "AXSeparatorDockItem" {
                    return nil
                }
                if subrole == "AXApplicationDockItem" {
                    dockItemElement = el
                }
            }

            if let validDockItem = dockItemElement {
                var titleRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(el, kAXTitleAttribute as CFString, &titleRef) == .success,
                   let title = titleRef as? String {
                    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty { return (trimmed, validDockItem) }
                }

                var descRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(el, kAXDescriptionAttribute as CFString, &descRef) == .success,
                   let desc = descRef as? String {
                    let trimmed = desc.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty { return (trimmed, validDockItem) }
                }
            }

            var parentRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(el, kAXParentAttribute as CFString, &parentRef) == .success,
               let parent = parentRef {
                current = (parent as! AXUIElement)
            } else {
                break
            }
        }
        return nil
    }

    private func findRunningApp(forDockTitle title: String) -> NSRunningApplication? {
        let runningApps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }

        // 1. Exact name match
        for app in runningApps {
            if let name = app.localizedName, name.caseInsensitiveCompare(title) == .orderedSame {
                return app
            }
            if let appFileName = app.bundleURL?.deletingPathExtension().lastPathComponent,
               appFileName.caseInsensitiveCompare(title) == .orderedSame {
                return app
            }
            if let execName = app.executableURL?.lastPathComponent,
               execName.caseInsensitiveCompare(title) == .orderedSame {
                return app
            }
            if let bid = app.bundleIdentifier {
                if bid.caseInsensitiveCompare(title) == .orderedSame {
                    return app
                }
                if let lastComponent = bid.components(separatedBy: ".").last,
                   lastComponent.caseInsensitiveCompare(title) == .orderedSame {
                    return app
                }
            }
        }

        // 2. Substring match
        for app in runningApps {
            if let name = app.localizedName,
               (name.localizedCaseInsensitiveContains(title) || title.localizedCaseInsensitiveContains(name)) {
                return app
            }
            if let appFileName = app.bundleURL?.deletingPathExtension().lastPathComponent,
               (appFileName.localizedCaseInsensitiveContains(title) || title.localizedCaseInsensitiveContains(appFileName)) {
                return app
            }
            if let bid = app.bundleIdentifier,
               (bid.localizedCaseInsensitiveContains(title) || title.localizedCaseInsensitiveContains(bid)) {
                return app
            }
        }

        return nil
    }

    private func isStandardWindow(_ window: AXUIElement) -> Bool {
        var roleRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(window, kAXRoleAttribute as CFString, &roleRef) == .success,
           let role = roleRef as? String, role != (kAXWindowRole as String) {
            return false
        }
        var subroleRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(window, kAXSubroleAttribute as CFString, &subroleRef) == .success,
           let subrole = subroleRef as? String {
            if subrole == "AXDesktop" || subrole == "AXSystemDialog" || subrole == "AXUnknown" {
                return false
            }
        }
        return true
    }

    private func isMinimizableStandardWindow(_ window: AXUIElement) -> Bool {
        guard isStandardWindow(window) else { return false }
        var settable = DarwinBoolean(false)
        if AXUIElementIsAttributeSettable(window, kAXMinimizedAttribute as CFString, &settable) == .success {
            return settable.boolValue
        }
        return true
    }

    private func hasOnScreenWindow(pid: pid_t) -> Bool {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        for info in infoList {
            guard let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t, ownerPID == pid else { continue }
            let layer = info[kCGWindowLayer as String] as? Int ?? -1
            let alpha = info[kCGWindowAlpha as String] as? Double ?? 1.0
            guard layer == 0, alpha > 0.01 else { continue }
            if let bounds = info[kCGWindowBounds as String] as? [String: Any],
               let width = bounds["Width"] as? Double,
               let height = bounds["Height"] as? Double,
               width >= 80, height >= 80 {
                return true
            }
        }
        return false
    }

    private func checkHasVisibleWindow(appElement: AXUIElement) -> Bool {
        var windowsRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
           let windows = windowsRef as? [AXUIElement] {
            for win in windows {
                var isMinRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(win, kAXMinimizedAttribute as CFString, &isMinRef) == .success,
                   let isMin = isMinRef as? Bool, !isMin,
                   isMinimizableStandardWindow(win) {
                    return true
                }
            }
        }
        var focusedWindowRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindowRef) == .success,
           let focusedWin = focusedWindowRef {
            let axWin = focusedWin as! AXUIElement
            var isMinRef: CFTypeRef?
            let isMin = (AXUIElementCopyAttributeValue(axWin, kAXMinimizedAttribute as CFString, &isMinRef) == .success) && ((isMinRef as? Bool) == true)
            if !isMin && isMinimizableStandardWindow(axWin) {
                return true
            }
        }
        return false
    }

    private func getWindowID(window: AXUIElement, pid: pid_t = 0) -> CGWindowID {
        var wid: CGWindowID = 0
        if _AXUIElementGetWindow(window, &wid) == .success, wid != 0 {
            return wid
        }
        guard pid != 0,
              let windowList = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return 0
        }
        let axPos = getWindowPosition(window: window)
        let axSize = getWindowSize(window: window)
        let axTitle = getWindowTitle(window: window)

        for info in windowList {
            guard let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t, ownerPID == pid,
                  let layer = info[kCGWindowLayer as String] as? Int, layer == 0,
                  let number = info[kCGWindowNumber as String] as? UInt32, number != 0 else {
                continue
            }
            if let boundsDict = info[kCGWindowBounds as String] as? NSDictionary,
               let rect = CGRect(dictionaryRepresentation: boundsDict),
               let pos = axPos, let size = axSize {
                if abs(rect.origin.x - pos.x) <= 8 && abs(rect.origin.y - pos.y) <= 8 &&
                   abs(rect.size.width - size.width) <= 8 && abs(rect.size.height - size.height) <= 8 {
                    return CGWindowID(number)
                }
            }
            if let title = axTitle, !title.isEmpty,
               let cgTitle = info[kCGWindowName as String] as? String, cgTitle == title {
                return CGWindowID(number)
            }
        }
        return 0
    }

    private func getWindowPosition(window: AXUIElement) -> CGPoint? {
        var posRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef) == .success,
           let val = posRef {
            var point = CGPoint.zero
            if AXValueGetValue(val as! AXValue, .cgPoint, &point) {
                return point
            }
        }
        return nil
    }

    private func getWindowSize(window: AXUIElement) -> CGSize? {
        var sizeRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success,
           let val = sizeRef {
            var size = CGSize.zero
            if AXValueGetValue(val as! AXValue, .cgSize, &size) {
                return size
            }
        }
        return nil
    }

    private func getWindowTitle(window: AXUIElement) -> String? {
        var titleRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef) == .success,
           let title = titleRef as? String, !title.isEmpty {
            return title
        }
        return nil
    }

    private func setWindowPosition(window: AXUIElement, point: CGPoint) {
        var pt = point
        if let val = AXValueCreate(.cgPoint, &pt) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, val)
        }
    }

    private func saveWindowPosition(pid: pid_t, window: AXUIElement) {
        let wid = getWindowID(window: window)
        // Cache live window snapshot before minimizing (if Screen Recording is permitted)
        if wid != 0, let thumb = captureWindowThumbnailIfPermitted(windowID: wid) {
            cachedWindowThumbnails[wid] = thumb
        }
        guard let pos = getWindowPosition(window: window) else { return }
        let title = getWindowTitle(window: window)
        let size = getWindowSize(window: window)
        var list = savedWindowPositions[pid] ?? []
        list.removeAll { (wid != 0 && $0.windowID == wid) || CFEqual($0.element, window) }
        list.append(SavedWindowInfo(windowID: wid, element: window, title: title, size: size, position: pos))
        savedWindowPositions[pid] = list
    }

    private func consumeSavedWindowPosition(pid: pid_t, window: AXUIElement) -> CGPoint? {
        guard var list = savedWindowPositions[pid], !list.isEmpty else { return nil }
        let wid = getWindowID(window: window)

        // 1. Exact match by unique CGWindowID
        if wid != 0, let idx = list.firstIndex(where: { $0.windowID == wid }) {
            let pos = list.remove(at: idx).position
            savedWindowPositions[pid] = list
            return pos
        }

        // 2. Match by AXUIElement reference
        if let idx = list.firstIndex(where: { CFEqual($0.element, window) }) {
            let pos = list.remove(at: idx).position
            savedWindowPositions[pid] = list
            return pos
        }

        let currentTitle = getWindowTitle(window: window)
        let currentSize = getWindowSize(window: window)

        // 3. Match by window title + size
        if let title = currentTitle, let size = currentSize,
           let idx = list.firstIndex(where: { $0.title == title && $0.size == size }) {
            let pos = list.remove(at: idx).position
            savedWindowPositions[pid] = list
            return pos
        }

        // 4. Match by window title
        if let title = currentTitle,
           let idx = list.firstIndex(where: { $0.title == title }) {
            let pos = list.remove(at: idx).position
            savedWindowPositions[pid] = list
            return pos
        }

        // 5. Fallback sequential match so saved screen position is never lost
        let pos = list.removeFirst().position
        savedWindowPositions[pid] = list
        return pos
    }

    private func ensureWindowPosition(window: AXUIElement, targetPos: CGPoint) {
        var isMinRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &isMinRef) == .success,
           let isMin = isMinRef as? Bool, isMin {
            return
        }
        if let currentPos = getWindowPosition(window: window),
           (abs(currentPos.x - targetPos.x) > 20 || abs(currentPos.y - targetPos.y) > 20) {
            setWindowPosition(window: window, point: targetPos)
        }
    }

    private func minimizeApplication(appElement: AXUIElement, app: NSRunningApplication) {
        if app.bundleIdentifier == "com.google.GeminiMacOS" || (app.localizedName ?? "") == "Gemini" {
            app.hide()
            return
        }

        // Collect all visible windows across all displays, save their positions first, then minimize all of them
        var visibleWindows: [AXUIElement] = []

        var windowsRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
           let windows = windowsRef as? [AXUIElement] {
            for win in windows {
                var isMinRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(win, kAXMinimizedAttribute as CFString, &isMinRef) == .success,
                   let isMin = isMinRef as? Bool, !isMin,
                   isMinimizableStandardWindow(win) {
                    visibleWindows.append(win)
                }
            }
        }

        // Check kAXFocusedWindowAttribute as a fallback if kAXWindowsAttribute returned no visible windows
        if visibleWindows.isEmpty {
            var focusedWindowRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindowRef) == .success,
               let focusedWin = focusedWindowRef {
                let axWin = focusedWin as! AXUIElement
                var isMinRef: CFTypeRef?
                let isMin = (AXUIElementCopyAttributeValue(axWin, kAXMinimizedAttribute as CFString, &isMinRef) == .success) && ((isMinRef as? Bool) == true)
                if !isMin && isMinimizableStandardWindow(axWin) {
                    visibleWindows.append(axWin)
                }
            }
        }

        if !visibleWindows.isEmpty {
            // Step 1: Save screen positions of all visible windows before any minimize animation starts
            for win in visibleWindows {
                saveWindowPosition(pid: app.processIdentifier, window: win)
            }

            // Step 2: Minimize all visible windows of the application
            var minimizedAny = false
            for win in visibleWindows {
                if AXUIElementSetAttributeValue(win, kAXMinimizedAttribute as CFString, kCFBooleanTrue) == .success {
                    minimizedAny = true
                }
            }
            if minimizedAny {
                return
            }
        }

        app.hide()
    }

    private func activateTargetApp(appElement: AXUIElement, app: NSRunningApplication) {
        if app.isHidden {
            app.unhide()
        }
        // Use both AppKit activate and Accessibility kAXFrontmostAttribute for reliable activation across displays
        app.activate()
        AXUIElementSetAttributeValue(appElement, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
    }

    // Trigger native Dock reopen action to create a new default window when a running app has no open or minimized windows
    private func reopenApplication(app: NSRunningApplication, appElement: AXUIElement, dockItem: AXUIElement?) {
        if let dockItem = dockItem {
            AXUIElementSetMessagingTimeout(dockItem, 0.25)
            if AXUIElementPerformAction(dockItem, kAXPressAction as CFString) == .success {
                return
            }
        }
        if let bundleURL = app.bundleURL {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: bundleURL, configuration: config, completionHandler: nil)
        } else {
            activateTargetApp(appElement: appElement, app: app)
        }
    }

    private func restoreApplication(appElement: AXUIElement, app: NSRunningApplication, dockItem: AXUIElement? = nil) {
        let wasHidden = app.isHidden
        let isGemini = (app.bundleIdentifier == "com.google.GeminiMacOS" || (app.localizedName ?? "") == "Gemini")

        if isGemini {
            if wasHidden || hasOnScreenWindow(pid: app.processIdentifier) {
                activateTargetApp(appElement: appElement, app: app)
                return
            }
            reopenApplication(app: app, appElement: appElement, dockItem: dockItem)
            return
        }

        var standardWindows: [AXUIElement] = []
        var windowsRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
           let windows = windowsRef as? [AXUIElement] {
            standardWindows = windows.filter { isMinimizableStandardWindow($0) }
        }

        if standardWindows.isEmpty {
            var focusedWindowRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindowRef) == .success,
               let focusedWin = focusedWindowRef {
                let axWin = focusedWin as! AXUIElement
                if isMinimizableStandardWindow(axWin) {
                    standardWindows.append(axWin)
                }
            }
        }

        // Reopen the application to create a default window if it is not hidden and has no windows
        if standardWindows.isEmpty && !wasHidden && !hasOnScreenWindow(pid: app.processIdentifier) {
            reopenApplication(app: app, appElement: appElement, dockItem: dockItem)
            return
        }

        activateTargetApp(appElement: appElement, app: app)

        if !standardWindows.isEmpty {
            // Restore windows in reverse order so the previously frontmost window is raised last, preserving z-order
            for win in standardWindows.reversed() {
                var isMinRef: CFTypeRef?
                let isMin = (AXUIElementCopyAttributeValue(win, kAXMinimizedAttribute as CFString, &isMinRef) == .success) && ((isMinRef as? Bool) == true)
                if isMin {
                    let targetPos = consumeSavedWindowPosition(pid: app.processIdentifier, window: win)
                    AXUIElementSetAttributeValue(win, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
                    AXUIElementPerformAction(win, kAXRaiseAction as CFString)
                    AXUIElementSetAttributeValue(win, kAXMainAttribute as CFString, kCFBooleanTrue)

                    if let pos = targetPos {
                        ensureWindowPosition(window: win, targetPos: pos)
                        for delay in [0.08, 0.20, 0.35, 0.50] {
                            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                                self?.ensureWindowPosition(window: win, targetPos: pos)
                            }
                        }
                    }
                } else {
                    AXUIElementPerformAction(win, kAXRaiseAction as CFString)
                }
            }
            if let firstWin = standardWindows.first {
                AXUIElementPerformAction(firstWin, kAXRaiseAction as CFString)
                AXUIElementSetAttributeValue(firstWin, kAXMainAttribute as CFString, kCFBooleanTrue)
                AXUIElementSetAttributeValue(firstWin, kAXFocusedAttribute as CFString, kCFBooleanTrue)
            }
        } else if wasHidden {
            // If the app was hidden and still has no windows after unhiding, trigger reopen to create a window
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
                guard let self = self else { return }
                if !self.checkHasVisibleWindow(appElement: appElement) && !self.hasOnScreenWindow(pid: app.processIdentifier) {
                    self.reopenApplication(app: app, appElement: appElement, dockItem: dockItem)
                }
            }
        }

        // Re-confirm foreground activation after restore animations complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.activateTargetApp(appElement: appElement, app: app)
        }
    }
}

// MARK: - C EventTap Callback
func dockEventCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        DockMinApp.shared.reEnableTap()
        return Unmanaged.passUnretained(event)
    }

    let shouldSwallow = DockMinApp.shared.handleEvent(type: type, event: event)
    if shouldSwallow {
        return nil
    }
    return Unmanaged.passUnretained(event)
}

// MARK: - Command Line Options
func handleCommandLineTools() -> Bool {
    let args = CommandLine.arguments

    if args.contains("--help") || args.contains("-h") {
        print("""
        ============================================================
        DockMin - Click to Minimize Mac Dock Windows (Open Source)
        ============================================================
        Usage:
            ./DockMin [options]

        Options:
            -u, --uninstall      Uninstall DockMin and clean up login items & permissions
            -v, --version        Show version information
            -h, --help           Show this help message
        ============================================================
        """)
        return false
    }

    if args.contains("--version") || args.contains("-v") {
        print("DockMin v1.0.0 (Open Source under MIT License)")
        return false
    }

    if args.contains("--uninstall") || args.contains("-u") {
        DockMinApp.shared.performFullUninstall(showConfirmation: false)
        return false
    }

    return true
}

// MARK: - Main Entry Point
if !handleCommandLineTools() {
    exit(0)
}

let app = NSApplication.shared
let delegate = DockMinApp.shared
app.delegate = delegate
app.run()
