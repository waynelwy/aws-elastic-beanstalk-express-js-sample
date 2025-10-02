pipeline {
  agent any  // 顶层在 Jenkins 容器；Node 相关阶段使用 'node:16' 作为构建代理

  environment {
    // === 按你的 Docker Hub 账户修改 ===
    REGISTRY   = "docker.io"
    IMAGE_REPO = "waynelwy/assignment_21818297"
    IMAGE_TAG  = "${env.BUILD_NUMBER}"
    IMAGE_FULL = "${REGISTRY}/${IMAGE_REPO}:${IMAGE_TAG}"

    // 跟 Compose 一致：通过 TLS 与 DinD 通信
    DOCKER_HOST       = "tcp://docker:2376"
    DOCKER_CERT_PATH  = "/certs/client"
    DOCKER_TLS_VERIFY = "1"

    npm_config_loglevel = "warn"
    CI = "true"
  }

  options {
    timestamps()
    ansiColor('xterm')
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Install deps (Node 16)') {
      agent { docker { image 'node:16' } }   // ✅ 作业要求：Node 16 作为构建代理
      steps {
        sh '''
          node -v && npm -v
          npm install --save
        '''
      }
    }

    stage('Unit tests (Node 16)') {
      agent { docker { image 'node:16' } }
      steps {
        // 若项目暂时没有测试，请在 package.json 准备一个最小 test 脚本
        sh 'npm test'
      }
      post {
        always {
          junit allowEmptyResults: true, testResults: '**/junit*.xml,**/test-results/*.xml'
        }
      }
    }

    stage('Dependency Scan (Snyk)') {
      agent { docker { image 'node:16' } }   // 在 Node 环境里做依赖扫描
      environment { SNYK_TOKEN = credentials('snyk-token') } // 你已创建
      steps {
        sh '''
          npm install -g snyk
          snyk auth "${SNYK_TOKEN}"
          # 发现 High/Critical 将返回非零码 -> 阻断流水线（✅ 作业硬性要求）
          snyk test --severity-threshold=high
        '''
      }
    }

    stage('Prepare Docker CLI in Jenkins') {
      steps {
        sh '''
          if ! command -v docker >/dev/null 2>&1; then
            echo "[INFO] Installing docker cli inside Jenkins container..."
            apt-get update -y
            apt-get install -y --no-install-recommends docker.io
          else
            echo "[INFO] docker cli already present."
          fi
          docker version
        '''
      }
    }

    stage('Docker Build') {
      steps {
        sh '''
          echo "Building image: ${IMAGE_FULL}"
          docker build -t "${IMAGE_FULL}" .
        '''
      }
    }

    stage('Docker Push') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-creds',     // 你已创建
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh '''
            echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
            docker push "${IMAGE_FULL}"
            docker logout
          '''
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'Dockerfile,package*.json', onlyIfSuccessful: false
    }
  }
}
