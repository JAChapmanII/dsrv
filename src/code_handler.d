import std.xml;
import std.path;
import std.algorithm;
import std.string;

import std.conv;

import repository;

static const string URL_PREFIX = "code/";
static const string URL_BASE = "http://jachapmanii.net/~jac/";

static const string CLONE_PREIX = "git clone git git://JAChapmanII.net/";

static const int HASH_LENGTH = 40;

Element codeHandler(string URL) {
	Element mMColumn = new Element("div");
	mMColumn.tag.attr["class"] = "mcol";
	Element mBody = new Element("div");
	mBody.tag.attr["class"] = "scol";
	mMColumn ~= mBody;

	mBody ~= new Element("h3", capwords(tolower(URL)));
	Repository[] repos = Repository.parseRepositories();
	if(!repos.length) {
		mBody ~= new Element("p", "There are no repositories");
	} else {
		if((URL == "code") || (URL == "code/")) {
			Element rTable = new Element("table");
			Element tableHead = new Element("tr");
			tableHead ~= new Element("th", "Language");
			tableHead ~= new Element("th", "Branch");
			tableHead ~= new Element("th", "Name");
			tableHead ~= new Element("th", "Description");
			rTable ~= tableHead;

			bool odd = true;
			foreach(repo; repos) {
				Element rRow = new Element("tr");
				if(odd)
					rRow.tag.attr["class"] = "odd";
				rRow ~= new Element("td", repo.language);
				rRow ~= new Element("td", repo.defaultBranch);

				Element linkTD = new Element("td");
				string names = repo.name;
				if(repo.alternateNames.length)
					names ~= ", ";
				for(int i = 0; i < repo.alternateNames.length; ++i) {
					names ~= repo.alternateNames[i];
					if(i != repo.alternateNames.length - 1)
						names ~= ", ";
				}
				Element rLink = new Element("a", names);
				rLink.tag.attr["href"] = URL_BASE ~ URL_PREFIX ~ repo.name;
				linkTD ~= rLink;
				rRow ~= linkTD;
				rRow ~= new Element("td", repo.description);
				rTable ~= rRow;
				odd = !odd;
			}
			mBody ~= rTable;
		} else {
			Repository repo;
			string[] rfields = split(URL[URL_PREFIX.length..$], "/");

			string rName = rfields[0], command;
			if(rfields.length > 1)
				command = rfields[1];
			string[] args;
			if(rfields.length > 2)
				foreach(arg; rfields[2..$])
					args ~= arg;

			foreach(i, field; rfields)
				mBody ~= new Comment("rfields[" ~ to!string(i) ~ "] = " ~ field);

			string branch = "master";

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
				switch(command) {
					case "commits":
						mBody ~= commitPageHandler(repo, branch);
						return mMColumn;
					case "files":
						mBody ~= fileViewerHandler(repo, branch, args);
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

				mBody ~= commitPageHandler(repo, branch, 3);
				mBody ~= new Element("p");

				string[] files = repo.files();
				if(files.length) {
					mBody ~= repositoryListingHandler(repo, branch);
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

Element fileViewerHandler(Repository repository, string branch, string[] args) {
	Element mBody = new Element("div");
		mBody.tag.attr["class"] = "fviewer";
	if(!args.length) {
		Element repoP = new Element("p", "No file specified.");
		Element repoLink = new Element("a", "Back to repository page");
			repoLink.tag.attr["href"] = URL_BASE ~ URL_PREFIX ~ repository.name;
		repoP ~= repoLink;
		mBody ~= repoP;
		return mBody;
	}
	mBody ~= new Element("p", "Can't display files yet");
	return mBody;
}

Element repositoryListingHandler(Repository repository, string branch) {
	string[] files = repository.files;
	if(!files.length)
		return null;

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
			fileLink.tag.attr["href"] = 
				URL_BASE ~ URL_PREFIX ~ repository.name ~ "/files/" ~ file;
		fileLinkTD ~= fileLink;
		fileRow ~= fileLinkTD;

		Repository.Commit[] fCommits = repository.commitsToFile(file, branch, 1);
		if(!fCommits.length) {
			fileRow ~= new Element("td", "Could not load data");
			continue;
		}

		fileRow ~= new Element("td", fCommits[0].relDate);

		string href = URL_BASE ~ URL_PREFIX ~ 
			repository.name() ~ "/" ~ branch ~ "/" ~ fCommits[0].hash;
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

static const int MAX_SUBJECT_LENGTH = 80;
// Make a listing of the first max commits of a repository as a nice table
Element commitPageHandler(
		Repository repository, string branch, long max = -1) { //{{{
	Repository.Commit[] commits = repository.commits();
	if(!commits.length)
		return null;

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
		string href = URL_BASE ~ URL_PREFIX ~ 
			repository.name() ~ "/" ~ branch ~ "/" ~ commits[i].hash;

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

