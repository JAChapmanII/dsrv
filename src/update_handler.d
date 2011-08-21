import std.xml;
import std.string;
import std.conv;
import std.regex;

import update;

static const string URL_BASE = "http://jachapmanii.net/";
static const string URL_PREFIX = "update/";

Element updateHandler(string URL, ref string headers) {
	Element mMColumn = new Element("div");
	mMColumn.tag.attr["class"] = "mcol";
	Element mBody = new Element("div");
	mBody.tag.attr["class"] = "scol";
	mMColumn ~= mBody;

	if(URL == "index.html")
		URL = "";
	if(URL == "updates")
		URL = "update";
	if((URL.length > 6) && (URL[6] == 's'))
		URL = URL[0..6] ~ URL[7..$];

	Element spacer = new Document("<p>&#160;</p>");
	spacer.tag.attr["style"] = "line-height:0;clear:both";

	Update[] updates = Update.parseUDates();
	if(!updates.length) {
		mBody ~= new Element("p", "There are no updates");
	} else {
		if(!URL.length) {
			long stop = updates.length - 3;
			if(stop < 0)
				stop = 0;
			for(long i = updates.length - 1; i >= stop; --i) {
				Element post;
				if(i == updates.length - 1)
					post = formatUpdate(updates[i], "update ubblue");
				else
					post = formatUpdate(updates[i], "update ubox");

				if(!(post is null))
					mBody ~= post;
			}
			Element updatesParagraph = new Element("p");
			Element updatesLink = new Element("a", "List of all updates");
				updatesLink.tag.attr["href"] = URL_BASE ~ "updates";
			updatesParagraph ~= updatesLink;
			mBody ~= updatesParagraph;
		} else if(URL == "update") {
			mBody ~= new Element("p", " ");
			for(long i = updates.length - 1; i >= 0; --i) {
				Element post = formatPostHeader(updates[i]);

				if(!(post is null))
					mBody ~= post;
			}
		} else {
			headers = "Cache-control: max-age=3600\n";
			string suffix = URL[URL_PREFIX.length..$];
			int r = cast(int)updates.length + 1;
			if(isNumeric(suffix)) {
				r = to!int(suffix) - 1;
			} else {
				string title = URL[URL_PREFIX.length..$];
				for(int i = 0; i < updates.length; ++i)
					if(updates[i].title == title)
						r = i;
			}

			if(r >= updates.length) {
				mBody ~= new Element("p", "Couldn't find post, sorry!");
				Element latestLink = new Element("a", "Latest post");
					latestLink.tag.attr["href"] = 
						URL_BASE ~ URL_PREFIX ~ to!string(updates.length);
				mBody ~= latestLink;
				return mMColumn;
			}
			Update update = updates[r];

			Element post = formatUpdate(update);
			if(!(post is null))
				mBody ~= post;

			int next = r + 2, prev = r;
			if(prev >= 1) {
				Element prevE = new Element("p");
				prevE.tag.attr["class"] = "lcol nlink";
				Element prevL = new Element("a", "Previous");
				prevL.tag.attr["href"] = 
					URL_BASE ~ URL_PREFIX ~ to!string(prev);
				prevE ~= prevL;
				mBody ~= prevE;
			}
			if(next <= updates.length) {
				Element nextE = new Element("p");
				nextE.tag.attr["class"] = "rcol nlink";
				nextE.tag.attr["style"] = "text-align:right";
				Element nextL = new Element("a", "Next");
				nextL.tag.attr["href"] = 
					URL_BASE ~ URL_PREFIX ~ to!string(next);
				nextE ~= nextL;
				mBody ~= nextE;
			}
		}
		mBody ~= spacer;
	}

	return mMColumn;
}

Element formatUpdate(Update update, string wrapperClass = "update") {
	if(update is null)
		return null;

	Element post = new Element("div");
		post.tag.attr["class"] = wrapperClass;
	string c = "<div class=\"post\">" ~ update.getContents() ~ "</div>";
	try {
		check(c);
		post ~= formatPostHeader(update);
		post ~= new Document(c);
	} catch(CheckException e) {
		post ~= new Element("p", "Looks like this post isn't proper XML!");
		post ~= new Element("pre", e.toString());
	}

	return post;
}

Element formatPostHeader(Update update) {
	if(update is null)
		return null;

	Element postHeader = new Element("h3");
	postHeader ~= new Document("<span>&#160;</span>");
		postHeader.tag.attr["class"] = "uhead";
	Element pTitle;
	if(update.title.length)
		pTitle = new Element("a", " " ~ update.title);
	else
		pTitle = new Element("a", " " ~ to!string(update.number));
	pTitle.tag.attr["class"] = "utitle lcol";
	pTitle.tag.attr["href"] = URL_PREFIX ~ to!string(update.number);
	postHeader ~= pTitle;
	postHeader ~= new Document("<span class=\"udt rcol\">" ~
			replace(update.date, regex(" ", "g"), "&#160;") ~ " " ~
			replace(update.time, regex(" ", "g"), "&#160;") ~ "</span>");
	return postHeader;
}

