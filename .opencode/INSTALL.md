# Installing CHP for OpenCode

## Prerequisites

- [OpenCode](https://opencode.ai) installed
- `bash` and `jq` on PATH (CHP runtime requirements)
- A project with CHP initialized (`docs/chp/laws/` and `.chp/` present)

## Installation

Add CHP to the `plugin` array in your `opencode.json` (global at `~/.config/opencode/opencode.json` or project-level):

```json
{
  "plugin": ["chp@git+https://github.com/code-highway-patrol/chp.git"]
}
```

Restart OpenCode. The plugin auto-installs and:

- Registers CHP skills (audit, investigate, write-laws, review-laws, decompose-laws, status, marketplace) for use via OpenCode's native `skill` tool.
- Gates tool calls through `core/dispatcher.sh pre-tool`. If a law fails (exit ≠ 0), the tool call is aborted and the verifier output is shown to the agent.
- Fires `core/dispatcher.sh post-tool` after each tool runs so post-tool laws can record violations.

## Pinning a version

```json
{
  "plugin": ["chp@git+https://github.com/code-highway-patrol/chp.git#v0.1.7"]
}
```

## Disabling the tool gate

If you only want skills (no enforcement), set the env var before launching OpenCode:

```sh
CHP_OPENCODE_GATE=off opencode
```

The plugin will still register skills but skip both `tool.execute.before` and `tool.execute.after`.

## Troubleshooting

### Plugin not loading
- `opencode run --print-logs "hello" 2>&1 | grep -i chp`
- Verify the plugin line in `opencode.json`.

### Dispatcher not found
The plugin no-ops if `<plugin-root>/core/dispatcher.sh` is missing. Reinstall the plugin if the git fetch didn't include the full repo.

### Tool calls always blocked
Run `chp-status` in the project to see which laws are registered. A pre-tool law's `verify.sh` may be misconfigured — test it with `CHP_TOOL_NAME=write CHP_TOOL_INPUT='{}' bash core/dispatcher.sh pre-tool`.

## Reporting issues

https://github.com/code-highway-patrol/chp/issues
