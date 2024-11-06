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
The same applies to slaves, spearmen, and slingers. Their AIC fields are `RunningUnits_Spearmen` `RunningUnits_Slingers` `RunningUnits_Slaves`.

Note that for spearmen, there is a conflicting option in the UCP2-Legacy plugin which sets spearmen to running as well. Make sure that is off.

## Support
All support is welcome!

[!["Buy Me A Coffee"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/orange_img.webp)](https://www.buymeacoffee.com/gynt)

If you have PayPal:
[!["Support me on Ko-Fi"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/kofi_button_red.png)](https://ko-fi.com/kofigynt)
