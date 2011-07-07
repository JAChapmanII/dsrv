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
			int r = to!int(suffix) - 1;
			if(r >= updates.length)
				mBody ~= new Element("p", "no post this high");
			else {
				string c = updates[r].getContents();
				try {
					check(c);
					mBody ~= new Document(c);
				} catch(CheckException e) {
					mBody ~= new Element("p", 
							"Looks like this post isn't proper XML!");
					mBody ~= new Element("pre", e.toString());
				}
			}
		} else {
			mBody ~= new Element("p", "Post requested by title");
		}
	}

	return mBody;
}

