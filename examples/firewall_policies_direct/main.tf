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
