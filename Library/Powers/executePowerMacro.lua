--{assert(0, "LUA")}--
function setupVars ()
  return {
    POWER_TYPES={"at-will","encounter","daily","feature","magic item: at-will","magic item: encounter","magic item: daily","magic item: healing surge","magic item: consumable","magic item: property","recharge 2","recharge 3","recharge 4","recharge 5","recharge 6","recharge special","aura","other"},
    POWER_COLORS={"#5B8F62","#7B1429","#424142","teal","#D6A210","#D6A210","#D6A210","#D6A210","#D6A210","#D6A210","purple","purple","purple","purple","purple","purple","blue","fuchsia"},
    MACRO_BUTTON_COLORS={"green","red","darkgray","cyan","orange","orange","orange","orange","orange","orange","magenta","magenta","magenta","magenta","magenta","magenta","blue","pink"},
    MACRO_BUTTON_FONT_COLORS={"black","white","white","black","green","red","black","blue","purple","navy","white","white","white","white","white","white","white","black"},
    MACRO_BUTTON_SORT_PREFIXES={"aboleth","beholder","cyclops","dragon","ettin","fomorian","githyanki","harpy","kobold","lich","minotaur","naga","otyugh","pseudodragon","rakshasa","sahuagin","troglodyte","unicorn","vampire","warforged","yuan-ti","zombie"},
    MACRO_BUTTON_FONT_SIZES={"1.00em","0.95em","1.05em","1.15em"},
    MACRO_BUTTON_FONT_SIZE_NAMES={"Normal","Small","Large","Larger"},
    MACRO_BUTTON_MIN_WIDTHS={"None","23","36","60","84","97","133"},
    MACRO_BUTTON_MIN_WIDTH_NAMES={"No minimum","1/4 width","1/3 width","1/2 width","2/3 width","3/4 width","Full width"},
    ACTION_TYPES={"standard","move","minor","immediate interrupt","immediate reaction","opportunity","free","no action"},
    ATTACK_TYPES={"Melee","Ranged","Close","Area","Personal","Aura"},
    SUSTAIN_ACTION_TYPES={"Standard","Move","Minor","Free"},
    ABILITY_BONUS_NAMES={"None","Strength","Constitution","Dexterity","Intelligence","Wisdom","Charisma"},
    ATTACK_ROLLS={"1d20","2d20 drop lowest","2d20 drop lowest crit on equal","2d20 drop highest","No Roll"},
    ABILITY_BONUSES={"0","StrBonus","ConBonus","DexBonus","IntBonus","WisBonus","ChaBonus"},
    DEFENSE_NAMES={"None","AC","Fortitude","Reflex","Will"},
    REPETITIONS={"0","1","2","3","4","5","6","7","8","9","10"},
    DAMAGE_DICE={"No Damage Roll (only apply EXTRA damage)","Damage bonus only (apply boni to damagerolls)","1x Damage Roll","2x Damage Roll","3x Damage Roll","4x Damage Roll","5x Damage Roll","6x Damage Roll","7x Damage Roll","8x Damage Roll","9x Damage Roll"},
    DAMAGE_ROLL={"[W] (from equipment)","d1","d2","d3","d4","d5","d6","d7","d8","d9","d10","d11","d12","d13","d14","d15","d16","d17","d18","d19","d20"},
    WEAPON_SLOTS={"None","Mainhand","Offhand","Implement1","Implement2"},
    DAMAGE_KEYWORDS={"Acid","Cold","Fire","Force","Lightning","Necrotic","Psychic","Radiant","Thunder"},
    S_WIDTH=15,
    M_WIDTH=40,
    L_WIDTH=60,
    TARGET_CHOICE_NONE = 0,
    TARGET_CHOICE_TEXTBOX = 1,
    TARGET_CHOICE_SELECTION = 2
  }
end

VARS = setupVars()
BIG = tokens.getLibProperty("TOOLTIP_BIG_FONT_SIZE", "Lib:Veg").value
BIGGER = tokens.getLibProperty("TOOLTIP_BIGGER_FONT_SIZE", "Lib:Veg").value
TOOLTIPS = tokens.getLibProperty("NPC_ROLL_TOOLTIPS_ARE_SECRET", "Lib:Veg").value
SHOW_PC = tokens.getLibProperty("ATTACKS_COMPARED_TO_PC_DEFENSES",  "Lib:Veg").value
SHOW_NPC = tokens.getLibProperty("ATTACKS_COMPARED_TO_NPC_DEFENSES",  "Lib:Veg").value
IMAGE_SIZE = tokens.getLibProperty("TARGET_SELECTION_IMAGE_SIZE", "Lib:Veg").value
ICONSIZE = 50
NPC_POWERNAMES_ARE_SECRET = tokens.getLibProperty("NPC_POWERNAMES_ARE_SECRET",    "Lib:Veg").value
NPC_POWERS_ARE_SECRET = tokens.getLibProperty("NPC_POWERS_ARE_SECRET",    "Lib:Veg").value
CONDITIONALS = token.properties.CustomRestCode.converted
TABLE_START = "<table border=0 cellspacing=0><tr bgcolor='#D6D7C6'><td><i>"
TABLE_END = "</i></td></tr></table>"
DISABLE = tokens.getLibProperty("DISABLE_CUSTOM_CODE_IN_POWERS", "Lib:Veg").value
STATE_TRANSLATIONS = tokens.getLibProperty("STATE_TRANSLATIONS", "Lib:Veg").converted
function translateState(oldState)
  return STATE_TRANSLATIONS[oldState] or oldState
end

function match(match, keywords, default)
  if match == nil or match == "0" or match == 0 or match == "--" or match == "." then return default, "" end
  if keywords == nil then keywords = {} end
  match=fromStr(match, ",") -- force List
  local found = default or #match > 0
  for i, kw in ipairs(match) do
    if string.startsWith(kw, "!") and kw ~= "!" then 
      if table.contains(keywords, kw:sub(2,-1):lower()) then return false end
    else 
      if not table.contains(keywords, kw:lower()) then return false end
    end
  end 
  return found, match
end

