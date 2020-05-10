# mod_muc_rpgdices - Roll RPG Dices
### Prosody module to Roll RPG Dices

This is a module for Prosody that adds `/roll` command to every MUC.

The syntax is:
```
/roll
/roll ROLL[+ROLL...]
```

A ROLL is `XdY+Z`, with
 - `X` = number of dices (1 to 10), optional
 - `d` = type of roll (d, k or K), optional
   - d = classic roll, sum of all dices
   - k = keep lower dice only
   - K = keep higher dice only
 - `Y` = sides of dice (2 to 1000)
 - `Z` = modifier (-1000 to +1000), optional

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