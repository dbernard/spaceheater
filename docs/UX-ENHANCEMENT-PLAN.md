# 🎨 Spaceheater CLI UX Enhancement Plan

## Executive Summary

This document outlines a comprehensive UX enhancement plan for the Spaceheater CLI tool. The goal is to create a sleek, visually appealing, and accessible command-line interface while maintaining portability and lightweight design principles.

## Current State Analysis

### Strengths
- ✅ Color-coded output with ANSI codes
- ✅ Clear status indicators
- ✅ Tabular data display
- ✅ Human-readable timestamps
- ✅ Single-file bash implementation (portable)
- ✅ No external dependencies for core functionality

### Areas for Enhancement
- Basic text-based tables could be more visually appealing
- Limited visual hierarchy in output
- No interactive selection menus
- Progress indicators could be more informative
- Error messages could provide more actionable guidance
- No accessibility options for users with visual impairments

## Proposed Enhancements

### 1. Enhanced Visual Design System

#### Box-Drawing Characters for Tables
Transform current space-delimited tables into visually appealing box-drawn tables:

**Current:**
```
✓ Available  ✔  fuzzy-umbrella      main         [clean]            (0h ago)
○ Shutdown   ●  organic-sniffle     my-feature   [uncommitted, 2↑]  (1h ago)
```

**Enhanced:**
```
┌─────────┬─────────────────────┬──────────┬──────────────────────┬───────────┐
│ Status  │ Name                │ Branch   │ Git Status           │ Created   │
├─────────┼─────────────────────┼──────────┼──────────────────────┼───────────┤
│ ● Ready │ fuzzy-umbrella      │ main     │ ✓ Clean              │ 2m ago    │
│ ○ Built │ organic-sniffle     │ feature  │ ⚠ 2 uncommitted, 1↑  │ 1h ago    │
└─────────┴─────────────────────┴──────────┴──────────────────────┴───────────┘
```

#### Unicode Icons with ASCII Fallbacks
- Primary: Unicode symbols for modern terminals
- Fallback: ASCII characters for compatibility
- Auto-detection of terminal capabilities

#### Branded Headers
```
╭─────────────────────────────────────────────────────────────────╮
│ 🔥 SPACEHEATER  │  3 codespaces for owner/repo                 │
╰─────────────────────────────────────────────────────────────────╯
```

### 2. Interactive Selection Menus

When running commands without specific targets (e.g., `spaceheater start`), provide interactive selection:

```
╭──────────────────────────────────────────────────────────────────╮
│ 🚀 Select a codespace to start:                                 │
╰──────────────────────────────────────────────────────────────────╯

  ▶ fuzzy-umbrella    [main]     ✓ Clean              Ready to go!
    organic-sniffle   [feature]  ⚠ Has changes        May need sync
    sturdy-capybara   [main]     ⚠ Behind remote      Needs pull

Use ↑/↓ arrows to navigate, Enter to select, q to quit
```

### 3. Enhanced Progress Indicators

#### Animated Spinners
```
Creating codespaces [2/3] ⠙ Building organic-sniffle...
```

#### Progress Bars
```
Progress: ████████████░░░░░░░░  60% │ Est. 2m remaining
```

#### Detailed Status Updates
```
├─ [✓] fuzzy-umbrella    (completed in 45s)
├─ [⠙] organic-sniffle   (building... 30s)
└─ [⠁] sturdy-capybara   (queued)
```

### 4. Rich Status Dashboard

Transform the `config` command output into a visually rich dashboard:

```
╭─────────────────────────────────────────────────────────────────────╮
│                      🔥 SPACEHEATER CONFIG                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  📦 Repository    owner/repo                     ✓ Auto-detected   │
│  🌿 Branch        main                           ✓ Active          │
│  💻 Machine       4-core, 8GB RAM                ✓ From devcontainer│
│  🌍 Region        West Europe                    ✓ Optimized       │
│  ⏱  Idle Timeout  30 minutes                     • GitHub default  │
│  📅 Retention     7 days                         • Org policy      │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│ 💡 Tip: Export SPACEHEATER_MACHINE=premiumLinux for more power     │
╰─────────────────────────────────────────────────────────────────────╯
```

### 5. Improved Error & Success Messages

