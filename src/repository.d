import std.file;
import std.string;
import std.conv;

import std.process;

static const string REPOS_FILE = "repos";
static const string REPOS_DIR = "code";

class Repository {
	public:
		this(string iLangauge, string iName, string iDescription, 
				string[] iAlternateNames) {
			this._language = iLangauge;
			this._name = iName;
			this._description = iDescription;
			this._alternateNames = iAlternateNames;
		}

		static Repository[] parseRepositories() {
			Repository[] repositories;
			if(!isFile(REPOS_FILE))
				return repositories;
			foreach(line; splitlines(readText(REPOS_FILE))) {
				string[] fields = split(line, "|");
				string[] altNames;
				if(fields[3].length)
					altNames = split(fields[3]);
				repositories ~= new Repository(
						fields[0], fields[1], fields[2], altNames);
			}
			return repositories;
		}

		string[] files() {
			if(!isDir(REPOS_DIR))
				return null;
			string r;
			try {
				string cwd = getcwd();
				chdir(REPOS_DIR ~ "/" ~ this._name);
				r = shell("git ls-tree -z --name-only master");
				chdir(cwd);
			} catch(Exception e) {
				return null;
			}
			return split(r, "\0");
		}

		string getFile(string fName, string branch = "master") {
			if(!isDir(REPOS_DIR))
				return null;

			string c;
			try {
				string cwd = getcwd();
				chdir(REPOS_DIR ~ "/" ~ this._name);
				c = shell("git show " ~ branch ~ ":" ~ fName);
				chdir(cwd);
			} catch(Exception e) {
				return null;
			}
			return c;
		}

		string[] commits() {
			if(!isDir(REPOS_DIR))
				return null;

			string commits;
			try {
				string cwd = getcwd();
				chdir(REPOS_DIR ~ "/" ~ this._name);
				commits = shell("git log -z --pretty=oneline");
				chdir(cwd);
			} catch(Exception e) {
				return null;
			}
			return split(commits, "\n");
		}

		string language() {
			return this._language;
		}

		string name() {
			return this._name;
		}

		string description() {
			return this._description;
		}

		string[] alternateNames() {
			return this._alternateNames;
		}

	protected:
		string _language;
		string _name;
		string _description;
		string[] _alternateNames;
}

