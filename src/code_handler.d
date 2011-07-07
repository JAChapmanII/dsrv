import std.xml;
import std.path;
import std.algorithm;

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

	mBody ~= new Element("h3", URL);
	Repository[] repos = Repository.parseRepositories();
	if(!repos.length) {
		mBody ~= new Element("p", "There are no repositories");
	} else {
		if(URL == "code") {
			Element rTable = new Element("table");
			foreach(repo; repos) {
				Element rRow = new Element("tr");
				rRow ~= new Element("td", repo.language());
				Element linkTD = new Element("td");
				Element rLink = new Element("a", repo.name());
				rLink.tag.attr["href"] = URL_BASE ~ URL_PREFIX ~ repo.name();
				linkTD ~= rLink;
				rRow ~= linkTD;
				rRow ~= new Element("td", repo.description());
				rTable ~= rRow;
			}
			mBody ~= rTable;
		} else {
			Repository repo;
			string rName = URL[URL_PREFIX.length..$];
			while(count(rName, '/'))
				rName = dirname(rName);

			foreach(r; repos)
				if(r.name == rName)
					repo = r;
			if(repo is null) {
				mBody ~= new Element("p", "No repository by that name");
			} else {
				mBody ~= new Element("p", "Clone this repository:");
				Element cloneCommand = new Element("p", CLONE_PREIX ~ rName);
					cloneCommand.tag.attr["class"] = "code";
				mBody ~= cloneCommand;
			}
		}
	}

	return mMColumn;
}

