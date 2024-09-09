//
//  ContentView.swift
//  Dymatic Live Link
//
//  Created by Ben Craighill on 1/9/2024.
//

import SwiftUI

struct ContentView: View {
    @State private var ipAddress: String = "127.0.0.1"
    @State private var port: String = "18080"
    @State private var isTransmitting: Bool = false
    @State private var updateInterval: String = "0.01"
    private var motionManager = MotionManager();
    
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Dymatic Live Link")
                .font(.largeTitle)
            Text("Version 24.1.0");
            
            TextField("IP Address", text: $ipAddress)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Port", text: $port)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Port", text: $updateInterval)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                if (isTransmitting) {
                    motionManager.stopUpdating()
                } else {
                    motionManager.startUpdating(ipAddress: ipAddress, port: port, updateInterval: updateInterval);
                }
                
                isTransmitting.toggle()
            }) {
                Text(isTransmitting ? "Stop Transmission" : "Start Transmission")
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
