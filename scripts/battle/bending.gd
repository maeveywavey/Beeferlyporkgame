extends RefCounted
## Bending abilities for every element. Each element has three slots:
## "q" (primary), "e" (secondary) and "r" (special).
##
## kind:
##   projectile — single projectile
##   volley     — several projectiles in a fan
##   cone       — instant cone in front of the bender
##   wall       — raises an earth/ice wall in front
##   heal       — heals self and nearby allies
##   quake      — radial stun around the bender
##   lightning  — instant line strike

const ABILITIES := {
	"fire": {
		"q": {"name": "Fire Blast", "kind": "projectile", "cost": 14.0, "cd": 0.75, "dmg": 19.0, "speed": 30.0, "radius": 0.45, "knock": 2.5, "gravity": 0.0, "range": 30.0, "effect": "burn", "fx": "fire", "sfx": "fire"},
		"e": {"name": "Fire Wave", "kind": "cone", "cost": 30.0, "cd": 3.0, "dmg": 24.0, "range": 6.0, "angle": 55.0, "knock": 5.0, "effect": "burn", "fx": "fire", "sfx": "fire"},
		"r": {"name": "Lightning", "kind": "lightning", "cost": 60.0, "cd": 9.0, "dmg": 70.0, "range": 45.0, "knock": 4.0, "min_skill": 5, "fx": "lightning", "sfx": "fire"},
	},
	"blue_fire": {
		"q": {"name": "Blue Fire Blast", "kind": "projectile", "cost": 12.0, "cd": 0.6, "dmg": 24.0, "speed": 36.0, "radius": 0.5, "knock": 3.0, "gravity": 0.0, "range": 32.0, "effect": "burn", "fx": "blue_fire", "sfx": "fire"},
		"e": {"name": "Blue Fire Arc", "kind": "cone", "cost": 28.0, "cd": 2.5, "dmg": 28.0, "range": 7.0, "angle": 70.0, "knock": 6.0, "effect": "burn", "fx": "blue_fire", "sfx": "fire"},
		"r": {"name": "Lightning", "kind": "lightning", "cost": 55.0, "cd": 7.0, "dmg": 80.0, "range": 45.0, "knock": 4.0, "fx": "lightning", "sfx": "fire"},
	},
	"earth": {
		"q": {"name": "Rock Throw", "kind": "projectile", "cost": 16.0, "cd": 1.0, "dmg": 26.0, "speed": 24.0, "radius": 0.6, "knock": 7.0, "gravity": 6.0, "range": 28.0, "effect": "", "fx": "rock", "sfx": "earth"},
		"e": {"name": "Earth Wall", "kind": "wall", "cost": 28.0, "cd": 6.0, "width": 5.0, "height": 2.6, "life": 12.0, "dist": 3.0, "fx": "rock", "sfx": "earth"},
		"r": {"name": "Earthquake", "kind": "quake", "cost": 45.0, "cd": 9.0, "dmg": 12.0, "range": 7.0, "stun": 1.6, "knock": 3.0, "fx": "rock", "sfx": "earth"},
	},
	"water": {
		"q": {"name": "Water Whip", "kind": "projectile", "cost": 11.0, "cd": 0.6, "dmg": 16.0, "speed": 34.0, "radius": 0.45, "knock": 3.0, "gravity": 0.0, "range": 20.0, "effect": "slow", "fx": "water", "sfx": "water"},
		"e": {"name": "Healing Water", "kind": "heal", "cost": 35.0, "cd": 6.0, "amount": 0.3, "range": 5.0, "fx": "water", "sfx": "water"},
		"r": {"name": "Ice Spikes", "kind": "volley", "cost": 40.0, "cd": 5.0, "dmg": 14.0, "speed": 38.0, "radius": 0.3, "knock": 1.5, "gravity": 0.0, "range": 26.0, "count": 5, "spread": 22.0, "effect": "slow", "fx": "ice", "sfx": "water"},
	},
	"air": {
		"q": {"name": "Air Blast", "kind": "projectile", "cost": 10.0, "cd": 0.55, "dmg": 9.0, "speed": 32.0, "radius": 1.0, "knock": 13.0, "gravity": 0.0, "range": 24.0, "effect": "", "pierce": true, "fx": "air", "sfx": "air"},
		"e": {"name": "Air Sweep", "kind": "cone", "cost": 25.0, "cd": 2.5, "dmg": 8.0, "range": 7.0, "angle": 80.0, "knock": 16.0, "effect": "", "fx": "air", "sfx": "air"},
		"r": {"name": "Air Scooter Slam", "kind": "quake", "cost": 40.0, "cd": 8.0, "dmg": 14.0, "range": 8.0, "stun": 1.2, "knock": 14.0, "fx": "air", "sfx": "air"},
	},
	"sand": {
		"q": {"name": "Sand Blast", "kind": "projectile", "cost": 14.0, "cd": 0.9, "dmg": 15.0, "speed": 26.0, "radius": 0.8, "knock": 4.0, "gravity": 1.0, "range": 24.0, "effect": "blind", "fx": "sand", "sfx": "air"},
		"e": {"name": "Sand Storm", "kind": "cone", "cost": 28.0, "cd": 4.0, "dmg": 10.0, "range": 7.0, "angle": 70.0, "knock": 6.0, "effect": "blind", "fx": "sand", "sfx": "air"},
		"r": {"name": "Sand Wall", "kind": "wall", "cost": 28.0, "cd": 7.0, "width": 5.0, "height": 2.2, "life": 9.0, "dist": 3.0, "fx": "sand", "sfx": "earth"},
	},
}

static func ability(element: String, slot: String) -> Dictionary:
	return ABILITIES.get(element, {}).get(slot, {})

static func fx_color(fx: String) -> Color:
	match fx:
		"fire": return Color(1.0, 0.45, 0.1)
		"blue_fire": return Color(0.3, 0.55, 1.0)
		"rock": return Color(0.45, 0.36, 0.25)
		"water": return Color(0.3, 0.6, 1.0, 0.85)
		"ice": return Color(0.75, 0.9, 1.0)
		"air": return Color(0.92, 0.95, 1.0, 0.55)
		"sand": return Color(0.85, 0.75, 0.5, 0.8)
		"lightning": return Color(0.7, 0.85, 1.0)
		"arrow": return Color(0.45, 0.32, 0.2)
	return Color.WHITE
