terraform {
    backend "remote" {
        organization = "epsi-misterpurl"

        workspaces {
            name = "terraform_epsi"
        }
    }
}