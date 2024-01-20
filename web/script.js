	var request;

	function getInfo() {

		var url = "/msg.html";

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
			document.location.reload();
		}
	}

	function processInfo() {
		if (request.readyState == 4) {
			var val = request.responseText;
			if( val != null && val.length != 0 ) {
			  document.getElementById('info').innerHTML = val;
			  setTimeout(getInfo, 2000);
			} else {
			  document.location.reload();
			}
		}
	}

setTimeout(getInfo, 2000);
//setTimeout(() => { document.location.reload(); }, 60000);
