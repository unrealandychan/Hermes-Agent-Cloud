# Hermes Agent — Helm Chart

Deploy [Hermes Agent](https://github.com/unrealandychan/Hermes-Agent-Cloud) to any Kubernetes cluster (EKS, AKS, GKE).

## Prerequisites

- Kubernetes 1.25+
- Helm 3.10+
- A container registry token (if using a private image)

## Quick Start

```bash
# 1. Add the repo (once published)
helm repo add hermes-agent https://unrealandychan.github.io/Hermes-Agent-Cloud
helm repo update

# 2. Install with your API keys
helm install hermes-agent hermes-agent/hermes-agent \
  --set env.OPENROUTER_API_KEY=<your-key> \
  --namespace hermes --create-namespace
```

Or install directly from this directory:

```bash
helm install hermes-agent ./k8s \
  --set env.OPENROUTER_API_KEY=<your-key> \
  --namespace hermes --create-namespace
```

## Upgrade

```bash
helm upgrade hermes-agent hermes-agent/hermes-agent \
  --set image.tag=0.16.0 \
  --namespace hermes
```

## Uninstall

```bash
helm uninstall hermes-agent --namespace hermes
# PVC is retained by default; delete manually if needed:
kubectl delete pvc hermes-agent-data -n hermes
```

## Values

| Key | Default | Description |
|-----|---------|-------------|
| `image.repository` | `ghcr.io/unrealandychan/hermes-agent` | Container image repository |
| `image.tag` | `"0.15.2"` | Image tag |
| `image.pullPolicy` | `IfNotPresent` | Image pull policy |
| `replicaCount` | `1` | Number of replicas |
| `service.type` | `ClusterIP` | Kubernetes service type |
| `service.port` | `8080` | Service port |
| `ingress.enabled` | `false` | Enable ingress resource |
| `ingress.className` | `""` | Ingress class name |
| `resources.requests.cpu` | `500m` | CPU request |
| `resources.requests.memory` | `512Mi` | Memory request |
| `resources.limits.cpu` | `2` | CPU limit |
| `resources.limits.memory` | `2Gi` | Memory limit |
| `persistence.enabled` | `true` | Enable persistent storage |
| `persistence.size` | `20Gi` | PVC size |
| `persistence.storageClass` | `""` | Storage class (leave blank for default) |
| `env.OPENROUTER_API_KEY` | `""` | OpenRouter API key |
| `env.OPENAI_API_KEY` | `""` | OpenAI API key |
| `env.ANTHROPIC_API_KEY` | `""` | Anthropic API key |
| `env.GEMINI_API_KEY` | `""` | Google Gemini API key |
| `serviceAccount.create` | `true` | Create a dedicated ServiceAccount |
| `nodeSelector` | `{}` | Node selector |
| `tolerations` | `[]` | Tolerations |
| `affinity` | `{}` | Affinity rules |

## Example: Enable Ingress with TLS

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: hermes.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: hermes-tls
      hosts:
        - hermes.example.com
```

Apply with:

```bash
helm upgrade --install hermes-agent ./k8s -f my-values.yaml -n hermes
```
