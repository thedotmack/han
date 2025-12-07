# Quick Security Assessment

> **TL;DR:** ✅ Safe to install for development use. Similar security model to npm packages.

## Is Han Safe?

**YES**, with these important notes:

### What You Should Know

1. **Plugins Run Code** - Like npm packages, plugins can execute commands on your system. This is intentional functionality.

2. **Trust Model** - You're trusting:
   - The Bushido Collective (plugin marketplace maintainer)
   - Plugin authors (official marketplace plugins)
   - Claude Code (the environment)

3. **Official Marketplace Only** - Only install plugins from the official Han marketplace at https://github.com/TheBushidoCollective/han

### Security Strengths

✅ **No known vulnerabilities** in dependencies (verified via npm audit)  
✅ **HTTPS-only** for marketplace downloads  
✅ **Proper command sanitization** to prevent injection attacks  
✅ **Path traversal protection** in file operations  
✅ **Scope isolation** (user/project/local settings)  
✅ **Kill switch** available (`HAN_DISABLE_HOOKS=1`)  
✅ **Comprehensive security documentation**  

### Security Considerations

⚠️ **Arbitrary command execution** - Plugins can run shell commands (by design, like npm scripts)  
⚠️ **No sandboxing** - Hooks run with your user permissions  
⚠️ **Trust required** - Plugin authors must be trustworthy  

### Before Installing

```bash
# Review what you're installing
han plugin list

# Check your configuration
han explain

# Test hooks without executing
han hook test --verbose
```

### If You're Concerned

1. **Review plugin code** - All plugins are open source in the marketplace repo
2. **Use project scope** - Limit plugins to specific projects: `han plugin install --scope project`
3. **Disable hooks temporarily** - Set `HAN_DISABLE_HOOKS=1` in your environment
4. **Audit regularly** - Run `han plugin list` to see what's enabled

## Comparison to Other Tools

| Tool | Arbitrary Code | Curated | Review Process |
|------|---------------|---------|----------------|
| **Han** | Yes | Yes | Manual curation |
| npm packages | Yes | No | None |
| VS Code Extensions | Yes | Yes | Automated |
| Git hooks | Yes | No | None |

## Security Verification

Run the automated security check:

```bash
bash scripts/security-check.sh
```

## Questions?

- 📖 Full analysis: See [SECURITY_REVIEW.md](./SECURITY_REVIEW.md)
- 🔒 Report issues: See [SECURITY.md](./SECURITY.md)
- 💬 Discussion: GitHub Issues

---

**Bottom Line:** Han is as safe as the plugins you install. Stick to the official marketplace, and you're good to go. 🛡️
