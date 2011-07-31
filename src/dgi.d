import std.stdio;
import std.process;
import std.array;
import std.uri;
import core.time;

import std.xml;
import std.regex;

import std.file, std.string;

import std.datetime, std.conv, std.algorithm;

import about_handler, code_handler, update_handler;
import update;

static const string URL_BASE = "http://jachapmanii.net/";
static const string ADMIN_EMAIL = "jac@JAChapmanII.net";

static const string UPDATES_RSS_FILE = "updates.rss";
static const string FAVICON_ICO_FILE = "favicon.ico";

static const string CSS_FILE = "style.css";
static const string JS_FILE = "js/main.js";
static const string JQUERY_FILE = "js/jquery-1.6.2.min.js";
static const string JQUERYUI_FILE = "js/jquery-ui-1.8.14.custom.min.js";
static const string JQUERYCSS_FILE = "css/jac/jquery-ui-1.8.14.custom.css";

// Compact a string containing valid CSS
string compactifyCSS(string CSS) { //{{{
	CSS = replace(CSS, regex(r"\/\*([^\*]*[^\/])*\*\/", "g"), "");

	CSS = replace(CSS, regex(r"^\s+"), "");
	CSS = replace(CSS, regex(r"\s+$"), "");
	CSS = replace(CSS, regex(r"\s+", "g"), " ");
	CSS = replace(CSS, regex(r"\s*;\s*", "g"), ";");
	CSS = replace(CSS, regex(r"\s*:\s*", "g"), ":");
	CSS = replace(CSS, regex(r"\s*\}\s*", "g"), "}");
	CSS = replace(CSS, regex(r"\s*\{\s*", "g"), "{");
	CSS = replace(CSS, regex(r";\}", "g"), "}");
	return CSS;
} //}}}

struct Handler {
	string r;
	Element function(string) h;

	this(string iR, Element function(string) iH) {
		r = iR, h = iH;
	}
}

string getDefaultErrorPage() {
	return import("derror-page");
}

static string[string] fieldMap;
// Generates the fieldMap made of parsed QUERY_STRING data
static void generateFieldMap() { //{{{
	fieldMap["__path__"] = "";
	string queryString = getenv("QUERY_STRING");
	fieldMap["QUERY_STRING"] = decodeComponent(queryString);
	if(queryString.length > 0) {
		string[] tokens = split(queryString, "&");

		foreach(token; tokens) {
			string[] fields = split(token, "=");
			string key = decodeComponent(fields[0]), value;
			if(fields.length > 1)
				value = decodeComponent(fields[1]);
			if(!key.length)
				continue;
			fieldMap[key] = value;
		}
	}
} //}}}

// Load and compact the CSS from CSS_FILE
string getCSS() { //{{{
	string CSS = "";
	if(isFile(CSS_FILE)) {
		foreach(line; splitlines(readText(CSS_FILE)))
			CSS ~= line ~ "\n";
	}
	CSS = compactifyCSS(CSS);
	return CSS;
} //}}}

// Generate basic informative body
Element defaultHandler(string URL) { //{{{
	Element mMColumn = new Element("div");
	mMColumn.tag.attr["class"] = "mcol";
	Element mBody = new Element("div");
	mBody.tag.attr["class"] = "scol";
	mBody ~= new Element("h3", "Welcome to DGI!");
	mBody ~= new Element("p", "A paragraph :D !");

	if(fieldMap.length > 0) {
		mBody ~= new Element("p", "fieldMap: ");
		Element ul = new Element("ul");
		foreach(key; fieldMap.keys)
			ul ~= new Element("li", key ~ 
					((fieldMap[key].length) ? " -> " : " ") ~ fieldMap[key]);
		mBody ~= ul;
	}

	if("name" in fieldMap)
		mBody ~= new Element("p", "Hello there, " ~ fieldMap["name"] ~ "!");

	mBody ~= new Element("p",
			"This is roughly 223 lines of D code. This includes a standard" ~
			" header generation function along with the same for the footer," ~
			" a basic CSS compacter and lots of error handling. So far the" ~
			" update sub-folder of this site is roughly another 100 or so" ~
			" lines. D is really awesome, the the only detriment to using it" ~
			" is the fact that the compiled binary is pretty hefty" ~
			" (~1.5 MiB O.o)");
	mBody ~= new Element("p",
			"Most of the above is out of date haha ;). The entire shebang is" ~
			" now weighing in around 750 lines with several modules including" ~
			" the cool and upcoming code stuff. I just made a rewrite rule to" ~
			" redirect all non-home directory traffic here so I can figure out" ~
			" what to do with the PHP thing later.");
	mBody ~= new Element("p", "Apparently, something defaults to requesting" ~
			" index.html or similar (according to the path we were given, " ~
			fieldMap["__path__"] ~ "), which is why you are here and not on my" ~
			" post list. Since this CGI program handles everything without" ~
			" saying \"404 - File not Found\" you could get here in an"
			" infinite number of ways :D [barring limitations to URL length in" ~
			" the HTML standard, apache, or some limit on environment variable" ~
			" length imposed somewhere in POSIX or linux or somethnig ;)]");
	Element mainLink = new Element("a", "Go to the update list");
		mainLink.tag.attr["href"] = URL_BASE;
	mBody ~= mainLink;

	mMColumn ~= mBody;
	return mMColumn;
} //}}}

