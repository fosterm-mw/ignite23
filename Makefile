MKFILEPATH = $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILEDIR = $(dir $(MKFILEPATH))
WORKDIR = ${MKFILEDIR}.work
K3D = ${WORKDIR}/k3d
HELM = ${WORKDIR}/helm
KUSTOMIZE = ${WORKDIR}/kustomize
KUBECTL = ${WORKDIR}/kubectl
INFRADIR = ${MKFILEDIR}infra
MKDIR = mkdir -p
CREDS ?= $${HOME}/.config/gcloud/application_default_credentials.json
NAMESPACE ?= crossplane-system
DEV_CLUSTER = projectx-dev-cluster
TENANT ?= admin

UNAME_S := $(shell uname -s)
UNAME_P := $(shell uname -p)

ifeq ($(UNAME_S),Darwin)
	ifneq ($(filter %86,$(UNAME_P)),)
		K3D_DOWNLOAD := curl -Lo ${K3D} https://github.com/k3d-io/k3d/releases/download/v5.4.6/k3d-darwin-amd64
		HELM_DOWNLOAD := curl -Lo ${WORKDIR}/helm.tar.gz https://get.helm.sh/helm-v3.9.4-darwin-amd64.tar.gz
		HELM_ARCH := ${WORKDIR}/darwin-amd64
		KUSTOMIZE_DOWNLOAD := curl -Lo ${WORKDIR}/kustomize.tar.gz https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.5.7/kustomize_v4.5.7_darwin_amd64.tar.gz
		KUBECTL_DOWNLOAD := curl -Lo ${WORKDIR}/kubectl "https://storage.googleapis.com/kubernetes-release/release/$$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl"
		ARGOCDCLI_DOWNLOAD := curl -Lo ${WORKDIR}/argocd https://github.com/argoproj/argo-cd/releases/download/v2.4.11/argocd-darwin-amd64
	endif
	ifneq ($(filter arm%,$(UNAME_P)),)
		K3D_DOWNLOAD := curl -Lo ${K3D} https://github.com/k3d-io/k3d/releases/download/v5.4.6/k3d-darwin-arm64
		HELM_DOWNLOAD := curl -Lo ${WORKDIR}/helm.tar.gz https://get.helm.sh/helm-v3.9.4-darwin-arm64.tar.gz
		HELM_ARCH := ${WORKDIR}/darwin-arm64
		KUSTOMIZE_DOWNLOAD := curl -Lo ${WORKDIR}/kustomize.tar.gz https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.5.7/kustomize_v4.5.7_darwin_arm64.tar.gz
		KUBECTL_DOWNLOAD := curl -Lo ${WORKDIR}/kubectl "https://storage.googleapis.com/kubernetes-release/release/$$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/arm64/kubectl"
		ARGOCDCLI_DOWNLOAD := curl -Lo ${WORKDIR}/argocd https://github.com/argoproj/argo-cd/releases/download/v2.4.11/argocd-darwin-arm64
	endif
endif

ifeq ($(UNAME_S),Linux)
	ifneq ($(filter x86_64,$(UNAME_P)),)
		K3D_DOWNLOAD := curl -Lo ${K3D} https://github.com/k3d-io/k3d/releases/download/v5.4.6/k3d-linux-amd64
		HELM_DOWNLOAD := curl -Lo ${WORKDIR}/helm.tar.gz https://get.helm.sh/helm-v3.9.4-linux-amd64.tar.gz
		KUSTOMIZE_DOWNLOAD := curl -Lo ${WORKDIR}/kustomize.tar.gz https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.5.7/kustomize_v4.5.7_linux_amd64.tar.gz
		KUBECTL_DOWNLOAD := curl -Lo ${WORKDIR}/kubectl "https://storage.googleapis.com/kubernetes-release/release/$$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
		ARGOCDCLI_DOWNLOAD := curl -Lo ${WORKDIR}/argocd https://github.com/argoproj/argo-cd/releases/download/v2.4.11/argocd-linux-amd64
	endif
	ifneq ($(filter arm%,$(UNAME_P)),)
		K3D_DOWNLOAD := curl -Lo ${K3D} https://github.com/k3d-io/k3d/releases/download/v5.4.6/k3d-linux-arm64
		HELM_DOWNLOAD := curl -Lo ${WORKDIR}/helm.tar.gz https://get.helm.sh/helm-v3.9.4-linux-arm64.tar.gz
		KUSTOMIZE_DOWNLOAD := curl -Lo ${WORKDIR}/kustomize.tar.gz https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.5.7/kustomize_v4.5.7_linux_arm64.tar.gz
		ARGOCDCLI_DOWNLOAD := curl -Lo ${WORKDIR}/argocd https://github.com/argoproj/argo-cd/releases/download/v2.4.11/argocd-linux-arm64
	endif
