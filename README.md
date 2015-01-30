# UniversalProcessKit für LS15

Das UniversalProcessKit (UPK) ist kein Mod im eigentliche Sinn, sondern es erweitert LS15 um Funktionalität, damit es Modder leichter haben, Gebäude mit Funktionen auszustatten. Dabei spielt es keine Rolle, ob das Gebäude platzierbar oder einbaubar sein soll.

Dieses Kit besteht aus verschiedenen Modulen, deren Aktionen durch den Spieler ausgelöst werden oder welche die je nach Füllstand aktiv werden. Es kann zudem durch selbst programmierte Module erweitert werden.

Die Konfiguration des UPK-Mods wird allein über UserAttributes in der i3d geregelt. Mapper und Modder "verwenden" die Funktionen einfach (wie die Funktionen der Giants-Skripte auch) - es ist nicht nötig/erlaubt das UPK zu "verbauen".


__aktuelle Version -> AAA\_UniversalProcessKit__

__aktuelle Entwickler-Version -> AAA\_UniversalProcessKit-dev__

__Dokumentation -> 00\_documentation__

__Beispiel-Mods -> 00\_examples__

Bisher enthaltene Module:

- base
- activatortrigger
- animator
- balertrigger
- baletrigger
- displaytrigger
- dumptrigger
- emptytrigger
- entitytrigger
- filltrigger
- gasstationtrigger
- liquidmanurefilltrigger
- mover
- pallettrigger
- parktrigger
- processor
- selltarget
- sprayerfilltrigger
- switcher
- tiptrigger
- unspecified
- washtrigger
- waterfilltrigger

##Changelog

__V0.9.6__

- Modultyp washtrigger hinzugefügt
- neu: washPerSecond (washtrigger)
- neu: dirtThreshold (washtrigger)
- neu: pricePerSecond (washtrigger)
- neu: pricePerSecondMultiplier (washtrigger)
- neu: statName (washtrigger)
- neu: enableChildrenIfWashing (washtrigger)
- neu: disableChildrenIfWashing (washtrigger)
- neu: enableChildrenIfNotWashing (washtrigger)
- neu: disableChildrenIfNotWashing (washtrigger)
- neu: allowAttachment (Trigger-UserAttributes)
- Beispielmod UPK_WashTriggerTest hinzugefügt

__V0.9.5__

- weitere Multiplayer-Bugs behoben
- neu: removeIfProcessing (processor)
- neu: removeIfNotProcessing (processor)
- neu: emptyFillTypesIfProductionSkipped (processor)
- neu: addIfProductionSkipped (processor)
- neu: removeIfProductionSkipped (processor)
- neu: enableChildrenIfProductionSkipped (processor)
- neu: disableChildrenIfProductionSkipped (processor)
- neu: preferMapDefaultPrice (balertrigger)
- neu: pricePerLiterMultiplier (balertrigger)

__V0.9.4__

- filltrigger kann Paletten befüllen *experimentell*
- emptytrigger kann Paletten entleeren *experimentell*
- neu: showFillLevelDecimals (displaytrigger)
- neu: showCapacity (displaytrigger)
- neu: showCapacityDecimals (displaytrigger)
- neu: showPercentageDecimals (displaytrigger)
- neu: useLongUnitNames (displaytrigger)
- geändert: Reihenfolge von displayFillTypes wird nun beachtet (displaytrigger)
- neu: startScalingAt (mover)
- neu: stopScalingAt (mover)
- neu: lowScale (mover)
- neu: highScale (mover)
- neu: lowerScale (mover)
- neu: higherScale (mover)
- neu: scalingType (mover)
- neu: fillOnlyWholeNumbers (filltrigger)
- neu: addIfFilling (filltrigger)
- neu: removeIfFilling (filltrigger)
- neu: fillOnlyWholeNumbers (gasstationtrigger)
- neu: addIfFilling (gasstationtrigger)
- neu: removeIfFilling (gasstationtrigger)
- neu: fillOnlyWholeNumbers (liquidmanurefilltrigger)
- neu: addIfFilling (liquidmanurefilltrigger)
- neu: removeIfFilling (liquidmanurefilltrigger)
- neu: fillOnlyWholeNumbers (sprayerfilltrigger)
- neu: addIfFilling (sprayerfilltrigger)
- neu: removeIfFilling (sprayerfilltrigger)
- neu: fillOnlyWholeNumbers (waterfilltrigger)
- neu: addIfFilling (waterfilltrigger)
- neu: removeIfFilling (waterfilltrigger)
- neu: addIfDumping (dumptrigger)
- neu: removeIfDumping (dumptrigger)
- neu: addIfTipping (tiptrigger)
- neu: removeIfTipping (tiptrigger)
- neu: emptyOnlyWholeNumbers (emptytrigger)
- neu: addIfEmptying (emptytrigger)
- neu: removeIfEmptying (emptytrigger)
- geändert: adjustToTerrainHeight (Standard-UserAttributes)
- Beispielmod UPK_MoverTest2, UPK_FillTriggerTest2 hinzugefügt

