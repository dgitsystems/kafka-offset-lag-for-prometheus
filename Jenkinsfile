pipeline {
    agent any

    stages {
        stage('Prepare') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'master') {
                        versionNumber = VersionNumber versionNumberString: '${BUILD_DATE_FORMATTED, "yy.MM"}.${BUILDS_THIS_MONTH}', versionPrefix: '', worstResultForIncrement: 'SUCCESS'
                        currentBuild.displayName = versionNumber
                    } else {
                        versionNumber = env.BUILD_NUMBER
                    }
                    timestamp = VersionNumber versionNumberString: '${BUILD_DATE_FORMATTED, "yyyy-MM-dd HH:mm:ss Z"}'
                    gitCommit = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
                    project = "kafka-offset-lag-for-prometheus"
                }
                echo "Building from commit ${gitCommit} in ${BRANCH_NAME} branch at ${timestamp}"
                echo "VersionNumber: ${versionNumber}"
            }
        }
        stage('Build') {
            steps {
                sh "versionNumber=${versionNumber} ./mkdocker"
            }
        }
        stage('Tag') {
            when {
                branch 'master'
            }
            environment {
                GIT_AUTH = credentials('github_inomial-ci')
            }
            steps {
                // add tag
                sh "git tag -a \"${versionNumber}\" -m \"Jenkins build from ${BRANCH_NAME} commit ${gitCommit} on ${timestamp}\""

                // push tag
                sh 'git config --local credential.helper "!f() { echo username=\\$GIT_AUTH_USR; echo password=\\$GIT_AUTH_PSW; }; f"'
                sh "git push origin \"${versionNumber}\""
            }
        }
        stage('Release') {
            when {
                branch 'master'
            }
            parallel {
                stage('Archive Docker image') {
                    steps {
                        sh "docker save inomial.io/${project}:${versionNumber} | pigz > ${project}-${versionNumber}.tar.gz"
                        archiveArtifacts artifacts: '*.tar.gz', fingerprint: true
                    }
                }
                stage('Push Docker image') {
                    steps {
                        sh "docker tag inomial.io/${project}:${versionNumber} inomial.io/${project}:latest"
                        withDockerRegistry([credentialsId: 'portus-docker-registry', url: "https://inomial.io"]) {
                            sh "docker push inomial.io/${project}:${versionNumber}"
                            sh "docker push inomial.io/${project}:latest"
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                if (env.BRANCH_NAME == 'master') {
                    notifyBuild()
                }
            }
        }

        cleanup {
            // cleanup workspace
            cleanWs disableDeferredWipeout: true
        }
    }

    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr:'20'))
        timeout(time: 60, unit: 'MINUTES')
        skipStagesAfterUnstable()
        timestamps()
        ansiColor('xterm')
    }
}

def notifyBuild() {
    // build status of null means successful
    buildStatus = currentBuild.result ?: 'SUCCESS'

    // Override default values based on build status
    if (buildStatus == 'STARTED' || buildStatus == 'UNSTABLE') {
        colorCode = '#d69d46'
    } else if (buildStatus == 'SUCCESS') {
        colorCode = '#43b688'
    } else {
        colorCode = '#9e040e'
    }

    // send notification if this build was not successful or if the previous build wasn't successful
    if ( (currentBuild.previousBuild != null && currentBuild.previousBuild.result != 'SUCCESS') || buildStatus != 'SUCCESS') {
        slackSend (
            color: colorCode,
            message: "${buildStatus}: ${env.JOB_NAME} [<${env.RUN_DISPLAY_URL}|${env.BUILD_DISPLAY_NAME}>]"
        )

        emailext (
            subject: '$DEFAULT_SUBJECT',
            body: '$DEFAULT_CONTENT',
            recipientProviders: [
                [$class: 'CulpritsRecipientProvider'],
                [$class: 'DevelopersRecipientProvider'],
                [$class: 'RequesterRecipientProvider']
            ],
            replyTo: '$DEFAULT_REPLYTO',
            to: '$DEFAULT_RECIPIENTS, cc:builds@inomial.com'
        )
    }
}
