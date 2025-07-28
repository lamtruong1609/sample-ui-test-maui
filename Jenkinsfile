pipeline {
    agent { label 'amazon-linux' }

    environment {
        OUTPUT_DIR = "tmp2/output"
        COMPOSE_FILE = "tmp2/docker-compose.yml"
    }

    stages {
        stage('Start Services') {
            steps {
                script {
                    // Start all services in the background
                    sh "docker-compose -f ${COMPOSE_FILE} up -d"
                }
            }
        }
        stage('Debug Emulator Container') {
            steps {
                script {
                    // Show status of all containers
                    sh "docker-compose -f ${COMPOSE_FILE} ps -a"
                    // Show logs from the emulator container
                    sh "docker-compose -f ${COMPOSE_FILE} logs --tail=100 android-emulator || true"
                    // Show Docker system info (for KVM, etc.)
                    sh "docker info || true"
                    // Show KVM device presence
                    sh "ls -l /dev/kvm || true"
                }
            }
        }
        stage('Wait for Emulator & Appium') {
            steps {
                script {
                    // Wait for emulator healthcheck (adjust as needed)
                    sh "docker-compose -f ${COMPOSE_FILE} ps"
                    // Optionally, add a sleep or a custom wait script here
                    sh "sleep 120"
                }
            }
        }
        stage('Run Tests') {
            steps {
                script {
                    // Run the test-runner service (it will run and exit)
                    sh "docker-compose -f ${COMPOSE_FILE} run --rm test-runner"
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
            // Tear down all services
            sh "docker-compose -f ${COMPOSE_FILE} down"
        }
    }
} 