node {
    stage('Preparation') {
        checkout scm
        versionNumber = VersionNumber versionNumberString: '${BUILD_DATE_FORMATTED, "yy.MM"}.${BUILDS_THIS_MONTH}', versionPrefix: '', buildsAllTime: '12'
        echo "VersionNumber: ${versionNumber}"
        timestamp = VersionNumber versionNumberString: '${BUILD_DATE_FORMATTED, "yyyy-MM-dd HH:mm:ss Z"}'
        echo "timestamp: ${timestamp}"
        gitBranch = sh(script: "git name-rev --name-only HEAD", returnStdout: true).trim()
        gitCommit = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
    }
    stage('Build') {
        sh "./mkdocker"
    }
    stage('Tag') {
        // add tag
        sh "git tag -a \"${versionNumber}\" -m \"Jenkins build from ${gitBranch} commit ${gitCommit} on ${timestamp}\""

        // push tag
        sh "git push origin \"${versionNumber}\""
    }
    stage('Push') {
        sh "docker tag inomial.io/kafka-offset-lag-for-prometheus inomial.io/kafka-offset-lag-for-prometheus:${versionNumber}"

        // archive image
        sh "docker save inomial.io/kafka-offset-lag-for-prometheus:${versionNumber} | gzip > kafka-offset-lag-for-prometheus-${versionNumber}.tar.gz"

        // tag and push (as $revision and as latest)
        sh "docker push inomial.io/kafka-offset-lag-for-prometheus:${versionNumber}"
        sh "docker push inomial.io/kafka-offset-lag-for-prometheus:latest"

        // cleanup images
    }
    stage('Results') {
        currentBuild.displayName = versionNumber
        archive '*.tar.gz'
        step([$class: 'WsCleanup'])
    }
}
