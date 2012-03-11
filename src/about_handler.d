import std.xml;
import std.file;
import std.string;

static const string URL_PREFIX = "about/";
static const string URL_BASE = "http://jachapmanii.net/";
static const string ABOUT_FILE = "about";

Element aboutHandler(string URL, ref string headers) {
	headers = "Cache-control: max-age=3600\n";
	Element mMBody = new Element("div");
		mMBody.tag.attr["class"] = "mcol";
	Element mBody = new Element("div");
		mBody.tag.attr["class"] = "scol";
	mMBody ~= mBody;

	if(!isFile(ABOUT_FILE)) {
		mBody ~= new Element("p", "The about page is missing.");
		return mMBody;
	}

	mBody ~= dumpFile(ABOUT_FILE);
	return mMBody;
}

Element dumpFile(string filename, string dclass = "me") {
	if(!exists(filename))
		return new Element("p", "File \"" ~ filename ~ "\" does not exist");

	string file = "<div class=\"" ~ dclass ~ "\">";
	foreach(line; splitLines(readText(filename)))
		file ~= line;
	file ~= "</div>";

	try {
		check(file);
		return new Document(file);
	} catch(CheckException e) {
		return new Element("p", "Document \"" ~ filename ~ "\" is malformed :(");
	}
}

