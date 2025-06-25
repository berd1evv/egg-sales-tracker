//
//  DashboardView.swift
//  EggSalesTracker
//
//  Created by Eldiiar on 22/6/25.
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var salesManager: SalesManager
    @State private var showingAddSale = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with farm-inspired styling
                    VStack(spacing: 8) {
                        HStack(alignment: .top) {
                            VStack(spacing: 8) {
                                Text("Egg Sales Tracker")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Track your farm's egg sales")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(alignment: .top, spacing: 12) {
                                NavigationLink(destination: AnalyticsView(salesManager: salesManager)) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.title3)
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                }
                                
                                NavigationLink(destination: CustomerListView(salesManager: salesManager)) {
                                    Image(systemName: "person.3.fill")
                                        .font(.title3)
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                }
                                
                                NavigationLink(destination: SettingsView(salesManager: salesManager)) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.title3)
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Quick Stats Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "Today's Sales",
                            value: "$\(String(format: "%.2f", salesManager.todayIncome))",
                            subtitle: "\(salesManager.todayDozens) dozen",
                            icon: "dollarsign.circle.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Monthly Income",
                            value: String(format: "$%.2f", salesManager.monthlyIncome),
                            subtitle: "\(salesManager.monthlyDozens) dozen",
                            icon: "chart.line.uptrend.xyaxis.circle.fill",
                            color: .blue
                        )
                    }
                    .padding(.horizontal)
                    
                    // Add Sale Button
                    Button(action: {
                        showingAddSale = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Log Sale")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.orange, .red]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Recent Sales Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Sales")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            NavigationLink(destination: SalesHistoryView(salesManager: salesManager)) {
                                Text("View All")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.horizontal)
                        
                        if salesManager.sales.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "oval.portrait.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray.opacity(0.5))
                                
                                Text("No sales yet")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("Tap 'Log Sale' to add your first sale")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(Array(salesManager.sales.prefix(5))) { sale in
                                    SaleRowView(sale: sale)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddSale) {
                AddSaleView(salesManager: salesManager)
            }
        }
    }
}

struct StatCard: View {
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
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct SaleRowView: View {
    let sale: Sale
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(sale.buyerName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(sale.quantity) eggs • \(sale.date, style: .date)")
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
            
            Text(String(format: "$%.2f", sale.price))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    DashboardView(salesManager: SalesManager())
} 
