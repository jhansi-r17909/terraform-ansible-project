pipeline {

    agent any

    environment {
        AWS_DEFAULT_REGION = "us-east-1"
        ANSIBLE_HOST_KEY_CHECKING = "False"
        DOCKER_IMAGE = "darninidhi2122/nginx-devops"
    }

    stages {

        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/darninidhi2122/terraform-ansible-project.git'
            }
        }

        stage('Terraform Init') {
            steps {
                dir('infra') {
                    sh 'terraform init'
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
                dir('infra') {
                    sh 'terraform plan'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('infra') {
                    sh 'terraform apply -auto-approve'
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
                sshagent(credentials: ['ec2-key']) {
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
                    docker.withRegistry('https://registry.hub.docker.com', 'dockerhub-creds') {
                        docker.image("${DOCKER_IMAGE}:latest").push()
                    }
                }
            }
        }

        stage('Deploy Application with Helm') {
            steps {
                sshagent(credentials: ['ec2-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ubuntu@${EC2_IP} << 'EOF'
                    
                    echo "Cloning repository on EC2..."
                    if [ ! -d terraform-ansible-project ]; then
                    git clone https://github.com/darninidhi2122/terraform-ansible-project.git
                    fi

                    cd terraform-ansible-project

                    echo "Checking Kubernetes nodes..."
                    kubectl get nodes

                    echo "Deploying Helm chart..."
                    helm upgrade --install nginx-app helm/nginx-chart

                    echo "Checking pods..."
                    kubectl get pods

                    echo "Checking services..."
                    kubectl get svc

                    EOF
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
