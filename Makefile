include .env

GODOT_URL=https://downloads.godotengine.org/?version=${GODOT_VERSION}&flavor=stable&slug=linux.x86_64.zip&platform=linux.64
# GODOT_ZIP=build/godot.zip
# GODOT_DIR=build/godot
# GODOT_PATH=${GODOT_DIR}/Godot_v${GODOT_VERSION}-stable_linux.x86_64
# PCK_PATH=build/cache_link.pck

.PHONY: all clean copy_src copy_export deploy

all: copy_src deploy

clean:
	rm -rf ./build

copy_src:
	rm -rf src
	mkdir -p src
	while IFS= read -r item; do \
		[ -z "$$item" ] && continue; \
		mkdir -p "src/$$(dirname "$$item")"; \
		cp -r "${PROJECT_PATH}/$$item" "src/$$item"; \
	done < export-list.txt

copy_export: build
	cp ${PROJECT_PATH}/cache-link.pck build/

deploy: copy_export
	mkdir -p "${GAME_PATH}/mods"
	rm -f "${GAME_PATH}/mods/cache-link.pck"
	cp build/cache-link.pck "${GAME_PATH}/mods/"

build:
	mkdir -p build

# install_godot: ${GODOT_PATH}

# ${GODOT_ZIP}:
# 	mkdir -p build
# 	curl -L -o "${GODOT_ZIP}" "${GODOT_URL}"

# ${GODOT_PATH}: ${GODOT_ZIP}
# 	mkdir -p "${GODOT_DIR}"
# 	unzip -oq "${GODOT_ZIP}" -d "${GODOT_DIR}"
# 	touch "${GODOT_PATH}"

# load_full_src:
# 	rm -rf build/full_src
# 	mkdir -p build/full_src
# 	git -C "$(PROJECT_PATH)" ls-files -co --exclude-standard | while IFS= read -r item; do \
# 		[ -z "$$item" ] && continue; \
# 		mkdir -p "build/full_src/$$(dirname "$$item")"; \
# 		cp -r "$(PROJECT_PATH)/$$item" "build/full_src/$$item"; \
# 	done

# build: ${GODOT_PATH} load_src load_full_src
# 	rm -f build/cache_link.pck
# 	"${GODOT_PATH}" --headless --path build/full_src --export-pack "Windows Desktop" "../cache_link.pck"

# deploy: build
# 	mkdir -p "${GAME_PATH}/mods"
# 	cp build/cache_link.pck "${GAME_PATH}/mods/"
