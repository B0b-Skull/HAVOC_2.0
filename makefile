ifndef VERBOSE
.SILENT:
endif

VERSION_COMMIT ?= $(shell git rev-parse HEAD 2>/dev/null || echo unknown)

# main build target. compiles the teamserver and client
all: ts-build client-build

# teamserver building target
ts-build:
	@ echo "[*] building teamserver"
	@ ./teamserver/Install.sh
	@ cd teamserver; GO111MODULE="on" go build -ldflags="-s -w -X cmd.VersionCommit=$(VERSION_COMMIT)" -o ../havoc main.go
	@ if command -v setcap >/dev/null 2>&1; then setcap 'cap_net_bind_service=+ep' havoc || true; fi # this allows you to run the server as a regular user

dev-ts-compile:
	@ echo "[*] compile teamserver"
	@ cd teamserver; GO111MODULE="on" go build -ldflags="-s -w -X cmd.VersionCommit=$(VERSION_COMMIT)" -o ../havoc main.go 

ts-cleanup: 
	@ echo "[*] teamserver cleanup"
	@ rm -rf ./teamserver/bin
	@ rm -rf ./data/loot
	@ rm -rf ./data/x86_64-w64-mingw32-cross 
	@ rm -rf ./data/havoc.db
	@ rm -rf ./data/server.*
	@ rm -rf ./teamserver/.idea
	@ rm -rf ./havoc

# client building and cleanup targets 
client-build: 
	@ echo "[*] building client"
	@ bash scripts/hydrate-client-deps.sh
	@ rm -rf client/Build
	@ mkdir client/Build; cd client/Build; cmake .. -DPython3_EXECUTABLE=$$(which python3)
	@ if [ -d "client/Modules" ]; then echo "Modules installed"; else git clone --depth=1 https://github.com/HavocFramework/Modules client/Modules; fi
	@ cmake --build client/Build --parallel

client-cleanup:
	@ echo "[*] client cleanup"
	@ rm -rf ./client/Build
	@ rm -rf ./client/Bin/*
	@ rm -rf ./client/Data/database.db
	@ rm -rf ./client/.idea
	@ rm -rf ./client/cmake-build-debug
	@ rm -rf ./client/Havoc
	@ rm -rf ./client/Modules


# cleanup target 
clean: ts-cleanup client-cleanup
	@ rm -rf ./data/*.db
	@ rm -rf payloads/Demon/.idea
