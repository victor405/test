from diagrams import Diagram, Cluster
from diagrams.onprem.client import Users
from diagrams.onprem.ci import GithubActions
from diagrams.onprem.monitoring import Datadog

from diagrams.aws.network import VPC, PublicSubnet, PrivateSubnet, NATGateway, InternetGateway, ELB
from diagrams.aws.compute import EKS
from diagrams.aws.database import RDS
from diagrams.aws.compute import ECR
from diagrams.aws.network import CloudFront

from diagrams.programming.framework import FastAPI

with Diagram("Prompt App Architecture", show=True, direction="LR"):

    users = Users("Users")

    github = GithubActions("GitHub Actions")

    frontend = CloudFront("Frontend\n(GitHub Pages / CloudFront)")

    datadog = Datadog("Datadog\nLogs / Metrics / APM")

    with Cluster("AWS"):

        with Cluster("VPC"):

            igw = InternetGateway("IGW")
            nat = NATGateway("NAT")

            with Cluster("Public Subnets"):
                public_lb = ELB("K8s LoadBalancer")

            with Cluster("Private Subnets"):

                eks = EKS("EKS Cluster")

                with Cluster("Kubernetes"):
                    app = FastAPI("prompt-gemini")

                db = RDS("RDS MySQL")

        ecr_app = ECR("ECR\nprompt-gemini")
        ecr_migration = ECR("ECR\ndb-migration")

    # ---------- User Flow ----------
    users >> frontend >> public_lb >> eks >> app >> db

    # ---------- CI/CD ----------
    github >> ecr_app >> eks
    github >> ecr_migration >> eks

    # ---------- Observability ----------
    app >> datadog
    eks >> datadog