
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

function find(array, value) {
	for(var i = 0; i < array.length; ++i)
		if(array[i] == value)
			return i;
	return -1;
}

function getArgument(index) { // {{{
	var parts = document.URL.split("/");
	var codeLoc = find(parts, "code");
	if(codeLoc == -1)
		return null;
	if(parts.size <= codeLoc + index)
		return null;
	return parts[codeLoc + index];
} // }}}
function getRepository() {
	return getArgument(1);
}
function getCommand() {
	return getArgument(2);
}

function getLanguage() {
	return getElementsByClassName("dsrv.language")[0].title;
}
function getBranch() {
	return getElementsByClassName("dsrv.branch")[0].title;
}



// Undo the escaping done by dsrv to files stored in a json string
function jsonUnEscape(str) { // {{{
	str = str.replace(/\"/g, '"');
	str = str.replace(/\t/g, '\t');
	str = str.replace(/\n/g, '\n');
	// TODO: actually replaces literal \\ ?
	str = str.replace(/\\/g, '\\');
	return str;
} // }}}

// Fill in a README box with a readme, display error if not silentFail
function fillReadme(readmeBox, readme, silentFail) { // {{{
	if(!readmeBox || !readme)
		return;
	if(readme.error) {
		if(silentFail) {
			readmeBox.style.display = 'none';
		} else {
			var errorComment = document.createElement("p");
			errorComment.innerHTML = "Error retrieving README: " + readme.error;
			readmeBox.parentNode.insertBefore(errorComment, readmeBox.nextSibling);
		}
		return;
	}
	var contentPre = document.createElement("pre");
	contentPre.innerHTML = jsonUnEscape(readme.contents);
	contentPre.className = "readme";
	readmeBox.parentNode.insertBefore(contentPre, readmeBox.nextSibling);
	var readmeP = document.createElement("p");
	readmeP.innerHTML = "README:";
	readmeBox.parentNode.insertBefore(readmeP, contentPre);
} // }}}

// Find all divs which should be filled with README files, attempt to fill them
function handleREADMEs() { // {{{
	var readmeBoxen = getElementsByClassName("dsrv.readme", "div");
	if(readmeBoxen.length > 0) {
		var xhr = new XMLHttpRequest();
		var repository = getRepository(), branch = getBranch(), path = "";
		var request = repository + "/" + branch + "/" + path + "/README";
		if(path.length == 0)
			request = repository + "/" + branch + "/README";

		xhr.open('POST', apiURL + "cat/" + request, true);
		xhr.onreadystatechange = function(xhrEvent) {
			if(xhr.readyState != 4)
				return;
			if(xhr.status != 200)
				return;

			var readme = JSON.parse(xhr.responseText, false);
			for(var i = 0; i < readmeBoxen.length; ++i)
				fillReadme(readmeBoxen[i], readme, (path.length != 0));
		};
		xhr.send(null);
	}
} // }}}

function handleFileLists() { // {{{
	var fileListBoxen = getElementsByClassName("dsrv.fileList", "div");
	if(fileListBoxen.length > 0) {
		var xhr = new XMLHttpRequest();
		var repository = fileListBoxen[0].title, branch = "master", path = "";
		var request = repository + "/" + branch + "/" + path + "/README";
		if(path.length == 0)
			request = repository + "/" + branch + "/README";

		xhr.open('POST', apiURL + "cat/" + request, true);
		xhr.onreadystatechange = function(xhrEvent) {
			if(xhr.readyState != 4)
				return;
			if(xhr.status != 200)
				return;

			readme = JSON.parse(xhr.responseText, false);
			for(var i = 0; i < fileListBoxen.length; ++i)
				fileListBoxen[i].style.visibilty = 'hidden';
		};
		xhr.send(null);
	}
} // }}}

function code() {
	handleREADMEs();
	handleFileLists();
	// TODO: handle branches
	// TODO: commit listing
	// TODO: diff viewer

	//alert(document.URL);
}
modules.push(code);

