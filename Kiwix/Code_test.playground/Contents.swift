//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

func truncatedPlaceHolderString(string: String?, searchBar: UISearchBar) -> String? {
    if let string = string, let label = searchBar.valueForKey("_searchField")?.valueForKey("_placeholderLabel") as? UILabel, let labelFont = label.font {
        let preferredSize = CGSizeMake(searchBar.frame.width - 45.0, 1000)
        var rect = (string as NSString).boundingRectWithSize(preferredSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: labelFont], context: nil)
        
        var truncatedString = string as NSString
        var istruncated = false
        while rect.height > label.frame.height {
            istruncated = true
            truncatedString = truncatedString.substringToIndex(truncatedString.length - 2)
            rect = truncatedString.boundingRectWithSize(preferredSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: labelFont], context: nil)
        }
        return truncatedString as String + (istruncated ? "..." : "")
    }
    return nil
}

let searchBar = UISearchBar(frame: CGRectMake(0, 0, 304, 44))
searchBar.placeholder = "Search"
let originalString = "Truncate and add an ellipsis character to the last visible line if the text does not fit into the specified bounds. "
let string = truncatedPlaceHolderString(originalString, searchBar: searchBar)
print(string)

let dice1 = arc4random_uniform(6) + 1