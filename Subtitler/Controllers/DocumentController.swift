//
//  DocumentController.swift
//  Subtitler
//
//  Created by Stanislas Chevallier on 28/09/2021.
//

import Cocoa

class DocumentController: NSDocumentController {
    override func openDocument(withContentsOf url: URL, display displayDocument: Bool, completionHandler: @escaping (NSDocument?, Bool, Error?) -> Void) {
        super.openDocument(withContentsOf: url, display: displayDocument) { document, documentWasAlreadyOpen, error in
            if error == nil {
                let transientDocuments = self.documents
                    .compactMap { $0 as? Subtitle }
                    .filter(\.isTransient)
                    .filter(\.isEmpty)

                transientDocuments.forEach { document in
                    document.close()
                }
            }
            completionHandler(document, documentWasAlreadyOpen, error)
        }
    }
}
