# mod_muc_rpgdices - Roll RPG Dices
### Prosody module to Roll RPG Dices

This is a module for Prosody that adds `/roll` command to every MUC.

The syntax for classic rolls is:
```
/roll
/roll ROLL[+ROLL...]
```

A ROLL is `XdY+Z`, with
 - `X` = number of dices (1 to 25), optional
 - `d` = type of roll (d, k or K), optional
   - d = classic roll, sum of all dices
   - k = keep lower dice only
   - K = keep higher dice only
 - `Y` = sides of dice (2 to 1000)
 - `Z` = modifier (-1000 to +1000), optional

The syntax for Shadowrun rolls is:
```
/sr
/sr ROLL
```

A ROLL is `XsY+Z with
 - `X` = number of 6 sides dices (1 to 25)
 - `s` = type of roll (always s for "shadowrun")
 - `Y` = threshold
 - `Z` = modifier (-10 to +10), optional

The syntax for World of Darnkess v1 rolls is:
```
/wod
/wod ROLL
```

A ROLL is `XwY with
 - `X` = number of 10 sides dices (1 to 10)
 - `w` = type of roll (always w for "world of darkness")
 - `Y` = threshold

## Installation

Drop the module to Prosody dir (usually `/usr/lib/prosody/modules` or `/usr/local/lib/prosody/modules`) and turn it on in your config. Help to [Installing modules](https://prosody.im/doc/installing_modules).

Under your MUC component, add `muc_rpgdices` to `modules_enabled`.

``` config
    Component "conference.meet.example.com" "muc"
        modules_enabled = {
            "muc_rpgdices";
        }
```

## Examples

Simple form to roll 1d20:
```
/roll 20
d20=[ 8 ]=> 8
```

Roll 2d20 and keep only the lower, like 'disadvantage' in 5e:
```
/roll 2k20
2k20=[ 7 19 ]=> 7
```

Roll a lot of dices and sum all of them:
```
/roll 3d8+2d6+1d10+2
3d8=[ 2 8 8 ]=> 18
2d6=[ 1 3 ]=> 4
d10+2=[ 7 ]=> 9
=> 31
```

A simple Shadowrun roll:
```
/sr 8s4
8s4=[ 4 10 4 2 4 1 1 3 ]=> 5
```

A Shadowrun roll with bonus:
```
sr 3s5+1
3s5+1=[ 1 7 4 ]=> 2
```

A World of Darkness v1 roll:
```
/wod 8w7
8w7=[ 9 3 7 5 5 4 8 2 ]=> 3
```
