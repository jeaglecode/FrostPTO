//
//  ProfileEditView.swift
//  FrostPTO
//
//  Created by Jesse Duenas on 9/17/25.
//

import SwiftUI

struct ProfileEditView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    
    @FocusState private var isAnyFieldFocused: Bool
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                HStack {
                    Text("Name")
                    Spacer()
                    TextField("Full Name", text: $settings.employeeName)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Employee ID")
                    Spacer()
                    TextField("ID", text: $settings.employeeID)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                        .focused($isAnyFieldFocused)
                }
                
                HStack {
                    Text("Department")
                    Spacer()
                    TextField("Department", text: $settings.department)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Manager")
                    Spacer()
                    TextField("Manager Name", text: $settings.manager)
                        .multilineTextAlignment(.trailing)
                }
                
                DatePicker("Hire Date", selection: $settings.hireDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isAnyFieldFocused = false
                }
            }
        }
    }
}