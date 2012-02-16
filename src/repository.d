import std.file;
import std.string;
import std.conv;

import std.process;

static const string REPOS_FILE = "repos";
static const string REPOS_DIR = "code";

class Repository {

	public:
		struct Commit {
			string hash;
			ulong timestamp;
			string relDate;
			string subject;
		}

		this(string iLangauge, string iDefaultBranch, string iName,
				string iDescription, string[] iAlternateNames) {
			this._language = iLangauge;
			this._defaultBranch = iDefaultBranch;
			this._name = iName;
			this._description = iDescription;
			this._alternateNames = iAlternateNames;
		}

		// obtain a Repository object by name
		static Repository repository(string name) { // {{{
			if(!_inited) {
				_repositories = parseRepositories();
				_inited = true;
			}
			if(_repositories is null || _repositories.length == 0)
				return null;
			if(name is null || name.length == 0)
				return null;

			Repository repo;
			// look for repo by primary name
			foreach(r; _repositories) {
				if(r.name == name) {
					return r;
				}
			}

			// look for repo by secondary name if we didn't find it yet
			foreach(r; _repositories) {
				foreach(altName; r.alternateNames) {
					if(altName == name) {
						return r;
					}
				}
			}

			return null;
		} // }}}

		static Repository[] repositories() { // {{{
			if(!_inited) {
				_repositories = parseRepositories();
				_inited = true;
			}
			return _repositories;
		} // }}}

		static Repository[] parseRepositories() { // {{{
			Repository[] repositories;
			if(!isFile(REPOS_FILE))
				return repositories;
			foreach(line; splitlines(readText(REPOS_FILE))) {
				string[] fields = split(line, "|");
				string[] names = split(fields[2], ",");
				string rdir = REPOS_DIR ~ "/" ~ names[0];
				//if(!exists(rdir))
					//continue;
				string[] altNames;
				foreach(n; names[1..$])
					altNames ~= strip(n);
				repositories ~= new Repository(
						strip(fields[0]), strip(fields[1]), strip(names[0]), 
						strip(fields[3]), altNames);
			}
			return repositories;
		} // }}}

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

		// Return the list of available branches in this repository
		string[] branches() { // {{{
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
			string[] barr = split(branches, "\n");
			string[] ret;
			foreach(i, b; barr)
				if(!b.length)
					continue;
				else if(b[0] == '*')
					ret ~= strip(b[2..$]);
				else
					ret ~= strip(b);

			return ret;
		} // }}}

		Commit[] commits(int count = -1, string branch = "") {
			if(!isDir(REPOS_DIR))
				return null;

			if(!branch.length)
				branch = this.defaultBranch;

			Commit[] commits;
			string cos;
			try {
				string cwd = getcwd();
				chdir(REPOS_DIR ~ "/" ~ this._name);
				if(count < 0)
					cos = shell("git log " ~ this.defaultBranch ~
							" --pretty='%H%x00%at%x00%ar%x00%s'");
				else
					cos = shell("git log " ~ this.defaultBranch ~
							" --pretty='%H%x00%at%x00%ar%x00%s' -" ~ to!string(count));
				chdir(cwd);
			} catch(Exception e) {
				return null;
			}
			string[] cs = split(cos, "\n");
			foreach(c; cs) {
				if(c.length) {
					string[] f = split(c, "\0");
					Commit com = { f[0], 0, f[2], f[3] };
					com.timestamp = parse!ulong(f[1]);
					commits ~= com;
				}
			}
			return commits;
		}

		string getCommitDiff(Commit commit) {
			// TODO: some sort of file not existant thing

			string diff;
			try {
				string cwd = getcwd();
				chdir(REPOS_DIR ~ "/" ~ this._name);
				diff = shell("git diff-tree -p " ~ commit.hash);
				chdir(cwd);
			} catch(Exception e) {
				return null;
			}
			return diff;
		}

		Commit[] commitsToFile(string fName, string branch = "", int max = 0) {
			if(!isDir(REPOS_DIR))
				return null;

			if(!branch.length)
				branch = this.defaultBranch;

			string comm = "git log --pretty='%H%x00%at%x00%ar%x00%s' ";

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
					Commit com = { f[0], 0, f[2], f[3] };
					com.timestamp = parse!ulong(f[1]);
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

		static Repository[] _repositories;
		static bool _inited;
}

