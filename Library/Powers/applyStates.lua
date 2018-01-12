--{assert(0, "LUA")}--

local groups = {}
groups.Status = { "Ongoing", "Dominated", "Dazed", "Restrained", "Deafened", "Surprised", "Weakened", "Petrified", "Stunned", "Slowed", "CA", "Damage", "Immobilized", "Unconscious", "Helpless", "Blinded"}
groups.Marks = { "PC Mark", "NPC Mark",  "Quarry", "Taunt", "Shroud", "Oath", "Curses"}
groups["Power Bonus"] = { "Bonus Attack Power", "Bonus Damage Power", "Bonus Defense Power", "Bonus AC Power", "Bonus FO Power", "Bonus RE Power", "Bonus WI Power", "Bonus Dice Power"}
groups["Item Bonus"] = { "Bonus Attack Item", "Bonus Damage Item",  "Bonus Defense Item", "Bonus AC Item", "Bonus FO Item", "Bonus RE Item", "Bonus WI Item", "Bonus Dice Item" }
groups.Bonus = { "Bonus Attack Untyped", "Bonus Damage Untyped", "Bonus Defense Untyped", "Bonus AC Untyped", "Bonus FO Untyped", "Bonus RE Untyped", "Bonus WI Untyped",  "Bonus Dice Untyped"}
groups.Penalty = { "Penalty Attack", "Penalty Damage", "Penalty Defense", "Penalty AC", "Penalty FO", "Penalty RE","Penalty WI", "Penalty Dice"}
groups.Misc = {"Move", "Damage Type", "Resist", "Vuln", "Misc", "Spent", "Class", "Icons"}
local groupOrder = {"Status", "Marks", "Power Bonus", "Item Bonus", "Bonus", "Penalty" } --no misc should be added at the end automatically
local stateSuffixOrder = {Save=1,SoNT=2, EoNT=3, EoE=4,Once=5,NoSave=6}
--  no "Other", should be found automatically

-- 
local dialogoutput = [[<html>
<style>
td {
	padding: 0px;
}
th {
	padding: 0px;
}
.litUpRow {
	background-color: rgb(255, 166, 166);
}
.oddRow {
	background-color: rgb(255, 255, 255);
}
.evenRow {
	background-color: rgb(239, 246, 254);
}
.rowHeader {
	text-align: right;
	font-weight: bold;
}
table.states {
	border-width: 2px;
}
table.states th {
	background-color: rgb(64, 64, 64);
	color: white;
	font-size: medium;
}
table.modes {
	border-width: 2px;
}
table.modes th {
	background-color: rgb(64, 96, 64);
	color: white;
	font-size: medium;
	padding: 0px;
}
table.modes td {
	padding: 1px;
}
table.lights {
	border-width: 2px;
}
table.lights th {
	background-color: rgb(96, 64, 64);
	color: white;
	font-size: medium;
	padding: 0px;
}
table.lights td {
	padding: 1px;
}
table.dice {
	border-width: 3px;
}
table.dice th {
	background-color: rgb(64, 64, 96);
	color: white;
	font-size: medium;
	padding: 2px;
}
table.dice td {
	padding: 2px;
}

</style>
]]



function stateCompare(a,b)
  local ai,aj = a:find("[%+-]%d+")
  if ai then ai = a:sub(ai + 1, aj) end
  local as = a:sub(a:find("[^%(]+"))
  local ar = as:gsub("[%+-]%d+","", 1)
  local ao, ak = a:find("%(.+%)")
  if ao then ao = a:sub(ao + 1, ak - 1) end
  local bi,bj = b:find("[%+-]%d+")
  if bi then bi = b:sub(bi + 1, bj) end
  local bs = b:sub(b:find("[^%(]+"))
  local br = bs:gsub("[%+-]%d+","", 1)
  local bo, bk = b:find("%(.+%)")
  if bo then bo = b:sub(bo + 1, bk - 1) end
  if ar ~= br then return ar < br end
  if ai ~= bi then return (tonumber(ai)) < (tonumber(bi)) end
  return (stateSuffixOrder[ao] or 0) < (stateSuffixOrder[bo] or 0)
end
 


function renderGroup(group)
  local output = "<table width=\"200px\"  class=\"states\"> <tr align=\"middle\"><th colspan=\"3\">"..group.."</th>"
  -- println("&nbsp;&nbsp;<i>", group, ":</i>")
  if campaign.states[group] then
     local t = {}
	 for name, state in pairs(campaign.states[group]) do
	   table.insert(t, name)
     end
	 
	 table.sort(t, stateCompare)
	   for i, name in ipairs(t) do
	     local state = campaign.allStates[name]
	     local ss = campaign.allStates[name] or {}
		 local row = ""
		 if i % 2 == 0 then row = "evenRow" else row = "oddRow" end
		 if token.states[name] then row = "litUpRow" else end
	     output = output.."<tr valign=\"middle\" class=\""..row.."\"><td width=\"10\%\">"..i.."</td>"
		 output = output.."<td width=\"15\%\">"
		 output = output.."<img height=15 width=15 src=\""..state.image.."\"></td>"
		 output = output.."<td>"..name.."</td>"
       end		
  end
  output = output.."</table></tr>"
  return output
end



function renderTopLevelGroup(name, contents, done) 
  local output = "<table width=\"100\%\"><tr><th colspan=\"6\">"..name.."</th></tr>"
--  println("<td><th>", name, "</th></td>")
local count = "0"
  for _, group in  ipairs(contents) do
    if done then done[group] = true end
	output = output.."<td>"
    output = output..renderGroup(group)
	output = output.."</td>"
	count = count + 1
	-- witdth control
	if count == 6 or count == 12 then
	  output = output.."</tr><tr>"
	end
  end
  output = output.."</table>"
  return output
end



local doneTopLevel={}
local doneGroup = {}
for _, group in ipairs(groupOrder) do
  if groups[group] then
    doneTopLevel[group] = true
    dialogoutput = dialogoutput..renderTopLevelGroup(group, groups[group], doneGroup)
  end
end

for group, content in pairs(groups) do
  if not doneTopLevel[group] then dialogoutput= dialogoutput..renderTopLevelGroup(group, content, doneGroup) end
end

local rest = {}
for group in pairs(campaign.states) do
  if not doneGroup[group] then table.insert(rest, group) end
end

if table.length(rest) > 0 then dialogoutput= dialogoutput..renderTopLevelGroup("OTHER:", rest) end

dialogoutput= dialogoutput.."</body></html>"
UI.dialog("States",dialogoutput,"width=1680; height=950; temporary=1")

