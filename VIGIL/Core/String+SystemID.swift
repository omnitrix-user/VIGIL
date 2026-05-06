import Foundation

extension String {
    var asSystemID: String {
        "[\(self.uppercased())]"
    }
}
