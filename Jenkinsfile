pipeline {
    agent { label 'amazon-linux' }
    
    environment {
        // AWS credentials should be configured in Jenkins credentials
        AWS_DEFAULT_REGION = 'eu-west-2'
        DOCKER_COMPOSE_FILE = "${WORKSPACE}/tmp2-original/docker-compose.yml"
        RESULTS_DIR = "${WORKSPACE}/test-results"
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
                        
                        # Wait for test-runner container to complete
                        echo "Waiting for test-runner to complete..."
                        
                        # Monitor test-runner container status
                        while true; do
                            # Check if test-runner container is still running
                            if ! docker-compose ps test-runner | grep -q "Up"; then
                                echo "Test-runner container has stopped."
                                break
                            fi
                            
                            # Check for completion message in logs
                            if docker-compose logs test-runner | grep -q "UI tests completed"; then
                                echo "UI tests completed successfully!"
                                break
                            fi
                            
                            # Check for error or failure
                            if docker-compose logs test-runner | grep -q "FAILED\|ERROR\|Exception"; then
                                echo "Test-runner encountered an error."
                                break
                            fi
                            
                            echo "Test-runner still running... waiting 30 seconds"
                            sleep 30
                        done
                        
                        # Get the exit code of test-runner
                        EXIT_CODE=$(docker-compose ps -q test-runner | xargs docker inspect -f '{{.State.ExitCode}}' 2>/dev/null || echo "1")
                        echo "Test-runner exit code: $EXIT_CODE"
                        
                        # Show final logs
                        echo "Final test-runner logs:"
                        docker-compose logs test-runner
                        
                        # Stop containers
                        docker-compose down
                        
                        # Exit with test-runner exit code if it failed
                        if [ "$EXIT_CODE" != "0" ]; then
                            echo "Test-runner failed with exit code: $EXIT_CODE"
                            exit $EXIT_CODE
                        fi
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
