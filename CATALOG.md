# Catalog

Everything install.sh sets up, what it's for, and what it costs. "Free" means
the tool runs without an account or with a free one.

## Plugins

| Plugin                           | What it does                                                     | Why it's in the setup                                            | Paid account?                                   |
| -------------------------------- | ---------------------------------------------------------------- | ---------------------------------------------------------------- | ----------------------------------------------- |
| context7                         | Pulls current library docs into context                          | Stops Claude coding against an API version that no longer exists | No (free login, optional key raises limits)     |
| playwright                       | Drives a real browser from Claude                                | Testing web apps, reading pages that need JS                     | No                                              |
| serena                           | Symbol-level code search and edits through language servers      | Faster, more exact navigation in big repos                       | No (needs `uv`)                                 |
| vercel                           | Deploys, logs, env vars, plus about 40 Vercel and Next.js skills | Shipping frontends without leaving Claude                        | No (Hobby plan is free)                         |
| railway                          | Deploys and manages Railway services                             | Backends, databases, workers                                     | Yes after the trial credit                      |
| expo                             | Expo and EAS skills plus the Expo MCP                            | React Native apps, builds, store submission                      | No for dev builds, paid EAS plans for heavy use |
| security-guidance                | Warns on risky code patterns as Claude writes them               | Catches injection, unsafe eval, leaked secrets early             | No                                              |
| hookify                          | Turns "stop doing X" into a hook from chat                       | Makes a correction stick instead of repeating it                 | No                                              |
| claude-md-management             | Audits and tightens CLAUDE.md files                              | Keeps instructions short and current                             | No                                              |
| typescript-lsp                   | TypeScript language server for Claude                            | Real type errors and go-to-definition                            | No                                              |
| pyright-lsp                      | Python language server                                           | Same for Python                                                  | No                                              |
| swift-lsp                        | Swift language server                                            | iOS and macOS work                                               | No (needs Xcode)                                |
| session-report                   | Summarizes what a session did                                    | Handy for standups and PR descriptions                           | No                                              |
| feature-dev                      | Explore, architect, review agents for a feature                  | Structured flow for anything bigger than a bug fix               | No                                              |
| frontend-design                  | UI design guidance for generated frontends                       | Gets past the generic AI look                                    | No                                              |
| humanizer                        | Rewrites text to drop AI-writing tells                           | Docs, posts, anything people will read                           | No                                              |
| runpod (opt-in, `--with-runpod`) | Manage RunPod GPU pods and serverless                            | Training and running models on rented GPUs                       | Yes, pay as you go                              |

## MCP servers

| Server              | Installed as                                                     | What it does                                               | Needs                                         | Paid account?                         |
| ------------------- | ---------------------------------------------------------------- | ---------------------------------------------------------- | --------------------------------------------- | ------------------------------------- |
| sequential-thinking | `npx @modelcontextprotocol/server-sequential-thinking`           | Scratchpad for multi-step reasoning                        | Nothing                                       | No                                    |
| filesystem          | `npx @modelcontextprotocol/server-filesystem ~/code ~/Downloads` | File access scoped to those two folders                    | Nothing                                       | No                                    |
| fetch               | `uvx mcp-server-fetch`                                           | Fetches a URL as markdown                                  | Nothing                                       | No                                    |
| time                | `uvx mcp-server-time`                                            | Current time and timezone math                             | Nothing                                       | No                                    |
| git                 | `uvx mcp-server-git`                                             | Git operations as structured calls                         | Nothing                                       | No                                    |
| chrome-devtools     | `npx chrome-devtools-mcp@latest --headless`                      | Headless Chrome: screenshots, console, network, Lighthouse | Chrome installed                              | No                                    |
| macos-automator     | `npx @steipete/macos-automator-mcp`                              | Runs AppleScript and JXA to drive Mac apps                 | Automation permission on first use            | No                                    |
| chart               | `npx @antv/mcp-server-chart`                                     | Renders charts from data                                   | Nothing                                       | No                                    |
| blender             | `uvx blender-mcp`                                                | Builds and edits 3D scenes in Blender                      | Blender plus the blender-mcp add-on           | No                                    |
| peekaboo            | `peekaboo mcp serve` (release download, or brew if you have it)  | Screenshots and clicks in any Mac app                      | Screen Recording and Accessibility permission | No                                    |
| watch-skill         | `uv tool install watch-skill`, then `watch-skill serve`          | Watches and indexes videos, answers questions about them   | Optional vision API key or local Ollama       | No (a vision provider can cost money) |
| supabase            | remote `https://mcp.supabase.com/mcp`                            | Query and manage Supabase projects                         | Supabase login via `/mcp`                     | No (free tier)                        |
| github              | `npx @modelcontextprotocol/server-github`                        | Issues, PRs, code search across GitHub                     | `gh` signed in (reads its token at startup)   | No                                    |
| todoist (optional)  | `npx @greirson/mcp-todoist`                                      | Todoist tasks from Claude                                  | `TODOIST_API_TOKEN`                           | No (free plan works)                  |

## Connectors (claude.ai and the desktop app)

These are optional extras, and setup doesn't need any of them. GitHub isn't one:
the installer signs you in to GitHub itself. Turn the ones you want on at
claude.ai, Settings, Connectors. They then show up in Claude Code too when you're signed in with the
same account.

| Connector       | What it does                        | Why                                        | Paid account?                                 |
| --------------- | ----------------------------------- | ------------------------------------------ | --------------------------------------------- |
| Gmail           | Read, search and draft email        | Email chores without opening the inbox     | Your Claude account (check which connectors your plan includes) |
| Google Calendar | Read and create events              | Scheduling, "what's my week"               | Same                                          |
| Google Drive    | Search and read Docs, Sheets, files | Pulling class or project docs into context | Same                                          |
| Slack           | Read and post in Slack              | Team chat without switching apps           | Same, plus a Slack workspace                  |
| Figma           | Read designs and frames             | Building UI from a real design             | Same, Figma free plan works                   |
| Claude Docs     | Living docs Claude writes and edits | Shareable plans and write-ups              | Same                                          |
| Hugging Face    | Search models, datasets, papers     | ML work                                    | Same                                          |
| Higgsfield      | AI image and video generation       | Visuals for demos and posts                | Same, plus Higgsfield credits (paid)          |

## Logins

What's left after install.sh, in the order worth doing it:

1. **GitHub CLI**: `gh auth login --web`. Needed to push your own code and for the GitHub MCP. It shows a code and opens a browser page, which may land behind the Claude window.
2. **GitHub MCP**: after step 1, run `./install.sh` again. It adds the server using your gh sign-in, so there's no token to make.
3. **Plugin and remote MCP sign-ins**: in Claude Code run `/mcp`, then sign in to context7, vercel, railway, expo and supabase (and runpod if you opted in). Each one opens a browser tab.
4. **macOS permissions**: the first time peekaboo or macos-automator runs, approve Screen Recording, Accessibility and Automation in System Settings, Privacy and Security.
5. **Connectors**: claude.ai, Settings, Connectors, then connect the ones above you want.
6. **Optional keys**: `TODOIST_API_TOKEN` (todoist.com, Settings, Integrations, Developer), and a vision key for watch-skill (`watch-skill setup` walks you through it).
