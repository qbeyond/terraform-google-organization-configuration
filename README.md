# Organization Module
Original Module from [Cloud-Foundation-Fabric](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric)

This module allows managing several organization properties:

- IAM bindings, both authoritative and additive
- custom IAM roles
- audit logging configuration for services
- organization policies
- organization policy custom constraints

To manage organization policies, the `orgpolicy.googleapis.com` service should be enabled in the quota project. Furthermore you need to use a service account. **End user credentials are not supported!**

## IAM

There are several mutually exclusive ways of managing IAM in this module

- non-authoritative via the `iam_additive` and `iam_additive_members` variables, where bindings created outside this module will coexist with those managed here
- authoritative via the `group_iam` and `iam` variables, where bindings created outside this module (eg in the console) will be removed at each `terraform apply` cycle if the same role is also managed here
- authoritative policy via the `iam_bindings_authoritative` variable, where any binding created outside this module (eg in the console) will be removed at each `terraform apply` cycle regardless of the role

If you set audit policies via the `iam_audit_config_authoritative` variable, be sure to also configure IAM bindings via `iam_bindings_authoritative`, as audit policies use the underlying `google_organization_iam_policy` resource, which is also authoritative for any role.

Some care must also be taken with the `groups_iam` variable (and in some situations with the additive variables) to ensure that variable keys are static values, so that Terraform is able to compute the dependency graph.

<!-- BEGIN_TF_DOCS -->
## Usage

The minimal configuration doesn't do anything.

```hcl
variable "organization_id" {
  description = "Organization id in organizations/nnnnnn format."
  type        = string
  validation {
    condition     = can(regex("^organizations/[0-9]+", var.organization_id))
    error_message = "The organization_id must in the form organizations/nnn."
  }
}


module "google_organitation" {
  source          = "../.."
  organization_id = var.organization_id
}
```

So you should configure more than that!

### Custom Constraints

