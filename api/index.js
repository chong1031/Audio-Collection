var express = require('express');
var app = express();
//var cookieParser = require('cookie-parser');
var session = require('cookie-session');
var bodyParser = require('body-parser');

//app.use(cookieParser());
app.use(bodyParser.urlencoded({
	extended: false
}));
app.use(session({
	name: 'JSESSIONID',
	keys: ['key1']
}));
app.use(function (req, res, next) {
	if (!req.session.JSESSIONID) {
		req.session.JSESSIONID = 123;
	}
	next();
});

app.get('/morphing/index.jsp', function (req, res) {
	console.log(JSON.stringify(req.session));
	res.json({
		response: true
	});
});
app.post('/morphing/LoginServlet', function (req, res) {
	console.log('LoginServlet');
	var result = false;
	if (req.body.email === "ObenSesame@ObenSesame.com" && req.body.password === "ObenSesame" && req.body.displayname === "iOS USER") {
		result = true;
	}
	console.log(req.body);
	res.json({
		response: result
	});
});

app.get('/morphing/avatar', function (req, res) {
	console.log('get avatar');
	res.json({
		result: 123
	});
});
app.post('/morphing/AvatarServlet', function (req, res) {
	// requires: req.body.avatarName
	// 
	console.log('save avatar');
	res.json({
		state: "success",
		message: "Successfully generated avatar!",
		sourceAvatarId: 123
	});
});
/*
	For deleting avatar
	request example:
	jsonStr=JSON.stringify({
		"action": "delete",
		"avatarId": 123
	})

 */
app.post('/morphing/ActionServlet', function (req, res) {
	setTimeout(function () {
		res.json({
			result: "success"
		});
	}, 500);
});

app.get('/morphing/phrases', function (req, res) {
	console.log('get phrases');
	res.json({
		"phrases": [
			makePhrase("say this first", 1),
			makePhrase("secondly", 2),
			makePhrase("this si the third thing to say", 3),
			makePhrase("last message to say for you", 4)
		]
	});
});

function makePhrase(phrase, id) {
	return {
		"phrase": phrase,
		"id": id
	};
}

/*
	Upload data for avatar builder
	req: uploadId (int)
	req: file (filename=blob wav blob)

	response example:
		{
		"state": "success",
		"morphingURL": "http://54.68.40.119:8080/demo/morphing/14/morphings/119/recorded_morph.wav",
		"morphingDownload": "MorphingServlet?userId=14&morphingId=119"
		}
 */
app.post('/morphing/VoiceServlet', function (req, res) {
	setTimeout(function () {
		res.json({
			result: "success"
		});
	}, 500);
});


app.get('/morphing/morphs', function (req, res) {
	console.log('get morph list');
	res.json({
		"models": [{
			name: "Angelina Jolie",
			image: "/demo/morphing/celebrity/Angelina_Jolie/avatar_image.jpg",
			id: "avatar_Angelina_Jolie_1"
		}, {
			name: "Kim Kardashian",
			image: "/demo/morphing/celebrity/Kim_Kardashian/avatar_image.jpg",
			id: "avatar_Kim_Kardashian_2"
		}, {
			name: "Morgan Freeman",
			image: "/demo/morphing/celebrity/Morgan_Freeman/avatar_image.jpg",
			id: "avatar_Morgan_Freeman_5"
		}, {
			name: "Diane Merritt",
			image: "images/avatar_default_image.jpg",
			id: "avatar_Diane_Merritt_4"
		}, {
			name: "Mark Harvilla",
			image: "images/avatar_default_image.jpg",
			id: "avatar_Mark_Harvilla_3"
		}, {
			name: "Aanji",
			image: "images/avatar_default_image.jpg",
			id: "43"
		}, {
			name: "ConnieOTAP",
			image: "images/avatar_default_image.jpg",
			id: "32"
		}]
	});
});
/*
	Transform recorded audio into specified voice
	req: sourceAvatarId (int)
	req: targetAvatarId (string)   [ex: avatar_Angelina_Jolie_1]
	req: file (filename=blob wav blob)
 */
app.post('/morphing/MorphingServlet', function (req, res) {
	setTimeout(function () {
		res.json({
			result: "success"
		});
	}, 500);
});




var server = app.listen(3000, function () {

	var host = server.address().address;
	var port = server.address().port;

	console.log('Example app listening at http://%s:%s', host, port);

});