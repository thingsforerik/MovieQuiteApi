# Makefile for MovieQuiteApi - OCI Container Registry
# =====================================================

# Variables - customize these for your environment
APP_NAME := moviequiteapi
VERSION ?= latest
CHART_VERSION := $(shell grep '^version:' helm/moviequiteapi/Chart.yaml | awk '{print $$2}')
APP_VERSION := $(shell grep '^appVersion:' helm/moviequiteapi/Chart.yaml | awk '{print $$2}' | tr -d '"')

# OCI Registry Configuration
REGION := iad
TENANCY_NAMESPACE := idrdeojypihh
REPO_PATH := pif/staging
REGISTRY := $(REGION).ocir.io
FULL_REPO := $(REGISTRY)/$(TENANCY_NAMESPACE)/$(REPO_PATH)/$(APP_NAME)

# Docker build arguments
DOCKER_BUILDKIT := 1

# Helm Configuration
HELM_RELEASE := $(APP_NAME)
HELM_NAMESPACE ?= moviequiteapi
HELM_CHART := ./helm/moviequiteapi
HELM_VALUES ?= $(HELM_CHART)/values.yaml
HELM_TIMEOUT ?= 5m

# Targets
.PHONY: help build tag push all clean info helm-install helm-upgrade helm-deploy helm-uninstall helm-dry-run helm-status helm-template helm-list deploy-all db-up db-down db-logs db-clean db-shell dev-up dev-down dev-logs dev-restart

help: ## Show this help message
	@echo "MovieQuiteApi - OCIR Container Registry Makefile"
	@echo "================================================="
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo ""
	@echo "Current Configuration:"
	@echo "  App Name:       $(APP_NAME)"
	@echo "  Version:        $(VERSION)"
	@echo "  App Version:    $(APP_VERSION)"
	@echo "  Chart Version:  $(CHART_VERSION)"
	@echo "  Full Image:     $(FULL_REPO):$(VERSION)"

info: ## Display current configuration
	@echo "Configuration:"
	@echo "  APP_NAME:           $(APP_NAME)"
	@echo "  VERSION:            $(VERSION)"
	@echo "  APP_VERSION:        $(APP_VERSION)"
	@echo "  CHART_VERSION:      $(CHART_VERSION)"
	@echo "  REGISTRY:           $(REGISTRY)"
	@echo "  TENANCY_NAMESPACE:  $(TENANCY_NAMESPACE)"
	@echo "  REPO_PATH:          $(REPO_PATH)"
	@echo "  FULL_REPO:          $(FULL_REPO)"
	@echo ""
	@echo "Images to be tagged:"
	@echo "  $(FULL_REPO):$(VERSION)"
	@echo "  $(FULL_REPO):$(APP_VERSION)"
	@echo ""
	@echo "Helm Configuration:"
	@echo "  RELEASE:            $(HELM_RELEASE)"
	@echo "  NAMESPACE:          $(HELM_NAMESPACE)"
	@echo "  CHART:              $(HELM_CHART)"
	@echo "  VALUES:             $(HELM_VALUES)"

build: ## Build the Docker image
	@echo "Building Docker image for $(APP_NAME)..."
	DOCKER_BUILDKIT=$(DOCKER_BUILDKIT) docker build -t $(APP_NAME) .
	@echo "Build complete: $(APP_NAME)"

tag: build ## Build and tag the image for OCIR
	@echo "Tagging image for OCIR..."
	docker tag $(APP_NAME) $(FULL_REPO):$(VERSION)
	docker tag $(APP_NAME) $(FULL_REPO):$(APP_VERSION)
	@echo "Tagged as:"
	@echo "  $(FULL_REPO):$(VERSION)"
	@echo "  $(FULL_REPO):$(APP_VERSION)"

push: tag ## Build, tag, and push to OCIR
	@echo "Pushing to OCIR..."
	docker push $(FULL_REPO):$(VERSION)
	docker push $(FULL_REPO):$(APP_VERSION)
	@echo "Push complete!"
	@echo ""
	@echo "Images pushed:"
	@echo "  $(FULL_REPO):$(VERSION)"
	@echo "  $(FULL_REPO):$(APP_VERSION)"

all: push ## Build, tag, and push (same as 'make push')

clean: ## Remove local Docker images
	@echo "Removing local images..."
	-docker rmi $(APP_NAME) 2>/dev/null || true
	-docker rmi $(FULL_REPO):$(VERSION) 2>/dev/null || true
	-docker rmi $(FULL_REPO):$(APP_VERSION) 2>/dev/null || true
	@echo "Cleanup complete!"

# Version-specific targets
push-version: ## Push with a specific version (use: make push-version VERSION=1.2.3)
	@if [ "$(VERSION)" = "latest" ]; then \
		echo "Error: Please specify a version: make push-version VERSION=x.y.z"; \
		exit 1; \
	fi
	@$(MAKE) push VERSION=$(VERSION)

# Development helpers
dev-build: ## Quick build without tagging
	@echo "Quick build for development..."
	DOCKER_BUILDKIT=$(DOCKER_BUILDKIT) docker build -t $(APP_NAME):dev .

