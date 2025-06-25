//
//  SettingsView.swift
//  EggSalesTracker
//
//  Created by Eldiiar on 22/6/25.
//

import SwiftUI
import UniformTypeIdentifiers
import WebKit

struct SettingsView: View {
    @ObservedObject var salesManager: SalesManager
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingAbout = false
    @State private var showingClearDataAlert = false
    @State private var showingImportPicker = false
    @State private var showingExportSheet = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
            List {
                Section("App Information") {
                    HStack {
                        Image(systemName: "oval.portrait.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Egg Sales Tracker")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Data & Statistics") {
                    HStack {
                        Label("Total Sales", systemImage: "list.bullet")
                        Spacer()
                        Text("\(salesManager.sales.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Total Customers", systemImage: "person.3")
                        Spacer()
                        Text("\(salesManager.buyers.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Total Income", systemImage: "dollarsign.circle")
                        Spacer()
                        Text(String(format: "$%.2f", salesManager.sales.reduce(0) { $0 + $1.price }))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Data Management") {
                    Button(action: {
                        exportData()
                    }) {
                        HStack {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    .disabled(salesManager.sales.isEmpty)
                    
                    Button(action: {
                        importData()
                    }) {
                        HStack {
                            Label("Import Data", systemImage: "square.and.arrow.down")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: {
                        showClearDataAlert()
                    }) {
                        HStack {
                            Label("Clear All Data", systemImage: "trash")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.red)
                    .disabled(salesManager.sales.isEmpty)
                }
                
                Section("Legal") {
                    Button(action: {
                        showingPrivacyPolicy = true
                    }) {
                        HStack {
                            Label("Privacy Policy", systemImage: "hand.raised")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: {
                        showingTermsOfService = true
                    }) {
                        HStack {
                            Label("Terms of Service", systemImage: "doc.text")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Section("About") {
                    Button(action: {
                        showingAbout = true
                    }) {
                        HStack {
                            Label("About App", systemImage: "info.circle")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .tint(.orange)
                            .font(.system(size: 17, weight: .bold))
                    }
                    
                }
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                WebViewContainer(
                    title: "Privacy Policy",
                    url: URL(string: "https://www.termsfeed.com/live/95a2e670-e0a9-48f1-8e1c-23131c49cf0b")!
                )
            }
            .sheet(isPresented: $showingTermsOfService) {
                WebViewContainer(
                    title: "Terms of Service",
                    url: URL(string: "https://www.termsfeed.com/live/1a5127c1-879e-422f-9ce2-38b48694f3c8")!
                )
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    salesManager.clearAllData()
                }
            } message: {
                Text("This will permanently delete all sales and customer data. This action cannot be undone.")
            }
            .sheet(isPresented: $showingImportPicker) {
                DocumentPicker(salesManager: salesManager)
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportSheet()
            }
    }
    
    // MARK: - Data Management Functions
    
    private func exportData() {
        guard let data = salesManager.exportData() else {
            // Handle export error
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let dateString = formatter.string(from: Date())
        let fileName = "EggSalesData_\(dateString).json"
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: url)
            showingExportSheet = true
        } catch {
            print("Error saving export file: \(error)")
        }
    }
    
    private func importData() {
        showingImportPicker = true
    }
    
    private func showClearDataAlert() {
        showingClearDataAlert = true
    }
}

struct WebViewContainer: View {
    let title: String
    let url: URL
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            WebView(url: url)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Updates handled automatically
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon and Name
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.orange, .red]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "oval.portrait.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        
                        Text("Egg Sales Tracker")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // App Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Egg Sales Tracker is a simple and efficient app designed for small farmers and backyard flock owners to manage their egg sales business.")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Text("Features:")
                            .font(.headline)
                            .padding(.top)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "plus.circle", text: "Log and track egg sales")
                            FeatureRow(icon: "person.3", text: "Manage customer information")
                            FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "View sales analytics")
                            FeatureRow(icon: "list.bullet", text: "Export sales data")
                            FeatureRow(icon: "calendar", text: "Track sales history")
                        }
                    }
                    .padding(.horizontal)
                    
                    // Developer Info
                    Text("Created with ❤️ for farmers")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    .padding(.horizontal)
                    
                    // App Info
                    VStack(spacing: 16) {
                        Text("App Information")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            InfoRow(title: "Build", value: "1.0.0 (1)")
                            InfoRow(title: "Platform", value: "iOS 15.0+")
                            InfoRow(title: "Framework", value: "SwiftUI")
                            InfoRow(title: "Language", value: "Swift")
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView(salesManager: SalesManager())
}

// MARK: - Document Picker for Import

struct DocumentPicker: UIViewControllerRepresentable {
    let salesManager: SalesManager
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                let success = parent.salesManager.importData(data)
                
                DispatchQueue.main.async {
                    if success {
                        // Show success message
                        print("Data imported successfully")
                    } else {
                        // Show error message
                        print("Failed to import data")
                    }
                    self.parent.dismiss()
                }
            } catch {
                print("Error reading file: \(error)")
                parent.dismiss()
            }
        }
    }
}

// MARK: - Export Sheet

struct ExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("Export Data")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Your data has been prepared for export. Tap the share button below to save or share your data.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 