__V0.9.3__

- Multiplayer-Bug gefixt
- FillTrigger-Bug von 0.9.1 gefixt

__V0.9.2__

- Modultyp pallettrigger hinzugefügt
- neu: acceptedFillTypes (pallettrigger)
- neu: ignorePallets (pallettrigger)
- neu: useFirstPallet (pallettrigger)
- neu: mode (pallettrigger)
- neu: delay (pallettrigger)
- neu: statName (pallettrigger)
- neu: revenueMultiplier (pallettrigger)
- neu: allowPallets (Trigger-UserAttributes)
- Beispielmod UPK_PalletTriggerTest und UPK_PalletTriggerTest2 hinzugefügt

__V0.9.1__

- Modultyp baletrigger hinzugefügt
- neu: acceptedFillTypes (baletrigger)
- neu: acceptRoundBales (baletrigger)
- neu: acceptSquareBales (baletrigger)
- neu: ignoreBales (baletrigger)
- neu: useFirstBale (baletrigger)
- neu: mode (baletrigger)
- neu: delay (baletrigger)
- neu: statName (baletrigger)
- neu: revenueMultiplier (baletrigger)
- neu: allowBales (Trigger-UserAttributes)
- neu: preferMapDefaultPrice (filltrigger)
- neu: pricePerLiterMultiplier (filltrigger)
- neu: preferMapDefaultPrice (gasstationtrigger)
- neu: pricePerLiterMultiplier (gasstationtrigger)
- neu: preferMapDefaultPrice (liquidmanurefilltrigger)
- neu: pricePerLiterMultiplier (liquidmanurefilltrigger)
- neu: preferMapDefaultPrice (sprayerfilltrigger)
- neu: pricePerLiterMultiplier (sprayerfilltrigger)
- neu: preferMapDefaultPrice (waterfilltrigger)
- neu: pricePerLiterMultiplier (waterfilltrigger)
- neu: preferMapDefaultRevenue (tiptrigger)
- neu: revenuePerLiterMultiplier (tiptrigger)
- neu: preferMapDefaultRevenue (dumptrigger)
- neu: revenuePerLiterMultiplier (dumptrigger)
- neu: preferMapDefaultRevenue (emptytrigger)
- neu: revenuePerLiterMultiplier (emptytrigger)
- Schnittstelle für CoursePlay hinzugefügt, dass das UPK erkannt werden kann
- Beispielmod UPK_BaleTriggerTest und UPK_BaleTriggerTest2 hinzugefügt

__V0.9.0__

- Modultyp activatortrigger hinzugefügt
- neu: isActive (activatortrigger)
- neu: activateText (activatortrigger)
- neu: deactivateText (activatortrigger)
- neu: showMapHotspot (Standard-UserAttributes)
- neu: MapHotspot (Standard-UserAttributes)
- neu: MapHotspotIcon (Standard-UserAttributes)
- neu: showMapHotspotIfDisabled (Standard-UserAttributes)
- Fix für animator (Synchronisation, Animation und Speichern)
- Beispielmod UPK\_ActivatorTriggerTest und UPK\_MapHotspotTest hinzugefügt

__V0.8.6__

- neu: allowMixerWagonPickup (Trigger-UserAttributes)
- neu: allowMixerWagonTrailer (Trigger-UserAttributes)
- Beispielmod UPK_MixerWagonTest hinzugefügt

__V0.8.1 - V0.8.5__

- diverse (größere) Bugfixes
- Fix für div. Trigger für pricePerLiter und revenuePerLiter
- Fix für switcher

__V0.8.0__

- Multiplayer-Support hinzugefügt

__V0.7.12__

- Modultyp waterfilltrigger hinzugefügt
- Modultyp liquidmanurefilltrigger hinzugefügt
- neu: createFillType (waterfilltrigger)
- neu: pricePerLiter (waterfilltrigger)
- neu: statName (waterfilltrigger)
- neu: createFillType (liquidmanurefilltrigger)
- neu: pricePerLiter (liquidmanurefilltrigger)
- neu: statName (liquidmanurefilltrigger)
- Beispielmod UPK_WaterTest, UPK_LiquidManureTest und UPK_MilkTest hinzugefügt


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
