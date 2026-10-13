**Author:** Markus van Kempen | [mvk@ca.ibm.com](mailto:mvk@ca.ibm.com) | [markus.van.kempen@gmail.com](mailto:markus.van.kempen@gmail.com)
[Research | Floor 7½ 🏢🤏](https://pages.github.ibm.com/mvankempen/homepage/)
*No bug too small, no syntax too weird.*

---

# WxO Observability Dashboard

This dashboard is a lightweight Node/Express application for exploring Watsonx Orchestrate trace data in a browser. It fetches trace summaries and full span payloads from the WxO observability APIs, then derives higher-level signals such as:

- likely agent name
- conversation presence
- tool usage
- error and interrupt indicators
- parent/child execution hierarchy
- prompt, completion, and structured payload content

The UI is intentionally optimized for debugging and issue discovery rather than polished reporting. It is useful when trace summaries alone are incomplete and you need to inspect the underlying OpenTelemetry payload.

## What The Dashboard Does

The application provides:

- environment selection for multiple WxO instances
- a trace list with agent-aware filtering
- conversation-only and tools-only toggles
- an overview strip for quick issue scanning
- detailed trace inspection backed by full span payloads
- timeline and hierarchy views for parent-child execution flow
- extracted conversation, tool, thought-process, and correlation signals
- JSON export of all currently loaded traces

## Current Architecture

The dashboard has two parts.

For a file-by-file and function-by-function code map, see [docs/CODE_ARCHITECTURE.md](/Users/markusvankempen/projects/wxo-projetcs/WxO-ToolBox/vsc/test_tools/wxo_observability_dashboard/docs/CODE_ARCHITECTURE.md).
For a trace semantics guide covering chats, spans, entities, tools, plugins, and user interaction, see [docs/TRACE_MODEL.md](/Users/markusvankempen/projects/wxo-projetcs/WxO-ToolBox/vsc/test_tools/wxo_observability_dashboard/docs/TRACE_MODEL.md).
The main runtime files also now carry inline documentation for the server routes, OTLP decoding helpers, enrichment pipeline, and inspector rendering flow.

### Backend

The backend is a small Express server in [server.js](/Users/markusvankempen/projects/wxo-projetcs/WxO-ToolBox/vsc/test_tools/wxo_observability_dashboard/server.js).

Responsibilities:

- load instance URLs and API keys from environment configuration
- mint and cache IAM tokens
- expose simplified local API endpoints to the browser
- proxy trace search and span export requests to WxO
- serve the static frontend from [public/index.html](/Users/markusvankempen/projects/wxo-projetcs/WxO-ToolBox/vsc/test_tools/wxo_observability_dashboard/public/index.html)

### Frontend

The frontend is plain HTML, CSS, and JavaScript:

- layout: [public/index.html](/Users/markusvankempen/projects/wxo-projetcs/WxO-ToolBox/vsc/test_tools/wxo_observability_dashboard/public/index.html)
- styling: [public/style.css](/Users/markusvankempen/projects/wxo-projetcs/WxO-ToolBox/vsc/test_tools/wxo_observability_dashboard/public/style.css)
- logic: [public/app.js](/Users/markusvankempen/projects/wxo-projetcs/WxO-ToolBox/vsc/test_tools/wxo_observability_dashboard/public/app.js)

Responsibilities:

- load available environments
- fetch trace summaries for the selected time range
- enrich weak summaries by loading full spans when needed
- filter and render traces in the list
- inspect a selected trace in multiple representations
- export raw JSON bundles

## Setup

### Requirements

- Node.js 18 or newer
- network access to the target Watsonx Orchestrate instance
- a valid API key for each instance you want to inspect

### Install

From the dashboard folder:

```bash
npm install
```

### Run

```bash
node server.js
```

The app listens on:

```text
http://localhost:3000
```

## Environment Configuration

This part matters because the current implementation does not read configuration from the dashboard-local `.env` file.

The server currently loads environment variables from a file located three directories above the dashboard directory:

```text
<repo-root>/vsc/.env
```

The path is hardcoded in [server.js](/Users/markusvankempen/projects/wxo-projetcs/WxO-ToolBox/vsc/test_tools/wxo_observability_dashboard/server.js).

### Supported Naming Pattern

Each environment is discovered from keys shaped like this:

```dotenv
<PREFIX>_INSTANCE_URL=https://...
<PREFIX>_API_KEY=...
```

Example:

```dotenv
WO_INSTANCE_URL=https://api.dl.watson-orchestrate.ibm.com/instances/...
WO_API_KEY=...
```

There is one built-in fallback:

- if the prefix is `WO`, the server will use `WO_API_KEY` or `WO_TRIAL_API_KEY`

### How Environment Names Appear In The UI

The server converts the prefix into a display name by replacing underscores with spaces and title-casing it.

Examples:

- `WO` becomes `Wo`
- `SYNC_TZ1` becomes `Sync Tz1`

### Local Systems Added In The UI

The Manage Systems modal can add environments at runtime.

Important constraints:

- these systems are stored only in memory
- they disappear when the server restarts
- systems loaded from the `.env` file cannot be removed in the UI

## Backend API

The browser talks only to the local Express server.

### `GET /`

Serves the dashboard UI.

### `GET /api/environments`

Returns only environment names.

### `GET /api/environments/details`

Returns environment metadata used by the system picker and systems modal.

Response shape:

```json
{
  "environments": [
    {
      "name": "Wo",
      "url": "https://...",
      "source": "env"
    }
  ]
}
```

### `POST /api/environments`

Adds a local in-memory environment.

Body:

```json
{
  "name": "Stage EU",
  "url": "https://...",
  "key": "..."
}
```

### `DELETE /api/environments/:name`

Removes a local in-memory environment.

### `GET /api/traces`

Fetches recent trace summaries from the selected environment.

Query parameters:

- `env`: UI environment name
- `start_time`: ISO timestamp
- `end_time`: ISO timestamp
- `limit`: optional max trace count, capped at 200
- `mins`: fallback lookback window when explicit dates are not supplied

### `GET /api/traces/:traceId/spans`

Fetches the full span payload for a specific trace.

This route is the foundation for the inspector and for summary enrichment.

## UI Guide

### Sidebar

- `Live Traces`: the only functional navigation item today
- `Agent Metrics`: placeholder, not implemented as a separate view
- `Exports`: placeholder, not implemented as a separate view
- `Active System`: environment selector and systems modal launcher

### Top Controls

- agent filter: text filter with wildcard-friendly normalization such as `*hr*`
- `Conversation only`: restricts the list to traces where conversation payloads were detected
- `Only traces with tools`: restricts the list to traces where tool calls were detected
- `15m`, `1h`, `24h`: quick time presets
- start/end fields: explicit time window selection
- `Refresh`: reload summaries
- `Export Traces`: download full JSON bundles for currently loaded traces

### Overview Strip

The summary cards above the trace list show:

- visible trace count
- error trace count
- tool-active trace count
- the most problematic visible agent based on current results

These are derived from the visible result set, not from all traces in the system.

### Trace List

Each trace item attempts to show:

- a usable trace name
- the best available agent name
- badges for `Chat`, `Tools`, `Interrupt`, and `Error`
- local start time and trace ID snippet

### Inspector

Selecting a trace loads the full span payload and renders:

- stats cards for spans and token counts
- trace correlation identifiers
- tool invocation cards
- conversation flow cards
- thought-process signals when such attributes are present
- execution timeline
- execution hierarchy tree
- span explorer with attributes, events, and links
- raw JSON payload

Clickable inspector cards now synchronize with hierarchy, timeline, and explorer rows via `spanId`.

## How Trace Summaries Are Enriched

The observability search API often returns incomplete trace summaries. In practice, agent names and meaningful root span names are not always present in the summary response.

To compensate, the frontend performs background enrichment in [public/app.js](/Users/markusvankempen/projects/wxo-projetcs/WxO-ToolBox/vsc/test_tools/wxo_observability_dashboard/public/app.js):

1. build lightweight UI metadata from the summary payload
2. detect summaries with generic or missing labels
3. fetch full span payloads for a limited number of those traces
4. derive better labels and trace signals from span attributes
5. re-render the filtered list when better metadata becomes available

This is why filtering by agent name can improve a few seconds after the initial list loads.

## Trace Signal Extraction

The dashboard derives higher-level semantics from OTLP payloads. The full extraction logic is implemented in [public/app.js](/Users/markusvankempen/projects/wxo-projetcs/WxO-ToolBox/vsc/test_tools/wxo_observability_dashboard/public/app.js).

Common identifiers and signals:

- `agent.name`
- `agent.id`
- `user.id`
- `session.id`
- `thread.id`
- `global_transaction_id`
- `traceloop.entity.input`
- `traceloop.entity.output`
- `traceloop.entity.name`
- `traceloop.span.kind`
- `gen_ai.prompt.*.content`
- `gen_ai.completion.*.content`
- `gen_ai.system`
- `exception.message`
- `error.message`
- `exception.stacktrace`

See the detailed field mapping in [docs/TRACE_CORRELATION.md](/Users/markusvankempen/projects/wxo-projetcs/WxO-ToolBox/vsc/test_tools/wxo_observability_dashboard/docs/TRACE_CORRELATION.md).

## Export Behavior

`Export Traces` does not export only what is currently selected in the inspector. It exports all traces currently loaded in the trace list state.

For each loaded trace, the client fetches:

- the summary object already loaded from `/api/traces`
- the full payload from `/api/traces/:traceId/spans`

The browser then downloads a single JSON file containing:

```json
[
  {
    "summary": {},
    "payload": {}
  }
]
```

## Known Limitations

- the server reads `.env` from a parent path, not from the dashboard directory
- `Agent Metrics` and `Exports` in the left nav are placeholders
- local systems added in the UI are not persisted
- some traces still resolve to generic labels if the underlying spans also lack identifying attributes
- export runs sequentially in the browser and can be slow for large trace lists
- there is no authentication layer on the local dashboard itself

## Troubleshooting

### `Cannot GET /`

This should already be fixed by serving the `public` directory with an explicit root route. If it reappears, verify you are running the current [server.js](/Users/markusvankempen/projects/wxo-projetcs/WxO-ToolBox/vsc/test_tools/wxo_observability_dashboard/server.js).

### No Environments Appear

Check:

- the server-startup `.env` location is correct
- at least one `*_INSTANCE_URL` and matching API key exist
- the instance URL is valid and reachable

### Agent Filter Shows Poor Results

This usually means trace summaries were incomplete. Wait for enrichment to finish, or narrow the time window so the client can enrich more traces quickly.

### Add System Fails

Check:

- the URL starts with `http://` or `https://`
- the system name is unique
- the backend is running with `express.json()` enabled

### Traces Load But Inspector Is Sparse

Some traces simply do not contain conversation or tool information in the attributes the dashboard currently understands. In those cases the Raw JSON panel is the source of truth.

## Suggested Next Improvements

- implement a real Agent Metrics page using current rollup logic
- add latency-focused cards such as slowest agents and slowest tools
- persist locally added systems to disk
- support click-to-filter directly from overview cards
- optionally make the server read a dashboard-local `.env` first
