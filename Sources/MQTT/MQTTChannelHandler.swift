import Foundation
import NIO

protocol MQTTChannelHandlerDelegate: AnyObject {
    func didReceive(packet: MQTTPacket)
    func didCatch(decodeError error: DecodeError)
    func channelActive(channel: Channel)
    func channelInactive()
}

final class MQTTChannelHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer

    private let decoder: MQTTDecoder
    weak var delegate: MQTTChannelHandlerDelegate?
    private var packetData = Data()

    init(decoder: MQTTDecoder = MQTTDecoder()) {
        self.decoder = decoder
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        defer { context.fireChannelRead(data) }

        var buf = unwrapInboundIn(data)
        if let bytes = buf.readBytes(length: buf.readableBytes) {
            packetData.append(contentsOf: bytes)
        }
    }

    func channelReadComplete(context: ChannelHandlerContext) {
        defer { context.fireChannelReadComplete() }

        var data = packetData
        packetData = Data()

        do {
            let packet = try decoder.decode(data: &data)
            delegate?.didReceive(packet: packet)
        } catch let error as DecodeError {
            delegate?.didCatch(decodeError: error)
        } catch {
            // unhandled error
            fatalError("Error while decoding packet data: \(error.localizedDescription)")
        }
    }

    func channelActive(context: ChannelHandlerContext) {
        defer { context.fireChannelActive() }
        delegate?.channelActive(channel: context.channel)
    }

    func channelInactive(context: ChannelHandlerContext) {
        defer { context.fireChannelInactive() }
        delegate?.channelInactive()
    }
}
