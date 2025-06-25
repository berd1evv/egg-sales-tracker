//
//  SalesHistoryView.swift
//  EggSalesTracker
//
//  Created by Eldiiar on 22/6/25.
//

import SwiftUI

struct SalesHistoryView: View {
    @ObservedObject var salesManager: SalesManager
    @State private var selectedDateRange: DateRange = .allTime
    @State private var selectedCustomer: String = "All Customers"
    @State private var showingExportOptions = false
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    @Environment(\.dismiss) var dismiss
    
    private var filteredSales: [Sale] {
        var sales = salesManager.sales
        
        // Filter by date range
        switch selectedDateRange {
        case .today:
            let today = Calendar.current.startOfDay(for: Date())
            sales = sales.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        case .thisWeek:
            let calendar = Calendar.current
            let now = Date()
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            sales = sales.filter { $0.date >= startOfWeek }
        case .thisMonth:
            let calendar = Calendar.current
            let now = Date()
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            sales = sales.filter { $0.date >= startOfMonth }
        case .custom:
            sales = sales.filter { $0.date >= customStartDate && $0.date <= customEndDate }
        case .allTime:
            break
        }
        
        // Filter by customer
        if selectedCustomer != "All Customers" {
            sales = sales.filter { $0.buyerName == selectedCustomer }
        }
        
        return sales.sorted { $0.date > $1.date }
    }
    
    private var totalIncome: Double {
        filteredSales.reduce(0) { $0 + $1.price }
    }
    
    private var totalEggs: Int {
        filteredSales.reduce(0) { $0 + $1.quantity }
    }
    
    private var availableCustomers: [String] {
        ["All Customers"] + Array(Set(salesManager.sales.map { $0.buyerName })).sorted()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Section
            VStack(spacing: 16) {
                // Date Range Filter
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date Range")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Picker("Date Range", selection: $selectedDateRange) {
                        ForEach(DateRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if selectedDateRange == .custom {
                        HStack {
                            DatePicker("Start", selection: $customStartDate, displayedComponents: .date)
                            DatePicker("End", selection: $customEndDate, displayedComponents: .date)
                        }
                    }
                }
                
                // Customer Filter
                VStack(alignment: .leading, spacing: 8) {
                    if selectedCustomer != "All Customers" {
                        Text("Customer")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    Picker("Customer", selection: $selectedCustomer) {
                        ForEach(availableCustomers, id: \.self) { customer in
                            Text(customer).tag(customer)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Summary Stats
                HStack {
                    StatSummaryView(
                        title: "Total Sales",
                        value: "\(filteredSales.count)",
                        icon: "list.bullet",
                        color: .blue
                    )
                    
                    StatSummaryView(
                        title: "Total Income",
                        value: String(format: "$%.2f", totalIncome),
                        icon: "dollarsign.circle",
                        color: .green
                    )
                    
                    StatSummaryView(
                        title: "Total Eggs",
                        value: "\(totalEggs)",
                        icon: "oval.portrait.fill",
                        color: .orange
                    )
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Sales List
            if filteredSales.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No sales found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Try adjusting your filters")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else {
                List {
                    ForEach(filteredSales) { sale in
                        SaleHistoryRowView(sale: sale)
                    }
                }
            }
        }
        .navigationTitle("Sales History")
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingExportOptions = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(filteredSales.isEmpty)
            }
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView(sales: filteredSales)
        }
    }
}

struct SaleHistoryRowView: View {
    let sale: Sale
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sale.buyerName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(sale.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "$%.2f", sale.price))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    Text("\(sale.quantity) eggs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let notes = sale.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.top, 4)
            }
            
            HStack {
                Label(String(format: "%.1f dozen", sale.quantityInDozens), systemImage: "chart.bar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label(String(format: "$%.2f/dozen", sale.pricePerDozen), systemImage: "dollarsign.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatSummaryView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct ExportOptionsView: View {
    let sales: [Sale]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Export Format") {
                    Button("Export as CSV") {
                        exportAsCSV()
                    }
                    
                    Button("Export as PDF") {
                        exportAsPDF()
                    }
                }
                
                Section("Export Options") {
                    Text("Total sales: \(sales.count)")
                    Text("Date range: \(sales.first?.date ?? Date(), style: .date) - \(sales.last?.date ?? Date(), style: .date)")
                    Text("Total income: \(String(format: "$%.2f", sales.reduce(0) { $0 + $1.price }))")
                }
            }
            .navigationTitle("Export Sales")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportAsCSV() {
        // CSV export implementation would go here
        dismiss()
    }
    
    private func exportAsPDF() {
        // PDF export implementation would go here
        dismiss()
    }
}

enum DateRange: CaseIterable {
    case today, thisWeek, thisMonth, custom, allTime
    
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .custom: return "Custom"
        case .allTime: return "All Time"
        }
    }
}

#Preview {
    NavigationView {
        SalesHistoryView(salesManager: SalesManager())
    }
} 
