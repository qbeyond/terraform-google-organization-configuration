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
