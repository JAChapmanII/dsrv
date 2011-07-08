import std.file;
import std.string;
import std.conv;

import std.process;

static const string REPOS_FILE = "repos";
static const string REPOS_DIR = "code";

class Repository {
	public:
		this(string iLangauge, string iDefaultBranch, string iName,
				string iDescription, string[] iAlternateNames) {
			this._language = iLangauge;
			this._defaultBranch = iDefaultBranch;
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
				string[] names = split(fields[2], ",");
				string[] altNames;
				foreach(n; names[1..$])
					altNames ~= strip(n);
				repositories ~= new Repository(
						strip(fields[0]), strip(fields[1]), strip(names[0]), 
						strip(fields[3]), altNames);
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
				r = shell("git ls-tree -r -z --name-only master");
				chdir(cwd);
			} catch(Exception e) {
				return null;
			}
			return split(r, "\0");
		}

		string getFile(string fName, string branch = "") {
			if(!isDir(REPOS_DIR))
				return null;

			if(!branch.length)
				branch = this.defaultBranch;

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

		Commit[] commits(string branch = "") {
			if(!isDir(REPOS_DIR))
				return null;

			if(!branch.length)
				branch = this.defaultBranch;

			Commit[] commits;
			string cos;
			try {
				string cwd = getcwd();
				chdir(REPOS_DIR ~ "/" ~ this._name);
				cos = shell("git log " ~ this.defaultBranch ~
						" --pretty='%H%x00%ar%x00%s'");
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

		Commit[] commitsToFile(string fName, string branch = "", int max = 0) {
			if(!isDir(REPOS_DIR))
				return null;

			if(!branch.length)
				branch = this.defaultBranch;

			string comm = "git log --pretty='%H%x00%ar%x00%s' ";

			Commit[] commits;
			string cos;
			try {
				string cwd = getcwd();
				chdir(REPOS_DIR ~ "/" ~ this._name);
				string suff = " " ~ branch ~ " -- \"" ~ fName ~ "\"";
				if(max > 0)
					suff = " -n " ~ to!string(max) ~ suff;
				cos = shell(comm ~ suff);
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

		string defaultBranch() {
			return this._defaultBranch;
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
		string _defaultBranch;
		string _name;
		string _description;
		string[] _alternateNames;
}

