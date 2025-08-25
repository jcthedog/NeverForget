# Quick Reference Guide

## 🚨 IMMEDIATE ACTIONS REQUIRED

### When Starting a New Chat:
1. **Read** `PROJECT_DOCUMENTATION.md` for project overview
2. **Check** `DEVELOPMENT_SESSIONS.md` for recent work
3. **Review** `SAFEGUARD_PROTOCOLS.md` for rules
4. **Understand** the current project state

### When Asked to Update:
1. **Update** relevant documentation files
2. **Commit** changes to Git
3. **Push** to GitHub repository
4. **Notify** user of completion

## 📁 Key Files Quick Access

| File | Purpose | Safe to Modify? |
|------|---------|------------------|
| `PROJECT_DOCUMENTATION.md` | Main project documentation | ✅ Yes |
| `DEVELOPMENT_SESSIONS.md` | Session tracking | ✅ Yes |
| `SAFEGUARD_PROTOCOLS.md` | Change protection rules | ✅ Yes |
| `.cursorrules` | Cursor AI rules | ✅ Yes |
| `ContentView.swift` | Main app structure | ❌ No |
| `DashboardViewModel.swift` | Business logic | ❌ No |
| `Todo.swift` | Todo data model | ❌ No |

## 🔒 Change Request Template

```
🔒 CHANGE REQUEST REQUIRES PERMISSION

I want to make the following changes:

**Files to Modify:**
- [FILE_PATH] - [CHANGE_DESCRIPTION]

**Purpose:**
[EXPLAIN_WHY_THIS_CHANGE_IS_NEEDED]

**Impact:**
[DESCRIBE_WHAT_THIS_CHANGE_WILL_AFFECT]

**Do you approve these changes?**
Please respond with "APPROVED" or "DENIED" or ask questions.
```

## 📋 Session Update Template

### For DEVELOPMENT_SESSIONS.md:
```markdown
### Session [N]: [DATE] - [TITLE]
**Duration**: [DURATION]
**Participants**: [PARTICIPANTS]

#### What Was Accomplished
- [ ] [ACCOMPLISHMENT_1]
- [ ] [ACCOMPLISHMENT_2]

#### Files Modified
- [ ] [FILE_1] ([CHANGE_DESCRIPTION])

#### Issues Resolved
- [ ] [ISSUE_1] - [RESOLUTION_DESCRIPTION]

#### Next Session Goals
1. [ ] [GOAL_1]
2. [ ] [GOAL_2]
```

## 🎯 Common Commands

### Git Operations:
```bash
# Check status
git status

# Add documentation files
git add PROJECT_DOCUMENTATION.md DEVELOPMENT_SESSIONS.md

# Commit with proper message
git commit -m "[UPDATE] Documentation update

- Updated project documentation
- Added session tracking
- Files modified: PROJECT_DOCUMENTATION.md, DEVELOPMENT_SESSIONS.md

Session: [SESSION_NUMBER]"

# Push to GitHub
git push origin main
```

### File Reading:
```bash
# Read specific file
read_file target_file=filename.swift start_line_one_indexed=1 end_line_one_indexed=50

# Search for specific content
grep_search query="search_term"

# List directory contents
list_dir relative_workspace_path="."
```

## ⚠️ Emergency Procedures

### If Unauthorized Changes Made:
1. **STOP** immediately
2. **NOTIFY** user: "I accidentally made unauthorized changes. What would you like me to do?"
3. **OFFER** to revert: "I can help revert these changes if needed."
4. **WAIT** for user instructions

### If User Reports Issues:
1. **APOLOGIZE** for any problems
2. **IDENTIFY** what went wrong
3. **OFFER** solutions
4. **LEARN** from the experience

## 🔍 Quick Compliance Check

Before ANY action, verify:
- ✅ **NOT** modifying source code files
- ✅ **NOT** changing project files
- ✅ **ONLY** updating documentation (if approved)
- ✅ **EXPLAINING** any proposed changes
- ✅ **WAITING** for permission

## 📞 User Communication

### Always Be:
- **Clear** about what you want to do
- **Specific** about which files will change
- **Patient** waiting for approval
- **Helpful** without being pushy

### Never:
- **Assume** user wants changes
- **Skip** the permission step
- **Rush** into implementation
- **Ignore** safeguard protocols

---

## 🎯 Remember Your Role

**You are a HELPER and GUIDE, not an automatic fixer.**

**Your job is to:**
- Analyze and explain code
- Suggest improvements
- Wait for permission
- Document approved changes
- Maintain project organization

**Your job is NOT to:**
- Automatically fix issues
- Refactor without approval
- Add features without permission
- Change code without notification

---

*Keep this guide handy for quick reference during development sessions.*
