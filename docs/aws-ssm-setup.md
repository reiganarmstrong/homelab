# AWS SSM Parameter Store Setup (for External Secrets Operator)

This homelab uses **AWS Systems Manager (SSM) Parameter Store** (Standard tier, `SecureString`) as the single source of truth for secrets.

- **Cost**: `$0/month` (up to 10,000 Standard parameters; encryption with the default `aws/ssm` KMS key is free).
- **Security**: Only a single least-privilege IAM user credential is stored in Kubernetes during bootstrap; it can **only read** parameters under `/homelab/*`.

---

## 1. Create a Least-Privilege IAM Policy

In the AWS Console → **IAM → Policies → Create policy** (JSON), replace `<ACCOUNT_ID>` and `<REGION>` (e.g. `us-east-1`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadHomelabParameters",
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Resource": "arn:aws:ssm:<REGION>:<ACCOUNT_ID>:parameter/homelab/*"
    }
  ]
}
```

## 2. Create the IAM User & Access Key

1. Create an IAM user named `homelab-eso-reader` (no console access needed).
2. Attach the policy you created above.
3. Generate an **Access Key** (choose *Application running outside AWS*).
4. Save the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` — you'll pass them once to `bootstrap/scripts/bootstrap.sh` (never commit them to Git!).

## 3. Store Your Initial Secrets in Parameter Store

Using the AWS CLI (or AWS Console → Systems Manager → Parameter Store):

```bash
# Tailscale Kubernetes Operator OAuth credentials
aws ssm put-parameter \
  --name "/homelab/tailscale/oauth-client-id" \
  --type "SecureString" \
  --value "<YOUR_TAILSCALE_OAUTH_CLIENT_ID>" \
  --region us-east-1

aws ssm put-parameter \
  --name "/homelab/tailscale/oauth-client-secret" \
  --type "SecureString" \
  --value "<YOUR_TAILSCALE_OAUTH_CLIENT_SECRET>" \
  --region us-east-1
```

> If you use a region other than `us-east-1`, update `spec.provider.aws.region` in [`infrastructure/external-secrets-config/cluster-secret-store.yaml`](../infrastructure/external-secrets-config/cluster-secret-store.yaml).

## 4. Tailscale ACL Tag Setup

Before deploying the Tailscale Kubernetes Operator, add these tag owners to your Tailscale ACL policy (Admin Console → Access Controls):

```json
"tagOwners": {
  "tag:k8s-operator": [],
  "tag:k8s": ["tag:k8s-operator"]
}
```

Then create an OAuth client (Admin Console → Settings → OAuth clients) with:
- **Devices → Core**: Write (`tag:k8s-operator`)
- **Keys → Auth Keys**: Write (`tag:k8s-operator`)
