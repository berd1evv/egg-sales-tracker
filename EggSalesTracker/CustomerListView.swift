//
//  CustomerListView.swift
//  EggSalesTracker
//
//  Created by Eldiiar on 22/6/25.
//

import SwiftUI

struct CustomerListView: View {
    @ObservedObject var salesManager: SalesManager
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss
    
    private var filteredBuyers: [Buyer] {
        if searchText.isEmpty {
            return salesManager.buyers
        } else {
            return salesManager.buyers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        List {
            if filteredBuyers.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.3")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text(searchText.isEmpty ? "No customers yet" : "No customers found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if searchText.isEmpty {
                        Text("Sales will appear here once you log them")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredBuyers) { buyer in
                    NavigationLink(destination: CustomerDetailView(salesManager: salesManager, buyer: buyer)) {
                        CustomerRowView(buyer: buyer)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search customers")
        .navigationTitle("Customers")
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
    }
}

struct CustomerRowView: View {
    let buyer: Buyer
    
    var body: some View {
        HStack(spacing: 16) {
            // Customer Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange.opacity(0.8), .red.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Text(String(buyer.name.prefix(1)).uppercased())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Customer Info
            VStack(alignment: .leading, spacing: 6) {
                Text(buyer.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Label("\(buyer.totalEggsPurchased) eggs", systemImage: "oval.portrait.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label(String(format: "%.1f dozen", buyer.totalDozensPurchased), systemImage: "chart.bar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Total Spent
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.2f", buyer.totalPaid))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Text("Total spent")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct CustomerDetailView: View {
    @ObservedObject var salesManager: SalesManager
    let buyer: Buyer
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) var dismiss
    
    private var buyerSales: [Sale] {
        salesManager.sales.filter { $0.buyerName == buyer.name }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        List {
            // Customer Summary Section
            Section {
                VStack(spacing: 16) {
                    // Customer Avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.orange.opacity(0.8), .red.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Text(String(buyer.name.prefix(1)).uppercased())
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Text(buyer.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatItemView(
                            title: "Total Eggs",
                            value: "\(buyer.totalEggsPurchased)",
                            icon: "oval.portrait.fill"
                        )
                        
                        StatItemView(
                            title: "Dozens",
                            value: String(format: "%.1f", buyer.totalDozensPurchased),
                            icon: "chart.bar"
                        )
                        
                        StatItemView(
                            title: "Total Spent",
                            value: String(format: "$%.2f", buyer.totalPaid),
                            icon: "dollarsign.circle"
                        )
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Sales History Section
            Section("Sales History") {
                if buyerSales.isEmpty {
                    Text("No sales recorded yet")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(buyerSales) { sale in
                        SaleDetailRowView(sale: sale)
                    }
                }
            }
        }
        .navigationTitle("Customer Details")
        .navigationBarTitleDisplayMode(.inline)
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
                Button("Delete") {
                    showingDeleteAlert = true
                }
                .foregroundColor(.red)
            }
        }
        .alert("Delete Customer", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteCustomer()
            }
        } message: {
            Text("This will delete all sales records for \(buyer.name). This action cannot be undone.")
        }
    }
    
    private func deleteCustomer() {
        // Remove all sales for this customer
        salesManager.deleteCustomer(buyer.name)
    }
}

struct StatItemView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.orange)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct SaleDetailRowView: View {
    let sale: Sale
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(sale.quantity) eggs")
                    .font(.headline)
                
                Text(sale.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let notes = sale.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.2f", sale.price))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Text(String(format: "$%.2f/dozen", sale.pricePerDozen))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CustomerListView(salesManager: SalesManager())
} 
