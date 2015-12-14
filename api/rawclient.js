var audioPath = "./";
var filePath = audioPath + '/example.wav';

var net = require('net');
var fs = require('fs');
var client;


var readStream = fs.createReadStream(filePath);
var isLocal = true;
//http://54.68.40.119
var config = isLocal ? {
    host: '127.0.0.1',
    port: 7070
} : {
    host: '130.204.23.168',
    port: 7777
};

console.log("Connecting to [%s]", (isLocal ? "LOCAL" : "REMOTE"));

client = net.connect(config,
    function () { //'connect' listener
        console.log("Connected, waiting for initial data");
    }
);

client.on('data', function (data) {
    console.log("[data]");
    try {
        var res = JSON.parse(data.toString());
        console.log("Server action: ", res.action);
        if (res.action === "STREAM_START") {
            console.log("Start file stream");
            readStream
                .on('data', function (chunk) {
                    console.log('write chunk:', chunk);
                    client.write(chunk);

                })
                .on('end', function () {
                    console.log('File read, send END');

                    client.write('\r\n' + JSON.stringify({
                        action: 'STREAM_END'
                    }));

                });
        }

        if (res.action === "STREAM_ACK") {
            console.log('Got ACK, closing client');
            client.end();
            process.exit();
        }

    } catch (e) {
        console.log("Server didn't send JSON");
        client.end();
    }
});

client.on('end', function () {
    console.log('disconnected from server');
});