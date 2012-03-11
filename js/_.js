var modules = [];
var apiURL = "http://jachapmanii.net/api/"
window.onload = setup;

function setup() {
	for(var i = 0; i < modules.length; ++i)
		modules[i]();
}

function _() {
	var sbox = document.getElementById("status-box");
	if(sbox == null)
		return;
	sbox.style.visiblity = 'hidden';
	sbox.innerHTML = " ";

	var xhr = new XMLHttpRequest();
	xhr.open('POST', apiURL + "status", true);
	xhr.onreadystatechange = function(xhrEvent) {
		if(xhr.readyState != 4)
			return;
		if(xhr.status != 200)
			return;

		var json = xhr.responseText;
		var jobj = JSON.parse(json, false);

		if(jobj.error)
			sbox.innerHTML = '<p class="error">' + jobj.error + '</p>';
		else {
			var ihtml = '<div class="status-head">';
			if(jobj.date)
				ihtml += '<span class="sdt">' + jobj.date + ' -- </span>';
			else
				ihtml += '<span class="sdt">Status -- </span> ';
			ihtml += '<span class="status">' + jobj.status + '</span>';
			ihtml += '</div>';
			sbox.innerHTML = ihtml;
			sbox.style.visiblity = 'visible';
		}
	};
	xhr.send(null);
}
modules.push(_);


