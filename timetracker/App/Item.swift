//
//  Item.swift
//  timetracker
//
//  Created by Moritz Engelhardt on 05.12.24.
//

import Foundation
import CoreData

@objc(Item)
public class Item: NSManagedObject {

}

extension Item {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Item> {
        return NSFetchRequest<Item>(entityName: "Item")
    }

    @NSManaged public var timestamp: Date
}

/*extension Item {
    convenience init(timestamp: Date, context: NSManagedObjectContext) {
        self.init(context: context)
        self.timestamp = timestamp
    }
}*/



