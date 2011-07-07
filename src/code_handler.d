import std.xml;
import std.path;
import std.algorithm;
import std.string;

import repository;

static const string URL_PREFIX = "code/";
static const string URL_BASE = "http://jachapmanii.net/~jac/";

static const string CLONE_PREIX = "git clone git git://JAChapmanII.net/";

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
			tableHead ~= new Element("th", "Name");
			tableHead ~= new Element("th", "Description");
			rTable ~= tableHead;

			bool odd = true;
			foreach(repo; repos) {
				Element rRow = new Element("tr");
				if(odd)
					rRow.tag.attr["class"] = "odd";
				rRow ~= new Element("td", repo.language());
				Element linkTD = new Element("td");
				string names = repo.name();
				if(repo.alternateNames.length)
					names ~= ", ";
				for(int i = 0; i < repo.alternateNames.length; ++i) {
					names ~= repo.alternateNames[i];
					if(i != repo.alternateNames.length - 1)
						names ~= ", ";
				}
				Element rLink = new Element("a", names);
				rLink.tag.attr["href"] = URL_BASE ~ URL_PREFIX ~ repo.name();
				linkTD ~= rLink;
				rRow ~= linkTD;
				rRow ~= new Element("td", repo.description());
				rTable ~= rRow;
				odd = !odd;
			}
			mBody ~= rTable;
		} else {
			Repository repo;
			string[] rfields = split(URL[URL_PREFIX.length..$], "/");

			string rName = rfields[0], branch, commit, file;
			if(rfields.length > 1)
				branch = rfields[1];
			if(rfields.length > 2)
				commit = rfields[2];
			if(rfields.length > 3)
				file = rfields[3];

			if(!branch.length)
				branch = "master";

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
			} else {
				mBody ~= new Element("p", "Clone this repository:");
				Element cloneCommand = new Element("p", CLONE_PREIX ~ rName);
					cloneCommand.tag.attr["class"] = "code";
				mBody ~= cloneCommand;

				string[] files = repo.files();
				if(files.length) {
					foreach(f; files) {
						if(f == "README") {
							Element readme = new Element("pre", repo.getFile(f));
								readme.tag.attr["class"] = "quote";
							mBody ~= readme;
						}
					}

					Element fileList = new Element("ul");
					foreach(f; files)
						if(f.length)
							fileList ~= new Element("li", f);
					mBody ~= fileList;
				}
				string[] commits = repo.commits();
				if(commits.length) {
					Element commitList = new Element("ul");
					foreach(c; commits) {
						if(c.length) {
							static const int HASH_LENGTH = 40;
							Element cLink = new Element("a", 
									c[0..8] ~ " " ~ c[HASH_LENGTH + 1..$]);
							cLink.tag.attr["href"] = URL_BASE ~ URL_PREFIX ~
								rName ~ "/" ~ branch ~ "/" ~ c[0..HASH_LENGTH];

							Element linkLI = new Element("li");
							linkLI ~= cLink;
							commitList ~= linkLI;
						}
					}
					mBody ~= commitList;
				}
			}
		}
	}

	return mMColumn;
}