function evalConditional(cond, attack, target)
  local found1, match1 = match(cond.Keyword, attack.Keywords, true)
  local found2, match2 = match(cond.Keyword2, attack.Keywords, false)
  local found3, match3 = match(cond.Keyword3, attack.Keywords, false)
  if not found1 and not found2 and not found3 then return end
  local inverse = cond.Reverse == 1
  local text = ""
  local targetSpecific = false
 -- local result = {Text = "", Value = 0, RawText = "", Target = false}
  if cond.From == 0 then --Keyword only
  elseif cond.From == 1 then --VS Defense
    if attack.VsDefense == cond.Defense and inverse or attack.VsDefense ~= cond.Defense and not inverse then return
    else text = "vs "..(inverse and "not " or "")..VARS.DEFENSE_NAMES[cond.Defense + 1] end
  elseif cond.From == 2 then --VS Defense
    if attack.AttackAbility == cond.Ability and inverse or attack.AttackAbility ~= cond.Ability and not inverse then return
    else text = "used "..(inverse and "not " or "")..VARS.ABILITY_BONUS_NAMES[cond.Ability + 1] end
  elseif cond.From == 3 then -- Attack Type
    if attack.Type == cond.Type and inverse or attack.Type ~= cond.Type and not inverse then return
    else text = (inverse and "not " or "")..VARS.ATTACK_TYPES[cond.Type + 1] end
  elseif cond.From == 4 then --CA
    if attack.CA and inverse or not attack.CA and not inverse then return
    else 
      text = inverse and "no CA" or "CA"
      targetSpecific = true
   end
  elseif cond.From == 5 then -- Attack Type
    if attack.Roll == cond.Roll and inverse or attack.Roll ~= cond.Roll and not inverse then return
    else text = (inverse and "not " or "")..VARS.ATTACK_ROLLS[cond.Roll + 1] end
  elseif cond.From == 6 then -- Target State
    if target == nil then return end
    local state = translateState(cond.State)
    if target.states[state] and inverse or not target.states[state] and not inverse then return
    else 
     text = "vs "..(inverse and "not " or "")..state 
     targetSpecific = true
    end
  elseif cond.From == 7 then -- My State
    local state = translateState(cond.State)
    if token.states[state] and inverse or not token.states[state] and not inverse then return
    else text = (inverse and "not " or "")..state end
  elseif cond.From == 8 then
    local kw = false;
    for i, damagekw in ipairs(VARS.DAMAGE_KEYWORDS) do
      if table.contains(attack.Keywords, damagekw) then kw = true end
    end
    if not kw and inverse or kw and not inverse then return
    else text = (inverse and "not " or "").."untyped" end
  elseif cond.From == 9 then
    local exp = eval(cond.Expression)
    if (exp == 1 or exp == true or exp == "1") then exp = true else exp = false end
    if exp and inverse or not exp and not inverse then return
    else text = (inverse and "not " or "").."Expression" end
  end
  local text2 = text;
  if (match1 and #match1 > 0 and found1) then text2 = toStr(match1).." "..text end
  if (found2) then text2 = toStr(match2).." "..text end
  if (found3) then text2 = toStr(match3).." "..text end

  if (cond.Name ~= nil and cond.Name ~= "0" and cond.Name ~= 0 and cond.Name ~="") then text = cond.Name..(text ~= "" and ": "..text or "")
  else text = text2
  end

  return {Text = text, Value = cond.Value or 0, RawText = text2, Target = targetSpecific, Max=cond.Max or 0}
end

function evalDamageConditional(cond, attack, target, state) 
  
  if (cond ~= nil) then
    if cond.Affects == 6 or cond.Affects == 3 and attack.DmgDice ~= 0 then

      local r = evalConditional(cond, attack, target)
      if r ~= nil then
        local c = eval(attack.isCrit and r.Max or r.Value)
        if r.Target then 
          table.insert(state.targeted, {value = c, text = r.Text})
        else 
          table.insert(state.conditional, {value = c, text = r.Text})
        end
      end
    elseif cond.Affects == 1 and attack.isCrit then
      local r = evalConditional(cond, attack, target)
      if r ~= nil then
        state.dmgDiceBonus = r.Value
      end
    elseif cond.Affects == 7 and attack.isCrit then
      local r = evalConditional(cond, attack, target)
      if r ~= nil then
        local critroll = r.Value:replace("\\D","")
        if critroll ~= "" then state.critRoll = critroll end
      end
    elseif cond.Affects == 8 then
      local r = evalConditional(cond, attack, target)
      if r ~= nil then
        state.dmgDiceMultiplier = state.dmgDiceMultiplier + r.Value
        state.dmgDiceMultiplier = math.max(0, state.dmgDiceMultiplier)
      end
    elseif cond.Affects == 4 then
      local r = evalConditional(cond, attack, target)
      if r ~= nil then
        state.dmgDice = r.Value
        state.dmgDiceMax = r.Max
      end
    end
  end
  return state
end

function getWeapon(attack)
  local equipname = "--"
  if attack and attack.Equip ~= 0 then equipname = token.properties[VARS.WEAPON_SLOTS[attack.Equip + 1]].value end
  local equip = nil
  if equipname ~= nil and equipname ~= "--" then equip = token.properties.WeaponLibrary.converted[equipname] end
  if equip == nil then return tokens.getLibProperty("UNARMED_ATTACK", "Lib:Veg").converted end
  return equip
end

function makeDamageState(attack, equip)
  local state = {
    dmgDice = equip.DmgDice,
    dmgDiceMax = equip.DmgDiceMax,
    dmgDiceMultiplier = math.max(attack.DmgDice - 1, 0),
    dmgRoll = attack.DmgRoll ~= nil and attack.DmgRoll ~= "" and attack.DmgRoll or 0,
    conditional = {},
    targeted = {},
    dmgDiceBonus = equip.DmgDiceBonus,
    critRoll = equip.CritDice or 0
  }
  state.stat = eval(VARS.ABILITY_BONUSES[attack.DmgAbility + 1])
  state.enh = 0
  if not (attack.Chk_IgnoreEnh == 1) and attack.DmgDice ~= 0 then state.enh = tonumber(equip.Enhance or 0) end
  state.misc = 0
  if not (attack.Chk_IgnoreMisc == 1) and attack.DmgDice ~= 0 then state.misc = tonumber(equip.Dmg or 0) end
  state.dmgType = attack.DmgType
  if state.dmgType == nil or state.dmgType == 0 or state.dmgType:lower() == "auto" or state.dmgType == "--" or state.dmgType == "." then
    local dm = {}
    for i, value in ipairs(VARS.DAMAGE_KEYWORDS) do
      if table.contains(attack.Keywords, value:lower()) and not table.contains(dm, value:lower()) then table.insert(dm, value:lower()) end
    end 
    local j, k = next(dm, nil)
    state.dmgType = ""
    while j ~= nil do
      local val = k
      j, k = next(dm, j)
      if state.dmgType ~= "" then state.dmgType = state.dmgType..(j == nil and " and " or ", ")..val 
      else state.dmgType = val end
    end
  end
  if state.dmgType == "untyped" then state.dmgType = "" end
  if tonumber(state.dmgRoll or 0) > 0 then
    state.dmgDice = "d"..tostring(state.dmgRoll or 0)
    state.dmgDiceMax =  tonumber(state.dmgRoll or 0)
  end
  return state
end

function executeDamage(attack, equip)
  attack.isCrit = false
  local equip = getWeapon(attack)
  local state = makeDamageState(attack, equip)
  state.powerBonus = tonumber(eval(attack.DmgBonus) or 0)
  if not (attack.Chk_IgnoreCondDmg == 1) then
    for i = 1, 100 do
      local c = "Conditional"..i
      if equip[c] ~= nil then state = evalDamageConditional(equip[c], attack, attack.target, state) end
      if CONDITIONALS[c] ~= nil then state = evalDamageConditional(CONDITIONALS[c], attack, attack.target, state) end
    end
  end 
  if state.dmgDice == 0 then state.dmgDice = "0d0" end
  local dmgDiceList = {}
  local dmgDiceResult = 0
  for i = 1, state.dmgDiceMultiplier do
    local r = eval(state.dmgDice)
    table.insert(dmgDiceList, r)
    dmgDiceResult = dmgDiceResult + r
  end
  local result = dmgDiceResult + state.stat + state.enh + state.misc + state.powerBonus + tonumber(attack.dmgMod or 0)
  for i, v in ipairs(state.conditional) do
    result = result + v.value
  end
  local t = 0
  for i, v in ipairs(state.targeted) do
    t = t + v.value
  end
  if not token.npc or TOOLTIPS == 0 then
    print("<span title='<html>")
    if attack.Chk_MultiDmgRolls == 1 or attack.iteration == 1 then
      if token.pc then print("<font size=", BIG, "><i>", equip.Name, ":&nbsp;</i></font>") end
      if dmgDiceResult > 0 then print("<font size=", BIG, ">", dmgDiceResult, "</font> (", state.dmgDiceMultiplier, "[", state.dmgDice, "]:", toStr(dmgDiceList)) end
      if state.powerBonus ~= 0 then print("+ <font size=", BIG, ">", state.powerBonus, "</font> (", attack.DmgBonus, ")") end
      if attack.DmgAbility ~= 0 then print("+ <font size=", BIG, ">", state.stat, "</font> (", VARS.ABILITY_BONUSES[attack.DmgAbility + 1] ,")") end
      if state.enh ~= 0 then print("+ <font size=", BIG, ">", state.enh, "</font> (enhance)") end
      if state.misc ~= 0 then print("+ <font size=", BIG, ">", state.misc, "</font> (misc.)") end
      for i, v in ipairs(state.conditional) do print("+ <font size=", BIG, ">", v.value, "</font> (", v.text, ")") end 
      if attack.dmgMod ~= 0 then print("+ <font size=", BIG, ">", attack.dmgMod, "</font> (temp)") end
      print("= <font size=",BIGGER, ">", result, "</font>")
    end
    for i, v in ipairs(state.targeted) do print("+ <font size=", BIG, ">", v.value, "</font> (", v.text, ")") end
    print("</html>'>")
    if attack.Chk_MultiDmgRolls == 1 or attack.iteration == 1 then print("<i><b>", result, t > 0 and " + "..t or "","</b> ", state.dmgType, " damage</i>.")
    elseif t > 0 then print("<i><b> + ", t, "</b> ", state.dmgType, " damage</i>.") end
    print("</span>")
  else
    if attack.Chk_MultiDmgRolls == 1 or attack.iteration == 1 then print("<i><b>", result, t>0 and " + "..t or "","</b> ", state.dmgType, " damage</i>.")
    elseif t > 0 then print("<i><b> + ", t, "</b> ", state.dmgType, " damage</i>.") end
  end
end

function executeCrit(attack, equip)
  attack.isCrit = true
  local state = makeDamageState(attack, equip)
  state.powerBonus = tonumber(eval(attack.DmgBonusMax) or 0)
  if not (attack.Chk_IgnoreCondDmg == 1) then
    for i = 1, 100 do
      local c = "Conditional"..i
      if equip[c] ~= nil then state = evalDamageConditional(equip[c], attack, attack.target, state) end
      if CONDITIONALS[c] ~= nil then state = evalDamageConditional(CONDITIONALS[c], attack, attack.target, state) end
    end
  end
  local dmgDiceResult = state.dmgDiceMax * state.dmgDiceMultiplier
  if state.critRoll <= 0 then state.critRoll = "0d0" else state.critRoll = "d"..state.critRoll end
  local critDiceList = {}
  local critDiceResult = 0
  for i = 1, equip.Enhance do
    local r = eval(state.critRoll)
    table.insert(critDiceList, r)
    critDiceResult = critDiceResult + r
  end
  local result = dmgDiceResult + state.stat + state.enh + state.misc + state.powerBonus + tonumber(attack.dmgMod or 0)
  for i, v in ipairs(state.conditional) do
    result = result + v.value
  end
  local t = 0
  for i, v in ipairs(state.targeted) do
    t = t + v.value
  end
  local critResultBonus = eval(state.dmgDiceBonus)
  local critDmgType = equip.DmgTypeOnCrit
  local critExtra=critResultBonus+critDiceResult
  if critDmgType == nil or critDmgType == "untyped" or critDmgType == 0 then critDmgType =  "" end
  if not token.npc or TOOLTIPS == 0 then
    print("<span title='<html>")
    if token.pc then print("<font size=", BIG, "><i>", equip.Name, ":&nbsp;</i></font>") end
    if dmgDiceResult > 0 then print("<font size=", BIG, ">", dmgDiceResult, "</font> (", state.dmgDiceMultiplier, "[", state.dmgDice, "]:MAX") end
    if state.powerBonus ~= 0 then print("+ <font size=", BIG, ">", state.powerBonus, "</font> (", attack.DmgBonus, ":MAX)") end
    if attack.DmgAbility ~= 0 then print("+ <font size=", BIG, ">", state.stat, "</font> (", VARS.ABILITY_BONUSES[attack.DmgAbility + 1] ,")") end
    if state.enh ~= 0 then print("+ <font size=", BIG, ">", state.enh, "</font> (enhance)") end
    if state.misc ~= 0 then print("+ <font size=", BIG, ">", state.misc, "</font> (misc.)") end
    for i, v in ipairs(state.conditional) do print("+ <font size=", BIG, ">", v.value, "</font> (", v.text, ")") end 
    if attack.dmgMod ~= 0 then print("+ <font size=", BIG, ">", attack.dmgMod, "</font> (temp)") end
    print("= <font size=", BIGGER, " color=red>", result, "</font>")
    if critDiceResult > 0 then print(" <font size=", BIG, " color=red>+", critDiceResult, "</font> (",equip.Enhance,"[", state.critRoll, "]: ",toStr(critDiceList), ")") end
    if critResultBonus > 0 then print(" <font size=", BIG, " color=red>+", critResultBonus, "</font> (", state.dmgDiceBonus, ")") end
    for i, v in ipairs(state.targeted) do print("+ <font size=", BIG, ">", v.value, "</font> (", v.text, ")") end
    print("</html>'>")
    print("<font color='red'><i>CRIT: <b>", result)
    if t>0 then print (" + ",t) end
    print("</b> ", state.dmgType, " damage")
    if critExtra > 0 then print(", plus ", critExtra,  " ", critDmgType, " damage") end
    print("</b></i></font>")
    print("</span>")
  else
    print("<font color='red'><i>CRIT: <b>", result)
    if t>0 then print (" + ",t) end
    print("</b> ", state.dmgType, " damage")
    if critExtra > 0 then print(", plus ", critExtra,  " ", critDmgType, " damage") end
    print("</b></i></font>")
  end
end

function executeAttackRoll(attack, equip) 
  local die = 0
  local die1 = 0
  local die2 = 0
  if attack.Roll == 0 or attack.Roll == nil then 
    die1 = dice.roll(1, 20)
    die = die1
  elseif attack.Roll == 1 then
    die1 = dice.roll(1, 20)
    die2 = dice.roll(1, 20)
    die = math.max(die1, die2)
  elseif attack.Roll == 2 then
    die1 = dice.roll(1, 20)
    die2 = dice.roll(1, 20)
    die = math.max(die1, die2)
    if die > 1 and die1 == die2 then die = 20 end
  elseif attack.Roll == 3 then
    die1 = dice.roll(1, 20)
    die2 = dice.roll(1, 20)
    die = math.min(die1, die2)
  end
  local lvl = 0
  if not (attack.Chk_IgnoreLevel == 1) then lvl = token.properties.LevelBonus.value end
  local stat = eval(VARS.ABILITY_BONUSES[attack.AttackAbility + 1])
  local prof = 0
  if not (attack.Chk_IgnoreProf == 1) and table.contains(attack.Keywords, "weapon") then prof = equip.Prof end
  local conditional = {}
  if not (attack.Chk_IgnoreCond == 1) then
    for i = 1, 100 do
      local c = "Conditional"..i
      if equip[c] ~= nil and equip[c].Affects == 2 then 
        local r = evalConditional(equip[c], attack, attack.target)
        if r ~= nil then table.insert(conditional, {value=eval(r.Value), text=r.Text}) end
      end
      if CONDITIONALS[c] ~= nil and CONDITIONALS[c].Affects == 2 then 
        local r = evalConditional(CONDITIONALS[c], attack, attack.target)
        if r ~= nil then table.insert(conditional, {value=eval(r.Value), text=r.Text}) end
      end
    end
  end
  local feat = 0
  local enh = equip.Enhance or 0
  local misc = equip.Atk or 0
  local ca = attack.CA and 2 or 0
  if not (attack.Chk_IgnoreFeat == 1) then feat = equip.AtkFeat or 0 end
  local powerBonusEval = eval(attack.AttackBonus) or 0
  local result = die+lvl+stat+prof+enh+feat+misc+ca+powerBonusEval+tonumber(attack.atkMod or 0)
  local result1 = die1+lvl+stat+prof+enh+feat+misc+ca+powerBonusEval+tonumber(attack.atkMod or 0)
  local result2 = die2+lvl+stat+prof+enh+feat+misc+ca+powerBonusEval+tonumber(attack.atkMod or 0)
  for i, v in ipairs(conditional) do
    result = result + v.value
    result1 = result1 + v.value
    result2 = result2 + v.value
  end
  local vsDefense = VARS.DEFENSE_NAMES[attack.VsDefense + 1]
  if not token.npc or TOOLTIPS == 0 then
    print("<td>&nbsp;<span title='<html>")
    if token.pc then print("<font size=", BIG, "><i>", equip.Name, ":&nbsp;</i></font>") end
    print("<font size=", BIG,">",die1)
    if attack.Roll ~= nil and attack.Roll>0 and attack.Roll<4 then print(", ", die2," &#8658; ", die) end
    print("</font> (d20)")
    if lvl > 0 then print("+ <font size=", BIG, ">", lvl, "</font> (&frac12; Lvl)") end
    if attack.DmgAbility ~= 0 then print("+ <font size=", BIG, ">", stat, "</font> (", VARS.ABILITY_BONUSES[attack.DmgAbility + 1] ,")") end
    if prof > 0 then print("+ <font size=", BIG, ">", prof, "</font> (prof.)") end
    if enh > 0 then print("+ <font size=", BIG, ">", enh, "</font> (enhance)") end
    if feat > 0 then print("+ <font size=", BIG, ">", feat, "</font> (feat)") end
    if misc > 0 then print("+ <font size=", BIG, ">", misc, "</font> (misc)") end
    for i, v in ipairs(conditional) do print("+ <font size=", BIG, ">", v.value, "</font> (", v.text, ")") end
    if ca > 0 then print("+ <font size=", BIG, ">", ca, "</font> (CA)") end
    if powerBonusEval > 0 then print("+ <font size=", BIG, ">", powerBonusEval, "</font> (",attack.AttackBonus,")") end
    if attack.atkMod ~= 0 then print("+ <font size=", BIG, ">", attack.atkMod, "</font> (temp)") end
    print("= <font size=",BIGGER,">",result1)
    if attack.Roll ~= nil and attack.Roll>0 and attack.Roll<4 then print(", ", result2," &#8658; ", result) end
    print("</font></html>'>")
  end
  if attack.Roll == nil or attack.Roll < 4 then
    print("<i>Rolled <b>", result1)
    if attack.Roll ~= nil and attack.Roll>0 then print(", ", result2) end
    print("</b> ")
    if vsDefense ~= "None" then print("vs. ", vsDefense) end
  elseif vsDefense ~= "None" then print("<i><b>",result, "</b> vs. ", vsDefense)
  end
  if (attack.target ~= nil and vsDefense ~= "None") and (attack.target.propertyType == "Player (VEG)" or attack.target.propertyType == "Monster (VEG)") then 
    executeComparison(attack.target, result, vsDefense) 
  end
  print("</i>")
  if not token.npc or TOOLTIPS == 0 then print("</span>") end
  print("&nbsp;</td>")
  return die
end

function executeComparison(target, result, defense) 
  local targetNumber = 0
  local show = false
  if target.propertyType == "Player (VEG)" then
    if defense == "AC" then targetNumber = getAC(target)
    elseif (defense == "Will") then targetNumber = getWill(target)
    elseif (defense == "Fortitude") then targetNumber = getFortitude(target)
    elseif (defense == "Reflex") then targetNumber = getReflex(target)
    end
    show = SHOW_PC == 1
  elseif target.propertyType == "Monster (VEG)" then
    targetNumber = target.properties[defense].value
    show = SHOW_NPC == 1
  end
  if show then print(result>=targetNumber and "<b> (Hit)</b>" or "<b> (Miss)</b>") end
end

function getAC(target)
  local acforce = target.properties.ACForce.value
  local acAbility = 0
  if acforce == 0 then acAbility = math.max(target.properties.DexBonus.value, target.properties.IntBonus.value)
  elseif acforce >= 2 then acAbility = target.properties[VARS.ABILITY_BONUSES[acforce]].value end
  local bonus = fromStr(target.properties.ACBonuses.value)
  return 10 + target.properties.LevelBonus.value + acAbility + target.properties.ArmorBonus.value + target.properties.ShieldBonus.value + (bonus.Class or 0) + (bonus.Feat or 0) + (bonus.Enhance or 0) + (bonus.Item or 0) + (bonus.Misc or 0) + (bonus.Temporary or 0) + (bonus.tillShortRest or 0) + (bonus.tillExtRest or 0)
end

function getFortitude(target)
  local force = target.properties.FortForce.value
  local ability = 0
  if force == 0 then ability = math.max(target.properties.StrBonus.value, target.properties.ConBonus.value)
  elseif force >= 2 then ability = target.properties[VARS.ABILITY_BONUSES[force]].value end
  local bonus = fromStr(target.properties.FortBonuses.value)
  return 10 + target.properties.LevelBonus.value + ability + (bonus.Class or 0) + (bonus.Feat or 0) + (bonus.Enhance or 0) + (bonus.Item or 0) + (bonus.Misc or 0) + (bonus.Temporary or 0) + (bonus.tillShortRest or 0) + (bonus.tillExtRest or 0)
end

function getWill(target)
  local force = target.properties.WillForce.value
  local ability = 0
  if force == 0 then ability = math.max(target.properties.WisBonus.value, target.properties.ChaBonus.value)
  elseif force >= 2 then ability = target.properties[VARS.ABILITY_BONUSES[force]].value end
  local bonus = fromStr(target.properties.WillBonuses.value)
  return 10 + target.properties.LevelBonus.value + ability + (bonus.Class or 0) + (bonus.Feat or 0) + (bonus.Enhance or 0) + (bonus.Item or 0) + (bonus.Misc or 0) + (bonus.Temporary or 0) + (bonus.tillShortRest or 0) + (bonus.tillExtRest or 0)
end

function getReflex(target)
  local force = target.properties.RefForce.value
  local ability = 0
  if force == 0 then ability = math.max(target.properties.DexBonus.value, target.properties.IntBonus.value)
  elseif force >= 2 then ability = target.properties[VARS.ABILITY_BONUSES[force]].value end
  local bonus = fromStr(target.properties.RefBonuses.value)
  return 10 + target.properties.LevelBonus.value + target.properties.ShieldBonus.value + ability + (bonus.Class or 0) + (bonus.Feat or 0) + (bonus.Enhance or 0) + (bonus.Item or 0) + (bonus.Misc or 0) + (bonus.Temporary or 0) + (bonus.tillShortRest or 0) + (bonus.tillExtRest or 0)
end


function executeAttack(attack, equip)
  equip = equip or getWeapon(attack)
  local keywords = attack.Keywords:lower()
  for i = 1, attack.Repeat do
    attack.iteration = i
    print("<tr bgcolor='#D6D7C6'>")
    if attack.UseTargetsChoice == VARS.TARGET_CHOICE_TEXTBOX then
      print("&nbsp;<td><i><b>Target:</b> ", attack["Repeat"..i], "&nbsp;</i></td><td bgcolor='white'>&#8212</td>")
      attack.TargetName = attack["Repeat"..i]
    else 
      print("<td>&nbsp;<b><i>", attack.PrependText, "</i></b></td>")
    end
    if attack.UseTargetsChoice == VARS.TARGET_CHOICE_SELECTION then
      attack.TargetName = attack["Repeat"..i].Name
      attack.target = attack["Repeat"..i].Object
      print("<td><img height=",IMAGE_SIZE," width=",IMAGE_SIZE, " src='",attack["Repeat"..i].Img,"'></img></td><td><i> (",attack["Repeat"..i].Distance,") ",attack.TargetName,"&nbsp;</i></td><td bgcolor='white'>&#8212</td>")
    else
      print("<td>&nbsp;</td>")
    end
    attack.CA = attack["Repeat"..i.."CA"] or false
    attack.Keywords = fromStr(keywords, ",")
    if not (attack.Chk_IgnoreCond == 1) then
      for i = 1, 100 do
        local c = "Conditional"..i
        if equip[c] ~= nil and equip[c].Affects == 5 then 
          local r = evalConditional(equip[c], attack, attack.target)
          if r ~= nil then 
            attack.Keywords = table.merge(attack.Keywords, fromStr(tostring(r.Value):lower(), ","))
            attack.Keywords = table.difference(attack.Keywords, fromStr(tostring(r.Max):lower(), ","))
          end
        end
        if CONDITIONALS[c] ~= nil and CONDITIONALS[c].Affects == 5 then 
          local r = evalConditional(CONDITIONALS[c], attack, attack.target)
          if r ~= nil then 
            attack.Keywords = table.merge(attack.Keywords, fromStr(tostring(r.Value):lower(), ","))
            attack.Keywords = table.difference(attack.Keywords, fromStr(tostring(r.Max):lower(), ","))
          end
        end
      end
    end
    local attackRoll = executeAttackRoll(attack, equip)
    local isCrit = attackRoll >= attack.CritThreshold
    if not (attack.Chk_IgnoreDamage == 1) then
      print("<td bgcolor='white'>&nbsp;&#8212;&nbsp;</td><td>&nbsp;")
      if not(isCrit) or (not(attack.Chk_MultiDmgRolls == 1) and i == 1) then executeDamage(attack, equip) end
      if isCrit then executeCrit(attack, equip) end
      print("&nbsp;</td></tr>")
    end
    if equip.RollCode ~= nil and equip.RollCode ~= 0 and equip.RollCode ~= "" then
      local x, r = macro.evalUntrustedRaw(equip.RollCode)
      print("<tr bgcolor='#D6D7C6'><td colspan=6><i><b>", equip.Name, ": </b>", r, "</i></td></tr>")
    end
  end
  if equip.AttackCode ~= nil and equip.AttackCode ~= 0 and equip.AttackCode ~= "" then
    local x2, r2 = macro.evalUntrustedRaw(equip.AttackCode)
    print("<tr bgcolor='#D6D7C6'><td colspan=6><i><b>", equip.Name, ": </b>", r2, "</i></td></tr>")
  end
end

function handleManualChanges(power)
  if power.PowerName == nil or power.PowerName == "" then return nil end
  local lib = token.properties.PowerLibrary.converted
  lib[power.PowerName] = power
  token.properties.PowerLibrary = lib
  for index, macro in pairs(token.macros) do
    if macro.label == power.PowerName then
       if power.group ~= macro.group then power.group = macro.group end
       if macro.sortBy ~= VARS.MACRO_BUTTON_SORT_PREFIXES[power.SortPrefix + 1] then macro.sortBy = VARS.MACRO_BUTTON_SORT_PREFIXES[power.SortPrefix + 1] end
       if macro.minWidth ~= VARS.MACRO_BUTTON_MIN_WIDTHS[power.MinWidth + 1] then macro.minWidth = VARS.MACRO_BUTTON_MIN_WIDTHS[power.MinWidth + 1] end
       if macro.fontSize ~= VARS.MACRO_BUTTON_FONT_SIZES[(power.FontSize or 0) + 1] then macro.fontSize = VARS.MACRO_BUTTON_FONT_SIZES[(power.FontSize or 0) + 1] end
       return macro, lib
    end
  end
end

function checkAvailablePP(power)
  if token.pc and power.Chk_Augment == 1 then
    if (token.properties.CurrentPP.value or 0) < (power.Augment or 0) then
      local r = input("blah | Not enough power points. Press OK to continue anyway. | Error | LABEL")
      macro.abort(r)
    end
  end
end

function getLowerCritThreshold(attack, equip)
  local t = attack.CritThreshold ~= "" and attack.CritThreshold ~= 0 and attack.CritThreshold or 20
  local t2 = equip.CritThreshold ~= "" and equip.CritThreshold ~= 0 and equip.CritThreshold or 20
  attack.CritThreshold = math.min(t, t2)
end

function addExecuteAttack(t, attack, atk, dmg, prefix, prefix2)
  prefix = prefix or ""
  prefix2 = prefix2 and prefix2.." " or ""
  local count = {}
  for i=0, 25 do count[i+1]=i end
  table.insert(t, {content="--------------------------------------------", type="LABEL", span="TRUE"})
  table.insert(t, {name=prefix.."equip", content=VARS.WEAPON_SLOTS, prompt=prefix2.."Weapon", type="LIST", select=attack.Equip})
  table.insert(t, {name=prefix.."roll", content=VARS.ATTACK_ROLLS, prompt=prefix2.."Roll", type="LIST", select=attack.AttackRoll or 0})
  table.insert(t, {name=prefix.."atkMod", content=atk or 0, prompt=prefix2.."Attack mod", type="TEXT", width=4})
  table.insert(t, {name=prefix.."dmgMod", content=dmg or 0, prompt=prefix2.."Damage mod", type="TEXT", width=4})
  table.insert(t, {name=prefix.."repeat", content=count, prompt=prefix2.."Repeat X times", type="LIST", select=attack.Repetitions or 0})
  table.insert(t, {name=prefix.."critThreshold", content=attack.CritThreshold, prompt=prefix2.."Critical threshold", type="TEXT", width=4})
end

function loadVar(attack, r, prefix)
   prefix = prefix or ""
   attack.Equip = tonumber(r[prefix.."equip"] or 0)
   attack.Roll = r[prefix.."roll"]
   attack.atkMod = tonumber(r[prefix.."atkMod"] or 0)
   attack.dmgMod = tonumber(r[prefix.."dmgMod"] or 0)
   attack.Repeat = tonumber(r[prefix.."repeat"] or 0)
   attack.CritThreshold = tonumber(r[prefix.."critThreshold"] or 20)
end

function append(t, value)
  if type(t) ~= "table" then t = {} end
  table.insert(t, value)
  return t
end

function handleExpendability(power, mac)
  local ptype = VARS.POWER_TYPES[power.PowerNum + 1] or ""
  local daily = string.contains(ptype,"daily")
  local encounter = string.contains(ptype,"encounter")
  local recharge = string.contains(ptype,"recharge")
  local magic = string.contains(ptype,"magic")
  if encounter or daily or recharge then
    if magic then mac.color = "default" else mac.color = "white" end
    if encounter then 
      mac.fontColor = "red"
      token.properties.ExpendedEncounterPowers = append(token.properties.ExpendedEncounterPowers.converted, power.PowerName)
    end
    if daily then 
      mac.fontColor = "black" 
      token.properties.ExpendedDailyPowers = append(token.properties.ExpendedDailyPowers.converted, power.PowerName)
    end
    if recharge then 
      mac.fontColor = "fuchsia"
      token.properties.ExpendedRechargePowers = append(token.properties.ExpendedRechargePowers.converted, power.PowerName)
    end
  end
end

function executePowerMacro(power)
  local safePowerName = power.PowerName:replace("'","`")
  local mac, lib = handleManualChanges(power)
  checkAvailablePP(power)
  local primaryAttack = power.PrimaryAttack
  local secondaryAttack = power.SecondaryAttack
  local tertiaryAttack = power.TertiaryAttack
  primaryAttack.PrependText = ""
  secondaryAttack.PrependText = "(Sec) "
  tertiaryAttack.PrependText = "(Tert) "
  getLowerCritThreshold(primaryAttack, getWeapon(primaryAttack))
  getLowerCritThreshold(secondaryAttack, getWeapon(secondaryAttack))
  getLowerCritThreshold(tertiaryAttack, getWeapon(tertiaryAttack))
  power.AskForSupplement = not(power.Chk_Supplement == 1) and (primaryAttack.Chk_Attack == 1 or secondaryAttack.Chk_Attack == 1 or tertiaryAttack.Chk_Attack == 1)
  power.PowerHasTargets = power.Chk_CustomCodeHasTarget ==1 or primaryAttack.Chk_Target == 1 or secondaryAttack.Chk_Target == 1 or tertiaryAttack.Chk_Target == 1
  if not(power.Chk_Supplement == 1) or power.PowerHasTargets or primaryAttack.Chk_Attack == 1 or secondaryAttack.Chk_Attack == 1 or tertiaryAttack.Chk_Attack == 1 then
    local private = fromStr(token.properties.Private.value, nil, ";")
    if (type(private)~="table") then private = {} end
    local inputs = {{prompt=safePowerName, type="LABEL", text=false}}
    if primaryAttack.Chk_Attack == 1 then addExecuteAttack(inputs, primaryAttack, private.PrimaryAttack, private.PrimaryDamage) end
    if secondaryAttack.Chk_Attack == 1 then addExecuteAttack(inputs, secondaryAttack, private.SecondaryAttack, private.SecondaryDamage, "sec", "(2nd)") end
    if tertiaryAttack.Chk_Attack == 1 then addExecuteAttack(inputs, tertiaryAttack, private.TertiaryAttack, private.TertiaryDamage, "tert", "(3rd)") end
    local supplementList = {}
    if power.AskForSupplement then
      table.insert(inputs, {content="--------------------------------------------", type="LABEL", span="TRUE"})
      supplementList = fromJSON(token.properties.PowerSupplements.value:replace("`","'"))
      table.insert(supplementList, 1, "None")
      table.insert(inputs, {name="supplementNum", content=supplementList, prompt="Supplement?", type="LIST", select=private.LastSupplementNum or 0})
    end
    if power.PowerHasTargets then
      table.insert(inputs, {content="--------------------------------------------", type="LABEL", span="TRUE"})
      table.insert(inputs, {name="useTargetsChoice", content={"None", "Textbox", "Selection"}, prompt="Targeting?", type="LIST", select=private.LastUseTargetsChoice or 0})
      table.insert(inputs, {name="chk_IncludeAllies", content=private.LastChk_IncludeAllies or 0, prompt="Include allies?", type="CHECK"})
    end
    table.insert(inputs, {content="--------------------------------------------", type="LABEL", span="TRUE"})
    local r = input(inputs)
    macro.abort(r)
    if power.AskForSupplement then 
      private.LastSupplementNum = r.supplementNum
      power.supplement = supplementList[r.supplementNum+1]
    end
    if power.PowerHasTargets then
      power.UseTargetsChoice = r.useTargetsChoice
      power.IncludeAllies = r.chk_IncludeAllies or false
      private.LastUseTargetsChoice = r.useTargetsChoice
      private.LastChk_IncludeAllies = r.chk_IncludeAllies
    end
    if primaryAttack.Chk_Attack == 1 then
      primaryAttack.UseTargetsChoice = r.useTargetsChoice or 0
      private.PrimaryAttack = tonumber(r.atkMod or 0)
      private.PrimaryDamage = tonumber(r.dmgMod or 0)
      loadVar(primaryAttack, r)
    end
    if secondaryAttack.Chk_Attack == 1 then
      secondaryAttack.UseTargetsChoice = r.useTargetsChoice or 0
      private.SecondaryAttack = tonumber(r.secatkMod or 0)
      private.SecondaryDamage = tonumber(r.secdmgMod or 0)
      loadVar(secondaryAttack, r, "sec")
    end
    if tertiaryAttack.Chk_Attack == 1 then
      tertiaryAttack.UseTargetsChoice = r.useTargetsChoice or 0
      private.TertiaryAttack = tonumber(r.tertatkMod or 0)
      private.TertiaryDamage = tonumber(r.tertdmgMod or 0)
      loadVar(tertiaryAttack, r, "tert")
    end
    token.properties.Private.value = toStr(private)
    if power.UseTargetsChoice == VARS.TARGET_CHOICE_TEXTBOX then
      local inputlist = {{content="Enter target name(s):", prompt="Note", type="LABEL"}}
      local LastTargets = token.properties.LastTargets.converted
      if primaryAttack.Chk_Attack == 1 then for i = 1, primaryAttack.Repeat do
          table.insert(inputlist, {name="repeat"..i, prompt = "Primary #"..i, content=LastTargets["TextboxRepeat"..i] or ""})
          table.insert(inputlist, {name="repeat"..i.."ca", prompt = "Combat Advantage #"..i, content=0, type="CHECK"})
      end end
      if secondaryAttack.Chk_Attack == 1 then for i = 1, secondaryAttack.Repeat do
          table.insert(inputlist, {name="secRepeat"..i, prompt = "Secondary #"..i, content=LastTargets["TextboxSecRepeat"..i] or ""})
          table.insert(inputlist, {name="secRepeat"..i.."ca", prompt = "Combat Advantage #"..i, content=0, type="CHECK"})
      end end
      if tertiaryAttack.Chk_Attack == 1 then for i = 1, tertiaryAttack.Repeat do
          table.insert(inputlist, {name="tertRepeat"..i, prompt = "Tertiary #"..i, content=LastTargets["TextboxTertRepeat"..i] or ""})
          table.insert(inputlist, {name="tertRepeat"..i.."ca", prompt = "Combat Advantage #"..i, content=0, type="CHECK"})
      end end
      if power.Chk_CustomCodeHasTarget == 1 then
        table.insert(inputlist, {name="customTarget", prompt = "Custom target", content=LastTargets["CustomTarget"] or ""})
      end
      table.insert(inputlist, {type="LABEL", prompt="--------------------", content="--------------------"})
      local rr = input(inputlist)
      macro.abort(rr)
      if primaryAttack.Chk_Attack == 1 then for i = 1, primaryAttack.Repeat do
          primaryAttack["Repeat"..i] = rr["repeat"..i] or "Other"
          LastTargets["TextboxRepeat"..i] = tonumber(rr["repeat"..i] or 0)
          primaryAttack["Repeat"..i.."CA"] = rr["repeat"..i.."ca"] or false
      end end
      if secondaryAttack.Chk_Attack == 1 then for i = 1, secondaryAttack.Repeat do
          secondaryAttack["Repeat"..i] = rr["secRepeat"..i] or "Other"
          LastTargets["TextboxSecRepeat"..i] = tonumber(rr["secRepeat"..i] or 0)
          secondaryAttack["Repeat"..i.."CA"] = rr["secRepeat"..i.."ca"] or false
      end end
      if tertiaryAttack.Chk_Attack == 1 then for i = 1, tertiaryAttack.Repeat do
          tertiaryAttack["Repeat"..i] = rr["tertRepeat"..i] or "Other"
          LastTargets["TextboxTertRepeat"..i] = tonumber(rr["tertRepeat"..i] or 0)
          tertiaryAttack["Repeat"..i.."CA"] = rr["tertRepeat"..i.."ca"] or false
      end end
      if power.Chk_CustomCodeHasTarget == 1 then
        power.CustomTarget = rr.customTarget or ""
        LastTargets.CustomTarget = rr.customTarget or ""
      end
      token.properties.LastTargets = LastTargets
    elseif power.UseTargetsChoice == VARS.TARGET_CHOICE_SELECTION then
      local condition = {visible=true, unsetStates={"Dead"}}
      if not power.IncludeAllies then
        condition.pc = not token.pc
        condition.npc = not token.npc
        condition.current = false
      end
      local LastTargets = token.properties.LastTargets.converted
      local lookup = {}
      local targetlist = {}
      local list = {"Other"}
      for index, tok in ipairs(tokens.find(condition)) do
        table.insert(targetlist, {Name=tok.name, Object=tok, ID=tok.id, Img=tok.image, Distance=token.getDistance(tok) or 0})
      end
      table.sort(targetlist, function(a,b) return a.Distance<b.Distance end)
      for index, v in ipairs(targetlist) do 
        lookup[v.ID] = index;
        table.insert(list, "("..v.Distance..") "..v.Name..v.Img)
      end
      table.insert(targetlist, 1, tokens.getLibProperty("TARGET_EMPTY", "Lib:Veg").converted)
      local inputlist = {{content="Choose your target(s):", prompt="Note", type="LABEL"}}
      local LastTargets = token.properties.LastTargets.converted
      if primaryAttack.Chk_Attack == 1 then for i = 1, primaryAttack.Repeat do
          table.insert(inputlist, {name="repeat"..i, prompt = "Primary #"..i, content=list, type="LIST", select=lookup[LastTargets["SelectionRepeat"..i]] or 0, icon="TRUE", iconsize=ICONSIZE})
          table.insert(inputlist, {name="repeat"..i.."ca", prompt = "Combat Advantage #"..i, content=0, type="CHECK"})
      end end
      if secondaryAttack.Chk_Attack == 1 then for i = 1, secondaryAttack.Repeat do
          table.insert(inputlist, {name="secRepeat"..i, prompt = "Secondary #"..i, content=list, type="LIST", select=lookup[LastTargets["SelectionSecRepeat"..i]] or 0, icon="TRUE", iconsize=ICONSIZE})
          table.insert(inputlist, {name="secRepeat"..i.."ca", prompt = "Combat Advantage #"..i, content=0, type="CHECK"})
      end end
      if tertiaryAttack.Chk_Attack == 1 then for i = 1, tertiaryAttack.Repeat do
          table.insert(inputlist, {name="tertRepeat"..i, prompt = "Secondary #"..i, content=list, type="LIST", select=lookup[LastTargets["SelectionTertRepeat"..i]] or 0, icon="TRUE", iconsize=ICONSIZE})
          table.insert(inputlist, {name="tertRepeat"..i.."ca", prompt = "Combat Advantage #"..i, content=0, type="CHECK"})
      end end
      if power.Chk_CustomCodeHasTarget == 1 then
        table.insert(inputlist, {name="customTarget", prompt = "Custom target", content=list, type="LIST", select=lookup[LastTargets["SelectionCustomTarget"]] or 0, icon="TRUE", iconsize=ICONSIZE})
      end
      table.insert(inputlist, {type="LABEL", prompt="--------------------", content="--------------------"})
      local rr = input(inputlist)
      macro.abort(rr)
      if primaryAttack.Chk_Attack == 1 then for i = 1, primaryAttack.Repeat do
          primaryAttack["Repeat"..i] = targetlist[(rr["repeat"..i] or 0) + 1]
          LastTargets["SelectionRepeat"..i] = targetlist[(rr["repeat"..i] or 0) + 1].ID or ""
          primaryAttack["Repeat"..i.."CA"] = rr["repeat"..i.."ca"] or false
      end end
      if secondaryAttack.Chk_Attack == 1 then for i = 1, secondaryAttack.Repeat do
          secondaryAttack["Repeat"..i] = targetlist[(rr["secRepeat"..i] or 0) + 1]
          LastTargets["SelectionSecRepeat"..i] = targetlist[(rr["secRepeat"..i] or 0) + 1].ID or ""
          secondaryAttack["Repeat"..i.."CA"] = rr["secRepeat"..i.."ca"] or false
      end end
      if tertiaryAttack.Chk_Attack == 1 then for i = 1, tertiaryAttack.Repeat do
          tertiaryAttack["Repeat"..i] = targetlist[(rr["tertRepeat"..i] or 0) + 1]
          LastTargets["SelectionTertRepeat"..i] = targetlist[(rr["tertRepeat"..i] or 0) + 1]
          tertiaryAttack["Repeat"..i.."CA"] = rr["tertRepeat"..i.."ca"] or false
      end end
      if power.Chk_CustomCodeHasTarget == 1 then
        power.CustomTarget = targetlist[(rr.customTarget or 0) + 1]
        LastTargets.SelectionCustomTarget = targetlist[(rr.customTarget or 0) + 1].ID
      end
      token.properties.LastTargets = LastTargets
    end

  end
  local expended = mac.color == "white" or mac.color == "default"
  
  if token.pc or not (NPC_POWERNAMES_ARE_SECRET == 1) then
    print("<table border=0 cellspacing=0><tr bgcolor=\"",(expended and "white" or VARS.POWER_COLORS[power.PowerNum + 1]),"\"><td>")
    print("<font color=\"", (expended and VARS.POWER_COLORS[power.PowerNum + 1] or "white"), "\">&nbsp; <font size=+1><b>")
    if token.pc or not (NPC_POWERS_ARE_SECRET == 1) then print(macro.link(power.PowerName, "powerFrame@Lib:Veg", "none", power.PowerName, token.id)) else print(power.PowerName) end
    print("</b></font>")
    if power.Chk_ShortDescription == 1 then print(": ", power.ShortDescription) end
    print("&nbsp; </font></td></tr></table>")
  elseif power.Chk_ShortDescription == 1 then print("<br>", power.ShortDescription) end
  if power.Chk_DisplayFlavorText == 1 and power.Chk_FlavorText == 1 then print("<table border=0 cellspacing=0><tr bgcolor='#D6D7C6'><td><i>&nbsp;", power.FlavorText, "</i></td></tr></table>") end
  handleExpendability(power, mac)
  if token.pc and power.Chk_Augment == 1 then
    local currentPP = tonumber(token.properties.CurrentPP.value or 0) - tonumber(power.Augment or 0)
    local maxPP = tonumber(token.properties.MaxPP.value or 0)
    print(TABLE_START, "<b>Augment (", power.Augment, "):</b> Remaining Power Points: ", currentPP, " / ", token.properties.MaxPP.value, ". ", TABLE_END)
    token.properties.CurrentPP = currentPP
    if token.pc and maxPP > 0 and tokens.getLibProperty("SHOW_PC_POWERBAR", "Lib:Veg") == 1 then token.bars[tokens.getLibProperty("POWER_BAR", "Lib:Veg").value] = currentPP/maxPP
    else token.bars[tokens.getLibProperty("POWER_BAR", "Lib:Veg").value] = nil end
  end
  if power.Chk_DisplayTrigger == 1 and power.Chk_Trigger == 1 then print(TABLE_START, "<b>Trigger:</b> ", power.Trigger, TABLE_END) end
  if power.Chk_DisplayEffect == 1 and power.Chk_PreEffect == 1 then print(TABLE_START, "<b>Effect:</b> ", power.PreEffect, TABLE_END) end
  if primaryAttack.Chk_Attack == 1 then
    primaryAttack.Keywords = power.Keywords
    primaryAttack.Type = power.AttackType
    print("<table border=0 cellspacing=0>")
    executeAttack(primaryAttack)
    print("</table>")
  end
  if power.Chk_DisplayHits == 1 then
    local append = primaryAttack.HitAppend
    if append ~= "." and append ~= "0" and append ~= "" and append then
      if append:startsWith(",") or append:startsWith(".") then append = append:sub(2, -1):trim():upper(1) end
      print(TABLE_START, "<b>Hit:</b> ", append, TABLE_END)
    end
  end
  if power.Chk_DisplayMisses == 1 and primaryAttack.Chk_Miss == 1 then print(TABLE_START, "<b>Miss:</b> ", primaryAttack.Miss, TABLE_END) end
  if power.Chk_DisplayEffect == 1 and primaryAttack.Chk_PriEffect == 1 then print(TABLE_START, "<b>Effect:</b> ", primaryAttack.PriEffect, TABLE_END) end
  
  if secondaryAttack.Chk_Attack == 1 then
    secondaryAttack.Keywords = power.Keywords
    secondaryAttack.Type = power.AttackType
    print("<table border=0 cellspacing=0>")
    executeAttack(secondaryAttack)
    print("</table>")
  end
  if power.Chk_DisplayHits == 1 then
    local append = secondaryAttack.HitAppend
    if append ~= "." and append ~= "0" and append ~= "" and append then
      if append:startsWith(",") or append:startsWith(".") then append = append:sub(2, -1):trim():upper(1) end
      print(TABLE_START, "<b>Sec. Hit:</b> ", append, TABLE_END)
    end
  end
  if power.Chk_DisplayMisses == 1 and secondaryAttack.Chk_Miss == 1 then print(TABLE_START, "<b>Sec. Miss:</b> ", secondaryAttack.Miss, TABLE_END) end
  if power.Chk_DisplayEffect == 1 and power.Chk_SecEffect == 1 then print(TABLE_START, "<b>Sec. Effect:</b> ", power.SecEffect, TABLE_END) end

  if tertiaryAttack.Chk_Attack == 1 then
    tertiaryAttack.Keywords = power.Keywords
    tertiaryAttack.Type = power.AttackType
    print("<table border=0 cellspacing=0>")
    executeAttack(tertiaryAttack)
    print("</table>")
  end
  if power.Chk_DisplayHits == 1 then
    local append = tertiaryAttack.HitAppend
    if append ~= "." and append ~= "0" and append ~= "" and append then
      if append:startsWith(",") or append:startsWith(".") then append = append:sub(2, -1):trim():upper(1) end
      print(TABLE_START, "<b>Tert. Hit:</b> ", append, TABLE_END)
    end
  end
  if power.Chk_DisplayMisses == 1 and tertiaryAttack.Chk_Miss == 1 then print(TABLE_START, "<b>Tert. Miss:</b> ", tertiaryAttack.Miss, TABLE_END) end
  if power.Chk_DisplayEffect == 1 and power.Chk_TertEffect == 1 then print(TABLE_START, "<b>Tert. Effect:</b> ", power.TertEffect, TABLE_END) end

  if power.Chk_DisplayEffect == 1 and power.Chk_Effect == 1 then print(TABLE_START, "<b>Effect:</b> ", power.Effect, TABLE_END) end
  if power.Chk_DisplaySustain == 1 and power.Chk_Sustain == 1 then print(TABLE_START, "<b>Sustain (", VARS.SUSTAIN_ACTION_TYPES[(power.SustainActionType or 0) + 1],"):</b> ", power.SustainDesc, TABLE_END) end
  if power.Chk_DisplaySpecial == 1 and power.Chk_Special == 1 then print(TABLE_START, "<b>Special:</b> ", power.Special, TABLE_END) end
  if power.Chk_DisplayCustomRows == 1 and power.Chk_Custom == 1 then print(TABLE_START, "<b>", power.CustomLabel, ":</b> ", power.Custom, TABLE_END) end
  if power.Chk_DisplayCustomRows == 1 and power.Chk_Custom2 == 1 then print(TABLE_START, "<b>", power.CustomLabel2, ":</b> ", power.Custom2, TABLE_END) end
  if power.Chk_DisplayCustomRows == 1 and power.Chk_Custom3 == 1 then print(TABLE_START, "<b>", power.CustomLabel3, ":</b> ", power.Custom3, TABLE_END) end

  if power.Chk_CustomCode == 1 and not (DISABLE == 1) then
    print("<table border=0 cellspacing=0><tr bgcolor='#D6D7C6'>")
    if power.useTargetsChoice == VARS.TARGET_CHOICE_TEXTBOX and power.Chk_CustomCodeHasTarget == 1 then
      print("<td><i><b>Target:</b> ", power.CustomTarget, "&nbsp;</i></td><td bgcolor='white'>&#8212</td>")
    elseif power.useTargetsChoice == VARS.TARGET_CHOICE_SELECTION and power.Chk_CustomCodeHasTarget == 1 then
      print("<td><img height=", IMAGE_SIZE, " width=", IMAGE_SIZE, " src='", power.CustomTarget.Img, "'></img></td><td><i> (", power.CustomTarget.Distance, ") ", power.CustomTarget.Name)
      export("CUSTOM_TARGET", power.CustomTarget.ID)
      print("&nbsp;</i></td><td bgcolor='white'>&#8212</td>")
    end
    local er, ev = macro.evalUntrusted(power.CustomCode:replace("\\[", "<b>\\["):replace("\\]", "\\]</b>"))
    print("<td><i>", ev, "</i></td>")
    print("</tr></table>")
  end

  if power.AssState1 ~= ""  or power.AssState2 ~= "" or power.AssState3 ~= "" or power.AssState4 ~= "" or power.AssState5 ~= "" then
    print("<table cellspacing=0><tr bgcolor='#D6D7C6'><td><i>Click to toggle</i></td>")
    for i = 1,5 do
		if power["AssState"..i] ~= "" then
			local state = translateState(power["AssState"..i])
			local ss = campaign.allStates[state] or {}
			print("<td><img height=15 width=15 src='", ss.image or "" ,"'></img></td><td><b>",macro.link(state, "toggleState@Lib:Veg", "none", state, "selected"),"</b></td>")
		end
    end
    print("<td><i>on Selected Target(s)</i></td></tr></table>")
  end
  
  if power.supplement ~= nil and lib[power.supplement] ~= nil then 
    local s, err = pcall(executePowerMacro, lib[power.supplement])
    if not s then println("Error in supplement ", power.supplement, ": ", err) end
  end
end

executePowerMacro(macro.args)
