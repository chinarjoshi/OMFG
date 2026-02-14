.PHONY: all framework clean build deploy

GOMOBILE := $(shell go env GOPATH)/bin/gomobile
FRAMEWORK := Syncthing.xcframework
DEVICE := 00008140-001171600A98801C
SCHEME := OMFG
DERIVED_DATA := $(shell ls -d ~/Library/Developer/Xcode/DerivedData/omfg-* 2>/dev/null | head -1)
APP := $(DERIVED_DATA)/Build/Products/Debug-iphoneos/OMFG.app

all: framework

$(GOMOBILE):
	go install golang.org/x/mobile/cmd/gomobile@latest
	$(GOMOBILE) init

framework: $(GOMOBILE)
	cd go && $(GOMOBILE) bind -target ios,iossimulator -o ../$(FRAMEWORK) ./libsyncthing

build:
	xcodebuild -project OMFG.xcodeproj -scheme $(SCHEME) -destination 'id=$(DEVICE)' -allowProvisioningUpdates -quiet

deploy: build
	xcrun devicectl device install app --device $(DEVICE) $(APP)

clean:
	rm -rf $(FRAMEWORK) $(DERIVED_DATA)
