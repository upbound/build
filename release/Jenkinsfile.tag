pipeline {
    agent { label 'upbound-gce' }

    environment {
        reload = '--reload pipeline--'
    }

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    parameters {
        string(name: 'version', defaultValue: '--reload pipeline--', description: 'The version you are releasing, for example, v0.5.0. (Leave it empty to reload the pipeline)')
        string(name: 'commit', defaultValue: '', description: 'Optional commit hash for this release, for example, 56b65dba917e50132b0a540ae6ff4c5bbfda2db6. If empty the latest commit hash will be used.')
    }

    stages {

        stage('Reload Pipeline') {
            when {
                expression { return params.version == env.reload }
            }

            steps {
                script {
                    currentBuild.result = 'NOT_BUILT'
                    currentBuild.displayName = "Skipped"
                    currentBuild.description = "Reloading pipeline definition, promotion skipped"
                }
            }
        }

        stage('Tag Release') {
            when {
                expression { return params.version != env.reload }
            }

            steps {
                checkout scm

                script {

                    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'github-upbound-jenkins', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD']]) {
                        sh("git config user.name ${env.GIT_AUTHOR_NAME}")
                        sh("git config user.email ${env.GIT_AUTHOR_EMAIL}")
                        // github credentials are not setup to push over https in jenkins. add the github token to the url
                        sh "git config remote.origin.url https://${GIT_USERNAME}:${GIT_PASSWORD}@\$(git config --get remote.origin.url | sed -e 's/https:\\/\\///')"
                        sh "make -C build/release tag VERSION=${params.version} COMMIT_HASH=${params.commit}"
                    }

                    currentBuild.displayName = "Tag: ${params.version}, Branch: ${env.BRANCH_NAME}"
                    if (params.commit == '') {
                        currentBuild.description = "Revision: ${env.GIT_COMMIT}"
                    } else {
                        currentBuild.description = "Revision: ${params.commit}"
                    }
                }
            }
        }
    }
}
