-- Roll RPG dices in chatroom
-- By J2Nlab <dev@j2nlab.com>

local tostring = tostring;

--local st_clone = require "util.stanza".clone
local st_msg = require "util.stanza".message;
local jid_split = require "util.jid".split;
local jid_join = require "util.jid".join;
local now = require "util.datetime".datetime;

local hosts = prosody.hosts;

local function get_room_from_jid(jid)
  local node, host = jid_split(jid);
  local component = hosts[host];
  if component then
    local muc = component.modules.muc
    if muc and rawget(muc,"rooms") then
      -- We're running 0.9.x or 0.10 (old MUC API)
      return muc.rooms[jid];
    elseif muc and rawget(muc,"get_room_from_jid") then
      -- We're running >0.10 (new MUC API)
      return muc.get_room_from_jid(jid);
    else
      return
    end
  end
end

function dice(sides, rolltype)
  if rolltype == 's' then
    local result = 0
    local roll = 0
    repeat
      roll = math.random(sides)
      result = result + roll
    until roll ~= sides
    return result
  else
    return math.random(sides)
  end
end

function roll(dices)
  local result = {}
  result.dice = {}
  result.final = 0

  module:log("debug", "roll(): %s %s %s + %s", dices.times, dices.rolltype, dices.sides, dices.bonus);

  for i = 1, dices.times do
    result.dice[i] = dice(dices.sides, dices.rolltype)
    module:log("debug", "roll(): %s", result.dice[i]);
  end

  -- classic roll: sum all dices
  if dices.rolltype == 'd' then
    for i = 1, dices.times do
      result.final = result.final + result.dice[i]
    end

  -- keep lower dice only
  elseif dices.rolltype == 'k' then
    result.final = result.dice[1]
    for i = 1, dices.times do
      if result.dice[i] < result.final then
        result.final = result.dice[i]
      end
    end
  
  -- keep upper dice only
  elseif dices.rolltype == 'K' then
    result.final = result.dice[1]
    for i = 1, dices.times do
      if result.dice[i] > result.final then
        result.final = result.dice[i]
      end
    end

  -- shadowrun roll
  elseif dices.rolltype == 's' then
    for i = 1, dices.times do
      if result.dice[i] + dices.bonus >= dices.threshold then
        module:log("debug", "roll(): (%s+%s)/%s=%s", result.dice[i], dices.bonus, dices.threshold, math.floor((result.dice[i] + dices.bonus) / dices.threshold))
        result.final = result.final + math.floor((result.dice[i] + dices.bonus) / dices.threshold)
      end
    end
  end

  if dices.rolltype ~= 's' then
    result.final = result.final + dices.bonus
  end

  module:log("debug", "roll(): %s", result.final);

  return result;
end

function format_result(result)
  local final = '[ '
  for i = 1, #result.dice do
    final = final..result.dice[i]..' '
  end
  final = final..']=> '..result.final;

  module:log("debug", "format_result(): %s", final);

  return final;
end

function format_dices(dices)
  local final = '';
  if dices.times > 1 then
    final = final..dices.times
  end

  if dices.rolltype ~= 's' then
    final = final..dices.rolltype..dices.sides
  else
    final = final..dices.rolltype..dices.threshold
  end

  if dices.bonus > 0 then
    final = final..'+'..dices.bonus
  elseif dices.bonus < 0 then
    final = final..dices.bonus
  end

  module:log("debug", "format_message(): %s", final);

  return final;
end

-- Classic rolls
--
function parse_roll_submessage(submessage)
  local dices = {}
  dices.times = 1
  dices.sides = 6
  dices.threshold = 0
  dices.bonus = 0
  dices.rolltype = 'd'

  -- only number of sides
  if submessage:match('^%d+$') then
    dices.sides = tonumber(submessage)
  else

    -- have a type of dice
    local position = submessage:find("[dkK]")
    if not position then return; end

    if position > 1 then
      dices.times = tonumber(submessage:sub(1, position - 1))
    end
    dices.rolltype = submessage:sub(position, position)

    submessage = submessage:sub(position+1)

    -- only number of sides
    if submessage:match('^%d+$') then
      dices.sides = tonumber(submessage)
    else

      -- 
      local position = submessage:find("[+-]")
      dices.sides = tonumber(submessage:sub(1, position - 1))
      dices.bonus = tonumber(submessage:sub(position))
    end
  end

  if dices.times > 25 then dices.times = 25 end
  if dices.times < 1 then dices.times = 1 end

  if dices.sides > 1000 then dices.sides = 1000 end
  if dices.sides < 2 then dices.sides = 2 end

  if dices.bonus > 1000 then dices.bonus = 1000 end
  if dices.bonus < -1000 then dices.bonus = -1000 end

  module:log("debug", "parse_roll_submessage(): %s/%s%s%s+%s", submessage, dices.times, dices.rolltype, dices.sides, dices.bonus);

  return dices
