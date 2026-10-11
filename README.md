# Void Mode

Void Mode is a long-running profile/launcher for [Project UAI](https://github.com/azcvyhnb-cpu/ProjectUAI). It uses UAI's existing provider registry and configuration rather than maintaining a second, incompatible API stack.

## Load

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/azcvyhnb-cpu/Void-Mode/main/main.lua"))()
```

## Setup

1. Run the loader.
2. In **UAI → Providers**, add a provider or choose **Custom endpoint**.
3. Enter the provider's Base URL, API key/auth style, API protocol, and exact model ID. For OpenAI-compatible services, use the base URL expected by that service (often ending in `/v1`).
4. Save the provider and select it as active.

The API key is stored by UAI's configuration on the client. Do not paste keys into this repository or share configuration exports containing credentials.

## What Void Mode changes

- Enables UAI's unlimited top-level turn setting.
- Enables UAI's long request-wait setting.
- Enables unlimited subagent step/time budgets.
- Leaves provider selection, model discovery, tool permissions, context compaction, and Stop under UAI's existing systems.
- Provides `getgenv().VoidMode.openProviders()` to reopen provider settings and `getgenv().VoidMode.disable()` to turn off the profile's unlimited switches.

## Important limits

"Unlimited" here means Void Mode does not add its own request-count or turn-count quota. It cannot remove the API provider's rate limits, billing/credit rules, model context/output limits, Roblox/executor HTTP deadlines, network failures, or platform restrictions. A host may still cap request duration. Use only API endpoints and keys you are authorized to use.

Void Mode currently relies on Project UAI's public loader and public config API. It does not vendor or patch UAI's 67k-line bundled client; keeping the upstream client updated is therefore important.
