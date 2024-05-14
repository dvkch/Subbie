//
//  AppError.swift
//  Subbie
//
//  Created by Stanislas Chevallier on 28/09/2021.
//

import Foundation

enum AppError: LocalizedError {
    case invalidFileType(String)
    case invalidTimingsFormat(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFileType(let type): return L10n.Error.invalidFileType(type)
        case .invalidTimingsFormat(let line): return L10n.Error.invalidTimingsFormat(line)
        }
    }
}
