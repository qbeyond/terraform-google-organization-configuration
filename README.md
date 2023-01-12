# Organization Module

This module allows managing several organization properties:

- IAM bindings, both authoritative and additive
- custom IAM roles
- audit logging configuration for services
- organization policies
- organization policy custom constraints

To manage organization policies, the `orgpolicy.googleapis.com` service should be enabled in the quota project. Furthermore you need to use a service account. **End user credentials are not supported!**

## Example

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = "organizations/1234567890"
  group_iam       = {
    "cloud-owners@example.org" = ["roles/owner", "roles/projectCreator"]
  }
  iam             = {
    "roles/resourcemanager.projectCreator" = ["group:cloud-admins@example.org"]
  }

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

  org_policies = {
    "custom.gkeEnableAutoUpgrade" = {
      enforce = true
    }
    "compute.disableGuestAttributesAccess" = {
      enforce = true
    }
    "constraints/compute.skipDefaultNetworkCreation" = {
      enforce = true
    }
    "iam.disableServiceAccountKeyCreation" = {
      enforce = true
    }
    "iam.disableServiceAccountKeyUpload" = {
      enforce = false
      rules = [
        {
          condition = {
            expression  = "resource.matchTagId(\"tagKeys/1234\", \"tagValues/1234\")"
            title       = "condition"
            description = "test condition"
            location    = "somewhere"
          }
          enforce = true
        }
      ]
    }
    "constraints/iam.allowedPolicyMemberDomains" = {
      allow = {
        values = ["C0xxxxxxx", "C0yyyyyyy"]
      }
    }
    "constraints/compute.trustedImageProjects" = {
      allow = {
        values = ["projects/my-project"]
      }
    }
    "constraints/compute.vmExternalIpAccess" = {
      deny = { all = true }
    }
  }
}
# tftest modules=1 resources=12
```

## IAM

There are several mutually exclusive ways of managing IAM in this module

- non-authoritative via the `iam_additive` and `iam_additive_members` variables, where bindings created outside this module will coexist with those managed here
- authoritative via the `group_iam` and `iam` variables, where bindings created outside this module (eg in the console) will be removed at each `terraform apply` cycle if the same role is also managed here
- authoritative policy via the `iam_bindings_authoritative` variable, where any binding created outside this module (eg in the console) will be removed at each `terraform apply` cycle regardless of the role

If you set audit policies via the `iam_audit_config_authoritative` variable, be sure to also configure IAM bindings via `iam_bindings_authoritative`, as audit policies use the underlying `google_organization_iam_policy` resource, which is also authoritative for any role.

Some care must also be taken with the `groups_iam` variable (and in some situations with the additive variables) to ensure that variable keys are static values, so that Terraform is able to compute the dependency graph.

### Organization policy factory

See the [organization policy factory in the project module](../project#organization-policy-factory).

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->

## Files

| name                                                                   | description                                      | resources                                                                                                                                                                                                                                                                                   |
| ---------------------------------------------------------------------- | ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [firewall-policies.tf](./firewall-policies.tf)                         | Hierarchical firewall policies.                  | <code>google_compute_firewall_policy</code> · <code>google_compute_firewall_policy_association</code> · <code>google_compute_firewall_policy_rule</code>                                                                                                                                    |
| [iam.tf](./iam.tf)                                                     | IAM bindings, roles and audit logging resources. | <code>google_organization_iam_audit_config</code> · <code>google_organization_iam_binding</code> · <code>google_organization_iam_custom_role</code> · <code>google_organization_iam_member</code> · <code>google_organization_iam_policy</code>                                             |
| [logging.tf](./logging.tf)                                             | Log sinks and supporting resources.              | <code>google_bigquery_dataset_iam_member</code> · <code>google_logging_organization_exclusion</code> · <code>google_logging_organization_sink</code> · <code>google_project_iam_member</code> · <code>google_pubsub_topic_iam_member</code> · <code>google_storage_bucket_iam_member</code> |
| [main.tf](./main.tf)                                                   | Module-level locals and resources.               | <code>google_essential_contacts_contact</code>                                                                                                                                                                                                                                              |
| [org-policy-custom-constraints.tf](./org-policy-custom-constraints.tf) | None                                             | <code>google_org_policy_custom_constraint</code>                                                                                                                                                                                                                                            |
| [organization-policies.tf](./organization-policies.tf)                 | Organization-level organization policies.        | <code>google_org_policy_policy</code>                                                                                                                                                                                                                                                       |
| [outputs.tf](./outputs.tf)                                             | Module outputs.                                  |                                                                                                                                                                                                                                                                                             |
| [tags.tf](./tags.tf)                                                   | None                                             | <code>google_tags_tag_binding</code> · <code>google_tags_tag_key</code> · <code>google_tags_tag_key_iam_binding</code> · <code>google_tags_tag_value</code> · <code>google_tags_tag_value_iam_binding</code>                                                                                |
| [variables.tf](./variables.tf)                                         | Module variables.                                |                                                                                                                                                                                                                                                                                             |
| [versions.tf](./versions.tf)                                           | Version pins.                                    |                                                                                                                                                                                                                                                                                             |

## Variables

| name                                                         | description                                                                                                                                                                                                                                                |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | required |          default          |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :------: | :-----------------------: |
| [organization_id](variables.tf#L246)                         | Organization id in organizations/nnnnnn format.                                                                                                                                                                                                            |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           <code>string</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |    ✓     |                           |
| [contacts](variables.tf#L17)                                 | List of essential contacts for this resource. Must be in the form EMAIL -> [NOTIFICATION_TYPES]. Valid notification types are ALL, SUSPENSION, SECURITY, TECHNICAL, BILLING, LEGAL, PRODUCT_UPDATES.                                                       |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              <code>map&#40;list&#40;string&#41;&#41;</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |          | <code>&#123;&#125;</code> |
| [custom_roles](variables.tf#L24)                             | Map of role name => list of permissions to create in this project.                                                                                                                                                                                         |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              <code>map&#40;list&#40;string&#41;&#41;</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |          | <code>&#123;&#125;</code> |
| [firewall_policies](variables.tf#L31)                        | Hierarchical firewall policy rules created in the organization.                                                                                                                                                                                            |                                                                                                                                                                                                                                                                                                                                                                                                                                                                           <code title="map&#40;map&#40;object&#40;&#123;&#10;  action                  &#61; string&#10;  description             &#61; string&#10;  direction               &#61; string&#10;  logging                 &#61; bool&#10;  ports                   &#61; map&#40;list&#40;string&#41;&#41;&#10;  priority                &#61; number&#10;  ranges                  &#61; list&#40;string&#41;&#10;  target_resources        &#61; list&#40;string&#41;&#10;  target_service_accounts &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;&#41;">map&#40;map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;&#41;</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |          | <code>&#123;&#125;</code> |
| [firewall_policy_association](variables.tf#L48)              | The hierarchical firewall policy to associate to this folder. Must be either a key in the `firewall_policies` map or the id of a policy defined somewhere else.                                                                                            |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     <code>map&#40;string&#41;</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |          | <code>&#123;&#125;</code> |
| [firewall_policy_factory](variables.tf#L55)                  | Configuration for the firewall policy factory.                                                                                                                                                                                                             |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         <code title="object&#40;&#123;&#10;  cidr_file   &#61; string&#10;  policy_name &#61; string&#10;  rules_file  &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |          |     <code>null</code>     |
| [group_iam](variables.tf#L65)                                | Authoritative IAM binding for organization groups, in {GROUP_EMAIL => [ROLES]} format. Group emails need to be static. Can be used in combination with the `iam` variable.                                                                                 |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              <code>map&#40;list&#40;string&#41;&#41;</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |          | <code>&#123;&#125;</code> |
| [iam](variables.tf#L72)                                      | IAM bindings, in {ROLE => [MEMBERS]} format.                                                                                                                                                                                                               |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              <code>map&#40;list&#40;string&#41;&#41;</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |          | <code>&#123;&#125;</code> |
| [iam_additive](variables.tf#L79)                             | Non authoritative IAM bindings, in {ROLE => [MEMBERS]} format.                                                                                                                                                                                             |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              <code>map&#40;list&#40;string&#41;&#41;</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |          | <code>&#123;&#125;</code> |
| [iam_additive_members](variables.tf#L86)                     | IAM additive bindings in {MEMBERS => [ROLE]} format. This might break if members are dynamic values.                                                                                                                                                       |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              <code>map&#40;list&#40;string&#41;&#41;</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |          | <code>&#123;&#125;</code> |
| [iam_audit_config](variables.tf#L93)                         | Service audit logging configuration. Service as key, map of log permission (eg DATA_READ) and excluded members as value for each service.                                                                                                                  |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       <code>map&#40;map&#40;list&#40;string&#41;&#41;&#41;</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |          | <code>&#123;&#125;</code> |
| [iam_audit_config_authoritative](variables.tf#L105)          | IAM Authoritative service audit logging configuration. Service as key, map of log permission (eg DATA_READ) and excluded members as value for each service. Audit config should also be authoritative when using authoritative bindings. Use with caution. |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       <code>map&#40;map&#40;list&#40;string&#41;&#41;&#41;</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |          |     <code>null</code>     |
| [iam_bindings_authoritative](variables.tf#L116)              | IAM authoritative bindings, in {ROLE => [MEMBERS]} format. Roles and members not explicitly listed will be cleared. Bindings should also be authoritative when using authoritative audit config. Use with caution.                                         |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              <code>map&#40;list&#40;string&#41;&#41;</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |          |     <code>null</code>     |
| [logging_exclusions](variables.tf#L122)                      | Logging exclusions for this organization in the form {NAME -> FILTER}.                                                                                                                                                                                     |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     <code>map&#40;string&#41;</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |          | <code>&#123;&#125;</code> |
| [logging_sinks](variables.tf#L129)                           | Logging sinks to create for the organization.                                                                                                                                                                                                              |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             <code title="map&#40;object&#40;&#123;&#10;  bq_partitioned_table &#61; optional&#40;bool&#41;&#10;  description          &#61; optional&#40;string&#41;&#10;  destination          &#61; string&#10;  disabled             &#61; optional&#40;bool, false&#41;&#10;  exclusions           &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  filter               &#61; string&#10;  include_children     &#61; optional&#40;bool, true&#41;&#10;  type                 &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |          | <code>&#123;&#125;</code> |
| [network_tags](variables.tf#L159)                            | Network tags by key name. The `iam` attribute behaves like the similarly named one at module level.                                                                                                                                                        |                                                                                                                                                                                                                                                                                                                                                                                                                                    <code title="map&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string, &#34;Managed by the Terraform organization module.&#34;&#41;&#10;  iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  network     &#61; string &#35; project_id&#47;vpc_name&#10;  values &#61; optional&#40;map&#40;object&#40;&#123;&#10;    description &#61; optional&#40;string, &#34;Managed by the Terraform organization module.&#34;&#41;&#10;    iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code>                                                                                                                                                                                                                                                                                                                                                                                                                                     |          | <code>&#123;&#125;</code> |
| [org_policies](variables.tf#L180)                            | Organization policies applied to this organization keyed by policy name.                                                                                                                                                                                   | <code title="map&#40;object&#40;&#123;&#10;  inherit_from_parent &#61; optional&#40;bool&#41; &#35; for list policies only.&#10;  reset               &#61; optional&#40;bool&#41;&#10;  allow &#61; optional&#40;object&#40;&#123;&#10;    all    &#61; optional&#40;bool&#41;&#10;    values &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  deny &#61; optional&#40;object&#40;&#123;&#10;    all    &#61; optional&#40;bool&#41;&#10;    values &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  enforce &#61; optional&#40;bool, true&#41; &#35; for boolean policies only.&#10;  rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;    allow &#61; optional&#40;object&#40;&#123;&#10;      all    &#61; optional&#40;bool&#41;&#10;      values &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    deny &#61; optional&#40;object&#40;&#123;&#10;      all    &#61; optional&#40;bool&#41;&#10;      values &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    enforce &#61; optional&#40;bool, true&#41; &#35; for boolean policies only.&#10;    condition &#61; object&#40;&#123;&#10;      description &#61; optional&#40;string&#41;&#10;      expression  &#61; optional&#40;string&#41;&#10;      location    &#61; optional&#40;string&#41;&#10;      title       &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#10;  &#125;&#41;&#41;, &#91;&#93;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |          | <code>&#123;&#125;</code> |
| [org_policies_data_path](variables.tf#L220)                  | Path containing org policies in YAML format.                                                                                                                                                                                                               |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           <code>string</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |          |     <code>null</code>     |
| [org_policy_custom_constraints](variables.tf#L226)           | Organization policiy custom constraints keyed by constraint name.                                                                                                                                                                                          |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     <code title="map&#40;object&#40;&#123;&#10;  display_name   &#61; optional&#40;string&#41;&#10;  description    &#61; optional&#40;string&#41;&#10;  action_type    &#61; string&#10;  condition      &#61; string&#10;  method_types   &#61; list&#40;string&#41;&#10;  resource_types &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |          | <code>&#123;&#125;</code> |
| [org_policy_custom_constraints_data_path](variables.tf#L240) | Path containing org policy custom constraints in YAML format.                                                                                                                                                                                              |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           <code>string</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |          |     <code>null</code>     |
| [tag_bindings](variables.tf#L255)                            | Tag bindings for this organization, in key => tag value id format.                                                                                                                                                                                         |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     <code>map&#40;string&#41;</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |          |     <code>null</code>     |
| [tags](variables.tf#L261)                                    | Tags by key name. The `iam` attribute behaves like the similarly named one at module level.                                                                                                                                                                |                                                                                                                                                                                                                                                                                                                                                                                                                                                                   <code title="map&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string, &#34;Managed by the Terraform organization module.&#34;&#41;&#10;  iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  values &#61; optional&#40;map&#40;object&#40;&#123;&#10;    description &#61; optional&#40;string, &#34;Managed by the Terraform organization module.&#34;&#41;&#10;    iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |          | <code>&#123;&#125;</code> |

## Outputs

| name                                     | description                                                   | sensitive |
| ---------------------------------------- | ------------------------------------------------------------- | :-------: |
| [custom_role_id](outputs.tf#L17)         | Map of custom role IDs created in the organization.           |           |
| [custom_roles](outputs.tf#L30)           | Map of custom roles resources created in the organization.    |           |
| [firewall_policies](outputs.tf#L35)      | Map of firewall policy resources created in the organization. |           |
| [firewall_policy_id](outputs.tf#L40)     | Map of firewall policy ids created in the organization.       |           |
| [network_tag_keys](outputs.tf#L45)       | Tag key resources.                                            |           |
| [network_tag_values](outputs.tf#L54)     | Tag value resources.                                          |           |
| [organization_id](outputs.tf#L65)        | Organization id dependent on module resources.                |           |
| [sink_writer_identities](outputs.tf#L82) | Writer identities created for each sink.                      |           |
| [tag_keys](outputs.tf#L90)               | Tag key resources.                                            |           |
| [tag_values](outputs.tf#L99)             | Tag value resources.                                          |           |

<!-- END TFDOC -->

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

module "gcs" {
  source        = "qbeyond/gcs/google"
  version       = "0.1.0"
  project_id    = var.project_id
  name          = random_id.gcs.hex
  force_destroy = true
}

# Also big query-datasets, pubsub, loggingbucket is supported
module "google_organization_configuration" {
  source          = "../.."
  organization_id = var.organization_id

  logging_sinks = {
    warnings = {
      destination = module.gcs.id
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

### ..\..\firewall-policies.tf

| Name | Type |
|------|------|
| [google_compute_firewall_policy.policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall_policy) | resource |
| [google_compute_firewall_policy_association.association](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall_policy_association) | resource |
| [google_compute_firewall_policy_rule.rule](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall_policy_rule) | resource |

### ..\..\iam.tf

| Name | Type |
|------|------|
| [google_organization_iam_audit_config.config](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_audit_config) | resource |
| [google_organization_iam_binding.authoritative](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_binding) | resource |
| [google_organization_iam_custom_role.roles](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_custom_role) | resource |
| [google_organization_iam_member.additive](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_member) | resource |
| [google_organization_iam_policy.authoritative](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_policy) | resource |
| [google_iam_policy.authoritative](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |

### ..\..\logging.tf

| Name | Type |
|------|------|
| [google_bigquery_dataset_iam_member.bq-sinks-binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset_iam_member) | resource |
| [google_logging_organization_exclusion.logging-exclusion](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_organization_exclusion) | resource |
| [google_logging_organization_sink.sink](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_organization_sink) | resource |
| [google_project_iam_member.bucket-sinks-binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_pubsub_topic_iam_member.pubsub-sinks-binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |
| [google_storage_bucket_iam_member.storage-sinks-binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |

### ..\..\main.tf

| Name | Type |
|------|------|
| [google-beta_google_essential_contacts_contact.contact](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_essential_contacts_contact) | resource |

### ..\..\org-policy-custom-constraints.tf

| Name | Type |
|------|------|
| [google-beta_google_org_policy_custom_constraint.constraint](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_org_policy_custom_constraint) | resource |

### ..\..\organization-policies.tf

| Name | Type |
|------|------|
| [google_org_policy_policy.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/org_policy_policy) | resource |

### ..\..\tags.tf

| Name | Type |
|------|------|
| [google_tags_tag_binding.binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_binding) | resource |
| [google_tags_tag_key.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_key) | resource |
| [google_tags_tag_key_iam_binding.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_key_iam_binding) | resource |
| [google_tags_tag_value.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_value) | resource |
| [google_tags_tag_value_iam_binding.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_value_iam_binding) | resource |
<!-- END_TF_DOCS -->