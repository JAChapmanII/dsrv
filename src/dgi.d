import std.stdio;
import std.process;
import std.array;
import std.uri;
import core.time;

import std.xml;
import std.regex;

import std.file, std.string;

import about_handler, code_handler, update_handler;

static const string CSS_FILE = "style.css";
static const string URL_BASE = "http://jachapmanii.net/~jac/";
static const string ADMIN_EMAIL = "jac@JAChapmanII.net";

// Compact a string containing valid CSS
string compactifyCSS(string CSS) { //{{{
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
			if(!key.length || !value.length)
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
			ul ~= new Element("li", key ~ " -> " ~ fieldMap[key]);
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
	Element aboutLink = new Element("a", "About");
		aboutLink.tag.attr["href"] = URL_BASE ~ "about";
	Element codeLink = new Element("a", "Code");
		codeLink.tag.attr["href"] = URL_BASE ~ "code";
	Element contactLink = new Element("a", "Contact");
		contactLink.tag.attr["href"] = "mailto:" ~ ADMIN_EMAIL;
	Element hValidatorLink = new Element("a", "Validate HTML");
		hValidatorLink.tag.attr["href"] = hValidatorBase ~ URL_BASE ~ URL;
	Element cValidatorLink = new Element("a", "Validate CSS");
		cValidatorLink.tag.attr["href"] = cValidatorBase ~ URL_BASE ~ URL;

	header ~= homeLink; header ~= tab;
	header ~= aboutLink; header ~= tab;
	header ~= codeLink; header ~= tab;
	header ~= contactLink; header ~= tab;
	header ~= hValidatorLink; header ~= tab;
	header ~= cValidatorLink;

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

	writeln("Content-type: text/html\n");

	writeln("<?xml version = \"1.0\" encoding = \"utf-8\" ?>\n" ~
		"<!DOCTYPE html\n" ~
		"\tPUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n" ~
		"\t\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">");

	Handler[] handlers;
	handlers ~= Handler(r"^$", &updateHandler);
	handlers ~= Handler(r"^about/", &aboutHandler);
	handlers ~= Handler(r"^about$", &aboutHandler);
	handlers ~= Handler(r"^code/", &codeHandler);
	handlers ~= Handler(r"^code$", &codeHandler);
	handlers ~= Handler(r"^update/", &updateHandler);
	handlers ~= Handler(r"^update$", &updateHandler);

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
			Element mStyle = new Element("link");
				mStyle.tag.attr["rel"] = "stylesheet";
				mStyle.tag.attr["type"] = "text/css";
				mStyle.tag.attr["href"] = URL_BASE ~ CSS_FILE;
			mHead ~= mStyle;
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

		writeln(join(mHTML.pretty(2), "\n"));
	} catch(Exception e) {
		writeln(getDefaultErrorPage());
		writeln("<!-- " ~ e.toString() ~ " -->");
	}
	writeln("<!-- ", (TickDuration.currSystemTick() - start).msecs(), " -->");
}

