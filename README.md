# Crystal Player Mod
 A player sprite mod for gen1recomp++
<img width="1023" height="769" alt="image" src="https://github.com/user-attachments/assets/9f04bc87-5af2-4607-a83b-673b197f2460" />


## Features
* Bike Sprite
* Fishing Sprite
* Battle Sprites (Front and Back)
* Voxel Mod support -- Mostly working.
  * The fishing sprite breaks with voxel. It looks like this happens on the original sprite too.
* Changed name options in Oak's dialogue to match Crystal's original options
* All sprites have an SGB compatibility mode as well as a full color mode
* Bring your own Front and Back Sprites!

## How to add your own sprites!
* Sprites can be placed in their own folder at assets/sprites/FOLDER_NAME_HERE
  * Your folder must not have any spaces in the name. This is what the mod uses for the option key.
  * In you folder place the following.
    * back.png
    * backColor.png
    * front.png
    * frontColor.png
    * meta.json
      * As long as you have either back.png or backColor.png the other is option. The mod is designed to fallback if a sprite is missing.
* Your meta.json needs to have a single key defined. This is the name that will appear in the options menu.

### Example meta.json file
```
{
  "label": "ARALE"
}
```


## What works in Gold
*  Full color overworld sprite
*  Full color bike sprite (untested but should work)
*  Credits
*  Battle Sprite Choices
*  Full color sprites in the battle engine
*  Girl Mode re-gendering of the text

## What doesn't work in Gold
*  Overworld sprite doesn't support DMG palletes yet (You can use the DMG palette. the sprite will just be the only thing in full color)
*  Player name options still show Golds defaults (for now)


