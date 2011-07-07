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
		
		string[] branches() {
			if(!isDir(REPOS_DIR))
				return null;

			string branches;
			try {
				string cwd = getcwd();
				chdir(REPOS_DIR ~ "/" ~ this._name);
				branches = shell("git branch -a");
				chdir(cwd);
			} catch(Exception e) {
				return null;
			}
			return split(branches, "\n");
		}

		struct Commit {
			string hash;
			string relDate;
			string subject;
		}

		Commit[] commits() {
			if(!isDir(REPOS_DIR))
				return null;

			Commit[] commits;
			string cos;
			try {
				string cwd = getcwd();
				chdir(REPOS_DIR ~ "/" ~ this._name);
				cos = shell("git log --pretty='%H%x00%ar%x00%s'");
				chdir(cwd);
			} catch(Exception e) {
				return null;
			}
			string[] cs = split(cos, "\n");
			foreach(c; cs) {
				if(c.length) {
					string[] f = split(c, "\0");
					Commit com = { f[0], f[1], f[2] };
					commits ~= com;
				}
			}
			return commits;
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

