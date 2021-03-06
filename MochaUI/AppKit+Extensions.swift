@_exported import AppKit
@_exported import Mocha

/* TODO: Localization support for NSDateFormatter stuff. */

public typealias Block = @convention(block) () -> ()

public extension NSView {
    
    /// Determines the semantic context of the `NSView`, how it behaves or draws.
    /// If set explicitly, the view's children also follow it; otherwise, it is
    /// implicitly inherited from an ancestor that has already explicitly marked it.
    public enum SemanticContext: Int {
        case none = 0x0
        case normal = 0x1
        case statusbar = 0x3
        case titlebar = 0x4
        case toolbar = 0x5
        case sourceList = 0x6
        case menu = 0x7
    }
    
    /// Corresponds to `NSView._semanticContext`.
    @nonobjc public var semanticContext: SemanticContext? {
        get { return SemanticContext(rawValue: NSView.semanticContextKey[self, default: 0x0]) }
        set { NSView.semanticContextKey[self] = newValue?.rawValue ?? .none }
    }
    
    /// Corresponds to `NSView._semanticContext`.
    @nonobjc public var owningViewController: NSViewController? {
        get { return NSView.viewControllerKey[self, default: nil] }
        set { NSView.viewControllerKey[self] = newValue }
    }
    
    /// Corresponds to `CALayer.backgroundColor`.
    @nonobjc public var fillColor: NSColor {
        get { return NSView.backgroundColorKey[self, default: .clear] }
        set { NSView.backgroundColorKey[self] = newValue }
    }
    
    /// Corresponds to `CALayer.cornerRadius`.
    @nonobjc public var cornerRadius: CGFloat {
        get { return NSView.cornerRadiusKey[self, default: 0.0] }
        set { NSView.cornerRadiusKey[self] = newValue }
    }
    
    /// Corresponds to `CALayer.masksToBounds`.
    @nonobjc public var clipsToBounds: Bool {
        get { return NSView.clipsToBoundsKey[self, default: false] }
        set { NSView.clipsToBoundsKey[self] = newValue }
    }
    
    /// Corresponds to `CALayer.mask` with a `CAShapeLayer` whose path is this value.
    @nonobjc public var clipPath: NSBezierPath? {
        get { return NSView.clipPathKey[self, default: nil] }
        set { NSView.clipPathKey[self] = newValue }
    }
    
    /// Forces NSView to return `nil` from every `hitTest(_:)`, making it "invisible"
    /// to events.
    @nonobjc public var ignoreHitTest: Bool {
        get { return NSView.ignoreHitTestKey[self, default: false] }
        set { NSView.ignoreHitTestKey[self] = newValue }
    }
    
    /// Forces `wantsUpdateLayer` to be `true`, and invokes the block handler during
    /// the `updateLayer` pass; `drawRect(_:)` will not be called.
    @nonobjc public var updateLayerHandler: Block? {
        get { return NSView.updateLayerHandlerKey[self, default: nil] }
        set { NSView.updateLayerHandlerKey[self] = newValue }
    }
    
    /// Sets the view's `isFlipped` value without overriding the class.
    @nonobjc func set(flipped newValue: Bool) {
        NSView.flippedKey[self] = newValue
    }
    
    /// Sets the view's `isOpaque` value without overriding the class.
    @nonobjc func set(opaque newValue: Bool) {
        NSView.opaqueKey[self] = newValue
    }
    
    /// Sets the view's `allowsVibrancy` value without overriding the class.
    @nonobjc func set(allowsVibrancy newValue: Bool) {
        NSView.allowsVibrancyKey[self] = newValue
    }
    
    private static var semanticContextKey = KeyValueProperty<NSView, Int>("semanticContext")
    private static var viewControllerKey = KeyValueProperty<NSView, NSViewController?>("viewController")
    private static var flippedKey = KeyValueProperty<NSView, Bool>("flipped")
    private static var opaqueKey = KeyValueProperty<NSView, Bool>("opaque")
    private static var backgroundColorKey = KeyValueProperty<NSView, NSColor>("backgroundColor")
    private static var cornerRadiusKey = KeyValueProperty<NSView, CGFloat>("cornerRadius")
    private static var clipsToBoundsKey = KeyValueProperty<NSView, Bool>("clipsToBounds")
    private static var clipPathKey = KeyValueProperty<NSView, NSBezierPath?>("clipPath")
    private static var ignoreHitTestKey = KeyValueProperty<NSView, Bool>("ignoreHitTest")
    private static var allowsVibrancyKey = KeyValueProperty<NSView, Bool>("allowsVibrancy")
    private static var updateLayerHandlerKey = KeyValueProperty<NSView, Block?>("updateLayerHandler")
}

