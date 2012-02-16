//import std.xml;
//import std.path;
//import std.algorithm;
//import std.string;

//import std.conv;
//import std.regex;

import std.array, std.algorithm;
import std.regex;

import repository;

static const string URL_PREFIX = "code/";
static const string URL_BASE = "http://jachapmanii.net/";

static const int HASH_LENGTH = 40;

// obtain a Repository object by name
Repository getRepository(string name) { // {{{
	Repository[] repositories = Repository.repositories;
	if(repositories is null || name is null || name.empty)
		return null;

	Repository repo;
	// look for repo by primary name
	foreach(r; repositories) {
		if(r.name == name) {
			return r;
		}
	}

	// look for repo by secondary name if we didn't find it yet
	foreach(r; repositories) {
		foreach(altName; r.alternateNames) {
			if(altName == name) {
				return r;
			}
		}
	}

	return null;
} // }}}

// return the default status
string getStatus() {
	return getStatus("Rediscovering blink-182");
}
// return a built status
string getStatus(string s) {
	return "\"status\":\"" ~ s ~ "\"";
}

// return the contents of something code-wise
string getContents(string[] args) {
	// return the list of repositories
	if(args.length == 0) { // {{{
		Repository[] repos = Repository.repositories;
		// if there aren't any, return an error
		if(repos.empty)
			return "\"error\":\"no repositories\"";
		// otherwise paste the names together into a json array
		string rlist = "[";
		foreach(r; repos)
			rlist ~= "\"" ~ r.name ~ "\",";
		rlist = rlist[0..$-1] ~ "]";
		return "\"contents\":" ~ rlist;
	} // }}}

	// if we're here, we at least have a repository name
	string repo = args[0];
	string res = "\"repository\":\"" ~ repo ~ "\"";

	Repository trepo = getRepository(repo);
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
	foreach(f; files) {
		// we found it
		if(f == file) {
			string contents = trepo.getFile(file);
			// replace illegal characters TODO check on this
			contents = replace(contents, regex(r"\\", "g"), "\\\\");
			contents = replace(contents, regex("\n", "g"), "\\n");
			contents = replace(contents, regex("\t", "g"), "\\t");
			contents = replace(contents, regex("\"", "g"), "\\\"");
			// append the file contents
			return res ~ ",\"contents\":\""~ contents ~ "\"";
		}
	}

	// look for directories to list instead
	string dlist = "[";
	bool[string] placed;
	foreach(f; files) {
		// paste files matching the passed directory which we haven't already
		// included into the directory list json object
		if(startsWith(f, file)) {
			string[] fp = split(f, "/");
			fp = fp[args.length - 2..$];
			string p = fp[0];
			if(fp.length > 1)
				p ~= "/";
			if(!(p in placed)) {
				dlist ~= "\"" ~ p ~ "\",";
				placed[p] = true;
			}
		}
	}
	// if we didn't find any matching directories
	if(dlist == "[")
		return res ~ ",\"error\":\"directory not found\"";

	// otherwise we return the directory contents
	dlist = dlist[0..$-1] ~ "]";
	return res ~ ",\"contents\":" ~ dlist;
}

string apiHandler(string URL, ref string headers) {
	string[] tufields = std.string.split(URL, "/"), ufields;
	foreach(field; tufields)
		if(!field.empty)
			ufields ~= field;
	if((ufields.length == 1) || (ufields[1].length == 0)) {
		return "\"api-functions\":[\"status\",\"cat\"]";
	}
	switch(ufields[1]) {
		case "status":
			if(ufields.length == 2)
				return getStatus();
			else
				return getStatus(ufields[2]);
		case "cat":
			return getContents(ufields[2..$]);
		default:
			return "null";
	}
}

