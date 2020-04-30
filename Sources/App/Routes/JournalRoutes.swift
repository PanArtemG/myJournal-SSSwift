//
//  JournalRoutes.swift
//  App
//
//  Created by Artem Panasenko on 30.04.2020.
//

import Vapor
import Leaf

struct JournalRoutes: RouteCollection {
    let journal = JournalController()
    func boot(router: Router) throws {
        
        let topRouter = router.grouped("journal") // [1]
        topRouter.get(use: getTotal)
        topRouter.post(use: newEntry)
        
        let entryRouter = router.grouped("journal", Int.parameter) // [2]
        entryRouter.get(use: getEntry)
        entryRouter.put(use: editEntry)
        entryRouter.delete(use: removeEntry)

        router.get { req -> Future<View> in // [1]
            let leaf = try req.make(LeafRenderer.self) // [2]
            let context = [String: String]() // [3]
            return leaf.render("main", context) // [4]
        }
    }
    
    func getAll(_ req: Request) throws -> Future<View> {
            let total = journal.total()
            let leaf = try req.make(LeafRenderer.self)
            let context = ["count": total]
            return leaf.render("main", context)
        }
    
    func getTotal(_ req: Request) throws -> Future<View> {
        let title = "My Journal"
        let author = "Angus"
        
         
        let total = journal.total()
        let count = "\(total)"
        let leaf = try req.make(LeafRenderer.self)
        let context = ["title": title, "author": author, "count": count]
        return leaf.render("main", context)
    }

    
//    func getTotal(_ req: Request) -> String {
//        let total = journal.total()
//        print("Total Records: \(total)")
//        return "\(total)"
//    }
    
    func newEntry(_ req: Request) throws -> Future<HTTPStatus> { // [1]
        let newID = UUID().uuidString // [2]
        return try req.content.decode(Entry.self).map(to: HTTPStatus.self) { entry in // [3]
            let newEntry = Entry(id: newID,
                                 title: entry.title,
                                 content: entry.content) // [4]
            guard let result = self.journal.create(newEntry) else { // [5]
                throw Abort(.badRequest) // [6]
            }
            print("Created: \(result)")
            return .ok // [7]
        }
    }
    
    func getEntry(_ req: Request) throws -> Entry {
        let index = try req.parameters.next(Int.self) // [1]
        let res = req.response() // [2]
        guard let entry = journal.read(index: index) else {
            throw Abort(.badRequest)
        }
        print("Read: \(entry)")
        try res.content.encode(entry, as: .formData) // [3]
        return entry
    }
    
    func editEntry(_ req: Request) throws -> Future<HTTPStatus> {
        let index = try req.parameters.next(Int.self)
        let newID = UUID().uuidString
        return try req.content.decode(Entry.self).map(to: HTTPStatus.self) { entry in // [1]
            let newEntry = Entry(id: newID,
                                 title: entry.title,
                                 content: entry.content)
            guard let result = self.journal.update(index: index, entry: newEntry) else {
                throw Abort(.badRequest)
            }
            print("Updated: \(result)")
            return .ok
        }
    }
    
    func removeEntry(_ req: Request) throws -> HTTPStatus {
        let index = try req.parameters.next(Int.self)
        guard let result = self.journal.delete(index: index) else {
            throw Abort(.badRequest)
        }
        print("Deleted: \(result)")
        return .ok
    }
    
}
