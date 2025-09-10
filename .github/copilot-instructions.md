# SourcePawn Plugin Development Guide for Advanced Targeting

## Repository Overview

This repository contains the **Advanced Targeting Extended** SourcePawn plugin for SourceMod, a scripting platform for Source engine games. The plugin extends SourceMod's targeting functionality by adding advanced targeting methods for administrative commands, including targeting by admin status, friend relationships, VIP status, and game-specific criteria like zombie infection status.

**Current Version**: 1.5.2 (as of last update)

### Key Features
- Advanced player targeting filters (@admins, @friends, @vips, @mzombies, etc.)
- Integration with multiple SourceMod plugins (VIP Core, ZombieReloaded, PlayerManager)
- Friend system functionality through Steam Web API
- Multi-target command support with descriptive names

## Technical Environment

- **Language**: SourcePawn (.sp files)
- **Platform**: SourceMod 1.11+ (configured for 1.11.0-git6934)
- **Compiler**: SourcePawn compiler (spcomp) via SourceKnight
- **Build System**: SourceKnight 0.2 (configured in `sourceknight.yaml`)
- **CI/CD**: GitHub Actions with automated building and releases

## Project Structure

```
├── .github/
│   └── workflows/ci.yml          # CI/CD pipeline
├── addons/sourcemod/scripting/
│   ├── AdvancedTargeting.sp      # Main plugin source
│   └── include/
│       └── AdvancedTargeting.inc # Native function definitions
├── sourceknight.yaml            # Build configuration and dependencies
└── .gitignore                   # Git ignore rules
```

### Important Files
- **AdvancedTargeting.sp**: Main plugin implementation with targeting filters and commands
- **AdvancedTargeting.inc**: Include file defining native functions for other plugins
- **sourceknight.yaml**: Build configuration defining dependencies and build targets

## Dependencies

The plugin depends on several SourceMod extensions and plugins:

### Core Dependencies (Required)
- **sourcemod**: SourceMod 1.11+ framework
- **multicolors**: Chat color functionality
- **utilshelper**: Utility functions
- **ripext**: HTTP/REST API functionality (for Steam Web API)

### Optional Dependencies (Conditional Compilation)
- **vip_core**: VIP system integration (`#tryinclude <vip_core>`)
- **zombiereloaded**: Zombie game mode support (`#tryinclude <zombiereloaded>`)
- **PlayerManager**: Steam/No-Steam player management (`#tryinclude <PlayerManager>`)
- **Voice**: Voice communication detection (`#tryinclude <Voice>`)

## Build Process

### Local Development
**Note**: SourceKnight is primarily designed for CI environments. For local development:
1. Set up a SourceMod development environment with the SourcePawn compiler (spcomp)
2. Install dependencies manually or use the CI build artifacts
3. Compile: `spcomp -i include_path AdvancedTargeting.sp`

### CI/CD Pipeline (Recommended)
- **Trigger**: Push, PR, or workflow dispatch
- **Build**: Automated via SourceKnight GitHub Action (`maxime1907/action-sourceknight@v1`)
- **Dependencies**: Automatically downloaded and configured by SourceKnight
- **Output**: Built plugins available in GitHub Actions artifacts
- **Release**: Automatic releases on tag push or main branch with `.tar.gz` packages

### Build Configuration
The `sourceknight.yaml` file defines:
- Project dependencies with specific versions
- Source and destination paths for includes
- Build targets and output directories

## Code Style & Standards

### Syntax Requirements
```sourcepawn
#pragma semicolon 1        // Always required
#pragma newdecls required  // Always required
#pragma dynamic 128*1024   // Used for large dynamic arrays
```

### Variable Naming Conventions
- **Global variables**: Prefix with `g_` (e.g., `g_Plugin_ZR`, `g_FriendsArray`)
- **Function names**: PascalCase (e.g., `OnPluginStart`, `Filter_Admin`)
- **Local variables**: camelCase (e.g., `sSteam32ID`, `iClientCount`)
- **Constants**: UPPER_CASE (e.g., `TAG_COLOR`, `MAXPLAYERS`)

### Memory Management
- Use `delete` for cleanup without null checks: `delete g_FriendsArray[client];`
- Avoid `.Clear()` for StringMap/ArrayList - use `delete` and recreate instead
- Properly handle array initialization: `Handle g_FriendsArray[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};`