public extension NSView {
	
	/// Snapshots the view as it exists and return an NSImage of it.
	public func snapshot() -> NSImage {
		
		// First get the bitmap representation of the view.
		let rep = self.bitmapImageRepForCachingDisplay(in: self.bounds)!
		self.cacheDisplay(in: self.bounds, to: rep)
		
		// Stuff the representation into an NSImage.
		let snapshot = NSImage(size: rep.size)
		snapshot.addRepresentation(rep)
		return snapshot
	}
	
	/// Automatically translate a view into a NSDraggingImageComponent
	public func draggingComponent(_ key: String) -> NSDraggingImageComponent {
        let component = NSDraggingImageComponent(key: NSDraggingItem.ImageComponentKey(rawValue: key))
		component.contents = self.snapshot()
		component.frame = self.convert(self.bounds, from: self)
		return component
	}
    
    /// Add multiple subviews at a time to an NSView.
    public func add(subviews: NSView..., constraints: () -> () = {}) {
        for s in subviews {
            self.addSubview(s)
        }
        batch { constraints() }
    }
}

extension CGFloat {
    public func defaulting(_ valueIfNaNOrInf: @autoclosure () -> CGFloat) -> CGFloat {
        return (self.isNaN || self.isInfinite) ? valueIfNaNOrInf() : self
    }
}

public extension NSWindow {
    public func crossfade() {
        let root = self.value(forKey: "borderView") as! NSView
        root.crossfade()
    }
}
public extension NSView {
    public func crossfade() {
        visit(self) { // equivalent to `NSViewLayerContentsRedrawCrossfade`:
            $0.layer?.add(CATransition(), forKey: "contents")
        }
    }
}

public class NSScrollableSlider: NSSlider {
    public override func scrollWheel(with event: NSEvent) {
        if event.momentumPhase != .changed && abs(event.deltaY) > 1.0 {
            self.doubleValue += Double(event.deltaY) / 100 * (self.maxValue - self.minValue)
            self.sendAction(self.action, to: self.target)
        }
    }
}

public extension NSAlert {
    
    /// Convenience to initialize a canned NSAlert.
    public convenience init(style: NSAlert.Style = .warning, message: String = "",
                            information: String = "", buttons: [String] = [],
                            suppressionIdentifier: String = "") {
        self.init()
        self.alertStyle = style
        self.messageText = message
        self.informativeText = information
        for b in buttons {
            self.addButton(withTitle: b)
        }
        
        // Enable alert suppression via unique ID.
        if suppressionIdentifier != "" {
            self.showsSuppressionButton = true
            let key = "alert.suppression.\(suppressionIdentifier)"
            
            self.suppressionButton?.boolValue = UserDefaults.standard.bool(forKey: key)
            self.suppressionButton?.performedAction = {
                UserDefaults.standard.set(self.suppressionButton?.boolValue ?? false, forKey: key)
            }
        }
        self.layout()
    }
    
    public func beginModal(completionHandler handler: ((NSApplication.ModalResponse) -> Void)? = nil) {
        let val = self.runModal()
        handler?(val)
    }
    
    public func beginPopover(for view: NSView, on preferredEdge: NSRectEdge,
                             completionHandler handler: ((NSApplication.ModalResponse) -> Void)? = nil)
    {
        // Copy the appearance to match the popover to the view's window.
        let popover = NSPopover()
        popover.appearance = view.window?.appearance
        
        // For a popover, when no buttons are manually added, the alert adds an unmanaged one.
        if self.buttons.count == 0 {
            self.addButton(withTitle: "OK") // TODO: LOCALIZE
            self.buttons[0].keyEquivalent = "\r"
        }
        
        // Reset the button's bezel style to match a popover and hijack its click action.
        for (idx, button) in self.buttons.enumerated() {
            button.bezelStyle = .texturedRounded
            button.performedAction = { [popover, handler] in
                
                // Close the popover and complete the handler with the clicked index.
                popover.close()
                handler?(NSApplication.ModalResponse(rawValue: 1000 + idx))
            }
        }
        
        // Signal the layout pass and mount the popover on the view.
        self.layout()
        popover.contentView = self.window.contentView!
        popover.show(relativeTo: view.bounds, of: view, preferredEdge: preferredEdge)
    }
}

