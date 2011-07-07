import std.xml;
import std.file;
import std.string;

static const string ABOUT_FILE = "about";

Element aboutHandler(string URL) {
	Element mBody = new Element("div");
	mBody.tag.attr["class"] = "mcol";

	mBody ~= new Element("h3", "About");

	if(!isFile(ABOUT_FILE)) {
		mBody ~= new Element("p", "The about page is missing.");
		return mBody;
	}

	string aboutDoc = "<div class=\"scol\">";
	foreach(line; splitlines(readText(ABOUT_FILE)))
		aboutDoc ~= line;
	aboutDoc ~= "</div>";

	try {
		check(aboutDoc);
		mBody ~= new Document(aboutDoc);
	} catch(CheckException e) {
		mBody ~= new Element("p", "About document is malformed :(");
	}

	return mBody;
}

