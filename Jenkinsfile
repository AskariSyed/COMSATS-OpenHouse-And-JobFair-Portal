pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    triggers {
        githubPush()
    }

    parameters {
      string(name: 'BACKEND_URL', defaultValue: 'https://comsats.api.jfair.tech', description: 'Backend URL used when building the portals.')
        string(name: 'DEPLOY_ROOT', defaultValue: '/var/www', description: 'Local deployment root on the Jenkins agent or target server.')
        booleanParam(name: 'APPLY_NGINX_CONFIG', defaultValue: false, description: 'If true, copy nginx config files from the repository to the server. Safe default: false.')
    }

    environment {
      FLUTTER_VERSION = '3.35.0'
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
            steps {
                dir('landing-page') {
                    sh 'npm ci'
                    sh 'npm run build'
                }
            }
        }

        stage('Build Student Portal') {
            steps {
                dir('student-portal') {
                    sh '''#!/usr/bin/env bash
set -euo pipefail

install_flutter() {
  local preferred_flutter_root="/opt/flutter-${FLUTTER_VERSION}"
  local managed_flutter_root="$WORKSPACE/.tooling/flutter-${FLUTTER_VERSION}"
  local selected_flutter_root=""

  sudo apt-get update -y
  sudo apt-get install -y git curl xz-utils unzip

  if [ -x "$preferred_flutter_root/bin/flutter" ] && "$preferred_flutter_root/bin/flutter" --version | grep -q "Flutter ${FLUTTER_VERSION}"; then
    selected_flutter_root="$preferred_flutter_root"
  else
    mkdir -p "$WORKSPACE/.tooling"
    if [ ! -d "$managed_flutter_root/.git" ] || ! "$managed_flutter_root/bin/flutter" --version | grep -q "Flutter ${FLUTTER_VERSION}"; then
      rm -rf "$managed_flutter_root"
      git clone --depth 1 -b "${FLUTTER_VERSION}" https://github.com/flutter/flutter.git "$managed_flutter_root"
    fi
    selected_flutter_root="$managed_flutter_root"
  fi

  [ -d "$preferred_flutter_root" ] && sudo chown -R jenkins:jenkins "$preferred_flutter_root" || true
  [ -d "$managed_flutter_root" ] && chown -R jenkins:jenkins "$managed_flutter_root" || true

  export PATH="$selected_flutter_root/bin:$PATH"
}

install_android_sdk() {
  local android_sdk_root="$WORKSPACE/.tooling/android-sdk"
  local cmdline_tools_zip="$WORKSPACE/.tooling/commandlinetools-linux.zip"
  local sdkmanager_bin="$android_sdk_root/cmdline-tools/latest/bin/sdkmanager"

  sudo apt-get update -y
  sudo apt-get install -y openjdk-17-jdk

  mkdir -p "$WORKSPACE/.tooling" "$android_sdk_root/cmdline-tools"

  if [ ! -x "$sdkmanager_bin" ]; then
    curl -fsSL -o "$cmdline_tools_zip" "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    rm -rf "$android_sdk_root/cmdline-tools/latest"
    mkdir -p "$android_sdk_root/cmdline-tools/latest"
    unzip -q -o "$cmdline_tools_zip" -d "$android_sdk_root/cmdline-tools/latest"

    if [ -d "$android_sdk_root/cmdline-tools/latest/cmdline-tools" ]; then
      mv "$android_sdk_root/cmdline-tools/latest/cmdline-tools"/* "$android_sdk_root/cmdline-tools/latest/"
      rmdir "$android_sdk_root/cmdline-tools/latest/cmdline-tools"
    fi
  fi

  export ANDROID_SDK_ROOT="$android_sdk_root"
  export ANDROID_HOME="$android_sdk_root"
  export PATH="$android_sdk_root/cmdline-tools/latest/bin:$android_sdk_root/platform-tools:$PATH"

  yes | "$sdkmanager_bin" --sdk_root="$ANDROID_SDK_ROOT" --licenses >/dev/null || true
  "$sdkmanager_bin" --sdk_root="$ANDROID_SDK_ROOT" --install \
    "platform-tools" \
    "platforms;android-34" \
    "platforms;android-35" \
    "build-tools;34.0.0" \
    "build-tools;35.0.0"
}

install_flutter
install_android_sdk

FLUTTER_BIN="$(command -v flutter)"

"$FLUTTER_BIN" --version
"$FLUTTER_BIN" config --android-sdk "$ANDROID_SDK_ROOT"

"$FLUTTER_BIN" pub get
"$FLUTTER_BIN" build web --release --no-wasm-dry-run --dart-define=BACKEND_BASE_URL="$BACKEND_URL" --dart-define=APP_ENV=production
"$FLUTTER_BIN" build apk --release --dart-define=BACKEND_BASE_URL="$BACKEND_URL" --dart-define=APP_ENV=production
'''
                }
            }
        }

        stage('Build Backend') {
            steps {
                dir('Backend') {
                    sh '''#!/usr/bin/env bash
set -euo pipefail

install_dotnet() {
  local dotnet_root="$WORKSPACE/.tooling/dotnet"
  local dotnet_bin="$dotnet_root/dotnet"

  sudo apt-get update -y
  sudo apt-get install -y curl ca-certificates

  if [ ! -x "$dotnet_bin" ]; then
    mkdir -p "$dotnet_root"
    curl -fsSL https://dot.net/v1/dotnet-install.sh -o "$WORKSPACE/.tooling/dotnet-install.sh"
    chmod +x "$WORKSPACE/.tooling/dotnet-install.sh"
    "$WORKSPACE/.tooling/dotnet-install.sh" --channel 8.0 --install-dir "$dotnet_root"
  fi

  export DOTNET_ROOT="$dotnet_root"
  export PATH="$DOTNET_ROOT:$PATH"
}

install_dotnet

dotnet --info
dotnet restore
dotnet build --configuration Release
dotnet publish JobFairPortal.csproj --configuration Release --output publish
'''
                }
            }
        }

        stage('Package Artifacts') {
            steps {
                sh '''#!/usr/bin/env bash
set -euo pipefail

mkdir -p .deploy-artifacts

if [ -d admin-portal/dist ]; then
  tar -czf .deploy-artifacts/admin.tar.gz -C admin-portal/dist .
fi

if [ -d company-portal/dist ]; then
  tar -czf .deploy-artifacts/company.tar.gz -C company-portal/dist .
fi

if [ -d landing-page/dist ]; then
  tar -czf .deploy-artifacts/landing.tar.gz -C landing-page/dist .
fi

if [ -d student-portal/build/web ]; then
  tar -czf .deploy-artifacts/student.tar.gz -C student-portal/build/web .
fi

if [ -f student-portal/build/app/outputs/flutter-apk/app-release.apk ]; then
  cp student-portal/build/app/outputs/flutter-apk/app-release.apk .deploy-artifacts/student-portal.apk
fi

if [ -d Backend/publish ]; then
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
sudo apt-get install -y tar gzip unzip webp nginx

  if [ "${APPLY_NGINX_CONFIG:-false}" = "true" ]; then
    echo "APPLY_NGINX_CONFIG=true -> updating nginx configs from repository (backing up current files)..."
    # backup existing configs when present
    sudo mkdir -p /etc/nginx/sites-available
    if [ -f /etc/nginx/sites-available/jfair-domains.conf ]; then
      sudo cp /etc/nginx/sites-available/jfair-domains.conf /etc/nginx/sites-available/jfair-domains.conf.bak.$(date +%s) || true
    fi
    if [ -f /etc/nginx/sites-available/jobfair-ip.nginx.conf ]; then
      sudo cp /etc/nginx/sites-available/jobfair-ip.nginx.conf /etc/nginx/sites-available/jobfair-ip.nginx.conf.bak.$(date +%s) || true
    fi

    if [ -f /etc/letsencrypt/live/comsats.jfair.tech/fullchain.pem ] && [ -f /etc/letsencrypt/live/comsats.jfair.tech/privkey.pem ]; then
      sudo cp jfair-domains.conf /etc/nginx/sites-available/jfair-domains.conf
      sudo ln -sfn /etc/nginx/sites-available/jfair-domains.conf /etc/nginx/sites-enabled/jfair-domains.conf
      sudo rm -f /etc/nginx/sites-enabled/jobfair-ip.nginx.conf
    else
      sudo cp jobfair-ip.nginx.conf /etc/nginx/sites-available/jobfair-ip.nginx.conf
      sudo ln -sfn /etc/nginx/sites-available/jobfair-ip.nginx.conf /etc/nginx/sites-enabled/jobfair-ip.nginx.conf
      sudo rm -f /etc/nginx/sites-enabled/jfair-domains.conf
    fi
  else
    echo "APPLY_NGINX_CONFIG=false -> skipping nginx config updates. To enable, set APPLY_NGINX_CONFIG=true in the job parameters."
  fi
sudo rm -f /etc/nginx/sites-enabled/default

if [ -f .deploy-artifacts/admin.tar.gz ]; then
  sudo rm -rf "${DEPLOY_ROOT}/admin"/*
  sudo tar -xzf .deploy-artifacts/admin.tar.gz -C "${DEPLOY_ROOT}/admin"
  sudo chown -R www-data:www-data "${DEPLOY_ROOT}/admin"
fi

if [ -f .deploy-artifacts/company.tar.gz ]; then
  sudo rm -rf "${DEPLOY_ROOT}/company"/*
  sudo tar -xzf .deploy-artifacts/company.tar.gz -C "${DEPLOY_ROOT}/company"
  sudo chown -R www-data:www-data "${DEPLOY_ROOT}/company"
fi

if [ -f .deploy-artifacts/landing.tar.gz ]; then
  sudo rm -rf "${DEPLOY_ROOT}/jfair"/*
  sudo tar -xzf .deploy-artifacts/landing.tar.gz -C "${DEPLOY_ROOT}/jfair"
  sudo chown -R www-data:www-data "${DEPLOY_ROOT}/jfair"
fi

if [ -f .deploy-artifacts/student.tar.gz ]; then
  # remove all student files except persisted downloads directory
  sudo mkdir -p "${DEPLOY_ROOT}/student"
  sudo find "${DEPLOY_ROOT}/student" -mindepth 1 -maxdepth 1 ! -name 'downloads' -exec rm -rf {} + || true
  sudo tar -xzf .deploy-artifacts/student.tar.gz -C "${DEPLOY_ROOT}/student"
  sudo mkdir -p "${DEPLOY_ROOT}/student/downloads"
  if [ -f .deploy-artifacts/student-portal.apk ]; then
    sudo cp .deploy-artifacts/student-portal.apk "${DEPLOY_ROOT}/student/downloads/student-portal.apk"
  fi

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

  if [ -f .deploy-artifacts/backend.tar.gz ]; then
  DOTNET_SERVICE_ROOT="/opt/jobfair-dotnet"
  DOTNET_EXEC="${DOTNET_SERVICE_ROOT}/dotnet"

  if [ ! -x "$DOTNET_EXEC" ]; then
    curl -fsSL https://dot.net/v1/dotnet-install.sh -o "$WORKSPACE/.tooling/dotnet-install.sh"
    chmod +x "$WORKSPACE/.tooling/dotnet-install.sh"
    sudo mkdir -p "$DOTNET_SERVICE_ROOT"
    sudo "$WORKSPACE/.tooling/dotnet-install.sh" --channel 8.0 --runtime aspnetcore --install-dir "$DOTNET_SERVICE_ROOT"
  fi

  # remove api contents but preserve the persistent uploads directory
  sudo mkdir -p "${DEPLOY_ROOT}/api"
  sudo find "${DEPLOY_ROOT}/api" -mindepth 1 -maxdepth 1 ! -name 'uploads' -exec rm -rf {} + || true
  sudo tar -xzf .deploy-artifacts/backend.tar.gz -C "${DEPLOY_ROOT}/api"

  printf '%s\n' "${FIREBASE_CONFIG_JSON}" | sudo tee "${DEPLOY_ROOT}/api/config/hirebridge-c28e9-firebase-adminsdk-fbsvc-22c59be5ca.json" >/dev/null
  sudo cp "${DEPLOY_ROOT}/api/config/hirebridge-c28e9-firebase-adminsdk-fbsvc-22c59be5ca.json" "${DEPLOY_ROOT}/api/config/firebase.json"

  sudo rm -rf "${DEPLOY_ROOT}/api/uploads" "${DEPLOY_ROOT}/api/wwwroot/uploads"
  sudo ln -sfn "${DEPLOY_ROOT}/uploads" "${DEPLOY_ROOT}/api/uploads"
  sudo ln -sfn "${DEPLOY_ROOT}/uploads" "${DEPLOY_ROOT}/api/wwwroot/uploads"

  sudo chown -R www-data:www-data "${DEPLOY_ROOT}/api" "${DEPLOY_ROOT}/uploads"
  sudo chown -h www-data:www-data "${DEPLOY_ROOT}/api/uploads" "${DEPLOY_ROOT}/api/wwwroot/uploads"

  sudo tee /etc/systemd/system/jobfair-backend.service >/dev/null <<UNIT
[Unit]
Description=JobFair Backend API
After=network.target

[Service]
WorkingDirectory=${DEPLOY_ROOT}/api
ExecStart=${DOTNET_EXEC} ${DEPLOY_ROOT}/api/JobFairPortal.dll
Restart=always
RestartSec=5
KillSignal=SIGINT
SyslogIdentifier=jobfair-backend
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false
Environment=DOTNET_ROOT=${DOTNET_SERVICE_ROOT}

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

    stage('Report Endpoints') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail

echo "Landing page: http://${DEPLOY_ROOT:-/var/www}/jfair (fallback port 8084)"
echo "Backend API:  ${BACKEND_URL}"
echo "Admin portal: http://${DEPLOY_ROOT:-/var/www}/admin or https://comsats.admin.jfair.tech"
echo "Company portal: http://${DEPLOY_ROOT:-/var/www}/company or https://comsats.company.jfair.tech"
echo "Student portal: http://${DEPLOY_ROOT:-/var/www}/student or https://comsats.student.jfair.tech"
echo "API domain:   https://comsats.api.jfair.tech"
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