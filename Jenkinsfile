pipeline {
  agent { label 'build' }

  environment { 
    registry = "kiransanda/democicd"
    registryCredential = 'dockerhub'
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
        echo "Running Software Composition Analysis using OWASP Dependency-Check ..."
        withCredentials([string(credentialsId: 'NVD_API_KEY', variable: 'NVD_API_KEY')]) {
          sh '''
            export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
            mvn org.owasp:dependency-check-maven:check -Dnvd.api.key=$NVD_API_KEY
          '''
        }
      }
    }

    stage('Stage IV: SAST') {
      steps { 
        echo "Running Static Application Security Testing using SonarQube Scanner ..."
        withSonarQubeEnv('mysonarqube') {
          sh '''
            mvn sonar:sonar \
              -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml \
              -Dsonar.dependencyCheck.jsonReportPath=target/dependency-check-report.json \
              -Dsonar.dependencyCheck.htmlReportPath=target/dependency-check-report.html \
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
   
    stage('Stage VI: Build Image') {
      steps { 
        echo "Building Docker Image..."
        script {
          docker.withRegistry('', registryCredential) { 
            def myImage = docker.build(registry)
            myImage.push()
          }
        }
      }
    }
        
    stage('Stage VII: Scan Image') {
      steps { 
        echo "Scanning Docker Image with Trivy..."
        sh "trivy image --scanners vuln --offline-scan ${registry}:latest > trivyresults.txt"
      }
    }
          
    stage('Stage VIII: Smoke Test') {
      steps { 
        echo "Running Smoke Test on Docker Image..."
        sh '''
          docker run -d --name smokerun -p 8080:8080 ${registry}:latest
          sleep 90
          ./check.sh
          docker rm --force smokerun
        '''
      }
    }
  }
}
