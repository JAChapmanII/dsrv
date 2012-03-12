
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
	var parts = document.URL.split("#")[0].split("/");
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
function getPath() {
	if(window.location.hash)
		return window.location.hash.substring(1);
	return "";
	if(document.URL.split("#").length < 2)
		return "";
	return document.URL.split("#")[1];
}


function htmlEscape(str) {
	str = str.toString();
	str = str.replace(/</g, "&lt;");
	str = str.replace(/>/g, "&gt;");
	return str;
}

// Undo the escaping done by dsrv to files stored in a json string
function jsonUnEscape(str) { // {{{
	str = str.toString();
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
	readmeBox.innerHTML = "";
	if(readme.error) {
		if(silentFail) {
			readmeBox.style.display = 'none';
		} else {
			var errorComment = document.createElement("p");
			errorComment.innerHTML = "Error retrieving README: " + readme.error;
			readmeBox.appendChild(errorComment);
		}
		return;
	}
	readmeBox.style.display = 'block';
	var readmeP = document.createElement("p");
	readmeP.innerHTML = "README:";
	readmeBox.appendChild(readmeP);
	var contentPre = document.createElement("pre");
	contentPre.innerHTML = jsonUnEscape(readme.contents);
	contentPre.className = "readme";
	readmeBox.appendChild(contentPre);
} // }}}

// Find all divs which should be filled with README files, attempt to fill them
function handleREADMEs() { // {{{
	var readmeBoxen = getElementsByClassName("dsrv.readme", "div");
	if(readmeBoxen.length > 0) {
		var xhr = new XMLHttpRequest();
		var repository = getRepository(), branch = getBranch(), path = getPath();
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

function fileViewerClick() {
	setTimeout("handleFileLists()",10);
	setTimeout("handleREADMEs()",20);
}

function generatePathDiv(path) {
	var pathDiv = document.createElement("p");
	pathDiv.style.display = "inline";

	var mainPage = document.createElement("a");
	mainPage.href = "#";
	mainPage.innerHTML = getRepository();
	mainPage.onclick = fileViewerClick;
	pathDiv.appendChild(mainPage);

	var ppieces = path.split("/");
	var bp = "";
	for(var i = 0; i < ppieces.length; ++i) {
		pathDiv.appendChild(document.createTextNode(" / "));

		bp += ppieces[i];
		var pLink = document.createElement("a");
		pLink.href = "#" + bp;
		pLink.innerHTML = ppieces[i];
		pLink.onclick = fileViewerClick;
		pathDiv.appendChild(pLink);
	}
	return pathDiv;
}

function fillFileListRow(row, file, fname) {
	console.log("fillFileListRow");
	//var tr = document.createElement("tr");

	var linkTD = document.createElement("td");
	var link = document.createElement("a");
	var path = getPath();
	link.href = "#" + path + fname;
	link.innerHTML = fname;
	link.onclick = fileViewerClick;
	linkTD.appendChild(link);

	var ageTD = document.createElement("td");
	var commitStringTD = document.createElement("td");
	if(file.error) {
		ageTD.innerHTML = "error";
		commitStringTD.innerHTML = "error: " + file.error;
	} else {
		ageTD.innerHTML = file.commit.relDate;
		commitStringTD.innerHTML = file.commit.subject;
	}

	row.innerHTML = "";
	row.appendChild(linkTD);
	row.appendChild(ageTD);
	row.appendChild(commitStringTD);
}

function callbackOnRow(row, fname) {
	var xhr = new XMLHttpRequest();
	var repository = getRepository(), branch = getBranch(), path = getPath();
	var request = repository + "/" + branch + "/" + path;
	if(path[path.length - 1] != "/");
		request += "/";
	request += fname;

	xhr.open('POST', apiURL + "file/" + request, true);
	xhr.onreadystatechange = function(xhrEvent) {
		if(xhr.readyState != 4)
			return;
		if(xhr.status != 200)
			return;

		file = JSON.parse(xhr.responseText, false);
		console.log("callbackOnRow, file.file: " + file.file);
		fillFileListRow(row, file, fname);
	};
	xhr.send(null);
}

function generateFileListTable(files, repository, branch) {
	var path = getPath();
	var table = document.createElement("table");
	var trs = [];
	for(var i = 0; i < files.length; ++i) {
		var tr = document.createElement("tr");
		trs.push(tr);

		var linkTD = document.createElement("td");
		var link = document.createElement("a");
		link.href = "#" + path + "/" + files[i];
		link.innerHTML = files[i];
		link.onclick = fileViewerClick;
		linkTD.appendChild(link);

		tr.appendChild(linkTD);

		var ageTD = document.createElement("td");
		ageTD.innerHTML = "...";
		tr.appendChild(ageTD);

		var commitStringTD = document.createElement("td");
		commitStringTD.innerHTML = "...";
		tr.appendChild(commitStringTD);

		table.appendChild(tr);
	}

	for(var i = 0; i < trs.length; ++i)
		callbackOnRow(trs[i], files[i]);

	return table;
}

function fillFileList(fileList, repository) {
	if(!fileList || !repository)
		return;
	fileList.innerHTML = "";
	if(repository.error) {
		var errorComment = document.createElement("p");
		errorComment.innerHTML = "Error retrieving file list: " + repository.error;
		fileList.appendChild(errorComment);
		return;
	}
	fileList.appendChild(generatePathDiv(getPath()));
	if(repository.contents instanceof Array) {
		fileList.appendChild(generateFileListTable(
				repository.contents, repository.name, repository.branch));
	} else {
		var contentPre = document.createElement("pre");
		contentPre.innerHTML = htmlEscape(jsonUnEscape(repository.contents));
		contentPre.className = "readme";
		fileList.appendChild(contentPre);
	}
}

function handleFileLists() { // {{{
	var fileListBoxen = getElementsByClassName("dsrv.fileList", "div");
	if(fileListBoxen.length > 0) {
		var xhr = new XMLHttpRequest();
		var repository = getRepository(), branch = getBranch(), path = getPath();
		var request = repository + "/" + branch + "/" + path;

		xhr.open('POST', apiURL + "cat/" + request, true);
		xhr.onreadystatechange = function(xhrEvent) {
			if(xhr.readyState != 4)
				return;
			if(xhr.status != 200)
				return;

			repository = JSON.parse(xhr.responseText, false);
			for(var i = 0; i < fileListBoxen.length; ++i)
				fillFileList(fileListBoxen[i], repository);
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