public extension Date {
	public static let origin = Date(timeIntervalSince1970: 0)
}

public extension NSFont {
    
    public struct Name: RawRepresentable, Equatable, Hashable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }
        
        public static let system = NSFont.Name(rawValue: "_system")
    }
    
    public static func from(name: NSFont.Name, size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont? {
        if name == .system {
            return NSFont.systemFont(ofSize: size, weight: weight)
        } else {
            return NSFont(name: name.rawValue, size: size)
        }
    }
	
	/// Load an NSFont from a provided URL.
	public static func from(_ fontURL: URL, size: CGFloat) -> NSFont? {
		let desc = CTFontManagerCreateFontDescriptorsFromURL(fontURL as CFURL) as NSArray?
        guard let item = desc?[0] else { return nil }
		return CTFontCreateWithFontDescriptor(item as! CTFontDescriptor, size, nil)
	}
}

public extension NSSound {
    
    /// Load a sound from an `NSDataAsset` (Xcode Asset Catalog).
    public convenience init?(assetName name: NSSound.Name, bundle: Bundle = .main) {
        guard let asset = NSDataAsset(name: NSDataAsset.Name(rawValue: name.rawValue),
                                      bundle: bundle) else { return nil }
        self.init(data: asset.data)
    }
}

/// A concrete controller type for the management of `NSApplication`.
open class NSApplicationController: NSResponder, NSApplicationDelegate {
    public override init() {
        super.init()
        self._init()
    }
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self._init()
    }
    
    /// Perform one-time URL event registration if not on macOS 13+
    ///
    /// Note: this only applies to CFBundleURLTypes, and not CFBundleDocumentTypes
    /// on compatibility platforms. -application:openFiles: and -application:openFile:
    /// will still be invoked for documents.
    private func _init() {
        guard floor(NSAppKitVersion.current.rawValue) > NSAppKitVersion.macOS10_12.rawValue else { return }
        let ae = NSAppleEventManager.shared()
        ae.setEventHandler(self,
                           andSelector: #selector(self.handleURL(event:withReply:)),
                           forEventClass: UInt32(kInternetEventClass),
                           andEventID: UInt32(kAEGetURL)
        )
    }
    
    /// Wrap the pre-macOS 13 handler and trampoline into the post-macOS 13 one.
    @objc dynamic private func handleURL(event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        guard   let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
                let url = URL(string: urlString)
        else { return }
        
        let sel = Selector(("application:" + "openURLs:")) // since DNE on < macOS 13
        if self.responds(to: sel) {
            self.perform(sel, with: NSApp, with: [url])
        }
    }
}

public extension NSHapticFeedbackManager {
    public static func vibrate(length: Int = 1000, interval: Int = 10) {
        let hp = NSHapticFeedbackManager.defaultPerformer
        for _ in 1...(length/interval) {
            hp.perform(.generic, performanceTime: .now)
            usleep(UInt32(interval * 1000))
        }
    }
}

public extension NSImage {
    
    /// Produce Data from this NSImage with the contained FileType image information.
    public func data(for type: NSBitmapImageRep.FileType) -> Data? {
        guard   let tiff = self.tiffRepresentation,
                let rep = NSBitmapImageRep(data: tiff),
                let dat = rep.representation(using: type, properties: [:])
        else { return nil }
        return dat
    }
}

