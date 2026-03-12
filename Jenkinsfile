pipeline {

    agent any

    environment {
        AWS_DEFAULT_REGION = "us-east-1"
        ANSIBLE_HOST_KEY_CHECKING = "False"
        DOCKER_IMAGE = "jhansi445/jhansi-terraform-image"
    }

    stages {

        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/jhansi-r17909/terraform-ansible-project.git'
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    dir('infra') {
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('infra') {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    dir('infra') {
                        sh 'terraform plan'
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    dir('infra') {
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }

        stage('Fetch EC2 Public IP') {
            steps {
                script {
                    env.EC2_IP = sh(
                        script: "terraform -chdir=infra output -raw minikube_public_ip",
                        returnStdout: true
                    ).trim()

                    echo "EC2 Public IP: ${EC2_IP}"
                }
            }
        }

        stage('Wait for EC2 SSH') {
            steps {
                script {
                    sh """
                    echo "Waiting for SSH to become available on ${EC2_IP}"

                    while ! nc -z ${EC2_IP} 22; do
                        echo "SSH not ready yet..."
                        sleep 10
                    done

                    echo "SSH is now available!"
                    """
                }
            }
        }

        stage('Configure Minikube with Ansible') {
            steps {
                sshagent(credentials: ['jhansi-ec2-terraform']) {
                    sh """
                    cd ansible-1
                    export ANSIBLE_CONFIG=ansible.cfg

                    ansible-playbook -i aws_ec2.yml \
                    --extra-vars "target_host=${EC2_IP}" \
                    -u ubuntu playbook.yml
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}:latest", "./app")
                }
            }
        }

        stage('Push Docker Image to DockerHub') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'jhansi-docker-credentials') {
                        docker.image("${DOCKER_IMAGE}:latest").push()
                    }
                }
            }
        }

        stage('Deploy Application with Helm') {
            steps {
                sshagent(credentials: ['jhansi-ec2-terraform']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ubuntu@${EC2_IP} '

                    echo "Cloning repository on EC2..."
                    if [ ! -d terraform-ansible-project ]; then
                      git clone https://github.com/jhansi-r17909/terraform-ansible-project.git
                    else
                      cd terraform-ansible-project
                      git pull origin main
                      cd ..
                    fi

                    cd terraform-ansible-project

                    export KUBECONFIG=/home/ubuntu/.kube/config

                    echo "Checking Kubernetes nodes..."
                    kubectl get nodes

                    echo "Deploying Helm chart..."
                    helm upgrade --install nginx-app ./helm/nginx-chart

                    echo "Checking pods..."
                    kubectl get pods -A

                    echo "Checking services..."
                    kubectl get svc -A
                    '
                    """
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline execution finished"
        }
        success {
            echo "Infrastructure, Docker build, and Helm deployment completed successfully."
        }
        failure {
            echo "Pipeline failed. Check logs."
        }
    }
}
