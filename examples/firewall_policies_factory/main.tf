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
  firewall_policy_factory = {
    cidr_file   = "./cidrs.yaml"
    policy_name = null
    rules_file  = "./rules.yaml"
  }
  firewall_policy_association = {
    factory-policy = module.google_organization_configuration.firewall_policy_id["factory"]
  }
}
