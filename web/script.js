	var request;

	function getInfo() {

		var url = "/msg";

		if (window.XMLHttpRequest) {
			request = new XMLHttpRequest();
		}
		else if (window.ActiveXObject) {
			request = new ActiveXObject("Microsoft.XMLHTTP");
		}

		try {
			request.onreadystatechange = processInfo;
			request.open("GET", url, true);
			request.send();
		}
		catch (e) {
			alert("Unable to connect to server");
		}
	}

	function processInfo() {
		if (request.readyState == 4) {
			var val = request.responseText;
			document.getElementById('info').innerHTML = val;
      setTimeout(getInfo, 2000);
		}
	}

setTimeout(getInfo, 2000);
