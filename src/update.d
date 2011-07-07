import std.file;
import std.string;
import std.conv;

import std.regex;

static const string UDATES_FILE = "udates";
static const string UDATES_DIR = "updates";

class Update {
	public:
		this(int iNumber, string iDate, string iTime, string iTitle) {
			this._number = iNumber;
			this._date = iDate;
			this._time = iTime;
			this._title = iTitle;
		}

		string getContents() {
			if(!isDir(UDATES_DIR))
				return "udates dir is nonexistant";
			string fName = UDATES_DIR ~ "/" ~ zfill(to!string(this.number), 4);
			if(!isFile(fName))
				return "update does not exist";

			return readText(fName);
		}

		static Update[] parseUDates() {
			Update[] updates;
			if(!isFile(UDATES_FILE))
				return updates;
			foreach(line; splitlines(readText(UDATES_FILE))) {
				string[] fields = std.string.split(line, "|");
				updates ~= new Update(
						to!int(fields[0]), fields[1], fields[2], fields[3]);
			}
			return updates;
		}

		string title() {
			return this._title;
		}

		string time() {
			return this._time;
		}

		string date() {
			return this._date;
		}

		int number() {
			return this._number;
		}

	protected:
		int _number;
		string _date;
		string _time;
		string _title;
}

