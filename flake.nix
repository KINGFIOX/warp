{
  description = "Warp macOS aarch64 development environment.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      rust-overlay,
      ...
    }:
    let
      system = "aarch64-darwin";
      overlays = [ rust-overlay.overlays.default ];
      pkgs = import nixpkgs {
        inherit system overlays;
      };
      rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;

      xcodeDeveloperDir = "/Applications/Xcode.app/Contents/Developer";
      xcodeToolchainBin = "${xcodeDeveloperDir}/Toolchains/XcodeDefault.xctoolchain/usr/bin";
      xcodeSdkRoot = "${xcodeDeveloperDir}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk";

      xcrunMetalShim = pkgs.writeShellScriptBin "xcrun" ''
        set -euo pipefail

        find_metal_toolchain_bin() {
          for toolchain in \
            "''${DEVELOPER_DIR:-${xcodeDeveloperDir}}/Toolchains/Metal.xctoolchain" \
            /Library/Developer/Toolchains/Metal.xctoolchain \
            /Volumes/*/Metal.xctoolchain \
            /var/run/com.apple.security.cryptexd/mnt/*/Metal.xctoolchain
          do
            if [ -x "$toolchain/usr/bin/metal" ] && [ -x "$toolchain/usr/bin/metallib" ]; then
              printf '%s\n' "$toolchain/usr/bin"
              return 0
            fi
          done

          return 1
        }

        maybe_run_metal_tool() {
          while [ "$#" -gt 0 ]; do
            case "$1" in
              -sdk|--sdk)
                [ "$#" -ge 2 ] || return 1
                shift 2
                ;;
              -find|--find)
                [ "$#" -ge 2 ] || return 1
                shift
                case "$1" in
                  metal|metallib)
                    if metal_bin="$(find_metal_toolchain_bin)"; then
                      printf '%s/%s\n' "$metal_bin" "$1"
                      return 0
                    fi
                    ;;
                esac
                return 1
                ;;
              metal|metallib)
                tool="$1"
                shift
                if metal_bin="$(find_metal_toolchain_bin)"; then
                  exec "$metal_bin/$tool" "$@"
                fi
                return 1
                ;;
              *)
                return 1
                ;;
            esac
          done

          return 1
        }

        maybe_run_metal_tool "$@" || exec /usr/bin/xcrun "$@"
      '';
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          bashInteractive
          brotli
          cargo-about
          cargo-binstall
          cargo-bundle
          cargo-nextest
          clang-tools
          cmake
          coreutils
          diesel-cli
          file
          findutils
          fish
          git
          git-lfs
          jq
          pkg-config
          protobuf
          python3
          rust-analyzer
          rustToolchain
          unzip
          wgsl-analyzer
          which
          zip
          zsh
        ];

        buildInputs = with pkgs; [
          curl
          expat
          freetype
          libgit2
          libiconv
          openssl
          sqlite
          zlib
        ];

        LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
        PROTOC = "${pkgs.protobuf}/bin/protoc";
        PROTOC_INCLUDE = "${pkgs.protobuf}/include";
        RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";

        shellHook = ''
          export WARP_NIX_DEV_SHELL=1
          export DEVELOPER_DIR="${xcodeDeveloperDir}"
          export SDKROOT="${xcodeSdkRoot}"
          export BINDGEN_EXTRA_CLANG_ARGS="-isysroot $SDKROOT ''${BINDGEN_EXTRA_CLANG_ARGS:-}"

          export CC="${xcodeToolchainBin}/clang"
          export CXX="${xcodeToolchainBin}/clang++"
          export AR="${xcodeToolchainBin}/ar"
          export RANLIB="${xcodeToolchainBin}/ranlib"
          export CARGO_TARGET_AARCH64_APPLE_DARWIN_LINKER="$CC"
          export PATH="${xcrunMetalShim}/bin:${xcodeToolchainBin}:$PATH"

          if [ -z "''${WARP_SKIP_NIX_SHELL_MESSAGE:-}" ]; then
            echo "Warp macOS dev shell (${system})"
            echo "  cargo build -p warp --bin warp-oss"
            echo "  ./script/run"
            echo "  ./script/format"
            echo "  cargo nextest run --no-fail-fast --workspace --exclude command-signatures-v2"
          fi
        '';
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