#### Success Messages with Context
```
╭─────────────────────────────────────────────────────────────────────╮
│ ✨ SUCCESS!                                                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   Created 3 codespaces successfully!                               │
│                                                                     │
│   🎯 Next steps:                                                   │
│   • Wait ~5-10 minutes for full build                              │
│   • Run 'spaceheater list' to check status                         │
│   • Run 'spaceheater start' when ready                             │
│                                                                     │
╰─────────────────────────────────────────────────────────────────────╯
```

#### Error Messages with Solutions
```
╭─────────────────────────────────────────────────────────────────────╮
│ ❌ ERROR: Failed to create codespace                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   Reason: Codespace limit reached (max 5 per user)                 │
│                                                                     │
│   💡 Try:                                                          │
│   • Run 'spaceheater clean' to remove old codespaces               │
│   • Delete unused codespaces: 'spaceheater delete <name>'          │
│   • Check your limits: 'gh codespace list'                         │
│                                                                     │
╰─────────────────────────────────────────────────────────────────────╯
```

### 6. Accessibility Features

#### Environment Variables
- `NO_COLOR` - Disable all color output
- `SPACEHEATER_SIMPLE_UI` - ASCII-only mode for screen readers
- `SPACEHEATER_HIGH_CONTRAST` - High contrast color scheme
- `SPACEHEATER_UI_STYLE` - Choose between 'fancy', 'simple', or 'plain'

#### Screen Reader Support
- Semantic output structure with clear headers
- Alternative text for visual elements
- Structured data output mode for parsing

#### Terminal Adaptation
- Automatic terminal width detection
- Responsive table formatting
- Graceful degradation for narrow terminals

### 7. Smart Terminal Adaptation

#### Capability Detection
```bash
# Detect Unicode support
can_use_unicode() {
    [[ "${LANG:-}" == *UTF-8* ]] && [[ "${TERM:-}" != "linux" ]]
}

# Detect color depth
get_color_depth() {
    if [[ -n "${COLORTERM:-}" ]]; then
        echo "truecolor"
    elif [[ "${TERM:-}" == *256color* ]]; then
        echo "256"
    else
        echo "16"
    fi
}

# Detect terminal width
get_terminal_width() {
    tput cols 2>/dev/null || echo 80
}
```

### 8. Enhanced Help System

#### Structured Help with Examples
```
╭─────────────────────────────────────────────────────────────────────╮
│ 🔥 SPACEHEATER - Pre-warm GitHub Codespaces for instant startup    │
╰─────────────────────────────────────────────────────────────────────╯

COMMANDS
────────
  create <count>     Create pre-warmed codespaces (max 3)
  list, ls           Show all codespaces with status
  start [name]       Start a codespace (auto-selects if none specified)
  stop [name]        Stop a running codespace
  clean [days]       Delete old codespaces (default: 7 days)
  delete <name>      Delete a specific codespace
  config             Show configuration
  help               Show this help

EXAMPLES
────────
  $ spaceheater create 2      # Create 2 pre-warmed codespaces
  $ spaceheater list           # See all your codespaces
  $ spaceheater start          # Start best available codespace
  $ spaceheater clean 30       # Clean codespaces older than 30 days

QUICK START
───────────
  1. Run 'spaceheater create 1' to create your first codespace
  2. Wait 5-10 minutes for it to build
  3. Run 'spaceheater start' to connect instantly!
```

## Implementation Plan

### ✅ Phase 1: Core Visual Enhancement (Priority: High) - **COMPLETED**

**Completion Date:** 2026-03-13

**What Was Implemented:**
1. ✅ **Terminal Capability Detection**
   - Unicode detection based on LANG and TERM
   - NO_COLOR environment variable support
   - SPACEHEATER_UI_STYLE modes (plain/simple)
   - Automatic fallback system

2. ✅ **Icon System with Unicode/ASCII Fallbacks**
   - Complete icon set for all UI elements (brand, status, git, config)
   - Automatic Unicode/ASCII switching based on terminal capabilities
   - Icons: 🔥 ✨ ❌ ⚠️ 💡 ● ○ ⟳ ✓ ✗ ✔ ↑ ↓ → 📦 🌿 💻 🌍 ⏱ 📅 🎯
   - ASCII fallbacks: * [OK] [X] [!] [i] o > + x ^ v [R] [B] [M] [L] [T] [D] =>

