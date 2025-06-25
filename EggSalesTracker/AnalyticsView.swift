//
//  AnalyticsView.swift
//  EggSalesTracker
//
//  Created by Eldiiar on 22/6/25.
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @ObservedObject var salesManager: SalesManager
    @State private var selectedTimeframe: Timeframe = .month
    @State private var selectedChartType: ChartType = .income
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("Analytics & Reports")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Business insights for your egg sales")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Chart Type Selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Chart Type")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Picker("Chart Type", selection: $selectedChartType) {
                        ForEach(ChartType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)
                
                // Timeframe Selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Timeframe")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(Timeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.displayName).tag(timeframe)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)
                
                // Main Chart
                VStack(alignment: .leading, spacing: 16) {
                    Text(selectedChartType.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    ChartView(
                        salesManager: salesManager,
                        chartType: selectedChartType,
                        timeframe: selectedTimeframe
                    )
                    .frame(height: 250)
                    .padding(.horizontal)
                }
                
                // Summary Cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    AnalyticsCard(
                        title: "Total Income",
                        value: String(format: "$%.2f", totalIncome),
                        subtitle: "This \(selectedTimeframe.displayName.lowercased())",
                        icon: "dollarsign.circle.fill",
                        color: .green
                    )
                    
                    AnalyticsCard(
                        title: "Total Eggs",
                        value: "\(totalEggs)",
                        subtitle: "This \(selectedTimeframe.displayName.lowercased())",
                        icon: "oval.portrait.fill",
                        color: .orange
                    )
                    
                    AnalyticsCard(
                        title: "Average Price",
                        value: String(format: "$%.2f", averagePricePerDozen),
                        subtitle: "Per dozen",
                        icon: "chart.bar.fill",
                        color: .blue
                    )
                    
                    AnalyticsCard(
                        title: "Total Sales",
                        value: "\(totalSales)",
                        subtitle: "This \(selectedTimeframe.displayName.lowercased())",
                        icon: "list.bullet",
                        color: .purple
                    )
                }
                .padding(.horizontal)
                
                // Top Customers
                VStack(alignment: .leading, spacing: 16) {
                    Text("Top Customers")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    if topCustomers.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.3")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("No customer data")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(Array(topCustomers.prefix(5).enumerated()), id: \.element.id) { index, customer in
                                TopCustomerRow(
                                    customer: customer,
                                    rank: index + 1,
                                    totalSpent: topCustomers.first?.totalPaid ?? 0
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Insights
                VStack(alignment: .leading, spacing: 16) {
                    Text("Business Insights")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        InsightCard(
                            title: "Best Selling Period",
                            value: bestSellingPeriod,
                            icon: "calendar",
                            color: .green
                        )
                        
                        InsightCard(
                            title: "Average Order Size",
                            value: String(format: "%.1f dozen", averageOrderSize),
                            icon: "chart.bar",
                            color: .blue
                        )
                        
                        InsightCard(
                            title: "Most Active Customer",
                            value: mostActiveCustomer,
                            icon: "person.circle",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Analytics")
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
    
    // Computed Properties
    private var filteredSales: [Sale] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeframe {
        case .week:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return salesManager.sales.filter { $0.date >= startOfWeek }
        case .month:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return salesManager.sales.filter { $0.date >= startOfMonth }
        case .year:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            return salesManager.sales.filter { $0.date >= startOfYear }
        }
    }
    
    private var totalIncome: Double {
        filteredSales.reduce(0) { $0 + $1.price }
    }
    
    private var totalEggs: Int {
        filteredSales.reduce(0) { $0 + $1.quantity }
    }
    
    private var totalSales: Int {
        filteredSales.count
    }
    
    private var averagePricePerDozen: Double {
        let totalDozens = filteredSales.reduce(0.0) { $0 + $1.quantityInDozens }
        return totalDozens > 0 ? totalIncome / totalDozens : 0
    }
    
    private var topCustomers: [Buyer] {
        salesManager.buyers.sorted { $0.totalPaid > $1.totalPaid }
    }
    
    private var averageOrderSize: Double {
        guard !filteredSales.isEmpty else { return 0 }
        let totalDozens = filteredSales.reduce(0.0) { $0 + $1.quantityInDozens }
        return totalDozens / Double(filteredSales.count)
    }
    
    private var bestSellingPeriod: String {
        // Simple logic - could be enhanced with more sophisticated analysis
        let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let calendar = Calendar.current
        var dayCounts: [Int: Int] = [:]
        
        for sale in filteredSales {
            let weekday = calendar.component(.weekday, from: sale.date) - 1
            dayCounts[weekday, default: 0] += 1
        }
        
        if let bestDay = dayCounts.max(by: { $0.value < $1.value })?.key {
            return weekdays[bestDay]
        }
        return "Not enough data"
    }
    
    private var mostActiveCustomer: String {
        topCustomers.first?.name ?? "No customers"
    }
}

struct ChartView: View {
    let salesManager: SalesManager
    let chartType: ChartType
    let timeframe: Timeframe
    
    var body: some View {
        Chart {
            ForEach(chartData, id: \.period) { data in
                LineMark(
                    x: .value("Period", data.period),
                    y: .value("Value", data.value)
                )
                .foregroundStyle(Color.orange.gradient)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Period", data.period),
                    y: .value("Value", data.value)
                )
                .foregroundStyle(Color.orange.opacity(0.1).gradient)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel()
            }
        }
    }
    
    private var chartData: [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var data: [ChartDataPoint] = []
        
        switch (chartType, timeframe) {
        case (.income, .week):
            // Daily income for the week
            for i in 0..<7 {
                let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
                let daySales = salesManager.sales.filter { calendar.isDate($0.date, inSameDayAs: date) }
                let income = daySales.reduce(0) { $0 + $1.price }
                data.append(ChartDataPoint(period: calendar.component(.weekday, from: date), value: income))
            }
            
        case (.income, .month):
            // Weekly income for the month
            for i in 0..<4 {
                let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: now) ?? now
                let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
                let weekSales = salesManager.sales.filter { $0.date >= weekStart && $0.date < weekEnd }
                let income = weekSales.reduce(0) { $0 + $1.price }
                data.append(ChartDataPoint(period: i + 1, value: income))
            }
            
        case (.income, .year):
            // Monthly income for the year
            for i in 0..<12 {
                let monthStart = calendar.date(byAdding: .month, value: -i, to: now) ?? now
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? now
                let monthSales = salesManager.sales.filter { $0.date >= monthStart && $0.date < monthEnd }
                let income = monthSales.reduce(0) { $0 + $1.price }
                data.append(ChartDataPoint(period: calendar.component(.month, from: monthStart), value: income))
            }
            
        case (.quantity, _):
            // Similar logic for quantity charts
            for i in 0..<7 {
                let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
                let daySales = salesManager.sales.filter { calendar.isDate($0.date, inSameDayAs: date) }
                let quantity = daySales.reduce(0) { $0 + $1.quantity }
                data.append(ChartDataPoint(period: calendar.component(.weekday, from: date), value: Double(quantity)))
            }
            
        case (.averagePrice, _):
            // Average price per dozen
            for i in 0..<7 {
                let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
                let daySales = salesManager.sales.filter { calendar.isDate($0.date, inSameDayAs: date) }
                let avgPrice = daySales.isEmpty ? 0 : daySales.reduce(0) { $0 + $1.pricePerDozen } / Double(daySales.count)
                data.append(ChartDataPoint(period: calendar.component(.weekday, from: date), value: avgPrice))
            }
        }
        
        return data.reversed()
    }
}

