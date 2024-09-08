# Running Units
This extension changes some units by making them run to their destination, instead of walking.

Currently only macemen are implemented.

## Macemen run!
If you enable running macemen, they will run to their destinations. You can also set whether AI creators are allowed to change this behavior.

### AI Personality (character/AIC)
To add extra flavour you can make your AI make use of this feature or not. 
If you add in your `character.json`:
```json
"RunningUnits_Macemen": 1
```
Then, macemen will run. If set to `0` or `2`, they will walk (vanilla behavior).

