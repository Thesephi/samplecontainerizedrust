# must match the value of package.name in Cargo.toml
CARGO_PACKAGE_NAME := samplecontainerizedrust

# this doesn't need to be the same as ${CARGO_PACKAGE_NAME}
# we only use that value here for simplicity
# @TODO use an external env var, defaulting to a hard-coded value
TARGET_K8S_NAMESPACE := samplecontainerizedrust

# hostname to a registry that supports OCI (ie DockerHub)
REGISTRY_HOSTNAME := registry-1.docker.io

#####################################################################
# NOTE: $REGISTRY_NAMESPACE is to be provided as an external env var
#####################################################################

# directory where output helm packages are generated (gitignore'd)
HELM_DIST := helm-dist

.PHONY:
	build build-debug
	start start-debug
	docker-build-latest docker-push-latest
	helm-login helm-package helm-push-v010:
	example-helm-install example-helm-upgrade-force-img-pull example-helm-uninstall

build:
	cargo build --release

build-debug:
	cargo build

start:
	target/release/${CARGO_PACKAGE_NAME}

start-debug:
	target/debug/${CARGO_PACKAGE_NAME}

docker-build-latest:
	@[ -z "${REGISTRY_NAMESPACE}" ] && echo 'missing $$REGISTRY_NAMESPACE' || \
	docker build -t ${REGISTRY_NAMESPACE}/${CARGO_PACKAGE_NAME}:latest .

docker-push-latest:
	@[ -z "${REGISTRY_NAMESPACE}" ] && echo 'missing $$REGISTRY_NAMESPACE' || \
	docker push ${REGISTRY_NAMESPACE}/${CARGO_PACKAGE_NAME}:latest

helm-login:
	helm registry login ${REGISTRY_HOSTNAME}

# build helm package into the ./helm-dist directory
helm-package:
	helm package helm/${CARGO_PACKAGE_NAME} -d ${HELM_DIST}

#####################################################################
# Make commands starting with `example-` is, as implied, mainly for
# examplary & educational purposes
#####################################################################

# push the resulted helm package at version 0.1.0 to the remote helm chart-supported registry
example-helm-push-v010:
	@[ -z "${REGISTRY_NAMESPACE}" ] && echo 'missing $$REGISTRY_NAMESPACE' || \
	helm push ${HELM_DIST}/${CARGO_PACKAGE_NAME}-0.1.0.tgz oci://${REGISTRY_HOSTNAME}/${REGISTRY_NAMESPACE}

example-helm-install:
	@[ -z "${REGISTRY_NAMESPACE}" ] && echo 'missing $$REGISTRY_NAMESPACE' || \
	helm upgrade --install ${CARGO_PACKAGE_NAME} oci://${REGISTRY_HOSTNAME}/${REGISTRY_NAMESPACE}/${CARGO_PACKAGE_NAME} -n ${TARGET_K8S_NAMESPACE}

example-helm-upgrade-force-img-pull:
	@[ -z "${REGISTRY_NAMESPACE}" ] && echo 'missing $$REGISTRY_NAMESPACE' || \
	helm upgrade ${CARGO_PACKAGE_NAME} oci://${REGISTRY_HOSTNAME}/${REGISTRY_NAMESPACE}/${CARGO_PACKAGE_NAME} -n ${TARGET_K8S_NAMESPACE} --set image.pullPolicy=Always

example-helm-uninstall:
	helm uninstall ${CARGO_PACKAGE_NAME} -n ${TARGET_K8S_NAMESPACE}