Refer to the [Creating and managing custom constraints](https://cloud.google.com/resource-manager/docs/organization-policy/creating-managing-custom-constraints) documentation for details on usage.
To manage organization policy custom constraints, the `orgpolicy.googleapis.com` service should be enabled in the quota project.

```hcl
variable "organization_id" {
  description = "Organization id in organizations/nnnnnn format."
  type        = string
}

variable "impersonate_service_account" {
  description = "Mail of service account to impersonate, because ADC not supported."
  type        = string
}


# Make sure to impersonate an service account
# gcloud application-default not supported
provider "google-beta" {
  impersonate_service_account = var.impersonate_service_account
}

provider "google" {
  impersonate_service_account = var.impersonate_service_account
}

module "google_organization" {
  source          = "../.."
  organization_id = var.organization_id

  org_policy_custom_constraints = {
    "custom.gkeEnableAutoUpgrade" = {
      resource_types = ["container.googleapis.com/NodePool"]
      method_types   = ["CREATE"]
      condition      = "resource.management.autoUpgrade == true"
      action_type    = "ALLOW"
      display_name   = "Enable node auto-upgrade"
      description    = "All node pools must have node auto-upgrade enabled."
    }
  }

  # not necessarily to enforce on the org level, policy may be applied on folder/project levels
  org_policies = {
    "custom.gkeEnableAutoUpgrade" = {
      enforce = true
    }
  }
}
```

### Custom Constraints Factory

Org policy custom constraints can be loaded from a directory containing YAML files where each file defines one or more custom constraints. The structure of the YAML files is exactly the same as the `org_policy_custom_constraints` variable.

The example below deploys a few org policy custom constraints split between two YAML files.

```hcl
variable "organization_id" {
  description = "Organization id in organizations/nnnnnn format."
  type        = string
}

variable "impersonate_service_account" {
  description = "Mail of service account to impersonate, because ADC not supported."
}


# Make sure to impersonate an service account
# gcloud application-default not supported
provider "google-beta" {
  impersonate_service_account = var.impersonate_service_account
}

provider "google" {
  impersonate_service_account = var.impersonate_service_account
}

module "org" {
  source          = "../../"
  organization_id = var.organization_id

  org_policy_custom_constraints_data_path = "custom_constraints"
}
```

The following two files are in the folder `custom_constrains`.

```yaml
custom.dataprocNoMoreThan10Workers:
  resource_types:
  - dataproc.googleapis.com/Cluster
  method_types:
  - CREATE
  - UPDATE
  condition: resource.config.workerConfig.numInstances + resource.config.secondaryWorkerConfig.numInstances > 10
  action_type: DENY
  display_name: Total number of worker instances cannot be larger than 10
  description: Cluster cannot have more than 10 workers, including primary and secondary workers.
```

```yaml
custom.gkeEnableLogging:
  resource_types:
  - container.googleapis.com/Cluster
  method_types:
  - CREATE
  - UPDATE
  condition: resource.loggingService == "none"
  action_type: DENY
  display_name: Do not disable Cloud Logging
custom.gkeEnableAutoUpgrade:
  resource_types:
  - container.googleapis.com/NodePool
  method_types:
  - CREATE
  condition: resource.management.autoUpgrade == true
  action_type: ALLOW
  display_name: Enable node auto-upgrade
  description: All node pools must have node auto-upgrade enabled.
```

### Hierarchical firewall policies

Hierarchical firewall policies can be managed in two ways:

- via the `firewall_policies` variable, to directly define policies and rules in Terraform
- via the `firewall_policy_factory` variable, to leverage external YaML files via a simple "factory" embedded in the module ([see here](../../blueprints/factories) for more context on factories)

Once you have policies (either created via the module or externally), you can associate them using the `firewall_policy_association` variable.

#### Directly defined firewall policies

```hcl
variable "organization_id" {
  description = "Organization id in organizations/nnnnnn format."
  type        = string
}


module "google_organization_configuration" {
  source          = "../.."
  organization_id = var.organization_id
  firewall_policies = {
    iap-policy = {
      allow-iap-ssh = {
        description = "Always allow ssh from IAP."
        direction   = "INGRESS"
        action      = "allow"
        priority    = 100
        ranges      = ["35.235.240.0/20"]
        ports = {
          tcp = ["22"]
        }
        target_service_accounts = null
        target_resources        = null
        logging                 = false
      }
    }
  }
  firewall_policy_association = {
    iap_policy = "iap-policy"
  }
}
```

#### Firewall policy factory

The in-built factory allows you to define a single policy, using one file for rules, and an optional file for CIDR range substitution variables. Remember that non-absolute paths are relative to the root module (the folder where you run `terraform`).

```hcl
variable "organization_id" {
  description = "Organization id in organizations/nnnnnn format."
  type        = string
}


module "google_organization_configuration" {
  source          = "../.."
  organization_id = var.organization_id
  firewall_policy_factory = {
    cidr_file   = "./cidrs.yaml"
    policy_name = null
    rules_file  = "./rules.yaml"
  }
  firewall_policy_association = {
    factory-policy = module.google_organization_configuration.firewall_policy_id["factory"]
  }
}
```

The following two files must exist in the root of the configuration.

`cidrs.yaml`
```yaml
rfc1918:
  - 10.0.0.0/8
  - 172.16.0.0/12
  - 192.168.0.0/16
```

`rules.yml`
```yaml
allow-admins:
  description: Access from the admin subnet to all subnets
  direction: INGRESS
  action: allow
  priority: 1000
  ranges:
    - $rfc1918
  ports:
    all: []
  target_resources: null
  enable_logging: false

allow-ssh-from-iap:
  description: Enable SSH from IAP
  direction: INGRESS
  action: allow
  priority: 1002
  ranges:
    - 35.235.240.0/20
  ports:
    tcp: ["22"]
  target_resources: null
  enable_logging: false
```

### Logging Sinks

```hcl
variable "organization_id" {
  description = "Organization id in organizations/nnnnnn format."
  type        = string
}

variable "project_id" {
  description = "The id of the project to deploy the logging sinks to."
  type        = string
}


resource "random_id" "gcs" {
  byte_length = 16
}

resource "google_storage_bucket" "this" {
  name          = random_id.gcs.hex
  location      = "EU"
  force_destroy = true
  project       = var.project_id
}

# Also big query-datasets, pubsub, loggingbucket is supported
module "google_organization_configuration" {
  source          = "../.."
  organization_id = var.organization_id

  logging_sinks = {
    warnings = {
      destination = google_storage_bucket.this.id
      filter      = "severity=WARNING"
      type        = "storage"
    }
  }
  logging_exclusions = {
    no-gce-instances = "resource.type=gce_instance"
  }
}
```

### Custom Roles

```hcl
variable "organization_id" {
  description = "Organization id in organizations/nnnnnn format."
  type        = string
}


data "google_client_openid_userinfo" "provider_identity" {
}

module "google_organization_configuration" {
  source          = "../.."
  organization_id = var.organization_id
  custom_roles = {
    "myRole" = [
      "compute.instances.list",
    ]
  }
  iam = {
    (module.google_organization_configuration.custom_role_id.myRole) = ["user:${data.google_client_openid_userinfo.provider_identity.email}"]
  }
}
```

### Tags

Refer to the [Creating and managing tags](https://cloud.google.com/resource-manager/docs/tags/tags-creating-and-managing) documentation for details on usage.

```hcl
variable "organization_id" {
  description = "Organization id in organizations/nnnnnn format."
  type        = string
}


data "google_client_openid_userinfo" "provider_identity" {
}

module "google_organization_configuration" {
  source          = "../.."
  organization_id = var.organization_id
  tags = {
    environment = {
      description = "Environment specification."
      iam = {
        "roles/resourcemanager.tagAdmin" = ["user:${data.google_client_openid_userinfo.provider_identity.email}"]
      }
      values = {
        dev = {}
        prod = {
          description = "Environment: production."
          iam = {
            "roles/resourcemanager.tagViewer" = ["user:${data.google_client_openid_userinfo.provider_identity.email}"]
          }
        }
      }
    }
  }
  tag_bindings = {
    env-prod = module.google_organization_configuration.tag_values["environment/prod"].id
  }
}
```

You can also define network tags, through a dedicated variable `network_tags`.

```hcl
variable "organization_id" {
  description = "Organization id in organizations/nnnnnn format."
  type        = string
}

variable "project_id" {
  description = "The id of the project to deploy the network to."
  type        = string
}


data "google_client_openid_userinfo" "provider_identity" {
}

resource "google_compute_network" "this" {
  name    = "vpc-network"
  project = var.project_id
}

module "google_organization_configuration" {
  source          = "../.."
  organization_id = var.organization_id
  network_tags = {
    net-environment = {
      description = "This is a network tag."
      network     = "${var.project_id}/${google_compute_network.this.name}"
      iam = {
        "roles/resourcemanager.tagAdmin" = ["user:${data.google_client_openid_userinfo.provider_identity.email}"]
      }
      values = {
        dev = null
        prod = {
          description = "Environment: production."
          iam = {
            "roles/resourcemanager.tagUser" = ["user:${data.google_client_openid_userinfo.provider_identity.email}"]
          }
        }
      }
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.1 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.40.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 4.40.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | Organization id in organizations/nnnnnn format. | `string` | n/a | yes |
| <a name="input_contacts"></a> [contacts](#input\_contacts) | List of essential contacts for this resource. Must be in the form EMAIL -> [NOTIFICATION\_TYPES]. Valid notification types are ALL, SUSPENSION, SECURITY, TECHNICAL, BILLING, LEGAL, PRODUCT\_UPDATES. | `map(list(string))` | `{}` | no |
| <a name="input_custom_roles"></a> [custom\_roles](#input\_custom\_roles) | Map of role name => list of permissions to create in this project. | `map(list(string))` | `{}` | no |
| <a name="input_firewall_policies"></a> [firewall\_policies](#input\_firewall\_policies) | Hierarchical firewall policy rules created in the organization. | <pre>map(map(object({<br>    action                  = string<br>    description             = string<br>    direction               = string<br>    logging                 = bool<br>    ports                   = map(list(string))<br>    priority                = number<br>    ranges                  = list(string)<br>    target_resources        = list(string)<br>    target_service_accounts = list(string)<br>    # preview                 = bool<br>  })))</pre> | `{}` | no |
| <a name="input_firewall_policy_association"></a> [firewall\_policy\_association](#input\_firewall\_policy\_association) | The hierarchical firewall policy to associate to this folder. Must be either a key in the `firewall_policies` map or the id of a policy defined somewhere else. | `map(string)` | `{}` | no |
| <a name="input_firewall_policy_factory"></a> [firewall\_policy\_factory](#input\_firewall\_policy\_factory) | Configuration for the firewall policy factory. | <pre>object({<br>    cidr_file   = string<br>    policy_name = string<br>    rules_file  = string<br>  })</pre> | `null` | no |
| <a name="input_group_iam"></a> [group\_iam](#input\_group\_iam) | Authoritative IAM binding for organization groups, in {GROUP\_EMAIL => [ROLES]} format. Group emails need to be static. Can be used in combination with the `iam` variable. | `map(list(string))` | `{}` | no |
| <a name="input_iam"></a> [iam](#input\_iam) | IAM bindings, in {ROLE => [MEMBERS]} format. | `map(list(string))` | `{}` | no |
| <a name="input_iam_additive"></a> [iam\_additive](#input\_iam\_additive) | Non authoritative IAM bindings, in {ROLE => [MEMBERS]} format. | `map(list(string))` | `{}` | no |
| <a name="input_iam_additive_members"></a> [iam\_additive\_members](#input\_iam\_additive\_members) | IAM additive bindings in {MEMBERS => [ROLE]} format. This might break if members are dynamic values. | `map(list(string))` | `{}` | no |
| <a name="input_iam_audit_config"></a> [iam\_audit\_config](#input\_iam\_audit\_config) | Service audit logging configuration. Service as key, map of log permission (eg DATA\_READ) and excluded members as value for each service. | `map(map(list(string)))` | `{}` | no |
| <a name="input_iam_audit_config_authoritative"></a> [iam\_audit\_config\_authoritative](#input\_iam\_audit\_config\_authoritative) | IAM Authoritative service audit logging configuration. Service as key, map of log permission (eg DATA\_READ) and excluded members as value for each service. Audit config should also be authoritative when using authoritative bindings. Use with caution. | `map(map(list(string)))` | `null` | no |
| <a name="input_iam_bindings_authoritative"></a> [iam\_bindings\_authoritative](#input\_iam\_bindings\_authoritative) | IAM authoritative bindings, in {ROLE => [MEMBERS]} format. Roles and members not explicitly listed will be cleared. Bindings should also be authoritative when using authoritative audit config. Use with caution. | `map(list(string))` | `null` | no |
| <a name="input_logging_exclusions"></a> [logging\_exclusions](#input\_logging\_exclusions) | Logging exclusions for this organization in the form {NAME -> FILTER}. | `map(string)` | `{}` | no |
| <a name="input_logging_sinks"></a> [logging\_sinks](#input\_logging\_sinks) | Logging sinks to create for the organization. | <pre>map(object({<br>    bq_partitioned_table = optional(bool)<br>    description          = optional(string)<br>    destination          = string<br>    disabled             = optional(bool, false)<br>    exclusions           = optional(map(string), {})<br>    filter               = string<br>    include_children     = optional(bool, true)<br>    type                 = string<br>  }))</pre> | `{}` | no |
| <a name="input_network_tags"></a> [network\_tags](#input\_network\_tags) | Network tags by key name. The `iam` attribute behaves like the similarly named one at module level. | <pre>map(object({<br>    description = optional(string, "Managed by the Terraform organization module.")<br>    iam         = optional(map(list(string)), {})<br>    network     = string # project_id/vpc_name<br>    values = optional(map(object({<br>      description = optional(string, "Managed by the Terraform organization module.")<br>      iam         = optional(map(list(string)), {})<br>    })), {})<br>  }))</pre> | `{}` | no |
| <a name="input_org_policies"></a> [org\_policies](#input\_org\_policies) | Organization policies applied to this organization keyed by policy name. | <pre>map(object({<br>    inherit_from_parent = optional(bool) # for list policies only.<br>    reset               = optional(bool)<br><br>    # default (unconditional) values<br>    allow = optional(object({<br>      all    = optional(bool)<br>      values = optional(list(string))<br>    }))<br>    deny = optional(object({<br>      all    = optional(bool)<br>      values = optional(list(string))<br>    }))<br>    enforce = optional(bool, true) # for boolean policies only.<br><br>    # conditional values<br>    rules = optional(list(object({<br>      allow = optional(object({<br>        all    = optional(bool)<br>        values = optional(list(string))<br>      }))<br>      deny = optional(object({<br>        all    = optional(bool)<br>        values = optional(list(string))<br>      }))<br>      enforce = optional(bool, true) # for boolean policies only.<br>      condition = object({<br>        description = optional(string)<br>        expression  = optional(string)<br>        location    = optional(string)<br>        title       = optional(string)<br>      })<br>    })), [])<br>  }))</pre> | `{}` | no |
| <a name="input_org_policies_data_path"></a> [org\_policies\_data\_path](#input\_org\_policies\_data\_path) | Path containing org policies in YAML format. | `string` | `null` | no |
| <a name="input_org_policy_custom_constraints"></a> [org\_policy\_custom\_constraints](#input\_org\_policy\_custom\_constraints) | Organization policiy custom constraints keyed by constraint name. | <pre>map(object({<br>    display_name   = optional(string)<br>    description    = optional(string)<br>    action_type    = string<br>    condition      = string<br>    method_types   = list(string)<br>    resource_types = list(string)<br>  }))</pre> | `{}` | no |
| <a name="input_org_policy_custom_constraints_data_path"></a> [org\_policy\_custom\_constraints\_data\_path](#input\_org\_policy\_custom\_constraints\_data\_path) | Path containing org policy custom constraints in YAML format. | `string` | `null` | no |
| <a name="input_tag_bindings"></a> [tag\_bindings](#input\_tag\_bindings) | Tag bindings for this organization, in key => tag value id format. | `map(string)` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags by key name. The `iam` attribute behaves like the similarly named one at module level. | <pre>map(object({<br>    description = optional(string, "Managed by the Terraform organization module.")<br>    iam         = optional(map(list(string)), {})<br>    values = optional(map(object({<br>      description = optional(string, "Managed by the Terraform organization module.")<br>      iam         = optional(map(list(string)), {})<br>    })), {})<br>  }))</pre> | `{}` | no |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_custom_role_id"></a> [custom\_role\_id](#output\_custom\_role\_id) | Map of custom role IDs created in the organization. |
| <a name="output_custom_roles"></a> [custom\_roles](#output\_custom\_roles) | Map of custom roles resources created in the organization. |
| <a name="output_firewall_policies"></a> [firewall\_policies](#output\_firewall\_policies) | Map of firewall policy resources created in the organization. |
| <a name="output_firewall_policy_id"></a> [firewall\_policy\_id](#output\_firewall\_policy\_id) | Map of firewall policy ids created in the organization. |
| <a name="output_network_tag_keys"></a> [network\_tag\_keys](#output\_network\_tag\_keys) | Tag key resources. |
| <a name="output_network_tag_values"></a> [network\_tag\_values](#output\_network\_tag\_values) | Tag value resources. |
| <a name="output_organization_id"></a> [organization\_id](#output\_organization\_id) | Organization id dependent on module resources. |
| <a name="output_sink_writer_identities"></a> [sink\_writer\_identities](#output\_sink\_writer\_identities) | Writer identities created for each sink. |
| <a name="output_tag_keys"></a> [tag\_keys](#output\_tag\_keys) | Tag key resources. |
| <a name="output_tag_values"></a> [tag\_values](#output\_tag\_values) | Tag value resources. |

## Resource types

| Type | Used |
|------|-------|
| [google-beta_google_essential_contacts_contact](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_essential_contacts_contact) | 1 |
| [google-beta_google_org_policy_custom_constraint](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_org_policy_custom_constraint) | 1 |
| [google_bigquery_dataset_iam_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset_iam_member) | 1 |
| [google_compute_firewall_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall_policy) | 1 |
| [google_compute_firewall_policy_association](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall_policy_association) | 1 |
| [google_compute_firewall_policy_rule](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall_policy_rule) | 1 |
| [google_logging_organization_exclusion](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_organization_exclusion) | 1 |
| [google_logging_organization_sink](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_organization_sink) | 1 |
| [google_org_policy_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/org_policy_policy) | 1 |
| [google_organization_iam_audit_config](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_audit_config) | 1 |
| [google_organization_iam_binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_binding) | 1 |
| [google_organization_iam_custom_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_custom_role) | 1 |
| [google_organization_iam_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_member) | 1 |
| [google_organization_iam_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_policy) | 1 |
| [google_project_iam_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | 1 |
| [google_pubsub_topic_iam_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | 1 |
| [google_storage_bucket_iam_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | 1 |
| [google_tags_tag_binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_binding) | 1 |
| [google_tags_tag_key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_key) | 1 |
| [google_tags_tag_key_iam_binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_key_iam_binding) | 1 |
| [google_tags_tag_value](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_value) | 1 |
| [google_tags_tag_value_iam_binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_value_iam_binding) | 1 |

**`Used` only includes resource blocks.** `for_each` and `count` meta arguments, as well as resource blocks of modules are not considered.

## Modules

No modules.

## Resources by Files

### firewall-policies.tf

| Name | Type |
|------|------|
| [google_compute_firewall_policy.policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall_policy) | resource |
| [google_compute_firewall_policy_association.association](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall_policy_association) | resource |
| [google_compute_firewall_policy_rule.rule](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall_policy_rule) | resource |

### iam.tf

| Name | Type |
|------|------|
| [google_organization_iam_audit_config.config](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_audit_config) | resource |
| [google_organization_iam_binding.authoritative](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_binding) | resource |
| [google_organization_iam_custom_role.roles](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_custom_role) | resource |
| [google_organization_iam_member.additive](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_member) | resource |
| [google_organization_iam_policy.authoritative](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_policy) | resource |
| [google_iam_policy.authoritative](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |

### logging.tf

| Name | Type |
|------|------|
| [google_bigquery_dataset_iam_member.bq-sinks-binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset_iam_member) | resource |
| [google_logging_organization_exclusion.logging-exclusion](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_organization_exclusion) | resource |
| [google_logging_organization_sink.sink](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_organization_sink) | resource |
| [google_project_iam_member.bucket-sinks-binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_pubsub_topic_iam_member.pubsub-sinks-binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |
| [google_storage_bucket_iam_member.storage-sinks-binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |

### main.tf

| Name | Type |
|------|------|
| [google-beta_google_essential_contacts_contact.contact](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_essential_contacts_contact) | resource |

### org-policy-custom-constraints.tf

| Name | Type |
|------|------|
| [google-beta_google_org_policy_custom_constraint.constraint](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_org_policy_custom_constraint) | resource |

### organization-policies.tf

| Name | Type |
|------|------|
| [google_org_policy_policy.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/org_policy_policy) | resource |

### tags.tf

| Name | Type |
|------|------|
| [google_tags_tag_binding.binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_binding) | resource |
| [google_tags_tag_key.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_key) | resource |
| [google_tags_tag_key_iam_binding.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_key_iam_binding) | resource |
| [google_tags_tag_value.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_value) | resource |
| [google_tags_tag_value_iam_binding.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_value_iam_binding) | resource |
<!-- END_TF_DOCS -->