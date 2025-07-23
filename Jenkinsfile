pipeline {
    agent any

    environment {
        IMAGE_NAME = "maui-test-runner"
        OUTPUT_DIR = "test-results"
    }

    stages {
        stage('Build Docker Image') {
            steps {
                script {
                    // Build the Docker image for the test runner
                    sh 'cd tmp2'
                    sh 'docker build -f test_runner.dockerfile -t ${IMAGE_NAME} .'
                }
            }
        }
        stage('Run Tests in Docker') {
            steps {
                script {
                    // Create output directory for test results
                    sh 'mkdir -p ${OUTPUT_DIR}'
                    // Run the tests in the container and save results
                    sh 'docker run --rm -v $PWD/${OUTPUT_DIR}:/home/app/output ${IMAGE_NAME}'
                }
            }
        }
        stage('Publish Test Results') {
            steps {
                // Publish TRX results if generated
                junit allowEmptyResults: true, testResults: "${OUTPUT_DIR}/*.trx"
            }
        }
    }
    post {
        always {
            // Clean up Docker image after pipeline
            sh 'docker rmi ${IMAGE_NAME} || true'
        }
    }
} 