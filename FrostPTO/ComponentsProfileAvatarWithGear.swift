//
//  ProfileAvatarWithGear.swift
//  FrostPTO
//
//  Created by Jesse Duenas on 9/17/25.
//

import SwiftUI

struct ProfileAvatarWithGear: View {
    let selected: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    private var unselectedColor: Color { 
        colorScheme == .dark ? .white : .black 
    }
    
    var body: some View {
        ZStack {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(selected ? .accentColor : unselectedColor)
            
            Image(systemName: "gearshape.fill")
                .font(.system(size: 8))
                .foregroundColor(.white)
                .background(
                    Circle()
                        .fill(selected ? Color.accentColor : (colorScheme == .dark ? Color.black : Color.black))
                        .frame(width: 12, height: 12)
                )
                .offset(x: 8, y: 8)
        }
    }
}