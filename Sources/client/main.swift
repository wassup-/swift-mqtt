import MQTT
import Foundation

class App: MQTTClientDelegate {
    let client: MQTTClient
    
    init() {
        client = MQTTClient(
            domain: .ip(host: "localhost", port: 8883),
            clientID: "swift-mqtt",
            cleanSession: true,
            keepAlive: 30
        )
        client.delegate = self
    }
    
    func run() throws {
        client.connect()
        RunLoop.current.run()
    }
    
    func didReceive<Packet>(client: MQTTClient, packet: Packet) where Packet : MQTTRecvPacket {
        switch packet {
        case let packet as ConnackPacket:
            print("Connack \(packet)")
            DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                self.client.disconnect()?.whenComplete({ res in
                    print("disconnect \(res) \(client.isConnected)")
                })
            }
        default:
            print(packet)
        }
    }
    
    func didChangeState(client: MQTTClient, state: ConnectionState) {
        print(state)
    }
}

try App().run()
