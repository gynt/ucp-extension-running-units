# Rennende Einheiten

Diese Erweiterung modifiziert das Verhalten bestimmter Einheiten, sodass diese zu ihrem Ziel rennen anstatt zu gehen.

Aktuell sind Streitkolbenkämpfer, Speerträger, Schleuderer und Sklaven implementiert.

---
## Streitkolbenkämpfer rennen!

Wenn aktiviert, rennen Streitkolbenkämpfer zu ihrem Zielort. Es kann ebenfalls festgelegt werden, ob KI-Gegner dieses Verhalten für ihre Einheiten nutzen dürfen.

### KI-Persönlichkeit (character/AIC)
Um der KI mehr Charakter zu verleihen, kannst du festlegen, ob sie dieses Feature nutzt.
Füge dazu in deiner `character.json` folgenden Eintrag hinzu:
```json
"RunningUnits_Macemen": 1
```
Mit dem Wert `1` werden die Streitkolbenkämpfer dieser KI rennen. Bei `0` oder `2` verhalten sie sich wie im Originalspiel (Vanilla).

---
## Sklaven, Speerträger und Schleuderer

Dasselbe Prinzip gilt für Sklaven, Speerträger und Schleuderer. Die entsprechenden Felder für die AIC lauten:
- `RunningUnits_Spearmen`
- `RunningUnits_Slingers`
- `RunningUnits_Slaves`

**Hinweis:** Für Speerträger gibt es eine konkurrierende Option im "UCP2-Legacy"-Plugin, die Speerträger ebenfalls rennen lässt. Stelle sicher, dass diese Option dort deaktiviert ist, um Konflikte zu vermeiden.

---
## Unterstützung

Unterstützung ist jederzeit willkommen!

[!["Buy Me A Coffee"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/orange_img.webp)](https://www.buymeacoffee.com/gynt)

Falls du PayPal bevorzugst:
[!["Support me on Ko-Fi"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/kofi_button_red.png)](https://ko-fi.com/kofigynt)
