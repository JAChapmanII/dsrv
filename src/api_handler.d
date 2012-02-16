//import std.xml;
//import std.path;
//import std.algorithm;
//import std.string;

//import std.conv;
//import std.regex;

import std.array, std.algorithm;
import std.regex;
import std.conv;
import std.string;

import repository;

static const string URL_PREFIX = "code/";
static const string URL_BASE = "http://jachapmanii.net/";

static const int HASH_LENGTH = 40;

bool equalsIgnoreCase(string a, string b) {
	// TODO: these are deprecated... update compiler?
	string la = tolower!string(a);
	string lb = tolower!string(b);
	return la == lb;
}

string jsonEscape(string str) {
	// replace illegal characters TODO check on this
	str = replace(str, regex(r"\\", "g"), "\\\\");
	str = replace(str, regex("\n", "g"), "\\n");
	str = replace(str, regex("\t", "g"), "\\t");
	str = replace(str, regex("\"", "g"), "\\\"");
	return str;
}
string toJSON(Repository.Commit commit) {
	return "{\"hash\":\"" ~ commit.hash ~ "\"" ~
		",\"timestamp\":" ~ to!string(commit.timestamp) ~
		",\"relDate\":\"" ~ commit.relDate ~ "\"" ~
		",\"subject\":\"" ~ jsonEscape(commit.subject) ~ "\"}";
}
string toJSON(Repository repository) {
	string repo = "{\"language\":\"" ~ repository.language ~ "\"" ~
		",\"defaultBranch\":\"" ~ repository.defaultBranch ~ "\"" ~
		",\"name\":\"" ~ repository.name ~ "\"" ~
		",\"description\":\"" ~ repository.description ~ "\"";
	string[] altNames = repository.alternateNames;
	if(altNames is null || altNames.empty)
		return repo ~ "}";

	repo ~= ",\"alternateNames\":[";
	foreach(an; altNames)
		repo ~= "\"" ~ an ~ "\",";
	repo = repo[0..$-1] ~ "]}";
	return repo;
}



// return the default status
string getStatus() {
	return getStatus("0");
}
// return a built status
string getStatus(string s) {
	try {
		int num = to!int(s);
		string status = s;
		if(num == 0)
			status = "Rediscovering blink-182";
		return "\"status\":\"" ~ status ~ "\"";
	} catch(Exception e) {
		return "\"error\":\"cannot convert argument to number\"";
	}
}

// return the repositories that use the specified language, or all
string getCLang(string[] args) {
	Repository[] repos = Repository.repositories;
	// if there aren't any, return an error
	if(repos.empty)
		return "\"error\":\"no repositories\"";

	// paste the names together into a json array
	string rlist = "[";
	foreach(r; repos) {
		// the user wants all the repositories
		if(args.length == 0)
				rlist ~= toJSON(r) ~ ",";
		// the user wants a specific language
		else if(equalsIgnoreCase(r.language, args[0]))
				rlist ~= toJSON(r) ~ ",";
	}
	if(rlist == "[")
		return "\"error\":\"no repositories in that language\"";
	rlist = rlist[0..$-1] ~ "]";
	return "\"contents\":" ~ rlist;
}

