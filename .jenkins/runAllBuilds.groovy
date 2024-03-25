#!/usr/bin/env groovy

@Library("pipeline-automation-lib")

import com.dettonville.api.pipeline.utils.logging.LogLevel
import com.dettonville.api.pipeline.utils.logging.Logger
import com.dettonville.api.pipeline.utils.JsonUtils

//Logger.init(this, LogLevel.INFO)
Logger log = new Logger(this)

String jobBaseFolder = "${JOB_NAME.substring(0, JOB_NAME.lastIndexOf("/"))}"
log.info("jobBaseFolder=${jobBaseFolder}")

Map config = readYaml text: configYmlStr

config.configFile = ".jenkins/vm-templates.${JENKINS_ENV}.yml"
config.jobBaseFolder = jobBaseFolder

log.info("config=${JsonUtils.printToJsonString(config)}")

runJobs(config)
