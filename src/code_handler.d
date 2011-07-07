import std.xml;

import repository;

Element codeHandler(string URL) {
	Element mMColumn = new Element("div");
	mMColumn.tag.attr["class"] = "mcol";
	Element mBody = new Element("div");
	mBody.tag.attr["class"] = "scol";

	mBody ~= new Element("h3", URL);
	Repository[] repos = Repository.parseRepositories();
	if(!repos.length) {
		mBody ~= new Element("p", "There are no repositories");
	} else {
		Element rTable = new Element("table");
		foreach(repo; repos) {
			Element rRow = new Element("tr");
			rRow ~= new Document("<td>" ~ repo.language() ~ "&#160;&#160;</td>");
			rRow ~= new Document("<td>" ~ repo.name() ~ "&#160;&#160;</td>");
			rRow ~= new Element("td", repo.description());
			rTable ~= rRow;
		}
		mBody ~= rTable;
	}

	mMColumn ~= mBody;
	return mMColumn;
}

