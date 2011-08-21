import std.xml;
import std.path;
import std.algorithm;
import std.string;

import std.conv;
import std.regex;

import std.array;

import repository;

static const string URL_PREFIX = "code/";
static const string URL_BASE = "http://jachapmanii.net/";

static const string CLONE_PREIX = "git clone git://JAChapmanII.net/";

static const int HASH_LENGTH = 40;

Element codeHandler(string URL, ref string headers) {
	Element mMColumn = new Element("div");
	mMColumn.tag.attr["class"] = "mcol";
	Element mBody = new Element("div");
	mBody.tag.attr["class"] = "scol";
	mMColumn ~= mBody;

	Repository[] repos = Repository.parseRepositories();
	if(!repos.length) {
		mBody ~= new Element("p", "There are no repositories");
	} else {
		if((URL == "code") || (URL == "code/")) {
			mBody ~= new Element("p", " ");
			Element recentlyModified = getRecentlyModified(repos);
			if(recentlyModified is null)
				mBody ~= new Element("p", "Couldn't get recently modified...");
			else
				mBody ~= recentlyModified;

			mBody ~= new Element("p", " ");
			Element codeBody = getRepositoryTable(repos);
			if(codeBody is null)
				mBody ~= new Element("p", "Problem generating the code table");
			else
				mBody ~= codeBody;

		} else {
			Repository repo;
			string[] rfields = std.string.split(URL[URL_PREFIX.length..$], "/");

			string rName = rfields[0], command;
			if(rfields.length > 1)
				command = rfields[1];
			string[] args;
			if(rfields.length > 2)
				foreach(arg; rfields[2..$])
					args ~= arg;

			foreach(i, field; rfields)
				mBody ~= new Comment("rfields[" ~ to!string(i) ~ "] = " ~ field);

			while(count(rName, '/'))
				rName = dirname(rName);

			// look for repo by primary name
			foreach(r; repos)
				if(r.name == rName)
					repo = r;

			// look for repo by secondary name if we didn't find it yet
			if(repo is null)
				foreach(r; repos)
					foreach(altName; r.alternateNames)
						if(altName == rName)
							// change rName to be the primary name, too
							repo = r, rName = r.name;

			if(repo is null) {
				mBody ~= new Element("p", "No repository by that name");
				mBody ~= new Comment(rName);
			} else {
				mBody ~= new Element("p", repo.name ~ " -- " ~ repo.description);
				switch(command) {
					case "commits":
						mBody ~= commitsPageHandler(repo, args);
						return mMColumn;
					case "files":
						mBody ~= fileViewerHandler(repo, args);
						return mMColumn;
					default:
						break;
				}

				Element cloneCommand = new Element("p", 
						"Clone this repository: " ~ CLONE_PREIX ~ rName);
					cloneCommand.tag.attr["class"] = "code";
				mBody ~= cloneCommand;

				if(!repo.branches) {
					mBody ~= new Element("p", 
							"Repository does not appear to have branches?");
					return mMColumn;
				}

				string branches;
				foreach(b; repo.branches)
					if(b.length)
						branches ~= b ~ ", ";
				branches = branches[0..$-2];
				mBody ~= new Element("p", "Branches: " ~ branches);

				mBody ~= commitsPageHandler(repo, args, 3);
				Element commitPageLink = new Element("a", "Full commit list");
					commitPageLink.tag.attr["href"] = 
						URL_PREFIX ~ repo.name ~ "/commits";
				mBody ~= commitPageLink;
				mBody ~= new Element("p");

				string[] files = repo.files();
				if(files.length) {
					mBody ~= repositoryListingHandler(repo, args);
					mBody ~= new Element("p");

					foreach(f; files) {
						if((toupper(f) == "README") || (tolower(f) == "readme.txt")) {
							mBody ~= new Element("p", "README:");
							Element readme = new Element("pre", repo.getFile(f));
								readme.tag.attr["class"] = "readme";
							mBody ~= readme;
						}
					}
				}
			}
		}
	}

	return mMColumn;
}

Element getRecentlyModified(Repository[] repos) {
	Element mBody = new Element("div");
		mBody.tag.attr["class"] = "rmod";

	Repository.Commit[][Repository] r_commits;
	foreach(repo; repos)
		r_commits[repo] = repo.commits(3);

	uint max = min(3, r_commits.length);
	for(uint i = 0; i < max; ++i) {
		mBody ~= new Comment("repos.length: " ~ to!string(repos.length));
		ulong earliest = 0;
		foreach(j, repo; repos)
			if(r_commits[repo][0].timestamp > 
					r_commits[repos[earliest]][0].timestamp)
				earliest = j;

		Repository repo = repos[earliest];

		Element np = new Element("p");
		Element rLink = new Element("a", repo.name);
		if(repo.alternateNames.length)
			rLink = new Element("a", repo.name ~ ", " ~ 
				std.string.join(repo.alternateNames, ", "));
			rLink.tag.attr["href"] = URL_PREFIX ~ repo.name;
		np ~= rLink;
		np ~= new Text(" -- " ~ repo.description);
		mBody ~= np;

		mBody ~= commitsPageHandler(repo, null, 3);

		if(earliest == 0)
			repos = repos[1..$];
		else if (earliest == repos.length - 1)
			repos = repos[0..$-1];
		else
			repos = repos[0..earliest] ~ repos[earliest+1..$];
	}

	return mBody;
}

