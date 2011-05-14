import std.stdio;
import std.conv;

class Tag {
	public:
		this(bool isSingle = false) {
			this.single = isSingle;
		}

		void print(string indent = "") {
			if((this._content.length > 0) &&
				(this.subTags.length == 0)) {
				write(indent ~ "<" ~ this.start ~ ">" ~
						this._content);
				if(this.end.length == 0)
					writeln("</" ~ this.start ~ ">");
				else
					writeln("<" ~ this.end ~ ">");
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

			if(this.end.length == 0)
				writeln(indent ~ "</" ~ this.start ~ ">");
			else
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
			this.start = "html";
			this.attributes["xmlns"] = "http://www.w3.org/1999/xhtml";
			this.attributes["xml:lang"] = "en";
			this.attributes["lang"] = "en";
		}
}

class Head : Tag {
	public:
		this() {
			this.start = "head";
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
			this.start = "title";
		}
}

class Body : Tag {
	public:
		this() {
			this.start = "body";
		}
}

class Heading : Tag {
	public:
		this(int iLevel) {
			this.start = "h" ~ toImpl!(string)(iLevel);
		}
}

class Paragrah : Tag {
	public:
		this() {
			this.start = "p";
		}
}

class UnorderedList : Tag {
	public:
		this() {
			this.start = "ul";
		}
}

class OrderedList : Tag {
	public:
		this() {
			this.start = "ol";
		}
}

class ListElement : Tag {
	public:
		this() {
			this.start = "li";
		}
}

