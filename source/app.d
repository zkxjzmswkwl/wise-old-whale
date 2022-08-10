import std.stdio;
import std.array;
import std.net.curl;
import std.regex;
import std.file;
import std.conv;
import std.string;
import std.json;
import std.datetime.systime : Clock;

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

Skill* getSkill(string name)
{
	if (jsonSkills.isNull) {
		jsonSkills = parseJSON(std.file.readText("skills.json"));
	}

	return new Skill(
		jsonSkills[name]["rank"].integer,
		jsonSkills[name]["exp"].integer,
		jsonSkills[name]["level"].integer);
}

string toJSON(
	string skill,
	string rank,
	string exp,
	string level,
	bool addTrailingComma
)
{
	string ret = `
	`
		~ "\"" ~ skill ~ "\": {" ~ `
		"rank": `
		~ rank ~ `,
		"exp": `
		~ exp ~ `,
		"level": `
		~ level ~ `
	}`;

	if (addTrailingComma)
		ret = ret ~ ",";
	return ret;
}

string parseStat(string tableCol)
{
	return tableCol.split(A_PAGE_ONE)[1].split(A_CLOSE)[0].replace(",", "");
}

void main()
{
	writeln(getSkill("Construction").level);
	writeln(getSkill("Constitution").level);
	writeln(getSkill("WoodCutting").exp);
	// string nowTime = Clock.currTime().toISOString();

	// string scoreTable = szContent.idup.split("<tbody>")[1].split("</tbody>")[0];
	// string regexTest = split(scoreTable, "/<tr >|<tr class=\"oddRow\">/g")[0];

	// string lastSkill = "Sailing";
	// string[] iterateMe = regexTest.split("\n");

	// string jsonBlob = "{\n\t\"timestamp\": \"" ~  ~ "\",";
	// for (int i = 0; i < iterateMe.length; i++)
	// {
	// 	if (canFind(iterateMe[i], A_PAGE_ONE))
	// 	{
	// 		int skillIndex = iterateMe[i].split(TABLE_EQUALS)[1].split(TABLE_EQUALS_END)[0].to!int;
	// 		if (lastSkill != skillArray[skillIndex])
	// 		{
	// 			writeln(skillArray[skillIndex]);
	// 			lastSkill = skillArray[skillIndex];

	// 			// Only add trailing comma to last skill. This is a bit hacky. too bad.
	// 			bool shouldAddComma = lastSkill != "Archaeology";
	// 			jsonBlob = jsonBlob ~ toJSON(lastSkill,
	// 				parseStat(iterateMe[i]),
	// 				parseStat(iterateMe[i + 1]),
	// 				parseStat(iterateMe[i + 2]),
	// 				shouldAddComma);
	// 		}
	// 	}
	// }

	// jsonBlob = jsonBlob ~ "\n}";

	// std.file.write("girthyplayer-" ~ nowTime ~ ".json", jsonBlob);
}