struct ChartDataPoint {
    let period: Int
    let value: Double
}

struct AnalyticsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct TopCustomerRow: View {
    let customer: Buyer
    let rank: Int
    let totalSpent: Double
    
    private var percentage: Double {
        guard totalSpent > 0 else { return 0 }
        return (customer.totalPaid / totalSpent) * 100
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                Circle()
                    .fill(rank <= 3 ? Color.orange : Color.gray.opacity(0.3))
                    .frame(width: 30, height: 30)
                
                Text("\(rank)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(rank <= 3 ? .white : .primary)
            }
            
            // Customer Info
            VStack(alignment: .leading, spacing: 2) {
                Text(customer.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(customer.totalEggsPurchased) eggs • \(String(format: "%.1f", customer.totalDozensPurchased)) dozen")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount and Percentage
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.2f", customer.totalPaid))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Text(String(format: "%.1f%%", percentage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct InsightCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

enum ChartType: CaseIterable {
    case income, quantity, averagePrice
    
    var displayName: String {
        switch self {
        case .income: return "Income"
        case .quantity: return "Quantity"
        case .averagePrice: return "Avg Price"
        }
    }
}

enum Timeframe: CaseIterable {
    case week, month, year
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }
}

#Preview {
    NavigationView {
        AnalyticsView(salesManager: SalesManager())
    }
} 
