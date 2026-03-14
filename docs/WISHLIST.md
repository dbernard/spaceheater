# Wishlist
Things we might like to implement in the future:

- [ ] Quick start command from list view for first HOT codespace (tooltip? something else?)
- [ ] Crontab integration for scheduling codespace pre-warming
- [ ] Config file based configuration
- [ ] Connection overrides (ex: `spaceheater start --ssh ...`)
- [ ] Other overrides like default branch name (ex: `spaceheater start --branch ...`)
- [ ] Better failure handling (failure to create still shows "5-10 minutes" tooltip)

## Temperature System Enhancements
- [ ] Make WARM threshold configurable via environment variable (SPACEHEATER_WARM_DAYS)
- [ ] Add separate HEATING category for Starting/Provisioning codespaces
- [ ] Allow customization of temperature icons via environment variables

## Fuzzy Matching Improvements
- [ ] When multiple codespaces match fuzzy search, use interactive menu instead of auto-selecting first
- [ ] Add option to require exact match for automated scripts

## Performance Optimizations
- [ ] Cache Python date calculations or use GNU date when available
- [ ] Implement more robust column alignment for mixed Unicode/ASCII content
