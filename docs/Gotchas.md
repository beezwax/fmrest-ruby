## Gotchas

This is a compilation of gotchas, mostly related to unexpected behaviors and
conditions in the FileMaker Data API itself, or the relationship of those with
this library.

### Duplicated (same name) portals

In FileMaker a single layout can hold two or more portals with the same name.
In that situation the Data API will include each portal in the response JSON
without regard for the duplication, resulting in an invalid JSON with two
identical keys at the same level. E.g.:

```json
{
  "response": {
    "data": [{
      "fieldData": {
        …
      },
      "portalData": {
        "MyPortal": [{
          …
        }],
        "MyPortal": [{
          …
        }]
      },
      "portalDataInfo": [{
        "portalObjectName": "MyPortal",
        "database": "…",
        "table": "…",
        "foundCount": 3,
        "returnedCount": 3
      },
      {
        "portalObjectName": "MyPortal",
        "database": "…",
        "table": "…",
        "foundCount": 3,
        "returnedCount": 3
      }]
    }]
  },
  …
}
```

Because fmrest-ruby uses standard JSON parsers that (correctly) don't account
for this kind of key duplication, in situations like this only one of the
duplicated portals will be ingested, with no way of controlling which one will
be.

The solution to this is to give each portal a unique name within the FileMaker
layout.
