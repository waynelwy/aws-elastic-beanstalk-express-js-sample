pipeline {
  agent any  
  // Use any available agent as the top-level Jenkins executor (Jenkins master container)
  // 在顶层使用任意可用的构建代理（这里默认跑在 Jenkins 容器本身）

  environment {
    // === Replace with your Docker Hub account ===
    // Define environment variables for Docker registry and image naming
    // 定义环境变量，用于 Docker 仓库和镜像命名，需替换为你自己的 Docker Hub 账号

    REGISTRY   = "docker.io"                
    IMAGE_REPO = "waynelwy/assignment_21818297" 
    IMAGE_TAG  = "${env.BUILD_NUMBER}"      
    IMAGE_FULL = "${REGISTRY}/${IMAGE_REPO}:${IMAGE_TAG}" 
    // Full image name / 完整的镜像名

    // === Connect Jenkins with DinD (Docker-in-Docker) service ===
    // These settings allow Jenkins to talk to DinD securely over TLS
    // 以下配置让 Jenkins 能通过 TLS 访问 DinD (docker:dind) 服务

    DOCKER_HOST       = "tcp://docker:2376" 
    DOCKER_CERT_PATH  = "/certs/client"
    DOCKER_TLS_VERIFY = "1"

    // === Node.js/NPM configurations ===
    npm_config_loglevel = "warn"  
    // reduce npm logs / 设置 npm 日志级别为 warn，减少输出
    CI = "true"                   
    // enable CI mode for npm / 启用 npm CI 模式（持续集成环境）
  }

  options {
    timestamps() 
    // Prefix logs with timestamps / 构建日志带时间戳
    ansiColor('xterm') 
    // Enable ANSI colors in console / 控制台日志支持彩色输出
    buildDiscarder(logRotator(numToKeepStr: '20')) 
    // Keep only the last 20 builds / 仅保留最近 20 个构建历史
  }

  stages {

    stage('Checkout') {
      steps { 
		echo "=== Stage: Checkout ===" // Show in logs / 在日志中显示阶段名
        checkout scm 
        // Checkout code from SCM (GitHub) / 从源码管理（GitHub）检出代码
      }
    }

    stage('Install deps (Node 16)') {
      agent { docker { image 'node:16' } }   
      // Run this stage in a Node.js 16 Docker container
      // 在 Node.js 16 Docker 容器中运行本阶段（符合作业要求）

      steps {
		echo "=== Stage: Install dependencies ===" // Show in logs / 显示阶段名
        sh '''
          node -v && npm -v     
          # show Node & npm versions / 显示 Node 和 npm 版本
          npm install --save    
          # install project dependencies / 安装项目依赖
        '''
      }
    }

    stage('Unit tests (Node 16)') {
      agent { docker { image 'node:16' } }
      steps {
		echo "=== Stage: Unit Tests ===" 
        // Run unit tests defined in package.json ("npm test")
        // 执行 package.json 中定义的单元测试
        sh 'npm test'
      }
      post {
        always {
          junit allowEmptyResults: true, testResults: '**/junit*.xml,**/test-results/*.xml'
          // Archive test results (JUnit format). Ignore if none found
          // 归档测试结果（JUnit 格式），若无结果也不会报错
        }
      }
    }

    stage('Dependency Scan (Snyk)') {
      agent { docker { image 'node:16' } }   
      // Run dependency scan in Node.js environment
      // 在 Node.js 环境中进行依赖漏洞扫描

      environment { 
        SNYK_TOKEN = credentials('snyk-token') 
        // Load Snyk API token from Jenkins credentials
        // 从 Jenkins 凭据管理中读取 Snyk API token
      }
      steps {
		echo "=== Stage: Dependency Security Scan ==="
        sh '''
          npm install -g snyk            
          # install snyk CLI / 全局安装 snyk CLI
          snyk auth "${SNYK_TOKEN}"      
          # authenticate with snyk / 用 token 登录 snyk
          snyk test --severity-threshold=high
          # fail pipeline if high/critical vulnerabilities found
          # 如果发现高危/严重漏洞，则流水线失败（作业要求）
        '''
      }
    }

    stage('Prepare Docker CLI in Jenkins') {
      steps {
		echo "=== Stage: Prepare Docker CLI ==="
        sh '''
          if ! command -v docker >/dev/null 2>&1; then
            echo "[INFO] Installing docker cli inside Jenkins container..."
            apt-get update -y
            apt-get install -y --no-install-recommends docker.io
          else
            echo "[INFO] docker cli already present."
          fi
          docker version
          # Check Docker CLI version / 显示 Docker CLI 版本
        '''
      }
    }

    stage('Docker Build') {
      steps {
		echo "=== Stage: Docker Build ==="
        sh '''
          echo "Building image: ${IMAGE_FULL}"
          docker build -t "${IMAGE_FULL}" .
          # Build Docker image with project code
          # 基于项目代码构建 Docker 镜像
        '''
      }
    }

    stage('Docker Push') {
      steps {
		echo "=== Stage: Docker Push ==="
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-creds',     
          // Load Docker Hub username/password from Jenkins credentials
          // 从 Jenkins 凭据中读取 Docker Hub 用户名和密码
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh '''
            echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
            # login to Docker Hub / 登录 Docker Hub
            docker push "${IMAGE_FULL}"
            # push image to Docker Hub / 推送镜像到 Docker Hub
            docker logout
          '''
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'build-logs/**', allowEmptyArchive: true
      // Archive additional build logs / 归档额外的构建日志
    }
  }
}
