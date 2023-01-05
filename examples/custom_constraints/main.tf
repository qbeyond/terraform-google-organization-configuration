/**
 * Copyright 2023 q.beyond AG
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

# Make sure to impersonate an service account
# gcloud application-default not supported
provider "google-beta" {
  impersonate_service_account = "sa-terraformorganization-01@dev-automation-01.iam.gserviceaccount.com"
}

provider "google" {
  impersonate_service_account = "sa-terraformorganization-01@dev-automation-01.iam.gserviceaccount.com"
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