end

function parse_roll_message(message)
  local submessage = message:gsub(' ', '')
  local nb_roll = select(2, submessage:gsub("[+-]", ""))
  local nb_dices = select(2, submessage:gsub("[dkK]", ""))
  local dices = {}

  module:log("debug", "parse_roll_message(): nb_roll=%s / nb_dices=%s", nb_roll, nb_dices)

  if nb_roll == 0 or nb_dices == 1 then
    dices = parse_roll_submessage(submessage)
    if not dices then return nil; end

    return format_dices(dices).."="..format_result(roll(dices))
  end

  if nb_dices > 1 then
    local result = ''
    local result_final = ''
    local score_final = 0;
    local position

    for i = 1, nb_dices - 1 do
      module:log("debug", "parse_roll_message(): submessage=%s", submessage)

      position = submessage:find("[+-]")
      dices = parse_roll_submessage(submessage:sub(1, position - 1))
      if not dices then return nil; end

      result = roll(dices)
      result_final = result_final..format_dices(dices).."="..format_result(result).."\n"
      score_final = score_final + result.final

      module:log("debug", "parse_roll_message(): score_final=%s", score_final)

      submessage = submessage:sub(position + 1)
    end

    dices = parse_roll_submessage(submessage)
    if not dices then return nil; end

    result = roll(dices)
    result_final = result_final..format_dices(dices).."="..format_result(result).."\n"
    score_final = score_final + result.final

    result_final = result_final.."=> "..score_final

    return result_final;
  end
end

-- Shadowrun rolls
--
function parse_sr_submessage(submessage)
  local dices = {}
  dices.times = 1
  dices.sides = 6
  dices.threshold = 4
  dices.bonus = 0
  dices.rolltype = 's'

  local sep = submessage:find("[sS]");
  if not sep then return; end
  local mod = submessage:find("[+-]");
  module:log("info", "parse_sr_submessage(): sep=%s / mod=%s", sep, mod);

  dices.times = tonumber(submessage:sub(1, sep-1))

  if mod then
    dices.threshold = tonumber(submessage:sub(sep+1, mod-1))
    dices.bonus = tonumber(submessage:sub(mod))
  else
    dices.threshold = tonumber(submessage:sub(sep+1))
  end

  if dices.times > 25 then dices.times = 25 end
  if dices.times < 1 then dices.times = 1 end

  if dices.threshold > 20 then dices.threshold = 20 end
  if dices.threshold < 1 then dices.threshold = 1 end

  if dices.bonus > 10 then dices.bonus = 10 end
  if dices.bonus < -10 then dices.bonus = -10 end

  module:log("debug", "parse_sr_submessage(): %s/%s%s%s+%s(SR%s)", submessage, dices.times, dices.rolltype, dices.sides, dices.bonus, dices.threshold);

  return dices
end

function parse_sr_message(message)
  local submessage = message:gsub(' ', '')
  module:log("debug", "parse_sr_message(): submessage=%s", submessage);

  local dices = parse_sr_submessage(submessage)
  if not dices then return nil; end

  local result = ''
  local result_final = ''
  local score_final = 0;
  local position

  result = roll(dices)
  result_final = result_final..format_dices(dices).."="..format_result(result).."\n"
  score_final = score_final + result.final

  module:log("info", "parse_sr_message(): result_final=%s", result_final)
  module:log("info", "parse_sr_message(): score_final=%s", score_final)

  return result_final;
end

--function print_r(tab, pad)
--  pad = pad or ''
--  for index,value in pairs(tab) do
--    if type(value) == "table" then
--      module:log("info", "%s%s =>", pad, index)
--      print_r(value, pad.."  ")
--    else
--      module:log("info", "%s%s = %s", pad, index, value)
--    end
--  end
--end

function send_result(this_room, from_room, from_room_jid, from_host, nick, result)
  local bare_room = jid_join(from_room, from_host);
  local sender = jid_join(from_room, module.host, "Roll - "..nick);
  local forward_stanza = st_msg({from = sender, to = bare_room, type = "groupchat"}, result);
  forward_stanza:tag("delay", { xmlns = 'urn:xmpp:delay', from = from_room_jid, stamp = now(os.time()+1) }):up();

  module:log("info", "send_result(): send result to '%s' room", bare_room);
  this_room:broadcast_message(forward_stanza);
