#!/usr/bin/env bash

## source: https://github.com/kvz/json2hcl

## Does not work when testing
## >
## > ljohnson@Lees-MBP:[templates](main)$ json2hcl common-vars.vars.json
## > fatal error: runtime: bsdthread_register error
## >
## > runtime stack:
## > runtime.throw(0x126b3b, 0x21)
## > 	/home/travis/.gimme/versions/go1.7.linux.amd64/src/runtime/panic.go:566 +0x95 fp=0x7ff7bfefe260 sp=0x7ff7bfefe240
## > runtime.goenvs()
## > 	/home/travis/.gimme/versions/go1.7.linux.amd64/src/runtime/os_darwin.go:88 +0xa0 fp=0x7ff7bfefe290 sp=0x7ff7bfefe260
## > runtime.schedinit()
## > 	/home/travis/.gimme/versions/go1.7.linux.amd64/src/runtime/proc.go:450 +0x9c fp=0x7ff7bfefe2d0 sp=0x7ff7bfefe290
## > runtime.rt0_go(0x7ff7bfefe300, 0x2, 0x7ff7bfefe300, 0x1000, 0x2, 0x7ff7bfefe728, 0x7ff7bfefe731, 0x0, 0x7ff7bfefe747, 0x7ff7bfefe771, ...)
## > 	/home/travis/.gimme/versions/go1.7.linux.amd64/src/runtime/asm_amd64.s:145 +0x14f fp=0x7ff7bfefe2d8 sp=0x7ff7bfefe2d0
## >
## >

## INSTEAD just use `packer hcl2_upgrade`
##
## Important: Unlike legacy JSON templates the input variables within a variable definitions file must be declared via
## a variables block within a standard HCL2 template file *.pkr.hcl before it can be assigned a value.
## Failure to do so will result in an unknown variable error during Packer's runtime.
##
## ref: https://developer.hashicorp.com/packer/docs/templates/hcl_templates/variables
##
## >
## > ljohnson@Lees-MBP:[templates](main)$ packer hcl2_upgrade -with-annotations common-vars.vars.json
## > Ignoring following initialization error: <nil>: ; 1 error occurred:
## > 	* at least one builder must be defined
## >
## >
## > Successfully created common-vars.vars.json.pkr.hcl. Exit 0
## >
## >

## OSX install process
curl -SsL -o /tmp/json2hcl https://github.com/kvz/json2hcl/releases/download/v0.0.6/json2hcl_v0.0.6_darwin_amd64 \
  && sudo cp /tmp/json2hcl /usr/local/bin/json2hcl \
  && sudo chmod 755 /usr/local/bin/json2hcl \
  && json2hcl -version
