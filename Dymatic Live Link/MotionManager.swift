//
//  MotionManager.swift
//  Dymatic Live Link
//
//  Created by Ben Craighill on 1/9/2024.
//

import SwiftUI
import CoreMotion
import ARKit

struct MotionData: Codable
{
    let roll: Double;
    let pitch: Double;
    let yaw: Double;
    let positionX: Float;
    let positionY: Float;
    let positionZ: Float;
    let velocityX: Double;
    let velocityY: Double;
    let velocityZ: Double;
    let accelerationX: Double;
    let accelerationY: Double;
    let accelerationZ: Double;
}

struct OrientationData: Codable
{
    let roll: Double;
    let pitch: Double;
    let yaw: Double;
}

class MotionManager : NSObject, ObservableObject, ARSessionDelegate
{
    // Core Motion
    private let motionManager = CMMotionManager()
    private var url: URL?
    private var task: URLSessionDataTask?
    
    private var lastUpdateTime: Date?
    private var velocity = CMAcceleration(x: 0, y: 0, z:0)
    
    // ARKit
    private var arSession = ARSession();
    private var deviceTransform: simd_float4x4?
    
    override init() {
        super.init()
        arSession.delegate = self;
    }
    
    func startUpdating(ipAddress: String, port: String, updateInterval: String)
    {
        // Validate port number
        guard let portInt = Int(port), portInt > 0 && portInt <= 65535 else
        {
            print("Invalid port number!");
            return;
        }
        
        url = URL(string: "http://\(ipAddress):\(port)");
        
        // Validate update interval
        guard let updateIntervalDouble = Double(updateInterval) else {
            print("Invalid update interval!");
            return;
        }
        
        // Validate motion can be accessed
        guard motionManager.isDeviceMotionAvailable else
        {
            print("Device motion is not available!")
            return
        }
        
        // Setup Values
        motionManager.deviceMotionUpdateInterval = updateIntervalDouble;
        velocity = CMAcceleration(x: 0, y: 0, z: 0);
        
        // Start the AR Session
        let configuration = ARWorldTrackingConfiguration();
        configuration.worldAlignment = .gravity
        configuration
        arSession.run(configuration)
        
        // Launch Motion Manager
        motionManager.startDeviceMotionUpdates(to: .main) { [self] (data, error) in
            guard let data = data, error == nil else
            {
                print("Error: \(error?.localizedDescription ?? "Unknown Error")");
                return;
            }
            
            let now = Date();
            let timeInterval = lastUpdateTime != nil ? now.timeIntervalSince(lastUpdateTime!) : 0;
            self.lastUpdateTime = now;
            
            self.velocity.x += data.userAcceleration.x * timeInterval;
            self.velocity.y += data.userAcceleration.y * timeInterval;
            self.velocity.z += data.userAcceleration.z * timeInterval;
            
            let position = getPosition();
            let orientation = getOrientation()
            
            // Prepare data for transmission
            // Note: This needs to match the Dymatic transform space
            let orientationData = MotionData(
                roll: orientation.roll,
                pitch: orientation.pitch,
                yaw: orientation.yaw,
                positionX: position.x,
                positionY: position.y,
                positionZ: position.z,
                velocityX: self.velocity.x,
                velocityY: self.velocity.y,
                velocityZ: self.velocity.z,
                accelerationX: data.userAcceleration.x,
                accelerationY: data.userAcceleration.y,
                accelerationZ: data.userAcceleration.z
            );
            
            self.sendMotionData(orientationData)
        }
    }
    
    func stopUpdating()
    {
        // Stop Motion Manager
        motionManager.stopDeviceMotionUpdates()
        task?.cancel()
        
        // Stop AR Session
        arSession.pause()
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Get the device's position and orientation
        print("ARSession camera transform updated!");
        let transform = frame.camera.transform;
        DispatchQueue.main.async {
            self.deviceTransform = transform;
        }
    }
    
    func getPosition() -> SIMD3<Float> {
        guard let transform = deviceTransform else { return SIMD3<Float>(0, 0, 0) }
        return SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z);
    }
    
    func getOrientation() -> OrientationData {
        guard let transform = deviceTransform else { return OrientationData(roll: 0, pitch: 0, yaw: 0) }
        
        let rotationMatrix = simd_float3x3(
            simd_make_float3(transform.columns.0.x, transform.columns.0.y, transform.columns.0.z),
            simd_make_float3(transform.columns.1.x, transform.columns.1.y, transform.columns.1.z),
            simd_make_float3(transform.columns.2.x, transform.columns.2.y, transform.columns.2.z)
        )
        
        let orientation = simd_quatf(rotationMatrix)
        
        let x = orientation.imag.x
        let y = orientation.imag.y
        let z = orientation.imag.z
        let w = orientation.real
        
        let pitchNumerator = 2 * (w * x + y * z)
        let pitchDenominator = 1 - 2 * (x * x + y * y)
        let pitch = atan2(pitchNumerator, pitchDenominator)
            
        let yawNumerator = 2 * (w * y - z * x)
        let yaw = asin(yawNumerator)
            
        let rollNumerator = 2 * (w * z + x * y)
        let rollDenominator = 1 - 2 * (y * y + z * z)
        let roll = atan2(rollNumerator, rollDenominator)
        
        let data = OrientationData(roll: Double(roll), pitch: Double(pitch), yaw: Double(yaw))
        
        return data;
    }
    
    private func sendMotionData(_ data: MotionData)
    {
        guard let url = url else
        {
            print("URL is not set");
            return;
        }
        
        var request = URLRequest(url: url);
        request.httpMethod = "POST";
        request.setValue("application/json", forHTTPHeaderField: "Content-Type");
        
        do
        {
            let jsonData = try JSONEncoder().encode(data);
            request.httpBody = jsonData;
        }
        catch
        {
            print("Error encoding JSON: \(error)");
            return;
        }
        
        print("Sending data to \(url)");
        
        task = URLSession.shared.dataTask(with: request) { (responseData, response, error) in
            if let error = error {
                print("Error sending data: \(error)");
                return;
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Received HTTP response status code: \(httpResponse.statusCode)");
            }
            
            print("Data sent successfully.");
        }
        
        task?.resume();
    }
}
