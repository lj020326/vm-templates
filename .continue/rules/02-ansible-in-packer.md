---
name: Ansible in Packer
globs: ["**/*.yml", "**/*.yaml"]
alwaysApply: true
description: Standards for Ansible playbooks used inside Packer
---

# Ansible in Packer Standards

- All playbooks must be fully idempotent
- Use FQCNs
- Minimize inline shell commands — prefer Ansible modules
- Document required variables clearly
- Handle errors gracefully
- Keep playbooks focused and reusable
