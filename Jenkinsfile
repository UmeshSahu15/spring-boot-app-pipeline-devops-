pipeline {
  agent { label 'build' }

  environment { 
    registry = "6378257556/wezvatech-demo"  // Docker Hub username + image
    registryCredential = 'DOCKER'          // Jenkins credential ID
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'main', credentialsId: 'GitlabCred', url: 'https://gitlab.com/learndevopseasypractice/devsecops/springboot-build-pipeline.git'
      }
    }
  
    stage('Stage I: Build') {
      steps {
        echo "Building Jar Component ..."
        sh '''
          export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
          mvn clean package
        '''
      }
    }

    stage('Stage II: Code Coverage') {
      steps {
        echo "Running Code Coverage ..."
        sh '''
          export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
          mvn jacoco:report
        '''
      }
    }

    stage('Stage III: SCA') {
      steps {
        echo "Running Software Composition Analysis using Trivy ..."
        sh 'trivy fs --scanners vuln . > trivy-sca-report.txt'
      }
      post {
        always {
          archiveArtifacts artifacts: 'trivy-sca-report.txt', fingerprint: true
        }
      }
    }

    stage('Stage IV: SAST') {
      steps { 
        echo "Running Static Application Security Testing using SonarQube Scanner ..."
        withSonarQubeEnv('sonarqube') {
          sh '''
            mvn sonar:sonar \
              -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml \
              -Dsonar.projectName=wezvatech
          '''
        }
      }
    }

    stage('Stage V: Quality Gates') {
      steps { 
        echo "Running Quality Gates to verify the code quality..."
        script {
          timeout(time: 1, unit: 'MINUTES') {
            def qg = waitForQualityGate()
            if (qg.status != 'OK') {
              error "Pipeline aborted due to quality gate failure: ${qg.status}"
            }
          }
        }
      }
    }
   
    stage('Stage VI: Build & Push Docker Image') {
      steps { 
        echo "Building Docker Image..."
        script {
          docker.withRegistry('https://index.docker.io/v1/', registryCredential) { 
            def myImage = docker.build("${registry}:${BUILD_NUMBER}")
            myImage.push()
            myImage.push("latest")
          }
        }
      }
    }
        
    stage('Stage VII: Scan Docker Image') {
      steps { 
        echo "Scanning Docker Image with Trivy..."
        sh '''
          trivy image --scanners vuln --offline-scan ${registry}:${BUILD_NUMBER} > trivy-image-report.txt
          # Fail pipeline if vulnerabilities found
          if grep -q "CRITICAL\|HIGH" trivy-image-report.txt; then
            echo "High or Critical vulnerabilities found! Failing pipeline..."
            exit 1
          fi
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'trivy-image-report.txt', fingerprint: true
        }
      }
    }
          
    stage('Stage VIII: Smoke Test') {
      steps { 
        echo "Running Smoke Test on Docker Image..."
        sh '''
          docker run -d --name smokerun -p 8080:8080 ${registry}:${BUILD_NUMBER}
          sleep 90
          ./check.sh
          docker rm --force smokerun
        '''
      }
    }
  }
}
