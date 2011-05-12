import std.stdio;
import std.process;
import std.array;
import std.conv;

import tag;

void main(string[] args) {
	writeln("Content-type: text/html\n");

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
		string sanitized = replace(queryString, "&", "&amp;");
		mBody.add((new Paragrah()).content =
				"QUERY_STRING: " ~ sanitized);

		queryString = replace(queryString, "&", " ");
		string[] tokens = split(queryString);

		OrderedList ol = new OrderedList();
		foreach(token; tokens) {
			token = replace(token, "=", " ");
			string[] fields = split(token);
			string key = fields[0], value;
			if(fields.length > 1)
				value = fields[1];
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

		mHTML.add(mBody);
	mHTML.print();
}

