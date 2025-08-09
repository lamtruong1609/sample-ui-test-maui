pipeline {
    agent { label 'amazon-linux' }
    
    environment {
        // AWS credentials should be configured in Jenkins credentials
        AWS_DEFAULT_REGION = 'eu-west-2'
        DOCKER_COMPOSE_FILE = "${WORKSPACE}/tmp2-original/docker-compose.yml"
        RESULTS_DIR = "${WORKSPACE}/test-results"
        PROJECT_NAME = 'UI-tests-maui'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from repository...'
                checkout scm
            }
        }
        
        stage('Launch Genymotion EC2') {
            steps {
                script {
                    echo 'Launching Genymotion EC2 instance...'
                    
                    // Make the script executable and run it
                    sh '''
                        chmod +x ${WORKSPACE}/genymotion_ec2_runner.sh
                        
                        # Run the script to create EC2 instance
                        ${WORKSPACE}/genymotion_ec2_runner.sh
                    '''
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                script {
                    echo 'Running UI tests with docker-compose...'
                    
                    // Get the EC2 instance ID from the script output or environment
                    sh '''
                        # Create results directory
                        mkdir -p ${RESULTS_DIR}
                        
                        # Run docker-compose for tests
                        cd ${WORKSPACE}/tmp2-original
                        docker-compose up -d
                        
                        # Wait for tests to complete (up to 600 seconds or until log message appears)
                        echo "Waiting for 'UI tests completed' message in test-runner logs (timeout: 600s)..."
                        end=$((SECONDS+600))
                        found=0
                        while [ $SECONDS -lt $end ]; do
                          if docker-compose logs test-runner | grep -q "UI tests completed"; then
                            found=1
                            echo "Detected 'UI tests completed' in logs."
                            break
                          fi
                          sleep 5
                        done
                        if [ $found -eq 0 ]; then
                          echo "Timeout reached (600s) without detecting 'UI tests completed' in logs."
                        fi
                        
                        # Stop containers
                        docker-compose down
                    '''
                }
            }
        }
        
        stage('Collect Results') {
            steps {
                script {
                    echo 'Collecting test results...'
                    
                    sh '''
                        # Create results directory if it doesn't exist
                        mkdir -p ${RESULTS_DIR}
                        
                        # Copy test results from docker containers
                        cd ${WORKSPACE}/tmp2-original
                        
                        # Copy test output files from the mounted volume
                        if [ -d "output" ]; then
                            echo "Copying test results from output directory..."
                            cp -r output/* ${RESULTS_DIR}/ || true
                            echo "Test results copied to ${RESULTS_DIR}"
                            ls -la ${RESULTS_DIR}/
                        else
                            echo "Warning: output directory not found"
                        fi
                        
                        # Copy docker logs
                        echo "Collecting docker logs..."
                        docker-compose logs > ${RESULTS_DIR}/docker-logs.txt 2>&1 || true
                        
                        # Copy any other relevant test files
                        echo "Looking for additional test files..."
                        find . -name "*.xml" -o -name "*.html" -o -name "*.json" -o -name "*.trx" -o -name "*.mp4" | head -20 | xargs -I {} cp {} ${RESULTS_DIR}/ || true
                        
                        # Show what was collected
                        echo "Collected files in ${RESULTS_DIR}:"
                        ls -la ${RESULTS_DIR}/ || true
                    '''
                    // Upload to S3 with date + build number inside 'results/' folder
                    sh '''
                        UPLOAD_DATE=$(date +%Y-%m-%d)
                        DEST_PATH="results/${PROJECT_NAME}/${UPLOAD_DATE}-build-${BUILD_NUMBER}"

                        echo "Uploading test results to S3 path: ${DEST_PATH}"
                        aws s3 cp ${RESULTS_DIR} s3://ads-jenkins-s3-staging/${DEST_PATH}/ --recursive
                        echo "Test results uploaded to s3://ads-jenkins-s3-staging/${DEST_PATH}/"
                    '''
                }
            }
        }
        
        stage('Cleanup') {
            steps {
                script {
                    echo 'Cleaning up resources...'
                    
                    sh '''
                        # Get the instance ID from the script output or a file
                        if [ -f "${WORKSPACE}/instance_id.txt" ]; then
                            INSTANCE_ID=$(cat ${WORKSPACE}/instance_id.txt)
                            echo "Terminating EC2 instance: $INSTANCE_ID"
                            aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region eu-west-2 || true
                        fi
                        
                        # Clean up docker resources
                        cd ${WORKSPACE}/tmp2-original
                        docker-compose down -v || true
                        docker system prune -f || true
                    '''
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo 'Publishing test results...'
                
                // Archive test results
                archiveArtifacts artifacts: 'test-results/**/*', fingerprint: true
                
                // Publish test results (if you have JUnit XML reports)
                sh '''
                    if [ -d "${RESULTS_DIR}" ]; then
                        echo "Test results available in: ${RESULTS_DIR}"
                        ls -la ${RESULTS_DIR}/
                    fi
                '''
            }
        }
        
        success {
            echo 'Pipeline completed successfully!'
        }
        
        failure {
            echo 'Pipeline failed!'
        }
        
        cleanup {
            echo 'Cleaning up workspace...'
            cleanWs()
        }
    }
}
