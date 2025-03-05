
# Migration of static OS build answer files to dynamic templates

## Motivation for moving to using templates for __OS build answer files__

The motivation for using dynamic templates for __OS build answer files__ includes:

- support for dynamic parameterized options/values to be used in templates instead of hard-coded values 
- support for conditional blocks in __OS build answer files__ based on runtime parameter settings
- enable the moving/conversion of sensitive information (__ssh keys__, __passwords__, etc) to vaulted parameterized variables
- elimination of hard-coded sensitive information in plaintext format in the __OS build answer files__

## State of migration to using templates for __OS build answer files__

The migration to using templates for __OS build answer files__ is in progress.

Currently, the build automation using templates for __OS build answer files__ has been implemented for the following OS platforms:

- Debian
- Ubuntu
- Redhat

The following OS platforms are to be soon implemented and tested using templates for __OS build answer files__:

- CentOS
