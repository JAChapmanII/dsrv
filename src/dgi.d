import std.stdio;
import std.process;
import std.array;
import std.conv;
import std.uri;

import tag;

void main(string[] args) {
	writeln("Content-type: text/html\n");
	writeln("<?xml version = \"1.0\" encoding = \"utf-8\" ?>\n" ~
		"<!DOCTYPE html\n" ~
			"\tPUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n" ~
			"\t\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n");

	HTML mHTML = new HTML();
		Head mHead = new Head();
			mHead.add(new Meta());
			mHead.add((new Title()).content =
				"D CGI script!");
		mHTML.add(mHead);
		Body mBody = new Body();
			mBody.add((new Heading(3)).content =
				"Welcome to DGI!");
			mBody.add((new Paragrah()).content =
				"A paragrpah!");

	string[string] fieldMap;
	string queryString = getenv("QUERY_STRING");
	if(queryString.length > 0) {
		string sanitized = decodeComponent(replace(queryString, "&", "&amp;"));
		mBody.add((new Paragrah()).content =
				"QUERY_STRING: " ~ sanitized);

		queryString = replace(queryString, "&", " ");
		string[] tokens = split(queryString);

		OrderedList ol = new OrderedList();
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

			ol.add((new ListElement()).content = key ~ " -&gt; " ~ value);
		}
		mBody.add(ol);
	}

	string name;
	if(fieldMap.length > 0) {
		mBody.add((new Paragrah()).content = "fieldMap: ");
		UnorderedList ul = new UnorderedList();
		foreach(key; fieldMap.keys) {
			if(key == "name")
				name = fieldMap[key];
			ul.add((new ListElement()).content =
					key ~ " -&gt; " ~ fieldMap[key]);
		}
		mBody.add(ul);
	}

	if(name.length > 0)
		mBody.add((new Paragrah()).content = "Hello there, " ~ name ~ "!");

	mBody.add((new Paragrah()).content =
			"This is roughly 80 lines of D code, not counting the rather" ~
			" hackish reimplementation of the whole XML library. I think by" ~
			" using that, it can be cut down even more. D is really awesome," ~
			" the only detriment to using it is the fact that the compiled" ~
			" binary is ~1MiB O.o");

		mHTML.add(mBody);
	mHTML.print();
}

