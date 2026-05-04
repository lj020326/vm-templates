---
name: Packer Best Practices
globs: ["**/*.pkr.hcl", "**/*.hcl"]
alwaysApply: true
description: Standards for Packer templates
---

# Packer Best Practices

- Use modular structure (variables, builders, provisioners, post-processors)
- Prefer `ansible` provisioner with local playbooks when possible
- Make builds reproducible with pinned versions and checksums
- Include clear variable documentation
- Use `http_directory` for kickstart/cloud-init files
- Keep templates easy to fork and customize
