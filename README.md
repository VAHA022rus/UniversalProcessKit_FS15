# UniversalProcessKit für LS15

Dieses projekt befindet sich zur Zeit in der "Konvertierungsphase" aus den LS13-Skripten. Unter der Haube vom UPK hat sich sehr viel verändert und nach und nach werden jetzt die Module ergänzt.

__aktuelle Entwickler-Version -> AAA\_UniversalProcessKit-dev__

__Dokumentation -> 00\_documentation__

__Beispiel-Mods -> 00\_examples__

Bisher enthaltene Module:

- base
- animator
- balertrigger
- displaytrigger
- dumptrigger
- emptytrigger
- entitytrigger
- filltrigger
- gasstationtrigger
- mover
- parktrigger
- processor
- selltarget
- sprayerfilltrigger
- switcher
- tiptrigger
- unspecified

##Changelog

__V0.7.11__

- Modultyp balertrigger hinzugefügt
- Modultyp sprayerfilltrigger hinzugefügt
- Modultyp gasstationtrigger hinzugefügt
- neu: fillType (balertrigger)
- neu: fillLitersPerSecond (balertrigger)
- neu: createFillType (balertrigger)
- neu: pricePerLiter (balertrigger)
- neu: statName (balertrigger)
- neu: createFillType (sprayerfilltrigger)
- neu: pricePerLiter (sprayerfilltrigger)
- neu: statName (sprayerfilltrigger)
- neu: createFillType (gasstationtrigger)
- neu: pricePerLiter (gasstationtrigger)
- neu: statName (gasstationtrigger)
- Fix für emptytrigger
- neu: spezielle Fülltypen "newVehiclesCost", "newAnimalsCost", "constructionCost", "vehicleRunningCost", "propertyMaintenance", "wagePayment", "harvestIncome", "missionIncome" und "loanInterest" hinzugefügt
- Beispielmod UPK_FertilizerTest und UPK_FuelTest hinzugefügt

__V0.7.10__

- Modultyp animator hinzugefügt
- neu: moveTo (animator)
- neu: movementDuration (animator)
- neu: movementSpeedupPeriod (animator)
- neu: movementSlowdownPeriod (animator)
- neu: rewindMovementOnDisable (animator)
- neu: rotationsPerSecond (animator)
- neu: rotateTo (animator)
- neu: rotationDuration (animator)
- neu: rotationSpeedupPeriod (animator)
- neu: rotationSlowdownPeriod (animator)
- neu: rewindRotationOnDisable (animator)
- neu: animationClip (animator)
- neu: animationSpeed (animator)
- neu: animationLoop (animator)
- neu: rewindAnimationOnDisable (animator)
- Beispielmod UPK_AnimatorTest hinzugefügt

__V0.7.9__

- neu: onCreate (base)
- geändert: alle UPK-Beispielmods

__V0.7.8__

- Modultyp switcher hinzugefügt
- Modultyp selltarget hinzugefügt
- Modultyp parktrigger hinzugefügt
- Fix für mover
- neu: fillTypes (switcher)
- neu: fillTypeChoice (switcher)
- neu: switchFillTypes (switcher)
- neu: switchFillLevels (switcher)
- neu: mode (switcher)
- neu: hidingPosition (switcher)
- geändert: startVisibilityAt (mover)
- geändert: stopVisibilityAt (mover)
- Beispielmod UPK_ParkTriggerTest hinzugefügt

__V0.7.7__

- Modultyp mover hinzugefügt
- neu: fillTypes (mover)
- neu: fillTypeChoice (mover)
- neu: startMovingAt (mover)
- neu: stopMovingAt (mover)
- neu: lowPosition (mover)
- neu: highPosition (mover)
- neu: lowerPosition (mover)
- neu: higherPosition (mover)
- neu: movingType (mover)
- neu: startTurningAt (mover)
- neu: stopTurningAt (mover)
- neu: lowRotation (mover)
- neu: highRotation (mover)
- neu: lowerRotation (mover)
- neu: higherRotation (mover)
- neu: turningType (mover)
- neu: startVisibilityAt (mover)
- neu: stopVisibilityAt (mover)
- Beispielmod UPK_MoverTest hinzugefügt

__V0.7.6__

- Modultyp dumptrigger hinzugefügt
- neu: acceptedFillTypes (dumptrigger)
- neu: revenuePerLiter (dumptrigger)
- neu: revenuesPerLiter (dumptrigger)
- neu: statName (dumptrigger)
- Fix für initialFillLevels (Standard-UserAttributes)
- Beispielmod UPK_DumpTriggerTest hinzugefügt

__V0.7.5__

- Fix für convertFillTypes (Standard-UserAttributes)
- Beispielmod UPK_TipTriggerTest2 hinzugefügt

__V0.7.4__

- neu: Fülltypen-Behandlung für money, void, sun, rain und temperature
- Beispielmod UPK_ProcessorTest3 hinzugefügt

__V0.7.3__

- neu: Speichern und Laden von Füllständen
- neu: convertFillTypes (Standard-UserAttributes)
- Modultyp emptytrigger hinzugefügt
- neu: emptyFillTypes (emptytrigger)
- neu: emptyLitersPerSecond (emptytrigger)
- neu: revenuePerLiter (emptytrigger)
- neu: revenuesPerLiter (emptytrigger)
- neu: statName (emptytrigger)
- neu: revenuePerLiter (tiptrigger)
- neu: revenuesPerLiter (tiptrigger)
- neu: statName (tiptrigger)
- Beispielmod UPK_EmptyTriggerTest hinzugefügt

__V0.7.2__

- Modultyp filltrigger hinzugefügt
- neu: fillType (filltrigger)
- neu: fillLitersPerSecond (filltrigger)
- neu: createFillType (filltrigger)
- neu: pricePerLiter (filltrigger)
- neu: statName (filltrigger)
- Beispielmod UPK_FillTriggerTest hinzugefügt

__V0.7.1__

- Modultyp tiptrigger hinzugefügt
- neu: acceptedFillTypes (tiptrigger)
- neu: showNotAcceptedWarning (tiptrigger)
- neu: showCapacityReachedWarning (tiptrigger)
- Beispielmod UPK_TipTriggerTest hinzugefügt

__V0.7.0__

- neue Art Füllstände zu verwalten

(Versionsnummern übersprungen)

__V0.1.3__

- Modultyp unspecified hinzugefügt
- geändert: enableChildrenIfProcessing (pocessor)
- neu: addIfProcessing (processor)
- neu: emptyFillTypesIfProcessing (processor)
- neu: enableChildrenIfNotProcessing (processor)
- neu: disableChildrenIfProcessing (processor)
- neu: disableChildrenIfNotProcessing (processor)
- umbenannt: von „equal“ zu „uniform“ in outcomeVariationType (procesor)
