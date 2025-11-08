// Jenkinsfile (Declarative Pipeline) - Odoo module deployer
// Assumes: Docker is installed on Jenkins agent and can run `docker` commands,
//          Jenkins has email configured (SMTP) for emailext,
//          A dockerized Odoo container is running and mounts the host modules dir.
pipeline {
  agent any
  parameters {
    string(name: 'REPO_URL', defaultValue: '', description: 'Git repo URL for Odoo module (leave blank to use saved repo)')
    string(name: 'GITHUB_TOKEN', defaultValue: '', description: 'GitHub token (if required for private repos)')
    booleanParam(name: 'MANUAL_ADD_REPO', defaultValue: false, description: 'If true, build will use REPO_URL provided now (manual add)')
    string(name: 'CONTAINER_NAME', defaultValue: 'odoo16', description: 'Name of Odoo docker container')
    string(name: 'MOUNT_PATH', defaultValue: '/mnt/extra-addons', description: 'Host path mounted into container for modules (host-side path)')
    string(name: 'NOTIFY_EMAIL', defaultValue: '', description: 'Email to notify on changes/errors')
  }
  environment {
    WORKDIR = "${env.WORKSPACE}/odoo_modules"
  }
  triggers {
    // Poll SCM every 5 minutes if repositories are defined in pipeline checkout steps.
    pollSCM('H/5 * * * *')
  }
  stages {
    stage('Prepare workspace') {
      steps {
        script {
          echo "Workspace: ${env.WORKSPACE}"
          sh 'rm -rf "${WORKDIR}" || true'
          sh 'mkdir -p "${WORKDIR}"'
        }
      }
    }
    stage('Determine repo(s)') {
      steps {
        script {
          // If MANUAL_ADD_REPO true and REPO_URL provided, we'll use that single repo.
          // Otherwise we expect a file `repos.txt` in the workspace listing repos (one per line).
          repos = []
          if (params.MANUAL_ADD_REPO && params.REPO_URL?.trim()) {
            repos.add(params.REPO_URL.trim())
          } else {
            // load repos.txt if exists
            if (fileExists('repos.txt')) {
              repos = readFile('repos.txt').split("\n").collect { it.trim() }.findAll { it }
            } else {
              echo "No repos.txt found and no manual repo provided - nothing to do."
            }
          }
          // expose repos for later stages
          env.REPOS_JSON = groovy.json.JsonOutput.toJson(repos)
          echo "Repos: ${env.REPOS_JSON}"
        }
      }
    }
    stage('Checkout & Validate modules') {
      when { expression { return env.REPOS_JSON != '[]' } }
      steps {
        script {
          repos = readJSON text: env.REPOS_JSON
          changes_detected = false
          for (r in repos) {
            echo "Processing repo: ${r}"
            // prepare per-repo dir
            dir("${WORKDIR}/${r.tokenize('/').last().replaceAll(/[^A-Za-z0-9_.-]/,'_')}") {
              // clone (use token if provided)
              sh """
                set -e
                rm -rf ./*
                if [ -n "${params.GITHUB_TOKEN}" ]; then
                  git clone https://${params.GITHUB_TOKEN}@${r.replaceFirst(/https:\/\//,'')} . || git clone ${r} .
                else
                  git clone ${r} . || true
                fi
              """
              // basic validation: check for python syntax errors in .py files
              sh """
                set -e || true
                # run a simple Python compile check (skips if no python files)
                if ls *.py >/dev/null 2>&1; then
                  find . -name '*.py' -print0 | xargs -0 -n1 -P2 python -m py_compile || echo "PY_COMPILE_FAIL" > pycheck.fail
                fi
              """
              // compute a git hash to detect changes
              script {
                def curHash = sh(script: "git rev-parse --verify HEAD 2>/dev/null || echo ''", returnStdout: true).trim()
                def hashFile = "${WORKDIR}/.${r.hashCode()}.last"
                def prevHash = ""
                if (fileExists(hashFile)) {
                  prevHash = readFile(hashFile).trim()
                }
                if (curHash && curHash != prevHash) {
                  echo "Change detected in ${r}: ${prevHash} -> ${curHash}"
                  writeFile file: hashFile, text: curHash
                  changes_detected = true
                } else {
                  echo "No change detected in ${r}."
                }
                // fail the pipeline if pycheck.fail exists
                if (fileExists('pycheck.fail')) {
                  error("Python syntax error detected in ${r}. See workspace for details.")
                }
              }
            }
          } // end for repos
          // set env flag for post actions
          env.CHANGES_DETECTED = changes_detected.toString()
        }
      }
    }
    stage('Deploy to Odoo volume & restart') {
      when { expression { return env.CHANGES_DETECTED == 'true' } }
      steps {
        script {
          echo "Changes detected; copying modules into ${params.MOUNT_PATH} and restarting ${params.CONTAINER_NAME}"
          sh """
            set -e
            for repo_dir in ${WORKDIR}/*; do
              if [ -d "$repo_dir" ]; then
                rsync -av --delete "$repo_dir/" "${params.MOUNT_PATH}/$(basename $repo_dir)/"
              fi
            done
            # ensure ownership/permissions - adapt UID/GID if needed
            chown -R 1000:1000 "${params.MOUNT_PATH}" || true
            docker ps -a | grep "${params.CONTAINER_NAME}" >/dev/null 2>&1 || echo "Container not found: ${params.CONTAINER_NAME}"
            docker restart "${params.CONTAINER_NAME}" || true
          """
        }
      }
    }
  } // stages
  post {
    success {
      script {
        if (env.CHANGES_DETECTED == 'true') {
          echo "Changes were deployed."
          if (params.NOTIFY_EMAIL?.trim()) {
            emailext subject: "Odoo CI: Modules updated", body: "Modules were updated and container ${params.CONTAINER_NAME} restarted.", to: params.NOTIFY_EMAIL
          }
        } else {
          echo "No changes on poll - nothing to notify."
        }
      }
    }
    failure {
      script {
        echo "Build failed - sending email"
        if (params.NOTIFY_EMAIL?.trim()) {
          emailext subject: "Odoo CI: Build/Deploy FAILED", body: "Build failed. Check Jenkins job console for details.", to: params.NOTIFY_EMAIL
        }
      }
    }
  }
}
