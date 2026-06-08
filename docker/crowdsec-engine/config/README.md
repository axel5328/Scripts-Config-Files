## Local Overrides

### Nextcloud Memories

Normales Scrollen in der Nextcloud Memories Android App erzeugt viele
Preview-Requests und führte zu False Positives in:

- crowdsecurity/http-probing
- crowdsecurity/http-crawl-non_statics
- LePresidente/http-generic-403-bf

Ausgenommene Endpunkte:

- /apps/memories/api/image/preview/*
- /apps/memories/api/image/multipreview
- /apps/memories/api/days/*
