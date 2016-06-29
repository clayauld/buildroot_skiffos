################################################################################
#
# docker-containerd
#
################################################################################

DOCKER_CONTAINERD_VERSION = b93a33be39bc4ef0fb00bfcb79147a28c33d9d43
DOCKER_CONTAINERD_SITE = $(call github,docker,containerd,$(DOCKER_CONTAINERD_VERSION))

DOCKER_CONTAINERD_LICENSE = Apache-2.0
DOCKER_CONTAINERD_LICENSE_FILES = LICENSE.code

DOCKER_CONTAINERD_DEPENDENCIES = host-go

DOCKER_CONTAINERD_GOPATH = "$(@D)/vendor"
DOCKER_CONTAINERD_MAKE_ENV = $(HOST_GO_TARGET_ENV) \
	CGO_ENABLED=1 \
	GOBIN="$(@D)/bin" \
	GOPATH="$(DOCKER_CONTAINERD_GOPATH)"

DOCKER_CONTAINERD_GLDFLAGS = \
	-X github.com/docker/containerd.GitCommit=$(DOCKER_CONTAINERD_VERSION) \
	-extldflags '-static'

define DOCKER_CONTAINERD_CONFIGURE_CMDS
	mkdir -p $(DOCKER_CONTAINERD_GOPATH)/src/github.com/docker
	ln -s $(@D) $(DOCKER_CONTAINERD_GOPATH)/src/github.com/docker/containerd
	mkdir -p $(DOCKER_CONTAINERD_GOPATH)/src/github.com/opencontainers
	ln -s $(RUNC_SRCDIR) $(DOCKER_CONTAINERD_GOPATH)/src/github.com/opencontainers/runc
endef

define DOCKER_CONTAINERD_BUILD_CMDS
	cd $(@D); $(DOCKER_CONTAINERD_MAKE_ENV) $(HOST_DIR)/usr/bin/go build -v -o $(@D)/bin/ctr -ldflags "$(DOCKER_CONTAINERD_GLDFLAGS)" ./ctr
	cd $(@D); $(DOCKER_CONTAINERD_MAKE_ENV) $(HOST_DIR)/usr/bin/go build -v -o $(@D)/bin/containerd -ldflags "$(DOCKER_CONTAINERD_GLDFLAGS)" ./containerd
	cd $(@D); $(DOCKER_CONTAINERD_MAKE_ENV) $(HOST_DIR)/usr/bin/go build -v -o $(@D)/bin/containerd-shim -ldflags "$(DOCKER_CONTAINERD_GLDFLAGS)" ./containerd-shim
endef

define DOCKER_CONTAINERD_INSTALL_TARGET_CMDS
	ln -fs runc $(TARGET_DIR)/usr/bin/docker-runc
	$(INSTALL) -D -m 0755 $(@D)/bin/containerd $(TARGET_DIR)/usr/bin/docker-containerd
	$(INSTALL) -D -m 0755 $(@D)/bin/containerd-shim $(TARGET_DIR)/usr/bin/containerd-shim
	ln -fs containerd-shim $(TARGET_DIR)/usr/bin/docker-containerd-shim
endef

$(eval $(generic-package))
