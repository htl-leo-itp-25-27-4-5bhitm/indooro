# AI Upsell Flow

## Ablauf

```mermaid
sequenceDiagram
    participant User as Kunde
    participant App as iOS App
    participant API as Indooro Backend
    participant Catalog as OpenSearch Produktkatalog
    participant AI as OpenAI Responses API

    User->>App: Supermarkt oeffnen / Einkaufstour starten
    App->>App: Route in Stationen gruppieren
    App->>API: POST /api/mobile/upsell/plan
    API->>Catalog: Kandidaten fuer Store laden
    API->>API: Liste, erledigte Produkte und Trigger ausschliessen
    API->>API: Produkt-Domain, Familie und Klasse ableiten
    API->>API: Harte Quality-Gates und Plan-Dedupe anwenden
    API->>AI: Strukturierter Ranking-Prompt mit nur vorgefilterten Kandidaten
    AI-->>API: JSON mit opportunityId + productId-Rankings
    API->>API: IDs gegen Kandidaten und Gates validieren
    API-->>App: Plan-JSON mit Vorschlaegen pro Station
    App->>App: Plan lokal nach opportunityId cachen, auch leere Ergebnisse
    User->>App: Station abhaken oder ueberspringen
    App->>App: station:<shelf-id> lokal nachschlagen
    App-->>User: Sofort vorbereitete Vorschlaege anzeigen
    User->>App: Vorschlag hinzufuegen
    App->>App: Produkt mit addedFromUpsell=true speichern
```

## Request vom Client an das Backend

Die App sendet keinen OpenAI-Key. Sie sendet nur die aktuelle Store-/Listen-/Stations-Situation:

```json
{
  "storeId": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
  "storeCode": "demo-store",
  "shoppingListId": "local-list-uuid",
  "currentListProductIds": [1, 3, 8],
  "completedProductIds": [],
  "source": "shopping_session",
  "opportunities": [
    {
      "opportunityId": "station:shelf-430",
      "triggerProductIds": [1, 3],
      "triggerProductNames": ["Spaghetti", "Tomatensauce"]
    },
    {
      "opportunityId": "station:shelf-525",
      "triggerProductIds": [8],
      "triggerProductNames": ["Parmesan"]
    }
  ]
}
```

## Prompt an OpenAI

System:

```text
Rank supermarket add-on products for each shopping station. Select only productIds from candidateProducts and only opportunityIds from opportunities. Do not invent products or opportunityIds. Reasons must be concise German customer-facing text.
```

User-Payload:

```json
{
  "opportunities": [
    {
      "opportunityId": "station:shelf-430",
      "triggerProductIds": [1, 3],
      "triggerProductNames": ["Spaghetti", "Tomatensauce"]
    }
  ],
  "opportunities": [
    {
      "opportunityId": "station:shelf-430",
      "triggerProductIds": [1, 3],
      "triggerProductNames": ["Spaghetti", "Tomatensauce"],
      "candidateProducts": [
        {
          "id": 2,
          "name": "Parmesan",
          "categoryCode": "525",
          "family": "cheese",
          "classKey": "cheese",
          "score": 124
        }
      ]
    }
  ],
  "maxSuggestionsPerOpportunity": 3
}
```

## Erwartete OpenAI-Antwort

OpenAI muss strikt JSON liefern und darf nur IDs aus dem Payload verwenden:

```json
{
  "opportunities": [
    {
      "opportunityId": "station:shelf-430",
      "suggestions": [
        {
          "productId": 2,
          "reason": "Passt gut zu Pasta und Sauce.",
          "confidence": 0.82
        }
      ]
    }
  ]
}
```

## Antwort vom Backend an die App

Das Backend ersetzt die AI-IDs durch echte Katalogprodukte, filtert ungueltige IDs, bereits gelistete Produkte und Trigger-Produkte:

```json
{
  "source": "openai",
  "expiresAt": "2026-06-03T10:30:00Z",
  "debug": {
    "requestId": "a-runtime-uuid",
    "model": "gpt-5.4-mini",
    "responseSource": "openai",
    "elapsedMs": 1320,
    "openAiElapsedMs": 1190,
    "inputTokens": 480,
    "outputTokens": 96,
    "totalTokens": 576,
    "cachedInputTokens": 0,
    "reasoningTokens": 0,
    "fallbackReason": null,
    "opportunityCount": 1,
    "candidateCount": 50
  },
  "opportunities": [
    {
      "opportunityId": "station:shelf-430",
      "triggerProductIds": [1, 3],
      "suggestions": [
        {
          "product": {
            "id": 2,
            "name": "Basilikum",
            "price": 1.29,
            "layoutCode": "310/1/1/1",
            "storeId": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
            "storeCode": "demo-store",
            "brand": null,
            "category": "310",
            "imageUrl": null,
            "hasLayoutPosition": true
          },
          "reason": "Passt gut zu Pasta und Sauce.",
          "confidence": 0.82
        }
      ]
    }
  ]
}
```

## Wichtige Schutzregeln

- OpenAI-Key liegt nur im Backend als Secret/Env, nie in Swift.
- AI bekommt nur Backend-vorgefilterte Kandidaten, nie den ganzen Katalog.
- AI darf keine Produkte erfinden; unbekannte oder inkompatible `productId` werden verworfen.
- Bereits offene, erledigte, akzeptierte Upsell-Produkte und Trigger-Produkte werden per ID und Produktklasse ausgeschlossen.
- Inkompatible Domains werden hart geblockt, zum Beispiel Reiniger zu Lebensmitteln oder Cola zu Mehl.
- Wenn nur schwache Kandidaten existieren, liefert das Backend lieber eine leere Opportunity als ein schlechtes Popup.
- Stationen werden ueber `opportunityId` gebunden, dadurch kann keine alte Antwort fuer eine andere Station erscheinen.
- iOS cached leere Opportunities als `loaded_empty`; spaeteres Abhaken fuehrt dann zu `no_suggestions` statt `cache_miss`.
- Produkte, die aus Vorschlaegen hinzugefuegt wurden, bekommen `addedFromUpsell=true` und triggern keine neue Upsell-Suche.
- Debug-Ausgaben verwenden in iOS den Prefix `[UpsellDebug]`; Backend-Logs enthalten Request-ID, Source, Dauer und Token-Usage, aber keinen API-Key.
