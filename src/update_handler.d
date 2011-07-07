import std.xml;
import std.string;
import std.conv;

import update;

static const string URL_BASE = "http://jachapmanii.net/~jac/";
static const string URL_PREFIX = "update/";

Element updateHandler(string URL) {
	Element mMColumn = new Element("div");
	mMColumn.tag.attr["class"] = "mcol";
	Element mBody = new Element("div");
	mBody.tag.attr["class"] = "scol";

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
				string c = 
					"<div class=\"update\">" ~ updates[r].getContents() ~ "</div>";
				try {
					check(c);
					Element postHeader = new Element("h3");
					postHeader ~= new Document("<span>&#160;</span>");
						postHeader.tag.attr["class"] = "uhead";
					Element pTitle = new Element("a", updates[r].title);
						pTitle.tag.attr["class"] = "utitle lcol";
					Element pDT = new Element("span",
							updates[r].date ~ " " ~ updates[r].time);
						pDT.tag.attr["class"] = "udt rcol";
					postHeader ~= pTitle;
					postHeader ~= pDT;
					mBody ~= postHeader;


					mBody ~= new Document(c);
				} catch(CheckException e) {
					mBody ~= new Element("p", 
							"Looks like this post isn't proper XML!");
					mBody ~= new Element("pre", e.toString());
				}
			}

			int next = r + 2, prev = r;
			if(prev >= 1) {
				Element prevE = new Element("p");
				prevE.tag.attr["class"] = "lcol";
				Element prevL = new Element("a", "Previous");
				prevL.tag.attr["href"] = 
					URL_BASE ~ URL_PREFIX ~ to!string(prev);
				prevE ~= prevL;
				mBody ~= prevE;
			}
			if(next <= updates.length) {
				Element nextE = new Element("p");
				nextE.tag.attr["class"] = "rcol";
				nextE.tag.attr["style"] = "text-align:right";
				Element nextL = new Element("a", "Next");
				nextL.tag.attr["href"] = 
					URL_BASE ~ URL_PREFIX ~ to!string(next);
				nextE ~= nextL;
				mBody ~= nextE;
			}
			
			Element spacer = new Document("<p>&#160;</p>");
			spacer.tag.attr["style"] = "line-height:0;clear:both";
			mBody ~= spacer;
		} else {
			mBody ~= new Element("p", "Post requested by title");
		}
	}

	mMColumn ~= mBody;
	return mMColumn;
}

