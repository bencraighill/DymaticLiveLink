# Dymatic Live Link

A basic Swift application for iOS which can be used to transmit various motion and orientation data for the Dymatic Live Link service in Dymatic Engine via an HTTP server.

## Usage
1. This application must be compiled on macOS and deployed onto an available iOS device.
1. In the Dymatic Editor start the Live Link server and select the target viewport (camera) entity.
1. Enter your local IPv4 address into the application, targeting <b>port 8800</b>, align the device camera with the virtual camera and begin data transmission.
4. All subsequent motion should be reflected live in Editor until the service is stopped.

## Support
This service is available in Dymatic Editor from <b>Version 24.1.0</b> onwards.

## Extending Alternant Devices
Adding support for motion replication of other devices should be a simple task. All that is required is the ability to send and receive HTTP requests in a similar manner to this Swift implementation.