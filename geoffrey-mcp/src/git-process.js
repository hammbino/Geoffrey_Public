import { spawnSync } from "node:child_process";

// Per-process settings only: use the same GitHub sign-in as the app, instead
// of inherited osxkeychain helpers whose bundled signature can trigger UI.
// Never write tokens or replace the owner's global Git configuration.
export function spawnGit(parameters, options = {}) {
  return spawnSync(process.env.GEOFFREY_GIT_BIN || "git", [
    "-c", "credential.helper=",
    "-c", "credential.https://github.com.helper=!gh auth git-credential",
    ...parameters,
  ], {
    ...options,
    env: {
      ...process.env, ...options.env,
      GH_PROMPT_DISABLED: "1", GIT_TERMINAL_PROMPT: "0",
      GIT_ASKPASS: "/usr/bin/false", SSH_ASKPASS: "/usr/bin/false",
      GIT_SSH_COMMAND: "ssh -oBatchMode=yes -oStrictHostKeyChecking=yes",
    },
  });
}
