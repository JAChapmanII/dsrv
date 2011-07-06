import std.xml;
import std.string;
import std.conv;

import update;

static const URL_PREFIX = "update/";

Element updateHandler(string URL) {
	Element mBody = new Element("div");
	mBody.tag.attr["class"] = "mcol";

	mBody ~= new Element("h3", URL);
	Update[] updates = Update.parseUDates();
	if(!updates.length) {
		mBody ~= new Element("p", "There are no updates");
	} else {
		string suffix = URL[URL_PREFIX.length..$];
		if(isNumeric(suffix)) {
			mBody ~= new Element("p", updates[to!int(suffix)].getContents());
		} else {
			mBody ~= new Element("p", "Post requested by title");
		}
	}

	return mBody;
}

