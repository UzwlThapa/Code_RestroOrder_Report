# RestroOrder Reports UI

Next.js reporting dashboard recovered from the Rocket AI build. Connects to
`RestroOrder.ReportsApi` for live data (Cost Centre report today; IRD Sales and
Menu Engineering still use sample data until their endpoints exist).

## Reports
- **IRD Sales Book** — Nepal IRD compliance view
- **Menu Engineering** — Top / Low / Dead items
- **Cost Centre Purchase Report** — Kitchen / Bar / Bakery

## Run locally

```bash
npm install
npm run dev
```

Open http://localhost:3000

Set the API base URL in `.env.local`:

```
NEXT_PUBLIC_API_URL=http://localhost:5080
```

## Production build

```bash
npm run build
npm start
```
