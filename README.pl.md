# cursor-cloak

Chowa prawdziwy kursor Windows przed nagrywaniem ekranu, a Ty dalej widzisz strzałkę.
Usuwa **podwójny kursor** w programach, które na nagraniu dorysowują własny, wygładzony
kursor, np. w [Openscreenie](https://github.com/siddharthvaddem/openscreen) w trybie
nagrywania przez przeglądarkę.

Dwa pliki `.bat` i jeden skrypt PowerShell. Bez instalacji i bez uprawnień
administratora, a po wyłączeniu nic nie zostaje zmienione.

> English: [README.md](README.md)

## Problem

Programy z auto-zoomem zapisują pozycję myszki i w edytorze rysują własny, ładniejszy
kursor. Jeśli w nagranym obrazie jest też prawdziwy kursor Windows (nagrywanie przez
Chromium wpisuje go w obraz i ignoruje `cursor: "never"`), na filmie widać dwa kursory,
które rozjeżdżają się przy każdym ruchu.

## Jak to działa

- **Włączenie** (`kursor-ukryj.bat`): 12 najczęstszych kursorów systemowych (strzałka,
  kursor tekstowy, rączka, klepsydra, zmiana rozmiaru i inne) dostaje przezroczysty
  obrazek przez funkcję `SetSystemCursor`. Na nagraniu nie ma prawdziwego kursora, ale
  Windows dalej zna pozycję myszki, więc auto-zoom i kursor z edytora działają.
- **Strzałka tylko dla Ciebie:** za myszką chodzi mała biała strzałka. To okno wyłączone
  z nagrywania (`SetWindowDisplayAffinity` z `WDA_EXCLUDEFROMCAPTURE`), więc widzisz je
  na ekranie, a na filmie go nie ma. Stoi 1 piksel obok czubka kursora, więc kliknięcia
  trafiają w program pod spodem.
- **Wyłączenie** (`kursor-przywroc.bat`): przywraca kursory z ustawień Windows
  (`SPI_SETCURSORS`) i zamyka strzałkę. Wylogowanie albo restart też je przywraca.
- **Bezpiecznik:** skrypt schowa kursor tylko wtedy, gdy strzałka naprawdę wystartowała.

## Wymagania

- Windows 10 w wersji 2004 (kompilacja 19041) lub nowszej albo Windows 11. Starsze
  wersje nie mają `WDA_EXCLUDEFROMCAPTURE`.
- Windows PowerShell 5.1, który jest wbudowany w Windows.

Sprawdzone na Windows 10 22H2 z Openscreenem 1.5.0 (nagrywanie przez przeglądarkę)
i dwoma monitorami.

## Jak używać

1. Pobierz repozytorium (Code → Download ZIP) i trzymaj pliki razem w jednym folderze.
2. Przed nagraniem uruchom `kursor-ukryj.bat`. Kursor zamieni się w białą strzałkę.
3. Nagrywaj jak zwykle. Na filmie będzie tylko kursor dorysowany przez program.
4. Po nagraniu uruchom `kursor-przywroc.bat`.

Z terminala:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\cursor-cloak.ps1 on
powershell -NoProfile -ExecutionPolicy Bypass -File .\cursor-cloak.ps1 off
```

Przy pierwszym uruchomieniu skrypt tworzy obok siebie plik `blank.cur` (przezroczysty
kursor 32×32), więc folder musi pozwalać na zapis.

Windows może pytać o zgodę na uruchomienie pliku `.bat` pobranego z internetu. Żeby nie
pytał, przed rozpakowaniem kliknij ZIP prawym przyciskiem, wybierz Właściwości, zaznacz
Odblokuj i dopiero potem rozpakuj.

**Jeśli kiedyś zostaniesz bez widocznego kursora**, użyj klawiatury: Win+R, wpisz pełną
ścieżkę do `kursor-przywroc.bat` i naciśnij Enter. Wylogowanie też przywraca kursor.

## Tryby diagnostyczne

- `test`: strzałka NIE jest wyłączona z nagrywania i stoi 24 piksele obok kursora, więc
  widać ją na zrzutach i nagraniach.
- `ghost`: strzałka jest wyłączona z nagrywania jak zwykle i stoi 24 piksele obok
  kursora, a prawdziwy kursor nie jest schowany. Sprawdzisz nim, czy widzisz strzałkę.

Strzałkę z trybu diagnostycznego zamyka `off`.

## Pułapki, na które trafiliśmy

- Okno warstwowe z przezroczystym kolorem (`TransparencyKey`) razem
  z `WDA_EXCLUDEFROMCAPTURE` znikało także z ekranu, więc zostawaliśmy bez kursora.
  Dlatego strzałka jest zwykłym oknem przyciętym regionem GDI.
- `off` szuka procesu strzałki po dokładnym wierszu polecenia
  (`cursor-cloak.ps1 overlay…`). Luźne dopasowanie słowa „overlay” zamknęło nam kiedyś
  okno PowerShella, z którego uruchamialiśmy skrypt.
- Strzałka jest zawsze strzałką: nie zmienia się w kursor tekstowy ani w rączkę.

## Licencja

MIT, szczegóły w pliku [LICENSE](LICENSE).

Skąd ten skrypt i jak nagrywamy ekran, opisaliśmy w artykule
[Jaki program do nagrywania ekranu wybrać](https://zautomatyzowani.ai/faq/program-do-nagrywania-ekranu/).
