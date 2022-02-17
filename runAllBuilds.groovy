#!/usr/bin/env groovy

@Library("pipeline-automation-lib")

import com.dettonville.api.pipeline.utils.logging.LogLevel
import com.dettonville.api.pipeline.utils.logging.Logger
import com.dettonville.api.pipeline.utils.JsonUtils

//Logger.init(this, LogLevel.INFO)
Logger log = new Logger(this)

String jobFolder = "${JOB_NAME.substring(0, JOB_NAME.lastIndexOf("/"))}"
log.info("jobFolder=${jobFolder}")

String configYmlStr="""
--- 
continueIfFailed: false
alwaysEmailList: ljohnson@dettonville.org
runInParallel: true
logLevel: DEBUG

jobList: 
- stage: Build Templates
  jobs: 
    - job: "${jobFolder}/centos7"
    - job: "${jobFolder}/centos8"
    - job: "${jobFolder}/ubuntu18"
    - job: "${jobFolder}/ubuntu20"
"""

Map config = readYaml text: configYmlStr
//Map config=configSettings

log.info("config=${JsonUtils.printToJsonString(config)}")

runJobs(config)
