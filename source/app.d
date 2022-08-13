import std.stdio;
import std.array;
import std.net.curl;
import std.regex;
import std.file;
import std.conv;
import std.string;
import std.json;
import std.getopt;
import std.algorithm;
import std.datetime.systime : Clock;

import vibe.d;

string A_PAGE_ONE = "&amp;page=1\">";
string A_CLOSE = "</a>";
string TABLE_EQUALS = "&amp;table=";
string TABLE_EQUALS_END = "&amp;";

auto skillArray = [
	"Total",
	"Attack",
	"Defense",
	"Strength",
	"Constitution",
	"Ranged",
	"Prayer",
	"Magic",
	"Cooking",
	"WoodCutting",
	"Fletching",
	"Fishing",
	"Firemaking",
	"Crafting",
	"Smithing",
	"Mining",
	"Herblore",
	"Agility",
	"Thieving",
	"Slayer",
	"Farming",
	"Runecrafting",
	"Hunter",
	"Construction",
	"Summoning",
	"Dungoneering",
	"Divination",
	"Invention",
	"Archaeology"
];

struct Skill
{
	long rank;
	long exp;
	long level;
}

JSONValue jsonSkills;
JSONValue newSkills;

Skill* getNSkill(string name)
{
	if (newSkills.isNull)
	{
		newSkills = parseJSON(std.file.readText("girthyplayer-20220812T144032.5231764.json"));
	}

	return new Skill(
		newSkills[name]["rank"].str.to!int,
		newSkills[name]["exp"].str.to!int,
		newSkills[name]["level"].str.to!int);
}

Skill* getSkill(string name)
{
	if (jsonSkills.isNull)
	{
		jsonSkills = parseJSON(std.file.readText("skills.json"));
	}

	return new Skill(
		jsonSkills[name]["rank"].integer,
		jsonSkills[name]["exp"].integer,
		jsonSkills[name]["level"].integer);
}

JSONValue toJSON(
	string skill,
	string rank,
	string exp,
	string level,
)
{
	auto skillBlob = JSONValue(string[string].init);
	skillBlob["rank"] = rank;
	skillBlob["exp"] = exp;
	skillBlob["level"] = level;

	return skillBlob;
}

JSONValue parsePlayerBlob(string blobPath)
{
	return parseJSON(blobPath);
}

string parseStat(string tableCol)
{
	return tableCol.split(A_PAGE_ONE)[1].split(A_CLOSE)[0].replace(",", "");
}


string[] getDirContents(string dir) 
{
	string[] dirBlobs;

	foreach (DirEntry e; dirEntries(dir, SpanMode.breadth))
		dirBlobs ~= e.name;

	return dirBlobs;
}

string concatenateBlobs(string[] blobs...)
{
	string ret = "[\n";
	foreach (string blob; blobs)
	{
		ret ~= blob ~ ",\n";
	}
	return ret ~= "]";
}

void player(HTTPServerRequest req, HTTPServerResponse res)
{
	/* 
		I was hoping vibed had a non silly way of doing this.
		To be honest, I'm not sure if it does.
		If it does, I did not find it. So, here I am being silly.
	*/
	string[] optionalParams;
	if (req.queryString.length > 1)
		optionalParams = req.queryString.split("=");
	
	string latest;
	if (optionalParams.length > 0)
	{
		if (optionalParams[0])
		{
			// This is just assuming that `latest` will always be the first parameter.
			// Which is just overtly silly. Too bad.
			latest = optionalParams[1];
		}
	}

	string[] blobs;
	auto rsn = req.params["rsn"];

	foreach (string blobPath; getDirContents("player-data/" ~ rsn ~ "/"))
		blobs ~= std.file.readText(blobPath);

	string concatenatedBlobs = concatenateBlobs(blobs);

	JSONValue baseBlob;

	if (latest == "silly")
	{
		JSONValue latestBlob;
		JSONValue previousSession = parseJSON(blobs[blobs.length - 2]);
		JSONValue latestSession = parseJSON(blobs[blobs.length - 1]);

		foreach (string skillName; skillArray)
		{
			int pS, lS;
			auto pVal = previousSession[skillName]["exp"].str;
			auto lVal = latestSession[skillName]["exp"].str;

			// If they have no entry for this skill, move on to the next.
			if (canFind(pVal, "-") || canFind(lVal, "-"))
				continue;

			pS = previousSession[skillName]["exp"].str.to!int;
			lS = latestSession[skillName]["exp"].str.to!int;

			if (pS != lS)
			{
				baseBlob[skillName] = JSONValue(string[string].init);
				baseBlob[skillName]["expGained"] = lS - pS;
			}
		}

		res.writeBody(baseBlob.toPrettyString());
		return;
	}

	JSONValue skillBlobs = parseJSON(concatenatedBlobs);

	baseBlob["snapshots"] = skillBlobs;
	baseBlob["sessionCount"] = blobs.length;


	res.writeBody(baseBlob.toPrettyString());
}

void startWebServer(ushort port)
{
	auto router = new URLRouter;
	router.get("/rsn/:rsn", &player);
	
	auto settings = new HTTPServerSettings;
	settings.sessionStore = new MemorySessionStore;
	settings.port = port;

	listenHTTP(settings, router);

	runApplication();
}

void main(string[] args)
{

	// Uncommenting this then building will give you the "tracker".
	// e.g wiseoldwhale.exe --rsn="Zezima"

	// string rsn;
	// getopt(args, "rsn", &rsn);
	// writeln(rsn);

	// string nowTime = Clock.currTime().toISOString();

	// auto client = HTTP();
	// client.addRequestHeader("User-Agent", "Mozilla: Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.3 Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/43.4");
	// char[] szContent = get("https://secure.runescape.com/m=hiscore/compare?user1=" ~ rsn, client);
	// string scoreTable = szContent.idup.split("<tbody>")[1].split("</tbody>")[0];
	// string regexTest = split(scoreTable, "/<tr >|<tr class=\"oddRow\">/g")[0];

	// string lastSkill = "Sailing";
	// string[] iterateMe = regexTest.split("\n");

	// JSONValue skills;

	// for (int i = 0; i < iterateMe.length - 1; i++)
	// {
	// 	if (canFind(iterateMe[i], A_PAGE_ONE))
	// 	{
	// 		int skillIndex = iterateMe[i].split(TABLE_EQUALS)[1].split(TABLE_EQUALS_END)[0].to!int;
	// 		if (lastSkill != skillArray[skillIndex])
	// 		{
	// 			writeln(skillArray[skillIndex]);
	// 			lastSkill = skillArray[skillIndex];

	// 			JSONValue skillBlob = toJSON(
	// 				iterateMe[i],
	// 				parseStat(iterateMe[i]),
	// 				parseStat(iterateMe[i + 1]),
	// 				parseStat(iterateMe[i + 2]),
	// 			);

	// 			skills[lastSkill] = skillBlob;
	// 		}
	// 	}
	// }

	// std.file.write("player-data/" ~ rsn ~ "/" ~ rsn ~ "-" ~ nowTime ~ ".json", skills.toPrettyString());

	startWebServer(6969);
}