Element getRepositoryTable(Repository[] repos) {
	string lang = "nonexistant language";
	Element mBody = new Element("div");
		mBody.tag.attr["class"] = "tabbox";

	int[string] langCount;
	foreach(repo; repos)
		if(repo.language in langCount)
			langCount[repo.language]++;
		else
			langCount[repo.language] = 1;

	Element rTable;
	Element rTableDiv;
	bool odd;
	int tabCount;
	foreach(repo; repos) {
		if(repo.language != lang) {
			lang = repo.language;
			tabCount++;

			if(!(rTableDiv is null))
				mBody ~= rTableDiv;

			rTable = new Element("table");
			Element tableHead = new Element("tr");
			tableHead ~= new Element("th", "Branch");
			tableHead ~= new Element("th", "Name");
			tableHead ~= new Element("th", "Description");
			rTable ~= tableHead;

			rTableDiv = new Element("div");
				rTableDiv.tag.attr["class"] = "tab";
				rTableDiv.tag.attr["title"] = repo.language ~ 
					((langCount[repo.language] > 1) ? 
						 " (" ~ to!string(langCount[repo.language]) ~ ")" :
						 "");
			rTableDiv ~= rTable;

			odd = true;
		}

		Element rRow = new Element("tr");
		if(odd)
			rRow.tag.attr["class"] = "odd";
		Element defaultBranch = new Element("td", repo.defaultBranch);
			defaultBranch.tag.attr["class"] = "branch";
		rRow ~= defaultBranch;

		Element linkTD = new Element("td");
			linkTD.tag.attr["class"] = "name";
		Element rLink = new Element("a", repo.name);
		if(repo.alternateNames.length)
			rLink = new Element("a",
				repo.name ~ ", " ~ std.string.join(repo.alternateNames, ", "));
			rLink.tag.attr["href"] = URL_PREFIX ~ repo.name;
		linkTD ~= rLink;
		rRow ~= linkTD;
		Element description = new Element("td", repo.description);
			description.tag.attr["class"] = "description";
		rRow ~= description;
		rTable ~= rRow;
		odd = !odd;
	}
	mBody ~= rTableDiv;
	return mBody;
}

Element repositoryErrorPage(Repository repository, string errorMessage) {
	Element error = new Element("p", errorMessage);
	Element repoLink = new Element("a", "Back to repository page");
		repoLink.tag.attr["href"] = URL_PREFIX ~ repository.name;
	error ~= repoLink;
	return error;
}

Element fileViewerHandler(Repository repository, string[] args) {
	Element mBody = new Element("div");
		mBody.tag.attr["class"] = "fviewer";
	Element repoLink = new Element("a", "Back to repository page");
		repoLink.tag.attr["href"] = URL_PREFIX ~ repository.name;

	if(args.length < 2)
		return repositoryErrorPage(repository, "No file specified");

	string branch = args[0];
	if(!branch.length)
		branch = repository.defaultBranch;
	args = args[1..$];

	string fname;
	foreach(arg; args)
		fname ~= arg ~ "/";
	fname = fname[0..$-1];

	string[] files = repository.files;
	if(!canFind(files, fname)) {
		return repositoryErrorPage(repository, 
				"This file does not appear to be part of the repository.");
	}

	string file = repository.getFile(fname, branch);
	Element mFile = new Element("pre", file);
		mFile.tag.attr["class"] = "code";
	mBody ~= mFile;

	Element repoP = new Element("p");
	repoP ~= repoLink;
	mBody ~= repoP;
	return mBody;
}

