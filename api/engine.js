var engine = require('engine.io');
var server = engine.listen(7070);

server.on('connection', function (socket) {
    console.log("conneted");
    socket.send('utf 8 string');
    socket.send(new Buffer([0, 1, 2, 3, 4, 5])); // binary data
    socket.on('close', function () {
        console.log("closed connection");
    });
});
console.log(server);