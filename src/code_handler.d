import std.xml;

Element codeHandler(string URL) {
	Element mBody = new Element("div");
	mBody.tag.attr["class"] = "mcol";

	mBody ~= new Element("h3", URL);

	return mBody;
}

