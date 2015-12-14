var net = require('net');
var fs = require('fs');
var utf8 = require("utf8");
var server;

var anyJsonTest = /{"|{\[|"}|\d}|e}|\]}/ig;
var startTest = /{"|{\[/i;
var endTest = /"}|\]}|\d}/i;



var server = net.createServer(function (c) { //'connection' listener
    console.log('client connected');
    c.bufferSize = 1024;
    var writeStream = null;
    var isWriting = false;

    c.on('end', function () {
        console.log('client disconnected');
    });
    c.on('data', function (chunk) {

        try {
            var str = chunk.toString();
            var hasJson = !!str.match(anyJsonTest);

            if (hasJson) {
                var startJson = str.search(startTest);
                var endJson = str.regexLastIndexOf(endTest) + 2;
                var jsonStr = str.substr(startJson, (endJson - startJson));

                //console.log(str);
                //console.log('Trying JSON:', startJson, endJson, jsonStr);

                var obj = JSON.parse(jsonStr);

                console.log("JSON:", obj);
                var stripBuffer = new Buffer(jsonStr);
                //console.log("Need to strip:", stripBuffer);
                var stripPos = chunk.indexOf(stripBuffer);
                //console.log('strip args start:%d length:%d ', stripPos, stripBuffer.length);
                var stripped = new Buffer.concat([chunk.slice(0, stripPos), chunk.slice((stripPos + stripBuffer.length))]);
                //console.log("original chunk:%d  strip len:%d  newLen:%d", chunk.length, stripBuffer.length, stripped.length);

                if (obj.action === "STREAM_END") {
                    console.log("Writing File");
                    isWriting = false;
                    writeStream.close();
                    c.write(JSON.stringify({
                        action: "STREAM_ACK",
                        morphId: 88
                    }));
                }

                if (obj.action === "STREAM_DATA") {
                    console.log('Audio stream started');
                    isWriting = true;
                    writeStream = fs.createWriteStream("./stream-" + (new Date()).valueOf().toString() + ".wav");
                }

                if (isWriting) {
                    console.log('writing:', stripped.length);
                    writeStream.write(stripped);
                }

            } else {
                if (isWriting) {
                    console.log('writing:', chunk.length);
                    writeStream.write(chunk);
                }
            }




        } catch (e) {
            console.log(e);
            console.log("Thought I had JSON, but no");
        }

    });

    console.log("Sending STREAM_START");
    c.write('{"action":"STREAM_START"}');

});
server.listen(7070, function () { //'listening' listener
    console.log('server bound');
});


function splitBuffer(buf, delimiter) {
    var arr = [],
        p = 0;

    for (var i = 0, l = buf.length; i < l; i++) {
        if (buf[i] !== delimiter) continue;
        if (i === 0) {
            p = 1;
            continue; // skip if it's at the start of buffer
        }
        arr.push(buf.slice(p, i));
        p = i + 1;
    }

    // add final part
    if (p < l) {
        arr.push(buf.slice(p, l));
    }

    return arr;
}

String.prototype.regexLastIndexOf = function (regex) {

    var stringToWorkWith = this;
    var lastIndexOf = -1;
    var location = stringToWorkWith.search(regex);
    while (location !== 0) {
        lastIndexOf = location;
        stringToWorkWith = this.substring(lastIndexOf);
        location = stringToWorkWith.search(regex);
    }
    return lastIndexOf;
};

Buffer.prototype.indexOf = function (needle) {
    if (!(needle instanceof Buffer)) {
        needle = new Buffer(needle + "");
    }
    var length = this.length,
        needleLength = needle.length,
        pos = 0,
        index;
    for (var i = 0; i < length; ++i) {
        if (needle[pos] === this[i]) {
            if ((pos + 1) === needleLength) {
                return index;
            } else if (pos === 0) {
                index = i;
            }
            ++pos;
        } else if (pos) {
            pos = 0;
            i = index;
        }
    }
    return -1;
};