// Generate the header div
Element getHeader(string URL) { //{{{
	string hValidatorBase = "http://validator.w3.org/check?uri=";
	string cValidatorBase = "http://jigsaw.w3.org/css-validator/validator?uri=";
	string spaces = "&#160;"; spaces ~= spaces; spaces ~= spaces;
	Document tab = new Document("<span>" ~ spaces ~ "</span>");

	Element headerContanier = new Element("div");
	headerContanier.tag.attr["class"] = "hnavbar";

	Element header = new Element("p");
	Element homeLink = new Element("a", "Home");
		homeLink.tag.attr["href"] = URL_BASE;
	Element updatesLink = new Element("a", "Updates");
		updatesLink.tag.attr["href"] = URL_BASE ~ "updates";
	Element rssLink = new Element("a", "RSS Feed");
		rssLink.tag.attr["href"] = URL_BASE ~ UPDATES_RSS_FILE;
	Element aboutLink = new Element("a", "About");
		aboutLink.tag.attr["href"] = URL_BASE ~ "about";
	Element codeLink = new Element("a", "Code");
		codeLink.tag.attr["href"] = URL_BASE ~ "code";
	Element contactLink = new Element("a", "Contact");
		contactLink.tag.attr["href"] = "mailto:" ~ ADMIN_EMAIL;

	header ~= homeLink; header ~= tab;
	header ~= updatesLink; header ~= tab;
	header ~= rssLink; header ~= tab;
	header ~= aboutLink; header ~= tab;
	header ~= codeLink; header ~= tab;
	header ~= contactLink;


	header ~= new Comment("Validate HTML: " ~ hValidatorBase ~ URL_BASE ~ URL ~
		"\n    Validate CSS: " ~ cValidatorBase ~ URL_BASE ~ URL ~ "\n");

	headerContanier ~= header;
	return headerContanier;
} //}}}

// Generate the footer div
Element getFooter(string URL) { //{{{
	Element footerContainer = new Element("div");
	footerContainer.tag.attr["class"] = "ffooter";

	Element footer = new Element("p");
	footer ~= new Text("If you need to get a hold of me for whatever reason," ~
			" simply drop me a line: ");
	Element mailto = new Element("a");
	mailto.tag.attr["href"] = "mailto:" ~ ADMIN_EMAIL;
	mailto ~= new Text(ADMIN_EMAIL);
	footer ~= mailto;

	footerContainer ~= footer;
	return footerContainer;
} //}}}

Element getUpdatesRSS() {
	Element rss = new Element("rss");
		rss.tag.attr["version"] = "2.0";

	Update[] updates = Update.parseUDates(); reverse(updates);
	Element channel = new Element("channel");
		channel ~= new Element("title", "~jac updates");
		channel ~= new Element("description", "Updates from Jeff Chapman");
		channel ~= new Element("link", URL_BASE);
		channel ~= new Element("lastBuildDate",
				updates[0].date ~ " " ~ updates[0].time);
		channel ~= new Element("pubDate", 
				updates[0].date ~ " " ~ updates[0].time);

	foreach(i, update; updates) {
		Element uItem = new Element("item");
		uItem ~= new Element("title", update.title);
		uItem ~= new Element("description", update.title);
		uItem ~= new Element("link",
				URL_BASE ~ "updates/" ~ to!string(update.number));
		uItem ~= new Element("guid", to!string(update.number));
		uItem ~= new Element("pubDate", update.date ~ " " ~ update.time);
		channel ~= uItem;
	}
	rss ~= channel;
	return rss;
}

