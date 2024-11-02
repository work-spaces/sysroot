"""
Add Rust
"""

def add_rust():
    """
    Add the Rust toolchain to your sysroot using rustup in the spaces store
    """

    # more binaries https://forge.rust-lang.org/infra/other-installation-methods.html

    macos_x86_64 = {
        "url": "https://static.rust-lang.org/rustup/dist/x86_64-apple-darwin/rustup-init",
        "sha256": "f547d77c32d50d82b8228899b936bf2b3c72ce0a70fb3b364e7fba8891eba781",
        "add_prefix": "sysroot/bin",
        "link": "Hard",
    }

    linux_x86_64 = macos_x86_64 | {
        "url": "https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init",
        "sha256": "6aeece6993e902708983b209d04c0d1dbb14ebb405ddb87def578d41f920f56d",
    }

    windows_x86_64 = macos_x86_64 | {
        "url": "https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe",
        "sha256": "193d6c727e18734edbf7303180657e96e9d5a08432002b4e6c5bbe77c60cb3e8",
    }

    checkout.add_platform_archive(
        rule = {"name": "rustup-init-archive"},
        platforms = {
            "macos-x86_64": macos_x86_64,
            "macos-aarch64": macos_x86_64,
            "linux-x86_64": linux_x86_64,
            "windows-x86_64": windows_x86_64,
        },
    )

    store_path = info.get_path_to_store()
    cargo_path = "{}/cargo/bin".format(store_path)
    rustup_home = "{}/rustup".format(store_path)
    cargo_home = "{}/cargo".format(store_path)

    checkout.update_env(
        rule = {"name": "rust_env"},
        env = {
            "vars": {"RUSTUP_HOME": rustup_home, "CARGO_HOME": cargo_home},
            "paths": [cargo_path],
        },
    )

    cargo_exists = fs.exists(cargo_path)

    run.add_exec(
        rule = {"name": "rustup-init-permissions", "type": "Setup"},
        exec = {
            "command": "chmod",
            "args": ["755", "sysroot/bin/rustup-init"],
        },
    )

    run.add_exec(
        rule = {"name": "rustup-init", "deps": ["rustup-init-permissions"], "type": "Setup"},
        exec = {
            "command": "sysroot/bin/rustup-init",
            "args": ["--version"] if cargo_exists else ["--profile=default", "--no-modify-path", "-y"]
        },
    )

    checkout.update_asset(
        rule = {"name": "vscode_settings"},
        asset = {
            "destination": ".vscode/settings.json",
            "format": "json",
            "value": {
                "rust-analyzer.cargo.buildScripts.invocationStrategy": "once",
                "rust-analyzer.cargo.buildScripts.invocationLocation": "root",
                "rust-analyzer.cargo.buildScripts.overrideCommand": [
                    "cargo",
                    "check",
                    "--quiet",
                    "--message-format=json",
                    "--all-targets",
                    "--keep-going",
                ],
                "rust-analyzer.cargo.targetDir": "target-rust-analyzer",
                "rust-analyzer.check.noDefaultFeatures": True,
                "rust-analyzer.cargo.noDefaultFeatures": True,
                "rust-analyzer.showUnlinkedFileNotification": False,
                "rust-analyzer.imports.granularity.enforce": True,
                "rust-analyzer.imports.granularity.group": "module",
                "rust-analyzer.cargo.buildScripts.enable": True,
                "rust-analyzer.procMacro.attributes.enable": False,
                "rust-analyzer.cargo.extraEnv": {"CARGO_HOME": cargo_home, "RUSTUP_HOME": rustup_home},
            },
        },
    )