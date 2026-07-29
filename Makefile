.PHONY: build-web deploy-web

build-web:
	flutter build web --release --pwa-strategy=none --no-wasm-dry-run

deploy-web: build-web
	firebase deploy --only hosting --project kasir-gen-live
