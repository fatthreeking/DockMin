APP_NAME = DockMin
SRC = Sources/main.swift

.PHONY: all build install uninstall clean dmg install.sh uninstall.sh

all: dmg

build: dmg

install:
	@./scripts/install.sh

install.sh: install

uninstall:
	@./scripts/uninstall.sh

uninstall.sh: uninstall

dmg:
	@./scripts/build_dmg.sh

clean:
	@echo "==> Cleaning build artifacts..."
	rm -f $(BIN)
	rm -rf DockMin.app DockMin.dmg DockMin.zip
	@echo "==> Done."
