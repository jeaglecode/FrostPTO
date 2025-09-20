//
//  NavRouter.swift
//  FrostPTO
//
//  Created by Jesse Duenas on 9/17/25.
//

import SwiftUI

// Simple navigation router to control the stack path from child views
final class NavRouter: ObservableObject {
    @Published fileprivate var path: [Route] = []
}