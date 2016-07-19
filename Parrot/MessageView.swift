import Cocoa
import protocol ParrotServiceExtension.Message

public class MessageView: ListViewCell {
	@IBOutlet var photoView: NSImageView?
	@IBOutlet var textLabel: NSTextView?
	
	// Upon assignment of the represented object, configure the subview contents.
	public override var cellValue: Any? {
		didSet {
			guard let o = self.cellValue as? Message else {
				log.warning("MessageView encountered faulty cellValue!")
				return
			}
			log.verbose("Configuring MessageView.")
			
			let user = o.sender
			let str = AttributedString(string: o.text as String)
			self.userInterfaceLayoutDirection = o.sender.me ? .rightToLeft : .leftToRight
			self.textLabel?.alignment = o.sender.me ? .right : .left
			
			//self.color = o.color
			self.textLabel?.textStorage?.setAttributedString(str)
			self.textLabel?.toolTip = "\((o.timestamp ?? .origin).fullString())"
			let img: NSImage = fetchImage(user: user)
			self.photoView?.image = img
			//self.photoView?.toolTip = o.caption
			
			// Enable automatic links and data detectors.
			self.textLabel?.isEditable = true
			self.textLabel?.checkTextInDocument(nil)
			self.textLabel?.isEditable = false
		}
	}
	
	public override var backgroundStyle: NSBackgroundStyle {
		didSet {
			guard let text = self.textLabel else { return }
			
			// NSTextView doesn't automatically change its text color when the
			// backing view's appearance changes, so we need to set it each time.
			// In addition, make sure links aren't blue as usual.
			// Also, expand the text size if it's purely emoji.
			text.textColor = NSColor.labelColor()
			text.font = NSFont.systemFont(ofSize: 12.0 * (text.string!.isEmoji ? 3 : 1))
			text.typingAttributes = [
				NSForegroundColorAttributeName: text.textColor!,
				NSFontAttributeName: text.font!
			]
			text.linkTextAttributes = [
				NSForegroundColorAttributeName: NSColor.labelColor(),
				NSCursorAttributeName: NSCursor.pointingHand(),
				NSUnderlineStyleAttributeName: 1,
			]
			text.selectedTextAttributes = [
				NSBackgroundColorAttributeName: NSColor.lightOverlay(forAppearance: self.effectiveAppearance),
				NSForegroundColorAttributeName: NSColor.labelColor(),
				NSUnderlineStyleAttributeName: 0,
			]
			text.markedTextAttributes = [
				NSBackgroundColorAttributeName: NSColor.lightOverlay(forAppearance: self.effectiveAppearance),
				NSForegroundColorAttributeName: NSColor.labelColor(),
				NSUnderlineStyleAttributeName: 0,
			]
		}
	}
	
	// Allows the circle crop to dynamically change.
	public override func layout() {
		super.layout()
		if let layer = self.photoView?.layer {
			layer.masksToBounds = true
			layer.cornerRadius = layer.bounds.width / 2.0
		}
		if let text = self.textLabel, let layer = text.layer {
			
			// [BUG] [macOS 12] NSTextView doesn't fill width for some reason.
			text.frame = text.enclosingScrollView!.bounds
			
			// Vertically center text which can fit in the bounds of the text view.
			// Note: only do this if the text isn't Emoji.
			if !text.string!.isEmoji {
				let charRect = text.characterRect()
				let rectDiff = text.bounds.height - charRect.height
				if rectDiff > 0 { text.textContainerInset.height += rectDiff / 2.0 }
				
				// Only clip the text if the text isn't purely Emoji.
				layer.masksToBounds = true
				layer.cornerRadius = 2.0
				layer.backgroundColor = NSColor.darkOverlay(forAppearance: self.effectiveAppearance).cgColor
			}
		}
	}
	
	public override class func cellHeight(forWidth width: CGFloat, cellValue: Any?) -> CGFloat {
		let text = (cellValue as! Message).text ?? ""
		let attr = AttributedString(string: text, attributes: [
			NSFontAttributeName: NSFont.systemFont(ofSize: 12.0 * (text.isEmoji ? 3 : 1))
		])
		let box = attr.boundingRect(with: NSSize(width: width, height: 10000000),
		                            options: [.usesLineFragmentOrigin, .usesFontLeading])
		return (box.size.height > 24.0 ? box.size.height : 24.0) + 16.0
	}
}
