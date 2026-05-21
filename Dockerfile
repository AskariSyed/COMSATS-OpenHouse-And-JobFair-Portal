# syntax=docker/dockerfile:1.7

FROM node:20-alpine AS admin-build
WORKDIR /src/admin-portal

ARG VITE_BACKEND_URL=
ARG VITE_API_BASE_URL=
ARG VITE_SERVER_URL=
ARG VITE_FIREBASE_API_KEY=
ARG VITE_FIREBASE_AUTH_DOMAIN=
ARG VITE_FIREBASE_PROJECT_ID=
ARG VITE_FIREBASE_STORAGE_BUCKET=
ARG VITE_FIREBASE_MESSAGING_SENDER_ID=
ARG VITE_FIREBASE_APP_ID=
ARG VITE_FIREBASE_VAPID_KEY=

ENV VITE_BACKEND_URL=${VITE_BACKEND_URL} \
    VITE_API_BASE_URL=${VITE_API_BASE_URL} \
    VITE_SERVER_URL=${VITE_SERVER_URL} \
    VITE_FIREBASE_API_KEY=${VITE_FIREBASE_API_KEY} \
    VITE_FIREBASE_AUTH_DOMAIN=${VITE_FIREBASE_AUTH_DOMAIN} \
    VITE_FIREBASE_PROJECT_ID=${VITE_FIREBASE_PROJECT_ID} \
    VITE_FIREBASE_STORAGE_BUCKET=${VITE_FIREBASE_STORAGE_BUCKET} \
    VITE_FIREBASE_MESSAGING_SENDER_ID=${VITE_FIREBASE_MESSAGING_SENDER_ID} \
    VITE_FIREBASE_APP_ID=${VITE_FIREBASE_APP_ID} \
    VITE_FIREBASE_VAPID_KEY=${VITE_FIREBASE_VAPID_KEY}

COPY admin-portal/package*.json ./
RUN npm ci
COPY admin-portal/ ./
RUN npm run build

FROM node:20-alpine AS company-build
WORKDIR /src/company-portal

ARG VITE_API_BASE_URL=
ARG VITE_SERVER_URL=
ARG VITE_FIREBASE_API_KEY=
ARG VITE_FIREBASE_AUTH_DOMAIN=
ARG VITE_FIREBASE_PROJECT_ID=
ARG VITE_FIREBASE_STORAGE_BUCKET=
ARG VITE_FIREBASE_MESSAGING_SENDER_ID=
ARG VITE_FIREBASE_APP_ID=
ARG VITE_FIREBASE_VAPID_KEY=

ENV VITE_API_BASE_URL=${VITE_API_BASE_URL} \
    VITE_SERVER_URL=${VITE_SERVER_URL} \
    VITE_FIREBASE_API_KEY=${VITE_FIREBASE_API_KEY} \
    VITE_FIREBASE_AUTH_DOMAIN=${VITE_FIREBASE_AUTH_DOMAIN} \
    VITE_FIREBASE_PROJECT_ID=${VITE_FIREBASE_PROJECT_ID} \
    VITE_FIREBASE_STORAGE_BUCKET=${VITE_FIREBASE_STORAGE_BUCKET} \
    VITE_FIREBASE_MESSAGING_SENDER_ID=${VITE_FIREBASE_MESSAGING_SENDER_ID} \
    VITE_FIREBASE_APP_ID=${VITE_FIREBASE_APP_ID} \
    VITE_FIREBASE_VAPID_KEY=${VITE_FIREBASE_VAPID_KEY}

COPY company-portal/package*.json ./
RUN npm ci
COPY company-portal/ ./
RUN npm run build

FROM node:20-alpine AS landing-build
WORKDIR /src/landing-page

COPY landing-page/package*.json ./
RUN npm ci
COPY landing-page/ ./
RUN npm run build

# Pin Flutter to the exact version used by CI/local builds.
FROM ghcr.io/cirruslabs/flutter:3.35.0 AS student-build
WORKDIR /src/student-portal

ARG BACKEND_BASE_URL=/api
ARG APP_ENV=production
ARG FIREBASE_VAPID_KEY=

ENV BACKEND_BASE_URL=${BACKEND_BASE_URL} \
    APP_ENV=${APP_ENV} \
    FIREBASE_VAPID_KEY=${FIREBASE_VAPID_KEY}

COPY student-portal/pubspec.yaml student-portal/pubspec.lock ./
RUN flutter pub get
COPY student-portal/ ./
RUN flutter build web --release --wasm \
    --dart-define=BACKEND_BASE_URL=${BACKEND_BASE_URL} \
    --dart-define=APP_ENV=${APP_ENV} \
    --dart-define=FIREBASE_VAPID_KEY=${FIREBASE_VAPID_KEY}

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS backend-build
WORKDIR /src/Backend

COPY Backend/*.csproj ./
RUN dotnet restore JobFairPortal.csproj
COPY Backend/ ./
RUN dotnet publish JobFairPortal.csproj -c Release -o /app/backend /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0-bookworm-slim AS final

ENV ASPNETCORE_ENVIRONMENT=Production
ENV PORT=5158

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends nginx ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=backend-build /app/backend/ /app/backend/
COPY --from=admin-build /src/admin-portal/dist/ /usr/share/nginx/html/admin/
COPY --from=company-build /src/company-portal/dist/ /usr/share/nginx/html/company/
COPY --from=landing-build /src/landing-page/dist/ /usr/share/nginx/html/landing/
COPY --from=student-build /src/student-portal/build/web/ /usr/share/nginx/html/student/
COPY nginx.single.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh \
    && mkdir -p /app/backend/uploads/student \
    && mkdir -p /app/backend/wwwroot/uploads/companies \
    && mkdir -p /var/cache/nginx /var/log/nginx

EXPOSE 80

CMD ["/entrypoint.sh"]