run-local: dev-build ## Build and run locally
	@echo "Running locally on port 8080..."
	docker run --rm -p 8080:8080 $(APP_NAME):dev

# Helm Deployment Targets
helm-template: ## Render Helm templates locally (dry-run)
	@echo "Rendering Helm templates..."
	helm template $(HELM_RELEASE) $(HELM_CHART) \
		--namespace $(HELM_NAMESPACE) \
		--values $(HELM_VALUES) \
		--set image.repository=$(FULL_REPO) \
		--set image.tag=$(VERSION)

helm-dry-run: ## Test Helm installation without actually deploying
	@echo "Testing Helm installation (dry-run)..."
	helm install $(HELM_RELEASE) $(HELM_CHART) \
		--namespace $(HELM_NAMESPACE) \
		--values $(HELM_VALUES) \
		--set image.repository=$(FULL_REPO) \
		--set image.tag=$(VERSION) \
		--dry-run --debug

helm-install: ## Install Helm chart (fresh install)
	@echo "Installing Helm chart: $(HELM_RELEASE)"
	helm install $(HELM_RELEASE) $(HELM_CHART) \
		--namespace $(HELM_NAMESPACE) \
		--create-namespace \
		--values $(HELM_VALUES) \
		--set image.repository=$(FULL_REPO) \
		--set image.tag=$(VERSION) \
		--timeout $(HELM_TIMEOUT) \
		--wait
	@echo "Helm chart installed successfully!"

helm-upgrade: ## Upgrade existing Helm release
	@echo "Upgrading Helm release: $(HELM_RELEASE)"
	helm upgrade $(HELM_RELEASE) $(HELM_CHART) \
		--namespace $(HELM_NAMESPACE) \
		--values $(HELM_VALUES) \
		--set image.repository=$(FULL_REPO) \
		--set image.tag=$(VERSION) \
		--timeout $(HELM_TIMEOUT) \
		--wait
	@echo "Helm chart upgraded successfully!"

helm-deploy: ## Install or upgrade Helm chart (idempotent)
	@echo "Deploying Helm chart: $(HELM_RELEASE)"
	helm upgrade --install $(HELM_RELEASE) $(HELM_CHART) \
		--namespace $(HELM_NAMESPACE) \
		--create-namespace \
		--values $(HELM_VALUES) \
		--set image.repository=$(FULL_REPO) \
		--set image.tag=$(VERSION) \
		--timeout $(HELM_TIMEOUT) \
		--wait
	@echo "Helm chart deployed successfully!"
	@echo ""
	@echo "Deployment info:"
	@echo "  Release:    $(HELM_RELEASE)"
	@echo "  Namespace:  $(HELM_NAMESPACE)"
	@echo "  Image:      $(FULL_REPO):$(VERSION)"

helm-uninstall: ## Uninstall Helm release
	@echo "Uninstalling Helm release: $(HELM_RELEASE)"
	helm uninstall $(HELM_RELEASE) --namespace $(HELM_NAMESPACE)
	@echo "Helm chart uninstalled successfully!"

helm-status: ## Show Helm release status
	@echo "Helm release status:"
	helm status $(HELM_RELEASE) --namespace $(HELM_NAMESPACE)

helm-list: ## List all Helm releases in namespace
	@echo "Helm releases in namespace $(HELM_NAMESPACE):"
	helm list --namespace $(HELM_NAMESPACE)

# Complete workflow targets
deploy-all: push helm-deploy ## Build, push, and deploy to Kubernetes
	@echo ""
	@echo "==================================="
	@echo "Complete deployment finished!"
	@echo "==================================="
	@echo "Image:     $(FULL_REPO):$(VERSION)"
	@echo "Release:   $(HELM_RELEASE)"
	@echo "Namespace: $(HELM_NAMESPACE)"

# Local Development with Docker Compose
db-up: ## Start MySQL database with docker-compose
	@echo "Starting MySQL database..."
	docker-compose up -d mysql
	@echo "Waiting for MySQL to be healthy..."
	@timeout 60 sh -c 'until docker-compose exec -T mysql mysqladmin ping -h localhost -u root -ppassword --silent; do sleep 2; done'
	@echo "MySQL is ready!"

db-down: ## Stop MySQL database
	@echo "Stopping MySQL database..."
	docker-compose down

db-logs: ## Show MySQL database logs
	docker-compose logs -f mysql

db-clean: ## Stop and remove MySQL database and volumes
	@echo "Removing MySQL database and volumes..."
	docker-compose down -v
	@echo "Database cleaned!"

db-shell: ## Open MySQL shell
	docker-compose exec mysql mysql -u root -ppassword moviequotes

dev-up: db-up ## Start local development environment (MySQL + App)
	@echo "Starting full development environment..."
	docker-compose up -d
	@echo "Development environment is running!"
	@echo ""
	@echo "Services:"
	@echo "  MySQL:  localhost:3306"
	@echo "  API:    localhost:8080"

dev-down: ## Stop local development environment
	docker-compose down

dev-logs: ## Show logs from all services
	docker-compose logs -f

dev-restart: dev-down dev-up ## Restart local development environment
