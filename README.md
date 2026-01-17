# vfox-dotnet

A [vfox](https://github.com/version-fox/vfox) / [mise](https://mise.jdx.dev) plugin for managing [.NET SDK](https://dotnet.microsoft.com/) versions.

## Features

- **Dynamic version fetching**: Automatically fetches available versions from Microsoft's official API
- **Always up-to-date**: No static version list to maintain
- **Supports all .NET versions**: Including previews, LTS, and STS releases
- **Cross-platform**: Works on Linux, macOS, and Windows
- **Legacy file support**: Reads version from `global.json`

## Installation

### With mise

```bash
mise install dotnet@latest
mise install dotnet@9.0.309
mise install dotnet@8.0.404
```

### With vfox

```bash
vfox add dotnet
vfox install dotnet@latest
```

## Usage

```bash
# List all available versions
mise list-all dotnet

# Install a specific version
mise install dotnet@9.0.309

# Set global version
mise use -g dotnet@9.0.309

# Set local version (creates .mise.toml)
mise use dotnet@8.0.404
```

## Environment Variables

This plugin sets the following environment variables:

- `PATH` - Adds the .NET SDK directory to PATH
- `DOTNET_ROOT` - Points to the .NET SDK installation directory

## global.json Support

The plugin automatically reads `.NET SDK` version from `global.json` files:

```json
{
  "sdk": {
    "version": "8.0.100"
  }
}
```

## How It Works

This plugin fetches version information directly from Microsoft's official release metadata API:

- [releases-index.json](https://builds.dotnet.microsoft.com/dotnet/release-metadata/releases-index.json) - Index of all .NET channels
- Per-channel release data (e.g., `10.0/releases.json`, `9.0/releases.json`)

Installation uses Microsoft's official `dotnet-install.sh` (or `dotnet-install.ps1` on Windows) script.

## License

MIT License - see [LICENSE](LICENSE) for details.
