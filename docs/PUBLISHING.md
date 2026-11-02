# Neon Pulse publiceren (privé beta)

## 1. Bouwen
```bash
monkeyc -e -f monkey.jungle -o bin/NeonPulse.iq -y ~/.garmin-keys/developer_key.der
```
Dit maakt `bin/NeonPulse.iq`, het bestand dat je uploadt.

## 2. Developer-account
Log in op <https://apps-developer.garmin.com> met je Garmin-account en accepteer de developer-voorwaarden. Kom je niet verder? Ga direct naar <https://apps-developer.garmin.com/en-US/developer/dashboard>.

## 3. Uploaden als beta
1. Klik op **Upload an App** en kies `bin/NeonPulse.iq`.
2. Kies als type **Watch Face**.
3. Vink **Beta App** aan. Een beta-app is privé, alleen te vinden via de link, en wordt niet gereviewd.
4. Vul een korte beschrijving in en voeg een screenshot toe. Die maak je in de simulator via **File > Save Screen Capture**.
5. Sla op en dien in.

## 4. Installeren op het horloge
1. Open de beta-link op je telefoon.
2. Installeer de watchface via de **Connect IQ Store**-app.
3. Synchroniseer het horloge.

> **Let op:** installeren gaat nu via de **Connect IQ Store**-app. Volgens gebruikers op het Garmin-forum is een beta installeren lastiger geworden. Werkt de beta-link niet? Bouw dan `bin/NeonPulse.prg` (`monkeyc -d fenix847mm -f monkey.jungle -o bin/NeonPulse.prg -y ~/.garmin-keys/developer_key.der`), sluit het horloge via USB aan en kopieer het bestand naar `GARMIN/APPS/`.

## 5. Instellingen
Je wijzigt de kleuren, maten en velden in de **Garmin Connect**-app onder Apparaat > Wijzerplaten > Neon Pulse > Instellingen. Je kunt dit ook in de Connect IQ-app doen.

## Updates
- Teken elke update met **dezelfde** developer key (`~/.garmin-keys/developer_key.der`). Met een andere key wordt het een nieuwe app.
- Verhoog de versie en upload een nieuwe `.iq` bij dezelfde app.

## Nooit committen
De developer key (`*.der`) en de `.iq`/`.prg`-bestanden horen niet in git. `.gitignore` sluit ze al uit. Maak een back-up van de key op een veilige plek.
