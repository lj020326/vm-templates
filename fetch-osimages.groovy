
// ref: https://serverfault.com/questions/987040/running-ansible-playbook-commands-inside-docker-image-using-jenkins-pipeline
pipeline {

    agent {
        label "docker-in-docker"
//        label 'ansible'
    }

//    environment {
//        ANSIBLE_VAULT_PASSWORD = credentials('ANSIBLE_VAULT_PASSWORD')
//    }

    options {
        timeout(time: 60, unit: "MINUTES")
    }

    stages {
        stage('Run Ansible playbook') {
            agent {
                docker {
                    image 'cytopia/ansible:latest'
                    args '-u 0:0'
                    reuseNode true
                }
            }
            steps {
              sh '''
                ansible-playbook \
                  --inventory-file localhost, \
                  --extra-vars ansible_ssh_common_args='"-o StrictHostKeyChecking=no -o ServerAliveInterval=30"' \
                  fetch-osimages.yml
              '''
            }
        }
    }

    post {
        always {
          deleteDir()
        }
    }

}