import std.xml;

Element codeHandler(string URL) {
	Element mMColumn = new Element("div");
	mMColumn.tag.attr["class"] = "mcol";
	Element mBody = new Element("div");
	mBody.tag.attr["class"] = "scol";

	mBody ~= new Element("h3", URL);

	mMColumn ~= mBody;
	return mMColumn;
}

