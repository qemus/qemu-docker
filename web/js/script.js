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
        console.log(e.message);
        setInfo(e.message);
        reload();
    }
}

function processInfo() {
    try {
        if (request.readyState != 4) {
            return true;
        }

        var val = request.responseText;
        if (val == null || val.length == 0) {
            setInfo("Empty response");
            reload();
            return false;
        }

        if (request.status == 200) {
            setInfo(val);
            schedule();
            return true;
        }

        if (request.status == 404) {
            setInfo("Connecting to web viewer", true);
            reload();
            return true;
        }

        setInfo("Status " + request.status);
        reload();
        return false;

    } catch (e) {
        console.log(e.message);
        setInfo(e.message);
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

        return true;
    } catch (e) {
        console.log(e.message);
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
//setTimeout(() => { document.location.reload(); }, 60000);