public func runSelectionPanel(for window: NSWindow? = nil, fileTypes: [String]?, prompt: String = "Select",
                              multiple: Bool = false, _ handler: @escaping ([URL]) -> () = {_ in}) {
	let p = NSOpenPanel()
	p.allowsMultipleSelection = multiple
	p.canChooseDirectories = false
	p.canChooseFiles = true
	p.canCreateDirectories = false
	p.canDownloadUbiquitousContents = true
	p.canResolveUbiquitousConflicts = false
	p.resolvesAliases = true
	p.allowedFileTypes = fileTypes
    p.prompt = "Select"
    p.message = prompt
    if let window = window {
        p.beginSheetModal(for: window) { r in
            guard r.rawValue == NSFileHandlingPanelOKButton else { return }
            handler(p.urls)
        }
    } else {
        p.begin { r in
            guard r.rawValue == NSFileHandlingPanelOKButton else { return }
            handler(p.urls)
        }
    }
}

public extension NSCollectionView {
    
    /// The SelectionType describes the manner in which the ListView may be selected by the user.
    public enum SelectionType {
        
        /// No items may be selected.
        case none
        
        /// One item may be selected at a time.
        case one
        
        /// One item must be selected at all times.
        case exactOne
        
        /// At least one item must be selected at all times.
        case leastOne
        
        /// Multiple items may be selected at a time.
        case any
    }
    
    public func indexPathForLastItem() -> IndexPath {
        let sec = max(0, self.numberOfSections - 1)
        let it = max(0, self.numberOfItems(inSection: sec) - 1)
        return IndexPath(item: it, section: sec)
    }
    
    /// Determines the selection capabilities of the ListView.
    public var selectionType: SelectionType {
        get { return NSCollectionView.selectionTypeProp[self, default: .none] }
        set(s) { NSCollectionView.selectionTypeProp[self] = s
            
            self.allowsMultipleSelection = (s == .leastOne || s == .any)
            self.allowsEmptySelection = (s == .none || s == .one || s == .any)
            self.isSelectable = (s != .none)
        }
    }
    
    private static var selectionTypeProp = AssociatedProperty<NSCollectionView, NSCollectionView.SelectionType>(.strong)
}

public extension NSScrollView {
    
    @nonobjc
    public convenience init(for contentView: NSView? = nil) {
        self.init(frame: .zero)
        self.wantsLayer = true
        self.translatesAutoresizingMaskIntoConstraints = false
        self.drawsBackground = false
        self.backgroundColor = .clear
        self.borderType = .noBorder
        self.documentView = contentView
        self.hasVerticalScroller = true
    }
}

public extension NSWindow {
    public var frameView: NSView {
        return self.value(forKey: "_borderView") as! NSView
    }
    public var titlebar: NSViewController {
        return self.value(forKey: "titlebarViewController") as! NSViewController
    }
}

public extension NSControl {
    
    @discardableResult
    public func setupForBindings() -> Self {
        NSControlValueBindingTrampoline(for: self, continuous: true)
        return self
    }
    
    @objc public dynamic var boolValue: Bool {
        get { return self.integerValue != 0 }
        set { self.integerValue = newValue ? 1 : 0 }
    }
    
    @IBAction public func takeBoolValueFrom(_ sender: Any?) {
        guard let sender = sender as? NSControl else { return }
        self.boolValue = sender.boolValue
    }
}

/// A trampoline for `NSControl`'s `value` NSBinding into KVO. This is required
/// if a client of an `NSControl` wishes to observe the user's action, as it
/// may not (i.e. in the case of `NSTextField`) provide KVO notifications, but,
/// notifies classic Cocoa Bindings clients.
private class NSControlValueBindingTrampoline: NSObject {
    
    /// The `control` currently bound.
    private weak var control: NSControl? = nil
    
    /// The `value` receipt: this value is never used or modified, but upon the
    /// triggering of the NSBinding, it is trampolined here through `didSet`.
    @objc dynamic var value: NSObject? = nil {
        didSet {
            let keys = ["objectValue", "attributedStringValue", "stringValue", "doubleValue",
                        "floatValue", "integerValue", "intValue", "boolValue"]
            for key in keys {
                self.control?.willChangeValue(forKey: key)
                self.control?.cell?.willChangeValue(forKey: key)
            }
            for key in keys {
                self.control?.cell?.didChangeValue(forKey: key)
                self.control?.didChangeValue(forKey: key)
            }
        }
    }
    
