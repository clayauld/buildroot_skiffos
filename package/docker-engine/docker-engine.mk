################################################################################
#
# docker-engine
#
################################################################################

DOCKER_ENGINE_VERSION = v1.12.0-rc3
DOCKER_ENGINE_SITE = $(call github,docker,docker,$(DOCKER_ENGINE_VERSION))

DOCKER_ENGINE_LICENSE = Apache-2.0
DOCKER_ENGINE_LICENSE_FILES = LICENSE

DOCKER_ENGINE_DEPENDENCIES = host-go docker-containerd

DOCKER_ENGINE_GOPATH = "$(@D)/vendor"
DOCKER_ENGINE_MAKE_ENV = $(HOST_GO_TARGET_ENV) \
	CGO_ENABLED=1 \
	CGO_NO_EMULATION=1 \
	GOBIN="$(@D)/bin" \
	GOPATH="$(DOCKER_ENGINE_GOPATH)"

DOCKER_ENGINE_GLDFLAGS = \
	-X main.GitCommit=$(DOCKER_ENGINE_VERSION) \
	-X main.Version=$(DOCKER_ENGINE_VERSION) \
	-extldflags '-static'

DOCKER_ENGINE_BUILD_TAGS = cgo exclude_graphdriver_zfs autogen

ifeq ($(BR2_PACKAGE_LIBSECCOMP),y)
DOCKER_ENGINE_BUILD_TAGS += seccomp
DOCKER_ENGINE_DEPENDENCIES += libseccomp
endif

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_DAEMON),y)
DOCKER_ENGINE_BUILD_TAGS += daemon
endif

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_EXPERIMENTAL),y)
DOCKER_ENGINE_BUILD_TAGS += experimental
endif

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_DRIVER_BTRFS),y)
DOCKER_ENGINE_DEPENDENCIES += btrfs-progs
else
DOCKER_ENGINE_BUILD_TAGS += exclude_graphdriver_btrfs
endif

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_DRIVER_DEVICEMAPPER),y)
DOCKER_ENGINE_DEPENDENCIES += lvm2
else
DOCKER_ENGINE_BUILD_TAGS += exclude_graphdriver_devicemapper
endif

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_DRIVER_VFS),y)
DOCKER_ENGINE_DEPENDENCIES += gvfs
else
DOCKER_ENGINE_BUILD_TAGS += exclude_graphdriver_vfs
endif

define DOCKER_ENGINE_CONFIGURE_CMDS
	mkdir -p $(DOCKER_ENGINE_GOPATH)/src/github.com/docker
	ln -fs $(@D) $(DOCKER_ENGINE_GOPATH)/src/github.com/docker/docker
	ln -fs $(DOCKER_CONTAINERD_SRCDIR) $(DOCKER_ENGINE_GOPATH)/src/github.com/docker/containerd
	mkdir -p $(DOCKER_ENGINE_GOPATH)/src/github.com/opencontainers
	ln -fs $(RUNC_SRCDIR) $(DOCKER_ENGINE_GOPATH)/src/github.com/opencontainers/runc
	cd $(@D) && \
		GITCOMMIT="unknown" BUILDTIME="$$(date)" VERSION="$(DOCKER_ENGINE_VERSION)" \
		bash ./hack/make/.go-autogen
endef

define DOCKER_ENGINE_BUILD_CLIENT_CMDS
	cd $(@D); $(DOCKER_ENGINE_MAKE_ENV) $(HOST_DIR)/usr/bin/go build -v -o $(@D)/bin/docker -tags "$(DOCKER_ENGINE_BUILD_TAGS)" -ldflags "$(DOCKER_ENGINE_GLDFLAGS)" ./cmd/docker
endef

define DOCKER_ENGINE_BUILD_DAEMON_CMDS
	cd $(@D); $(DOCKER_ENGINE_MAKE_ENV) $(HOST_DIR)/usr/bin/go build -v -o $(@D)/bin/dockerd -tags "$(DOCKER_ENGINE_BUILD_TAGS)" -ldflags "$(DOCKER_ENGINE_GLDFLAGS)" ./cmd/dockerd
endef

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_DAEMON),y)
define DOCKER_ENGINE_BUILD_CMDS
	$(DOCKER_ENGINE_BUILD_CLIENT_CMDS)
	$(DOCKER_ENGINE_BUILD_DAEMON_CMDS)
endef
else
define DOCKER_ENGINE_BUILD_CMDS
	$(DOCKER_ENGINE_BUILD_CLIENT_CMDS)
endef
endif

define DOCKER_ENGINE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/docker $(TARGET_DIR)/usr/bin/docker
	$(INSTALL) -D -m 0755 $(@D)/bin/dockerd $(TARGET_DIR)/usr/bin/dockerd
endef

define DOCKER_ENGINE_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0644 $(@D)/contrib/init/systemd/docker.service \
		$(TARGET_DIR)/usr/lib/systemd/system/docker.service
	$(INSTALL) -D -m 0644 $(@D)/contrib/init/systemd/docker.socket \
		$(TARGET_DIR)/usr/lib/systemd/system/docker.socket
	mkdir -p $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/
	ln -fs ../../../../usr/lib/systemd/system/docker.service \
		$(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/docker.service
endef

define DOCKER_ENGINE_INSTALL_INIT_SYSV
	$(INSTALL) -D -m 755 $(@D)/contrib/init/sysvinit-redhat/docker \
		$(TARGET_DIR)/etc/init.d/S61docker
	$(INSTALL) -D -m 644 $(@D)/contrib/init/sysvinit-redhat/docker.sysconfig \
		$(TARGET_DIR)/etc/sysconfig/docker.sysconfig
endef

define DOCKER_ENGINE_USERS
	- - docker -1 * - - - Docker Application Container Framework
endef

$(eval $(generic-package))
