import std.file;
import std.string;
import std.conv;

static const string UDATES_FILE = "udates";
static const string UDATES_DIR = "updates";

class Update {
	public:
		this(int iNumber, string iDate, string iTime, string iTitle) {
			this.number = iNumber;
			this.date = iDate;
			this.time = iTime;
			this.title = iTime;
		}

		string getContents() {
			if(!isDir(UDATES_DIR))
				return "udates dir is nonexistant";
			string fName = UDATES_DIR ~ "/" ~ zfill(to!string(this.number), 4);
			if(!isFile(fName))
				return "update does not exist";

			string contents = readText(fName);
			return contents;
		}

		static Update[] parseUDates() {
			Update[] updates;
			if(!isFile(UDATES_FILE))
				return updates;
			foreach(line; splitlines(readText(UDATES_FILE))) {
				string[] fields = split(line, "|");
				updates ~= new Update(
						to!int(fields[0]), fields[1], fields[2], fields[3]);
			}
			return updates;
		}

	protected:
		int number;
		string date;
		string time;
		string title;
}

