# Jenkins Odoo CI/CD (Pipeline-as-Code)

## What this project provides
- `Jenkinsfile` - Declarative pipeline that:
  - Accepts repo URL and GitHub token as parameters (or reads `repos.txt`)
  - Polls every 5 minutes for changes (SCM polling)
  - Clones module repos, runs a basic python syntax check, and if changes are detected:
    - rsyncs the module into the host `MOUNT_PATH` (the volume path mounted in your Odoo container)
    - restarts the Odoo docker container
  - Sends notification emails using the `emailext` plugin when changes occur or on failures.
- `module_update.sh` - helper script for manual testing / one-off deploys.
- `repos.txt` - optional file listing module repositories (one per line)

## Assumptions & prerequisites
1. Jenkins agent has Docker CLI permissions and can run `docker restart` on the Odoo container.
2. The host path (e.g. `/mnt/extra-addons`) is mounted as a volume in your Odoo container.
3. Jenkins has the Email Extension plugin (`emailext`) configured (SMTP). Configure SMTP in Jenkins global settings.
4. Python is available in the Jenkins agent for basic syntax checking.

## Quick setup
1. Put `Jenkinsfile` in a pipeline job (Pipeline script from SCM or Multibranch). Add `repos.txt` (one repo per line) in the workspace if you want automatic repos.
2. Or create a param-based job and set `MANUAL_ADD_REPO` true and provide `REPO_URL` when building.
3. Configure `CONTAINER_NAME`, `MOUNT_PATH`, and `NOTIFY_EMAIL` parameters as needed.
4. Ensure the Jenkins user can write to `MOUNT_PATH` (or adjust chown in the Jenkinsfile).

## Using the helper script
```bash
chmod +x module_update.sh
./module_update.sh https://github.com/your/module.git /mnt/extra-addons odoo16 YOUR_GITHUB_TOKEN
```

## Note
- The pipeline uses a simple git commit hash comparison persisted in workspace hidden files to detect changes between runs.
- You may adapt validation to run unit tests, flake8, or odoo-specific checks.
