pipeline {
    agent any
    
    stages {
        stage('Git Checkout') {
            steps {
                git url: 'https://github.com/muzammilpasha4/star-agile-health-care/', branch: "master"
            }
        }
        stage('Build') {
            steps {
                sh "mvn clean package"
            }
        }
        stage('Build Image') {
            steps {
                sh 'docker build -t medicureimg .'
                sh 'docker tag medicureimg:latest muzammilp/medicureimg8082:latest'
            }
        }

        stage('Docker login and push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-pass', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    sh 'docker push muzammilp/medicureimg8082:latest'
                }
            }
        }
        stage('Deploy') {
            steps {
                    sh 'docker run -itd --name medicure -p 8082:8082 muzammilp/medicureimg8082:latest'
                }
            }
    }
        post {
            success {
                echo 'Pipeline successfully executed!'
            }
            failure {
                echo 'Pipeline failed!'
            }
        }
}
