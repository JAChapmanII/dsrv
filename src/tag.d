import std.stdio;
import std.conv;

class Tag {
	public:
		this(bool isSingle = false) {
			this.start = "";
			this.single = isSingle;
			this.end = "";
			this.content = "";
		}

		void print(string indent = "") {
			if((this._content.length > 0) &&
				(this.subTags.length == 0)) {
				writeln(indent ~ "<" ~ this.start ~ ">" ~
						this._content ~ "<" ~ this.end ~ ">");
				return;
			}
			write(indent ~ "<" ~ this.start);
			if(this.attributes.length > 0) {
				foreach(key; this.attributes.keys)
					write(" " ~ key  ~ "=\"" ~ this.attributes[key] ~ "\"");
			}
			if(this.single) {
				writeln(" />");
				return;
			}
			writeln(">");
			if(this._content.length > 0)
				writeln(indent ~ indent ~ this._content);

			foreach(tag; this.subTags)
				tag.print(indent ~ "  ");

			writeln(indent ~ "<" ~ this.end ~ ">");
		}

		void add(Tag nTag) {
			this.subTags ~= nTag;
		}

		Tag content(string nContent) {
			this._content = nContent;
			return this;
		}

	protected:
		string start;
		bool single;
		string end;
		string[string] attributes;
		string _content;
		Tag[] subTags;
}

class HTML : Tag {
	public:
		this() {
			super();

			this.start = "?xml version = \"1.0\" encoding = \"utf-8\" ?>\n"
				"<!DOCTYPE html\n" ~
					"\tPUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n" ~
					"\t\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n\n" ~
				"<html";
			this.attributes["xmlns"] = "http://www.w3.org/1999/xhtml";
			this.attributes["xml:lang"] = "en";
			this.attributes["lang"] = "en";
			this.end = "/html";
		}
}

class Head : Tag {
	public:
		this() {
			super();

			this.start = "head";
			this.end = "/head";
		}
}

class Meta : Tag {
	public:
		this() {
			super(true);

			this.start = "meta";
			this.attributes["http-equiv"] = "Content-type";
			this.attributes["content"] = "text/html; charset=UTF-8";
		}
}

class Title : Tag {
	public:
		this() {
			super();

			this.start = "title";
			this.end = "/title";
		}
}

class Body : Tag {
	public:
		this() {
			super();

			this.start = "body";
			this.end = "/body";
		}
}

class Heading : Tag {
	public:
		this(int iLevel) {
			super();

			this.start = "h" ~ toImpl!(string)(iLevel);
			this.end = "/h" ~ toImpl!(string)(iLevel);
		}
}

class Paragrah : Tag {
	public:
		this() {
			super();

			this.start = "p";
			this.end = "/p";
		}
}

class UnorderedList : Tag {
	public:
		this() {
			super();

			this.start = "ul";
			this.end = "/ul";
		}
}

class OrderedList : Tag {
	public:
		this() {
			super();

			this.start = "ol";
			this.end = "/ol";
		}
}

class ListElement : Tag {
	public:
		this() {
			super();

			this.start = "li";
			this.end = "/li";
		}
}

