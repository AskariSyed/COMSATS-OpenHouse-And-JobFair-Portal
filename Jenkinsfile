pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    parameters {
        string(name: 'BACKEND_URL', defaultValue: 'http://127.0.0.1:5158', description: 'Backend URL used when building the portals.')
        string(name: 'DEPLOY_ROOT', defaultValue: '/var/www', description: 'Local deployment root on the Jenkins agent or target server.')
    }

    environment {
        VITE_FIREBASE_API_KEY = credentials('jobfair-firebase-api-key')
        VITE_FIREBASE_AUTH_DOMAIN = credentials('jobfair-firebase-auth-domain')
        VITE_FIREBASE_PROJECT_ID = credentials('jobfair-firebase-project-id')
        VITE_FIREBASE_STORAGE_BUCKET = credentials('jobfair-firebase-storage-bucket')
        VITE_FIREBASE_MESSAGING_SENDER_ID = credentials('jobfair-firebase-messaging-sender-id')
        VITE_FIREBASE_APP_ID = credentials('jobfair-firebase-app-id')
        VITE_FIREBASE_VAPID_KEY = credentials('jobfair-firebase-vapid-key')
        FIREBASE_CONFIG_JSON = credentials('jobfair-firebase-config-json')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/AskariSyed/StudentJobFairPortal.git',
                        credentialsId: 'github-pat'
                    ]]
                ])
            }
        }

        stage('Detect Changes') {
            steps {
                script {
                    def changedFiles = sh(script: 'git diff --name-only HEAD~1 HEAD 2>/dev/null || true', returnStdout: true).trim()

                    if (!changedFiles) {
                        env.ADMIN_CHANGED = 'true'
                        env.COMPANY_CHANGED = 'true'
                        env.LANDING_CHANGED = 'true'
                        env.STUDENT_CHANGED = 'true'
                        env.BACKEND_CHANGED = 'true'
                    } else {
                        def fileList = changedFiles.readLines()
                        env.ADMIN_CHANGED = fileList.any { it.startsWith('admin-portal/') } ? 'true' : 'false'
                        env.COMPANY_CHANGED = fileList.any { it.startsWith('company-portal/') } ? 'true' : 'false'
                        env.LANDING_CHANGED = fileList.any { it.startsWith('landing-page/') } ? 'true' : 'false'
                        env.STUDENT_CHANGED = fileList.any { it.startsWith('student-portal/') } ? 'true' : 'false'
                        env.BACKEND_CHANGED = fileList.any { it.startsWith('Backend/') } ? 'true' : 'false'
                    }

                    echo "Admin:   ${env.ADMIN_CHANGED}"
                    echo "Company: ${env.COMPANY_CHANGED}"
                    echo "Landing: ${env.LANDING_CHANGED}"
                    echo "Student: ${env.STUDENT_CHANGED}"
                    echo "Backend: ${env.BACKEND_CHANGED}"
                }
            }
        }

        stage('Validate Secrets') {
            steps {
                sh '''#!/usr/bin/env bash
set -euo pipefail

fail=false

for var in VITE_FIREBASE_API_KEY VITE_FIREBASE_AUTH_DOMAIN VITE_FIREBASE_PROJECT_ID VITE_FIREBASE_STORAGE_BUCKET VITE_FIREBASE_MESSAGING_SENDER_ID VITE_FIREBASE_APP_ID VITE_FIREBASE_VAPID_KEY FIREBASE_CONFIG_JSON; do
  if [ -z "${!var:-}" ]; then
    echo "ERROR: $var is missing."
    fail=true
  fi
done

if ! printf '%s' "${VITE_FIREBASE_API_KEY}" | grep -Eq '^AIza[0-9A-Za-z_-]{20,}$'; then
  echo 'ERROR: VITE_FIREBASE_API_KEY format looks invalid.'
  fail=true
fi

if ! printf '%s' "${VITE_FIREBASE_APP_ID}" | grep -Eq '^[0-9]+:[0-9]+:web:[0-9a-f]+$'; then
  echo 'ERROR: VITE_FIREBASE_APP_ID format looks invalid.'
  fail=true
fi

if ! printf '%s' "${VITE_FIREBASE_VAPID_KEY}" | tr -d '\r\n\t ' | grep -Eq '^[A-Za-z0-9_-]{80,}$'; then
  echo 'ERROR: VITE_FIREBASE_VAPID_KEY format looks invalid.'
  fail=true
fi

if [ "$fail" = true ]; then
  exit 1
fi

echo 'Secret validation passed.'
'''
            }
        }

        stage('Build Admin Portal') {
            when {
                expression { env.ADMIN_CHANGED == 'true' }
            }
            steps {
                dir('admin-portal') {
                    withEnv(["VITE_BACKEND_URL=${params.BACKEND_URL}", "VITE_API_BASE_URL=${params.BACKEND_URL}"]) {
                        sh 'npm ci'
                        sh 'npm run build'
                    }
                }
            }
        }

        stage('Build Company Portal') {
            when {
                expression { env.COMPANY_CHANGED == 'true' }
            }
            steps {
                dir('company-portal') {
                    withEnv(["VITE_SERVER_URL=${params.BACKEND_URL}"]) {
                        sh 'npm ci'
                        sh 'npm run build'
                    }
                }
            }
        }

        stage('Build Landing Page') {
            when {
                expression { env.LANDING_CHANGED == 'true' }
            }
            steps {
                dir('landing-page') {
                    sh 'npm ci'
                    sh 'npm run build'
                }
            }
        }

        stage('Build Student Portal') {
            when {
                expression { env.STUDENT_CHANGED == 'true' }
            }
            steps {
                dir('student-portal') {
                    sh 'flutter pub get'
                    sh "flutter build web --release --dart-define=BACKEND_BASE_URL=${params.BACKEND_URL} --dart-define=APP_ENV=production"
                    sh "flutter build apk --release --dart-define=BACKEND_BASE_URL=${params.BACKEND_URL} --dart-define=APP_ENV=production"
                }
            }
        }

        stage('Build Backend') {
            when {
                expression { env.BACKEND_CHANGED == 'true' }
            }
            steps {
                dir('Backend') {
                    sh 'dotnet restore'
                    sh 'dotnet build --configuration Release'
                    sh 'dotnet publish --configuration Release --output publish'
                }
            }
        }

        stage('Package Artifacts') {
            steps {
                sh '''#!/usr/bin/env bash
set -euo pipefail

mkdir -p .deploy-artifacts

if [ "${ADMIN_CHANGED}" = "true" ] && [ -d admin-portal/dist ]; then
  tar -czf .deploy-artifacts/admin.tar.gz -C admin-portal/dist .
fi

if [ "${COMPANY_CHANGED}" = "true" ] && [ -d company-portal/dist ]; then
  tar -czf .deploy-artifacts/company.tar.gz -C company-portal/dist .
fi

if [ "${LANDING_CHANGED}" = "true" ] && [ -d landing-page/dist ]; then
  tar -czf .deploy-artifacts/landing.tar.gz -C landing-page/dist .
fi

if [ "${STUDENT_CHANGED}" = "true" ] && [ -d student-portal/build/web ]; then
  tar -czf .deploy-artifacts/student.tar.gz -C student-portal/build/web .
  cp student-portal/build/app/outputs/flutter-apk/app-release.apk .deploy-artifacts/student-portal.apk
fi

if [ "${BACKEND_CHANGED}" = "true" ] && [ -d Backend/publish ]; then
  tar -czf .deploy-artifacts/backend.tar.gz -C Backend/publish .
fi

ls -lh .deploy-artifacts || true
'''
            }
        }

        stage('Deploy Locally') {
            steps {
                sh '''#!/usr/bin/env bash
set -euo pipefail

sudo mkdir -p "${DEPLOY_ROOT}/admin" "${DEPLOY_ROOT}/company" "${DEPLOY_ROOT}/student" "${DEPLOY_ROOT}/student/downloads" "${DEPLOY_ROOT}/jfair" "${DEPLOY_ROOT}/api" "${DEPLOY_ROOT}/uploads" "${DEPLOY_ROOT}/api/config"
sudo apt-get update -y
sudo apt-get install -y tar gzip unzip webp

if [ "${ADMIN_CHANGED}" = "true" ] && [ -f .deploy-artifacts/admin.tar.gz ]; then
  sudo rm -rf "${DEPLOY_ROOT}/admin"/*
  sudo tar -xzf .deploy-artifacts/admin.tar.gz -C "${DEPLOY_ROOT}/admin"
  sudo chown -R www-data:www-data "${DEPLOY_ROOT}/admin"
fi

if [ "${COMPANY_CHANGED}" = "true" ] && [ -f .deploy-artifacts/company.tar.gz ]; then
  sudo rm -rf "${DEPLOY_ROOT}/company"/*
  sudo tar -xzf .deploy-artifacts/company.tar.gz -C "${DEPLOY_ROOT}/company"
  sudo chown -R www-data:www-data "${DEPLOY_ROOT}/company"
fi

if [ "${LANDING_CHANGED}" = "true" ] && [ -f .deploy-artifacts/landing.tar.gz ]; then
  sudo rm -rf "${DEPLOY_ROOT}/jfair"/*
  sudo tar -xzf .deploy-artifacts/landing.tar.gz -C "${DEPLOY_ROOT}/jfair"
  sudo chown -R www-data:www-data "${DEPLOY_ROOT}/jfair"
fi

if [ "${STUDENT_CHANGED}" = "true" ] && [ -f .deploy-artifacts/student.tar.gz ]; then
  sudo rm -rf "${DEPLOY_ROOT}/student"/*
  sudo tar -xzf .deploy-artifacts/student.tar.gz -C "${DEPLOY_ROOT}/student"
  sudo cp .deploy-artifacts/student-portal.apk "${DEPLOY_ROOT}/student/downloads/student-portal.apk"

  if command -v cwebp >/dev/null 2>&1; then
    for png in "${DEPLOY_ROOT}/student"/icons/*.png; do
      [ -e "$png" ] || continue
      sudo cwebp -q 85 "$png" -o "${png%.png}.webp" >/dev/null 2>&1 || true
    done
  fi

    find "${DEPLOY_ROOT}/student" -type f | while IFS= read -r file; do
        case "$file" in
            *.js|*.mjs|*.css|*.json|*.wasm)
                sudo gzip -k -9 -f "$file"
                ;;
        esac
    done
  sudo find "${DEPLOY_ROOT}/student" -name '*.map' -delete
  sudo chown -R www-data:www-data "${DEPLOY_ROOT}/student"
fi

if [ "${BACKEND_CHANGED}" = "true" ] && [ -f .deploy-artifacts/backend.tar.gz ]; then
  sudo rm -rf "${DEPLOY_ROOT}/api"/*
  sudo tar -xzf .deploy-artifacts/backend.tar.gz -C "${DEPLOY_ROOT}/api"

  printf '%s\n' "${FIREBASE_CONFIG_JSON}" | sudo tee "${DEPLOY_ROOT}/api/config/hirebridge-c28e9-firebase-adminsdk-fbsvc-22c59be5ca.json" >/dev/null
  sudo cp "${DEPLOY_ROOT}/api/config/hirebridge-c28e9-firebase-adminsdk-fbsvc-22c59be5ca.json" "${DEPLOY_ROOT}/api/config/firebase.json"

  sudo rm -rf "${DEPLOY_ROOT}/api/uploads" "${DEPLOY_ROOT}/api/wwwroot/uploads"
  sudo ln -sfn "${DEPLOY_ROOT}/uploads" "${DEPLOY_ROOT}/api/uploads"
  sudo ln -sfn "${DEPLOY_ROOT}/uploads" "${DEPLOY_ROOT}/api/wwwroot/uploads"

  sudo chown -R www-data:www-data "${DEPLOY_ROOT}/api" "${DEPLOY_ROOT}/uploads"
  sudo chown -h www-data:www-data "${DEPLOY_ROOT}/api/uploads" "${DEPLOY_ROOT}/api/wwwroot/uploads"

  sudo tee /etc/systemd/system/jobfair-backend.service >/dev/null <<'UNIT'
[Unit]
Description=JobFair Backend API
After=network.target

[Service]
WorkingDirectory=${DEPLOY_ROOT}/api
ExecStart=/usr/bin/dotnet ${DEPLOY_ROOT}/api/JobFairPortal.dll
Restart=always
RestartSec=5
KillSignal=SIGINT
SyslogIdentifier=jobfair-backend
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

[Install]
WantedBy=multi-user.target
UNIT

  sudo systemctl daemon-reload
  sudo systemctl enable jobfair-backend
  sudo systemctl restart jobfair-backend
fi

sudo nginx -t
sudo systemctl reload nginx
'''
            }
        }
    }

    post {
        always {
            sh 'rm -rf .deploy-artifacts || true'
        }
    }
}