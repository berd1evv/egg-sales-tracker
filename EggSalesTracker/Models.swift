//
//  Models.swift
//  EggSalesTracker
//
//  Created by Eldiiar on 22/6/25.
//

import Foundation

struct Sale: Identifiable, Codable {
    let id = UUID()
    let buyerName: String
    let date: Date
    let quantity: Int // number of eggs
    let price: Double
    let notes: String?
    
    var quantityInDozens: Double {
        Double(quantity) / 12.0
    }
    
    var pricePerDozen: Double {
        guard quantity > 0 else { return 0 }
        return price / quantityInDozens
    }
}

struct Buyer: Identifiable, Codable {
    let id = UUID()
    let name: String
    var totalEggsPurchased: Int = 0
    var totalPaid: Double = 0.0
    
    var totalDozensPurchased: Double {
        Double(totalEggsPurchased) / 12.0
    }
}

class SalesManager: ObservableObject {
    @Published var sales: [Sale] = []
    @Published var buyers: [Buyer] = []
    
    private let salesKey = "SavedSales"
    private let buyersKey = "SavedBuyers"
    
    init() {
        loadData()
//        if sales.isEmpty {
//            loadSampleData()
//        }
    }
    
    // MARK: - Data Persistence
    
    private func saveData() {
        do {
            let salesData = try JSONEncoder().encode(sales)
            UserDefaults.standard.set(salesData, forKey: salesKey)
            
            let buyersData = try JSONEncoder().encode(buyers)
            UserDefaults.standard.set(buyersData, forKey: buyersKey)
        } catch {
            print("Error saving data: \(error)")
        }
    }
    
    private func loadData() {
        // Load sales data
        if let salesData = UserDefaults.standard.data(forKey: salesKey) {
            do {
                sales = try JSONDecoder().decode([Sale].self, from: salesData)
            } catch {
                print("Error loading sales data: \(error)")
                sales = []
            }
        }
        
        // Load buyers data
        if let buyersData = UserDefaults.standard.data(forKey: buyersKey) {
            do {
                buyers = try JSONDecoder().decode([Buyer].self, from: buyersData)
            } catch {
                print("Error loading buyers data: \(error)")
                buyers = []
            }
        }
        
        // If we have sales but no buyers, regenerate buyers from sales
        if !sales.isEmpty && buyers.isEmpty {
            updateBuyerStats()
        }
    }
    
    // MARK: - Public Methods
    
    func addSale(_ sale: Sale) {
        sales.append(sale)
        updateBuyerStats()
        saveData()
    }
    
    func deleteSale(_ sale: Sale) {
        sales.removeAll { $0.id == sale.id }
        updateBuyerStats()
        saveData()
    }
    
    func updateSale(_ sale: Sale) {
        if let index = sales.firstIndex(where: { $0.id == sale.id }) {
            sales[index] = sale
            updateBuyerStats()
            saveData()
        }
    }
    
    func deleteCustomer(_ customerName: String) {
        sales.removeAll { $0.buyerName == customerName }
        updateBuyerStats()
        saveData()
    }
    
    func updateBuyerStats() {
        var buyerStats: [String: (eggs: Int, paid: Double)] = [:]
        
        for sale in sales {
            let current = buyerStats[sale.buyerName] ?? (0, 0.0)
            buyerStats[sale.buyerName] = (current.eggs + sale.quantity, current.paid + sale.price)
        }
        
        buyers = buyerStats.map { name, stats in
            Buyer(name: name, totalEggsPurchased: stats.eggs, totalPaid: stats.paid)
        }.sorted { $0.totalPaid > $1.totalPaid }
        
        saveData()
    }
    
    // MARK: - Computed Properties
    
    var todaySales: [Sale] {
        let today = Calendar.current.startOfDay(for: Date())
        return sales.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }
    
    var todayIncome: Double {
        todaySales.reduce(0) { $0 + $1.price }
    }
    
    var todayDozens: Int {
        todaySales.reduce(0) { $0 + $1.quantity } / 12
    }
    
    var monthlyIncome: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return sales.filter { $0.date >= startOfMonth }.reduce(0) { $0 + $1.price }
    }
    
    var monthlyDozens: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return sales.filter { $0.date >= startOfMonth }.reduce(0) { $0 + $1.quantity } / 12
    }
    
    // MARK: - Data Management
    
    func clearAllData() {
        sales = []
        buyers = []
        UserDefaults.standard.removeObject(forKey: salesKey)
        UserDefaults.standard.removeObject(forKey: buyersKey)
        UserDefaults.standard.synchronize()
    }
    
    func exportData() -> Data? {
        do {
            return try JSONEncoder().encode(sales)
        } catch {
            print("Error exporting data: \(error)")
            return nil
        }
    }
    
    func importData(_ data: Data) -> Bool {
        do {
            let importedSales = try JSONDecoder().decode([Sale].self, from: data)
            sales = importedSales
            updateBuyerStats()
            saveData()
            return true
        } catch {
            print("Error importing data: \(error)")
            return false
        }
    }
    
    // MARK: - Sample Data
    
    private func loadSampleData() {
        // Add some sample data for testing
        let sampleSales = [
            Sale(buyerName: "Anna", date: Date(), quantity: 24, price: 6.00, notes: "Paid in cash"),
            Sale(buyerName: "John", date: Date().addingTimeInterval(-86400), quantity: 12, price: 3.50, notes: "Included carton"),
            Sale(buyerName: "Sarah", date: Date().addingTimeInterval(-172800), quantity: 36, price: 9.00, notes: nil),
            Sale(buyerName: "Anna", date: Date().addingTimeInterval(-259200), quantity: 12, price: 3.00, notes: "Regular customer")
        ]
        
        sales = sampleSales
        updateBuyerStats()
        saveData()
    }
} 
