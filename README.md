# agent-meter-cli

The part of agent-meter that runs on your machine, open source so you can read exactly what it does. It reports to an agent-meter server your team runs. The server and the desktop app are a separate, commercial product.

## What is here

- `statusline.sh`: a Claude Code status line command. It reads the JSON Claude Code gives it, sends **only** the session id and the `rate_limits` object (your 5-hour and weekly quota use) to your server, at most once a minute, in the background, and prints a short status line. Local paths and everything else in the input never leave your machine. Needs `curl` and `jq`.
- The settings that connect Claude Code and Codex CLI usage reporting (below).

## Connect Claude Code usage

Each person opens **Machines** in their agent-meter server, names a computer and clicks **Connect**, which shows a token once. Merge this into the `env` object of `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_LOGS_EXPORTER": "otlp",
    "OTEL_EXPORTER_OTLP_LOGS_PROTOCOL": "http/json",
    "OTEL_EXPORTER_OTLP_LOGS_ENDPOINT": "https://meter.example.com/api/otel/v1/logs",
    "OTEL_EXPORTER_OTLP_LOGS_HEADERS": "Authorization=Bearer <token>"
  }
}
```

Codex CLI, in `~/.codex/config.toml`:

```toml
[otel]
log_user_prompt = false
exporter = { otlp-http = { endpoint = "https://meter.example.com/api/otel/v1/logs", protocol = "json", headers = { "Authorization" = "Bearer <token>" } } }
```

Restart the agent afterwards. These use the agents' own OpenTelemetry export; this repository adds no client.

## Quota bars (optional)

Copy `statusline.sh` to `~/.claude/agent-meter-statusline.sh`, run `chmod +x` on it, and merge into `~/.claude/settings.json`:

```json
{
  "env": { "AGENT_METER_URL": "https://meter.example.com", "AGENT_METER_TOKEN": "<token>" },
  "statusLine": { "type": "command", "command": "~/.claude/agent-meter-statusline.sh" }
}
```

To keep a status line you already have, set `AGENT_METER_WRAP` in `env` to its command; the script passes the input to it and prints its output.

## What leaves your machine

- Usage telemetry: token counts, model, timestamp, agent, session id, machine name and the agent account's identifier and email. Never prompts, responses, file paths or credentials (`log_user_prompt = false` for Codex).
- Quota: the session id, and the percentages and reset times in `rate_limits`.

Both go only to the server address you configure.

## License

MIT. See `LICENSE`.
