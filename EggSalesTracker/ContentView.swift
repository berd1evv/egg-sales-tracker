//
//  ContentView.swift
//  EggSalesTracker
//
//  Created by Eldiiar on 22/6/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var salesManager = SalesManager()
    
    var body: some View {
        DashboardView(salesManager: salesManager)
    }
}

#Preview {
    ContentView()
}
