/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# tfdoc:file:description Organization-level organization policies.

locals {
  _factory_data_raw = (
    var.org_policies_data_path == null
    ? tomap({})
    : merge([
      for f in fileset(var.org_policies_data_path, "*.yaml") :
      yamldecode(file("${var.org_policies_data_path}/${f}"))
    ]...)
  )

  # simulate applying defaults to data coming from yaml files
  _factory_data = {
    for k, v in local._factory_data_raw :
    k => {
      inherit_from_parent = try(v.inherit_from_parent, null)
      reset               = try(v.reset, null)
      allow = can(v.allow) ? {
        all    = try(v.allow.all, null)
        values = try(v.allow.values, null)
      } : null
      deny = can(v.deny) ? {
        all    = try(v.deny.all, null)
        values = try(v.deny.values, null)
      } : null
      enforce = try(v.enforce, true)

      rules = [
        for r in try(v.rules, []) : {
          allow = can(r.allow) ? {
            all    = try(r.allow.all, null)
            values = try(r.allow.values, null)
          } : null
          deny = can(r.deny) ? {
            all    = try(r.deny.all, null)
            values = try(r.deny.values, null)
          } : null
          enforce = try(r.enforce, true)
          condition = {
            description = try(r.condition.description, null)
            expression  = try(r.condition.expression, null)
            location    = try(r.condition.location, null)
            title       = try(r.condition.title, null)
          }
        }
      ]
    }
  }

  _org_policies = merge(local._factory_data, var.org_policies)

  org_policies = {
    for k, v in local._org_policies :
    k => merge(v, {
      name   = "${var.organization_id}/policies/${k}"
      parent = var.organization_id

      is_boolean_policy = v.allow == null && v.deny == null
      has_values = (
        length(coalesce(try(v.allow.values, []), [])) > 0 ||
        length(coalesce(try(v.deny.values, []), [])) > 0
      )
      rules = [
        for r in v.rules :
        merge(r, {
          has_values = (
            length(coalesce(try(r.allow.values, []), [])) > 0 ||
            length(coalesce(try(r.deny.values, []), [])) > 0
          )
        })
      ]
    })
  }

  _custom_constraints_factory_data_raw = (
    var.org_policy_custom_constraints_data_path == null
    ? tomap({})
    : merge([
      for f in fileset(var.org_policy_custom_constraints_data_path, "*.yaml") :
      yamldecode(file("${var.org_policy_custom_constraints_data_path}/${f}"))
    ]...)
  )

  _custom_constraints_factory_data = {
    for k, v in local._custom_constraints_factory_data_raw :
    k => {
      display_name   = try(v.display_name, null)
      description    = try(v.description, null)
      action_type    = v.action_type
      condition      = v.condition
      method_types   = v.method_types
      resource_types = v.resource_types
    }
  }

  _custom_constraints = merge(local._custom_constraints_factory_data, var.org_policy_custom_constraints)

  custom_constraints = {
    for k, v in local._custom_constraints :
    k => merge(v, {
      name   = k
      parent = var.organization_id
    })
  }
}

resource "google_org_policy_policy" "default" {
  for_each = local.org_policies
  name     = each.value.name
  parent   = each.value.parent

  spec {
    inherit_from_parent = each.value.inherit_from_parent
    reset               = each.value.reset

    rules {
      allow_all = try(each.value.allow.all, null) == true ? "TRUE" : null
      deny_all  = try(each.value.deny.all, null) == true ? "TRUE" : null
      enforce = (
        each.value.is_boolean_policy && each.value.enforce != null
        ? upper(tostring(each.value.enforce))
        : null
      )
      dynamic "values" {
        for_each = each.value.has_values ? [1] : []
        content {
          allowed_values = try(each.value.allow.values, null)
          denied_values  = try(each.value.deny.values, null)
        }
      }
    }

    dynamic "rules" {
      for_each = each.value.rules
      iterator = rule
      content {
        allow_all = try(rule.value.allow.all, false) == true ? "TRUE" : null
        deny_all  = try(rule.value.deny.all, false) == true ? "TRUE" : null
        enforce = (
          each.value.is_boolean_policy && rule.value.enforce != null
          ? upper(tostring(rule.value.enforce))
          : null
        )
        condition {
          description = rule.value.condition.description
          expression  = rule.value.condition.expression
          location    = rule.value.condition.location
          title       = rule.value.condition.title
        }
        dynamic "values" {
          for_each = rule.value.has_values ? [1] : []
          content {
            allowed_values = try(rule.value.allow.values, null)
            denied_values  = try(rule.value.deny.values, null)
          }
        }
      }
    }
  }

  depends_on = [
    google_organization_iam_audit_config.config,
    google_organization_iam_binding.authoritative,
    google_organization_iam_custom_role.roles,
    google_organization_iam_member.additive,
    google_organization_iam_policy.authoritative,
    google_org_policy_custom_constraint.constraint,
  ]
}

resource "google_org_policy_custom_constraint" "constraint" {
  provider = google-beta

  for_each       = local.custom_constraints
  name           = each.value.name
  parent         = each.value.parent
  display_name   = each.value.display_name
  description    = each.value.description
  action_type    = each.value.action_type
  condition      = each.value.condition
  method_types   = each.value.method_types
  resource_types = each.value.resource_types
}
