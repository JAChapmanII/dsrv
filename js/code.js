
function getElementsByClassName(className, tagType) {
	var hasClass = new RegExp("(?:^|\\s)" + className + "(?:$|\\s)");
	if(tagType == null)
		tagType = "*";
	var tags = document.getElementsByTagName(tagType);
	var matches = [];

	for(var i = 0; i < tags.length; ++i) {
		var cclass = tags[i].className;
		if(cclass && (cclass.indexOf(className) != -1) && hasClass.test(cclass))
			matches.push(tags[i]);
	}
	return matches;
}

function jsonToPreContent(str) {
	str = str.replace(/\n/g, '\n');
	return str;
}

function fillReadme(readmeBox, readme) {
	if(!readmeBoxen || !readme)
		return;
	if(readme.error) {
		var errorComment = document.createElement("p");
		errorComment.innerHTML = "Error retrieving README: " + readme.error;
		readmeBox.parentNode.insertBefore(errorComment, readmeBox.nextSibling);
		//readmeBox.style.visiblity = 'hidden';
		//readmeBox.style.display = 'none';
		return;
	}
	var contentPre = document.createElement("pre");
	contentPre.innerHTML = jsonToPreContent(readme.contents);
	contentPre.className = "readme";
	readmeBox.parentNode.insertBefore(contentPre, readmeBox.nextSibling);
	var readmeP = document.createElement("p");
	readmeP.innerHTML = "README:";
	readmeBox.parentNode.insertBefore(readmeP, contentPre);
}

function code() {
	readmeBoxen = getElementsByClassName("dsrv.readme", "div");
	if(readmeBoxen.length > 0) {
		var xhr = new XMLHttpRequest();
		xhr.open('POST', apiURL + "cat/" + readmeBoxen[0].title + "/master/README", true);
		xhr.onreadystatechange = function(xhrEvent) {
			if(xhr.readyState != 4)
				return;
			if(xhr.status != 200)
				return;

			for(var i = 0; i < readmeBoxen.length; ++i)
				fillReadme(readmeBoxen[i], JSON.parse(xhr.responseText, false));
		};
		xhr.send(null);
	}

	fileListBoxen = getElementsByClassName("fileList", "div");
	for(var i = 0; i < fileListBoxen.length; ++i)
		fileListBoxen[i].style.visibilty = 'hidden';

	//alert(document.URL);
}
modules.push(code);