3. ✅ **Enhanced Color Palette**
   - Consistent color scheme across all commands
   - Bright blue for visibility on dark terminals
   - DIM and BOLD text for visual hierarchy
   - Full NO_COLOR compliance for accessibility

4. ✅ **Updated All Commands**
   - list: Branded header with elegant separators
   - config: Icon-based configuration display
   - version: Styled version information
   - help: Clean, colorized command reference
   - All messages use appropriate icons and colors

**Design Decisions:**
- Avoided complex table alignments per requirements
- Used simple row-based displays with clean separators
- Maintained zero external dependencies
- Progressive enhancement approach

### Phase 2: Interactive Features (Priority: Medium)
1. **Enhanced Progress Indicators**
   - Add spinner animations
   - Implement progress bars
   - Create status tracking system

2. **Responsive Table Formatting**
   - Dynamic column width calculation
   - Terminal width adaptation
   - Text wrapping for narrow terminals

### Phase 3: Accessibility & Polish (Priority: High)
1. **Accessibility Modes**
   - Implement NO_COLOR support
   - Add screen reader mode
   - Create high contrast theme

2. **Terminal Width Adaptation**
   - Responsive layout system
   - Graceful degradation
   - Mobile terminal support

3. **Enhanced Error Messages**
   - Contextual help system
   - Solution suggestions
   - Error code system

### Phase 4: Testing & Refinement
1. **Cross-Terminal Testing**
   - iTerm2
   - Terminal.app
   - Windows Terminal
   - Linux terminals (gnome-terminal, konsole)
   - SSH sessions

2. **Accessibility Validation**
   - Screen reader testing
   - Color blindness simulation
   - Keyboard navigation

3. **Performance Optimization**
   - Minimize API calls
   - Optimize rendering
   - Cache terminal capabilities

## Technical Specifications

### Design Principles
1. **Progressive Enhancement** - Start with basic functionality, enhance based on capabilities
2. **Backwards Compatibility** - All existing functionality must continue to work
3. **Zero Dependencies** - Maintain pure bash implementation
4. **Performance First** - No noticeable performance impact
5. **Accessibility by Default** - Consider all users from the start

### Key Functions to Implement

```bash
# UI Component Functions
ui_header()              # Draw branded header
ui_box()                 # Draw message box
ui_table()               # Render formatted table
ui_progress()            # Show progress indicator
ui_spinner()             # Animated spinner
ui_select_menu()         # Interactive selection

# Terminal Detection
detect_unicode()         # Check Unicode support
detect_colors()          # Determine color capability
detect_width()           # Get terminal width
detect_interactive()     # Check if interactive session

# Formatting Helpers
format_status()          # Format status with icons
format_git_status()      # Format git information
format_time_ago()        # Human-readable timestamps
format_error()           # Structured error messages
format_success()         # Success message formatting

# Accessibility
apply_theme()            # Apply color theme
strip_formatting()       # Remove all formatting
screen_reader_output()   # Structured output for readers
```

### Configuration Options

New environment variables to support customization:
- `SPACEHEATER_UI_STYLE` - 'fancy', 'simple', 'plain'
- `SPACEHEATER_THEME` - 'default', 'high-contrast', 'dark', 'light'
- `SPACEHEATER_SPINNER` - Spinner style preference
- `SPACEHEATER_ICONS` - 'unicode', 'ascii', 'none'
- `NO_COLOR` - Standard no-color mode
- `TERM` - Respect terminal capabilities

## Success Metrics

1. **User Experience**
   - Improved readability of output
   - Faster task completion through interactive menus
   - Reduced errors through better guidance

2. **Accessibility**
   - Full functionality with screen readers
   - Support for color-blind users
   - Works in all terminal environments

3. **Performance**
   - No performance degradation
   - Responsive UI updates
   - Efficient rendering

4. **Adoption**
   - Positive user feedback
   - Increased usage
   - Community contributions

## Rollout Strategy

1. **Beta Testing** - Optional UI flag for early adopters
2. **Gradual Rollout** - Progressive enhancement based on feedback
3. **Documentation** - Update docs with new features
4. **Community Feedback** - Iterate based on user input

## Conclusion

This enhancement plan transforms Spaceheater from a functional CLI tool into a delightful, accessible, and professional command-line experience while maintaining its core principles of simplicity and portability.