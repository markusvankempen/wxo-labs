# Download file — HTTPS anchors + optional `data:` (E2E)

**Package folder:** `download_file_and_stream_e2e_test` — separate from the **link-only** example in **`download_link_agent_e2e_test`** (leave that package as-is: short label + HTTPS `href`, no inlined bytes).

Python tool **`get_pdf_download_with_bytes`** defaults to a **short** answer: **`PRIMARY`** = HTTPS `<a>` + **Plain URL:** for the [**PDF.js demo**](https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf) (no mega-base64 — avoids **Groq** / other LLM **“reduce the length of messages”** failures when inlined **`data:`** would add ~1–2 MiB of ASCII to `messages`).

**Optional inlined bytes:** when the tool host sets **`PDF_DOWNLOAD_INCLUDE_DATA_URI=1`**, the tool **HTTPS-fetches** bytes (bounded; chunked **`read()` loop** via **`_fetch_pdf`**) and appends **`SECONDARY`** = **`data:application/pdf;base64,…`**. Prefer keeping that **off** unless you need the RFC 2397 path and accept provider limits.

Per IBM ADK, tools return **`str`** — [Authoring Python-Based Tools](https://developer.watson-orchestrate.ibm.com/tools/create_tool). For HTTPS-only demos with no fetching, sibling [`../download_link_agent_e2e_test`](../download_link_agent_e2e_test/) is even smaller.

---

## Run everything from this directory

Single entry point (defaults: **local urllib demo → deploy WxO → orchestrate chat E2E**):

```bash
cd download_file_and_stream_e2e_test
chmod +x deploy_to_wxo.sh run_e2e_test.sh run_all.sh
./run_all.sh
```

Other modes: **`./run_all.sh --no-demo`** (skip network demo), **`./run_all.sh --deploy-only`** (deploy only; no local demo), **`./run_all.sh --e2e-only`** (E2E only; no local demo), **`./run_all.sh --help`**.

---

## Streaming example (`examples/` — local)

| Path | Role |
|------|------|
| [`examples/streaming_pdf_fetch_demo.py`](examples/streaming_pdf_fetch_demo.py) | Plain **urllib** chunked fetch (**no WxO SDK** required) — verifies the same bounded streaming pattern offline |

Run from this directory:

```bash
python3 examples/streaming_pdf_fetch_demo.py
```

(Optional: `STREAM_DEMO_URL`, `STREAM_DEMO_MAX_BYTES`.)

---

## IBM watsonx Orchestrate documentation (relevant)

| Topic | Link |
|------|------|
| Tools overview (Python, OpenAPI, flows, …) | [Tools overview](https://developer.watson-orchestrate.ibm.com/tools/overview) |
| Authoring Python tools (return type `str`, `@tool`, import) | [Authoring Python-Based Tools](https://developer.watson-orchestrate.ibm.com/tools/create_tool) |
| Managing tools (CLI) | [Managing tools](https://developer.watson-orchestrate.ibm.com/tools/manage_tool) |
| Full doc index (for agents) | [`llms.txt`](https://developer.watson-orchestrate.ibm.com/llms.txt) |
| Agent Connect (external service) tool response shape — `step_details.content` as **string** | [Working with tools — Tool Responses](https://connect.watson-orchestrate.ibm.com/tools/implementation) |

---

## Behaviour

1. **PRIMARY (always)** — From **`PDF_SOURCE_URL`**, emits HTTPS `<a id="…-https">` + **Plain URL:** (no oversized tool string; safe for Groq-sized contexts).
2. **SECONDARY (opt-in)** — If **`PDF_DOWNLOAD_INCLUDE_DATA_URI=1`**: chunked **`urllib`** read of **`PDF_SOURCE_URL`**, guarded by **`PDF_DOWNLOAD_MAX_BYTES`** (default `1048576`), then **`data:application/pdf;base64,…`** `<a>`.
3. **Groq note:** inlined **`data:`** + assistant turns can exceed **max `messages`/completion** length — defaults avoid fetch + SECONDARY entirely.

**Portal reality (`data:` URLs):** many WxO skins show huge **`href`s** as wrapped plain text. Prefer **PRIMARY** HTTPS.

**“Streaming” (clarified):** **`_fetch_pdf`** reads the HTTP body in chunks only when SECONDARY mode is enabled. There is no token streaming API for arbitrary Python tools in WxO beyond normal chat completion streams.

---

## Contents

| Path | Role |
|------|------|
| [`tools/get_pdf_download_with_bytes.py`](tools/get_pdf_download_with_bytes.py) | `get_pdf_download_with_bytes` — HTTPS anchors; optional chunked fetch + `data:` SECONDARY |
| [`agents/pdf_bytes_download_agent.yaml`](agents/pdf_bytes_download_agent.yaml) | Agent **`pdf_bytes_download_agent`** |
| [`examples/streaming_pdf_fetch_demo.py`](examples/streaming_pdf_fetch_demo.py) | **Local** chunked fetch demo (**no ADK** — see [Streaming example](#streaming-example-examples--local) above) |
| [`run_all.sh`](run_all.sh) | **Recommended:** chained local demo → **deploy_to_wxo.sh** → **run_e2e_test.sh** |
| [`deploy_to_wxo.sh`](deploy_to_wxo.sh) | Import tool → agent → deploy |
| [`run_e2e_test.sh`](run_e2e_test.sh) | `orchestrate chat ask` smoke (+ HTML excerpt) |

---

## Environment overrides

| Variable | Meaning |
|----------|---------|
| `PDF_DOWNLOAD_INCLUDE_DATA_URI` | `1`/`true` — fetch PDF and append SECONDARY **`data:`** `<a>`; **omit or `0`** (default) — PRIMARY HTTPS only (**recommended for Groq**) |
| `PDF_SOURCE_URL` | HTTPS PDF URL (**PRIMARY always** uses this label; fetched only when `PDF_DOWNLOAD_INCLUDE_DATA_URI` is on) |
| `PDF_DOWNLOAD_MAX_BYTES` | Max fetch bytes when SECONDARY enabled (default `1048576`) |
| `PDF_DOWNLOAD_FILENAME` | `download=` on SECONDARY `<a>` (default `compressed.tracemonkey-pldi-09.pdf`) |
| `PDF_DOWNLOAD_LABEL` | SECONDARY `<a>` text (default `Public sample PDF`) |
| `PDF_DOWNLOAD_LINK_ID` | HTML id stem (default `pdfDataDownload`) |

Set these in the **WxO tool host environment** before deploy if your tenant allows configuring env per tool/context (same pattern as other tests in this repo).

---

## Deploy & E2E

Use **`./run_all.sh`** (see [Run everything from this directory](#run-everything-from-this-directory)) or run steps yourself:

```bash
cd download_file_and_stream_e2e_test
chmod +x deploy_to_wxo.sh run_e2e_test.sh run_all.sh
./deploy_to_wxo.sh && ./run_e2e_test.sh
```

### How E2E works

1. **Deploy** — **`pdf_bytes_download_agent`** + **`get_pdf_download_with_bytes`**.
2. **Automated smoke** — **`./run_e2e_test.sh`** runs  
   **`echo "q" | orchestrate chat ask -n pdf_bytes_download_agent "…"`**  
   Expects **HTTPS** / **Plain URL:** / **`Same PDF via HTTPS`** (default tool output), **`data:`**/`base64`, or (if truncated) **`get_pdf_download_with_bytes`**. With **`PDF_DOWNLOAD_INCLUDE_DATA_URI=0`** you will **not** see **`base64`** in output.
3. **Manual (`orchestrate chat ask -n`) — inspect HTML**:

   ```bash
   orchestrate chat ask -n pdf_bytes_download_agent "Give me the HTTPS Mozilla PDF.js sample link."
   ```

   You should see **PRIMARY** **`https://mozilla.github.io/pdf.js/…`** and **Plain URL:** (no huge **`base64`** block unless SECONDARY embedding is enabled on the deployed tool).

   Type **`q`** to exit chat.

Use **`E2E_SHOW_HTML=0 ./run_e2e_test.sh`** to skip the excerpt.

---

## Author

**Author:** Markus van Kempen | [mvk@ca.ibm.com](mailto:mvk@ca.ibm.com) | [markus.van.kempen@gmail.com](mailto:markus.van.kempen@gmail.com)  
[Research | Floor 7½ 🏢🤏](https://pages.github.ibm.com/mvankempen/homepage/)  
*No bug too small, no syntax too weird.*
