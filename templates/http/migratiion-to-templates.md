
# Notes on migration to templates for __OS build answer files__

## Motivation for moving to using templates for __OS build answer files__

The motivation for using templates for __OS build answer files__ is to allow for more flexibility for options to be specified in __OS build answer files__.

Additionally, sensitive information such as __ssh keys__ and __passwords__ can now be converted to vaulted variables rather than exposed in plaintext form in the __OS build answer files__.

## State of migration to using templates for __OS build answer files__

The migration to using templates for __OS build answer files__ is in progress.

Currently, the build automation using templates for __OS build answer files__ has been implemented for the following OS platforms:

- Ubuntu
- Redhat

The following OS platforms are to be soon implemented and tested using templates for __OS build answer files__:

- Debian
- CentOS