// return the contents of something code-wise
string getContents(string[] args) { // {{{
	// return the list of repositories
	if(args.length == 0) { // {{{
		return getCLang(args);
	} // }}}

	// if we're here, we at least have a repository name
	string repo = args[0];
	string res = "\"repository\":\"" ~ repo ~ "\"";

	Repository trepo = Repository.repository(repo);
	// if we can't get that repository, return an error
	if(trepo is null)
		return res ~ ",\"error\":\"no repository by than name\"";

	// if there are no more args, we should return the list of branches
	if(args.length == 1) { // {{{
		// paste the branch names into a json array
		string blist = "[";
		string[] branches = trepo.branches;
		foreach(b; branches)
			blist ~= "\"" ~ b ~ "\",";
		blist = blist[0..$-1] ~ "]";
		return res ~ ",\"contents\":" ~ blist;
	} // }}}

	// if we're here, then we got a branch name too
	string branch = args[1];
	res ~= ",\"branch\":\"" ~ branch ~ "\"";

	// get the files TODO: this is master branch only...
	string[] files = trepo.files;

	// if they just want a file list
	if(args.length == 2) { // {{{
		// paste the list of files into a json array
		string farray = "[";
		// however, we only put directory names once (and not its files)
		bool[string] placed;
		foreach(f; files) {
			if(f.empty)
				break;

			// get the base name
			string[] fp = split(f, "/");
			string p = fp[0];
			// if it's a directory, append /
			if(fp.length > 1)
				p ~= "/";
			// if we haven't added it already, add it
			if(!(p in placed)) {
				farray ~= "\"" ~ p ~ "\",";
				placed[p] = true;
			}
		}
		return res ~ ",\"files\":" ~ farray[0..$-1] ~ "]";
	} // }}}

	// otherwise we're looking for a specific file/directory
	string file = join(args[2..$], "/");
	res ~= ",\"file\":\"" ~ file ~ "\"";

	// look for files literally named the argument
	foreach(f; files) { // {{{
		// we found it
		if(f == file) {
			string contents = jsonEscape(trepo.getFile(file));
			// append the file contents
			return res ~ ",\"contents\":\""~ contents ~ "\"";
		}
	} // }}}

	// look for directories to list instead
	string dlist = "[";
	bool[string] placed;
	foreach(f; files) { // {{{
		// paste files matching the passed directory which we haven't already
		// included into the directory list json object
		if(startsWith(f, file)) {
			string[] fp = split(f, "/");
			fp = fp[args.length - 2..$];
			if(fp.length == 0)
				continue;
			string p = fp[0];
			if(fp.length > 1)
				p ~= "/";
			if(!(p in placed)) {
				dlist ~= "\"" ~ p ~ "\",";
				placed[p] = true;
			}
		}
	} // }}}
	// if we didn't find any matching directories
	if(dlist == "[")
		return res ~ ",\"error\":\"file/directory not found\"";

	// otherwise we return the directory contents
	dlist = dlist[0..$-1] ~ "]";
	return res ~ ",\"contents\":" ~ dlist;
} // }}}

// return information about commits or a commit
string getCommit(string[] args) {
	if(args.length < 2) {
		return "\"error\":\"" ~
			"repository, branch, [, limit|commit] args must be given" ~ "\"";
	}

	string repo = args[0], branch = args[1];
	string res = "\"repository\":\"" ~ repo ~ "\",\"branch\":\"" ~ branch ~ "\"";

	Repository trepo = Repository.repository(repo);
	if(trepo is null) {
		return res ~ ",\"error\":\"no repository by that name\"";
	}
	string[] branches = trepo.branches;
	bool found;
	foreach(b; branches)
		if(b == branch)
			found = true;
	if(!found) {
		return res ~ ",\"error\":\"branch not found\"";
	}

	int limit = -1;
	if(args.length == 3) {
		try {
			int tmp = to!int(args[2]);
			if(tmp > 0)
				limit = tmp;
		} catch(Exception e) {
			;//do nothing
		}
	}

	// TODO: allow getting just the most recent n commits
	Repository.Commit[] commits = trepo.commits(limit, branch);
	if(commits.empty) {
		return res ~ ",\"error\":\"no commits to that repository:branch\"";
	}

	// if they specified the want all the commits, or some recent ones
	if((args.length == 2) || (limit != -1)) { // {{{
		if(limit == -1)
			limit = 0;
		res ~= ",\"limit\":" ~ to!string(limit);
		// paste the commit objects into a JSON array
		string clist = "[";
		foreach(c; commits)
			clist ~= toJSON(c) ~ ",";
		clist = clist[0..$-1] ~ "]";
		return res ~ ",\"commits\":" ~ clist;
	} // }}}

	string comname = args[2];

	// TODO: this system is broken when filenames are also commit hashes
	// otherwise, look for the one they specified
	foreach(c; commits) {
		if(startsWith(c.hash, comname)) {
			res ~= ",\"commit\":" ~ toJSON(c);
			string diff = jsonEscape(trepo.getCommitDiff(c));
			return res ~ ",\"diff\":\"" ~ diff ~ "\"";
		}
	}

	return res ~ ",\"error\":\"commit not found\"";
}

string apiHandler(string URL, ref string headers) {
	string[] tufields = std.string.split(URL, "/"), ufields;
	foreach(field; tufields)
		if(!field.empty)
			ufields ~= field;
	if((ufields.length == 1) || (ufields[1].length == 0)) {
		return "\"api-functions\":[\"status\",\"cat\",\"clang\",\"commit\"]";
	}
	switch(ufields[1]) {
		case "status":
			if(ufields.length == 2)
				return getStatus();
			else
				return getStatus(ufields[2]);
		case "cat":
			return getContents(ufields[2..$]);
		case "clang":
			return getCLang(ufields[2..$]);
		case "commit":
			return getCommit(ufields[2..$]);
		default:
			return "null";
	}
}

