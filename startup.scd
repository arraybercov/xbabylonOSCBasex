(
s.options.device = "ASIO : Universal Audio Apollo TB";
s.options.sampleRate = 44100;
s.options.numBuffers = 2048 * 32;
s.options.memSize = 8192 * 128;
s.options.maxNodes = 1024 * 128;
s.options.numAudioBusChannels = 2048;
s.options.numOutputBusChannels = 10;
s.options.numInputBusChannels = 8;
s.waitForBoot {
    ~dirt = SuperDirt(2, s);
    ~dirt.loadSoundFiles;
    s.sync;
    ~dirt.start(57120, [0, 0, 2, 2, 4, 4, 6, 6, 8, 8, 10, 10]);
};
);

//open re-route port
b = NetAddr.new("127.0.0.1", 4000);

//forward OSC message with filtering
o = OSCdef(\test,  { |msg, time|
    var bass2 = false;
    var bd = false;
    var sd = false;
    var speed = 0;
    for(1, msg.size, {
        arg i;
        bass2 = if(msg[i] == 'bass2', true, bass2);
        bd = if(msg[i] == 'bd', true, bd);
        sd = if(msg[i] == 'sd', true, sd);
        speed = if(msg[i] == 'speed', msg[i+1], speed)
    });
    b.sendMsg("/tidal", bass2, bd, sd, speed);
}, '/play2', n);

OSCFunc.trace(true); // Turn posting on
OSCFunc.trace(false); // Turn posting on

o.free;

(
//forward OSC message without filtering (localhost, port 4000)
var addr = NetAddr.new("127.0.0.1", 4000);
o = OSCdef(\tidalplay2, {
  arg msg;
  addr.sendMsg(*msg);
}, '/play2', n);
)

//forward OSC messages after OSC schedule unpack
(
var addr = NetAddr.new("127.0.0.1", 4000);
o = OSCFunc({ |msg, time, tidalAddr|
        var latency = time - Main.elapsedTime;
        addr.sendBundle(latency, msg)
}, '/play2', ~dirt.senderAddr, recvPort: ~dirt.port).fix
)