### Plugin Structure Patterns
```sourcepawn
// Standard plugin initialization
public void OnPluginStart()
{
    // Register commands with descriptions
    RegConsoleCmd("sm_command", Command_Handler, "Command description");
    
    // Add targeting filters
    AddMultiTargetFilter("@target", Filter_Function, "Description", false);
    
    // Late load handling
    if(g_bLateLoad) { /* handle late load */ }
}

// Proper cleanup
public void OnPluginEnd()
{
    // Remove filters
    RemoveMultiTargetFilter("@target", Filter_Function);
    
    // Clean up global variables
    g_sVariable = "\0";
}
```

### Conditional Compilation
Use `#if defined` blocks for optional dependencies:
```sourcepawn
#if defined _zr_included
    // ZombieReloaded specific code
    HookEvent("round_start", OnRoundStart, EventHookMode_Pre);
#endif
```

## Common Development Patterns

### Multi-Target Filter Implementation
```sourcepawn
public bool Filter_Example(const char[] sPattern, Handle hClients)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && /* condition */)
        {
            PushArrayCell(hClients, i);
        }
    }
    return true;
}
```

### Native Function Definition
```sourcepawn
// In .inc file
native int FunctionName(int param1, const char[] param2);

// In .sp file
public int Native_FunctionName(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    // Implementation
    return result;
}
```

### Error Handling
- Always validate client indices: `if(IsClientInGame(client) && !IsFakeClient(client))`
- Check authorization: `if(IsClientAuthorized(client))`
- Handle late loading scenarios in `OnPluginStart()`

## Testing & Debugging

### Manual Testing
1. Load plugin on a test server
2. Test targeting commands: `sm_admins`, `sm_friends`, `sm_vips`
3. Test multi-target filters: `sm_kick @admins`, `sm_slay @friends`
4. Verify conditional features based on loaded plugins

### Common Issues
- **Memory leaks**: Ensure proper cleanup in `OnPluginEnd()`
- **Late load problems**: Handle client state in late load scenarios
- **Plugin conflicts**: Check library availability with `OnLibraryAdded()`

## Performance Considerations

### Optimization Guidelines
- Cache frequently accessed data (friend lists, admin status)
- Minimize operations in targeting filters (called frequently)
- Use efficient data structures (StringMap over arrays when appropriate)
- Avoid unnecessary string operations in loops

### Resource Management
- Friends array uses Handle storage per client for Steam Web API results
- Global variables track plugin availability to avoid repeated checks
- Event hooks only registered when required plugins are available

## Integration Points

### Steam Web API
- Utilizes RipExt extension for HTTP requests
- Manages friend relationships through Steam Web API calls
- Caches friend data in per-client Handle arrays

### Plugin Dependencies
- **VIP Core**: Adds @vips targeting for VIP players
- **ZombieReloaded**: Adds @mzombies for mother zombie targeting
- **PlayerManager**: Adds @steam/@nosteam targeting filters
- **Voice**: Adds @talking for players using voice chat

## Common Commands for Development

```bash
# View current plugin version
grep "version.*=" addons/sourcemod/scripting/AdvancedTargeting.sp

# Check plugin syntax (if spcomp is available locally)
spcomp -i addons/sourcemod/scripting/include addons/sourcemod/scripting/AdvancedTargeting.sp

# Check CI build status via GitHub Actions
# (Recommended approach for validating builds)

# View build configuration
cat sourceknight.yaml

# Check dependency versions
grep -A 20 "dependencies:" sourceknight.yaml
```

## Troubleshooting

### Build Issues
- **Missing dependencies**: Check `sourceknight.yaml` dependency definitions
- **Include errors**: Verify optional includes use `#tryinclude`
- **Version conflicts**: Ensure SourceMod version compatibility

### Runtime Issues
- **Plugin load failures**: Check SourceMod error logs for missing dependencies
- **Targeting not working**: Verify filters are properly registered in `OnPluginStart()`
- **Memory errors**: Review Handle management and cleanup procedures

## Release Process

1. Update version in plugin info block (line ~41 in AdvancedTargeting.sp):
   ```sourcepawn
   version = "1.5.3",  // Update this
   ```
2. Commit changes to main branch
3. Create and push tag: `git tag v1.5.3 && git push origin v1.5.3`
4. GitHub Actions automatically builds and creates release with `.tar.gz` package
5. Monitor CI build at: https://github.com/srcdslab/sm-plugin-AdvancedTargeting/actions
6. Download artifacts from release page for manual distribution

### Version History
- **1.5.2**: Current stable version
- Previous versions available in GitHub releases

This guide should help you efficiently work with this SourcePawn plugin codebase while maintaining code quality and following established patterns.