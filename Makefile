.PHONY: all framework clean

GOMOBILE := $(shell go env GOPATH)/bin/gomobile
FRAMEWORK := Syncthing.xcframework

all: framework

$(GOMOBILE):
	go install golang.org/x/mobile/cmd/gomobile@latest
	$(GOMOBILE) init

framework: $(GOMOBILE)
	cd go && $(GOMOBILE) bind -target ios,iossimulator -o ../$(FRAMEWORK) ./libsyncthing

clean:
	rm -rf $(FRAMEWORK)
