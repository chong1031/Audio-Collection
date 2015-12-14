var io = require('socket.io')(7070);
io.on('connection', function (socket) {
    socket.broadcast.emit('join', socket['id']);
    console.log(socket['id'] + ' has connected!');

    socket.on('writeStr', function (data) {
        console.log('writeStr', data);
        socket.emit('update', data);
    });

    socket.on('disconnect', function () {
        socket.broadcast.emit('disappear', socket['id']);
        console.log(socket['id'] + ' has disconnected!');
    });
});