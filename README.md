# Void Mode — Dual AI Collaboration

Void Mode is a standalone Roblox Lua UI for configuring **two OpenAI-compatible Chat Completions models** and having them collaborate on a task.

## Load

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/azcvyhnb-cpu/Void-Mode/main/main.lua"))()
```

## Where is the UI?

After running the loader, a window named **VOID MODE / DUAL AI** should appear. If it does not, check the executor console for an HTTP, compile, or GUI-parenting error. Re-run the loader to replace an already-open Void Mode window.

## Configure the two models

Fill in each model's separate:

- **Base URL** — for example `https://ai.thirx.com/v1`, if that provider documents this as its OpenAI-compatible base URL.
- **API key** — optional only if the endpoint does not require authentication.
- **Model ID** — the exact identifier given by the provider.

Both endpoints must support OpenAI-compatible `POST /chat/completions` requests and return `choices[1].message.content`. A provider that uses Anthropic Messages or a proprietary schema needs an adapter before it can work here.

## How collaboration works

Click **RUN COLLABORATION**. Void Mode runs three sequential API calls:

1. **Model A plans** the task and proposes a solution.
2. **Model B reviews** that plan, finds weaknesses, and contributes improvements.
3. **Model A synthesizes** both outputs into the final answer.

This is actual cross-model handoff, not just alternating model selection. It is sequential rather than parallel so each model can use the previous model's output. One collaboration uses three API requests; provider limits and latency still apply.

## Credential and runtime notes

- API keys are kept in UI fields in memory for the current session and are not written to this repository or deliberately persisted by Void Mode.
- Use only API endpoints and keys you are authorized to use.
- "Unlimited" cannot override provider rate limits, credits/billing, context/output limits, executor timeouts, HTTP failures, or network/platform restrictions.
- The script requires an executor that can make HTTP POST requests. If no executor request function exists, it falls back to Roblox `HttpService:RequestAsync`, which may require HTTP requests to be enabled by the host.
- This is a standalone UI; it does not add a new tab inside Project UAI's existing interface.
