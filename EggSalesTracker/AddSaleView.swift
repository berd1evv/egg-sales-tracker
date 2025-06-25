//
//  AddSaleView.swift
//  EggSalesTracker
//
//  Created by Eldiiar on 22/6/25.
//

import SwiftUI

struct AddSaleView: View {
    @ObservedObject var salesManager: SalesManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var buyerName = ""
    @State private var quantity = 12
    @State private var price = 3.0
    @State private var date = Date()
    @State private var notes = ""
    @State private var showingBuyerPicker = false
    
    private var existingBuyers: [String] {
        Array(Set(salesManager.sales.map { $0.buyerName })).sorted()
    }
    
    private var pricePerDozen: Double {
        guard quantity > 0 else { return 0 }
        return price / (Double(quantity) / 12.0)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Sale Details") {
                    // Buyer Name
                    HStack {
                        Text("Buyer")
                        Spacer()
                        Button(buyerName.isEmpty ? "Select Buyer" : buyerName) {
                            showingBuyerPicker = true
                        }
                        .foregroundColor(buyerName.isEmpty ? .orange : .primary)
                    }
                    
                    // Quantity
                    HStack {
                        Text("Quantity")
                        Spacer()
                        Stepper("\(quantity) eggs", value: $quantity, in: 1...1000, step: 1)
                    }
                    
                    HStack {
                        Text("Dozens")
                        Spacer()
                        Text(String(format: "%.1f", Double(quantity) / 12.0))
                            .foregroundColor(.secondary)
                    }
                    
                    // Price
                    HStack {
                        Text("Total Price")
                        Spacer()
                        TextField("Price", value: $price, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Price per Dozen")
                        Spacer()
                        Text(String(format: "$%.2f", pricePerDozen))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Date & Notes") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button("Save Sale") {
                        saveSale()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                    .disabled(buyerName.isEmpty || price <= 0)
                }
            }
            .navigationTitle("Log Sale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingBuyerPicker) {
                BuyerPickerView(
                    selectedBuyer: $buyerName,
                    existingBuyers: existingBuyers,
                    isPresented: $showingBuyerPicker
                )
            }
        }
    }
    
    private func saveSale() {
        let newSale = Sale(
            buyerName: buyerName,
            date: date,
            quantity: quantity,
            price: price,
            notes: notes.isEmpty ? nil : notes
        )
        
        salesManager.addSale(newSale)
        dismiss()
    }
}

struct BuyerPickerView: View {
    @Binding var selectedBuyer: String
    let existingBuyers: [String]
    @Binding var isPresented: Bool
    @State private var newBuyerName = ""
    @State private var showingNewBuyerField = false
    
    var body: some View {
        NavigationView {
            List {
                if !existingBuyers.isEmpty {
                    Section("Existing Buyers") {
                        ForEach(existingBuyers, id: \.self) { buyer in
                            Button(action: {
                                selectedBuyer = buyer
                                isPresented = false
                            }) {
                                HStack {
                                    Text(buyer)
                                    Spacer()
                                    if selectedBuyer == buyer {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
                
                Section("Add New Buyer") {
                    if showingNewBuyerField {
                        HStack {
                            TextField("Buyer name", text: $newBuyerName)
                            
                            Button("Add") {
                                if !newBuyerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    selectedBuyer = newBuyerName.trimmingCharacters(in: .whitespacesAndNewlines)
                                    isPresented = false
                                }
                            }
                            .disabled(newBuyerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    } else {
                        Button("+ Add New Buyer") {
                            showingNewBuyerField = true
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("Select Buyer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    AddSaleView(salesManager: SalesManager())
} 