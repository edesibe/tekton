# Tekton
The Tekton engine lives inside a Kubernetes cluster and through its API objects represents a declarative way to define the actions to perform. The core components such as Tasks and Pipelines can be used to create a pipeline to generate artifacts and/or containers from a Git repository.
Tekton also supports a mechanism for automating the start of a Pipeline with Triggers. These allow you to detect and extract information from events from a variety of sources, such as a webhook, and to start Tasks or Pipelines accordingly.
Working with private Git repositories is a common use case that Tekton supports nicely, and building artifacts and creating containers can be done in many ways such as with Buildah or Shipwright. It is also possible to integrate Kustomize and Helm in order to make the CI part dynamic and take benefit of the rich
ecosystem of Kubernetes tools.

## Prerequisites
- [direnv](https://direnv.net/)
- [nix](https://nixos.org/download.html)
- [tkn](https://tekton.dev/docs/cli/)
- kubernetes cluster (kind,k3s,minikube,...)

## Folder structure
Here is the folder structure.

```
./
├── Makefile			  # make targets
├── README.md			  # this file
├── hello/                        # hello use case
│   └── hello.yaml
└── shell.nix			  # nix reproducable env
```

## Installation
You need to have k8s cluster like minikube,k3s,or kind.For this purpose k3s is used.

### Cluster
Trigger `make create-cluster` and it will install k3s cluster on current node.

### Tekton
You need to call several `make` targets to install tekton components.

```
# Tekton Pipelines
make tekton-pipelines

# Tekton triggers
make tekton-triggers

# Tekton dashboard (optional)
make tekton-dashboard
```

## General
Tekton is a Kubernetes-native CI/CD solution that can be installed on top of any Kubernetes cluster. The installation brings you a set of Kubernetes Custom Resources (CRDs).

Task  
: A reusable, loosely coupled number of steps that perform a specific function (e.g.,
building a container image). Tasks get executed as Kubernetes pods, while steps
in a Task map onto containers.

Pipeline  
: A list Tasks needed to build and/or deploy your apps.

TaskRun  
: The execution and result of running an instance of a Task.

PipelineRun  
: The execution and result of running an instance of a Pipeline, which includes a
number of TaskRuns.

Trigger  
: Detects an event and connects to other CRDs to specify what happens when such
an event occurs.

Tekton has a modular structure. You can install all components separately or all at
once (e.g., with an Operator):

Tekton Pipelines
: Contains Tasks and Pipelines

Tekton Triggers
: Contains Triggers and EventListeners

Tekton Dashboard
: A convenient dashboard to visualize Pipelines and logs

Tekton CLI
: A CLI to manage Tekton objects (start/stop Pipelines and Tasks, check logs)

### Reserved directories
There are several directories that all Tasks run by Tekton will treat as special

`/workspace` - This directory is where resources and workspaces are mounted. Paths to these are available to Task authors via variable substitution

`/tekton` - This directory is used for Tekton specific functionality
: - `/tekton/results` is where results are written to. The path is available to Task authors via `$(results.name.path)`
: - There are other subfolders which are implementation details of Tekton and users should not rely on their specific behavior as it may change in the future

### Private repos
Tekton supports private repos where it will use secrets of type ssh-auth or basic-auth for fetching repos.

#### Secret credentials
Create a secret file and encrypt it with sops.
```
k create secret generic github-secret --type=kubernetes.io/basic-auth --from-literal=username=${GITHUB_USER} --from-literal=password=${GITHUB_PAT} --dry-run=client -o yaml > secrets/github-secret.yaml
# add annotations use by Tekton
#     annotations:
#        # specify the URL for which Tekton will use this Secret
#        tekton.dev/git-0: 'https://github.com'

make sops-encrypt FILENAME=secrets/github-secret.yaml
```
Create a secret inside kuberentes cluster 
```
sops -d secrets/github-secret.yaml | k apply -f-
```

#### Serviceaccount
Create a serviceaccount and define above secret for it.

```
k create sa tekton-bot-sa 
# and patch it with secrets attribute
k patch sa tekton-bot-sa -p '{"secrets": [{"name": "github-secret"}]}'
```

## TKN CLI
start task (optionally use --use-param-defaults in order to use default params from task)

```
tkn task start TASK_NAME --showlog [--use-param-defaults]
```

list tasks

```
tkn task list
```

list taskruns

```
tkn taskrun list
```

show log

```
tkn taskrun logs TASKRUN
```

[debug taskrun](https://tekton.dev/docs/pipelines/taskruns/#debugging-a-taskrun)

```
# add the following to the taskrun spec
spec:
  debug:
    breakpoint: ["onFailure"]
```
