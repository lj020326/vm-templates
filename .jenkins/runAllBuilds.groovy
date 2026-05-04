#!/usr/bin/env groovy

@Library("pipelineAutomationLib")

import com.dettonville.pipeline.utils.logging.LogLevel
import com.dettonville.pipeline.utils.logging.Logger
import com.dettonville.pipeline.utils.JsonUtils

//Logger.init(this, LogLevel.INFO)
Logger log = new Logger(this)

String jobBaseFolder = "${JOB_NAME.substring(0, JOB_NAME.lastIndexOf("/"))}"
log.info("jobBaseFolder=${jobBaseFolder}")

List jobParts = JOB_NAME.split("/")
log.info("jobParts=${jobParts}")
templateEnv = jobParts[-2]
log.info("templateEnv=${templateEnv}")

// Map config = readYaml text: configYmlStr
Map config = [:]
config.logLevel = "DEBUG"

log.info("JENKINS_ENV=${JENKINS_ENV}")

//config.configFile = ".jenkins/vm-templates.${JENKINS_ENV}.yml"
config.configFile = ".jenkins/vm-templates.${templateEnv}.yml"
config.jobBaseFolder = jobBaseFolder

log.info("config=${JsonUtils.printToJsonString(config)}")

runJobs(config)
