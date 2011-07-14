import std.xml;
import std.file;
import std.string;

static const string URL_PREFIX = "about/";
static const string URL_BASE = "http://jachapmanii.net/";
static const string ABOUT_FILE = "about";

Element aboutHandler(string URL) {
	Element mMBody = new Element("div");
		mMBody.tag.attr["class"] = "mcol";
	Element mBody = new Element("div");
		mBody.tag.attr["class"] = "scol";
	mMBody ~= mBody;

	mBody ~= new Element("h3", "About");

	if(!isFile(ABOUT_FILE)) {
		mBody ~= new Element("p", "The about page is missing.");
		return mMBody;
	}

	mBody ~= dumpFile(ABOUT_FILE);

	Element links = new Element("p");
		links.tag.attr["style"] = "text-align:center";
	Element workLink = new Element("a", "Work");
		workLink.tag.attr["href"] = URL_BASE ~ URL_PREFIX ~ "work";
	Element hobbiesLink = new Element("a", "Hobbies");
		hobbiesLink.tag.attr["href"] = URL_BASE ~ URL_PREFIX ~ "hobbies";
	Element schoolLink = new Element("a", "School");
		schoolLink.tag.attr["href"] = URL_BASE ~ URL_PREFIX ~ "school";
	Element gradesLink = new Element("a", "Grades");
		gradesLink.tag.attr["href"] = URL_BASE ~ URL_PREFIX ~ "grades";

	string spaces = "&#160;"; spaces ~= spaces; spaces ~= spaces;
	Document tab = new Document("<span>" ~ spaces ~ "</span>");

	links ~= workLink; links ~= tab;
	links ~= hobbiesLink; links ~= tab;
	links ~= schoolLink; links ~= tab;
	links ~= gradesLink;
	mBody ~= links;

	string[] fields = split(URL, "/");
	if(fields.length > 1) {
		switch(fields[1]) {
			case "work":
				mBody ~= dumpFile(ABOUT_FILE ~ "_work");
				break;
			case "hobbies":
				mBody ~= dumpFile(ABOUT_FILE ~ "_hobbies");
				break;
			case "school":
				mBody ~= dumpFile(ABOUT_FILE ~ "_school");
				break;
			case "grades":
				mBody ~= dumpFile(ABOUT_FILE ~ "_grades");
				break;
			default:
				mBody ~= new Element("p", "Bad sub-URL");
		}
	}

	return mMBody;
}

Element dumpFile(string filename, string dclass = "me") {
	if(!exists(filename))
		return new Element("p", "File \"" ~ filename ~ "\" does not exist");

	string file = "<div class=\"" ~ dclass ~ "\">";
	foreach(line; splitlines(readText(filename)))
		file ~= line;
	file ~= "</div>";

	try {
		check(file);
		return new Document(file);
	} catch(CheckException e) {
		return new Element("p", "Document \"" ~ filename ~ "\" is malformed :(");
	}
}

