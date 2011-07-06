import std.file;

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
			return "contents";
		}

		static Update[] parseUDates() {
			Update[] updates;
			if(!isFile(UDATES_FILE))
				return updates;
			return updates;
		}

	protected:
		int number;
		string date;
		string time;
		string title;
}

