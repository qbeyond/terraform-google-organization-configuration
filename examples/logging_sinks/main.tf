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
