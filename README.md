# Running Units for Stronghold Crusader
Modifies Stronghold Crusader by making, for example, macemen run in groups (currently they tend to walk).

This mod is integrated with UCP3, get it here: https://github.com/UnofficialCrusaderPatch/UnofficialCrusaderPatch

## Macemen run!
If you enable running macemen, they will run to their destinations. You can also set whether AI creators are allowed to change this behavior.

### AI Personality (character/AIC)
To add extra flavour you can make your AI make use of this feature or not. 
If you add in your `character.json`:
```json
"RunningUnits_Macemen": 1
```
Then, macemen will run. If set to `0` or `2`, they will walk like in vanilla behavior.

## Slaves, spearmen, and slingers
Slaves and slingers use `RunningUnits_Slaves` and `RunningUnits_Slingers` with the same values as macemen. For `RunningUnits_Spearmen`, use `0` for the game decision, `1` to run, or `2` to walk.

Note that for spearmen, there is a conflicting option in the UCP2-Legacy plugin which sets spearmen to running as well. Make sure that is off.

## Customizations menu

Version 1.0.3 requires GUI 1.0.16. Open **General → Balance Changes → Running
Units**. The section starts collapsed. Expand the Running Units card, then enable the unit types you want to run.
Each unit has a separate rule for AI lords. “Run by default” and “Use game
behaviour by default” let the AI personality override the rule. “Always run”
and “Always use game behaviour” use the same rule for every AI. The menu supports all nine GUI
languages. Running Units requires framework 3.0.8.

## Support
All support is welcome!

[!["Buy Me A Coffee"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/orange_img.webp)](https://www.buymeacoffee.com/gynt)

If you have PayPal:
[!["Support me on Ko-Fi"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/kofi_button_red.png)](https://ko-fi.com/kofigynt)
