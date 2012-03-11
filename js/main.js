var tabs = new Array();
var tabList;

function mainModule() {
	var divs = document.getElementsByTagName("DIV");
	for(var i = 0; i < divs.length; ++i)
		if(divs[i].className.indexOf("tabbox") != -1)
			initTabs(divs[i]);
}
modules.push(mainModule);

function initTabs(tabbox) {
	var children = tabbox.childNodes;
	for(var i = 0; i < children.length; ++i) {
		if((children[i].nodeName == "DIV") &&
			(children[i].className == "tab"))
			tabs.push(children[i]);
	}

	tabList = document.createElement("ul");
	tabList.className = "tablist";
	for(var i = 0; i < tabs.length; ++i) {
		var tabLI = document.createElement("li");
		var tabA = document.createElement("a");

		tabLI.className = "unselected";
		if(i != 0)
			tabs[i].className = "tab hidden";
		else
			tabLI.className = "selected";

		tabA.href = "#" + i;
		tabA.onclick = showTab;
		tabA.appendChild(document.createTextNode(tabs[i].title));
		tabLI.appendChild(tabA);
		tabList.appendChild(tabLI);
	}
	tabbox.insertBefore(tabList, tabs[0]);
}

function showTab(n) {
	for(var i = 0; i < tabs.length; ++i) {
		tabs[i].className = "tab hidden";
		tabList.childNodes[i].className = "unselected";
	}
	var active = this.getAttribute('href').substr(1);
	tabs[active].className = "tab";
	tabList.childNodes[active].className = "selected";
	return false;
}

