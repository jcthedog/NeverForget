# Safeguard Protocols for File Changes

## ⚠️ CRITICAL: File Change Protection Rules

### Rule 1: NO AUTOMATIC FILE CHANGES
**NEVER make any file changes without explicit user permission and notification.**

### Rule 2: Change Request Protocol
Before making ANY file changes, you MUST:
1. **Notify the user** of what changes you want to make
2. **Wait for explicit permission** before proceeding
3. **Explain the purpose** of each change
4. **List all files** that will be modified
5. **Provide a summary** of the impact

### Rule 3: Change Notification Format
When requesting permission to make changes, use this format:

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

## File Change Categories

### 🟢 Safe Operations (No Permission Required)
- Reading files for analysis
- Searching through codebase
- Creating new documentation files
- Suggesting code improvements (without implementing)
- Explaining code functionality

### 🟡 Operations Requiring Permission
- **ANY** modification to existing source code files
- **ANY** modification to configuration files
- **ANY** modification to project files
- **ANY** deletion of files
- **ANY** file renaming or moving

### 🔴 Forbidden Operations
- Automatic code fixes without permission
- Refactoring without explicit approval
- Adding new dependencies without approval
- Changing project structure without approval
- Implementing features without approval

## Specific File Protections

### Protected Source Files
```
*.swift          - All Swift source code files
*.plist          - Configuration files
*.xcodeproj/*    - Xcode project files
*.xcworkspace/*  - Xcode workspace files
*.md             - README and documentation (except new ones)
.gitignore       - Git ignore file
```

### Protected Directories
```
Never Forget/           - Main app source code
Never Forget.xcodeproj/ - Xcode project files
Never ForgetTests/      - Test files
Never ForgetUITests/    - UI test files
```

### Safe to Create/Modify
```
PROJECT_DOCUMENTATION.md     - Main project documentation
DEVELOPMENT_SESSIONS.md      - Session tracking
SAFEGUARD_PROTOCOLS.md      - This file
Cursor Chats/               - Chat history (read-only)
```

## Permission Request Examples

### Example 1: Bug Fix
```
🔒 CHANGE REQUEST REQUIRES PERMISSION

I want to make the following changes:

**Files to Modify:**
- DashboardViewModel.swift - Fix memory leak in alarm management

**Purpose:**
Resolve a potential memory leak where alarm observers aren't properly removed

**Impact:**
- Fixes memory leak
- Improves app stability
- No user-facing changes

**Do you approve these changes?**
Please respond with "APPROVED" or "DENIED" or ask questions.
```

### Example 2: Feature Addition
```
🔒 CHANGE REQUEST REQUIRES PERMISSION

I want to make the following changes:

**Files to Modify:**
- Todo.swift - Add new priority level "Critical"
- DashboardView.swift - Update priority picker UI
- DashboardViewModel.swift - Handle new priority logic

**Purpose:**
Add a new "Critical" priority level above "High" for urgent tasks

**Impact:**
- New priority option in todo creation
- Updated UI components
- Enhanced task prioritization

**Do you approve these changes?**
Please respond with "APPROVED" or "DENIED" or ask questions.
```

## Emergency Procedures

### If You Accidentally Make Changes
1. **Immediately stop** all operations
2. **Notify the user** of what happened
3. **Offer to revert** the changes
4. **Wait for instructions** before proceeding

### If User Reports Unwanted Changes
1. **Apologize** for the unauthorized change
2. **Identify** what was changed
3. **Offer to revert** immediately
4. **Review** safeguard protocols to prevent recurrence

## Documentation Updates

### When to Update Documentation
- **ALWAYS** update documentation after approved changes
- **NEVER** update documentation for unauthorized changes
- **Track** all changes in DEVELOPMENT_SESSIONS.md

### Documentation Update Protocol
1. Update PROJECT_DOCUMENTATION.md with changes
2. Update DEVELOPMENT_SESSIONS.md with session details
3. Commit documentation changes to Git
4. Push to GitHub repository

## Git Workflow Safeguards

### Before Committing
1. **Verify** all changes were approved
2. **Check** no unauthorized files were modified
3. **Review** changes match approved scope
4. **Test** functionality if applicable

### Commit Message Format
```
[FEATURE/FIX/REFACTOR] Brief description

- Detailed change 1
- Detailed change 2
- Files modified: [LIST_FILES]

Approved by: [USER_NAME]
Session: [SESSION_NUMBER]
```

## User Communication Guidelines

### Always Be Clear About
- What you want to change
- Why the change is needed
- What the impact will be
- What files will be affected
- That you're waiting for permission

### Never Assume
- User wants automatic fixes
- User understands technical details
- User approves of changes
- Changes are "obvious" improvements

## Compliance Monitoring

### Self-Check Questions
Before making ANY change, ask yourself:
1. ✅ Have I explained what I want to change?
2. ✅ Have I listed all files that will be modified?
3. ✅ Have I explained why the change is needed?
4. ✅ Have I received explicit permission?
5. ✅ Am I only changing what was approved?

### If Answer is "No" to Any Question
**STOP and ask for permission first.**

---

## Summary

**REMEMBER: When in doubt, ASK FIRST. It's better to ask permission than to make unauthorized changes.**

**Your primary role is to HELP and GUIDE, not to automatically fix or change things.**

**Every file change requires explicit user approval. No exceptions.**
