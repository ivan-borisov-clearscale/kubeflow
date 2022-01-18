{
  local k = import "k.libsonnet",
  local util = import "kubeflow/common/util.libsonnet",

  new(_env, _params):: {
    local params = _params + _env,

    local mpiJobCrd = {
      apiVersion: "apiextensions.k8s.io/v1",
      kind: "CustomResourceDefinition",
      metadata: {
        name: "mpijobs.kubeflow.org",
      },
      spec: {
        group: "kubeflow.org",
        scope: "Namespaced",
        names: {
          plural: "mpijobs",
          singular: "mpijob",
          kind: "MPIJob",
          shortNames: [
            "mj",
            "mpij",
          ],
        },
        versions: [
          {
            name: "v1alpha1",
            served: true,
            storage: true,
            schema: {
              "openAPIV3Schema": {
                type: "object",
                required: ["spec"],
                "properties": {
                  status: {
                    "x-kubernetes-preserve-unknown-fields": true,
                    type: "object",
                  },
                  "spec": {
                    type: "object",
                    "x-kubernetes-preserve-unknown-fields": true,
                  }
                },
              },
            },
            subresources: {
              status: {}
            }
          },
        ],

      },
    },
    mpiJobCrd:: mpiJobCrd,

    local serviceAccount = {
      apiVersion: "v1",
      kind: "ServiceAccount",
      metadata: {
        name: params.name,
        namespace: params.namespace,
      },
    },
    serviceAccount:: serviceAccount,

    local clusterRole = {
      kind: "ClusterRole",
      apiVersion: "rbac.authorization.k8s.io/v1",
      metadata: {
        name: params.name,
      },
      rules: [
        {
          apiGroups: [
            "",
          ],
          resources: [
            "configmaps",
            "serviceaccounts",
          ],
          verbs: [
            "create",
            "list",
            "watch",
            "update",
          ],
        },
        {
          // This is needed for the launcher Role.
          apiGroups: [
            "",
          ],
          resources: [
            "pods",
          ],
          verbs: [
            "create",
            "get",
            "list",
            "watch",
            "delete",
            "update",
            "patch",
          ],
        },
        // This is needed for the launcher Role.
        {
          apiGroups: [
            "",
          ],
          resources: [
            "pods/exec",
          ],
          verbs: [
            "create",
          ],
        },
        {
          apiGroups: [
            "",
          ],
          resources: [
            "endpoints",
          ],
          verbs: [
            "create",
            "get",
            "update",
          ],
        },
        {
          apiGroups: [
            "",
          ],
          resources: [
            "events",
          ],
          verbs: [
            "create",
            "patch",
          ],
        },
        {
          apiGroups: [
            "rbac.authorization.k8s.io",
          ],
          resources: [
            "roles",
            "rolebindings",
          ],
          verbs: [
            "create",
            "list",
            "watch",
            "update",
          ],
        },
        {
          apiGroups: [
            "apps",
          ],
          resources: [
            "statefulsets",
          ],
          verbs: [
            "create",
            "list",
            "update",
            "watch",
          ],
        },
        {
          apiGroups: [
            "batch",
          ],
          resources: [
            "jobs",
          ],
          verbs: [
            "create",
            "list",
            "update",
            "watch",
          ],
        },
        {
          apiGroups: [
            "policy",
          ],
          resources: [
            "poddisruptionbudgets",
          ],
          verbs: [
            "create",
            "list",
            "update",
            "watch",
          ],
        },
        {
          apiGroups: [
            "apiextensions.k8s.io",
          ],
          resources: [
            "customresourcedefinitions",
          ],
          verbs: [
            "create",
            "get",
          ],
        },
        {
          apiGroups: [
            "kubeflow.org",
          ],
          resources: [
            "mpijobs",
            "mpijobs/finalizers",
            "mpijobs/status",
          ],
          verbs: [
            "*",
          ],
        },
        {
          apiGroups: [
            "scheduling.incubator.k8s.io",
            "scheduling.sigs.dev",
            "scheduling.volcano.sh",
          ],
          resources: [
            "queues",
            "podgroups",
          ],
          verbs: [
            "*",
          ],
        },
      ],
    },
    clusterRole:: clusterRole,

    local clusterRoleBinding = {
      kind: "ClusterRoleBinding",
      apiVersion: "rbac.authorization.k8s.io/v1",
      metadata: {
        name: params.name,
        namespace: params.namespace,
      },
      roleRef: {
        apiGroup: "rbac.authorization.k8s.io",
        kind: "ClusterRole",
        name: params.name,
      },
      subjects: [
        {
          kind: "ServiceAccount",
          name: params.name,
          namespace: params.namespace,
        },
      ],
    },
    clusterRoleBinding:: clusterRoleBinding,

    local deployment = {
      apiVersion: "apps/v1",
      kind: "Deployment",
      metadata: {
        name: params.name,
        namespace: params.namespace,
        labels: {
          app: params.name,
        },
      },
      spec: {
        replicas: 1,
        selector: {
          matchLabels: {
            app: params.name,
          },
        },
        template: {
          metadata: {
            labels: {
              app: params.name,
            },
          },
          spec: {
            serviceAccountName: params.name,
            containers: [
              {
                name: "mpi-operator",
                image: params.image,
                args: [
                  "-alsologtostderr",
                  //"--gpus-per-node",
                  //std.toString(params.gpusPerNode),
                  "--kubectl-delivery-image",
                  params.kubectlDeliveryImage,
                ],
                imagePullPolicy: "Always",
              },
            ],
          },
        },
      },
    },
    deployment:: deployment,

    parts:: self,
    all:: [
      self.mpiJobCrd,
      self.serviceAccount,
      self.clusterRole,
      self.clusterRoleBinding,
      self.deployment
    ],

    list(obj=self.all):: util.list(obj),
  },
}