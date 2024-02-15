pipeline {
    agent any
    
    stages {
        stage('Checkout') {
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
                sh 'docker tag medicureimg:latest muzammilp/medicureimgaddbook:latest'
            }
        }

        stage('Docker login and push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker_pass', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    sh 'docker push muzammilp/medicureimgaddbook:latest'
                }
            }
        }
        stage('Deploy') {
            steps {
                    sh 'docker run -itd --name medicure -p 80:8082 muzammilp/medicureimgaddbook:latest'
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
