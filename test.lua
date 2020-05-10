-- Roll RPG dices in chatroom
-- By J2Nlab <dev@j2nlab.com>

function roll(dices)
  local result = {}
  result.dice = {}
  result.final = 0

--  module:log("debug", "roll(): %s %s %s + %s", dices.times, dices.rolltype, dices.sides, dices.bonus);
  print("roll(): "..dices.times..' '..dices.rolltype..' '..dices.sides..' + '..dices.bonus);

  for i = 1, dices.times do
    result.dice[i] = math.random(dices.sides)
--    module:log("debug", "roll() rand=%s", result.dice[i]);
    print("roll() rand="..result.dice[i]);
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
  end

  result.final = result.final + dices.bonus
--  module:log("debug", "roll() final=%s", result.final);
  print("roll() final="..result.final)

  return result;
end

function format_result(result)
  local final = '[ '
  for i = 1, #result.dice do
    final = final..result.dice[i]..' '
  end
  final = final..']=> '..result.final;

--  module:log("debug", "format_result(): %s", final);
  print("format_result(): "..final)

  return final;
end

function format_dices(dices)
  local final = '';
  if dices.times > 1 then
    final = final..dices.times
  end
  final = final..dices.rolltype..dices.sides
  if dices.bonus > 0 then
    final = final..'+'..dices.bonus
  elseif dices.bonus < 0 then
    final = final..dices.bonus
  end

--  module:log("debug", "format_dices(): %s", final);
  print("format_dices(): "..final);

  return final;
end

function parse_submessage(submessage)
  local dices = {}
  dices.times = 1
  dices.sides = 6
  dices.bonus = 0
  dices.rolltype = 'd'

  -- only number of sides
  if submessage:match('^%d+$') then
    dices.sides = tonumber(submessage)
  else

    -- have a type of dice
    local position = submessage:find("[dkK]")

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

  if dices.times > 10 then dices.times = 10 end
  if dices.times < 1 then dices.times = 1 end

  if dices.sides > 1000 then dices.sides = 1000 end
  if dices.sides < 2 then dices.sides = 2 end

  if dices.bonus > 1000 then dices.bonus = 1000 end
  if dices.bonus < -1000 then dices.bonus = -1000 end

--  module:log("debug", "parse_submessage(): %s/%s%s%s+%s", submessage, dices.times, dices.rolltype, dices.sides, dices.bonus);
  print("parse_submessage(): "..submessage.."/"..dices.times..dices.rolltype..dices.sides..'+'..dices.bonus);

  return dices
end

function parse_message(message)
  local submessage = message:gsub(' ', '')
  local nb_roll = select(2, submessage:gsub("[+-]", ""))
  local nb_dices = select(2, submessage:gsub("[dkK]", ""))
  local dices = {}

--  module:log("debug", "parse_message(): message=%s", submessage);
  print("parse_message(): message="..submessage);
--  module:log("debug", "parse_message(): nb_roll=%s / nb_dices=%s", nb_roll, nb_dices);
  print("parse_message(): nb_roll="..nb_roll.." / nb_dices="..nb_dices);

  if nb_roll == 0 or nb_dices == 1 then
    dices = parse_submessage(submessage)
    return format_dices(dices).."="..format_result(roll(dices))
  end

  if nb_dices > 1 then
    local result = ''
    local result_final = ''
    local score_final = 0;
    local position

    for i = 1, nb_dices - 1 do
--      module:log("debug", "parse_message(): submessage=%s", submessage)
      print("parse_message(): submessage="..submessage)

      position = submessage:find("[+-]")
      dices = parse_submessage(submessage:sub(1, position - 1))
      result = roll(dices)
      result_final = result_final..format_dices(dices).."="..format_result(result).."\n"
      score_final = score_final + result.final

--      module:log("debug", "parse_message(): score_final=%s", score_final)
      print("parse_message(): score_final="..score_final)

      submessage = submessage:sub(position + 1)
    end

    dices = parse_submessage(submessage)
    result = roll(dices)
    result_final = result_final..format_dices(dices).."="..format_result(result).."\n"
    score_final = score_final + result.final

    result_final = result_final.."=> "..score_final

    return result_final;
  end
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

print(parse_message('18'))
print("--------------------")
print(parse_message('d4'))
print("--------------------")
print(parse_message('3d6'))
print("--------------------")
print(parse_message('3d8+10'))
print("--------------------")
print(parse_message('2K20'))
print("--------------------")
print(parse_message('3k10'))
print("--------------------")
print(parse_message('5d6+3d8+2d10+1'))
print("--------------------")
print(parse_message('10000d10000+10000'))
print("--------------------")
