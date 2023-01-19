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
