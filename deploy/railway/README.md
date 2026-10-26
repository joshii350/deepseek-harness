# Deploy the Web UI to Railway

This folder packages `dsh web` as one container for [Railway](https://railway.com), so the harness runs on a server and you use it from a phone browser. Railway builds `deploy/railway/Dockerfile` (selected by the root `railway.json`) from the repository root.

## What runs in the container

- `dsh web` listens on `127.0.0.1:3080`. It advertises `https://$RAILWAY_PUBLIC_DOMAIN/` and trusts that host name.
- Caddy listens on `$PORT`, forwards to `dsh` with the browser's `Host` header unchanged, and marks the login cookie `Secure` because Railway serves the public side over HTTPS.
- On first boot the entrypoint copies `seed.cordis.patch.yml` to `$DSH_HOME/profiles/web/cordis.patch.yml`. The seed registers the `anthropic` provider with its key read from `ANTHROPIC_API_KEY` and makes Claude Sonnet the default model. Later boots leave that file alone, so changes made in **Settings → Models** persist.
- Everything that must survive a redeploy lives on the volume at `/data`: `$DSH_HOME` (`/data/dsh`: sessions, settings, the cookie-signing secret) and `HOME` (`/data/home`, with projects in `/data/home/projects`).

## Set up from a phone

1. In the Railway app, create a project from this GitHub repository and branch.
2. Under the service's **Variables**, add `ANTHROPIC_API_KEY`.
3. Under **Settings → Networking**, generate a public domain. Railway then sets `RAILWAY_PUBLIC_DOMAIN`, which the container requires.
4. Add a **Volume** mounted at `/data`.
5. Deploy. In the deploy logs, find the line `dsh web: https://<domain>/?token=...` and open that link on your phone. It sets a sign-in cookie that lasts 30 days and redirects to the app; afterwards open `https://<domain>/` directly. Add it to the home screen for an app-like launcher.

The token in that log line grants full access to the agent and its shell, so do not share it. Every restart prints a new token, but cookies from earlier links keep working while the volume keeps the signing secret.

## Switch to an open-weight model later

In **Settings → Models**, choose **Add model provider → Custom model API**, enter the endpoint's base URL (for example a vLLM or Ollama server's `/v1`), pick **OpenAI Chat Completions**, add the model id, and select it in the composer's model picker. No rebuild is needed. The [model configuration guide](../../docs/user/guide/providers.md) covers the fields.

## Command sandbox

The agent's shell commands run under the harness sandbox, which fails closed when no runner works. The image ships bubblewrap and the Landlock launcher; bubblewrap usually cannot create namespaces inside a container, and the harness then uses Landlock, which needs a host kernel that allows it. If commands fail with `SANDBOX_UNAVAILABLE`, the host blocks both runners.
