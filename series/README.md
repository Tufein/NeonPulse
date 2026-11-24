# Watchface-reeks (6 faces, release begin december 2026)

Zes losse watchfaces op één gedeelde codebasis, gericht op de Fenix 8- en Venu-reeks.
Ion Ring (de face in de root van deze repo) staat hier los van en blijft ongewijzigd.

| Map | Naam in de store | Stijl | Velden die je kan kiezen |
| --- | --- | --- | --- |
| `faces/bitlevel` | Bitlevel | Retro 8-bit: pixelcijfers, hartjes = batterij, XP-balk, pixelgrond | XP-balk, 2 stats, 2 kleuren |
| `faces/ridgeline` | Ridgeline | Outdoor: twee bergkammen, zon of maan loopt tussen zonsopkomst en -ondergang | 3 velden, accent, lucht |
| `faces/meridian` | Meridian Chrono | Analoog chrono: minutenring, 3 subwijzerplaten, datumvenster | 3 subdials, accent, wijzerplaat |
| `faces/stacked` | Stacked Hours | Grote uren boven grote minuten, zijkolom, randbogen (stappen, batterij) | 2 velden, 2 kleuren |
| `faces/gridwork` | Gridwork | Tijd + 6 datategels met voortgangsstrook | 6 tegels, accent |
| `faces/sunpath` | Sunpath 24 | 24-uurswijzerplaat, daglichtboog, zon/maan-marker, op/onder-tijden | 1 veld, daglichtkleur |

Elk veld kiest uit dezelfde lijst: batterij, hartslag, stappen, calorieën, actieve minuten,
body battery, verdiepingen, afstand, stress, hoogte, temperatuur, meldingen, volgende
zonsopkomst/-ondergang. Alle faces hebben ook 12/24 uur (behalve het analoge Meridian)
en optioneel seconden.

## Toestellen

Alle layouts zijn ontworpen op 454x454 en schalen mee (`Kit.Screen`).

| Scherm | Toestellen (device id) |
| --- | --- |
| AMOLED rond 454 | Fenix 8 47/51mm (`fenix847mm`), Fenix 8 Pro (`fenix8pro47mm`), Venu 3 (`venu3`), Venu 4 45mm (`venu445mm`), FR970, FR965, FR570 47mm, Epix Pro 51mm |
| AMOLED rond 416 | Fenix 8 43mm (`fenix843mm`), Fenix E (`fenixe`), FR265, Epix Pro 47mm |
| AMOLED rond 390 | Venu 3S (`venu3s`), Venu 4 41mm (`venu441mm`), vivoactive 5/6, FR570 42mm, FR165, Epix Pro 42mm |
| MIP rond 260/280 | Fenix 8 Solar 47/51mm (`fenix8solar47mm`, `fenix8solar51mm`), Enduro 3 (`enduro3`) |
| AMOLED rechthoek 448x486 | Venu X1 (`venux1`) |

Bron schermdata: [Connect IQ compatible devices](https://developer.garmin.com/connect-iq/compatible-devices/).
Niet meegenomen: Instinct 3 Solar (176x176, 2 kleuren), daar past geen van deze ontwerpen op.

De device ids staan in `tools/series.py` (`DEVICES`). Ze zijn niet allemaal geverifieerd tegen
de SDK. `build.sh` controleert ze tegen de devices van jouw SDK en laat onbekende ids weg,
met een lijst van wat hij vond (resolutie, scherm). Fenix 8 Pro 51mm en MicroLED: kijk in die
lijst of ze een eigen id hebben en voeg ze dan toe aan `DEVICES`.

## Hoe de code in elkaar zit

```
series/
  common/source/
    Kit.mc        instellingen, kleurenpalet, schermschaal (rond en rechthoek), tijd/datum,
                  vector fonts met cache, bogen, zonsopkomst/-ondergang (cache 10 min)
    Stats.mc      alle datavelden met één id-lijst, geeft [voortgang, waarde, label]
    BaseFace.mc   SeriesApp (gedeeld startpunt) en BaseFace: slaapmodus, always-on op AMOLED
                  (gedimd en elke minuut verschoven tegen inbranden), MIP blijft de gewone face tonen
  faces/<id>/
    source/FaceView.mc     alleen het tekenwerk van die face (erft van BaseFace)
    manifest.xml, monkey.jungle, resources/   gegenereerd door tools/series.py
  tools/series.py   één tabel met alle faces: naam, app-id, instellingen, toestellen, icoon
  tools/pixelfont.py   het 3x5 pixelfont van Bitlevel
  build.sh          bouwt alle .iq-bestanden op de Mac
```

Een instelling of toestel aanpassen: wijzig de tabel in `tools/series.py` en draai
`python3 series/tools/series.py`. CI controleert dat de gegenereerde bestanden kloppen en dat
elke instelling die de code leest ook bestaat.

## Bouwen op de Mac

```
series/build.sh                # alle zes .iq-bestanden in series/bin/
series/build.sh fenix847mm     # plus een .prg per face voor de simulator
connectiq &
monkeydo series/bin/bitlevel-fenix847mm.prg fenix847mm
```

Test minstens: `fenix847mm` (454), `venu441mm` (390), `fenix8solar51mm` (MIP),
`venux1` (rechthoek). In de simulator: Settings > Low power mode voor always-on, en
File > Edit persistent storage / app settings voor de instellingen.

## Store, per face

Elke face is een eigen store-vermelding met een eigen app-id (staat al in `tools/series.py`).

1. Naam controleren: zoek de naam in de Connect IQ store-app. Vanuit de cloud kon ik de store
   niet bereiken; op het web vond ik geen face met deze namen. Is een naam bezet, wijzig hem
   in `FACES` en draai de generator opnieuw.
2. `series/build.sh` draaien, dan in https://apps-developer.garmin.com > Upload an app, het
   `.iq`-bestand van die face kiezen.
3. Icoon (512x512 en de 70x70 die al in de face zit), hero 1440x720 en 3 screenshots
   (maak ze in de simulator: File > Save screenshot), beschrijving NL + EN, categorie Watch Faces.
4. Eerst als private beta naar je eigen horloge, dan openbaar. Review duurt meestal 1 tot 3 werkdagen.

## Planning (richttijd)

| Stap | Wie | Tijd |
| --- | --- | --- |
| Basis + 6 faces in code | Claude | klaar (ca. 3 uur) |
| Compileren, fouten fixen, simulator per face | Stefan + Claude | ca. 15 tot 20 min per face, 2 uur totaal |
| Store-afbeeldingen + teksten | Claude (screenshots uit de simulator van Stefan) | ca. 1 uur voor alle zes |
| Upload 6 vermeldingen | Stefan | ca. 10 min per face |
| Review Garmin | Garmin | 1 tot 3 werkdagen |

Nog niet getest (geen SDK in de cloud): compileren, echte sensorwaarden, always-on, instellingen.
