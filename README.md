# Classicum Admin

App mobile (Flutter) per gestire il sito di Classicum. Per ora contiene solo la
sezione **admin**: l'utente semplice non è ancora una funzione della piattaforma.

Il design segue il mock-up dell'app (EB Garamond + Inter, nero / crema / oro).

## Sezioni

| Tab      | Cosa fa                                                              | API del sito                          |
| -------- | -------------------------------------------------------------------- | ------------------------------------- |
| Oggi     | prossimo evento, scorciatoie, ultime news                            | `GET /api/eventi`, `GET /api/news`    |
| Agenda   | eventi (prossimi / passati), creazione con immagine, eliminazione    | `/api/eventi`                         |
| Moduli   | moduli del form builder, pubblica/bozza, risposte ricevute           | `/api/form`, `/api/form/:id/submissions` |
| Messaggi | richieste dal modulo contatti, ricerca, eliminazione                 | `/api/contact`                        |
| Profilo  | account, uscita                                                      | `/api/auth/*`                         |

Dalla home: news (crea, modifica, elimina) e comunicati stampa (crea, modifica, elimina).

## Autenticazione

Il sito usa cookie httpOnly per il web. Per l'app il sito accetta anche
`Authorization: Bearer <accessToken>`; con l'header `X-Client: mobile`,
`/api/auth/login` e `/api/auth/refresh` restituiscono i token nel body.
I token sono salvati nello storage sicuro del dispositivo e rinnovati
automaticamente alla prima risposta 401. L'account deve essere attivo
(`AdminUser.isActive = true`).

## Sviluppo

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000   # emulatore Android -> localhost
flutter analyze
flutter test
```

`API_BASE_URL` di default è `https://classicum.fly.dev`.

## CI / CD

- `.github/workflows/ci.yml`: su ogni push a `main` e PR esegue formattazione,
  `flutter analyze`, `flutter test --coverage` e costruisce un APK debug (artifact).
- `.github/workflows/release.yml`: un tag `vX.Y.Z` esegue i test, costruisce APK e
  app bundle release e li allega a una GitHub Release.
  Imposta la variabile di repository `API_BASE_URL` se il sito non è su `classicum.fly.dev`.

> Le release sono firmate con la chiave di debug finché non viene configurata una
> keystore di upload. Prima di pubblicare sullo store va aggiunta.
