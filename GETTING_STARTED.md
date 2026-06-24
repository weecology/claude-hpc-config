# Getting started: Claude on HiPerGator

## 1. Install Claude Code (your laptop)

```bash
npm install -g @anthropic-ai/claude-code
claude login
```

## 2. Clone the repo

```bash
git clone <repo-url> && code <repo-folder>
```

## 3. Submit the tunnel job

From a HiPerGator login node:

```bash
sbatch ~/tunnel.sh
```

`tunnel.sh` runs VS Code Server on HiPerGator for up to 48 h and names the tunnel
`hipergator`. Watch `~/logs/tunnel.out` for the `vscode.dev` URL confirming it's live.

```bash
#!/bin/bash
#SBATCH --job-name=tunnel
#SBATCH --mail-type=END
#SBATCH --mail-user=ben.weinstein@weecology.org
#SBATCH --account=ewhite
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=50GB
#SBATCH --time=48:00:00
#SBATCH --output=/home/b.weinstein/logs/tunnel.out
#SBATCH --error=/home/b.weinstein/logs/tunnel.err

module load vscode
unset VSCODE_IPC_HOOK_CLI
code tunnel --accept-server-license-terms --name hipergator --log info \
  2>~/logs/tunnel.err | tee ~/logs/tunnel.out
```

> Each lab member: update `--mail-user` and log paths before submitting.

## 4. Connect VS Code to the tunnel

Command Palette (`Cmd/Ctrl+Shift+P`) → **Remote-Tunnels: Connect to Tunnel** → `hipergator`.

Activate your environment in the integrated terminal:

```bash
source /blue/ewhite/b.weinstein/src/<project>/.venv/bin/activate
```

## 5. Open Claude Code

Click the Claude icon in the VS Code sidebar, or run `claude` in the terminal.
`CLAUDE.md` loads automatically. Try:

```
Launch a rerun of the last bird-detector training job.
Check whether my overnight runs are still alive.
What did the last five tree jobs peak at for GPU memory?
Compare requested vs actual memory for my last completed tree run — are we over-asking?
Before I submit this job, what resources did similar bird runs actually use?
```

> To reconnect after a tunnel drop: `sbatch ~/tunnel.sh` again.