endif

export KUBECONFIG=${MKFILEDIR}kubeconfig

# COLORS
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)

.PHONY: help directories

help: ## Show this help message.
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
					helpMessage = match(lastLine, /^## (.*)/); \
					if (helpMessage) { \
									helpCommand = substr($$1, 0, index($$1, ":")-1); \
									helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
									printf "  ${YELLOW}%-$(TARGET_MAX_CHAR_NUM)s${RESET} ${GREEN}%s${RESET}\n", helpCommand, helpMessage; \
					} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

## Create buil directories
directories:
	$(MKDIR) $(BUILDDIR) $(WORKDIR)

install_kustomize: directories
ifneq ($(wildcard ${KUSTOMIZE}), ${KUSTOMIZE})
	$(KUSTOMIZE_DOWNLOAD) ;\
	tar -zxvf ${WORKDIR}/kustomize.tar.gz -C ${WORKDIR} ;\
	rm ${WORKDIR}/kustomize.tar.gz
endif

install_kubectl: directories
ifneq ($(wildcard ${KUBECTL}), ${KUBECTL})
	$(KUBECTL_DOWNLOAD) ;\
	chmod +x ${KUBECTL}
endif

install_k3d: directories
ifneq ($(wildcard ${K3D}), ${K3D})
	$(K3D_DOWNLOAD) ;\
	chmod +x ${K3D}
endif

install_helm: directories
ifneq ($(wildcard ${HELM}), ${HELM})
	$(HELM_DOWNLOAD) ;\
	tar -zxvf ${WORKDIR}/helm.tar.gz -C ${WORKDIR} ;\
	mv ${HELM_ARCH}/helm ${WORKDIR} ;\
	rm -Rf ${HELM_ARCH} ;\
	rm ${WORKDIR}/helm.tar.gz
endif

## Install crossplane onto K3D cluster
install_crossplane: install_helm
	${HELM} upgrade --install --repo https://charts.crossplane.io/stable --version 1.10.1 --create-namespace --namespace crossplane-system crossplane crossplane --values ${MKFILEDIR}helm/crossplane/values.yaml --wait

## Install Crossplane providers
create_providers: install_kubectl
	${KUBECTL} apply -f ${MKFILEDIR}providers

local_bootstrap: install_crossplane create_providers

## Create tenant namespace
create_ns: install_kubectl
	${KUBECTL} create ns ${TENANT} || true

## Delete Crossplane GCP provider secret
delete_provider_secret:
	${KUBECTL} -n ${NAMESPACE} delete secret gcp-default || true

## Create Crossplane GCP provider secret
create_provider_secret: create_ns delete_provider_secret
	${KUBECTL} -n ${NAMESPACE} create secret generic gcp-default --from-file=credentials=${CREDS}

create_gcp_providerconfig:
	${KUBECTL} apply -f ${MKFILEDIR}provider-configs ;\

create_providerconfigs: create_gcp_providerconfig

## Setup local devlopment cluster
setup: create_provider_secret create_providerconfigs

## Create GKE bootstrap cluster
create_bootstrap_cluster:
	${KUBECTL} apply -f ${MKFILEDIR}infra ;\

## Destroy local devlopment cluster
destroy: destroy_dev_cluster

## Clean Crossplane packages
clean_all: destroy
	rm -Rf ${WORKDIR}

## Local Development
.PHONY: create_dev_cluster
## Create local dev cluster
create_dev_cluster: install_k3d
	${K3D} cluster create ${DEV_CLUSTER} --no-lb  --k3s-arg --disable=traefik@server:* || true

.PHONY: local_dev
local_dev: install_kubectl create_dev_cluster local_bootstrap

.PHONY: destroy_dev_cluster
destroy_dev_cluster:
	@k3d cluster delete ${DEV_CLUSTER}

.PHONY: create_infra
create_infra:
	${KUBECTL} apply -k ${MKFILEDIR}infra

.PHONY: destroy_infra
destroy_infra:
	${KUBECTL} delete -k ${MKFILEDIR}infra
