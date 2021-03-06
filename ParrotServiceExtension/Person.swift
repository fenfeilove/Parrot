import struct Foundation.Date

/* TODO: Person.timeZone; on/off/away (to augment lastSeen). */

/// Describe's a Person's reachability in the Service.
public enum Reachability {
	
	/// The Person is currently unavailable.
	case unavailable
	
	/// The Person is currently available on a phone device.
	case phone
	
	/// The Person is currently available on a tablet device.
	case tablet
	
	/// The Person is currently available on a desktop device.
    /// If the person is available but no device information is provided,
    /// this is the default available state.
	case desktop
}

public protocol Person: class, ServiceOriginating /*: Hashable, Equatable*/ {
    
    typealias IdentifierType = String
	
	/// The Person's unique identifier (specific to the Service).
	var identifier: IdentifierType { get }
    
	/// The Person's name as an array of components.
	/// For example, the first element of the array provides the first name,
	/// and the last element provides the last name. Concatenation of all the elements
	/// in the array should produce the full name.
	var nameComponents: [String] { get }
	
	/// The Person's photo as a remote (internet) or file URL (on disk).
	/// If there is no photo, nil should be returned.
	var photoURL: String? { get }
	
	/// Any possible locations for the Person. These can be physical or virtual.
	/// For example, it may contain email addresses and phone numbers, and even
	/// twitter handles, real physical addresses or coordinates.
	var locations: [String] { get }
	
	/// Is this Person the one logged into the Service?
    var me: Bool { get }
    
    /// Block or unblock this person from contacting the logged in user.
    var blocked: Bool { get set }
    
    /// The timestamp the Person was last active on the Service.
    var lastSeen: Date { get }
    
    /// The Person's reachability (device), if they are reachable.
    var reachability: Reachability { get }
    
    /// The Person's mood or status message (a la XMPP or AIM).
    var mood: String { get }
}

public extension Person {
	
	/// Computes the full name by taking the name components like so:
	/// ["John", "Mark", "Smith"] => "John Mark Smith"
	/// Will return an empty string if there are no name components.
	public var fullName: String {
		return self.nameComponents.joined(separator: " ")
	}
	
	/// Computes the first name by taking the first of the name components:
	/// ["John", "Mark", "Smith"] => "John"
	/// Will return an empty string if there are no name components.
	public var firstName: String {
		return self.nameComponents.first ?? ""
	}
}
