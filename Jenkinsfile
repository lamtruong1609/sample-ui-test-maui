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
                    try {
                        echo "🚀 Starting Docker services..."
                        sh "docker-compose -f ${COMPOSE_FILE} up -d"
                    } catch (err) {
                        echo "❌ Failed to start Docker services. Fetching logs..."
                        sh "docker-compose -f ${COMPOSE_FILE} logs --tail=100"
                        error("Start Services stage failed: ${err}")
                    }
                }
            }
        }

        stage('Wait for Emulator & Appium') {
            steps {
                script {
                    echo "⏳ Waiting for Emulator & Appium to be ready..."
                    sh "docker-compose -f ${COMPOSE_FILE} ps -a"

                    // Optional: Wait loop to poll for emulator health status
                    def retries = 10
                    def healthy = false
                    for (int i = 0; i < retries; i++) {
                        def status = sh(
                            script: "docker inspect -f '{{.State.Health.Status}}' emulator || echo 'unavailable'",
                            returnStdout: true
                        ).trim()
                        echo "➡️ Emulator health status: ${status}"
                        if (status == "healthy") {
                            healthy = true
                            break
                        }
                        sleep 30
                    }

                    if (!healthy) {
                        echo "❌ Emulator is not healthy. Fetching logs..."
                        sh "docker-compose -f ${COMPOSE_FILE} logs --tail=100 android-emulator"
                        error("Emulator did not become healthy in time.")
                    }
                }
            }
        }

        stage('Run Tests') {
            steps {
                script {
                    echo "🧪 Running test-runner..."
                    sh "docker-compose -f ${COMPOSE_FILE} run --rm test-runner"
                }
            }
        }

        stage('Publish Test Results') {
            steps {
                echo "📤 Publishing test results..."
                junit allowEmptyResults: true, testResults: "${OUTPUT_DIR}/*.trx"
            }
        }
    }

    post {
        always {
            echo "🧹 Cleaning up Docker services..."
            sh "docker-compose -f ${COMPOSE_FILE} down"
        }
    }
}
