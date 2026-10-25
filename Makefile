# AudioToys Makefile

SWIFTC = swiftc
SWIFT_FLAGS = -parse-as-library -module-cache-path .cache
SOURCES = $(shell find Sources/AudioToys -name "*.swift")
APP_BUNDLE = AudioToys.app

.PHONY: all build app run demo list play-barber play-study play-nostromo play-meadow play-celestial play-rain play-clockwork clean

all: build app

build:
	@mkdir -p .cache
	$(SWIFTC) $(SWIFT_FLAGS) $(SOURCES) -o audiotoys
	@echo "✅ Built executable: ./audiotoys"

app: build
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS $(APP_BUNDLE)/Contents/Resources
	@cp audiotoys $(APP_BUNDLE)/Contents/MacOS/AudioToys
	@cp -r Resources $(APP_BUNDLE)/Contents/Resources/ 2>/dev/null || true
	@chmod +x $(APP_BUNDLE)/Contents/MacOS/AudioToys
	@echo "✅ Packaged macOS application: $(APP_BUNDLE)"

run: app
	open $(APP_BUNDLE)

demo: build
	./audiotoys demo

list: build
	./audiotoys list

play-barber: build
	./audiotoys play barber-shop

play-study: build
	./audiotoys play tactile-study

play-nostromo: build
	./audiotoys play nostromo

play-meadow: build
	./audiotoys play midnight-meadow

play-celestial: build
	./audiotoys play celestial-orbits

play-rain: build
	./audiotoys play rain-on-skylight

play-clockwork: build
	./audiotoys play clockwork-attic

play-quantum: build
	./audiotoys play quantum-voyage

clean:
	rm -rf audiotoys $(APP_BUNDLE) .cache