Element repositoryListingHandler(Repository repository, string[] args) {
	string[] files = repository.files;
	if(!files.length)
		return null;
	
	string branch;
	if(!args.length)
		branch = repository.defaultBranch;
	else
		branch = args[0];
	if(!canFind(repository.branches, branch))
		return repositoryErrorPage(repository,
				"Could not find that branch (" ~ branch ~ ").");

	Element fileListing = new Element("table");

	Element listingHeader = new Element("tr");
	listingHeader ~= new Element("th", "Name");
	listingHeader ~= new Element("th", "Date");
	listingHeader ~= new Element("th", "Commit Subject");
	fileListing ~= listingHeader;

	foreach(file; files) {
		if(!file.length)
			continue;
		Element fileRow = new Element("tr");
		Element fileLinkTD = new Element("td");
		Element fileLink = new Element("a", file);
			fileLink.tag.attr["href"] = repository.name ~
				"/files/" ~ branch ~ "/" ~ file;
		fileLinkTD ~= fileLink;
		fileRow ~= fileLinkTD;

		Repository.Commit[] fCommits = repository.commitsToFile(file, branch, 1);
		if(!fCommits.length) {
			fileRow ~= new Element("td", "Could not load data");
			continue;
		}

		fileRow ~= new Element("td", fCommits[0].relDate);

		string href = repository.name() ~ "/commits/" ~ fCommits[0].hash;
		Element descData = new Element("td");
		Element descLink = new Element("a", 
				fCommits[0].subject[0..min(MAX_SUBJECT_LENGTH, $)]);
			descLink.tag.attr["href"] = href;
			descLink.tag.attr["class"] = "commitDescription";
		descData ~= descLink;
		fileRow ~= descData;
		fileListing ~= fileRow;
	}

	return fileListing;
}

Element colorizeDiff(string diff) {
	string[] lines = std.string.split(diff, "\n");
	string result = "<div class=\"code\">\n";
	foreach(line; lines) {
		if(!line.length) {
			result ~= "<br />";
			continue;
		}
		line = replace(expandtabs(encode(line), 4), regex(r"\s", "g"), "&#160;");
		result ~= "<span class=\"";
		if(line[0] == '+') {
			result ~= "dadd";
		} else if(line[0] == '-') {
			result ~= "dsubtract";
		} else if(line[0] == '@') {
			result ~= "dcontext";
		} else
			result ~= "dplain";
		result ~= "\">" ~ line ~ "</span><br />\n";
	}
	result ~= "</div>";
	return new Document(result);
}

Element commitPageHandler(Repository repository, string[] args) {
	Element commitPage = new Element("div");
		commitPage.tag.attr["class"] = "commitp";
	Element repoLink = new Element("a", "Back to repository page");
		repoLink.tag.attr["href"] = URL_PREFIX ~ repository.name;
	
	Repository.Commit[] commits = repository.commits;
	bool found;
	Repository.Commit commit;
	foreach(c; commits)
		if(c.hash == args[0])
			commit = c, found = true;

	if(!found)
		return repositoryErrorPage(repository, 
				"Could not find that commit, sorry.");

	commitPage ~= new Element("p",
			"Commit " ~ commit.hash ~ " -- " ~ commit.relDate);
	commitPage ~= new Element("p", commit.subject);

	string diff = repository.getCommitDiff(commit);
	if(diff.length)
		commitPage ~= colorizeDiff(diff);
	else
		commitPage ~= new Element("p", "This is the initial commit");

	commitPage ~= repoLink;
	return commitPage;
}

static const int MAX_SUBJECT_LENGTH = 80;
// Make a listing of the first max commits of a repository as a nice table
Element commitsPageHandler(
		Repository repository, string[] args, long max = -1) { //{{{
	Repository.Commit[] commits = repository.commits();
	if(!commits.length)
		return null;

	string branch;
	if(!args.length)
		branch = repository.defaultBranch;
	else
		branch = args[0];
	if(branch.length == HASH_LENGTH)
		return commitPageHandler(repository, args);
	if(!canFind(repository.branches, branch))
		return repositoryErrorPage(repository,
				"Could not find that branch (" ~ branch ~ ").");

	if(max == -1)
		max = commits.length;
	else
		max = min(commits.length, max);

	Element mBody = new Element("table");
		mBody.tag.attr["class"] = "commits";

	Element mBodyHeader = new Element("tr");
	mBodyHeader ~= new Element("th", "Hash");
	mBodyHeader ~= new Element("th", "Date");
	mBodyHeader ~= new Element("th", "Description");
	mBody ~= mBodyHeader;

	for(long i = 0; i < max; ++i) {
		string href = URL_PREFIX ~ 
			repository.name() ~ "/commits/" ~ commits[i].hash;

		Element hashData = new Element("td");
		Element hashLink = new Element("a", commits[i].hash[0..8]);
			hashLink.tag.attr["href"] = href;
			hashLink.tag.attr["class"] = "commitAbbrevHash";
		hashData ~= hashLink;

		Element relDateData = new Element("td");
		Element relDateLink = new Element("a", commits[i].relDate);
			relDateLink.tag.attr["href"] = href;
			relDateLink.tag.attr["class"] = "commitRelDate";
		relDateData ~= relDateLink;

		Element descData = new Element("td");
		Element descLink = new Element("a", 
				commits[i].subject[0..min(MAX_SUBJECT_LENGTH, $)]);
			descLink.tag.attr["href"] = href;
			descLink.tag.attr["class"] = "commitDescription";
		descData ~= descLink;

		Element commitRow = new Element("tr");
		commitRow ~= hashData;
		commitRow ~= relDateData;
		commitRow ~= descData;
		mBody ~= commitRow;
	}
	return mBody;
} //}}}