    /// Set up the trampoline for the provided `control`. A weak ref is maintained.
    /// Note: if `continuous` is `true`, the `value` binding updates with each
    /// user interaction, and not just when the user is done editing the control.
    /// Note: if no `value` binding is present, the `selectedIndex` binding takes precedence.
    @discardableResult
    public required init(for control: NSControl, continuous: Bool = false) {
        super.init()
        self.control = control
        let binding: NSBindingName = control.exposedBindings.contains(.selectedIndex) ? .selectedIndex : .value
        control.bind(binding, to: self, withKeyPath: "value", options: [
            .continuouslyUpdatesValue: continuous
        ])
    }
}

//
//
//

@discardableResult
public func benchmark<T>(_ only60FPS: Bool = true, _ title: String = #function, _ handler: () throws -> (T)) rethrows -> T {
    let t = CACurrentMediaTime()
    let x = try handler()
    
    let ms = (CACurrentMediaTime() - t)
    if (!only60FPS) || (only60FPS && ms > (1.0/60.0)) {
        print("Operation \(title) took \(ms * 1000)ms!")
    }
    return x
}

@discardableResult
public func UI<T>(_ handler: @escaping () throws -> (T)) rethrows -> T {
    if DispatchQueue.current == .main {
        return try handler()
    } else {
        return try DispatchQueue.main.sync(execute: handler)
    }
}

// Take a screenshot using the system function and provide it as an image.
public func screenshot(interactive: Bool = false) throws -> NSImage {
    let task = Process()
    task.launchPath = "/usr/sbin/screencapture"
    task.arguments = [interactive ? "-ci" : "-cm"]
    task.launch()
    
    var img: NSImage? = nil
    let s = DispatchSemaphore(value: 0)
    task.terminationHandler = { _ in
        guard let pb = NSPasteboard.general.pasteboardItems?.first, pb.types.contains(.png) else {
            s.signal(); return
        }
        guard let data = pb.data(forType: .png), let image = NSImage(data: data) else {
            s.signal(); return
        }
        img = image
        NSPasteboard.general.clearContents()
        s.signal()
    }
    s.wait()
    
    guard img != nil else { throw CocoaError(.fileNoSuchFile) }
    return img!
}

// Trigger the Preview MarkupUI for the given image.
public func markup(for image: NSImage, in view: NSView) throws -> NSImage {
    class MarkupDelegate: NSObject, NSSharingServiceDelegate {
        private let view: NSView
        private let handler: (NSImage?) -> ()
        init(view: NSView, handler: @escaping (NSImage?) -> ()) {
            self.view = view
            self.handler = handler
        }
        
        func sharingService(_ sharingService: NSSharingService, sourceFrameOnScreenForShareItem item: Any) -> NSRect {
            return self.view.window!.frame.insetBy(dx: 0, dy: 16).offsetBy(dx: 0, dy: -16)
        }
        
        func sharingService(_ sharingService: NSSharingService, sourceWindowForShareItems items: [Any], sharingContentScope: UnsafeMutablePointer<NSSharingService.SharingContentScope>) -> NSWindow? {
            return self.view.window!
        }
        
        func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) {
            let itp = items[0] as! NSItemProvider
            itp.loadItem(forTypeIdentifier: "public.url", options: nil) { (url, _) in
                self.handler(NSImage(contentsOf: url as! URL))
            }
        }
    }
    
    var img: NSImage? = nil
    let s = DispatchSemaphore(value: 0)
    
    // Allocate the MarkupUI service.
    var service_ = NSSharingService(named: NSSharingService.Name(rawValue: "com.apple.MarkupUI.Markup"))
    if service_ == nil {
        service_ = NSSharingService(named: NSSharingService.Name(rawValue: "com.apple.Preview.Markup"))
    }
    guard let service = service_ else { throw CocoaError(.fileNoSuchFile) }
    
    // Perform the UI action.
    let markup = MarkupDelegate(view: view) {
        img = $0; s.signal()
    }
    service.delegate = markup
    DispatchQueue.main.async {
        service.perform(withItems: [image])
    }
    
    s.wait()
    guard img != nil else { throw CocoaError(.fileNoSuchFile) }
    return img!
}

public extension CALayer {
    fileprivate static var layoutProp = AssociatedProperty<CALayer, NSLayoutGuide>(.strong)
    
