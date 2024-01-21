var request;
var interval = 1000;

function getInfo() {

    var url = "/msg.html";

    if (window.XMLHttpRequest) {
        request = new XMLHttpRequest();
    } else if (window.ActiveXObject) {
        request = new ActiveXObject("Microsoft.XMLHTTP");
    }

    try {
        request.onreadystatechange = processInfo;
        request.open("GET", url, true);
        request.send();
    } catch (e) {
        var err = "Error: " + e.message;
        console.log(err);
        setError(err);
        reload();
    }
}

function processInfo() {
    try {
        if (request.readyState != 4) {
            return true;
        }

        var msg = request.responseText;
        if (msg == null || msg.length == 0) {
            setError("Lost connection");
            schedule();
            return false;
        }

        if (request.status == 200) {
            setInfo(msg);
            schedule();
            return true;
        }

        if (request.status == 404) {
            setInfo("Connecting to VNC", true);
            reload();
            return true;
        }

        setError("Error: Received status " + request.status);
        schedule();
        return false;

    } catch (e) {
        var err = "Error: " + e.message;
        console.log(err);
        setError(err);
        reload();
        return false;
    }
}

function setInfo(text, loading) {

    try {
        if (text == null || text.length == 0) {
            return false;
        }

        loading = !!loading;
        if (loading) {
            text = "<p class=\"loading\">" + text + "</p>"
        }

        var el = document.getElementById("info");

        if (el.innerHTML != text) {
            el.innerHTML = text;
        }
        
        el = document.getElementById("spinner");
        el.style.visibility = 'visible';
        
        return true;
        
    } catch (e) {
        console.log("Error: " + e.message);
        return false;
    }
}

function setError(text, loading) {

    try {
        if (text == null || text.length == 0) {
            return false;
        }

        var el = document.getElementById("info");

        if (el.innerHTML != text) {
            el.innerHTML = text;
        }
        
        el = document.getElementById("spinner");
        el.style.visibility = 'hidden';
        document.body.style.backgroundColor = "red";
        
        return true;
        
    } catch (e) {
        console.log("Error: " + e.message);
        return false;
    }
}

function schedule() {
    setTimeout(getInfo, interval);
}

function reload() {
    setTimeout(() => {
        document.location.reload();
    }, 2000);
}

setTimeout(getInfo, interval);
