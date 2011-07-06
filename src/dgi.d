import std.stdio;
import std.process;
import std.array;
import std.uri;

import std.xml;
import std.regex;

import code_handler, update_handler;

string compactifyCSS(string CSS) {
	CSS = replace(CSS, regex(r"^\s+"), "");
	CSS = replace(CSS, regex(r"\s+$"), "");
	CSS = replace(CSS, regex(r"\s+", "g"), " ");
	CSS = replace(CSS, regex(r"\s*;\s*", "g"), ";");
	CSS = replace(CSS, regex(r"\s*:\s*", "g"), ":");
	CSS = replace(CSS, regex(r"\s*\}\s*", "g"), "}");
	CSS = replace(CSS, regex(r"\s*\{\s*", "g"), "{");
	CSS = replace(CSS, regex(r";\}", "g"), "}");
	return CSS;
}

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
static void generateFieldMap() {
	string queryString = getenv("QUERY_STRING");
	if(queryString.length > 0) {
		queryString = replace(queryString, "&", " ");
		string[] tokens = split(queryString);

		foreach(token; tokens) {
			token = replace(token, "=", " ");
			string[] fields = split(token);
			string key = decodeComponent(fields[0]), value;
			if(fields.length > 1)
				value = decodeComponent(fields[1]);
			bool insert = true;
			if(!key.length || !value.length)
				continue;
			fieldMap[key] = value;
		}
	}
}

// Generate basic informative body
Element defaultHandler(string URL) {
	Element mBody = new Element("div");
	mBody.tag.attr["class"] = "mcol";
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
			"This is roughly 90 lines of D code. D is really awesome, the" ~
			" the only detriment to using it is the fact that the compiled" ~
			" binary is ~1MiB O.o");

	return mBody;
}

void main(string[] args) {
	writeln("Content-type: text/html\n");

	writeln("<?xml version = \"1.0\" encoding = \"utf-8\" ?>\n" ~
		"<!DOCTYPE html\n" ~
		"\tPUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n" ~
		"\t\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">");

	Handler[] handlers;
	handlers ~= Handler(r"^update/", &updateHandler);
	handlers ~= Handler(r"^code/", &codeHandler);

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
			Element mStyle = new Element("style");
			mHead ~= mStyle;
		mHTML ~= mHead;

		mStyle.tag.attr["type"] = "text/css";
		// This is compile time, not run time
		string CSS = import("style.css");
		// this is run time, not compile time >_>
		CSS = compactifyCSS(CSS);
		mStyle ~= new Text(CSS);

		// process QUERY_STRING
		generateFieldMap();

		Element mBody = new Element("body");
		
		Element function(string) handleURL = &defaultHandler;

		foreach(handler; handlers) {
			auto m = match(fieldMap["__path__"], regex(handler.r, "i"));
			if(!m.empty())
				handleURL = handler.h;
		}

		mBody ~= handleURL(fieldMap["__path__"]);
		mHTML ~= mBody;

		writefln(join(mHTML.pretty(2), "\n"));
	} catch(Exception e) {
		writeln(getDefaultErrorPage());
	}
}