    /// Provides an optional NSLayoutGuide for use in a containing NSView.
    /// This allows CALayers to be laid out by the NSLayoutConstraint engine.
    ///
    /// Note: this does not happen automatically; in your NSView, override
    /// layout() while invoking super, and call syncLayout() manually.
    public fileprivate(set) var layout: NSLayoutGuide {
        get { return CALayer.layoutProp[self, creating: NSLayoutGuide()] }
        set { CALayer.layoutProp[self] = newValue }
    }
    
    /// Allows the CALayer to reconcile the frame calculated by the NSLayoutConstraint
    /// engine, if applicable; not animatable (yet).
    public func syncLayout() {
        guard self.layout.owningView != nil else { return }
        self.frame = self.layout.frame
    }
}

public extension NSView {
    
    /// The preferred method of adding a sublayer to a view. Allows the CALayer
    /// to use an NSLayoutGuide and participate in the NSLayoutConstraint cycle.
    ///
    /// Note: does not do anything if the view is not layer-backed.
    public func add(sublayer layer: CALayer) {
        layer.removeFromSuperlayer()
        guard let superlayer = self.layer else { return }
        superlayer.addSublayer(layer)
        self.addLayoutGuide(layer.layout)
    }
    
    /// The preferred method of removing a sublayer from a view. Allows the CALayer
    /// to unregister its NSLayoutGuide from the NSView.
    public func remove(sublayer layer: CALayer) {
        guard let superlayer = self.layer, layer.superlayer == superlayer else { return }
        layer.removeFromSuperlayer()
        guard layer.layout.owningView == self else { return }
        self.removeLayoutGuide(layer.layout)
    }
}

public extension NSRectEdge {
    
    /// `.leading` is equivalent to either `.minX` or `.maxX` depending on the
    /// system language's UI layout direction.
    public static var leading: NSRectEdge {
        switch NSApp.userInterfaceLayoutDirection {
        case .leftToRight: return .minX
        case .rightToLeft: return .maxX
        }
    }
    
    /// `.trailing` is equivalent to either `.minX` or `.maxX` depending on the
    /// system language's UI layout direction.
    public static var trailing: NSRectEdge {
        switch NSApp.userInterfaceLayoutDirection {
        case .leftToRight: return .maxX
        case .rightToLeft: return .minX
        }
    }
}

public extension String {
    
    /// Verify that the path extension of @{path} matches the UTI provided.
    /// Note that this is actually a terrible idea and should be replaced by
    /// a separate UTI class wrapper.
    public func conformsToUTI(_ UTI: CFString) -> Bool {
        let ext = (self as NSString).pathExtension
        let fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext as CFString, nil)!.takeRetainedValue()
        return UTTypeConformsTo(fileUTI, UTI)
    }
}

public struct NSRectCorner: OptionSet {
    public typealias RawValue = Int
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let none: NSRectCorner = []
    public static let topLeft = NSRectCorner(1 << 0)
    public static let topRight = NSRectCorner(1 << 1)
    public static let bottomLeft = NSRectCorner(1 << 2)
    public static let bottomRight = NSRectCorner(1 << 3)
    public static let all: NSRectCorner = [.topLeft, .topLeft, .bottomLeft, .bottomRight]
}

public struct CornerRadii: Equatable {
    public var topLeft: CGFloat
    public var topRight: CGFloat
    public var bottomLeft: CGFloat
    public var bottomRight: CGFloat
    
    public init(topLeft: CGFloat, topRight: CGFloat, bottomLeft: CGFloat, bottomRight: CGFloat) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
    }
    
    public static let zero = CornerRadii(topLeft: 0, topRight: 0, bottomLeft: 0, bottomRight: 0)
}

public extension NSBezierPath {
    
    /// Builds a "squircle" rounded rectangle with the specified `corners` masked
    /// to the specified `radius`. See iOS 7+ home screen icons for an example.
    public convenience init(roundedIn rect: CGRect, corners: NSRectCorner, radius: CGFloat) {
        let set = CornerRadii(topLeft: corners.contains(.topLeft) ? radius : 0.0,
                              topRight: corners.contains(.topRight) ? radius : 0.0,
                              bottomLeft: corners.contains(.bottomLeft) ? radius : 0.0,
                              bottomRight: corners.contains(.bottomRight) ? radius : 0.0)
        self.init(roundedIn: rect, cornerRadii: set)
    }
    