end

function send_roll_help(this_room, from_room, from_room_jid, from_host)
  local result = 'Roll RPG Dices\n'..
  '/sr => the Shadowrun roll help\n'..
  '/roll => this help\n'..
  '/roll ROLL[+ROLL...]\n'..
  '\n'..
  'a ROLL is XdY+Z\n'..
  'X = number of dices (1 to 25)\n'..
  'd = type of roll (d, k or K)\n'..
  '  d = classic roll, sum of all dices\n'..
  '  k = keep lower dice only\n'..
  '  K = keep higher dice only\n'..
  'Y = sides of dice (2 to 1000)\n'..
  'Z = modifier (-1000 to +1000)\n'..
  '\n'..
  'examples:\n'..
  '/roll 20\n'..
  'd20=[ 8 ]=> 8\n'..
  '\n'..
  '/roll 2k20\n'..
  '2k20=[ 7 19 ]=> 7\n'..
  '\n'..
  '/roll 3d8+2d8+1d10+2\n'..
  '3d8=[ 2 8 8 ]=> 18\n'..
  '2d8=[ 7 3 ]=> 10\n'..
  'd10+2=[ 6 ]=> 8\n'..
  '=> 36\n';
  send_result(this_room, from_room, from_room_jid, from_host, "RPG Dices", result)
end

function send_sr_help(this_room, from_room, from_room_jid, from_host)
  local result = 'Roll Shadowrun Dices\n'..
  '/roll => the classic roll help\n'..
  '/sr => this help\n'..
  '/sr ROLL\n'..
  '\n'..
  'a ROLL is XsY+Z\n'..
  'X = number of 6 sides dices (1 to 25)\n'..
  's = type of roll (s)\n'..
  'Y = threshold\n'..
  'Z = modifier (-10 to +10)\n'..
  '\n'..
  'examples:\n'..
  '/sr 8s4\n'..
  '8s4=[ 4 10 4 2 4 1 1 3 ]=> 5\n'..
  '\n'..
  '/sr 3s5+1\n'..
  '3s5+1=[ 1 7 4 ]=> 2\n';
  send_result(this_room, from_room, from_room_jid, from_host, "Shadowrun Dices", result)
end

function check_message(event)
  local origin, stanza = event.origin, event.stanza;

  module:log("debug", "check_message(): %s", stanza.name);
  if not stanza.name == "message" then return; end -- not a message

  local this_room = get_room_from_jid(stanza.attr.to);
  if not this_room then return; end -- no such room

  local from_room_jid = this_room._jid_nick[stanza.attr.from];
  if not from_room_jid then return; end -- no such nick

  local from_room, from_host, from_nick = jid_split(from_room_jid);

  module:log("debug", "check_message(): %s, %s, %s", from_nick, from_room, from_host);
  module:log("debug", "check_message(): %s", stanza.attr.from);
  module:log("debug", "check_message(): %s", stanza.attr.to);

--  print_r(stanza.attr)
--  print_r(stanza.tags)

  local body = stanza:get_child("body");
  if not body then return; end
  body = body and body:get_text();
  module:log("info", "check_message(): %s", body);

  local nick = stanza:get_child("nick", "http://jabber.org/protocol/nick");
  if not nick then return; end
  nick = nick and nick:get_text();
  module:log("info", "check_message(): %s", nick);

  if body:match("^/roll$") then
    send_roll_help(this_room, from_room, from_room_jid, from_host)
  elseif body:match("^/sr$") then
    send_sr_help(this_room, from_room, from_room_jid, from_host)
  end

-- TODO: rework all regex matching
  local result = '';
  local message = body:match("^/roll (.*)");
  if message then
    message = message:gsub("^%s*(.-)%s*$", "%1");
    module:log("debug", "check_message(): %s", message);

    result = parse_roll_message(message);
  else
    message = body:match("^/sr (.*)");
    if not message then return; end

    message = message:gsub("^%s*(.-)%s*$", "%1");
    module:log("debug", "check_message(): %s", message);

    result = parse_sr_message(message);
  end

  if not result then return; end

  module:log("debug", "check_message(): %s", result);
  send_result(this_room, from_room, from_room_jid, from_host, nick, result)
end

module:hook("message/bare", check_message);
module:log("info", "Loading mod_muc_rpgdices for host "..module:get_host().."!");
