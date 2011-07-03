import std.stdio;
import std.process;
import std.array;
import std.uri;

import std.xml;

void main(string[] args) {
	writeln("Content-type: text/html\n");

	Element mHTML = new Element("html");
	mHTML.tag.attr["xmlns"] = "http://www.w3.org/1999/xhtml";
	mHTML.tag.attr["xml:lang"] = "en";
	mHTML.tag.attr["lang"] = "en";

	Element mHead = new Element("head");
		Element mMeta = new Element("meta");
			mMeta.tag.attr["http-equiv"] = "Content-type";
			mMeta.tag.attr["content"] = "text/html; charset=UTF-8";
		mHead ~= mMeta;
		mHead ~= new Element("title", "D CGI script");
		Element mStyle = new Element("style");
		mHead ~= mStyle;
	mHTML ~= mHead;
	Element mTBody = new Element("body");
		Element mBody = new Element("div");
	mTBody ~= mBody;
		mBody.tag.attr["class"] = "mcol";
		mBody ~= new Element("h3", "Welcome to DGI!");
		mBody ~= new Element("p", "A paragraph :D !");
	mHTML ~= mTBody;

	mStyle.tag.attr["type"] = "text/css";
	mStyle ~= new Text(
			".mcol { width:860px; margin:0 auto; background: #fff; " ~
			" border: 1px solid #ccc; padding:20px }" ~
			"h3 { text-align: center }" ~
			"p { text-align: justify }" ~
			"body { background: #eee }");


	string[string] fieldMap;
	string queryString = getenv("QUERY_STRING");
	if(queryString.length > 0) {
		string sanitized = decodeComponent(queryString);
		mBody ~= new Element("p", "QUERY_STRING: " ~ sanitized);

		queryString = replace(queryString, "&", " ");
		string[] tokens = split(queryString);

		Element ol = new Element("ol");
		foreach(token; tokens) {
			token = replace(token, "=", " ");
			string[] fields = split(token);
			string key = decodeComponent(fields[0]), value;
			if(fields.length > 1)
				value = decodeComponent(fields[1]);
			bool insert = true;
			if(!key.length) {
				key = "[EMPTY]";
				insert = false;
			}
			if(!value.length) {
				value = "[EMPTY]";
				insert = false;
			}
			if(insert)
				fieldMap[key] = value;

			ol ~= new Element("li", key ~ " -> " ~ value);
		}
		mBody ~= ol;
	}

	string name;
	if(fieldMap.length > 0) {
		mBody ~= new Element("p", "fieldMap: ");
		Element ul = new Element("ul");
		foreach(key; fieldMap.keys) {
			if(key == "name")
				name = fieldMap[key];
			ul ~= new Element("li", key ~ " -> " ~ fieldMap[key]);
		}
		mBody ~= ul;
	}

	if(name.length > 0)
		mBody ~= new Element("p", "Hello there, " ~ name ~ "!");

	mBody ~= new Element("p",
			"This is roughly 90 lines of D code. D is really awesome, the" ~
			" the only detriment to using it is the fact that the compiled" ~
			" binary is ~1MiB O.o");

	writeln("<?xml version = \"1.0\" encoding = \"utf-8\" ?>\n" ~
		"<!DOCTYPE html\n" ~
		"\tPUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n" ~
		"\t\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">");

	writefln(join(mHTML.pretty(3), "\n"));
}

