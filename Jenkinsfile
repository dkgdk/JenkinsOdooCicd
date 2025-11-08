pipeline {
  agent any

  environment {
    REPO_URL        = 'https://github.com/dkgdk/web_monitor.git'    // your module repo
    GITHUB_TOKEN_ID = 'github-token'                                // Jenkins secret text ID
    CONTAINER_NAME  = 'odoo'                                        // your Odoo container name
    MOUNT_PATH      = '/home/ubuntu/odoo_modules'                   // host path mounted to Odoo container
    NOTIFY_EMAIL    = 'durgeshgupt.dg@gmail.com'                    // notification email
    WORKDIR         = "${env.WORKSPACE}/odoo_modules"               // Jenkins workspace dir for repo
  }

  stages {

    stage('Prepare Workspace') {
      steps {
        sh 'mkdir -p "$WORKDIR"'
      }
    }

    stage('Clone or Update Module') {
      steps {
        script {
          withCredentials([string(credentialsId: env.GITHUB_TOKEN_ID, variable: 'GITHUB_TOKEN')]) {
            if (fileExists("${env.WORKDIR}/.git")) {
              echo "Repository already exists. Pulling latest changes..."
              dir(env.WORKDIR) {
                sh 'git reset --hard'
                sh 'git pull'
              }
            } else {
              echo "Cloning repository..."
              sh """
                rm -rf "${env.WORKDIR}"
                git clone https://${GITHUB_TOKEN}@${env.REPO_URL.replaceFirst(/https:\\/\\//,'')} "${env.WORKDIR}"
              """
            }
          }
        }
      }
    }

    stage('Deploy to Odoo') {
      steps {
        sh """
          echo "Copying module files to Odoo addons directory..."
          rm -rf "${env.MOUNT_PATH}/*"
          cp -r "${env.WORKDIR}/." "${env.MOUNT_PATH}/"
          echo "Restarting Odoo container..."
          docker restart "${env.CONTAINER_NAME}"
        """
      }
    }
  }

  post {
    success {
      emailext subject: "✅ Odoo CI/CD Success",
               body: "The module from ${env.REPO_URL} has been deployed successfully and container ${env.CONTAINER_NAME} restarted.",
               to: "${env.NOTIFY_EMAIL}"
    }
    failure {
      emailext subject: "❌ Odoo CI/CD Failed",
               body: "The Jenkins pipeline failed. Please check the logs for details.",
               to: "${env.NOTIFY_EMAIL}"
    }
  }
}