void main(string[] args) {
	TickDuration start = TickDuration.currSystemTick();

	// process QUERY_STRING
	generateFieldMap();

	if((args.length > 1) || (fieldMap["__path__"] == CSS_FILE)) {
		writeln("Content-type: text/css\n");
		writeln(getCSS());
		writeln("/* ", (TickDuration.currSystemTick() - start).msecs(), " */");
		return;
	}
	if((args.length > 2) || (fieldMap["__path__"] == UPDATES_RSS_FILE)) {
		writeln("Content-type: application/rss+xml\n");
		writeln("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n");
		Element updatesRSS = getUpdatesRSS();
		writeln(replace(
					join(updatesRSS.pretty(2), "\n"), regex(r"\0", "g"), "\\0"));
		writeln("<!-- ", (TickDuration.currSystemTick() - start).msecs(), " -->");
		return;
	}
	if(exists(fieldMap["__path__"])) {
		bool good = true;
		if((endsWith(fieldMap["__path__"], ".png")) ||
			(endsWith(fieldMap["__path__"], ".ico"))) {
			writeln("Content-type: image/png\n");
		} else if(endsWith(fieldMap["__path__"], ".js")) {
			writeln("Content-type: text/javascript\n");
		} else if(endsWith(fieldMap["__path__"], ".css")) {
			writeln("Content-type: text/css\n");
		} else {
			good = false;
		}
		if(good) {
			auto bytes = cast(ubyte[]) read(fieldMap["__path__"], 1024*128);
			writef("%r", bytes);
			return;
		}
	}

	writeln("Content-type: text/html\n");

	writeln("<?xml version = \"1.0\" encoding = \"utf-8\" ?>\n" ~
		"<!DOCTYPE html\n" ~
		"\tPUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n" ~
		"\t\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">");

	Handler[] handlers;
	handlers ~= Handler(r"^$", &updateHandler);
	handlers ~= Handler(r"^index.html$", &updateHandler);
	handlers ~= Handler(r"^about/", &aboutHandler);
	handlers ~= Handler(r"^about$", &aboutHandler);
	handlers ~= Handler(r"^code/", &codeHandler);
	handlers ~= Handler(r"^code$", &codeHandler);
	handlers ~= Handler(r"^updates?/", &updateHandler);
	handlers ~= Handler(r"^updates?$", &updateHandler);

	try {
		// create html tag
		Element mHTML = new Element("html");
		mHTML.tag.attr["xmlns"] = "http://www.w3.org/1999/xhtml";
		mHTML.tag.attr["xml:lang"] = "en";
		mHTML.tag.attr["lang"] = "en";

		// create basics of a head
		Element mHead = new Element("head");
			Element mMeta = new Element("meta");
				mMeta.tag.attr["http-equiv"] = "Content-type";
				mMeta.tag.attr["content"] = "text/html; charset=UTF-8";
			mHead ~= mMeta;
			mHead ~= new Element("title", "~jac");
			// JQuery and JQuery UI {{{
			Element mJQueryCSS = new Element("link");
				mJQueryCSS.tag.attr["rel"] = "stylesheet";
				mJQueryCSS.tag.attr["type"] = "text/css";
				mJQueryCSS.tag.attr["href"] = URL_BASE ~ JQUERYCSS_FILE;
			Element mJQuery = new Element("script", " ");
				mJQuery.tag.attr["type"] = "text/javascript";
				mJQuery.tag.attr["src"] = URL_BASE ~ JQUERY_FILE;
			Element mJQueryUI = new Element("script", " ");
				mJQueryUI.tag.attr["type"] = "text/javascript";
				mJQueryUI.tag.attr["src"] = URL_BASE ~ JQUERYUI_FILE;

			mHead ~= mJQueryCSS;
			mHead ~= mJQuery;
			mHead ~= mJQueryUI;
			// }}}
			Element mStyle = new Element("link");
				mStyle.tag.attr["rel"] = "stylesheet";
				mStyle.tag.attr["type"] = "text/css";
				mStyle.tag.attr["href"] = URL_BASE ~ CSS_FILE;
			mHead ~= mStyle;
			Element mJS = new Element("script", " ");
				mJS.tag.attr["type"] = "text/javascript";
				mJS.tag.attr["src"] = URL_BASE ~ JS_FILE;
			mHead ~= mJS;
		mHTML ~= mHead;


		Element function(string) handleURL = &defaultHandler;

		foreach(handler; handlers) {
			auto m = match(fieldMap["__path__"], regex(handler.r, "i"));
			if(!m.empty())
				handleURL = handler.h;
		}

		Element mBody = new Element("body");
			mBody ~= getHeader(fieldMap["__path__"]);
			mBody ~= handleURL(fieldMap["__path__"]);
			mBody ~= getFooter(fieldMap["__path__"]);
		mHTML ~= mBody;

		writeln(replace(join(mHTML.pretty(2), "\n"), regex(r"\0", "g"), "\\0"));
	} catch(Exception e) {
		writeln(getDefaultErrorPage());
		writeln("<!-- " ~ e.toString() ~ " -->");
	}
	writeln("<!-- ", (TickDuration.currSystemTick() - start).msecs(), " -->");
}

