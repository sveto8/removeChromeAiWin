# Chrome AI Cleaner

Batch skripta (`removeChromeAi.bat`) za onemogucavanje ugradenih AI znacajki u Google Chromeu na Windowsu (Gemini, AI Mode, lokalni on-device AI model).

## Sto skripta radi

1. **Zatvara Chrome** ako je pokrenut.
2. **Radi backup postojecih Chrome registry policyja** (ako postoje) u `%USERPROFILE%\Desktop\Chrome_AI_Backup`, prije nego sto bilo sto mijenja.
3. **Postavlja Chrome enterprise policye** koje trajno onemogucuju AI funkcije:
   - `GenAILocalFoundationalModelSettings = 1` - iskljucuje lokalni (on-device) AI model
   - `GeminiSettings = 1` - iskljucuje Gemini integraciju
   - `AIModeSettings = 1` - iskljucuje AI Mode u pretrazivanju
4. **Pronalazi i brise postojece lokalno preuzete AI model datoteke** (npr. `weights.bin` unutar `OptGuideOnDeviceModel`, `OnDeviceModel`, `OptimizationGuide` foldera) unutar Chrome profila, da se odmah oslobodi prostor na disku.
5. **Ne dira** bookmarke, lozinke, povijest ni ekstenzije.
6. Na kraju ispisuje trenutno stanje postavljenih policyja radi provjere.

## Vazna napomena o disku

Nakon brisanja, Chrome moze **ponovno preuzeti** AI model datoteke u pozadini (preko internog "Component Updater" mehanizma) kad se sljedeci put pokrene. To je normalno i **nije problem** - iako datoteka ponovno postoji na disku (obicno nekoliko stotina MB), AI funkcije ostaju neaktivne zbog postavljenih policyja iz koraka 3. Skripta se moze ponovno pokrenuti bilo kada da se ta datoteka opet obrise, ako smeta.

## Kako koristiti

1. Preuzmi `removeChromeAi.bat`.
2. Pokreni ga dvoklikom (skripta sama trazi Administrator prava i ponudi UAC prompt - klikni **Yes**).
3. Prati upute na ekranu, pritisni bilo koju tipku kad se od tebe trazi.
4. Nakon zavrsetka, otvori Chrome i idi na `chrome://policy`, pa klikni **Reload policies** da se promjene odmah primijene.
5. Provjeri da je `GenAILocalFoundationalModelSettings` postavljen na `1`.

## Zahtjevi

- Windows s instaliranim Google Chromeom
- Administrator prava (skripta ih sama trazi)

## Sigurnost

Skripta mijenja samo Windows registry pod `HKLM\SOFTWARE\Policies\Google\Chrome` (standardna Chrome enterprise policy lokacija) i brise iskljucivo AI model datoteke unutar prepoznatih AI foldera u Chrome profilu. Ne dira druge dijelove sustava. Registry backup se automatski sprema prije bilo kakve izmjene, pa se promjene mogu rucno vratiti importanjem `.reg` datoteka iz backup mape ako je potrebno.