    /// Builds a "squircle" rounded rectangle with the specified `cornerRadii`.
    public convenience init(roundedIn rect: CGRect, cornerRadii: CornerRadii) {
        self.init()
        let bottomRight = CGPoint(x: rect.maxX, y: rect.minY)
        let topRight = CGPoint(x: rect.maxX, y: rect.maxY)
        let topLeft = CGPoint(x: rect.minX, y: rect.maxY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.minY)
        
        self.move(to: bottomRight)
        
        if cornerRadii.bottomRight > 0.0 {
            self.line(to: CGPoint(x: rect.maxX - (cornerRadii.bottomRight * 2), y: rect.minY))
            self.curve(to: CGPoint(x: rect.maxX, y: rect.minY + (cornerRadii.bottomRight * 2)),
                       controlPoint1: bottomRight, controlPoint2: bottomRight)
        } else {
            self.line(to: bottomRight)
        }
        
        if cornerRadii.topRight > 0.0 {
            self.line(to: CGPoint(x: rect.maxX, y: rect.maxY - (cornerRadii.topRight * 2)))
            self.curve(to: CGPoint(x: rect.maxX - (cornerRadii.topRight * 2), y: rect.maxY),
                       controlPoint1: topRight, controlPoint2: topRight)
        } else {
            self.line(to: topRight)
        }
        
        if cornerRadii.topLeft > 0.0 {
            self.line(to: CGPoint(x: rect.minX + (cornerRadii.topLeft * 2), y: rect.maxY))
            self.curve(to: CGPoint(x: rect.minX, y: rect.maxY - (cornerRadii.topLeft * 2)),
                       controlPoint1: topLeft, controlPoint2: topLeft)
        } else {
            self.line(to: topLeft)
        }
        
        if cornerRadii.bottomLeft > 0.0 {
            self.line(to: CGPoint(x: rect.minX, y: rect.minY + (cornerRadii.bottomLeft * 2)))
            self.curve(to: CGPoint(x: rect.minX + (cornerRadii.bottomLeft * 2), y: rect.minY),
                       controlPoint1: bottomLeft, controlPoint2: bottomLeft)
        } else {
            self.line(to: bottomLeft)
        }
    }
    
    public var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            switch type {
            case .moveToBezierPathElement: path.move(to: points[0])
            case .lineToBezierPathElement: path.addLine(to: points[0])
            case .curveToBezierPathElement: path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePathBezierPathElement: path.closeSubpath()
            }
        }
        return path
    }
}

// The union of all types the pasteboard items collectively hold. Use this instead of
// NSPasteboard's `types` accessor for a UTI-only world.
public extension Array where Element == NSPasteboardItem {
    public var allTypes: [NSPasteboard.PasteboardType] {
        return self.flatMap { $0.types }
    }
}

// Some backward compatible extensions since macOS 10.13 did some weird things.
public extension NSPasteboard.PasteboardType {
    public static func of(_ uti: CFString) -> NSPasteboard.PasteboardType {
        return NSPasteboard.PasteboardType(uti as String)
    }
    public static let _URL: NSPasteboard.PasteboardType = {
        if #available(macOS 10.13, *) {
            return NSPasteboard.PasteboardType.URL
        } else {
            return NSPasteboard.PasteboardType(kUTTypeURL as String)
        }
    }()
    public static let _fileURL: NSPasteboard.PasteboardType = {
        if #available(macOS 10.13, *) {
            return NSPasteboard.PasteboardType.fileURL
        } else {
            return NSPasteboard.PasteboardType(kUTTypeFileURL as String)
        }
    }()
}

public extension NotificationCenter {
    public static var workspace: NotificationCenter {
        return NSWorkspace.shared.notificationCenter
    }
}

//
// Visitors
//

func visit(_ root: NSWindow, _ visitor: (NSWindow) -> ()) {
    visitor(root)
    for x in (root.childWindows ?? []) {
        visit(x, visitor)
    }
}

func visit(_ root: NSView, _ visitor: (NSView) -> ()) {
    visitor(root)
    for x in root.subviews {
        visit(x, visitor)
    }
}

func visit(_ root: CALayer, _ visitor: (CALayer) -> ()) {
    visitor(root)
    for x in (root.sublayers ?? []) {
        visit(x, visitor)
    }
}
